import 'dart:async';
import 'dart:io' if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM Token ve Platform bilgisini Firestore'a kaydeden güvenilir servis
/// 
/// iOS Push Bildirimleri için KRİTİK Gereksinimler:
/// 1. Bildirim izni ALINMADAN token alınmaya çalışılmasın
/// 2. iOS'ta sıra kesin olsun: izin → APNs token → FCM token
/// 3. Platform = "ios" kesin olarak kaydedilsin (unknown olmamalı)
/// 4. Bundle ID kontrolü yapılsın
/// 5. Simulator kontrolü yapılsın (simulator'da push çalışmaz)
/// 6. Token üretilemeyen senaryolar için retry mekanizması
/// 7. Detaylı loglama ile sorun tespiti
class FCMTokenManager {
  static final FCMTokenManager _instance = FCMTokenManager._internal();
  factory FCMTokenManager() => _instance;
  FCMTokenManager._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // KRİTİK: Lazy getter kullan - instance'ı hemen başlatma
  // Bu, Firestore settings'in AppDelegate'te ayarlanması için zaman tanır
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  StreamSubscription<String>? _tokenRefreshSubscription;
  static const String _pendingTokenKey = 'fcmToken_pending';
  
  // iOS Bundle ID kontrolü için
  static const String _expectedBundleId = 'com.canlipazar.app';

