import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../PostWriteCard.dart';
import 'post_list_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class Newhomepage extends StatefulWidget {
  const Newhomepage({super.key});

  @override
  State<Newhomepage> createState() => _NewhomepageState();
}

class _NewhomepageState extends State<Newhomepage> {
  String selectedTab = 'following';
  String selectedCategory = 'Tümü';
  final PageStorageBucket _bucket = PageStorageBucket();

  final categories = [
    'Tümü', 'Eğitim', 'Spor', 'Tamirat', 'Araç Bakım',
    'Sağlık', 'Teknoloji', 'Kişisel Gelişim', 'Sanat', 'Yazılım'
  ];

  final Map<String, IconData> categoryIcons = {
    'Tümü': Icons.all_inclusive,
    'Eğitim': Icons.school,
    'Spor': Icons.fitness_center,
    'Tamirat': Icons.handyman,
    'Araç Bakım': Icons.car_repair,
    'Sağlık': Icons.local_hospital,
    'Teknoloji': Icons.memory,
    'Kişisel Gelişim': Icons.self_improvement,
    'Sanat': Icons.palette,
    'Yazılım': Icons.code,
  };

  final TextEditingController controller = TextEditingController();

  // ✅ Gönderim işlemi
  Future<void> _handlePost(String text, String category) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Kullanıcı bilgilerini Firestore'dan alalım
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final username = userDoc['username'] ?? currentUser.email;
    final photoUrl = userDoc['photoUrl'] ?? '';

    await FirebaseFirestore.instance.collection('posts').add({
      'content': text,                     // ✅ gönderi içeriği
      'category': category,                // ✅ kategori
      'authorId': currentUser.uid,         // ✅ kullanıcı UID
      'date': FieldValue.serverTimestamp(),// ✅ tarih (sunucu zamanı)
      'dailyPick': false,                  // ✅ önerilen gönderi değil
      'progressStep': 0,                   // ✅ ilk aşama
      'step1Note': '',                     // (isteğe bağlı eklendi)
      'step2Note': '',
      'step3Note': '',
      'likedBy': [],                       // ✅ boş beğeni listesi
      'savedBy': [],                       // ✅ boş kayıt listesi
      'views': 0,                          // ✅ ilk görüntülenme 0
      'likesCount': 0,                     // ✅ başlangıç beğeni sayısı
      'commentsCount': 0,                  // ✅ başlangıç yorum sayısı
    });

    setState(() {}); // gönderi eklendiğinde anasayfa güncelle
  }


  // ✅ Post yazma ekranını aç
  void _openPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: PostWrite(
            key: const ValueKey('PostWrite'),
            controller: controller,
            onPost: _handlePost,
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _requestNotificationPermission(); // 🔔 izin isteği

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Gelen bildirim: ${message.notification?.title}');
      print('📩 İçerik: ${message.notification?.body}');
    });
  }

  Future<void> _requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 Bildirim izni verildi.');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ Bildirim izni reddedildi.');
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      print('❓ Bildirim izni sorulmadı.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageStorage(
          bucket: _bucket,
          child: Column(
            children: [
              _buildFeedToggleBar(),
              const SizedBox(height: 6),
              _buildDropdownCategorySelector(),
              const SizedBox(height: 10),
              Expanded(
                child: PostListView(
                  key: PageStorageKey('postList_${selectedTab}_$selectedCategory'),
                  filter: selectedTab,
                  category: selectedCategory,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _openPostModal, // ✅ artık buradan açılıyor
      ),

    );
  }

  Widget _buildFeedToggleBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['following', 'all'].map((tab) {
          final isSelected = selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Text(
                    tab == 'following' ? '👥 Takip' : '🌍 Herkes',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      height: 3,
                      width: 40,
                      margin: const EdgeInsets.only(top: 6),
                      color: Colors.deepOrange,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdownCategorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.deepOrange, width: 1.2),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCategory,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepOrange),
            items: categories.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(categoryIcons[value], color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newVal) {
              setState(() {
                selectedCategory = newVal!;
              });
            },
          ),
        ),
      ),
    );
  }
}
