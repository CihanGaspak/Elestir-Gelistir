import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? userPhotoUrl;
  final bool isTyping;
  final String? username;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.userPhotoUrl,
    this.isTyping = false,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/avatars/elestir-AI.png'),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: isUser
                ? _buildUserBubble()
                : ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 300),
              child: _buildAiBubble(),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 16,
              backgroundImage: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                  ? (userPhotoUrl!.startsWith('assets/')
                  ? AssetImage(userPhotoUrl!)
                  : NetworkImage(userPhotoUrl!)) as ImageProvider
                  : const AssetImage('assets/avatars/avatar11.png'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (username != null)
            Text(
              username!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          isTyping
              ? TweenAnimationBuilder<int>(
            tween: IntTween(begin: 1, end: 3),
            duration: const Duration(seconds: 1),
            builder: (_, value, __) => Text('.' * value, style: const TextStyle(fontSize: 20)),
          )
              : Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (username != null)
            Text(
              username!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          isTyping
              ? TweenAnimationBuilder<int>(
            tween: IntTween(begin: 1, end: 3),
            duration: const Duration(seconds: 1),
            builder: (_, value, __) => Text('.' * value, style: const TextStyle(fontSize: 20)),
          )
              : Html(
            data: text,
            style: {
              "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero, fontSize: FontSize(14)),
              "ul": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              "li": Style(margin: Margins.zero, padding: HtmlPaddings.only(left: 0), fontWeight: FontWeight.bold),
            },
          ),
        ],
      ),
    );
  }
}
