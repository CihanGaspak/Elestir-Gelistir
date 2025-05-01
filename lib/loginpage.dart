import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'mainpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLogin = true;
  bool isBusy   = false;

  final loginEmail    = TextEditingController();
  final loginPassword = TextEditingController();
  final regEmail      = TextEditingController();
  final regPassword   = TextEditingController();
  final regUsername   = TextEditingController();

  //──────────────────────────────────────── login
  Future<void> signIn() async {
    if (loginEmail.text.isEmpty || loginPassword.text.isEmpty) {
      _alert('E-posta ve şifre giriniz'); return;
    }
    setState(() => isBusy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail.text.trim(),
        password: loginPassword.text.trim(),
      );
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
        'photoUrl' : '',
      });

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
      RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(e);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: isBusy
            ? const CircularProgressIndicator()
            : showLogin
            ? _loginForm()
            : _registerForm(),
      ),
    ),
  );

  //──────────────────────────────────────── Login UI
  Widget _loginForm() => _wrapper(
    key: const ValueKey('login'),
    title: 'Giriş Yap',
    upperBox: _upperBox(
      question: 'Hesabın yok mu?',
      button: 'Kayıt Ol',
      onTap: () => setState(() => showLogin = false),
    ),
    children: [
      _input(loginEmail, 'E-Posta', Icons.email),
      _space,
      _input(loginPassword, 'Şifre', Icons.lock, obsecure: true),
      _space,
      _mainBtn('Giriş Yap', signIn),
    ],
  );

  //──────────────────────────────────────── Register UI
  Widget _registerForm() => _wrapper(
    key: const ValueKey('register'),
    title: 'Kayıt Ol',
    upperBox: _upperBox(
      question: 'Hesabın var mı?',
      button: 'Giriş Yap',
      onTap: () => setState(() => showLogin = true),
    ),
    children: [
      _input(regUsername, 'Kullanıcı Adı', Icons.person),
      _space,
      _input(regEmail, 'E-Posta', Icons.email),
      _space,
      _input(regPassword, 'Şifre (min 6)', Icons.lock, obsecure: true),
      _space,
      _mainBtn('Kayıt Ol', register),
    ],
  );

  //──────────────────────────────────────── UI helpers
  Widget _wrapper(
      {required Key key,
        required String title,
        required Widget upperBox,
        required List<Widget> children}) =>
      Container(
        key: key,
        width: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              upperBox,
              const SizedBox(height: 30),
              Text(title,
                  style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _upperBox(
      {required String question,
        required String button,
        required VoidCallback onTap}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(question,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white)),
              child: Text(button,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      );

  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obsecure = false}) =>
      TextField(
        controller: c,
        obscureText: obsecure,
        decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Icon(icon),
            border: const OutlineInputBorder()),
      );

  Widget _mainBtn(String txt, VoidCallback fn) => ElevatedButton(
    onPressed: fn,
    style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade600,
        minimumSize: const Size.fromHeight(48),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    child: Text(txt,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold)),
  );

  Widget get _space => const SizedBox(height: 10);
}
