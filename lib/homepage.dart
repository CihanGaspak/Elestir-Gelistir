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
        // Eğer assets'ten ilk defa yüklenecekse
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
    final imagePath = imageFile?.path ?? ""; // image varsa yolunu al

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
      return allPosts
          .where((post) => post['category'] == selectedCategory)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.orange.shade600,
        title: Text("Eleştir - Geliştir",style: TextStyle(color: Colors.white),),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange.shade800
                                : Colors.grey.shade500,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ];
        },
        body: ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return PostCard(post: post);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Bottom sheet açma
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            builder: (BuildContext context) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: MediaQuery.of(context).size.width*1,
                ),
                child: PostWrite(
                  controller: postController,  // Pass the TextEditingController
                  onPost: addPost,  // Pass the addPost callback
                ),
              );
            },
          );
        },
        backgroundColor: Colors.orange.shade600,
        child: Icon(
          size: 32,
          Icons.help_outline,
          color: Colors.white,
        ),
      ),

    );
  }
}
