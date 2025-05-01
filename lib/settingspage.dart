import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';

import 'loginpage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationEnabled = true;
  String appVersion = "1.0.1";
  String username = "";
  String selectedAvatar = "";
  String savedAvatar = "";

  final Color primaryColor = Colors.orange.shade600;

  final List<String> avatars = List.generate(
    10,
        (index) => 'assets/avatars/avatar${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    loadAppInfo();
    fetchUserData();
  }

  Future<void> loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        username = doc['username'] ?? "";
        selectedAvatar = doc['photoUrl'] ?? avatars.first;
        savedAvatar = selectedAvatar;
      });
    }
  }

  Future<void> saveAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await userRef.update({'photoUrl': selectedAvatar});

      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: user.uid)
          .get();

      for (var doc in postsSnapshot.docs) {
        await doc.reference.update({'authorPhotoUrl': selectedAvatar});
      }

      setState(() {
        savedAvatar = selectedAvatar;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar başarıyla kaydedildi.")),
        );
      }

      Navigator.pop(context); // 👈 burası profili açmak için
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e")),
        );
      }
    }
  }

  Future<void> openPlayStore() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.elestirgelistir');
    if (!await launchUrl(url)) {
      throw Exception('Play Store açılamadı');
    }
  }

  Future<void> sendEmail() async {
    final Email email = Email(
      body: '',
      subject: 'Eleştir - Geliştir Destek',
      recipients: ['destek@elestirgelistir.com'],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage(selectedAvatar),
                ),
                const SizedBox(height: 8),
                Text(
                  username.isNotEmpty ? username : "Yükleniyor...",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text("Avatarını Seç", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: avatars.map((path) {
                    final isSelected = selectedAvatar == path;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = path;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage(path),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: selectedAvatar != savedAvatar ? saveAvatar : null,
                  icon: const Icon(Icons.save,color: Colors.white,),
                  label: const Text("Kaydet",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Divider(),
          _buildSectionTitle('Genel Ayarlar'),
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: primaryColor),
            title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Bildirim tercihlerini düzenleyin'),
            value: isNotificationEnabled,
            activeColor: primaryColor,
            onChanged: (value) => setState(() => isNotificationEnabled = value),
          ),
          _buildListTile(
            icon: Icons.language,
            title: 'Dil',
            subtitle: 'Uygulama dilini değiştirin',
            onTap: () => _showSnackBar('Dil değişimi henüz desteklenmiyor!'),
          ),
          _buildSectionTitle('Hesap Ayarları'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Gizlilik ve Güvenlik',
            subtitle: 'Hesap güvenliğinizi yönetin',
            onTap: () => _showSnackBar('Gizlilik ayarları yakında!'),
          ),
          _buildListTile(
            icon: Icons.person,
            title: 'Profil Ayarları',
            subtitle: 'Kullanıcı bilgilerinizi güncelleyin',
            onTap: () => _showSnackBar('Profil düzenleme yakında!'),
          ),
          _buildSectionTitle('Ek Ayarlar'),
          _buildListTile(
            icon: Icons.star,
            title: 'Bizi Değerlendir',
            subtitle: 'Google Play üzerinden puan verin',
            onTap: openPlayStore,
          ),
          _buildListTile(
            icon: Icons.email,
            title: 'Bize Ulaşın',
            subtitle: 'Öneri ve geri bildirim gönderin',
            onTap: sendEmail,
          ),
          _buildListTile(
            icon: Icons.info,
            title: 'Hakkında',
            subtitle: 'Versiyon: $appVersion',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Eleştir - Geliştir',
                applicationVersion: appVersion,
                applicationLegalese: '© 2025 Cihan Gaspak',
              );
            },
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryColor),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30, color: primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
