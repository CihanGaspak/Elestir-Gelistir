import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'PostCard.dart';
import 'settingspage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 🔴  Gerçek-zamanlı gönderi akışı
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream;

  // -------------- Kullanıcı bilgisi --------------
  String _photoUrl = '';
  String name = "Kullanıcı";
  String username = "@kullanici";
  String bio = "Nisan değilse Mayıs";

  // (istatistik örnek, veri tabanınızda yoksa kaldırabilirsiniz)
  int followers = 143;
  int following = 87;
  double helpfulness = 8.9;

  @override
  void initState() {
    super.initState();

    // avatar / isim
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserInfo());

    final uid = FirebaseAuth.instance.currentUser?.uid;
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    setState(() {
      name     = doc['username'] ?? 'Kullanıcı';
      username = "@${user.email?.split('@').first}";
      _photoUrl = doc['photoUrl'] ?? '';
    });
  }

  // ---------- Tek bir tab listesi ----------
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
                _stat('Takipçi', followers),
                _stat('Takip', following),
                _stat('Faydalılık', '${helpfulness.toStringAsFixed(1)}/10'),
              ],
            ),
            const SizedBox(height: 8),

            // ----------- STREAM -----------
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _postsStream,
                builder: (context, snap) {
                  // --- sayaçlar ---
                  final docs = snap.hasData ? snap.data!.docs : [];
                  final supportCnt  = docs.where((d) => (d['progressStep'] ?? 0) < 3).length;
                  final solutionCnt = docs.where((d) => (d['progressStep'] ?? 0) == 3).length;

// 🔥 Kaydedilenler
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  final savedCnt   = docs.where((d) {
                    final savedBy = List<String>.from(d['savedBy'] ?? []);
                    return uid != null && savedBy.contains(uid);
                  }).length;


                  return Column(
                    children: [
                      TabBar(
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        tabs: [
                          Tab(icon: const Icon(Icons.timelapse),  text: 'Devam ($supportCnt)'),
                          Tab(icon: const Icon(Icons.check_circle), text: 'Bitti ($solutionCnt)'),
                          Tab(icon: const Icon(Icons.bookmark),     text: 'Kaydet ($savedCnt)'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Devam
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) < 3),
                            // Bitti
                            _buildPostTab(snap, (p) => (p['progressStep'] ?? 0) == 3),
                            // Kaydedilenler
                            _buildPostTab(snap, (p) {
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              final saved = List<String>.from(p['savedBy'] ?? []);
                              return uid != null && saved.contains(uid);
                            }),
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

  Widget _stat(String title, dynamic value) => Column(
    children: [
      Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(title, style: const TextStyle(color: Colors.grey)),
    ],
  );
}
