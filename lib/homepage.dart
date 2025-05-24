import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:elestir_gelistir/PostCard.dart';
import 'package:elestir_gelistir/PostWriteCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageStorageBucket _bucket = PageStorageBucket(); // 👈 doğru yerde
  final PageStorageKey _pageKey = PageStorageKey("postListScroll");

  final List<DocumentSnapshot> _posts = [];
  final List<String> _cats = [
    'Tümü', 'Eğitim', 'Spor', 'Tamirat', 'Araç Bakım',
    'Sağlık', 'Teknoloji', 'Kişisel Gelişim', 'Sanat', 'Yazılım'
  ];

  String _selected = 'Tümü';
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchNextPage();
    }
  }

  Query _baseQuery() {
    final base = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true);

    if (_selected != 'Tümü') {
      return base.where('category', isEqualTo: _selected);
    }
    return base;
  }

  Future<void> _fetchFirstPage() async {
    setState(() {
      _loading = true;
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    final snap = await _baseQuery().limit(_pageSize).get();

    if (!mounted) return;

    setState(() {
      _posts.addAll(snap.docs);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _pageSize;
      _loading = false;
    });
  }

  Future<void> _fetchNextPage() async {
    if (_lastDoc == null || _loading) return;
    setState(() => _loading = true);

    final snap = await _baseQuery()
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize)
        .get();

    if (!mounted) return;

    setState(() {
      _posts.addAll(snap.docs);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      _hasMore = snap.docs.length == _pageSize;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eleştir - Geliştir'),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: PageStorage(
        bucket: _bucket,
        child: Column(
          children: [
            // Kategori Barı
            SizedBox(
              height: 50,
              child: ListView.builder(
                cacheExtent: 1000,
                scrollDirection: Axis.horizontal,
                itemCount: _cats.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(_cats[index]),
                      selected: _selected == _cats[index],
                      selectedColor: primary,
                      onSelected: (_) {
                        if (_selected != _cats[index]) {
                          setState(() {
                            _selected = _cats[index];
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });

                          _fetchFirstPage();
                        }
                      },

                    ),
                  );
                },
              ),
            ),

            // Post Listesi
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchFirstPage,
                child: ListView.builder(
                  key: _pageKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _posts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final data = _posts[index].data() as Map<String, dynamic>;
                    data['id'] = _posts[index].id;
                    return PostCard(post: data);
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // Yeni Post Ekle FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: PostWrite(
                controller: TextEditingController(),
                onPost: (text, category) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  await FirebaseFirestore.instance.collection('posts').add({
                    'authorId': user.uid,
                    'authorName': userDoc['username'] ?? user.email,
                    'authorPhotoUrl': userDoc['photoUrl'] ?? '',
                    'content': text,
                    'category': category,
                    'dailyPick': false,
                    'likesCount': 0,
                    'likedBy': [],
                    'savedBy': [],
                    'views': 0,
                    'progressStep': 0,
                    'step1Note': '',
                    'step2Note': '',
                    'step3Note': '',
                    'date': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  _fetchFirstPage();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
