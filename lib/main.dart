import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 🆕 Yerel bildirim
import 'package:elestir_gelistir/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

// 📌 Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 🔔 Arka planda gelen mesajları yakalamak için
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 [BG] Arka planda mesaj: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Bildirim kanalı tanımı (Android için)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Yüksek Önemli Bildirimler',
    description: 'Bu kanal yüksek öneme sahip bildirimler içindir.',
    importance: Importance.high,
  );

  // Bildirim altyapısını başlat
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await initializeDateFormatting('tr', null);
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() async {
    // 🔑 Bildirim izni (Android 13+ için)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

    // ✅ Token alma
    final token = await FirebaseMessaging.instance.getToken();
    print('🔐 FCM Token: $token');

    // ✅ Uygulama açıkken gelen mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 [ON] Yeni mesaj geldi: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // ✅ Bildirime tıklayarak açıldığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 [TAP] Kullanıcı bildirime tıkladı');
      // Buraya yönlendirme kodları eklenebilir
    });
  }

  // 📍 Yerel bildirim gösterimi
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Yeni Bildirim';
    final body = notification?.body ?? data['body'] ?? '';

    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Yüksek Önemli Bildirimler',
          channelDescription: 'Bu kanal yüksek öneme sahip bildirimler içindir.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eleştir - Geliştir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
