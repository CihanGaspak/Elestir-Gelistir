import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Color primaryColor = const Color(0xFFFF944D);
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<bool> _expandedSteps = [false, false, false];

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'];
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    return StreamBuilder<DocumentSnapshot>(
      stream: postRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final likeCount = data['likesCount'] ?? 0;
        final commentCount = data['commentsCount'] ?? 0;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final isLiked = currentUserId != null && likedBy.contains(currentUserId);
        final content = data['content'] ?? '';
        final author = data['authorName'] ?? 'Kullanıcı';
        final timestamp = data['date'];
        final dateStr = timestamp != null
            ? (timestamp as Timestamp).toDate().toLocal().toString().split('.')[0]
            : '';
        final step = data['progressStep'] ?? 0;

        final List<String> stepNotes = [
          data['step1Note'] ?? '',
          data['step2Note'] ?? '',
          data['step3Note'] ?? ''
        ];

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(author, dateStr, step),
                const SizedBox(height: 12),
                Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLikeButton(postRef, likeCount, likedBy, isLiked),
                    _buildCommentButton(commentCount),
                    _buildShareButton(content),
                  ],
                ),
                ExpansionPanelList(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _expandedSteps[index] = !_expandedSteps[index];
                    });
                  },
                  children: List.generate(3, (i) {
                    final bool isReached = step >= i;
                    final noteField = 'step${i + 1}Note';

                    return ExpansionPanel(
                      backgroundColor: Colors.white,
                      isExpanded: _expandedSteps[i],
                      canTapOnHeader: true,
                      headerBuilder: (context, isOpen) {
                        return ListTile(
                          leading: Icon(
                            _getStepIcon(i),
                            color: isReached ? primaryColor : Colors.grey.shade300,
                          ),
                          title: Text(
                            isReached ? "Aşama ${i + 1}" : "Henüz bu aşama değil",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isReached ? primaryColor : Colors.grey,
                            ),
                          ),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: isReached
                            ? currentUserId == widget.post['authorId']
                            ? TextFormField(
                          initialValue: stepNotes[i],
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Notunuzu girin...',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (val) {
                            postRef.update({noteField: val});
                          },
                        )
                            : Text(
                          stepNotes[i].isEmpty
                              ? "Henüz not girilmemiş."
                              : stepNotes[i],
                          style: const TextStyle(fontSize: 14),
                        )
                            : const Text(
                          "Henüz bu aşamaya geçilmedi.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.lightbulb_outline;
      case 1:
        return Icons.build_circle_outlined;
      case 2:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildHeader(String author, String dateStr, int step) {
    final authorId = widget.post['authorId'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, snapshot) {
        String photoUrl = '';
        if (snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['photoUrl'] ?? '';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: photoUrl.startsWith('assets/')
                  ? AssetImage(photoUrl)
                  : NetworkImage(photoUrl) as ImageProvider,
              child: photoUrl.isEmpty
                  ? Text(
                author.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    _getStepIcon(i),
                    size: 18,
                    color: i <= step ? primaryColor : Colors.grey.shade300,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }



  Widget _buildLikeButton(
      DocumentReference postRef,
      int likeCount,
      List<String> likedBy,
      bool isLiked,
      ) {
    return GestureDetector(
      onTap: () async {
        if (currentUserId == null) return;
        final update = isLiked
            ? {
          'likesCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId])
        }
            : {
          'likesCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId])
        };
        await postRef.update(update);
      },
      child: Row(
        children: [
          Icon(
            isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: isLiked ? primaryColor : Colors.black,
          ),
          const SizedBox(width: 4),
          Text('$likeCount'),
        ],
      ),
    );
  }

  Widget _buildCommentButton(int commentCount) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => CommentSheet(post: widget.post),
      ),
      child: Row(
        children: [
          const Icon(Icons.comment_outlined, color: Colors.black),
          const SizedBox(width: 4),
          Text('$commentCount'),
        ],
      ),
    );
  }

  Widget _buildShareButton(String content) {
    return GestureDetector(
      onTap: () => Share.share(content),
      child: const Row(
        children: [
          Icon(Icons.share_outlined, color: Colors.black),
          SizedBox(width: 4),
          Text("Paylaş"),
        ],
      ),
    );
  }
}
