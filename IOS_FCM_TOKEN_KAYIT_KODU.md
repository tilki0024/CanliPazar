# 🔧 iOS FCM Token Kayıt Kodu - Eksik Kod Düzeltmesi

## 📋 Sorun

Firestore Database'deki kullanıcı dokümanında (`users/{userID}`):
- ❌ `fcmToken` alanı **EKSİK**
- ❌ `platform` alanı **EKSİK**

## ✅ Çözüm

Mevcut kodunuzda `FCMTokenManager` zaten mevcut ve doğru çalışıyor. Ancak iOS'ta token alınması için **notification permission** verilmesi gerekiyor. Aşağıdaki kod, kullanıcı giriş yaptıktan hemen sonra FCM token'ı alıp Firestore'a kaydedecek.

---

## 🔧 1. FCM Token Manager (Zaten Mevcut - Kontrol Edin)

Dosya: `lib/services/fcm_token_manager.dart`

Bu dosya zaten mevcut ve doğru çalışıyor. Sadece kontrol edin:

```dart
// ✅ Bu method zaten mevcut
Future<bool> saveTokenToFirestore({bool forceRetry = false}) async {
  // 1. FCM token'ı alır
  // 2. Platform bilgisini belirler (ios/android)
  // 3. Firestore'a kaydeder
}
```

---

## 🔧 2. Auth Methods - Sign Up Sonrası Token Kaydı (Zaten Mevcut - Kontrol Edin)

Dosya: `lib/resources/auth_methods.dart`

Bu kod zaten mevcut. Sadece kontrol edin:

```dart
// ✅ signUpUser() method'unda zaten mevcut
Future<String> signUpUser({...}) async {
  // ... kullanıcı kaydı ...
  
  // FCM Token'ı kaydet (kayıt başarılı olduktan sonra)
  try {
    print('🔄 AuthMethods: Kullanıcı kaydı başarılı, FCM token kaydı başlatılıyor...');
    final fcmManager = FCMTokenManager();
    await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
    final success = await fcmManager.saveTokenToFirestore(forceRetry: true);
    
    if (success) {
      print('✅ AuthMethods: FCM Token başarıyla kaydedildi (signup)');
    } else {
      print('⚠️ AuthMethods: FCM Token kaydı başarısız (signup)');
    }
  } catch (e) {
    print('❌ AuthMethods: FCM Token kaydı başarısız (signup): $e');
  }
  
  return res;
}
```

---

## 🔧 3. Auth Methods - Login Sonrası Token Kaydı (Zaten Mevcut - Kontrol Edin)

Dosya: `lib/resources/auth_methods.dart`

Bu kod zaten mevcut. Sadece kontrol edin:

```dart
// ✅ loginUser() method'unda zaten mevcut
Future<String> loginUser({...}) async {
  // ... kullanıcı girişi ...
  
  // FCM Token'ı kaydet (giriş başarılı olduktan sonra)
  try {
    print('🔄 AuthMethods: Kullanıcı girişi başarılı, FCM token kaydı başlatılıyor...');
    final fcmManager = FCMTokenManager();
    await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
    final success = await fcmManager.saveTokenToFirestore(forceRetry: true);
    
    if (success) {
      print('✅ AuthMethods: FCM Token başarıyla kaydedildi (login)');
    } else {
      print('⚠️ AuthMethods: FCM Token kaydı başarısız (login)');
    }
  } catch (e) {
    print('❌ AuthMethods: FCM Token kaydı başarısız (login): $e');
  }
  
  return res;
}
```

---

## 🔧 4. User Provider - Auth State Değişikliğinde Token Kaydı (Zaten Mevcut - Kontrol Edin)

Dosya: `lib/providers/user_provider.dart`

Bu kod zaten mevcut. Sadece kontrol edin:

```dart
// ✅ initialize() method'unda zaten mevcut
void initialize() async {
  // ... auth state kontrolü ...
  
  firebase_auth.FirebaseAuth.instance
      .authStateChanges()
      .listen((firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      // Kullanıcı giriş yaptığında FCM token'ı al ve kaydet
      Future.microtask(() async {
        try {
          print('🔄 UserProvider: Kullanıcı giriş yaptı, FCM token kaydı başlatılıyor...');
          final fcmManager = FCMTokenManager();
          await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
          await fcmManager.saveTokenToFirestore(forceRetry: true);
          print('✅ UserProvider: FCM token kaydı tamamlandı');
        } catch (e) {
          print('❌ UserProvider: FCM token kaydı başarısız: $e');
        }
      });
    }
  });
}
```

---

## ⚠️ ÖNEMLİ: iOS'ta Token Alınması İçin Gereksinimler

### 1. Notification Permission Verilmiş Olmalı

