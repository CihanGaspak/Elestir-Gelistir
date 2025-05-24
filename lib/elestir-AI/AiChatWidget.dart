import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatBubble.dart';
import 'gemini_service.dart';

class AiChatWidget extends StatefulWidget {
  final String? userPhotoUrl;
  final String? username;
  final String? existingChatId;
  final bool chatStarted;

  const AiChatWidget({
    super.key,
    this.userPhotoUrl,
    this.username,
    this.existingChatId,
    this.chatStarted = false,
  });

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  String? _chatId;
  bool _chatStarted = false;

  String? _selectedCategory;
  final Map<String, List<String>> _suggestions = {
    "Eğitim": [
      "Verimli ders çalışmak için ne yapmalıyım?",
      "Öğrenciler için zaman yönetimi nasıl olmalı?",
      "Online eğitim faydalı mı?"
    ],
    "Spor": [
      "Kas yapmak için ne yemeliyim?",
      "Evde spor programı önerir misin?",
      "Spor sakatlıkları nasıl önlenir?"
    ],
    "Tamirat": [
      "Musluk sızıntısı nasıl giderilir?",
      "Kendi priz tamirimi yapabilir miyim?",
      "Evin duvarındaki çatlak tehlikeli mi?"
    ],
    "Araç Bakım": [
      "Yağ değişimi ne sıklıkla yapılır?",
      "Araba aküsü nasıl kontrol edilir?",
      "Kışın araca nasıl bakım yapılır?"
    ],
    "Sağlık": [
      "Gripten korunmak için ne yapmalıyım?",
      "Daha enerjik hissetmek için ne yemeliyim?",
      "Göz yorgunluğu nasıl geçer?"
    ],
    "Teknoloji": [
      "Yeni telefon alırken nelere dikkat etmeliyim?",
      "Bilgisayarım yavaşladı, ne yapabilirim?",
      "Yapay zekâ hayatımızı nasıl etkiliyor?"
    ],
    "Kişisel Gelişim": [
      "Özgüven nasıl artırılır?",
      "Sabah rutini neden önemlidir?",
      "Hedef belirleme nasıl yapılır?"
    ],
    "Sanat": [
      "Resme nereden başlamalıyım?",
      "Yaratıcılığı artırmak için ne yapılır?",
      "Sanat terapisi nedir?"
    ],
    "Yazılım": [
      "Yazılım öğrenmeye nereden başlanır?",
      "Frontend ve Backend farkı nedir?",
      "Hangi programlama dili bana uygun?"
    ]
  };

  @override
  @override
  void initState() {
    super.initState();
    _chatStarted = widget.chatStarted;
    _chatId = widget.existingChatId;

    if (_chatStarted && _chatId != null) {
      _loadPreviousMessages(); // 🔥 Geçmiş mesajları yükle
    } else {
      _addWelcomeMessage(); // 🔸 Yeni sohbette hoş geldin mesajı
    }
  }

  Future<void> _loadPreviousMessages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _chatId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(_chatId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> rawMessages = data?['messages'] ?? [];

        setState(() {
          messages.clear();
          messages.addAll(rawMessages.map<Map<String, String>>((e) {
            return {
              'role': e['role'] ?? '',
              'text': e['text'] ?? '',
            };
          }));
        });

        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Geçmiş mesajlar yüklenemedi: $e');
    }
  }


  void _addWelcomeMessage() {
    final name = widget.username;
    messages.add({
      "role": "ai",
      "text": "Merhaba <b>${name ?? 'Kullanıcı'}</b> Ben <b>eleştir-AI 🤖</b>.<br>Size nasıl yardımcı olabilirim?"
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      messages.add({"role": "ai", "text": "..."});
      isTyping = true;
      _selectedCategory = null;
    });

    _controller.clear();
    _scrollToBottom();

    final aiResponse = await GeminiService.getResponse(text);

    setState(() {
      messages[messages.length - 1] = {"role": "ai", "text": aiResponse};
      isTyping = false;
    });
    _scrollToBottom();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      if (!_chatStarted) {
        _chatId = DateTime.now().millisecondsSinceEpoch.toString();
        _chatStarted = true;

        final title = text.split(" ").take(6).join(" ");
        final chatRef = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("chats")
            .doc(_chatId);

        await chatRef.set({
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
          'messages': [
            {"role": "user", "text": text},
            {"role": "ai", "text": aiResponse}
          ]
        });
      } else {
        final chatRef = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("chats")
            .doc(_chatId);

        await chatRef.update({
          'messages': FieldValue.arrayUnion([
            {"role": "user", "text": text},
            {"role": "ai", "text": aiResponse}
          ])
        });
      }
    } catch (e) {
      print("❌ Firestore'a sohbet kaydedilemedi: $e");
    }
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

    return Column(
      children: [
        if (!_chatStarted && _selectedCategory == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Kategori seçin',
                labelStyle: const TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFFFFE0B2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFFB8C00), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFFB8C00), width: 2),
                ),
              ),
              dropdownColor: const Color(0xFFFFF3E0),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE65100)),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              items: _suggestions.keys.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),

        if (!_chatStarted && _selectedCategory != null && _suggestions[_selectedCategory] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions[_selectedCategory]!.map((soru) {
                return ActionChip(
                  label: Text(
                    soru,
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFFFFE0B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    _controller.text = soru;
                    setState(() {
                      _selectedCategory = null;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _sendMessage();
                    });
                  },
                );
              }).toList(),
            ),
          ),

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
                userPhotoUrl: widget.userPhotoUrl,
                isTyping: isTypingBubble,
                username: isUser ? (widget.username ?? 'Ben') : 'Eleştir-AI 🤖',
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
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
