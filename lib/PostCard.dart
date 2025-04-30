import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'CommentSheet.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({required this.post, super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late bool isLiked;

  final Color primaryColor = Color(0xFFFF944D); // Turuncu

  @override
  void initState() {
    super.initState();
    likeCount = widget.post["likes"];
    isLiked = false;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void showComments() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CommentSheet(post: widget.post),
    );
  }

  void sharePost() {
    final postText = widget.post["text"];
    Share.share(postText ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(post),
            const SizedBox(height: 12),
            Text(
              post["text"] ?? "",
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            if (post.containsKey("image") && post["image"].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  post["image"],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildActions(post),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> post) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            (post["username"] ?? "U").substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post["username"] ?? "Kullanıcı",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                post["date"] ?? "",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        _buildProgress(post),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            // Menü işlemleri burada olacak
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "edit",
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Düzenle'),
              ),
            ),
            const PopupMenuItem(
              value: "delete",
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Sil'),
              ),
            ),
            const PopupMenuItem(
              value: "report",
              child: ListTile(
                leading: Icon(Icons.report_problem, size: 20, color: Colors.orange),
                title: Text('Şikayet Et'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgress(Map<String, dynamic> post) {
    final int currentStep = int.tryParse(post["progressStep"].toString()) ?? 0;

    List<IconData> stepIcons = [
      Icons.help_outline,
      Icons.autorenew,
      Icons.check_circle_outline,
    ];

    return Row(
      children: List.generate(3, (index) {
        bool isActive = index <= currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            stepIcons[index],
            size: 18,
            color: isActive ? primaryColor : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildActions(Map<String, dynamic> post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAction(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          label: '$likeCount',
          color: isLiked ? primaryColor : Colors.black,
          onTap: toggleLike,
        ),
        _buildAction(
          icon: Icons.comment_outlined,
          label: '${post["commentList"].length}',
          color: Colors.black,
          onTap: showComments,
        ),
        _buildAction(
          icon: Icons.share_outlined,
          label: '${post["shares"]}',
          color: Colors.black,
          onTap: sharePost,
        ),
      ],
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
