import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ChatBubble.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final List<Map<String, String>> messages = [
    {"role": "ai", "text": "Merhaba 👋 Ben Eleştir-AI.\nSize nasıl yardımcı olabilirim?"},
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
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
        print('✅ Firestore fotoğraf URL: $_photoUrl');
      } else {
        print('⚠️ Firestore user doc bulunamadı.');
      }
    } catch (e) {
      print('❌ Fotoğraf yükleme hatası: $e');
    }
  }

  Future<String> getGeminiResponse(String prompt) async {
    const apiKey = 'AIzaSyBHgfTUPyIBbayKiYQ-LCBb4GLiDGp4370';
    const model = 'gemini-2.0-flash';

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? '⚠️ Boş cevap döndü.';
      } else if (response.statusCode == 429) {
        return '🚫 Aylık kota sınırına ulaştınız.';
      } else {
        return '❌ Hata ${response.statusCode}: ${response.reasonPhrase}\n\n${response.body}';
      }
    } catch (e) {
      return '❌ İstek sırasında hata: $e';
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      messages.add({"role": "ai", "text": "..."});
      isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final aiResponse = await getGeminiResponse(text);

    setState(() {
      messages[messages.length - 1] = {"role": "ai", "text": aiResponse};
      isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eleştir-AI', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";
                final isTypingBubble = msg["text"] == "...";

                return ChatBubble(
                  text: msg["text"] ?? '',
                  isUser: isUser,
                  userPhotoUrl: _photoUrl,
                  isTyping: isTypingBubble,
                  username: isUser ? (_username ?? 'Ben') : 'Eleştir-AI',
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 8,
              right: 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}