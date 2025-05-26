import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../PostCard.dart';
import '../settingspage.dart';
import 'follower_list_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream;

  // ✅ Tüm kaydedilen gönderiler için
  late Future<List<Map<String, dynamic>>> savedPostsFuture;

  String _photoUrl = '';
  String name = "Kullanıcı";
  String username = "@kullanici";
  String bio = "Nisan değilse Mayıs";

  int followers = 143;
  int following = 87;
  double helpfulness = 8.9;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserInfo());

    final uid = FirebaseAuth.instance.currentUser?.uid;
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .snapshots();

    // ✅ Kaydedilen gönderileri yükle
    savedPostsFuture = FirebaseFirestore.instance
        .collection('posts')
        .where('savedBy', arrayContains: uid)
        .get()
        .then((snap) => snap.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList());
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      name        = data['username'] ?? 'Kullanıcı';
      username    = "@${user.email?.split('@').first}";
      _photoUrl   = data['photoUrl'] ?? '';
      followers   = (data['followers'] as List<dynamic>? ?? []).length;
      following   = (data['following'] as List<dynamic>? ?? []).length;
      helpfulness = (data['usefulness'] ?? 0).toDouble();
    });
  }


  Widget _buildPostTab(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
      bool Function(Map<String, dynamic>) filter,
      ) {
    if (!snap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final posts = snap.data!.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).where(filter).toList();

    if (posts.isEmpty) {
      return const Center(child: Text('Gönderi yok.'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(post: posts[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          centerTitle: true,
          backgroundColor: primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ).then((_) => _loadUserInfo()),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: _photoUrl.isNotEmpty
                  ? (_photoUrl.startsWith('assets/')
                  ? AssetImage(_photoUrl)
                  : NetworkImage(_photoUrl)) as ImageProvider
                  : const AssetImage('assets/images/profile.jpg'),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(username, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(bio),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Takipçi', followers, onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FollowerListPage(userId: uid, showFollowers: true),
                    ));
                  }
                }),
                _stat('Takip', following, onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FollowerListPage(userId: uid, showFollowers: false),
                    ));
                  }
                }),
                _stat('Faydalılık', '${helpfulness.toStringAsFixed(1)}/10'),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _postsStream,
                builder: (context, snap) {
                  final docs = snap.hasData ? snap.data!.docs : [];
                  final supportCnt = docs.where((d) => (d['progressStep'] ?? 0) < 3).length;
                  final solutionCnt = docs.where((d) => (d['progressStep'] ?? 0) == 3).length;

                  // ✅ Kaydedilen sayısı ayrı hesaplanmaz artık
                  return Column(
                    children: [
                      TabBar(
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        tabs: [
                          Tab(icon: const Icon(Icons.timelapse), text: 'Devam ($supportCnt)'),
                          Tab(icon: const Icon(Icons.check_circle), text: 'Bitti ($solutionCnt)'),
                          Tab(
                            icon: const Icon(Icons.bookmark),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: savedPostsFuture,
                              builder: (context, snap) {
                                final count = snap.hasData ? snap.data!.length : 0;
                                return Text('Kaydet ($count)');
                              },
                            ),
                          ),

                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) < 3),
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) == 3),

                            // ✅ Kaydedilenler sekmesi
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: savedPostsFuture,
                              builder: (context, savedSnap) {
                                if (!savedSnap.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final savedPosts = savedSnap.data!;
                                if (savedPosts.isEmpty) {
                                  return const Center(child: Text("Kaydedilen gönderi yok."));
                                }
                                return ListView.builder(
                                  itemCount: savedPosts.length,
                                  itemBuilder: (_, i) => PostCard(post: savedPosts[i]),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, dynamic value, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

}
