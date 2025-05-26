import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'PostCard.dart';
import 'ProfilePage/follower_list_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _photoUrl = '';
  String name = "Kullanıcı";
  String bio = "Bunca yıl sönmemiş umudum Nisan değilse Mayıs, Perşembe değilse Pazar";
  double usefulness = 0;
  int totalPosts = 0;
  DateTime? createdAt;
  bool _userInfoLoaded = false;
  bool _isFollowing = false;
  bool followsMe = false;
  List<String> followersList = [];
  List<String> followingList = [];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .snapshots();
  }

  Future<void> _loadUserInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data == null) return;

    final raw = data['usefulness'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final currentFollowing = List<String>.from(currentUserDoc.data()?['following'] ?? []);
    final targetFollowers = List<String>.from(data['followers'] ?? []);
    final targetFollowing = List<String>.from(data['following'] ?? []);

    setState(() {
      name         = data['username'] ?? 'Kullanıcı';
      _photoUrl    = data['photoUrl'] ?? '';
      followersList = targetFollowers;
      followingList = targetFollowing;
      usefulness   = raw is num ? raw.toDouble() : 0.0;
      createdAt    = (data['joinedAt'] as Timestamp?)?.toDate();
      _isFollowing = currentFollowing.contains(widget.userId);
      followsMe    = targetFollowers.contains(currentUserId);
      _userInfoLoaded = true;
    });
  }

  Widget _buildPostTab(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
      bool Function(Map<String, dynamic>) filter,
      ) {
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());

    final posts = snap.data!.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).where(filter).toList();

    return posts.isEmpty ? const Center(child: Text("Gönderi yok.")) :
    ListView.builder(
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(post: posts[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == widget.userId;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: primaryColor,
          actions: [
            if (!isOwnProfile)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'block') {
                    print('Engelle seçildi');
                  } else if (value == 'report') {
                    print('Şikayet Et seçildi');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'block', child: Text("Engelle")),
                  const PopupMenuItem(value: 'report', child: Text("Şikayet Et")),
                  if (createdAt != null)
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        "Hesap açıldı: ${_formatJoinDate(createdAt!)}",
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                ],
              ),
          ],
        ),
        body: !_userInfoLoaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: _photoUrl.startsWith("assets/")
                        ? AssetImage(_photoUrl) as ImageProvider
                        : NetworkImage(_photoUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (!isOwnProfile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.orange.shade50 : Colors.white,
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: _isFollowing ? Colors.amber : Colors.orange.shade600, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () async {
                            setState(() {
                              _isFollowing = !_isFollowing;
                              if (_isFollowing) {
                                followersList.add(currentUserId!);
                              } else {
                                followersList.remove(currentUserId);
                              }
                            });
                            if (_isFollowing) {
                              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                                'following': FieldValue.arrayUnion([widget.userId])
                              });
                              await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                                'followers': FieldValue.arrayUnion([currentUserId])
                              });
                            } else {
                              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                                'following': FieldValue.arrayRemove([widget.userId])
                              });
                              await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                                'followers': FieldValue.arrayRemove([currentUserId])
                              });
                            }
                          },
                          child: Text(_isFollowing ? "Takipten Çık" : "Takip Et"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _postsStream,
              builder: (context, snap) {
                final docs = snap.hasData ? snap.data!.docs : [];
                final supportCnt = docs.where((d) => (d['progressStep'] ?? 0) < 3).length;
                final solutionCnt = docs.where((d) => (d['progressStep'] ?? 0) == 3).length;
                totalPosts = docs.length;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowerListPage(userId: widget.userId, showFollowers: true),
                                ),
                              );
                            },
                            child: _stat('Takipçi', followersList.length),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowerListPage(userId: widget.userId, showFollowers: false),
                                ),
                              );
                            },
                            child: _stat('Takip', followingList.length),
                          ),
                          _stat('Faydalılık', '${usefulness.toStringAsFixed(1)}/10'),
                          _stat('Gönderi', totalPosts),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TabBar(
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        tabs: [
                          Tab(icon: const Icon(Icons.timelapse), text: 'Devam ($supportCnt)'),
                          Tab(icon: const Icon(Icons.check_circle), text: 'Bitti ($solutionCnt)'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) < 3),
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) == 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, dynamic value) => Column(
    children: [
      Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(title, style: const TextStyle(color: Colors.grey)),
    ],
  );

  String _formatJoinDate(DateTime date) {
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    return "${months[date.month - 1]} ${date.year}";
  }
}
