import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io'
    if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _token;

  Future<void> initialize() async {
    print("Initializing FCM Service");

    // On web platform, handle things differently
    if (kIsWeb) {
      print(
          "FCM Service running on web platform - using limited functionality");
      return;
    }

    // Request permission and get token
    await _requestPermission();
    await _getToken();

    // Set up message handlers for non-web platforms
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // Background handler is set in main.dart
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial messages
    await _checkInitialMessage();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      print("Skipping notification permission request on web");
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      // KRİTİK: iOS'ta permission AppDelegate'te zaten isteniyor
      // Burada sadece durum kontrolü yap, permission isteme
      print("📱 Bildirim izin durumu kontrol ediliyor...");

      final settings = await messaging.getNotificationSettings();

      print("📱 Bildirim izin durumu: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print("✅ Bildirim izni verilmiş");
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("❌ Bildirim izni reddedilmiş");
      } else {
        print(
            "⚠️ Bildirim izni henüz belirlenmemiş (AppDelegate'te istenecek)");
      }
    } catch (e) {
      print("❌ Bildirim izin durumu kontrolü hatası: $e");
    }
  }

  Future<void> _getToken() async {
    if (kIsWeb) {
      print("FCM token retrieval limited on web platform");
      return;
    }

    try {
      int attempt = 1;
      String? token;

      while (token == null && attempt <= 3) {
        print("Attempting to get FCM token (attempt $attempt)");
        token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          print("FCM token received: ${token.substring(0, 10)}...");
          await _saveTokenToFirestore(token);
          return;
        }

        attempt++;
        if (token == null && attempt <= 3) {
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (token == null) {
        print("Failed to get FCM token after 3 attempts");
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Platform bilgisini belirle
        String platform = 'unknown';
        if (!kIsWeb) {
          if (io.Platform.isIOS) {
            platform = 'ios';
          } else if (io.Platform.isAndroid) {
            platform = 'android';
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': platform,
        });

        print("✅ FCM token saved to Firestore (platform: $platform)");
      } else {
        print("⚠️ Cannot save token: No user is signed in");
      }
    } catch (e) {
      print("❌ Error updating FCM token on startup: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print(
        "🔔 FCM message received in foreground: ${message.notification?.title}");
    print("📋 Message data: ${message.data}");

    // KRİTİK: Bu handler main.dart'taki handler ile ÇAKIŞIYOR olabilir
    // main.dart'ta da FirebaseMessaging.onMessage.listen var
    // Bu servisi devre dışı bırakıyoruz - main.dart halledecek
    //
    // NOT: Bu servis initialize edilirse çift handler olur!
    // Şimdilik sadece log yapıyoruz, local notification göstermiyoruz
    print(
        "📱 FCMService: Foreground message alındı, main.dart handler'ına bırakılıyor");
    print(
        "   - Bu servis local notification GÖSTERMİYOR (çift bildirim önlendi)");

    // Eski kod devre dışı - main.dart halledecek
    return;

    /* DEVRE DIŞI - main.dart'ta hallediliyor
    if (kIsWeb) return;

    try {
      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;

      // Bildirim başlığı ve içeriği
      String title = notification?.title ?? data['title'] ?? 'CanlıPazar';
      String body = notification?.body ?? data['text'] ?? data['body'] ?? 'Yeni bildiriminiz var!';
      
      // Badge sayısını al
      int? badgeNumber;
      if (data['unreadCount'] != null) {
        badgeNumber = int.tryParse(data['unreadCount'].toString());
      }

      print('📱 Foreground notification gösteriliyor: title=$title, body=$body, badge=$badgeNumber');

      // Android notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        android?.channelId ?? 'messages_channel',
        android?.channelId ?? 'Mesajlar',
        channelDescription: 'Mesaj bildirimlerini gösterir',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification',
      );

      // iOS notification details
      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badgeNumber,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );
      
      print('✅ Foreground notification gösterildi');
    } catch (e, stackTrace) {
      print('❌ Foreground notification gösterilirken hata: $e');
      print('❌ Stack trace: $stackTrace');
    }
    */
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print("🔔 App opened from notification: ${message.notification?.title}");
    print("📋 Message data: ${message.data}");

    // Navigate to appropriate screen
    // (You can add your navigation code here)
  }

  Future<void> _checkInitialMessage() async {
    if (kIsWeb) {
      return;
    }

    // Check if the app was opened from a notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print(
          "🔔 App started from notification: ${initialMessage.notification?.title}");
      print("📋 Initial message data: ${initialMessage.data}");

      // Handle the initial message
      // (You can add your navigation code here)
    }
  }
}

// This is defined outside the class to be accessible globally
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to initialize Firebase for background handling
  await Firebase.initializeApp();

  print("Handling background message: ${message.messageId}");
  print("Background message data: ${message.data}");

  // Minimal processing for background messages
}
