import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core import
import 'package:elestir_gelistir/splash_screen.dart'; // SplashScreen import
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;


// Eğer firebase_options.dart dosyan varsa onu da import edeceğiz. (firebase kurulumunda gelmiş olmalı)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase burada başlatılıyor
  await initializeDateFormatting('tr', null);
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eleştir - Geliştir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Splash ekranı burada açılıyor
    );
  }
}
