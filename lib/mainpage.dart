import 'package:elestir_gelistir/elestir-AI/ai_page.dart';
import 'package:elestir_gelistir/ProfilePage/profilpage.dart';
import 'package:elestir_gelistir/newhome/NewHomePage.dart';
import 'package:flutter/material.dart';

import 'NotificationsPage.dart';
import 'explorepage/explore.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    Newhomepage(),
    ExplorePage(),
    AiPage(),
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
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange.shade600,
        unselectedItemColor: Colors.grey,
        onTap: (index) => _pageController.jumpToPage(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),

          // 🌟 Ortadaki buton - sade AI stili
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),   // 👈 Değiştirdik
            label: 'elestir-AI',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Bildirimler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}


