import 'package:flutter/widgets.dart';
import 'package:firebase_analytics/firebase_analytics.dart' as firebase_analytics;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/models/user.dart';
import 'package:animal_trade/resources/auth_methods.dart';
import 'package:animal_trade/services/fcm_token_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();
  bool _isLoading = true;

  User? get getUser =>
      _user ??
      User(
        uid: '',
        email: '',
        username: '',
        photoUrl: '',
        bio: '',
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
        matchedWith: '',
        country: '',
        state: '',
        city: '',
        matchCount: 0,
        isPremium: false,
        numberOfSentGifts: 0,
        numberOfUnsentGifts: 0,
        giftSendingRate: '',
        isVerified: false,
        isConfirmed: false,
        giftPoint: 0,
        isRated: false,
        rateCount: 0,
        fcmToken: '',
        credit: 0,
      );

  bool get isLoading => _isLoading;

  // Initialize user provider with auth stream
  void initialize() async {
    print('🔄 UserProvider: Initialize başlatılıyor...');
    
    // İlk auth state'i hemen kontrol et (stream'den önce)
    // Bu sayede loading süresi kısalır ve beyaz ekran sorunu çözülür
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('🔄 UserProvider: İlk auth state kontrolü, currentUser: ${currentUser?.uid ?? "null"}');
      
      if (currentUser != null) {
        // Kullanıcı zaten giriş yapmış, hemen detayları al
        print('✅ UserProvider: Kullanıcı zaten giriş yapmış, detaylar alınıyor...');
        try {
          // KRİTİK: getUserDetails() çağrısına timeout ekle (2 saniye)
          // Firestore bağlantısı yoksa veya yavaşsa takılmasın
          User? user = await _authMethods.getUserDetails()
              .timeout(
                Duration(seconds: 2),
                onTimeout: () {
                  print('⚠️ UserProvider: getUserDetails timeout (2 saniye), varsayılan kullanıcı döndürülüyor');
                  // Timeout durumunda varsayılan kullanıcı döndür
                  return User(
                    uid: currentUser.uid,
                    email: currentUser.email ?? '',
                    username: '',
                    photoUrl: '',
                    bio: '',
                    followers: [],
                    following: [],
                    blocked: [],
                    blockedBy: [],
                    matchedWith: '',
                    country: '',
                    state: '',
                    city: '',
                    matchCount: 0,
                    isPremium: false,
                    numberOfSentGifts: 0,
                    numberOfUnsentGifts: 0,
                    giftSendingRate: '',
                    isVerified: false,
                    isConfirmed: false,
                    giftPoint: 0,
                    isRated: false,
                    rateCount: 0,
                    fcmToken: '',
                    credit: 0,
                  );
                },
              );
          _user = user;
          _isLoading = false;
          print('✅ UserProvider: Kullanıcı detayları alındı, isLoading: false');
          notifyListeners();
          
          // FCM token kaydı - ASYNC olarak devam ettir (loading'i bloklamasın)
          // Bu işlem arka planda devam edebilir, kullanıcıyı bekletmez
          Future.microtask(() async {
            try {
              print('🔄 UserProvider: FCM token kaydı başlatılıyor (async)...');
              
              // KRİTİK: Platform "unknown" ise önce düzelt
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .get();
                
                if (userDoc.exists) {
                  final currentPlatform = userDoc.data()?['platform'] as String?;
                  if (currentPlatform == null || 
                      currentPlatform.isEmpty || 
                      currentPlatform == 'unknown') {
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
                        .update({'platform': platform});
                    print('✅ UserProvider: Platform düzeltildi: $platform (önceki: $currentPlatform)');
                  }
                }
              } catch (e) {
                print('⚠️ UserProvider: Platform kontrolü hatası: $e');
              }
              
              final fcmManager = FCMTokenManager();
              await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
              await fcmManager.saveTokenToFirestore(forceRetry: true);
              print('✅ UserProvider: FCM token kaydı tamamlandı');
              
              // KRİTİK: Firebase Analytics'e platform bilgisini user property olarak gönder
              // Bu, Firebase Console → Users bölümünde platform bilgisinin görünmesi için GEREKLİ
              // iOS için kesin olarak "ios" gönderilir
              try {
                final analytics = firebase_analytics.FirebaseAnalytics.instance;
                String platform = 'unknown';
                if (!kIsWeb) {
                  if (io.Platform.isIOS) {
                    platform = 'ios'; // KRİTİK: iOS için kesin olarak "ios"
                  } else if (io.Platform.isAndroid) {
                    platform = 'android';
                  }
                }
                await analytics.setUserProperty(name: 'platform', value: platform);
                await analytics.setUserId(id: currentUser.uid);
                
                // KRİTİK: Platform event'i logla (iOS için özellikle önemli)
                await analytics.logEvent(
                  name: 'user_platform_set',
                  parameters: {
                    'platform': platform,
                    'user_id': currentUser.uid,
                  },
                );
                print('✅ UserProvider: Firebase Analytics platform user property ayarlandı: $platform');
              } catch (analyticsError) {
                print('⚠️ UserProvider: Firebase Analytics user property hatası: $analyticsError');
              }
            } catch (e, stackTrace) {
              print('❌ UserProvider: FCM token kaydı başarısız: $e');
              print('❌ UserProvider: Stack trace: $stackTrace');
            }
          });
        } catch (e) {
          print('❌ UserProvider: getUserDetails hatası: $e');
          _isLoading = false;
          notifyListeners();
        }
      } else {
        // Kullanıcı giriş yapmamış, loading'i kapat
        print('ℹ️ UserProvider: Kullanıcı giriş yapmamış');
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ UserProvider: İlk auth state kontrolü hatası: $e');
      _isLoading = false;
      notifyListeners();
    }
    
    // KRİTİK: Timeout mekanizması - 2 saniye sonra loading'i kapat (güvenlik için)
    // Beyaz ekran sorununu önlemek için timeout'u kısalttık
    Future.delayed(Duration(seconds: 2), () {
      if (_isLoading) {
        print('⚠️ UserProvider: Auth state timeout (2 saniye), loading kapatılıyor');
        _isLoading = false;
        notifyListeners();
      }
    });
    
    // Auth state değişikliklerini dinle (gelecekteki giriş/çıkışlar için)
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? firebaseUser) async {
      print('🔄 UserProvider: Auth state değişti, firebaseUser: ${firebaseUser?.uid ?? "null"}');
      if (firebaseUser != null) {
        // User is signed in
        print('✅ UserProvider: Kullanıcı giriş yapmış, detaylar alınıyor...');
        try {
          User? user = await _authMethods.getUserDetails();
          _user = user;
          _isLoading = false;
          print('✅ UserProvider: Kullanıcı detayları alındı, isLoading: false');
          notifyListeners();
        } catch (e) {
          print('❌ UserProvider: getUserDetails hatası: $e');
          _isLoading = false;
          notifyListeners();
        }
        
        // Kullanıcı giriş yaptığında FCM token'ı al ve kaydet - ASYNC olarak devam ettir
        // Loading'i bloklamasın, arka planda devam etsin
        Future.microtask(() async {
          try {
            print('🔄 UserProvider: Kullanıcı giriş yaptı, FCM token kaydı başlatılıyor (async)...');
            
            // KRİTİK: Platform "unknown" ise önce düzelt
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .get();
              
              if (userDoc.exists) {
                final currentPlatform = userDoc.data()?['platform'] as String?;
                if (currentPlatform == null || 
                    currentPlatform.isEmpty || 
                    currentPlatform == 'unknown') {
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
                      .doc(firebaseUser.uid)
                      .update({'platform': platform});
                  print('✅ UserProvider: Platform düzeltildi: $platform (önceki: $currentPlatform)');
                }
              }
            } catch (e) {
              print('⚠️ UserProvider: Platform kontrolü hatası: $e');
            }
            
            final fcmManager = FCMTokenManager();
            await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
            await fcmManager.saveTokenToFirestore(forceRetry: true);
            print('✅ UserProvider: FCM token kaydı tamamlandı');
            
            // KRİTİK: Firebase Analytics'e platform bilgisini user property olarak gönder
            // Bu, Firebase Console → Users bölümünde platform bilgisinin görünmesi için GEREKLİ
            // iOS için kesin olarak "ios" gönderilir
            try {
              final analytics = firebase_analytics.FirebaseAnalytics.instance;
              String platform = 'unknown';
              if (!kIsWeb) {
                if (io.Platform.isIOS) {
                  platform = 'ios'; // KRİTİK: iOS için kesin olarak "ios"
                } else if (io.Platform.isAndroid) {
                  platform = 'android';
                }
              }
              await analytics.setUserProperty(name: 'platform', value: platform);
              await analytics.setUserId(id: firebaseUser.uid);
              
              // KRİTİK: Platform event'i logla (iOS için özellikle önemli)
              await analytics.logEvent(
                name: 'user_platform_set',
                parameters: {
                  'platform': platform,
                  'user_id': firebaseUser.uid,
                },
              );
              print('✅ UserProvider: Firebase Analytics platform user property ayarlandı: $platform');
            } catch (analyticsError) {
              print('⚠️ UserProvider: Firebase Analytics user property hatası: $analyticsError');
            }
          } catch (e, stackTrace) {
            print('❌ UserProvider: FCM token kaydı başarısız: $e');
            print('❌ UserProvider: Stack trace: $stackTrace');
          }
        });
      } else {
        // User is signed out
        print('ℹ️ UserProvider: Kullanıcı çıkış yapmış');
        _user = null;
        _isLoading = false;
        notifyListeners();
        
        // Kullanıcı çıkış yaptığında FCM token'ı sil - YENİ FCMTokenManager kullan
        try {
          print('🔄 UserProvider: Kullanıcı çıkış yaptı, FCM token siliniyor...');
          await FCMTokenManager().deleteToken();
          print('✅ UserProvider: FCM token silindi');
        } catch (e, stackTrace) {
          print('❌ UserProvider: FCM token silme hatası: $e');
          print('❌ UserProvider: Stack trace: $stackTrace');
        }
      }
    });
  }

  // refresh user
  Future<void> refreshUser() async {
    User? user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}
