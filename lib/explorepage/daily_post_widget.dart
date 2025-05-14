import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../post_detail_page.dart';

class DailyPostWidget extends StatelessWidget {
  const DailyPostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('dailyPick', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Text(
            "Henüz 'Günün Gönderisi' seçilmedi.",
            style: TextStyle(color: Colors.grey.shade600),
          );
        }

        final postData = docs.first.data() as Map<String, dynamic>;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(postData["authorId"])
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final user = userSnapshot.data!.data() as Map<String, dynamic>?;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(post: postData),
                  ),
                );
              },
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 200),
                tween: Tween<double>(begin: 1, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, postData, user),
                      const SizedBox(height: 12),
                      Text(
                        "\"${postData["content"] ?? ""}\"",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> post, Map<String, dynamic>? user) {
    final step = post['progressStep'] ?? 0;
    final category = post['category'] ?? 'Genel';
    final timestamp = post['date'] as Timestamp?;
    final author = user?['username'] ?? 'Kullanıcı';
    final photoUrl = user?['photoUrl'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("✨", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              "Günün Eleştirisi",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
        Divider(),
        SizedBox(height: 6,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photoUrl.startsWith('assets/')
                      ? AssetImage(photoUrl) as ImageProvider
                      : NetworkImage(photoUrl),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(category), size: 18, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp != null ? timeago.format(timestamp.toDate(), locale: 'tr') : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    _getStepIcon(i),
                    size: 18,
                    color: i <= step ? Colors.orange.shade600 : Colors.grey.shade300,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sağlık':
        return Icons.favorite;
      case 'Spor':
        return Icons.sports_soccer;
      case 'Kişisel Gelişim':
        return Icons.self_improvement;
      case 'Teknoloji':
        return Icons.devices;
      default:
        return Icons.category;
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
}
