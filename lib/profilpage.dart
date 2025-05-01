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
  String _photoUrl = '';
  String name = "Kullanıcı";
  String username = "@kullanici";
  String bio = "Nisan değilse Mayıs";

  List<Map<String, dynamic>> allPosts = [];
  int supports = 0;
  int solutions = 0;
  int followers = 143;
  int following = 87;
  double helpfulness = 8.9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserInfo();
      loadPosts();
    });
  }

  Future<void> loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        name = userDoc['username'] ?? "Kullanıcı";
        username = "@${user.email?.split('@')[0]}";
        _photoUrl = userDoc['photoUrl'] ?? '';
      });
    }
  }

  Future<void> loadPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("Aktif kullanıcı: ${user?.uid}");
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: user.uid)
        .get();

    debugPrint("Post sayısı: ${query.docs.length}");

    final fetchedPosts = query.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();

    // Tarihe göre sıralama
    fetchedPosts.sort((a, b) {
      final aDate = (a['date'] as Timestamp?)?.toDate();
      final bDate = (b['date'] as Timestamp?)?.toDate();
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    int newSupports =
        fetchedPosts.where((p) => (p['progressStep'] ?? 0) < 3).length;
    int newSolutions =
        fetchedPosts.where((p) => (p['progressStep'] ?? 0) == 3).length;

    setState(() {
      allPosts = fetchedPosts;
      supports = newSupports;
      solutions = newSolutions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profil"),
          centerTitle: true,
          backgroundColor: primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((_) {
                  // Ayarlardan dönünce avatarı tekrar yükle
                  loadUserInfo();
                });

              },
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
                  : NetworkImage(_photoUrl) as ImageProvider)
                  : const AssetImage("assets/images/profile.jpg"),
            ),
            const SizedBox(height: 10),
            Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(username, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(bio),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("Takipçi", followers),
                _buildStat("Takip", following),
                _buildStat(
                    "Faydalılık", "${helpfulness.toStringAsFixed(1)}/10"),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: [
                Tab(
                    icon: const Icon(Icons.timelapse),
                    text: "Devam Ediyor ($supports)"),
                Tab(
                    icon: const Icon(Icons.check_circle),
                    text: "Çözüldü ($solutions)"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPostList((p) => (p['progressStep'] ?? 0) < 3),
                  _buildPostList((p) => (p['progressStep'] ?? 0) == 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, dynamic value) {
    return Column(
      children: [
        Text("$value",
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPostList(bool Function(Map<String, dynamic>) filter) {
    final filtered = allPosts.where(filter).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text("Gönderi yok."));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => PostCard(post: filtered[index]),
    );
  }
}
