import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elestir_gelistir/loginpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationEnabled = true;
  String appVersion = "1.0.1";

  final Color primaryColor = Colors.orange.shade600; // Turuncu tonumuz

  @override
  void initState() {
    super.initState();
    loadAppInfo();
  }

  Future<void> loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
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

  Future<void> openPlayStore() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.elestirgelistir');
    if (!await launchUrl(url)) {
      throw Exception('Play Store açılamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionTitle('Genel Ayarlar'),
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: primaryColor),
            title: Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Bildirim tercihlerini düzenleyin'),
            value: isNotificationEnabled,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                isNotificationEnabled = value;
              });
            },
          ),
          _buildListTile(
            icon: Icons.language,
            title: 'Dil',
            subtitle: 'Uygulama dilini değiştirin',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dil değişimi henüz desteklenmiyor!'), backgroundColor: primaryColor),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Hesap Ayarları'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Gizlilik ve Güvenlik',
            subtitle: 'Hesap güvenliğinizi yönetin',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gizlilik ayarları yakında!'), backgroundColor: primaryColor),
              );
            },
          ),
          _buildListTile(
            icon: Icons.person,
            title: 'Profil Ayarları',
            subtitle: 'Kullanıcı bilgilerinizi güncelleyin',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil düzenleme yakında!'), backgroundColor: primaryColor),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Ek Ayarlar'),
          _buildListTile(
            icon: Icons.star,
            title: 'Bizi Değerlendir',
            subtitle: 'Google Play üzerinden puan verin',
            onTap: () => openPlayStore(),
          ),
          _buildListTile(
            icon: Icons.email,
            title: 'Bize Ulaşın',
            subtitle: 'Öneri ve geri bildirim gönderin',
            onTap: () => sendEmail(),
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
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade400),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
      ),
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
