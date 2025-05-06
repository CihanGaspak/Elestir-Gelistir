import 'package:elestir_gelistir/PostWriteCard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'PostListView.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<PostListViewState> _postListKey = GlobalKey();
  final TextEditingController _postController = TextEditingController();

  final List<String> categories = [
    'Tümü', 'Eğitim', 'Spor', 'Tamirat', 'Araç Bakım',
    'Sağlık', 'Teknoloji', 'Kişisel Gelişim', 'Sanat', 'Yazılım',
  ];

  String selectedCategory = 'Tümü';

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
          // Kategori butonları
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
                      if (selectedCategory != cat) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Post List View
          Expanded(
            child: PostListView(
              key: _postListKey,
              category: selectedCategory,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_circle_outline, color: Colors.white),

        onPressed: () => showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: PostWrite(
              controller: _postController,
              onPost: (text, category) async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final postData = {
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
                };

                await FirebaseFirestore.instance
                    .collection('posts')
                    .add(postData);

                _postListKey.currentState?.refreshPosts();
              },
            ),
          ),
        ),
      ),
    );
  }
}
