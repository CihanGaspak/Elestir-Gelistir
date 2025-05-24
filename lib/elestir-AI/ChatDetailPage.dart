// chat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatBubble.dart'; // Aynı baloncukları kullanalım

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String? username;
  final String? userPhotoUrl;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    this.username,
    this.userPhotoUrl,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final List<dynamic> rawMessages = data?['messages'] ?? [];

      setState(() {
        _messages = rawMessages.map<Map<String, String>>((e) {
          return {
            'role': e['role'] ?? '',
            'text': e['text'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('❌ Mesajlar yüklenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Sohbet'),
        backgroundColor: primaryColor,
      ),
      body: _messages.isEmpty
          ? const Center(child: Text('Sohbet boş'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isUser = msg['role'] == 'user';

          return ChatBubble(
            text: msg['text'] ?? '',
            isUser: isUser,
            isTyping: false,
            userPhotoUrl: isUser ? widget.userPhotoUrl : null,
            username: isUser ? widget.username ?? "Ben" : "Eleştir-AI 🤖",
          );
        },
      ),
    );
  }
}
