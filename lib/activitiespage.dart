import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final Color primaryColor = Colors.orange.shade600;
  List<dynamic> allPosts = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/posts.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          allPosts = json.decode(contents);
        });
      } else {
        final assetData = await rootBundle.loadString('assets/posts.json');
        setState(() {
          allPosts = json.decode(assetData);
        });
      }
    } catch (e) {
      print("Postlar yüklenirken hata: $e");
    }
  }

  List<dynamic> get filteredPosts {
    if (searchQuery.isEmpty) {
      return allPosts;
    } else {
      return allPosts.where((post) {
        final username = (post["username"] ?? "").toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return username.contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keşfet", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          Text(
            "Popüler Kategoriler",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip("Teknoloji", Icons.devices),
              _buildCategoryChip("Sağlık", Icons.health_and_safety),
              _buildCategoryChip("Seyahat", Icons.flight),
              _buildCategoryChip("Kitaplar", Icons.menu_book),
              _buildCategoryChip("Müzik", Icons.music_note),
              _buildCategoryChip("Yemek", Icons.restaurant),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Popüler Paylaşımlar",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 12),
          if (filteredPosts.isEmpty)
            Center(
              child: Text(
                "Sonuç bulunamadı.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            )
          else
            ...filteredPosts.map((post) => _buildDiscoverCard(post)).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Kullanıcı adına göre ara...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 20, color: Colors.white),
      label: Text(label),
      backgroundColor: primaryColor,
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildDiscoverCard(dynamic post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          if (post.containsKey("image") && post["image"] != "")
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                post["image"],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            title: Text(post["text"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post["username"] ?? "Kullanıcı"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
