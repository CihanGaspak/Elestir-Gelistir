import 'package:elestir_gelistir/homepage.dart';
import 'package:elestir_gelistir/profilpage.dart';
import 'package:flutter/material.dart';

import 'activitiespage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    HomePage(),
    ActivitiesPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange.shade600,
        unselectedItemColor: Colors.grey,
        onTap: (index) => _pageController.jumpToPage(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Bildirimler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}


class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    final List<Map<String, String>> notifications = [
      {"title": "Yeni takipçin var!", "time": "5 dk önce", "icon": "person_add"},
      {"title": "Gönderin beğenildi!", "time": "15 dk önce", "icon": "thumb_up"},
      {"title": "Yeni yorum aldın!", "time": "1 saat önce", "icon": "comment"},
      {"title": "Hesap güvenliği güncellendi", "time": "3 saat önce", "icon": "lock"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade600,
                child: Icon(_mapIcon(notif["icon"] ?? ""), color: Colors.white),
              ),
              title: Text(notif["title"] ?? ""),
              subtitle: Text(notif["time"] ?? ""),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }

  IconData _mapIcon(String iconName) {
    switch (iconName) {
      case "person_add":
        return Icons.person_add;
      case "thumb_up":
        return Icons.thumb_up;
      case "comment":
        return Icons.comment;
      case "lock":
        return Icons.lock;
      default:
        return Icons.notifications;
    }
  }
}
