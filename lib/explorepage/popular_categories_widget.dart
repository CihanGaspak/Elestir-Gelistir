import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopularCategoriesWidget extends StatelessWidget {
  const PopularCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        final Map<String, int> categoryCount = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data["category"] ?? "Diğer";
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }

        final sorted = categoryCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⭐ Popüler Kategoriler",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sorted.take(5).map((e) => Chip(
                label: Text(e.key),
                backgroundColor: primaryColor,
                labelStyle: const TextStyle(color: Colors.white),
              )).toList(),
            ),
          ],
        );
      },
    );
  }
}
