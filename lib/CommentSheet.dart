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
  final _commentController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;
  static const _maxLen = 140;

  // ─── Yorum ekle ─────────────────────────────────────────────────────
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _user == null) return;

    final uDoc = await FirebaseFirestore.instance
        .collection('users').doc(_user!.uid).get();

    final postRef = FirebaseFirestore.instance
        .collection('posts').doc(widget.post['id']);

    await postRef.collection('comments').add({
      'text'           : text,
      'authorId'       : _user!.uid,
      'authorName'     : uDoc['username'] ?? 'Kullanıcı',
      'authorPhotoUrl' : uDoc['photoUrl'] ?? '',
      'date'           : FieldValue.serverTimestamp(),
      'likes'          : 0,
      'likedBy'        : [],
    });

    await postRef.update({'commentsCount': FieldValue.increment(1)});
    _commentController.clear();
    setState(() {});                // karakter sayacını sıfırla
  }

  Future<void> _toggleLike(
      DocumentReference ref, List likedBy) async {

    final uid = _user?.uid;
    if (uid == null) return;

    final isLiked = likedBy.contains(uid);
    await ref.update({
      'likes'   : FieldValue.increment(isLiked ? -1 : 1),
      'likedBy' : isLiked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  // ─── Çerçeve rengi ───────────────────────────────────────────────────
  OutlineInputBorder _border(Color c) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(20),
          borderSide  : BorderSide(color: c, width: 2));

  @override
  Widget build(BuildContext context) {
    // kalan karakter
    final remain = _maxLen - _commentController.text.length;
    final Color frameColor = remain >= 60  // yeşil  (≥ 60)
        ? Colors.green
        : (remain >= 20 ? Colors.amber : Colors.red);  // sarı 20-59, kırmızı < 20

    return SafeArea(  // klavyeyi hesaba kat
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
            right: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(      // yüksekliği ekrana göre ayarlar
          heightFactor: .80,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Yorumlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),

              // ── Yorum listesi ──
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post['id'])
                      .collection('comments')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Henüz yorum yok.'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d        = docs[i];
                        final c        = d.data() as Map<String, dynamic>;
                        final likedBy  = List<String>.from(c['likedBy'] ?? []);
                        final isLiked  = _user != null && likedBy.contains(_user!.uid);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (c['authorPhotoUrl'] ?? '')
                                    .toString()
                                    .startsWith('assets/')
                                    ? AssetImage(c['authorPhotoUrl'])
                                    : (c['authorPhotoUrl'] ?? '').isNotEmpty
                                    ? NetworkImage(c['authorPhotoUrl'])
                                    : null,
                                child: (c['authorPhotoUrl'] ?? '').isEmpty
                                    ? const Icon(Icons.person, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  direction: Axis.vertical,
                                  spacing: 2,
                                  children: [
                                    Text(c['authorName'] ?? 'Kullanıcı',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(c['text'] ?? ''),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? Colors.orange
                                            : Colors.grey,
                                        size: 18),
                                    onPressed: () =>
                                        _toggleLike(d.reference, likedBy),
                                  ),
                                  Text('${c['likes'] ?? 0}',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Yorum girişi ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: TextField(
                  controller: _commentController,
                  maxLength: _maxLen,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    counterText: '$remain',
                    hintText   : 'Yorum yaz...',
                    filled     : true,
                    fillColor  : Colors.grey.shade100,
                    enabledBorder  : _border(frameColor),
                    focusedBorder  : _border(frameColor),
                    errorBorder    : _border(Colors.red),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.orange.shade600,
                      onPressed: remain < 0 ? null : _addComment,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

