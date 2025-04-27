import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'PostCWriteCard.dart';
import 'PostCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = ['Tümü', 'Eğitim', 'Spor', 'Tamirat', 'Araç Bakım'];
  String selectedCategory = 'Tümü';

  List<dynamic> allPosts = [];
  final TextEditingController postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/posts.json');
  }

  Future<void> loadPosts() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          allPosts = json.decode(contents);
        });
      } else {
        final assetData = await rootBundle.loadString('assets/posts.json');
        allPosts = json.decode(assetData);
        await savePosts();
        setState(() {});
      }
    } catch (e) {
      print("Postları yüklerken hata: $e");
    }
  }

  Future<void> savePosts() async {
    final file = await _localFile;
    await file.writeAsString(json.encode(allPosts));
  }

  void addPost(String text, String category, File? imageFile) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final imagePath = imageFile?.path ?? "";

    final newPost = {
      "username": "Cihan Gaspak",
      "date": now.toString().substring(0, 16),
      "text": text,
      "hashtags": [],
      "image": imagePath,
      "likes": 0,
      "comments": 0,
      "shares": 0,
      "category": category,
      "commentList": [],
    };

    setState(() {
      allPosts.insert(0, newPost);
    });

    await savePosts();
  }

  List<dynamic> get filteredPosts {
    if (selectedCategory == 'Tümü') {
      return allPosts;
    } else {
      return allPosts.where((post) => post['category'] == selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text("Eleştir - Geliştir", style: TextStyle(color: Colors.white)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(category),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: filteredPosts.isEmpty
            ? Center(
          child: Text(
            "Henüz gönderi yok.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        )
            : ListView.separated(
          itemCount: filteredPosts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return PostCard(post: post);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext context) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: PostWrite(
                  controller: postController,
                  onPost: addPost,
                ),
              );
            },
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
