import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AiChatWidget.dart';
import 'package:intl/intl.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  String? _photoUrl;
  String? _username;
  List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadChatHistory();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _photoUrl = data?['photoUrl'] ?? '';
          _username = data?['username'] ?? 'Ben';
        });
      }
    } catch (e) {
      print('❌ Fotoğraf yükleme hatası: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .get();

      final chats = query.docs.map((doc) {
        final data = doc.data();
        final List<dynamic> messages = data['messages'] ?? [];
        final firstMessage = messages.isNotEmpty && messages[0]['text'] is String
            ? messages[0]['text']
            : 'Başlıksız';
        return {
          'chatId': doc.id,
          'title': firstMessage,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'messages': messages,
        };
      }).toList();

      setState(() {
        _chatHistory = chats;
      });
    } catch (e) {
      print('❌ Sohbet geçmişi yüklenemedi: $e');
    }
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds} saniye önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ay önce';
    return '${(diff.inDays / 365).floor()} yıl önce';
  }

  double getAverageMessageCount() {
    if (_chatHistory.isEmpty) return 0;
    int totalMessages = 0;
    for (var chat in _chatHistory) {
      final List messages = chat['messages'] ?? [];
      totalMessages += messages.length;
    }
    return (totalMessages / _chatHistory.length);
  }

  String getLastChatDate() {
    if (_chatHistory.isEmpty) return 'Yok';
    final date = _chatHistory.first['createdAt'] ?? DateTime.now();
    return DateFormat('dd MMM yyyy – HH:mm', 'tr_TR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    Widget _buildStatCard({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              ],
            )
          ],
        ),
      );
    }



    return Scaffold(
      appBar: AppBar(
        title: const Text('eleştir-AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // 🟠 DrawerHeader - Kullanıcı Bilgisi
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (_photoUrl?.isNotEmpty ?? false)
                        ? AssetImage(_photoUrl!)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 18),
                            const SizedBox(width: 5),
                            Text(
                              '${_chatHistory.length} Sohbet',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔽 Alt İçerik - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ➕ Yeni Sohbet Butonu
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
                      label: const Text("Yeni Sohbet Oluştur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final titleController = TextEditingController();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Yeni Sohbet Başlığı"),
                            content: TextField(
                              controller: titleController,
                              decoration: const InputDecoration(hintText: "Başlık girin..."),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oluştur")),
                            ],
                          ),
                        );

                        if (confirmed == true && titleController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.white,
                                appBar: AppBar(title: Text(titleController.text.trim()), backgroundColor: primaryColor),
                                body: AiChatWidget(
                                  userPhotoUrl: _photoUrl,
                                  username: _username,
                                  chatStarted: false,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    // 📋 Sohbet Listesi
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final chat = _chatHistory[index];
                        final createdAt = chat['createdAt'] ?? DateTime.now();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          leading: const Icon(Icons.chat, color: Colors.orange),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chat['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(timeAgo(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Sohbeti Sil'),
                                    content: const Text('Bu sohbeti silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.uid)
                                        .collection("chats")
                                        .doc(chat['chatId'])
                                        .delete();
                                    setState(() => _chatHistory.removeAt(index));
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'delete', child: Text('Sohbeti Sil')),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.white,
                                  appBar: AppBar(title: const Text("Sohbete Devam"), backgroundColor: primaryColor),
                                  body: AiChatWidget(
                                    userPhotoUrl: _photoUrl,
                                    username: _username,
                                    existingChatId: chat['chatId'],
                                    chatStarted: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const Divider(height: 32, thickness: 1, color: Colors.black12),

                    // 📊 İstatistik Kartları
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 1,
                      mainAxisSpacing: 12,
                      childAspectRatio: 4 / 1.3,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildStatCard(
                          icon: Icons.category,
                          label: 'En Çok Konuşulan',
                          value: 'Yazılım',
                          color: Colors.deepPurpleAccent,
                        ),
                        _buildStatCard(
                          icon: Icons.access_time,
                          label: 'Ortalama Uzunluk',
                          value: '${getAverageMessageCount().toStringAsFixed(1)} mesaj',
                          color: Colors.teal,
                        ),
                        _buildStatCard(
                          icon: Icons.folder_copy_outlined,
                          label: 'Son Sohbet',
                          value: getLastChatDate(),
                          color: Colors.blueGrey,
                        ),
                        _buildStatCard(
                          icon: Icons.calendar_month,
                          label: 'Haftalık Aktiflik',
                          value: '3 sohbet',
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    SizedBox(height: 8,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        body: (_username == null)
          ? const Center(child: CircularProgressIndicator())
          : AiChatWidget(
        userPhotoUrl: _photoUrl,
        username: _username,
      ),
    );
  }
}
