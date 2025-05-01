import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'PostCard.dart';
import 'PostCWriteCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = [
    'Tümü',
    'Eğitim',
    'Spor',
    'Tamirat',
    'Araç Bakım',
  ];
  String selectedCategory = 'Tümü';
  final TextEditingController postController = TextEditingController();

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
      'category': category.toLowerCase(),
      'content': text,
      'date': FieldValue.serverTimestamp(),
      'imageUrl': '',
      'likesCount': 0,
      'commentsCount': 0,
      'views': 0,
      'likedBy': [],
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
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Eleştir - Geliştir'),
      ),
      body: Column(
        children: [
          // Kategori Çipleri
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

          // Postlar
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
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
                  );
                }

                final docs = snapshot.data!.docs;
                final all = docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  m['id'] = d.id;
                  return m;
                }).toList();

                final sel = selectedCategory.toLowerCase();
                final posts = sel == 'tümü'
                    ? all
                    : all.where((p) =>
                (p['category']?.toString().toLowerCase() ?? '') == sel)
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 1),
                  itemBuilder: (context, index) {
                    return PostCard(post: posts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Yeni Gönderi FAB
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
                Navigator.of(ctx).pop(); // önce modal'ı kapat
                await addPost(text, category, null); // sonra postu ekle
              },
            ),
          ),
        ),
      ),
    );
  }
}
