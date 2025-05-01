import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const CommentSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final username = userDoc['username'] ?? 'Kullanıcı';
    final photoUrl = userDoc['photoUrl'] ?? '';

    final newComment = {
      'text': text,
      'authorId': user!.uid,
      'authorName': username,
      'authorPhotoUrl': photoUrl,
      'date': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
    };

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post['id']);

    await postRef.collection('comments').add(newComment);

    // Yorum sayısını artır
    await postRef.update({'commentsCount': FieldValue.increment(1)});

    // En son input temizlenir
    _commentController.clear();
  }

  Future<void> _toggleLike(DocumentReference commentRef, List likedBy, int likes) async {
    final uid = user?.uid;
    if (uid == null) return;

    final isLiked = likedBy.contains(uid);

    await commentRef.update({
      'likes': FieldValue.increment(isLiked ? -1 : 1),
      'likedBy': isLiked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post['id'])
                    .collection('comments')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return const Center(child: Text("Henüz yorum yok."));
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final doc = comments[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final likedBy = List<String>.from(data['likedBy'] ?? []);
                      final isLiked = user != null && likedBy.contains(user!.uid);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['authorName'] ?? 'Anonim',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(data['text']),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.orange : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleLike(doc.reference, likedBy, data['likes']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text('${data['likes'] ?? 0}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  hintText: "Yorum yaz...",
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send, color: Colors.orange.shade600),
                    onPressed: _addComment,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
