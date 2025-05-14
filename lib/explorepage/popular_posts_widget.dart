import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopularPostsWidget extends StatelessWidget {
  const PopularPostsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "💬 Popüler Paylaşımlar",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Text("Gönderi bulunamadı", style: TextStyle(color: Colors.grey.shade600));
            }

            return Column(
              children: docs.map((doc) {
                final post = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Column(
                    children: [
                      if (post["image"] != null && post["image"] != "")
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            post["image"],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ListTile(
                        title: Text(post["text"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(post["username"] ?? "Kullanıcı"),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
