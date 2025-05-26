import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopularCategoriesWidget extends StatelessWidget {
  const PopularCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    // 🎯 Kategoriye özel ikonlar
    final Map<String, IconData> categoryIcons = {
      "Eğitim": Icons.school,
      "Spor": Icons.fitness_center,
      "Tamirat": Icons.build,
      "Araç Bakım": Icons.car_repair,
      "Sağlık": Icons.health_and_safety,
      "Teknoloji": Icons.computer,
      "Kişisel Gelişim": Icons.self_improvement,
      "Sanat": Icons.brush,
      "Yazılım": Icons.code,
      "Diğer": Icons.local_offer,
    };

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "⭐ Popüler Kategoriler",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: sorted.take(5).map((entry) {
                  final icon = categoryIcons[entry.key] ?? Icons.local_offer;
                  return GestureDetector(
                    onTap: () {
                      // kategoriye göre filtreleme yapılabilir
                    },
                    child: Chip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: primaryColor.withOpacity(0.15),
                      avatar: Icon(icon, size: 18, color: Colors.deepOrange),
                      label: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
