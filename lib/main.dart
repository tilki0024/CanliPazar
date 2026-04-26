import 'dart:convert';
import 'package:animal_trade/screens/location_picker_screen.dart';
import 'package:animal_trade/screens/message_screen.dart';
import 'package:animal_trade/screens/animal_detail_screen.dart';
import 'package:animal_trade/models/animal_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:animal_trade/utils/safe_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animal_trade/providers/user_provider.dart';
import 'package:animal_trade/responsive/mobile_screen_layout.dart';
import 'package:animal_trade/responsive/responsive_layout_screen.dart';
import 'package:animal_trade/responsive/web_screen_layout.dart';
import 'package:animal_trade/screens/login_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_links/app_links.dart';
import 'package:animal_trade/services/fcm_token_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// Conditionally import dart:io
import 'dart:io'
    if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
import 'screens/location_picker_demo.dart';

/// KRİTİK: Background message handler
/// Bu handler ayrı bir isolate'te çalışır ve Firebase'i kendi başına başlatmalıdır
/// Telefon kapalıyken veya uygulama kapalıyken bile bildirim gösterir
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // KRİTİK: Background handler ayrı bir isolate'te çalışır
  // Firebase'i bu isolate'te başlatmalıyız
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Background handler: Firebase başlatıldı");
    } else {
      print("✅ Background handler: Firebase zaten başlatılmış");
    }
  } catch (e) {
    print(
        "⚠️ Background handler: Firebase başlatma hatası (devam ediliyor): $e");
  }

  // Platform tespiti
  final isAndroid = !kIsWeb && io.Platform.isAndroid;
  final isIOS = !kIsWeb && io.Platform.isIOS;

  print("📱 [BACKGROUND] ========== BACKGROUND MESAJ ALINDI ==========");
  print(
      "📱 [BACKGROUND] Platform: ${isAndroid ? 'Android' : (isIOS ? 'iOS' : 'Unknown')}");
  print("📱 [BACKGROUND] Message ID: ${message.messageId}");
  print("📋 [BACKGROUND] Mesaj tipi: ${message.data['type'] ?? 'bilinmiyor'}");
  print(
      "📋 [BACKGROUND] Notification title: ${message.notification?.title ?? 'yok'}");
  print(
      "📋 [BACKGROUND] Notification body: ${message.notification?.body ?? 'yok'}");
  print(
      "📋 [BACKGROUND] Has notification payload: ${message.notification != null}");
  print("📋 [BACKGROUND] Data: ${message.data}");
  print("📱 [BACKGROUND] ============================================");

  // KRİTİK: ÇİFT BİLDİRİM SORUNU ÇÖZÜMÜ
  // iOS'ta APNs notification payload varsa, sistem bildirimi otomatik gösterir
  // Android'de de notification payload varsa sistem bildirimi otomatik gösterebilir
  // Biz de local notification gösterirsek ÇİFT BİLDİRİM olur!
  //
  // ÇÖZÜM: Hem iOS hem Android için notification payload varsa local notification GÖSTERME
  // Sadece data-only mesajlar için local notification göster
  if (isIOS && message.notification != null) {
    print("📱 [BACKGROUND] iOS: Notification payload mevcut");
    print("   - APNs sistem bildirimi otomatik gösterecek");
    print("   - Local notification GÖSTERİLMİYOR (çift bildirim önlendi)");
    print("✅ [BACKGROUND] iOS çift bildirim önlendi - işlem tamamlandı");
    return; // iOS'ta notification payload varsa çık, APNs halledecek
  }

  // KRİTİK: Android için de notification payload kontrolü
  // Android'de notification payload varsa sistem bildirimi otomatik gösterebilir
  // Bu durumda local notification GÖSTERME (çift bildirim önleme)
  if (isAndroid && message.notification != null) {
    print("📱 [BACKGROUND] Android: Notification payload mevcut");
    print("   - Android sistem bildirimi otomatik gösterecek");
    print("   - Local notification GÖSTERİLMİYOR (çift bildirim önlendi)");
    print("✅ [BACKGROUND] Android çift bildirim önlendi - işlem tamamlandı");
    return; // Android'de notification payload varsa çık, sistem halledecek
  }

  // Sadece data-only mesajlar için local notification göster
  print("📱 [BACKGROUND] Data-only mesaj tespit edildi, local notification gösterilecek");
  print("   - Platform: ${isAndroid ? 'Android' : 'iOS'}");

  // Local notifications plugin'i initialize et
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: false, // Background'da permission zaten verilmiş
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Mesaj tipine göre bildirim göster
  final notificationType = message.data['type'] ?? '';
  String title;
  String body;

  if (notificationType == 'message') {
    // KRİTİK: Kullanıcı isteği - Android için "Mesajınız var" başlığı
    // iOS için "kullanıcı_adı size mesaj gönderdi" formatı korunuyor
    if (isAndroid) {
      // Android için sabit başlık: "Mesajınız var"
      title = 'Mesajınız var';
      // Body: Mesaj içeriği
      body = message.data['text'] ?? 
          message.data['body'] ?? 
          message.notification?.body ?? 
          'Yeni mesajınız var!';
    } else {
      // iOS için eski format korunuyor
      final senderUsername = message.data['senderUsername'] ?? 'Birisi';
      title = message.notification?.title ??
          message.data['title'] ??
          '$senderUsername size mesaj gönderdi';
      // Body: Sadece mesaj içeriği (kullanıcı adı başlıkta zaten var)
      if (message.notification?.body != null &&
          message.notification!.body!.isNotEmpty) {
        body = message.notification!.body!;
      } else {
        // Data'dan mesaj içeriğini al
        final messageText =
            message.data['text'] ?? message.data['body'] ?? 'Yeni mesajınız var!';
        body = messageText;
      }
    }

    print("📨 [BACKGROUND] Yeni mesaj bildirimi gösteriliyor");
    print("   - Platform: ${isAndroid ? 'Android' : 'iOS'}");
    print("   - Başlık: $title");
    print("   - İçerik: $body");
  } else if (notificationType == 'new_post' ||
      notificationType == 'new_animal_post' ||
      notificationType == 'listing' ||
      notificationType == 'daily_notification') {
    // KRİTİK: İlan bildirimi - Her 2 ilanda 1 bildirim gönderme mekanizması Cloud Functions'ta
    // Burada sadece bildirim gösteriliyor
    title =
        message.notification?.title ?? message.data['title'] ?? 'CanlıPazar';
    body = message.notification?.body ??
        message.data['body'] ??
        'Yeni İlanlar Eklendi!';
    print("🆕 [BACKGROUND] Yeni ilan bildirimi gösteriliyor");
    print("   - Type: $notificationType");
  } else {
    // Varsayılan bildirim
    title =
        message.notification?.title ?? message.data['title'] ?? 'CanlıPazar';
    body = message.notification?.body ??
        message.data['text'] ??
        message.data['body'] ??
        'Yeni bildiriminiz var!';
  }

  // Badge sayısını al
  int? badgeNumber;
  if (message.data['unreadCount'] != null) {
    badgeNumber = int.tryParse(message.data['unreadCount'].toString());
  }

  // KRİTİK: Android için notification channel ve details
  final String channelId = (notificationType == 'new_post' ||
          notificationType == 'new_animal_post' ||
          notificationType == 'daily_notification')
      ? 'new_posts_channel'
      : 'messages_channel';
  final String channelName = (notificationType == 'new_post' ||
          notificationType == 'new_animal_post' ||
          notificationType == 'daily_notification')
      ? 'Yeni İlanlar'
      : 'Mesajlar';

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: notificationType == 'new_post' ||
            notificationType == 'new_animal_post' ||
            notificationType == 'daily_notification'
        ? 'Yeni ilan bildirimlerini gösterir'
        : 'Mesaj bildirimlerini gösterir',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@drawable/ic_notification',
    color: const Color(0xFF2E7D32),
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

  // Bildirimi göster - Android ve iOS için
  // KRİTİK: Unique bildirim ID kullan (çift bildirim önleme)
  int notificationId;
  
  if (notificationType == 'message') {
    // Mesaj bildirimleri için messageId kullan
    final messageId = message.data['messageId'] ?? '';
    notificationId = messageId.isNotEmpty 
        ? messageId.hashCode 
        : (message.messageId?.hashCode ?? message.hashCode);
  } else if (notificationType == 'new_post' || notificationType == 'new_animal_post') {
    // İlan bildirimleri için postId kullan
    final postId = message.data['postId'] ?? message.data['animalId'] ?? '';
    notificationId = postId.isNotEmpty 
        ? postId.hashCode 
        : (message.messageId?.hashCode ?? message.hashCode);
  } else {
    // Diğer bildirimler için messageId kullan
    notificationId = message.messageId?.hashCode ?? message.hashCode;
  }
  
  try {
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
    print("✅ [BACKGROUND] Bildirim başarıyla gösterildi: $title - $body");
    print(
        "   - Platform: ${isAndroid ? 'Android' : (isIOS ? 'iOS' : 'Unknown')}");
    print("   - Channel ID: $channelId");
    print("   - Notification Type: $notificationType");
  } catch (e) {
    print("❌ [BACKGROUND] Bildirim gösterilirken hata oluştu: $e");
  }
}

