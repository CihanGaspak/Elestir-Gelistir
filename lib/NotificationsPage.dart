import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Giriş yapılmamış.")),
      );
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('time', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Bir hata oluştu."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz bir bildirimin yok."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final iconName = data['icon'] ?? 'notifications';
              final title = data['title'] ?? 'Bildirim';
              final timestamp = data['time'];
              String timeStr = '';

              if (timestamp is Timestamp) {
                timeStr = DateFormat('dd MMM yyyy • HH:mm', 'tr_TR').format(timestamp.toDate());
              }

              print('📬 Bildirim: $title / $timeStr');

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(_mapIcon(iconName), color: Colors.white),
                  ),
                  title: Text(title),
                  subtitle: Text(timeStr),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Bildirime tıklanınca detay ekranı olabilir.
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _mapIcon(String iconName) {
    switch (iconName) {
      case "person_add":
        return Icons.person_add;
      case "thumb_up":
        return Icons.thumb_up;
      case "comment":
        return Icons.comment;
      case "lock":
        return Icons.lock;
      default:
        return Icons.notifications;
    }
  }
}
