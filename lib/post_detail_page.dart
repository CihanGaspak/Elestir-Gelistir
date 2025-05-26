import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'CommentSheet.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late DocumentReference postRef;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final Color primaryColor = Colors.orange.shade600;

  int views = 0;
  int likeCount = 0;
  List<String> likedBy = [];
  List<String> savedBy = [];
  List<Map<String, dynamic>> comments = [];
  List<TextEditingController> stepNoteControllers =
      List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post['id']);
    _incrementViews();
    _fetchPostData();
    _loadComments();
  }

  Future<void> _incrementViews() async {
    await postRef.update({'views': FieldValue.increment(1)});
    final snapshot = await postRef.get();
    if (snapshot.exists) {
      setState(() {
        views = (snapshot.data() as Map<String, dynamic>)['views'] ?? 0;
      });
    }
  }

  Future<void> _fetchPostData() async {
    final snapshot = await postRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        likeCount = data['likesCount'] ?? 0;
        likedBy = List<String>.from(data['likedBy'] ?? []);
        savedBy = List<String>.from(data['savedBy'] ?? []);
        stepNoteControllers[0].text = data['step1Note'] ?? '';
        stepNoteControllers[1].text = data['step2Note'] ?? '';
        stepNoteControllers[2].text = data['step3Note'] ?? '';
      });
    }
  }

  Future<void> _loadComments() async {
    final query = await postRef
        .collection('comments')
        .orderBy('date', descending: true)
        .get();
    setState(() {
      comments = query.docs.map((doc) {
        final c = doc.data();
        c['id'] = doc.id;
        return c;
      }).toList();
    });
  }

  Future<void> _toggleCommentLike(
      String commentId, List<String> likedBy) async {
    if (currentUserId == null) return;
    final ref = postRef.collection('comments').doc(commentId);
    final isLiked = likedBy.contains(currentUserId);
    await ref.update({
      'likedBy': isLiked
          ? FieldValue.arrayRemove([currentUserId])
          : FieldValue.arrayUnion([currentUserId])
    });
    _loadComments();
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return '${difference.inSeconds} saniye önce';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dakika önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    if (difference.inDays < 30)
      return '${(difference.inDays / 7).floor()} hafta önce';
    if (difference.inDays < 365)
      return '${(difference.inDays / 30).floor()} ay önce';
    return '${(difference.inDays / 365).floor()} yıl önce';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorId = post['authorId'] ?? '';
    final isOwner = currentUserId == authorId;
    final content = post['content']?.toString().trim() ?? '';
    final category = post['category']?.toString().capitalize() ?? '';
    final step = post['progressStep'] ?? 0;
    final timestamp = post['date'] as Timestamp?;

    final isLiked = currentUserId != null && likedBy.contains(currentUserId);
    final isSaved = currentUserId != null && savedBy.contains(currentUserId);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Gönderi Detayı'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
                builder: (context, snapshot) {
                  String displayName = 'Kullanıcı';
                  String photoUrl = 'assets/avatar0.png';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    displayName = userData['username'] ?? 'Kullanıcı';
                    photoUrl = userData['photoUrl'] ?? 'assets/avatar0.png';

                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: photoUrl.startsWith('assets/')
                            ? AssetImage(photoUrl) as ImageProvider
                            : NetworkImage(photoUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            if (timestamp != null)
                              Text(
                                timeAgo(timestamp.toDate()),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: List.generate(3, (i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(
                                    _getStepIcon(i),
                                    size: 20,
                                    color: i <= step ? Colors.orange : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(_getCategoryIcon(category), color: Colors.black, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  category,
                                  style: const TextStyle(fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAction(
                    isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    likeCount.toString(),
                    () async {
                      if (currentUserId == null) return;
                      final isAlreadyLiked = likedBy.contains(currentUserId);
                      final update = isAlreadyLiked
                          ? {
                              'likesCount': FieldValue.increment(-1),
                              'likedBy': FieldValue.arrayRemove([currentUserId])
                            }
                          : {
                              'likesCount': FieldValue.increment(1),
                              'likedBy': FieldValue.arrayUnion([currentUserId])
                            };
                      await postRef.update(update);
                      _fetchPostData();
                    },
                    isLiked,
                  ),
                  _buildAction(
                    Icons.comment_outlined,
                    comments.length.toString(),
                    () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CommentSheet(post: widget.post),
                      ).then((_) async {
                        await _loadComments();
                        setState(() {}); // 👈 Bu satırı ekle
                      });
                      // yorumdan sonra listeyi yenile
                    },
                  ),
                  _buildAction(
                    Icons.share_outlined,
                    ' ',
                    () {
                      final shareText = content.trim().isEmpty
                          ? 'Eleştir-Geliştir uygulamasındaki bir gönderiye göz at!'
                          : content;
                      Share.share(shareText); // ← içeriği paylaş
                    },
                  ),
                  _buildAction(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    ' ',
                    () async {
                      if (currentUserId == null) return;
                      final update = isSaved
                          ? {
                              'savedBy': FieldValue.arrayRemove([currentUserId])
                            }
                          : {
                              'savedBy': FieldValue.arrayUnion([currentUserId])
                            };
                      await postRef.update(update);
                      _fetchPostData();
                    },
                    isSaved,
                  ),
                  _buildAction(
                    Icons.remove_red_eye_outlined,
                    views.toString(),
                    () {}, // Görüntüleme pasif; sadece sayıyı gösteriyor
                    false,
                  ),
                ],
              ),
              const Divider(height: 32),
              Column(
                children: List.generate(3, (i) {
                  final reached = step >= i;
                  final isCurrent = step == i;

                  final stageTitles = ['Eleştir', 'Düşündür', 'Geliştir'];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    [
                                      Icons.lightbulb,
                                      Icons.build,
                                      Icons.check_circle
                                    ][i],
                                    color: reached
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reached
                                        ? stageTitles[i]
                                        : 'Henüz bu aşamaya geçilmedi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          reached ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              if (isOwner && reached)
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 20, color: Colors.orange),
                                  onPressed: () async {
                                    final newNote = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final controller =
                                            TextEditingController(
                                                text: stepNoteControllers[i]
                                                    .text);
                                        return AlertDialog(
                                          title: Text(
                                              '${stageTitles[i]} Notunu Düzenle'),
                                          content: TextField(
                                            controller: controller,
                                            maxLines: null,
                                            decoration: const InputDecoration(
                                                hintText: 'Notunuzu girin...'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('İptal'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context,
                                                  controller.text.trim()),
                                              child: const Text('Kaydet'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (newNote != null) {
                                      final field = 'step${i + 1}Note';
                                      await postRef.update({
                                        field: newNote,
                                        'progressStep': newNote.isEmpty
                                            ? i
                                            : (i + 1 > 2 ? 3 : i + 1),
                                      });
                                      _fetchPostData();
                                      setState(() =>
                                          widget.post['progressStep'] =
                                              newNote.isEmpty
                                                  ? i
                                                  : (i + 1 > 2 ? 3 : i + 1));
                                    }
                                  },
                                ),
                            ],
                          ),
                          if (reached && stepNoteControllers[i].text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                stepNoteControllers[i].text,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const Divider(height: 32),
              const Text("Yorumlar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final c = comments[index];
                  final authorId = c['authorId'] ?? '';
                  final likedBy = List<String>.from(c['likedBy'] ?? []);
                  final isLiked =
                      currentUserId != null && likedBy.contains(currentUserId);
                  final timestamp = c['date'] as Timestamp?;
                  final dateStr =
                      timestamp != null ? timeAgo(timestamp.toDate()) : '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(authorId)
                        .get(),
                    builder: (context, snapshot) {
                      String photoUrl = '';
                      String displayName = 'Kullanıcı';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        photoUrl = userData['photoUrl'] ?? '';
                        displayName = userData['username'] ?? 'Kullanıcı';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: photoUrl
                                          .startsWith('assets/')
                                      ? AssetImage(photoUrl) as ImageProvider
                                      : (photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : const AssetImage(
                                                  'assets/avatar0.png')
                                              as ImageProvider),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName ?? 'Kullanıcı',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c['text'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: GestureDetector(
                                onTap: () =>
                                    _toggleCommentLike(c['id'], likedBy),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${likedBy.length}',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap,
      [bool active = false]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: active ? Colors.orange : Colors.black),
          if (label.isNotEmpty) Text(label),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tümü':
        return Icons.all_inclusive;
      case 'eğitim':
        return Icons.school;
      case 'spor':
        return Icons.fitness_center;
      case 'tamirat':
        return Icons.build;
      case 'araç bakım':
        return Icons.car_repair;
      case 'sağlık':
        return Icons.health_and_safety;
      case 'teknoloji':
        return Icons.computer;
      case 'kişisel gelişim':
        return Icons.self_improvement;
      case 'sanat':
        return Icons.brush;
      case 'yazılım':
        return Icons.code;
      default:
        return Icons.category;
    }
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
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? '' : this[0].toUpperCase() + substring(1).toLowerCase();
}