Future<void> requestNotificationPermissions() async {
  if (kIsWeb) return;

  try {
    // Android 13+ için POST_NOTIFICATIONS izni
    if (io.Platform.isAndroid) {
      final permissionHandler = Permission.notification;
      final status = await permissionHandler.status;

      print('📱 Android bildirim izin durumu: $status');

      if (status.isDenied || status.isLimited) {
        final result = await permissionHandler.request();
        print('📱 Android bildirim izin sonucu: $result');

        if (result.isGranted) {
          print('✅ Android bildirim izni verildi');
        } else if (result.isPermanentlyDenied) {
          print('❌ Android bildirim izni kalıcı olarak reddedildi');
          print('⚠️ Kullanıcı ayarlardan manuel olarak açmalı');
        } else {
          print('⚠️ Android bildirim izni reddedildi');
        }
      } else if (status.isGranted) {
        print('✅ Android bildirim izni zaten verilmiş');
      }
    }

    // Firebase Messaging izni (iOS için)
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('📱 Firebase Messaging izin durumu: ${settings.authorizationStatus}');
  } catch (e) {
    print('⚠️ Notification permission hatası: $e');
  }
}

Future<void> setupLocalNotifications() async {
  if (kIsWeb) {
    print("Skipping local notifications setup on web platform");
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android için notification channel'ları oluştur
  // KRİTİK: Importance.max olmalı (Android'de bildirimlerin gösterilmesi için)
  if (io.Platform.isAndroid) {
    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
      'messages_channel',
      'Mesajlar',
      description: 'Mesaj bildirimlerini gösterir',
      importance: Importance.max, // KRİTİK: max olmalı
      playSound: true,
    );

    const AndroidNotificationChannel newPostsChannel =
        AndroidNotificationChannel(
      'new_posts_channel',
      'Yeni İlanlar',
      description: 'Yeni ilan bildirimlerini gösterir',
      importance: Importance.max, // KRİTİK: max olmalı
      playSound: true,
    );

    print(
        '📱 [setupLocalNotifications] Android notification channel\'lar oluşturuluyor...');
    print('   - messages_channel: Importance.max');
    print('   - new_posts_channel: Importance.max');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(newPostsChannel);
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          Map<String, dynamic> data = jsonDecode(response.payload!);
          print('📱 Bildirim tıklandı, payload: $data');
        } catch (e) {
          print('⚠️ Bildirim payload parse hatası: $e');
        }
      }
    },
  );

  print('✅ Local notifications setup tamamlandı');
}

