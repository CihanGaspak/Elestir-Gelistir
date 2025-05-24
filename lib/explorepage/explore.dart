import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'SearchUserWidget.dart';
import 'daily_post_widget.dart';
import 'popular_categories_widget.dart';
import 'popular_posts_widget.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      final history = List<String>.from(data?['searchHistory'] ?? []);
      setState(() => _searchHistory = history);
    }
  }

  Future<void> _updateSearchHistory(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || query.isEmpty) return;

    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }

    setState(() {});
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'searchHistory': _searchHistory,
    });
  }

  Future<void> _deleteSearchHistoryItem(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _searchHistory.remove(query);
    setState(() {});
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'searchHistory': _searchHistory,
    });
  }

  Future<void> _clearAllHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _searchHistory.clear());
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'searchHistory': [],
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = "";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keşfet", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchUserWidget(
                      onClose: (val) {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı adına göre ara...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                DailyPostWidget(),
                SizedBox(height: 24),
                PopularCategoriesWidget(),
                SizedBox(height: 24),
                PopularPostsWidget(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
