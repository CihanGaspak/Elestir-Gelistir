import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../post_detail_page.dart';

class PopularPostsWidget extends StatelessWidget {
  const PopularPostsWidget({super.key});

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.lightbulb_outline;
      case 1:
        return Icons.build_circle_outlined;
      case 2:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }


  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💬 Popüler Paylaşımlar",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('views', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text("Popüler gönderi bulunamadı", style: TextStyle(color: Colors.grey.shade600));
              }

              return Column(
                children: docs.map((doc) {
                  final post = doc.data() as Map<String, dynamic>;
                  post['id'] = doc.id;
                  final uid = post["authorId"] ?? "";

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: getUserData(uid),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      final userName = user?["username"] ?? "Kullanıcı";
                      final userPhoto = user?["photoUrl"] ?? "assets/default_avatar.png";
                      final category = post["category"] ?? "Diğer";
                      final content = post["content"] ?? "";
                      final step = post["progressStep"] ?? 0;
                      final viewCount = post["views"] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(post: post),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 👤 Kullanıcı ve kategori + step
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: userPhoto.startsWith("assets/")
                                          ? AssetImage(userPhoto) as ImageProvider
                                          : NetworkImage(userPhoto),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.category, size: 16, color: Colors.orange),
                                              const SizedBox(width: 4),
                                              Text(category, style: const TextStyle(fontSize: 13)),
                                              const SizedBox(width: 10),
                                              Row(
                                                children: List.generate(3, (i) {
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                                    child: Icon(
                                                      _getStepIcon(i),
                                                      size: 16,
                                                      color: i <= step ? Colors.orange.shade600 : Colors.grey.shade300,
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // 📝 İçerik
                                Text(
                                  content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 👁️ Views - sağa hizalı
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$viewCount',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
