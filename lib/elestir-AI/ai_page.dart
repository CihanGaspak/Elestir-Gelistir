import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AiChatWidget.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  String? _photoUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _photoUrl = data?['photoUrl'] ?? '';
          _username = data?['username'] ?? 'Ben';
        });
      }
    } catch (e) {
      print('❌ Fotoğraf yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('eleştir-AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: (_username == null)
          ? const Center(child: CircularProgressIndicator()) // 💡 İlk yüklenirken spinner göster
          : AiChatWidget(
        userPhotoUrl: _photoUrl,
        username: _username,
      ),
    );
  }
}
