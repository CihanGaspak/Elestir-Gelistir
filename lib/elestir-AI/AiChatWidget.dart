import 'dart:async';
import 'package:flutter/material.dart';
import 'ChatBubble.dart';
import 'gemini_service.dart'; // Servisi ayırmıştın, burada çağırılıyor.

class AiChatWidget extends StatefulWidget {
  final String? userPhotoUrl;
  final String? username;

  const AiChatWidget({super.key, this.userPhotoUrl, this.username});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final name = widget.username;
    print('✅ AIChatWidget username: $name');
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
    });
    _controller.clear();
    _scrollToBottom();

    final aiResponse = await GeminiService.getResponse(text);

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

    return Column(
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
                      borderSide: const BorderSide(color: Colors.orange, width: 1.5), // Dış ince turuncu çizgi
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.orange, width: 2), // Odaklanınca biraz kalınlaşabilir
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
