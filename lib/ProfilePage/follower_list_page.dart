import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../UserProfilePage.dart';

class FollowerListPage extends StatefulWidget {
  final String userId;
  final bool showFollowers;

  const FollowerListPage({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowerListPage> createState() => _FollowerListPageState();
}

class _FollowerListPageState extends State<FollowerListPage> {
  List<String> myFollowing = [];
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredUserList = [];
  String searchQuery = '';
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserList();
    _loadCurrentUserFollowing();
  }

  Future<void> _loadCurrentUserFollowing() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    final data = doc.data() as Map<String, dynamic>;
    myFollowing = List<String>.from(data['following'] ?? []);
  }

  Future<void> _loadUserList() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data() as Map<String, dynamic>;
    final List<String> loadedUids = List<String>.from(data[widget.showFollowers ? 'followers' : 'following'] ?? []);

    List<Map<String, dynamic>> users = [];

    for (final uid in loadedUids) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['uid'] = uid;
        users.add(userData);
      }
    }

    setState(() {
      userList = users;
      filteredUserList = users;
      totalCount = users.length;
    });
  }

  void _filterList(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredUserList = userList.where((user) {
        final name = (user['username'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final title = widget.showFollowers ? 'Takipçiler' : 'Takip Edilenler';

    return Scaffold(
      appBar: AppBar(
        title: Text("$title ($totalCount)"),
        backgroundColor: Colors.orange.shade600,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterList,
              decoration: InputDecoration(
                hintText: 'İsme göre ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUserList.length,
              itemBuilder: (context, index) {
                final user = filteredUserList[index];
                final uid = user['uid'];
                final username = user['username'] ?? 'Kullanıcı';
                final photoUrl = user['photoUrl'] ?? '';
                final userFollowers = List<String>.from(user['followers'] ?? []);
                final userFollowing = List<String>.from(user['following'] ?? []);

                final bool iFollow = myFollowing.contains(uid);
                final bool followsMe = userFollowing.contains(currentUserId);
                final bool showFollowButton = currentUserId != uid;

                ImageProvider avatarImage;
                if (photoUrl.toString().startsWith('http') && photoUrl.isNotEmpty) {
                  avatarImage = NetworkImage(photoUrl);
                } else if (photoUrl.toString().startsWith('assets/')) {
                  avatarImage = AssetImage(photoUrl);
                } else {
                  avatarImage = const AssetImage('assets/avatar0.png');
                }

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: uid),
                      ),
                    );
                  },
                  leading: CircleAvatar(radius: 22, backgroundImage: avatarImage),
                  title: Row(
                    children: [
                      Text(username),
                    ],
                  ),
                  trailing: showFollowButton ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showFollowers)
                        OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(iFollow ? "Takipten Çık" : "Takip Et"),
                                content: Text(iFollow
                                    ? "Bu kişiyi takip etmeyi bırakmak istediğine emin misin?"
                                    : "Bu kişiyi takip etmek istiyor musun?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("İptal"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: iFollow ? Colors.grey : Colors.orange),
                                    child: Text(
                                      iFollow ? "Evet, takipten çık" : "Evet, takip et",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final currentRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
                              final targetRef = FirebaseFirestore.instance.collection('users').doc(uid);

                              if (iFollow) {
                                await currentRef.update({
                                  'following': FieldValue.arrayRemove([uid])
                                });
                                await targetRef.update({
                                  'followers': FieldValue.arrayRemove([currentUserId])
                                });
                              } else {
                                await currentRef.update({
                                  'following': FieldValue.arrayUnion([uid])
                                });
                                await targetRef.update({
                                  'followers': FieldValue.arrayUnion([currentUserId])
                                });
                              }

                              _loadUserList();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: iFollow ? Colors.black : Colors.white,
                            backgroundColor: iFollow ? Colors.grey.shade300 : Colors.orange,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            iFollow ? 'Takipten Çık' : 'Takip Et',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (!widget.showFollowers)
                        OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Takibi Bırak"),
                                content: const Text("Bu kişiyi takip etmeyi bırakmak istediğine emin misin?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("İptal"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text("Evet, bırak", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final currentRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
                              final targetRef = FirebaseFirestore.instance.collection('users').doc(uid);

                              await currentRef.update({
                                'following': FieldValue.arrayRemove([uid])
                              });
                              await targetRef.update({
                                'followers': FieldValue.arrayRemove([currentUserId])
                              });

                              setState(() {
                                userList.removeWhere((u) => u['uid'] == uid);
                                filteredUserList.removeWhere((u) => u['uid'] == uid);
                                totalCount--;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.grey.shade300,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Takibi Bırak',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                      if (widget.showFollowers)
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Takipçiden Çıkar"),
                                content: const Text("Bu kişiyi takipçilerinden çıkarmak istediğine emin misin?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("İptal"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text("Evet, çıkar", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final currentRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
                              final targetRef = FirebaseFirestore.instance.collection('users').doc(uid);

                              await currentRef.update({
                                'followers': FieldValue.arrayRemove([uid])
                              });
                              await targetRef.update({
                                'following': FieldValue.arrayRemove([currentUserId])
                              });

                              setState(() {
                                userList.removeWhere((u) => u['uid'] == uid);
                                filteredUserList.removeWhere((u) => u['uid'] == uid);
                                totalCount--;
                              });
                            }
                          },
                          icon: const Icon(Icons.person_remove, color: Colors.red),
                          tooltip: 'Takipçiden Çıkar',
                        ),
                    ],
                  ) : null,

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
