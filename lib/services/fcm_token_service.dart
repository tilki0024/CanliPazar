import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// FCM Token yönetimi için servis
/// Kullanıcı giriş yaptığında, token yenilendiğinde ve uygulama açıldığında çalışır
class FCMTokenService {
  static final FCMTokenService _instance = FCMTokenService._internal();
  factory FCMTokenService() => _instance;
  FCMTokenService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // Use lazy getter to avoid initializing Firestore before settings are configured
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _retryTimer;
  bool _isRetrying = false;
  static const int _maxRetries = 3;
  static const int _maxPeriodicRetries = 10; // 30 saniye * 10 = 5 dakika
  int _periodicRetryCount = 0;
  int _retryCount = 0;

  /// FCM token'ı al ve Firestore'a kaydet (retry mekanizması ile)
  Future<void> initializeAndSaveToken({bool forceRetry = false}) async {
    try {
      // Web platformunda farklı işlem yap
      if (kIsWeb) {
        print('⚠️ FCM Token Service: Web platformunda çalışıyor, token kaydedilmiyor');
        return;
      }

      // Kullanıcı giriş yapmış mı kontrol et
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ FCM Token Service: Kullanıcı giriş yapmamış');
        return;
      }

      // Bildirim izni iste veya kontrol et
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ FCM Token Service: Bildirim izni verildi (${settings.authorizationStatus})');

        // Token'ı al (retry ile)
        bool success = await _getAndSaveTokenWithRetry(currentUser.uid, forceRetry: forceRetry);
        
        if (success) {
          _retryCount = 0; // Başarılı olursa retry sayacını sıfırla
          _periodicRetryCount = 0; // Periyodik retry sayacını da sıfırla
          
          // Token yenilendiğinde dinle
          _messaging.onTokenRefresh.listen((String newToken) {
            print('🔄 FCM Token yenilendi: ${newToken.substring(0, 20)}...');
            _saveTokenToFirestoreWithRetry(currentUser.uid, newToken);
          });
        } else {
          // Başarısız olursa periyodik retry başlat
          _startPeriodicRetry(currentUser.uid);
        }
      } else {
        print('❌ FCM Token Service: Bildirim izni reddedildi (${settings.authorizationStatus})');
        // İzin reddedilirse bile periyodik olarak tekrar dene (kullanıcı izin verebilir)
        _startPeriodicRetry(currentUser.uid);
      }
    } catch (e, stackTrace) {
      print('❌ FCM Token Service hatası: $e');
      print('❌ Stack trace: $stackTrace');
      // Hata olursa retry başlat
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _startPeriodicRetry(currentUser.uid);
      }
    }
  }

  /// Token'ı al ve kaydet (retry mekanizması ile)
  Future<bool> _getAndSaveTokenWithRetry(String userId, {bool forceRetry = false, int attempt = 1}) async {
    try {
      // Token'ı al
      String? token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        print('📱 FCM Token alındı (deneme $attempt): ${token.substring(0, 20)}...');
        
        // Firestore'daki token ile karşılaştır
        bool needsUpdate = await _checkTokenNeedsUpdate(userId, token);
        
        if (needsUpdate) {
          bool saved = await _saveTokenToFirestoreWithRetry(userId, token, attempt: attempt);
          if (saved) {
            // Token'ın gerçekten kaydedildiğini doğrula
            bool verified = await _verifyTokenSaved(userId, token);
            if (verified) {
              print('✅ FCM Token başarıyla kaydedildi ve doğrulandı: $userId');
              _retryCount = 0;
              stopPeriodicRetry(); // Başarılı olursa periyodik retry'ı durdur
              return true;
            } else {
              print('⚠️ FCM Token kaydedildi ama doğrulanamadı: $userId');
              // Doğrulama başarısız olsa bile kayıt başarılı sayılabilir (Firestore gecikmesi olabilir)
              _retryCount = 0;
              stopPeriodicRetry();
              return true;
            }
          } else {
            print('❌ FCM Token kaydedilemedi: $userId');
          }
        } else {
          print('✅ FCM Token zaten güncel: $userId');
          _retryCount = 0;
          stopPeriodicRetry(); // Zaten güncelse periyodik retry'ı durdur
          return true;
        }
      } else {
        print('⚠️ FCM Token alınamadı (deneme $attempt)');
      }
    } catch (e, stackTrace) {
      print('❌ Token alma hatası (deneme $attempt): $e');
      print('❌ Stack trace: $stackTrace');
    }

    // Retry mekanizması
    if (attempt < _maxRetries && (forceRetry || attempt == 1)) {
      int delay = (attempt * 2); // Exponential backoff: 2s, 4s, 6s
      print('🔄 Token kaydı tekrar deneniyor (${attempt + 1}/$_maxRetries) - $delay saniye sonra...');
      await Future.delayed(Duration(seconds: delay));
      return await _getAndSaveTokenWithRetry(userId, forceRetry: forceRetry, attempt: attempt + 1);
    }

    return false;
  }

  /// Firestore'daki token ile cihazdaki token'ı karşılaştır
  Future<bool> _checkTokenNeedsUpdate(String userId, String currentToken) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final storedToken = userDoc.data()?['fcmToken'] as String?;
        if (storedToken == null || storedToken.trim().isEmpty || storedToken != currentToken) {
          print('🔄 Token güncelleme gerekli: Firestore\'daki token farklı veya boş');
          return true;
        }
        return false;
      }
      return true; // Doküman yoksa kaydet
    } catch (e, stackTrace) {
      print('⚠️ Token kontrolü hatası: $e');
      print('⚠️ Stack trace: $stackTrace');
      return true; // Hata olursa güncelle
    }
  }

  /// Periyodik retry başlat (her 30 saniyede bir, max 5 dakika)
  void _startPeriodicRetry(String userId) {
    if (_isRetrying) {
      print('⚠️ Periyodik retry zaten çalışıyor');
      return;
    }

    if (_periodicRetryCount >= _maxPeriodicRetries) {
      print('⚠️ Maksimum periyodik retry sayısına ulaşıldı ($_maxPeriodicRetries)');
      return;
    }

    _isRetrying = true;
    _periodicRetryCount++;
    
    print('🔄 Periyodik retry başlatıldı (${_periodicRetryCount}/$_maxPeriodicRetries) - 30 saniye sonra...');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 30), () async {
      _isRetrying = false;
      print('🔄 Periyodik retry çalışıyor...');
      await initializeAndSaveToken(forceRetry: true);
    });
  }

  /// Periyodik retry'ı durdur
  void stopPeriodicRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _isRetrying = false;
    _periodicRetryCount = 0;
    print('✅ Periyodik retry durduruldu');
  }

  /// Token'ı Firestore'a kaydet (retry mekanizması ile)
  Future<bool> _saveTokenToFirestoreWithRetry(String userId, String token, {int attempt = 1}) async {
    try {
      // Platform bilgisini belirle
      String platform = 'unknown';
      if (!kIsWeb) {
        if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isAndroid) {
          platform = 'android';
        }
      }

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': platform, // Platform bilgisini ekle
      });
      print('✅ FCM Token Firestore\'a kaydedildi (deneme $attempt, platform: $platform): $userId');
      return true;
    } catch (e, stackTrace) {
      print('❌ FCM Token kaydetme hatası (deneme $attempt): $e');
      print('❌ Stack trace: $stackTrace');
      // Eğer update başarısız olursa (doküman yoksa), set dene
      try {
        // Platform bilgisini belirle
        String platform = 'unknown';
        if (!kIsWeb) {
          if (Platform.isIOS) {
            platform = 'ios';
          } else if (Platform.isAndroid) {
            platform = 'android';
          }
        }

        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': platform, // Platform bilgisini ekle
        }, SetOptions(merge: true));
        print('✅ FCM Token Firestore\'a set edildi (merge, deneme $attempt, platform: $platform): $userId');
        return true;
      } catch (e2, stackTrace2) {
        print('❌ FCM Token set etme hatası (deneme $attempt): $e2');
        print('❌ Stack trace: $stackTrace2');
        
        // Retry mekanizması
        if (attempt < _maxRetries) {
          int delay = (attempt * 2); // Exponential backoff
          print('🔄 Token kaydı tekrar deneniyor (${attempt + 1}/$_maxRetries) - $delay saniye sonra...');
          await Future.delayed(Duration(seconds: delay));
          return await _saveTokenToFirestoreWithRetry(userId, token, attempt: attempt + 1);
        }
      }
    }
    return false;
  }

  /// Token'ın Firestore'a kaydedildiğini doğrula
  Future<bool> _verifyTokenSaved(String userId, String expectedToken) async {
    try {
      // Kısa bir gecikme sonrası kontrol et (Firestore gecikmesi olabilir)
      await Future.delayed(Duration(milliseconds: 500));
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final storedToken = userDoc.data()?['fcmToken'] as String?;
        if (storedToken != null && storedToken.trim().isNotEmpty && storedToken == expectedToken) {
          print('✅ Token doğrulandı: Firestore\'da mevcut ve eşleşiyor');
          return true;
        } else {
          print('⚠️ Token doğrulanamadı: Firestore\'daki token farklı veya boş');
          print('⚠️ Beklenen: ${expectedToken.substring(0, 20)}...');
          print('⚠️ Mevcut: ${storedToken?.substring(0, 20) ?? "null"}...');
          return false;
        }
      } else {
        print('⚠️ Token doğrulanamadı: Kullanıcı dokümanı bulunamadı');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Token doğrulama hatası: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }


  /// Token'ı sil (kullanıcı çıkış yaptığında)
  Future<void> deleteToken() async {
    try {
      stopPeriodicRetry(); // Periyodik retry'ı durdur
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        print('✅ FCM Token silindi: ${currentUser.uid}');
      }
    } catch (e, stackTrace) {
      print('❌ FCM Token silme hatası: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  /// Dispose - timer'ları temizle
  void dispose() {
    stopPeriodicRetry();
  }
}

