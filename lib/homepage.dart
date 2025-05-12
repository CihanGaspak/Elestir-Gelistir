import 'dart:async';
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
  /* --------------------------- SABİT VERİ ---------------------------- */
  final _scrollCtl = ScrollController();
  final _cats = [
    'Tümü','Eğitim','Spor','Tamirat','Araç Bakım',
    'Sağlık','Teknoloji','Kişisel Gelişim','Sanat','Yazılım',
  ];
  String _selected = 'Tümü';

  /* --------------------------- POST STATE ---------------------------- */
  final List<DocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;            // şu an fetch ediliyor mu?
  bool _hasMore = true;             // başka sayfa kaldı mı?
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    _fetchFirstPage();              // ilk 10 post
  }

  @override
  void dispose() {
    _scrollCtl.removeListener(_onScroll);
    _scrollCtl.dispose();
    super.dispose();
  }

  /* ---------------------- SCROLL LİSTENER ---------------------------- */
  void _onScroll() {
    if (_scrollCtl.position.pixels >=
        _scrollCtl.position.maxScrollExtent - 200 && // dipten 200px önce
        !_loading &&
        _hasMore) {
      _fetchNextPage();
    }
  }

  /* -------------------------- FETCH LOGİC --------------------------- */
  Query _baseQuery() => FirebaseFirestore.instance
      .collection('posts')
      .where('category', isEqualTo: _selected == 'Tümü' ? null : _selected)
      .orderBy('date', descending: true);

  Future<void> _fetchFirstPage() async {
    setState(() { _loading = true; _posts.clear(); _lastDoc = null; _hasMore = true; });
    final snap = await _baseQuery().limit(_pageSize).get();
    if (mounted) {
      setState(() {
        _posts.addAll(snap.docs);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMore = snap.docs.length == _pageSize;
        _loading = false;
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (_lastDoc == null || _loading) return;

    /* 1️⃣  ÖNCE: mevcut konumu ve listenin boyunu kaydet */
    final double beforeOffset = _scrollCtl.offset;
    final double beforeMax    = _scrollCtl.position.maxScrollExtent;

    setState(() => _loading = true);

    final snap = await _baseQuery()
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize)
        .get();

    if (!mounted) return;

    /* 2️⃣  VERİLERİ EKLE */
    setState(() {
      _posts.addAll(snap.docs);
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      _hasMore = snap.docs.length == _pageSize;
      _loading = false;
    });

    /* 3️⃣  FRAME BİTTİKTEN HEMEN SONRA kaydırma konumunu geri ayarla */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final double newMax = _scrollCtl.position.maxScrollExtent;
      final double delta  = newMax - beforeMax;
      // Listeye eleman eklenmişse delta > 0 olur
      if (delta > 0) {
        _scrollCtl.jumpTo(beforeOffset + delta);
      }
    });
  }



  /* -------------------------- UI ------------------------------------ */
  @override
  Widget build(BuildContext context) {
    final primary = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eleştir - Geliştir'),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          /* --------------------- KATEGORİ CHİP BAR -------------------- */
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: _cats.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_cats[i]),
                  selected: _selected == _cats[i],
                  selectedColor: primary,
                  onSelected: (_) {
                    if (_selected != _cats[i]) {
                      _selected = _cats[i];
                      _fetchFirstPage(); // kategori değişince liste sıfırla
                    }
                  },
                ),
              ),
            ),
          ),

          /* ----------------------- POST LİSTESİ ----------------------- */
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchFirstPage,
              child: ListView.builder(
                key: const PageStorageKey('postListScroll'),   // 👈 konum saklanır
                controller: _scrollCtl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _posts.length) {
                    // dipte yükleniyor göstergesi
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final doc = _posts[i];
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return PostCard(post: data);
                },
              ),
            ),
          ),
        ],
      ),

      /* ------------------------ POST YAZ FAB ------------------------ */
      floatingActionButton: FloatingActionButton(
      backgroundColor: primary,
      child: const Icon(Icons.add_circle_outline),
      onPressed: () => showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: PostWrite(          //  ← PostWrite → PostWriteCard
            controller: TextEditingController(),
            onPost: (text, category) async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final snap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

              await FirebaseFirestore.instance.collection('posts').add({
                'authorId': user.uid,
                'authorName': snap['username'] ?? user.email,
                'authorPhotoUrl': snap['photoUrl'] ?? '',
                'content': text,
                'category': category,
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

              Navigator.pop(context);   // sayfadan çık
              _fetchFirstPage();        // listeyi güncelle
            },
          ),
        ),
      ),
    ),
    );
  }
}
