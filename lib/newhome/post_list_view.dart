import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../PostCard.dart';

class PostListView extends StatefulWidget {
  final String filter; // 'following' or 'all'
  final String category; // kategori ismi veya 'Tümü'

  const PostListView({super.key, required this.filter, required this.category});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _posts = [];
  List<String> _followingIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPosts();
    });
  }


  @override
  void didUpdateWidget(PostListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔁 Scroll pozisyonunu koru
    final shouldRefetch =
        oldWidget.filter != widget.filter || oldWidget.category != widget.category;
    if (shouldRefetch) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    final currentScroll = _scrollController.hasClients ? _scrollController.offset : 0.0;

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _posts = [];
        _isLoading = false;
      });
      return;
    }


    if (widget.filter == 'following') {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _followingIds = List<String>.from(userDoc.data()?['following'] ?? []);
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true)
        .get();

    List<DocumentSnapshot> posts = snapshot.docs;

    if (widget.filter == 'following') {
      posts = posts.where((doc) => _followingIds.contains(doc['authorId'])).toList();
    }

    if (widget.category != 'Tümü') {
      posts = posts.where((doc) => doc['category'] == widget.category).toList();
    }

    setState(() {
      _posts = posts;
      _isLoading = false;
    });

    // 🔥 Scroll pozisyonunu geri yükle
    await Future.delayed(Duration(milliseconds: 50));
    _scrollController.jumpTo(currentScroll);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset('assets/no-posts.png', width: 240)),
          const SizedBox(height: 12),
          const Text(
            'Oops! Henüz hiç gönderi yok.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yeni bir gönderiyle ilk sen ol!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final postData = _posts[index].data() as Map<String, dynamic>;
        postData['id'] = _posts[index].id;
        return PostCard(post: postData);
      },
    );

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