iOS'ta FCM token alınması için **notification permission** verilmesi gerekiyor. Eğer permission verilmemişse, token alınamaz.

**Kontrol:**
```dart
// FCMTokenManager içinde zaten kontrol ediliyor
final settings = await _messaging.getNotificationSettings();
if (settings.authorizationStatus != AuthorizationStatus.authorized &&
    settings.authorizationStatus != AuthorizationStatus.provisional) {
  print('⚠️ FCMTokenManager: Bildirim izni verilmemiş');
  return false;
}
```

### 2. AppDelegate.swift'te Permission İsteği

`ios/Runner/AppDelegate.swift` dosyasında permission isteği yapılmalı:

```swift
// ✅ Zaten mevcut - kontrol edin
UNUserNotificationCenter.current().requestAuthorization(
  options: [.alert, .badge, .sound],
  completionHandler: { granted, error in
    if granted {
      application.registerForRemoteNotifications()
    }
  }
)
```

---

## 🧪 Test Adımları

### 1. Uygulamayı Çalıştırın
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### 2. Kullanıcı Girişi Yapın
- Uygulamayı açın
- Giriş yapın veya kayıt olun
- Notification permission isteğini kabul edin

### 3. Firestore'u Kontrol Edin
- Firebase Console → Firestore → `users/{userID}` dokümanını açın
- **`fcmToken`** alanının var olduğunu ve dolu olduğunu kontrol edin
- **`platform`** alanının var olduğunu ve değerinin **`ios`** olduğunu kontrol edin

### 4. Console Log'larını Kontrol Edin
```dart
// Şu log'ları görmelisiniz:
✅ FCMTokenManager: Kullanıcı giriş yapmış, userId: {userID}
✅ FCMTokenManager: FCM token alındı: {token}...
✅ FCMTokenManager: Platform belirlendi: ios
✅ FCMTokenManager: Token Firestore'a kaydedildi (userId: {userID}, platform: ios)
```

---

## 🔍 Sorun Giderme

### Token Kaydedilmiyor:

1. **Notification Permission Kontrolü:**
   ```dart
   // iOS ayarlarında bildirim izni açık mı kontrol edin
   // Ayarlar → CanlıPazar → Bildirimler → AÇIK
   ```

2. **Console Log'larını Kontrol Edin:**
   ```dart
   // Xcode Console veya Flutter Console'da şu log'ları arayın:
   ⚠️ FCMTokenManager: Bildirim izni verilmemiş
   ❌ FCMTokenManager: FCM token alınamadı
   ❌ FCMTokenManager: Token Firestore'a kaydedilemedi
   ```

3. **Firestore Security Rules Kontrolü:**
   ```javascript
   // Firestore security rules'da users koleksiyonuna yazma izni var mı?
   match /users/{userId} {
     allow write: if request.auth != null && request.auth.uid == userId;
   }
   ```

4. **Kullanıcı Giriş Kontrolü:**
   ```dart
   // Kullanıcı gerçekten giriş yapmış mı?
   final currentUser = FirebaseAuth.instance.currentUser;
   print('Current user: ${currentUser?.uid}');
   ```

### Platform "unknown" Olarak Kaydediliyor:

1. **Platform Belirleme Kontrolü:**
   ```dart
   // FCMTokenManager içinde _getPlatform() method'u doğru çalışıyor mu?
   String _getPlatform() {
     if (io.Platform.isIOS) {
       return 'ios'; // ✅ Doğru
     } else if (io.Platform.isAndroid) {
       return 'android'; // ✅ Doğru
     }
     return 'unknown'; // ⚠️ Sorun burada
   }
   ```

2. **Import Kontrolü:**
   ```dart
   // Dosyanın başında import var mı?
   import 'dart:io' if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
   ```

---

## 📝 Özet

### Mevcut Kod Durumu:
- ✅ `FCMTokenManager` mevcut ve doğru çalışıyor
- ✅ `AuthMethods` signup/login sonrası token kaydediyor
- ✅ `UserProvider` auth state değişikliğinde token kaydediyor
- ✅ Platform bilgisi otomatik belirleniyor

### Yapılması Gerekenler:
1. ✅ iOS yapılandırma kontrol listesini takip edin
2. ✅ Notification permission verin
3. ✅ Uygulamayı test edin
4. ✅ Firestore'da token ve platform alanlarını kontrol edin

### Eğer Hala Çalışmıyorsa:
1. Console log'larını kontrol edin
2. Firestore security rules kontrol edin
3. Notification permission kontrol edin
4. AppDelegate.swift kontrol edin

---

**Kod zaten mevcut ve doğru çalışıyor. Sadece iOS yapılandırmasını kontrol edin!** ✅





























