import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'PostCard.dart';
import 'PostWriteCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollCtl = ScrollController();
  final List<String> categories = [
    'Tümü',
    'Eğitim',
    'Spor',
    'Tamirat',
    'Araç Bakım',
    'Sağlık',
    'Teknoloji',
    'Kişisel Gelişim',
    'Sanat',
    'Yazılım',
  ];

  String selectedCategory = 'Tümü';
  final TextEditingController postController = TextEditingController();
  List<Map<String, dynamic>> allPosts = [];

  Future<void> addPost(String text, String category, XFile? imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce giriş yapın.')),
        );
      }
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgisi bulunamadı.')),
        );
      }
      return;
    }

    final username = userDoc['username'] ?? 'Anonim';
    final photoUrl = userDoc['photoUrl'] ?? '';

    final newPost = {
      'authorId': user.uid,
      'authorName': username,
      'authorPhotoUrl': photoUrl,
      'category': category.toLowerCase(),
      'content': text,
      'date': FieldValue.serverTimestamp(),
      'imageUrl': '',
      'likesCount': 0,
      'commentsCount': 0,
      'views': 0,
      'likedBy': [],
      'savedBy': [],
      'progressStep': 0,
    };

    try {
      await FirebaseFirestore.instance.collection('posts').add(newPost);
      postController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi başarıyla paylaşıldı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderi hatası: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final newPosts = snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          if (allPosts.isEmpty || allPosts.first['id'] != newPosts.first['id']) {
            allPosts = newPosts;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;
    final sel = selectedCategory.toLowerCase();
    final filteredPosts = sel == 'tümü'
        ? allPosts
        : allPosts
        .where((p) => (p['category'] ?? '').toLowerCase() == sel)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Eleştir - Geliştir'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    selectedColor: primaryColor,
                    onSelected: (_) {
                      setState(() => selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  'Henüz gönderi yok.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
                : ListView.separated(
              controller: _scrollCtl,
              padding: const EdgeInsets.only(top: 8),
              itemCount: filteredPosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (context, index) {
                return PostCard(post: filteredPosts[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, size: 30),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: PostWrite(
              controller: postController,
              onPost: (text, category) async {
                Navigator.of(ctx).pop();
                await addPost(text, category, null);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    postController.dispose();
    super.dispose();
  }
}
