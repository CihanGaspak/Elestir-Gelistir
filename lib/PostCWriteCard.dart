import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostWrite extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String text, String category) onPost;

  const PostWrite({
    Key? key,
    required this.controller,
    required this.onPost,
  }) : super(key: key);

  @override
  State<PostWrite> createState() => _PostWriteState();
}

class _PostWriteState extends State<PostWrite> {
  /* ───────────────────────── STATE ───────────────────────── */
  String selectedCategory = 'Eğitim';
  bool   isPosting        = false;
  int    remaining        = 280;

  String? username;          // 👈 oturum açan kullanıcının adı
  String? photoUrl;          //    (isteğe bağlı)

  /* ───────────────────────── KATEGORİ LİSTESİ ────────────── */
  final categories = [
    {'name': 'Eğitim',     'icon': Icons.school},
    {'name': 'Spor',       'icon': Icons.fitness_center},
    {'name': 'Tamirat',    'icon': Icons.build},
    {'name': 'Araç Bakım', 'icon': Icons.car_repair},
  ];

  /* ───────────────────────── INIT ────────────────────────── */
  @override
  void initState() {
    super.initState();

    // karakter sayacı dinleyicisi
    widget.controller.addListener(() {
      setState(() => remaining = 280 - widget.controller.text.length);
    });

    // kullanıcı adını Firestore’dan çek
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      username  = snap['username'] ?? user.email;
      photoUrl  = snap['photoUrl'] ?? '';
    });
  }

  /* ───────────────────────── POST GÖNDER ─────────────────── */
  Future<void> handlePost() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || text.length > 280) return;

    setState(() => isPosting = true);
    await widget.onPost(text, selectedCategory);

    if (!mounted) return;
    setState(() {
      isPosting = false;
      widget.controller.clear();
      remaining = 280;
    });
    Navigator.pop(context);
  }

  /* ───────────────────────── UI ──────────────────────────── */
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Başlık + Kategori */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Yeni Gönderi',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedCategory,
                items: categories
                    .map<DropdownMenuItem<String>>(
                      (cat) => DropdownMenuItem<String>(
                    value: cat['name'] as String,
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 18),
                        const SizedBox(width: 6),
                        Text(cat['name'] as String),
                      ],
                    ),
                  ),
                )
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCategory = v ?? selectedCategory),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /* Kullanıcı bilgisi */
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.shade100,
                backgroundImage: (photoUrl != null && photoUrl!.startsWith('assets/'))
                    ? AssetImage(photoUrl!) as ImageProvider
                    : (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(username ?? 'Kullanıcı',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),

          /* Yazı alanı */
          TextField(
            controller: widget.controller,
            maxLines: 5,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: 'Fikrini veya sorunu paylaş...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          Align(
              alignment: Alignment.centerRight,
              child: Text('$remaining karakter kaldı',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                      remaining < 0 ? Colors.red : Colors.grey))),

          const SizedBox(height: 20),

          /* Gönder / yükleniyor */
          isPosting
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: remaining < 0 ? null : handlePost,
              icon: const Icon(Icons.send),
              label: const Text('Paylaş'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