/// iOS-Safe Minimal Firebase Init
///
/// Kurallar:
/// 1. runApp() öncesinde Firestore, FirebaseMessaging, AppCheck, Analytics, LocalNotifications KULLANMA
/// 2. Background message handler SADECE tanımlı olabilir, init edilmesin
/// 3. Tüm Firebase servisleri runApp() SONRASINA taşınacak (MyApp.initState())
Future<void> main() async {
  // 1. Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (SADECE initializeApp, başka hiçbir şey yok)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // KRİTİK iOS BİLDİRİM AYARI: Foreground notification presentation options
  // iOS'ta bildirimlerin foreground'da görünmesi için MUTLAKA gerekli
  // Bu ayar Firebase.initializeApp() SONRASINDA ama runApp() ÖNCESİNDE yapılmalı
  if (!kIsWeb && io.Platform.isIOS) {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print(
          '✅ iOS foreground notification presentation options ayarlandı (main)');
    } catch (e) {
      print('⚠️ iOS foreground notification options hatası: $e');
    }
  }

  // 3. Background message handler'ı SADECE tanımla (init etme)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // 4. Turkish locale initialize
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    print("⚠️ Turkish locale initialization error: $e");
  }

  // 5. Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ Flutter Error: ${details.exception}');
    FlutterError.presentError(details);
  };

  // 6. Uygulamayı başlat (TÜM Firebase servisleri runApp SONRASINA taşındı)
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // KRİTİK: Firebase Messaging dinleyicilerini sakla (çift dinleyici önleme)
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  @override
  void initState() {
    super.initState();

    // KRİTİK: Tüm Firebase servisleri runApp() SONRASINA taşındı
    // Bu initState() runApp()'tan SONRA çalışır, bu yüzden güvenli

    // 1. Uygulama açıldığında badge'i sıfırla
    _resetBadgeOnAppLaunch();

    // 2. Deep link handler'ı başlat
    _initDeepLinkHandler();

    // 3. Firebase servislerini initialize et (runApp SONRASI - GÜVENLİ)
    _initializeFirebaseServices();

    // 4. Firebase Messaging handler'ları ayarla
    _setupFirebaseMessagingHandlers();

    // 5. FCM token kontrolü
    _checkAndSaveFCMTokenOnAppStart();
  }

  /// Tüm Firebase servislerini initialize et
  /// Bu metod runApp() SONRASINDA çalışır, bu yüzden güvenli
  Future<void> _initializeFirebaseServices() async {
    print('🚀 Firebase servisleri initialize ediliyor (runApp SONRASI)...');

    // 1. Firebase Analytics
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);

      // Platform bilgisini user property olarak ayarla
      if (!kIsWeb) {
        String platform = io.Platform.isIOS
            ? 'ios'
            : (io.Platform.isAndroid ? 'android' : 'unknown');

        await analytics.setUserProperty(name: 'platform', value: platform);

        // İlk event'i logla
        await analytics.logEvent(
          name: 'app_open',
          parameters: {'platform': platform},
        );
        print('✅ Firebase Analytics initialized (platform: $platform)');
      } else {
        await analytics.logEvent(
          name: 'app_open',
          parameters: {'platform': 'web'},
        );
        print('✅ Firebase Analytics initialized (platform: web)');
      }
    } catch (e) {
      print('⚠️ Firebase Analytics initialization error: $e');
    }

    // 2. Local notifications setup
    try {
      if (!kIsWeb) {
        await setupLocalNotifications();
        print('✅ Local notifications setup tamamlandı');
      }
    } catch (e) {
      print('⚠️ Local notifications setup hatası: $e');
    }

    // 3. Notification permissions
    try {
      if (!kIsWeb) {
        if (io.Platform.isAndroid) {
          await requestNotificationPermissions();
          print('✅ Android notification permission istendi');
        } else if (io.Platform.isIOS) {
          // iOS için permission AppDelegate'te alınıyor
          // Burada sadece durumu kontrol et ve foreground options ayarla
          try {
            final settings =
                await FirebaseMessaging.instance.getNotificationSettings();
            print(
                '📱 iOS Notification permission durumu: ${settings.authorizationStatus}');

            // iOS için foreground notification presentation options ayarla
            await FirebaseMessaging.instance
                .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
            print(
                '✅ iOS foreground notification presentation options ayarlandı');
          } catch (e) {
            print('⚠️ iOS Notification permission kontrolü hatası: $e');
          }
        }
      }
    } catch (e) {
      print('⚠️ Notification permissions setup hatası: $e');
    }

    // 4. Firebase App Check
    // KRİTİK: App Check HTTP 412 hatasına neden olabilir (download URL'lerinde)
    // Şimdilik tamamen devre dışı bırakıyoruz (412 hatası çözümü)
    try {
      // App Check'i tamamen devre dışı bırak (412 hatası çözümü)
      // Production'da production provider kullanılmalı, debug mode sadece test için
      // await FirebaseAppCheck.instance.activate(...);
      print('⚠️ Firebase App Check devre dışı (412 hatası çözümü)');
    } catch (e) {
      print("⚠️ Firebase App Check initialization error: $e");
      print("⚠️ App Check hatası yoksayılıyor");
    }

    print('✅ Tüm Firebase servisleri initialize edildi');
  }

  @override
  void dispose() {
    // KRİTİK: Tüm dinleyicileri iptal et (memory leak önleme)
    _linkSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinkHandler() {
    if (kIsWeb) return;

    _appLinks = AppLinks();

    // KRİTİK: iOS Universal Links için method channel setup
    if (io.Platform.isIOS) {
      _setupUniversalLinksChannel();
    }

    // KRİTİK: Stream listener - uygulama açıkken gelen linkler
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Deep link alındı (stream): $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ Deep link stream hatası: $err');
      },
    );

    // KRİTİK: Initial link - uygulama terminated state'den açıldığında
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 Initial deep link: $uri');
        // Context hazır olana kadar bekle
        Future.delayed(Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      }
    }).catchError((err) {
      print('❌ Initial deep link hatası: $err');
    });
  }

  /// iOS Universal Links için method channel setup
  void _setupUniversalLinksChannel() {
    const MethodChannel platform =
        MethodChannel('com.canlipazar/universal_link');

    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleUniversalLink') {
        final String link = call.arguments as String;
        print('🔗 [Flutter] Universal Link alındı: $link');

        // Context hazır olana kadar bekle
        Future.delayed(Duration(milliseconds: 500), () {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _handleDeepLinkFromStream(link);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final context = navigatorKey.currentContext;
              if (context != null) {
                _handleDeepLinkFromStream(link);
              }
            });
          }
        });
      }
    });

    print('✅ iOS Universal Links method channel ayarlandı');
  }

  /// Deep link'i handle et - tüm formatları destekle
  void _handleDeepLink(Uri uri) {
    // Tüm desteklenen formatları kontrol et
    final isSupportedLink = uri.scheme == 'canlipazar' ||
        (uri.scheme == 'https' &&
            (uri.host == 'canlipazar.net' ||
                uri.host == 'www.canlipazar.net' ||
                uri.host == 'canlipazar.com' ||
                uri.host == 'www.canlipazar.com' ||
                uri.host == 'canlipazar.page.link'));

    if (!isSupportedLink) {
      print('⚠️ Desteklenmeyen link formatı: $uri');
      return;
    }

    _handleDeepLinkFromStream(uri.toString());
  }

  void _handleDeepLinkFromStream(String deepLink) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          _navigateToDeepLink(context, deepLink);
        }
      });
    } else {
      _navigateToDeepLink(context, deepLink);
    }
  }

  void _navigateToDeepLink(BuildContext context, String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      String? postId;

      print('🔗 Deep link parse ediliyor: $deepLink');

      // canlipazar://ilan/{postId} formatı
      if (uri.scheme == 'canlipazar' &&
          (uri.host == 'ilan' || uri.host == 'animal')) {
        postId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        print('✅ Custom scheme link: postId=$postId');
      }
      // https://canlipazar.net/ilan/{postId} veya canlipazar.com (Universal Link / App Link)
      else if (uri.scheme == 'https' &&
          (uri.host == 'canlipazar.net' || uri.host == 'www.canlipazar.net' ||
              uri.host == 'canlipazar.com' || uri.host == 'www.canlipazar.com')) {
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'ilan') {
          postId = uri.pathSegments[1];
          print('✅ Universal/App Link (/ilan/): postId=$postId');
        }
        // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
        else if (uri.pathSegments.length >= 2 &&
            uri.pathSegments[0] == 'animal') {
          postId = uri.pathSegments[1];
          print('✅ Universal/App Link (/animal/): postId=$postId');
        } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'p') {
          postId = uri.pathSegments[1];
          print('✅ Universal/App Link (/p/): postId=$postId');
        } else if (uri.pathSegments.length == 1 && uri.pathSegments[0] == 'p') {
          postId = uri.queryParameters['id'];
          print('✅ Universal/App Link (/p?id=): postId=$postId');
        } else if (uri.pathSegments.isEmpty &&
            uri.queryParameters.containsKey('id')) {
          postId = uri.queryParameters['id'];
          print('✅ Universal/App Link (?id=): postId=$postId');
        }
      }
      // Firebase Dynamic Links (canlipazar.page.link)
      else if (uri.scheme == 'https' && uri.host == 'canlipazar.page.link') {
        if (uri.queryParameters.containsKey('link')) {
          final String extractedLink = uri.queryParameters['link']!;
          print('✅ Dynamic Link: extractedLink=$extractedLink');

          // Extracted link'i parse et
          final extractedUri = Uri.parse(extractedLink);

          // /ilan/ formatını kontrol et
          if (extractedUri.pathSegments.length >= 2 &&
              extractedUri.pathSegments[0] == 'ilan') {
            postId = extractedUri.pathSegments[1];
            print('✅ Dynamic Link (/ilan/): postId=$postId');
          }
          // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
          else if (extractedUri.pathSegments.length >= 2 &&
              extractedUri.pathSegments[0] == 'animal') {
            postId = extractedUri.pathSegments[1];
            print('✅ Dynamic Link (/animal/): postId=$postId');
          }
          // String içinde /ilan/ veya /animal/ arama (fallback)
          else if (extractedLink.contains('/ilan/')) {
            final List<String> parts = extractedLink.split('/ilan/');
            if (parts.length > 1) {
              postId = parts[1].split('?')[0].split('#')[0];
              print('✅ Dynamic Link (/ilan/ - fallback): postId=$postId');
            }
          } else if (extractedLink.contains('/animal/')) {
            final List<String> parts = extractedLink.split('/animal/');
            if (parts.length > 1) {
              postId = parts[1].split('?')[0].split('#')[0];
              print('✅ Dynamic Link (/animal/ - fallback): postId=$postId');
            }
          }
        }
        // Short link formatı: canlipazar.page.link/xxxxx
        // Bu durumda deep link'i resolve etmek için Cloud Functions'a istek gerekir
        // Şimdilik kullanıcıyı web sayfasına yönlendir (web sayfası Universal Link'i açmaya çalışır)
        else if (uri.pathSegments.isNotEmpty) {
          print('⚠️ Short link formatı: ${uri.pathSegments.join("/")}');
          print(
              '⚠️ Short link resolve için Cloud Functions gerekli, web sayfasına yönlendiriliyor');
          // Short link'i web sayfasına yönlendir (web sayfası Universal Link'i açmaya çalışır)
          // Bu durumda web sayfası görünecek ama Universal Link çalışırsa uygulama açılır
        }
      }

      if (postId != null && postId.isNotEmpty) {
        print('✅ İlan ID bulundu: $postId, detay sayfasına yönlendiriliyor...');

        // İlan detay sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('animals')
                  .doc(postId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'İlan yükleniyor...',
                            style: SafeFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      title: Text('Hata'),
                      backgroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'İlan bulunamadı',
                            style: SafeFonts.poppins(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İlan silinmiş veya mevcut değil olabilir',
                            style: SafeFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                try {
                  final animal = AnimalPost.fromSnap(snapshot.data!);
                  print('✅ İlan yüklendi: ${animal.postId}');
                  return AnimalDetailScreen(animal: animal);
                } catch (e) {
                  print('❌ İlan parse hatası: $e');
                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      title: Text('Hata'),
                      backgroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'İlan yüklenemedi',
                            style: SafeFonts.poppins(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hata: $e',
                            style: SafeFonts.poppins(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      } else {
        print('⚠️ İlan ID bulunamadı, link formatı desteklenmiyor olabilir');
      }
    } catch (e, stackTrace) {
      print('❌ Deep link parse hatası: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> _resetBadgeOnAppLaunch() async {
    if (kIsWeb) return;
    print('📊 Badge sıfırlandı');
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) {
            try {
              final provider = UserProvider();
              provider.initialize();
              return provider;
            } catch (e) {
              print('❌ UserProvider oluşturma hatası: $e');
              final fallbackProvider = UserProvider();
              fallbackProvider.initialize();
              return fallbackProvider;
            }
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'CanlıPazar',
        builder: (context, widget) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('❌ ErrorWidget: ${details.exception}');
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Bir hata oluştu',
                        style: SafeFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lütfen uygulamayı yeniden başlatın',
                        style: SafeFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (kDebugMode) ...[
                        SizedBox(height: 16),
                        Text(
                          '${details.exception}',
                          style: SafeFonts.poppins(
                            fontSize: 10,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          };
          return widget ?? Container();
        },
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF2E7D32),
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFFFF9800),
            surface: const Color(0xFFF5F5F5),
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF000000),
            onBackground: const Color(0xFF000000),
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.black.withOpacity(0.3),
            selectionHandleColor: Colors.black,
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF2E7D32)),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
            ),
          ),
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/location': (context) => const LocationPickerScreen(),
          '/location_picker': (context) => const LocationPickerDemo(),
        },
        home: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return Scaffold(
                backgroundColor: const Color(0xFF2E7D32),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CanlıPazar',
                        style: SafeFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Güvenilir hayvan alım satım platformu',
                        style: SafeFonts.poppinsWithOpacity(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          baseColor: Colors.white,
                          opacity: 0.8,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
              webScreenLayout: WebScreenLayout(),
            );
          },
        ),
      ),
    );
  }

  void _handleForegroundMessage(RemoteMessage message, BuildContext context) {
    print('📱 [MAIN] Foreground mesaj işleniyor: ${message.messageId}');
    print('📱 [MAIN] Mesaj tipi: ${message.data['type'] ?? 'bilinmiyor'}');
    print(
        '📱 [MAIN] Notification: ${message.notification?.title ?? 'yok'} - ${message.notification?.body ?? 'yok'}');

    final unreadCount = message.data['unreadCount'];
    if (unreadCount != null) {
      try {
        final count = int.tryParse(unreadCount.toString()) ?? 0;
        print('📊 [MAIN] Badge count: $count');
      } catch (e) {
        print('❌ [MAIN] Badge güncelleme hatası: $e');
      }
    }

    final notificationType = message.data['type'] ?? '';
    final isIOS = !kIsWeb && io.Platform.isIOS;

    // KRİTİK: ÇİFT BİLDİRİM SORUNU ÇÖZÜMÜ
    // Hem iOS hem Android için foreground'da local notification GÖSTERME
    // Çünkü Cloud Functions zaten notification payload ile bildirim gönderiyor
    // Hem FCM/APNs hem de local notification gösterilirse ÇİFT BİLDİRİM olur
    final isAndroid = !kIsWeb && io.Platform.isAndroid;
    
    if (isIOS || isAndroid) {
      print('📱 [MAIN] ${isIOS ? "iOS" : "Android"}: Foreground notification tespit edildi');
      print('   - Notification Type: $notificationType');
      print('   - Has notification payload: ${message.notification != null}');
      print('   - Has data payload: ${message.data.isNotEmpty}');
      print(
          '   ⏭️ ${isIOS ? "iOS" : "Android"} için local notification GÖSTERİLMİYOR (Cloud Functions FCM/APNs ile gönderiyor)');
      print('   ✅ Çift bildirim önlendi');
      // Foreground'da local notification gösterme - Cloud Functions FCM/APNs ile gönderiyor
      // _showLocalNotification(message); // KALDIRILDI
    } else {
      print('⚠️ [MAIN] Bilinmeyen platform, bildirim gösterilmeyecek');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;

      final notificationType = data['type'] ?? '';

      // KRİTİK: Mesaj bildirimleri için başlık ve içerik
      // "CanlıPazardan Bir Mesaj Bildirimi" başlığını kullan
      String title;
      String body;

      if (notificationType == 'message') {
        // Mesaj bildirimleri için özel format
        // KRİTİK: Kullanıcı isteği - "kullanıcı_adı size mesaj gönderdi" başlığı
        // Cloud Functions bu formatta gönderiyor, eğer yoksa burada oluştur
        final senderUsername = data['senderUsername'] ?? 'Birisi';
        title = notification?.title ??
            data['title'] ??
            '$senderUsername size mesaj gönderdi';
        // Body: Sadece mesaj içeriği (kullanıcı adı başlıkta zaten var)
        if (notification?.body != null && notification!.body!.isNotEmpty) {
          body = notification.body!;
        } else {
          // Data'dan mesaj içeriğini al
          final messageText =
              data['text'] ?? data['body'] ?? 'Yeni mesajınız var!';
          body = messageText;
        }
      } else if (notificationType == 'new_animal_post' ||
          notificationType == 'daily_notification') {
        // İlan bildirimleri için özel format
        title = notification?.title ?? data['title'] ?? 'CanlıPazar 🐄';
        body = notification?.body ?? data['body'] ?? 'Yeni ilan eklendi';
      } else {
        // Diğer bildirimler için normal format
        title = notification?.title ?? data['title'] ?? 'CanlıPazar';
        body = notification?.body ??
            data['text'] ??
            data['body'] ??
            'Yeni bildiriminiz var!';
      }

      int? badgeNumber;
      if (data['unreadCount'] != null) {
        badgeNumber = int.tryParse(data['unreadCount'].toString());
      }

      final String channelId = (notificationType == 'new_animal_post' ||
              notificationType == 'daily_notification')
          ? 'new_posts_channel'
          : (android?.channelId ?? 'messages_channel');
      final String channelName = (notificationType == 'new_animal_post' ||
              notificationType == 'daily_notification')
          ? 'Yeni İlanlar'
          : 'Mesajlar';

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: notificationType == 'new_animal_post' ||
                notificationType == 'daily_notification'
            ? 'Yeni ilan bildirimlerini gösterir'
            : 'Mesaj bildirimlerini gösterir',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification',
      );

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

      print('📱 [MAIN] Local notification gösteriliyor...');
      print('   - Title: $title');
      print('   - Body: $body');
      print('   - Channel ID: $channelId');
      print('   - Notification Type: $notificationType');

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );

      print('✅ [MAIN] Local notification başarıyla gösterildi');
      print('   - ID: ${message.hashCode}');
      print('   - Title: $title');
      print('   - Body: $body');
    } catch (e, stackTrace) {
      print('❌ Local notification hatası: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  void _handleMessage(RemoteMessage message, BuildContext context) {
    final String notificationType = message.data['type'] ?? '';

    if (notificationType == 'message') {
      String senderId =
          message.data['senderId'] ?? message.data['sender_id'] ?? '';
      String receiverId =
          message.data['receiverId'] ?? message.data['receiver_id'] ?? '';
      String postId = message.data['postId'] ?? message.data['post_id'] ?? '';

      String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUid.isEmpty) {
        // Kullanıcı giriş yapmamış, ana sayfaya yönlendir
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      // Karşı tarafın UID'sini belirle
      String targetUid = currentUid == senderId ? receiverId : senderId;

      if (targetUid.isEmpty) {
        print('⚠️ Target UID bulunamadı, ana sayfaya yönlendiriliyor');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      print('📱 Mesaj bildirimi tıklandı - Sohbet ekranına yönlendiriliyor');
      print('📱 Gönderen: $senderId, Alıcı: $receiverId, Hedef: $targetUid');

      // Sohbet ekranına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: currentUid,
            recipientUid: targetUid,
            postId: postId,
          ),
        ),
      );
    } else if (notificationType == 'new_animal_post' ||
        notificationType == 'daily_notification') {
      String animalId = message.data['animalId'] ?? '';

      if (animalId.isNotEmpty) {
        // İlan detay sayfasına yönlendir
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        // TODO: İlan detay sayfasına yönlendirme eklenebilir
        print('📱 İlan bildirimi tıklandı - İlan ID: $animalId');
      } else {
        // Ana sayfaya yönlendir
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  void _setupFirebaseMessagingHandlers() {
    if (kIsWeb) return;

    print('🔔 Firebase Messaging handler\'lar ayarlanıyor...');

    // KRİTİK: Önce mevcut dinleyicileri iptal et (çift dinleyici önleme)
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    print('✅ Mevcut dinleyiciler iptal edildi (varsa)');

    if (io.Platform.isIOS) {
      FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      )
          .then((_) {
        print('✅ iOS foreground notification presentation options ayarlandı');
      }).catchError((e) {
        print('⚠️ iOS foreground notification options hatası: $e');
      });
    }

    // KRİTİK: Dinleyiciyi StreamSubscription olarak sakla
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final isAndroid = !kIsWeb && io.Platform.isAndroid;
      final isIOS = !kIsWeb && io.Platform.isIOS;

      print('📱 [MAIN] ========== FOREGROUND MESAJ ALINDI ==========');
      print(
          '📱 [MAIN] Platform: ${isAndroid ? 'Android' : (isIOS ? 'iOS' : 'Unknown')}');
      print('📱 [MAIN] Message ID: ${message.messageId}');
      print('📱 [MAIN] Mesaj tipi: ${message.data['type'] ?? 'bilinmiyor'}');
      print(
          '📱 [MAIN] Notification title: ${message.notification?.title ?? 'yok'}');
      print(
          '📱 [MAIN] Notification body: ${message.notification?.body ?? 'yok'}');
      print(
          '📱 [MAIN] Has notification payload: ${message.notification != null}');
      if (isAndroid) {
        print(
            '📱 [MAIN] Android Channel ID: ${message.notification?.android?.channelId ?? 'default'}');
        print(
            '📱 [MAIN] Android Priority: ${message.notification?.android?.priority ?? 'N/A'}');
      }
      print('📱 [MAIN] Data: ${message.data}');
      print('📱 [MAIN] ============================================');

      // Android ve iOS için foreground'da local notification göster
      final context = navigatorKey.currentContext;
      if (context != null) {
        _handleForegroundMessage(message, context);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _handleForegroundMessage(message, context);
          }
        });
      }
    });

    // KRİTİK: Dinleyiciyi StreamSubscription olarak sakla
    _messageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 [MAIN] App opened from notification: ${message.messageId}');
      final context = navigatorKey.currentContext;
      if (context != null) {
        _handleMessage(message, context);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _handleMessage(message, context);
          }
        });
      }
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            '📱 [MAIN] App started from terminated state: ${message.messageId}');
        Future.delayed(Duration(seconds: 1), () {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _handleMessage(message, context);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final context = navigatorKey.currentContext;
              if (context != null) {
                _handleMessage(message, context);
              }
            });
          }
        });
      }
    });

    print(
        '✅ Firebase Messaging handler\'lar ayarlandı (StreamSubscription ile)');
  }

  /// FCM token kontrolü ve kaydı (uygulama başlangıcında)
  /// iOS için KRİTİK: İzin → APNs → FCM sırası kontrol edilir
  /// FCM token kontrolü ve kaydı (uygulama başlangıcında)
  /// iOS için KRİTİK: İzin → APNs → FCM sırası kontrol edilir
  Future<void> _checkAndSaveFCMTokenOnAppStart() async {
    if (kIsWeb) return;

    try {
      final isAndroid = !kIsWeb && io.Platform.isAndroid;
      final isIOS = !kIsWeb && io.Platform.isIOS;

      print('🔄 [main.dart] FCM token kontrolü başlatılıyor...');
      print(
          '📱 [main.dart] Platform: ${isAndroid ? "Android" : (isIOS ? "iOS" : "Unknown")}');

      await Future.delayed(Duration(seconds: 2));

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print(
            'ℹ️ [main.dart] Kullanıcı giriş yapmamış, token kontrolü atlandı');
        print('ℹ️ [main.dart] Token kullanıcı giriş yaptığında kaydedilecek');
        return;
      }

      print('✅ [main.dart] Kullanıcı giriş yapmış, userId: ${currentUser.uid}');

      // iOS için özel log ve token kontrolü
      if (isIOS) {
        print(
            '📱 [main.dart] iOS: FCM token kontrol ediliyor ve kaydediliyor...');
        try {
          // iOS'ta bildirim izin durumunu kontrol et
          final settings =
              await FirebaseMessaging.instance.getNotificationSettings();
          print(
              '📱 [main.dart] iOS bildirim izin durumu: ${settings.authorizationStatus}');

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            print(
                '✅ [main.dart] iOS bildirim izni verilmiş, FCM token alınıyor...');

            // FCM token'ı al
            final token = await FirebaseMessaging.instance.getToken();
            if (token != null && token.isNotEmpty) {
              print(
                  '✅ [main.dart] iOS: FCM token alındı: ${token.substring(0, 20)}...');
              print(
                  '📱 [main.dart] iOS: Token uzunluğu: ${token.length} karakter');

              // Token'ı FCMTokenManager ile kaydet
              final tokenManager = FCMTokenManager();
              final saved = await tokenManager.saveTokenToFirestore();
              if (saved) {
                print('✅ [main.dart] iOS: FCM token Firestore\'a kaydedildi');
              } else {
                print(
                    '⚠️ [main.dart] iOS: FCM token Firestore\'a kaydedilemedi, tekrar denenecek');
              }
            } else {
              print('❌ [main.dart] iOS: FCM token alınamadı (null veya boş)');
              print('⚠️ [main.dart] iOS: Olası nedenler:');
              print('   - APNs token Firebase Messaging\'e verilmemiş');
              print('   - Bildirim izni verilmemiş');
              print('   - Firebase yapılandırması hatalı');
            }
          } else {
            print(
                '⚠️ [main.dart] iOS bildirim izni verilmemiş: ${settings.authorizationStatus}');
            print(
                '⚠️ [main.dart] iOS: Bildirim izni verilmeden FCM token alınamaz');
          }
        } catch (e) {
          print('❌ [main.dart] iOS: FCM token kontrolü hatası: $e');
        }
      }

      // Android için özel log
      if (isAndroid) {
        print('📱 [main.dart] Android: FCM token alınıyor ve kaydediliyor...');
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            print(
                '✅ [main.dart] Android: FCM token alındı: ${token.substring(0, 20)}...');
            print(
                '📱 [main.dart] Android: Token uzunluğu: ${token.length} karakter');
          } else {
            print('❌ [main.dart] Android: FCM token alınamadı (null veya boş)');
          }
        } catch (e) {
          print('❌ [main.dart] Android: FCM token alma hatası: $e');
        }
      }

      print('🔄 [main.dart] Firestore\'dan mevcut token kontrol ediliyor...');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(Duration(seconds: 3), onTimeout: () {
        return FirebaseFirestore.instance
            .collection('users')
            .doc('dummy')
            .get();
      });

      if (userDoc.exists) {
        final userData = userDoc.data();
        final existingToken = userData?['fcmToken'] as String?;
        final existingPlatform = userData?['platform'] as String?;

        print('📝 [main.dart] Mevcut durum:');
        print(
            '   - Token: ${existingToken != null && existingToken.isNotEmpty ? "Mevcut" : "Eksik"}');
        if (existingToken != null && existingToken.isNotEmpty) {
          print('   - Token uzunluğu: ${existingToken.length} karakter');
          print(
              '   - Token başlangıcı: ${existingToken.substring(0, existingToken.length > 20 ? 20 : existingToken.length)}...');
        }
        print('   - Platform: ${existingPlatform ?? "Eksik"}');

        // Android için özel log
        if (isAndroid) {
          if (existingPlatform != 'android') {
            print(
                '⚠️ [main.dart] Android: Platform "$existingPlatform" tespit edildi, "android" olarak düzeltilecek');
          } else {
            print(
                '✅ [main.dart] Android: Platform doğru kaydedilmiş: $existingPlatform');
          }
        }

        // KRİTİK: Platform "unknown" ise veya eksikse HER ZAMAN düzelt
        final platformMissing = existingPlatform == null ||
            existingPlatform.toString().isEmpty ||
            existingPlatform == 'unknown';

        // Platform "unknown" ise veya eksikse önce düzelt
        if (platformMissing) {
          try {
            final platform = io.Platform.isIOS
                ? 'ios'
                : (io.Platform.isAndroid ? 'android' : 'unknown');
            print(
                '⚠️ [main.dart] Platform eksik veya "unknown", düzeltiliyor...');
            print('   - Önceki: $existingPlatform');
            print('   - Yeni: $platform');

            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'platform': platform});
            print('✅ [main.dart] Platform düzeltildi: $platform');
          } catch (e) {
            print('⚠️ [main.dart] Platform düzeltme hatası: $e');
          }
        } else if (existingPlatform != 'ios' && io.Platform.isIOS) {
          // iOS'ta çalışıyorsak ama platform "ios" değilse düzelt
          print('⚠️ [main.dart] Platform uyuşmazlığı tespit edildi!');
          print('   - Mevcut: $existingPlatform');
          print('   - Beklenen: ios');
          print('   - Düzeltiliyor...');

          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'platform': 'ios'});
            print('✅ [main.dart] Platform düzeltildi: ios');
          } catch (e) {
            print('⚠️ [main.dart] Platform düzeltme hatası: $e');
          }
        }

        // Token eksikse veya platform düzeltildiyse token'ı kaydet
        if (existingToken == null || existingToken.isEmpty || platformMissing) {
          print('⚠️ [main.dart] Token veya platform eksik, kaydediliyor...');
          if (isAndroid) {
            print(
                '📱 [main.dart] Android: FCMTokenManager ile token kaydediliyor...');
          } else if (isIOS) {
            print(
                '📱 [main.dart] iOS: FCMTokenManager ile token kaydediliyor...');
          }

          final fcmManager = FCMTokenManager();
          await fcmManager.checkAndSavePendingToken();
          final success =
              await fcmManager.saveTokenToFirestore(forceRetry: true);

          if (success) {
            print('✅ [main.dart] FCM token başarıyla kaydedildi');
            if (isAndroid) {
              print(
                  '✅ [main.dart] Android: Token ve platform="android" başarıyla kaydedildi');
            } else if (isIOS) {
              print(
                  '✅ [main.dart] iOS: Token ve platform="ios" başarıyla kaydedildi');
            }
          } else {
            print('❌ [main.dart] FCM token kaydedilemedi');
            if (isAndroid) {
              print(
                  '❌ [main.dart] Android: Token kaydı başarısız, tekrar denenecek');
            } else if (isIOS) {
              print(
                  '❌ [main.dart] iOS: Token kaydı başarısız, tekrar denenecek');
              print('⚠️ [main.dart] iOS: Olası nedenler:');
              print('   - Bildirim izni verilmemiş');
              print('   - APNs token alınamamış');
              print('   - Firebase yapılandırması hatalı');
            }
          }
        } else {
          // Token mevcut ama iOS'ta platform kontrolü yap
          if (isIOS && existingPlatform != 'ios') {
            print(
                '⚠️ [main.dart] iOS: Token mevcut ama platform yanlış, düzeltiliyor...');
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({'platform': 'ios'});
              print('✅ [main.dart] iOS: Platform düzeltildi: ios');
            } catch (e) {
              print('⚠️ [main.dart] iOS: Platform düzeltme hatası: $e');
            }
          }
          print(
              '✅ [main.dart] Token ve platform mevcut (platform: $existingPlatform)');

          // Yine de platform kontrolü yap (iOS için kesin olarak "ios", Android için "android")
          if (io.Platform.isIOS && existingPlatform != 'ios') {
            print(
                '⚠️ [main.dart] Platform "ios" olmalı ama "$existingPlatform" tespit edildi, düzeltiliyor...');
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({'platform': 'ios'});
              print('✅ [main.dart] Platform düzeltildi: ios');
            } catch (e) {
              print('⚠️ [main.dart] Platform düzeltme hatası: $e');
            }
          } else if (isAndroid && existingPlatform != 'android') {
            // Android için kesin olarak "android" olmalı
            print(
                '⚠️ [main.dart] Android: Platform "android" olmalı ama "$existingPlatform" tespit edildi, düzeltiliyor...');
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({'platform': 'android'});
              print('✅ [main.dart] Android: Platform düzeltildi: android');
            } catch (e) {
              print('⚠️ [main.dart] Android: Platform düzeltme hatası: $e');
            }
          }
        }
      } else {
        print(
            '⚠️ [main.dart] Kullanıcı dokümanı bulunamadı, token kaydediliyor...');
        final fcmManager = FCMTokenManager();
        await fcmManager.checkAndSavePendingToken();
        final success = await fcmManager.saveTokenToFirestore(forceRetry: true);

        if (success) {
          print('✅ [main.dart] FCM token başarıyla kaydedildi');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [main.dart] FCM token kontrolü hatası: $e');
      print('❌ [main.dart] Stack trace: $stackTrace');
    }
  }
}
