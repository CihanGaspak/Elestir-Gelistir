import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'CommentSheet.dart';
import 'post_detail_page.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({required this.post, super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final Color primaryColor = Colors.orange.shade600;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<bool> _expandedSteps = [false, false, false];
  String _compact(int n) => NumberFormat.compact(locale: 'tr_TR').format(n);

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return '${difference.inSeconds} saniye önce';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dakika önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} hafta önce';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} ay önce';
    return '${(difference.inDays / 365).floor()} yıl önce';
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'] ?? '';
    if (postId == '') return const SizedBox();

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    return StreamBuilder<DocumentSnapshot>(
      stream: postRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final likeCount = data['likesCount'] ?? 0;
        final commentCount = data['commentsCount'] ?? 0;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final savedBy = List<String>.from(data['savedBy'] ?? []);
        final isLiked = currentUserId != null && likedBy.contains(currentUserId);
        final isSaved = currentUserId != null && savedBy.contains(currentUserId);

        final content = data['content'] ?? '';
        final author = data['authorName'] ?? 'Kullanıcı';
        final timestamp = data['date'] as Timestamp?;
        final step = data['progressStep'] ?? 0;

        final List<String> stepNotes = [
          data['step1Note'] ?? '',
          data['step2Note'] ?? '',
          data['step3Note'] ?? ''
        ];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailPage(post: widget.post),
              ),
            );
          },
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(author, timestamp, step),
                  const SizedBox(height: 12),
                  Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLikeButton(postRef, likeCount, likedBy, isLiked),
                      _buildCommentButton(commentCount),
                      _buildShareButton(content),
                      _buildSaveButton(postRef, isSaved),
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
                      return ExpansionPanel(
                        backgroundColor: Colors.white,
                        isExpanded: _expandedSteps[i],
                        canTapOnHeader: true,
                        headerBuilder: (context, isOpen) {
                          const stageTitles = ['Eleştir', 'Düşündür', 'Geliştir'];
                          return ListTile(
                            leading: Icon(
                              [Icons.lightbulb, Icons.build, Icons.check_circle][i],
                              color: isReached ? Colors.orange : Colors.grey.shade300,
                            ),
                            title: Text(
                              isReached ? stageTitles[i] : 'Henüz bu aşamaya geçilmedi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isReached ? Colors.black : Colors.grey,
                              ),
                            ),
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: () {
                            final reached = step >= i;
                            final note = stepNotes[i].toString().trim();

                            if (!reached) {
                              return const Text('Henüz bu aşamaya geçilmedi.',
                                  style: TextStyle(color: Colors.grey));
                            }
                            if (note.isEmpty) {
                              return const Text('Henüz not girilmemiş.',
                                  style: TextStyle(color: Colors.grey));
                            }
                            return Text(note, style: const TextStyle(fontSize: 14));
                          }(),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String author, Timestamp? timestamp, int step) {
    final authorId = widget.post['authorId'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, snapshot) {
        String photoUrl = '';
        String displayName = 'Kullanıcı';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['photoUrl'] ?? '';
          displayName = data['username'] ?? 'Kullanıcı';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: photoUrl.isNotEmpty
                  ? (photoUrl.startsWith('assets/')
                  ? AssetImage(photoUrl)
                  : NetworkImage(photoUrl)) as ImageProvider
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                displayName.substring(0, 1).toUpperCase(),
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
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    timestamp != null ? timeAgo(timestamp.toDate()) : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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

  Widget _buildShareButton(String content) {
    return GestureDetector(
      onTap: () => Share.share(content),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.share_outlined, color: Colors.black),
          const SizedBox(height: 4),
          Text(" "),
        ],
      ),
    );
  }

  Widget _buildLikeButton(
      DocumentReference postRef, int likeCount, List<String> likedBy, bool isLiked) {
    return GestureDetector(
      onTap: () async {
        if (currentUserId == null) return;
        await postRef.update(
          isLiked
              ? {
            'likesCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([currentUserId])
          }
              : {
            'likesCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([currentUserId])
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
            color: isLiked ? primaryColor : Colors.black,
          ),
          const SizedBox(height: 4),
          Text(_compact(likeCount)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.comment_outlined, color: Colors.black),
          const SizedBox(height: 4),
          Text(_compact(commentCount)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(DocumentReference postRef, bool isSaved) {
    return GestureDetector(
      onTap: () async {
        if (currentUserId == null) return;
        await postRef.update(
          isSaved
              ? {'savedBy': FieldValue.arrayRemove([currentUserId])}
              : {'savedBy': FieldValue.arrayUnion([currentUserId])},
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_outline,
            color: isSaved ? primaryColor : Colors.black,
          ),
          const SizedBox(height: 4),
          Text(" "),
        ],
      ),
    );
  }
}
