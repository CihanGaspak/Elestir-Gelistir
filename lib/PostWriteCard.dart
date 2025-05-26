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
  static const _maxLen = 280;
  int remaining = _maxLen;
  bool isPosting = false;
  String selectedCategory = 'Eğitim';
  String? username, photoUrl;

  final categories = [
    {'name': 'Eğitim', 'icon': Icons.school},
    {'name': 'Spor', 'icon': Icons.fitness_center},
    {'name': 'Tamirat', 'icon': Icons.build},
    {'name': 'Araç Bakım', 'icon': Icons.car_repair},
    {'name': 'Sağlık', 'icon': Icons.health_and_safety},
    {'name': 'Teknoloji', 'icon': Icons.memory},
    {'name': 'Kişisel Gelişim', 'icon': Icons.psychology_alt},
    {'name': 'Sanat', 'icon': Icons.palette},
    {'name': 'Yazılım', 'icon': Icons.code},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
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
    final frameColor = remaining >= 100
        ? Colors.green
        : remaining >= 40
        ? Colors.amber
        : Colors.red;

    final canSend = widget.controller.text.trim().isNotEmpty && remaining >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(0),

            child: Material(
              elevation: 4,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.orange.shade100,
                            backgroundImage: (photoUrl?.startsWith('assets/') ?? false)
                                ? AssetImage(photoUrl!) as ImageProvider
                                : (photoUrl?.isNotEmpty ?? false)
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: (photoUrl?.isEmpty ?? true)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              username ?? 'Kullanıcı',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          DropdownButton<String>(
                            value: selectedCategory,
                            items: categories
                                .map((cat) => DropdownMenuItem<String>(
                              value: cat['name'] as String,
                              child: Row(
                                children: [
                                  Icon(cat['icon'] as IconData, size: 18),
                                  const SizedBox(width: 4),
                                  Text(cat['name'] as String),
                                ],
                              ),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedCategory = v ?? selectedCategory),
                            underline: const SizedBox(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.controller,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: _maxLen,
                        onChanged: (_) => setState(() => remaining = _maxLen - widget.controller.text.length),
                        decoration: InputDecoration(
                          hintText: 'Ne düşünüyorsun?',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: frameColor.withOpacity(0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: frameColor, width: 1.5),
                          ),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$remaining / $_maxLen',
                            style: TextStyle(
                              fontSize: 12,
                              color: frameColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          isPosting
                              ? const CircularProgressIndicator()
                              : ElevatedButton.icon(
                            onPressed: canSend ? _handlePost : null,
                            icon: const Icon(Icons.send, size: 16, color: Colors.white),
                            label: const Text('Gönder', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              canSend ? Colors.orange.shade600 : Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}