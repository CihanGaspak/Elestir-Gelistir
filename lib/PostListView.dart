import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'PostCard.dart';

class PostListView extends StatefulWidget {
  final String category;

  const PostListView({super.key, required this.category});

  @override
  State<PostListView> createState() => PostListViewState();
}

class PostListViewState extends State<PostListView>
    with AutomaticKeepAliveClientMixin<PostListView> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isRefreshing = false;
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PostListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      refreshPosts();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
        !_isLoading &&
        _hasMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchInitialPosts() async {
    _posts.clear();
    _lastDoc = null;
    _hasMore = true;
    await _fetchMorePosts();
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true)
        .limit(10);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      final newPosts = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      _posts.addAll(newPosts);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> refreshPosts() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    final oldOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final oldPosts = List<Map<String, dynamic>>.from(_posts);

    setState(() {
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    await _fetchMorePosts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _posts.isNotEmpty) {
        _scrollController.jumpTo(oldOffset);
      } else {
        // veri gelmediyse eski listeyi geri yükle
        setState(() => _posts.addAll(oldPosts));
      }
    });

    _isRefreshing = false;
  }

  void refreshList() async {
    await refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = widget.category.toLowerCase() == 'tümü'
        ? _posts
        : _posts
        .where((p) => (p['category'] ?? '') == widget.category.toLowerCase())
        .toList();

    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        FocusScope.of(context).unfocus();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: refreshPosts,
        child: ListView.builder(
          key: const PageStorageKey('post_list'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filtered.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < filtered.length) {
              return PostCard(
                key: ValueKey(filtered[index]['id']),
                post: filtered[index],
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
