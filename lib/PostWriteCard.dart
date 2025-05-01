import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostWrite extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String text, String category) onPost;
  const PostWrite({Key? key, required this.controller, required this.onPost})
      : super(key: key);

  @override
  State<PostWrite> createState() => _PostWriteState();
}

class _PostWriteState extends State<PostWrite> {
  /* ─────── Sabitler & Durum ─────── */
  static const _maxLen = 280;
  int  remaining       = _maxLen;
  bool isPosting       = false;
  String selectedCategory = 'Eğitim';
  String? username, photoUrl;

  /* Kategoriler */
  final categories = [
    {'name': 'Eğitim',          'icon': Icons.school},
    {'name': 'Spor',            'icon': Icons.fitness_center},
    {'name': 'Tamirat',         'icon': Icons.build},
    {'name': 'Araç Bakım',      'icon': Icons.car_repair},
    {'name': 'Sağlık',          'icon': Icons.health_and_safety},
    {'name': 'Teknoloji',       'icon': Icons.memory},
    {'name': 'Kişisel Gelişim', 'icon': Icons.psychology_alt},
    {'name': 'Sanat',           'icon': Icons.palette},
    {'name': 'Yazılım',         'icon': Icons.code},
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => remaining = _maxLen - widget.controller.text.length);
    });
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    setState(() {
      username = snap['username'] ?? u.email;
      photoUrl = snap['photoUrl'] ?? '';
    });
  }

  Future<void> _handlePost() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || text.length > _maxLen) return;
    setState(() => isPosting = true);
    await widget.onPost(text, selectedCategory);
    if (!mounted) return;
    setState(() {
      isPosting = false;
      widget.controller.clear();
      remaining = _maxLen;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    /* Renk mantığı */
    final frameColor = remaining >= 100
        ? Colors.green
        : remaining >= 40
        ? Colors.amber
        : Colors.red;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: 2),
    );

    final canSend =
        widget.controller.text.trim().isNotEmpty && remaining >= 0;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            /* —— İçerik Scroll ——————————————————————— */
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık + kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Yeni Gönderi',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedCategory,
                          items: categories
                              .map((cat) => DropdownMenuItem<String>(
                            value: cat['name'] as String,
                            child: Row(
                              children: [
                                Icon(cat['icon'] as IconData, size: 18),
                                const SizedBox(width: 6),
                                Text(cat['name'] as String),
                              ],
                            ),
                          ))
                              .toList(),
                          onChanged: (v) => setState(
                                  () => selectedCategory = v ?? selectedCategory),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kullanıcı
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.orange.shade100,
                          backgroundImage:
                          (photoUrl?.startsWith('assets/') ?? false)
                              ? AssetImage(photoUrl!) as ImageProvider
                              : (photoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: (photoUrl?.isEmpty ?? true)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(username ?? 'Kullanıcı',
                            style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Metin kutusu (daha yüksek)
                    TextField(
                      controller: widget.controller,
                      minLines: 6,
                      maxLines: 10,
                      maxLength: _maxLen,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Fikrini veya sorunu paylaş...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: border(frameColor),
                        focusedBorder: border(frameColor),
                        counterText: '',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$remaining / $_maxLen',
                        style: TextStyle(
                            fontSize: 12,
                            color: frameColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /* —— Paylaş Butonu ———————————————————— */
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: isPosting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: canSend ? _handlePost : null,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Paylaş',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSend
                        ? Colors.orange.shade600
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