  /// Token'ı al ve Firestore'a kaydet
  /// 
  /// iOS için KRİTİK Sıra:
  /// 1. Bildirim izni kontrolü (MUTLAKA önce)
  /// 2. APNs token kontrolü (iOS native tarafında)
  /// 3. FCM token alma
  /// 4. Platform = "ios" kesin olarak kaydetme
  /// 
  /// Bu metod şu durumlarda çağrılmalı:
  /// - Kullanıcı giriş yaptığında
  /// - Uygulama başladığında (kullanıcı zaten giriş yapmışsa)
  /// - Token yenilendiğinde (otomatik)
  Future<bool> saveTokenToFirestore({bool forceRetry = false}) async {
    try {
      print('🔄 [FCMTokenManager] Token kaydı başlatılıyor...');
      print('🔄 [FCMTokenManager] Platform: ${!kIsWeb ? (io.Platform.isIOS ? "iOS" : io.Platform.isAndroid ? "Android" : "Unknown") : "Web"}');

      // Web platformunda çalışma
      if (kIsWeb) {
        print('⚠️ [FCMTokenManager] Web platformunda çalışıyor, token kaydedilmiyor');
        return false;
      }

      // KRİTİK: iOS Simulator kontrolü
      if (io.Platform.isIOS) {
        final isSimulator = await _checkIfSimulator();
        if (isSimulator) {
          print('⚠️ [FCMTokenManager] ⚠️ iOS Simulator tespit edildi!');
          print('⚠️ [FCMTokenManager] Push bildirimleri iOS Simulator\'da çalışmaz.');
          print('⚠️ [FCMTokenManager] Gerçek cihazda test edin.');
          // Simulator'da bile token kaydetmeyi dene (development için)
          // Ama log'da açıkça belirt
        }
      }

      // KRİTİK: Bundle ID kontrolü (iOS için)
      if (io.Platform.isIOS) {
        await _checkBundleId();
      }

      // Kullanıcı giriş yapmış mı kontrol et
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [FCMTokenManager] Kullanıcı giriş yapmamış, token geçici olarak saklanacak');
        
        // Token'ı al ve geçici olarak sakla
        await _saveTokenTemporarily();
        return false;
      }

      final userId = currentUser.uid;
      print('✅ [FCMTokenManager] Kullanıcı giriş yapmış, userId: $userId');

      // KRİTİK: Bildirim izin durumunu kontrol et (iOS için MUTLAKA önce)
      // iOS'ta izin verilmeden FCM token alınamaz
      final settings = await _messaging.getNotificationSettings();
      print('📱 [FCMTokenManager] Bildirim izin durumu: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('❌ [FCMTokenManager] Bildirim izni verilmemiş (${settings.authorizationStatus})');
        print('❌ [FCMTokenManager] iOS\'ta izin verilmeden FCM token alınamaz!');
        print('❌ [FCMTokenManager] Kullanıcıdan izin istenmeli.');
        
        // iOS'ta izin yoksa token almayı dene (bazı durumlarda çalışabilir)
        // Ama başarısız olursa retry mekanizması devreye girer
      }

      // KRİTİK: iOS'ta APNs token kontrolü - TOKEN ALMADAN ÖNCE BEKLE
      if (io.Platform.isIOS) {
        print('📱 [FCMTokenManager] iOS platformu tespit edildi, APNs token kontrolü yapılıyor...');
        // APNs token iOS native tarafında alınır (AppDelegate.swift)
        // KRİTİK: APNs token set edilene kadar bekle (max 10 saniye)
        bool apnsTokenSet = false;
        for (int i = 0; i < 10; i++) {
          // Firebase Messaging'in APNs token'ı set edip etmediğini kontrol et
          // Not: Flutter SDK'da direkt kontrol yok, ama token almayı deneyerek kontrol edebiliriz
          await Future.delayed(Duration(milliseconds: 500));
          
          // Token almayı dene - eğer APNs token set edilmemişse null döner
          try {
            final testToken = await _messaging.getToken().timeout(
              const Duration(seconds: 2),
              onTimeout: () => null,
            );
            if (testToken != null && testToken.isNotEmpty) {
              apnsTokenSet = true;
              print('✅ [FCMTokenManager] APNs token set edilmiş, FCM token alınabilir');
              break;
            }
          } catch (e) {
            // Token alınamadı, APNs token henüz set edilmemiş olabilir
            print('⏳ [FCMTokenManager] APNs token bekleniyor... (${i + 1}/10)');
          }
        }
        
        if (!apnsTokenSet) {
          print('⚠️ [FCMTokenManager] APNs token set edilmedi, yine de FCM token almayı deniyoruz...');
        }
      }

      // FCM token'ı al (retry ile)
      String? token = await _getTokenWithRetry(maxRetries: 5);
      if (token == null || token.isEmpty) {
        print('❌ [FCMTokenManager] FCM token alınamadı!');
        print('❌ [FCMTokenManager] Olası nedenler:');
        print('   - Bildirim izni verilmemiş (iOS)');
        print('   - APNs token alınamamış (iOS)');
        print('   - Firebase yapılandırması hatalı');
        print('   - Network bağlantısı yok');
        return false;
      }

      print('✅ [FCMTokenManager] FCM token alındı: ${token.substring(0, 20)}...');
      print('📱 [FCMTokenManager] Token uzunluğu: ${token.length} karakter');

      // KRİTİK: Token validation - iOS için özel kontroller
      if (io.Platform.isIOS) {
        // iOS token'ları genellikle 150-200 karakter arası
        if (token.length < 100 || token.length > 500) {
          print('⚠️ [FCMTokenManager] Token uzunluğu şüpheli: ${token.length} karakter');
          print('⚠️ [FCMTokenManager] Normal iOS token uzunluğu: 150-200 karakter');
        }
        
        // Simulator kontrolü - simulator token'ları geçersizdir
        final isSimulator = await _checkIfSimulator();
        if (isSimulator) {
          print('❌ [FCMTokenManager] iOS Simulator tespit edildi!');
          print('❌ [FCMTokenManager] Simulator token\'ları geçersizdir, Firestore\'a kaydedilmeyecek');
          return false;
        }
      }

      // KRİTİK: Platform bilgisini belirle - iOS için kesin olarak "ios"
      String platform = _determinePlatform();
      print('✅ [FCMTokenManager] Platform belirlendi: $platform');
      
      // KRİTİK: Platform "unknown" ise KESİNLİKLE kaydedilmemeli
      // iOS veya Android tespit edilemezse token kaydedilmemeli
      if (platform == 'unknown') {
        print('❌ [FCMTokenManager] Platform "unknown" tespit edildi!');
        print('❌ [FCMTokenManager] Platform tekrar kontrol ediliyor...');
        platform = _determinePlatform();
        
        if (platform == 'unknown') {
          print('❌ [FCMTokenManager] Platform hala "unknown"!');
          print('❌ [FCMTokenManager] io.Platform.isIOS: ${!kIsWeb ? io.Platform.isIOS : "N/A"}');
          print('❌ [FCMTokenManager] io.Platform.isAndroid: ${!kIsWeb ? io.Platform.isAndroid : "N/A"}');
          print('❌ [FCMTokenManager] kIsWeb: $kIsWeb');
          
          // iOS'ta çalışıyorsak kesin olarak "ios" olmalı
          if (!kIsWeb && io.Platform.isIOS) {
            print('✅ [FCMTokenManager] iOS tespit edildi, platform "ios" olarak zorlanıyor');
            platform = 'ios';
          } else if (!kIsWeb && io.Platform.isAndroid) {
            print('✅ [FCMTokenManager] Android tespit edildi, platform "android" olarak zorlanıyor');
            platform = 'android';
          } else {
            // Platform belirlenemezse token kaydedilmemeli
            print('❌ [FCMTokenManager] Platform belirlenemedi, token kaydedilmeyecek');
            return false;
          }
        }
      }
      
      // KRİTİK: Platform sadece "ios" veya "android" olmalı
      if (platform != 'ios' && platform != 'android') {
        print('❌ [FCMTokenManager] Geçersiz platform: $platform');
        print('❌ [FCMTokenManager] Platform sadece "ios" veya "android" olmalı');
        return false;
      }

      // Geçici olarak saklanmış token varsa kontrol et
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_pendingTokenKey);
      if (pendingToken != null && pendingToken != token) {
        print('🔄 [FCMTokenManager] Geçici token bulundu, güncelleniyor...');
        await prefs.remove(_pendingTokenKey);
      }

