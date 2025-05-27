import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'mainpage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLogin = true;
  bool isBusy = false;

  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();
  final regEmail = TextEditingController();
  final regPassword = TextEditingController();
  final regUsername = TextEditingController();

  //──────────────────────────────────────── login
  Future<void> signIn() async {
    if (loginEmail.text.isEmpty || loginPassword.text.isEmpty) {
      _alert('E-posta ve şifre giriniz');
      return;
    }
    setState(() => isBusy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail.text.trim(),
        password: loginPassword.text.trim(),
      );
      // 🔥 Token kaydet!
      await saveDeviceToken();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      _alert(e.message ?? 'Giriş hatası');
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  //──────────────────────────────────────── register
  Future<void> register() async {
    if (regUsername.text.isEmpty) { _alert('Kullanıcı adı gerekli'); return; }
    if (!_validEmail(regEmail.text)) { _alert('Geçersiz e-posta'); return; }
    if (regPassword.text.length < 6) { _alert('Şifre en az 6 karakter'); return; }

    setState(() => isBusy = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: regEmail.text.trim(),
          password: regPassword.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid'      : cred.user!.uid,
        'email'    : cred.user!.email,
        'username' : regUsername.text.trim(),
        'photoUrl' : 'assets/avatars/avatar1.png',
        'joinedAt' : Timestamp.now(),
        'usefulness': 0.0, // İlk kayıt 0.0 olabilir, istersen 5.0 default koyabilirsin.
        'followers': [],
        'following': [],
      });

      // 📌 Hemen sonra token'ı kaydet
      await saveDeviceToken();

      _alert('Kayıt başarılı! Giriş yapabilirsiniz.', ok: true);
      setState(() => showLogin = true);
    } on FirebaseAuthException catch (e) {
      _alert(e.message ?? 'Kayıt hatası');
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }


  //──────────────────────────────────────── helpers
  void _alert(String msg, {bool ok = false}) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(ok ? 'Başarılı' : 'Uyarı'),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tamam'),
        )
      ],
    ),
  );

  bool _validEmail(String e) =>
      RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(e);

  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });

      print("✅ FCM Token kaydedildi: $token");
    } else {
      print("❌ Token alınamadı.");
    }
  }


  //──────────────────────────────────────── UI
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo & Başlık
              Column(
                children: [
                  Image.asset('assets/default_icon.png',
                      width: 120, height: 120),
                  const SizedBox(height: 16),
                  const Text(
                    'Eleştir - Geliştir',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    showLogin ? 'Giriş Yap' : 'Kayıt Ol',
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.shade100, blurRadius: 8)
                  ],
                ),
                child: isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : showLogin
                    ? _loginForm()
                    : _registerForm(),
              ),
              const SizedBox(height: 24),
              // Alt Kutu
              _footerBox(),

              const SizedBox(height: 32),

              // Alt Logo ve AIM DEV.
              Column(
                children: [
                  Image.asset('assets/logo-footer.png',
                      width: 100, height: 100),
                  Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );


  Widget _footerBox() => Column(
    children: [
      Text(
        showLogin ? 'Hesabın yok mu?' : 'Zaten hesabın var mı?',
        style: const TextStyle(color: Colors.black87),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() => showLogin = !showLogin),
        style: TextButton.styleFrom(
            foregroundColor: Colors.orange.shade600,
            textStyle: const TextStyle(fontWeight: FontWeight.bold)),
        child: Text(showLogin ? 'Kayıt Ol' : 'Giriş Yap'),
      ),
    ],
  );

  Widget _loginForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _input(loginEmail, 'E-posta', Icons.email),
      _space,
      _input(loginPassword, 'Şifre', Icons.lock, obsecure: true),
      _space,
      _mainBtn('Giriş Yap', signIn),
    ],
  );

  Widget _registerForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _input(regUsername, 'Kullanıcı Adı', Icons.person),
      _space,
      _input(regEmail, 'E-posta', Icons.email),
      _space,
      _input(regPassword, 'Şifre (min 6 karakter)', Icons.lock,
          obsecure: true),
      _space,
      _mainBtn('Kayıt Ol', register),
    ],
  );

  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obsecure = false}) =>
      TextField(
        controller: c,
        obscureText: obsecure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange.shade600),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.orange.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
        ),
      );

  Widget _mainBtn(String txt, VoidCallback fn) => ElevatedButton.icon(
    onPressed: fn,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade600,
      minimumSize: const Size.fromHeight(50),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
    label: Text(
      txt,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget get _space => const SizedBox(height: 10);
}
