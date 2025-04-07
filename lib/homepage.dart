import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'PostCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = ['Tümü', 'Eğitim', 'İnşaat', 'Araç Bakım'];
  String selectedCategory = 'Tümü';

  List<dynamic> allPosts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final String jsonString = await rootBundle.loadString('assets/posts.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      allPosts = jsonData;
    });
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
        title: Text("Eleştir - Geliştir"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori Butonları
          Container(
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
                      color: isSelected ? Colors.orange.shade600 : Colors.orange.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.orange.shade800 : Colors.orange.shade500,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Postlar
          Expanded(
            child: ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return PostCard(post: post);
              },
            ),
          ),
        ],
      ),
    );
  }
}