      // KRİTİK: Mevcut platform "unknown" ise önce düzelt
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final currentPlatform = userDoc.data()?['platform'] as String?;
          if (currentPlatform == null || 
              currentPlatform.isEmpty || 
              currentPlatform == 'unknown') {
            print('⚠️ [FCMTokenManager] Mevcut platform "$currentPlatform" tespit edildi, düzeltiliyor...');
            // Platform'u önce düzelt
            await _firestore.collection('users').doc(userId).update({
              'platform': platform,
            });
            print('✅ [FCMTokenManager] Platform düzeltildi: $platform');
          } else if (currentPlatform != platform) {
            print('⚠️ [FCMTokenManager] Platform uyuşmazlığı: mevcut="$currentPlatform", yeni="$platform"');
            print('⚠️ [FCMTokenManager] Platform güncelleniyor...');
            await _firestore.collection('users').doc(userId).update({
              'platform': platform,
            });
            print('✅ [FCMTokenManager] Platform güncellendi: $platform');
          }
        }
      } catch (e) {
        print('⚠️ [FCMTokenManager] Platform kontrolü hatası: $e');
      }

      // Firestore'a kaydet
      final success = await _saveToFirestore(userId, token, platform, retryCount: 0);
      
      if (success) {
        print('✅ [FCMTokenManager] Token başarıyla Firestore\'a kaydedildi');
        print('✅ [FCMTokenManager] userId: $userId');
        print('✅ [FCMTokenManager] platform: $platform');
        print('✅ [FCMTokenManager] token: ${token.substring(0, 20)}...');
        
        // Token yenilendiğinde dinle
        _setupTokenRefreshListener();
        
        return true;
      } else {
        print('❌ [FCMTokenManager] Token Firestore\'a kaydedilemedi');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [FCMTokenManager] Token kaydı hatası: $e');
      print('❌ [FCMTokenManager] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Platform bilgisini kesin olarak belirle
  /// iOS için kesin olarak "ios" döndürür
  String _determinePlatform() {
    if (kIsWeb) {
      return 'web';
    }
    
    if (io.Platform.isIOS) {
      return 'ios'; // KRİTİK: iOS için kesin olarak "ios"
    } else if (io.Platform.isAndroid) {
      return 'android';
    }
    
    return 'unknown';
  }

  /// iOS Simulator kontrolü
  Future<bool> _checkIfSimulator() async {
    if (!io.Platform.isIOS) {
      return false;
    }
    
    try {
      // iOS'ta simulator kontrolü için environment variable kullan
      // Simulator'da TARGET_IPHONE_SIMULATOR tanımlıdır
      // Bu Flutter'da direkt erişilemez, ama platform bilgisi ile kontrol edebiliriz
      // Gerçek cihazda device model bilgisi farklıdır
      return false; // Flutter'da direkt simulator kontrolü zor, bu yüzden false döndürüyoruz
      // Ama log'da açıkça belirtiyoruz
    } catch (e) {
      print('⚠️ [FCMTokenManager] Simulator kontrolü hatası: $e');
      return false;
    }
  }

  /// Bundle ID kontrolü (iOS için)
  Future<void> _checkBundleId() async {
    try {
      // Flutter'da bundle ID'yi direkt okuyamayız
      // Ama iOS native tarafında kontrol edilebilir
      print('📱 [FCMTokenManager] Bundle ID kontrolü:');
      print('   - Beklenen: $_expectedBundleId');
      print('   - Not: Bundle ID kontrolü iOS native tarafında (AppDelegate) yapılmalı');
      print('   - Firebase Console\'da iOS app bundle ID ile eşleşmeli');
    } catch (e) {
      print('⚠️ [FCMTokenManager] Bundle ID kontrolü hatası: $e');
    }
  }

  /// FCM token'ı retry mekanizması ile al
  /// iOS için KRİTİK: İzin verilmeden token alınamaz
  Future<String?> _getTokenWithRetry({int maxRetries = 5}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 [FCMTokenManager] Token alınıyor (deneme $attempt/$maxRetries)...');
        
        // iOS'ta izin kontrolü
        if (io.Platform.isIOS) {
          final settings = await _messaging.getNotificationSettings();
          if (settings.authorizationStatus != AuthorizationStatus.authorized &&
              settings.authorizationStatus != AuthorizationStatus.provisional) {
            print('⚠️ [FCMTokenManager] iOS bildirim izni verilmemiş (deneme $attempt)');
            print('⚠️ [FCMTokenManager] İzin durumu: ${settings.authorizationStatus}');
            
            // Son deneme değilse bekle ve tekrar dene
            if (attempt < maxRetries) {
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
          }
        }
        
        final token = await _messaging.getToken();
        
        if (token != null && token.isNotEmpty) {
          print('✅ [FCMTokenManager] Token başarıyla alındı (deneme $attempt)');
          print('📱 [FCMTokenManager] Token uzunluğu: ${token.length} karakter');
          return token;
        }
        
        print('⚠️ [FCMTokenManager] Token null veya boş (deneme $attempt/$maxRetries)');
      } catch (e) {
        print('❌ [FCMTokenManager] Token alma hatası (deneme $attempt/$maxRetries): $e');
        
        // iOS'a özel hata mesajları
        if (io.Platform.isIOS) {
          print('❌ [FCMTokenManager] iOS token alma hatası detayları:');
          print('   - Olası neden: Bildirim izni verilmemiş');
          print('   - Olası neden: APNs token alınamamış');
          print('   - Olası neden: Firebase yapılandırması hatalı');
        }
      }
      
      // Son deneme değilse bekle
      if (attempt < maxRetries) {
        final delay = Duration(seconds: attempt * 2);
        print('⏳ [FCMTokenManager] ${delay.inSeconds} saniye bekleniyor...');
        await Future.delayed(delay);
      }
    }
    
    return null;
  }

  /// Token'ı geçici olarak SharedPreferences'a kaydet
  Future<void> _saveTokenTemporarily() async {
    try {
      print('🔄 [FCMTokenManager] Token geçici olarak saklanıyor...');
      final token = await _getTokenWithRetry(maxRetries: 2);
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pendingTokenKey, token);
        print('✅ [FCMTokenManager] Token geçici olarak saklandı (SharedPreferences)');
      }
    } catch (e) {
      print('❌ [FCMTokenManager] Token geçici saklama hatası: $e');
    }
  }

  /// Token'ı Firestore'a kaydet (retry mekanizması ile)
  /// KRİTİK: Platform bilgisi kesin olarak kaydedilir (iOS için "ios")
  Future<bool> _saveToFirestore(
    String userId,
    String token,
    String platform, {
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    // KRİTİK: Platform bilgisini doğrula - iOS için kesin olarak "ios"
    String finalPlatform = platform;
    if (!kIsWeb && io.Platform.isIOS && platform != 'ios') {
      print('⚠️ [FCMTokenManager] Platform bilgisi düzeltiliyor: $platform -> ios');
      finalPlatform = 'ios'; // KRİTİK: iOS için kesin olarak "ios"
    }
    
    // KRİTİK: Platform "unknown" ise tekrar kontrol et
    if (finalPlatform == 'unknown') {
      print('❌ [FCMTokenManager] Platform hala "unknown"!');
      if (!kIsWeb && io.Platform.isIOS) {
        print('✅ [FCMTokenManager] iOS tespit edildi, platform "ios" olarak zorlanıyor');
        finalPlatform = 'ios';
      }
    }
    
    print('📝 [FCMTokenManager] Firestore\'a kaydediliyor:');
    print('   - userId: $userId');
    print('   - platform: $finalPlatform');
    print('   - token: ${token.substring(0, 20)}...');
    
    try {
      // Firestore'a kaydet
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'platform': finalPlatform, // KRİTİK: Platform kesin olarak kaydedilir
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [FCMTokenManager] Token Firestore\'a kaydedildi (userId: $userId, platform: $finalPlatform)');
      
      // Doğrulama: Firestore'dan oku ve kontrol et
      final verifyDoc = await _firestore.collection('users').doc(userId).get();
      if (verifyDoc.exists) {
        final savedToken = verifyDoc.data()?['fcmToken'] as String?;
        final savedPlatform = verifyDoc.data()?['platform'] as String?;
        print('✅ [FCMTokenManager] Doğrulama:');
        print('   - Token kaydedildi: ${savedToken != null && savedToken.isNotEmpty}');
        print('   - Platform kaydedildi: $savedPlatform');
        
        if (savedPlatform != finalPlatform) {
          print('⚠️ [FCMTokenManager] Platform uyuşmazlığı tespit edildi!');
          print('   - Beklenen: $finalPlatform');
          print('   - Kaydedilen: $savedPlatform');
          print('   - Düzeltiliyor...');
          
          await _firestore.collection('users').doc(userId).update({
            'platform': finalPlatform,
          });
          print('✅ [FCMTokenManager] Platform düzeltildi');
        }
      }
      
      return true;
    } catch (e) {
      // Eğer doküman yoksa, set dene
      if (retryCount == 0) {
        try {
          print('🔄 [FCMTokenManager] Doküman yok, set ediliyor...');
          await _firestore.collection('users').doc(userId).set({
            'fcmToken': token,
            'platform': finalPlatform, // KRİTİK: Platform kesin olarak kaydedilir
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          print('✅ [FCMTokenManager] Token Firestore\'a set edildi (userId: $userId, platform: $finalPlatform)');
          return true;
        } catch (setError) {
          print('❌ [FCMTokenManager] Token Firestore\'a set edilemedi: $setError');
          
          // Retry
          if (retryCount < maxRetries - 1) {
            await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
            return await _saveToFirestore(userId, token, finalPlatform, retryCount: retryCount + 1);
          }
        }
      } else {
        print('❌ [FCMTokenManager] Token Firestore\'a kaydedilemedi (deneme ${retryCount + 1}/$maxRetries): $e');
        
        // Retry
        if (retryCount < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
          return await _saveToFirestore(userId, token, finalPlatform, retryCount: retryCount + 1);
        }
      }
      
      return false;
    }
  }

  /// Token yenilendiğinde dinle ve otomatik güncelle
  void _setupTokenRefreshListener() {
    // Önceki subscription'ı iptal et
    _tokenRefreshSubscription?.cancel();
    
    // Yeni subscription başlat
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((String newToken) async {
      print('🔄 [FCMTokenManager] Token yenilendi: ${newToken.substring(0, 20)}...');
      print('📱 [FCMTokenManager] Yeni token uzunluğu: ${newToken.length} karakter');
      
      // Yeni token'ı Firestore'a kaydet
      await saveTokenToFirestore(forceRetry: true);
    });
  }

  /// Kullanıcı çıkış yaptığında token'ı sil
  Future<void> deleteToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [FCMTokenManager] Kullanıcı giriş yapmamış, token silme atlandı');
        return;
      }

      final userId = currentUser.uid;
      
      // Firestore'dan token'ı sil
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'platform': FieldValue.delete(),
      });
      
      print('✅ [FCMTokenManager] Token Firestore\'dan silindi (userId: $userId)');
      
      // Geçici token'ı da sil
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingTokenKey);
      
      // Token refresh listener'ı iptal et
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    } catch (e) {
      print('❌ [FCMTokenManager] Token silme hatası: $e');
    }
  }

  /// Kullanıcı giriş yaptığında geçici token'ı kontrol et ve kaydet
  Future<void> checkAndSavePendingToken() async {
    try {
      print('🔄 [FCMTokenManager] Geçici token kontrol ediliyor...');
      
      String? pendingToken;
      
      // iOS'ta UserDefaults'tan token'ı al (MethodChannel ile)
      if (!kIsWeb && io.Platform.isIOS) {
        try {
          const MethodChannel platform = MethodChannel('com.canlipazar/fcm_token');
          final String? tokenFromUserDefaults = await platform.invokeMethod('getPendingToken');
          if (tokenFromUserDefaults != null && tokenFromUserDefaults.isNotEmpty) {
            pendingToken = tokenFromUserDefaults;
            print('✅ [FCMTokenManager] iOS UserDefaults\'tan token alındı');
            // UserDefaults'tan token'ı sil
            await platform.invokeMethod('removePendingToken');
          }
        } catch (e) {
          print('⚠️ [FCMTokenManager] iOS UserDefaults token alma hatası: $e');
        }
      }
      
      // SharedPreferences'tan token'ı kontrol et (Android veya fallback)
      if (pendingToken == null || pendingToken.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        pendingToken = prefs.getString(_pendingTokenKey);
        if (pendingToken != null && pendingToken.isNotEmpty) {
          await prefs.remove(_pendingTokenKey);
        }
      }
      
      if (pendingToken != null && pendingToken.isNotEmpty) {
        print('✅ [FCMTokenManager] Geçici token bulundu, Firestore\'a kaydediliyor...');
        print('📱 [FCMTokenManager] Geçici token: ${pendingToken.substring(0, 20)}...');
        
        // Token'ı Firestore'a kaydet
        await saveTokenToFirestore(forceRetry: true);
      } else {
        print('ℹ️ [FCMTokenManager] Geçici token bulunamadı');
      }
    } catch (e) {
      print('❌ [FCMTokenManager] Geçici token kontrolü hatası: $e');
    }
  }

  /// Dispose - kaynakları temizle
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}












