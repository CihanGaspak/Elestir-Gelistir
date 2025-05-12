import 'package:flutter/material.dart';

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
    final Color userBubbleColor = Colors.grey.shade200; // Kullanıcı mesajları gri
    final Color aiBubbleColor = Colors.orange.shade50;  // AI mesajları açık turuncu

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/avatars/avatar0.png'),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (username != null)
                    Text(
                      username!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUser ? Colors.blueGrey : Colors.orange.shade600,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  isTyping
                      ? TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 1, end: 3),
                    duration: const Duration(seconds: 1),
                    builder: (_, value, __) => Text('.' * value, style: const TextStyle(fontSize: 20)),
                    onEnd: () {},
                  )
                      : Text(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
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
}
