# 🔍 iOS FCM Bildirim Sorunları - Kapsamlı Analiz Raporu

**Tarih:** 2024  
**Proje:** CanlıPazar (com.canlipazar.app)  
**Durum:** iOS Firebase Cloud Messaging bildirimleri gelmiyor

---

## 📋 İÇİNDEKİLER

1. [Kritik Hatalar](#1-kritik-hatalar)
2. [AppDelegate.swift Analizi](#2-appdelegateswift-analizi)
3. [Dart Tarafı Analizi](#3-dart-tarafı-analizi)
4. [Xcode Yapılandırması](#4-xcode-yapılandırması)
5. [APNs-FCM Bağlantı Sorunları](#5-apns-fcm-bağlantı-sorunları)
6. [Token Üretim Sorunları](#6-token-üretim-sorunları)
7. [Foreground/Background/Terminated State Analizi](#7-foregroundbackgroundterminated-state-analizi)
8. [Düzeltme Listesi](#8-düzeltme-listesi)

---

## 1. KRİTİK HATALAR

### ❌ HATA #1: Çakışan Permission Request'leri

**Dosya:** `ios/Runner/AppDelegate.swift` (satır 111-125) ve `lib/main.dart` (satır 63-77) ve `lib/screens/services/firebase_messaging_service.dart` (satır 44-70)

**Sorun:**
- AppDelegate'te `UNUserNotificationCenter.current().requestAuthorization()` çağrılıyor
- Dart tarafında `FirebaseMessaging.instance.requestPermission()` çağrılıyor
- `message_screen.dart` içinde de ayrı bir permission request var (satır 175-183)

**Etki:**
- iOS kullanıcıya birden fazla kez izin diyaloğu gösterebilir
- İkinci request ilk request'i override edebilir
- Token üretimi gecikebilir veya başarısız olabilir

**Çözüm:**
- Permission request'i SADECE AppDelegate'te yapılmalı
- Dart tarafında sadece `getNotificationSettings()` ile durum kontrol edilmeli

---

### ❌ HATA #2: APNs Token Set Edilmeden FCM Token İsteniyor

**Dosya:** `ios/Runner/AppDelegate.swift` (satır 202-204)

**Sorun:**
```swift
// didRegisterForRemoteNotificationsWithDeviceToken içinde
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
  self.getAndSaveFCMToken()
}
```

**Etki:**
- APNs token set edildikten hemen sonra FCM token isteniyor
- FCM token almak için APNs token'ın FCM'e verilmesi gerekiyor
- 1 saniye yeterli olmayabilir

**Çözüm:**
- `Messaging.messaging().apnsToken = deviceToken` set edildikten sonra
- `MessagingDelegate`'in `didReceiveRegistrationToken` callback'ini beklemek daha güvenli
- Veya en az 2-3 saniye beklemek

---

### ❌ HATA #3: Firebase Initialize Sırası Sorunu

**Dosya:** `lib/main.dart` (satır 200-212)

**Sorun:**
```dart
} else if (!kIsWeb && io.Platform.isIOS) {
  // iOS için Firebase zaten AppDelegate'te initialize edilmiş
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(...);
  }
}
```

**Etki:**
- iOS'ta Firebase hem AppDelegate'te hem de main.dart'ta initialize edilmeye çalışılıyor
- Bu çakışmaya neden olabilir
- Firestore settings çakışması olabilir

**Çözüm:**
- iOS'ta Firebase initialize'i SADECE AppDelegate'te yapılmalı
- main.dart'ta iOS için Firebase initialize edilmemeli

---

### ❌ HATA #4: Foreground Notification Handler Eksik

**Dosya:** `ios/Runner/AppDelegate.swift` (satır 164-176)

**Sorun:**
```swift
override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  // ...
  completionHandler([[.alert, .sound, .badge]])
}
```

**Etki:**
- Foreground'da bildirim gösteriliyor ama Dart tarafındaki handler ile çakışabilir
- İki kez bildirim gösterilebilir

**Çözüm:**
- Foreground notification'ları Dart tarafında handle etmek daha iyi
- AppDelegate'te foreground handler'ı kaldırmak veya Dart'a yönlendirmek

---

## 2. APPDELEGATE.SWIFT ANALİZİ

### ✅ DOĞRU OLANLAR

1. **Firebase Initialize:** ✅ Doğru (satır 24-29)
2. **Messaging Delegate:** ✅ Doğru (satır 99)
3. **UNUserNotificationCenter Delegate:** ✅ Doğru (satır 104)
4. **APNs Token Set:** ✅ Doğru (satır 198)
5. **Background Modes:** ✅ Info.plist'te var

### ❌ YANLIŞ/EXİK OLANLAR

1. **Permission Request Timing:** ❌ Çok erken çağrılıyor (satır 111-125)
   - `didFinishLaunchingWithOptions` içinde async olarak çağrılıyor
   - Flutter engine hazır olmadan önce çağrılabilir

2. **FCM Token Retry:** ⚠️ Yeterli değil
   - Sadece 3 retry var
   - APNs token set edildikten sonra daha uzun süre beklemek gerekebilir

3. **Error Handling:** ⚠️ Yetersiz
   - `didFailToRegisterForRemoteNotificationsWithError` sadece logluyor
   - Retry mekanizması yok

4. **Firestore Token Save:** ⚠️ Kullanıcı giriş yapmamışsa token kaydedilmiyor
   - Token geçici olarak saklanmalı
   - Kullanıcı giriş yaptığında kaydedilmeli

---

## 3. DART TARAFI ANALİZİ

### ❌ HATA #1: Çoklu Permission Request

**Dosyalar:**
- `lib/main.dart` (satır 63-77)
- `lib/screens/services/firebase_messaging_service.dart` (satır 44-70)
- `lib/screens/message_screen.dart` (satır 175-183)

**Sorun:**
- 3 farklı yerde permission request yapılıyor
- iOS'ta AppDelegate zaten permission istiyor

**Çözüm:**
- Permission request'i kaldır
- Sadece `getNotificationSettings()` ile durum kontrol et

---

### ❌ HATA #2: iOS'ta Firebase Initialize

**Dosya:** `lib/main.dart` (satır 200-212)

**Sorun:**
- iOS'ta Firebase initialize edilmeye çalışılıyor
- AppDelegate'te zaten initialize ediliyor

**Çözüm:**
- iOS için Firebase initialize'i kaldır

---

### ❌ HATA #3: FCM Service Initialize Timing

**Dosya:** `lib/main.dart` (satır 238)

**Sorun:**
```dart
await FCMService().initialize();
```

- FCMService initialize edilirken permission request yapılıyor
- AppDelegate'te zaten permission istenmiş olabilir

**Çözüm:**
- FCMService.initialize() içindeki permission request'i kaldır
- Sadece token al ve kaydet

---

## 4. XCODE YAPILANDIRMASI

### ⚠️ MANUEL KONTROL GEREKLİ

1. **Push Notifications Capability:**
   - Xcode'da `Signing & Capabilities` sekmesinde kontrol edilmeli
   - Eğer yoksa eklenmeli

2. **Background Modes:**
   - `Remote notifications` seçeneği işaretli olmalı
   - Info.plist'te var ama Xcode'da da kontrol edilmeli

3. **Entitlements:**
   - `Runner.entitlements` - Production için `aps-environment: production`
   - `Runner-Debug.entitlements` - Debug için `aps-environment: development`
   - Xcode'da doğru entitlements dosyası seçilmeli

4. **Bundle Identifier:**
   - `com.canlipazar.app` olmalı
   - Firebase Console'daki Bundle ID ile eşleşmeli

5. **Provisioning Profile:**
   - Push Notifications capability'si olan bir profile kullanılmalı
   - Development ve Production için ayrı profile'lar olmalı

---

## 5. APNs-FCM BAĞLANTI SORUNLARI

### ❌ HATA #1: APNs Key Firebase Console'da Yok Olabilir

**Kontrol:**
1. Firebase Console > Project Settings > Cloud Messaging
2. Apple app configuration bölümünde APNs Authentication Key kontrol edilmeli

**Sorun:**
- APNs key yoksa veya yanlışsa bildirimler gelmez
- Key ID ve Team ID doğru olmalı

**Çözüm:**
- Apple Developer Portal'dan APNs key oluştur
- Firebase Console'a yükle

---

### ❌ HATA #2: Entitlements Ortam Uyuşmazlığı

**Dosyalar:**
- `Runner.entitlements` - `aps-environment: production`
- `Runner-Debug.entitlements` - `aps-environment: development`

**Sorun:**
- Debug build'de production entitlements kullanılırsa bildirimler gelmez
- Production build'de development entitlements kullanılırsa bildirimler gelmez

**Çözüm:**
- Xcode'da build configuration'a göre doğru entitlements dosyası seçilmeli
- Build script ile otomatik seçilebilir

---

### ❌ HATA #3: Bundle ID Uyuşmazlığı

**Kontrol:**
- Xcode'da Bundle ID: `com.canlipazar.app`
- Firebase Console'da Bundle ID: `com.canlipazar.app`
- GoogleService-Info.plist'te Bundle ID: `com.canlipazar.app`

**Sorun:**
- Bundle ID'ler eşleşmezse APNs token alınamaz

**Çözüm:**
- Tüm yerlerde aynı Bundle ID kullanılmalı

---

## 6. TOKEN ÜRETİM SORUNLARI

### ❌ HATA #1: Permission Alınmadan Token İsteniyor

**Dosya:** `lib/screens/services/firebase_messaging_service.dart` (satır 72-104)

**Sorun:**
```dart
Future<void> _getToken() async {
  // ...
  token = await FirebaseMessaging.instance.getToken();
}
```

- Permission kontrolü yapılmadan token isteniyor
- iOS'ta permission yoksa token alınamaz

**Çözüm:**
- Token almadan önce permission durumunu kontrol et
- Permission yoksa token isteme

---

### ❌ HATA #2: APNs Token Set Edilmeden FCM Token İsteniyor

**Dosya:** `ios/Runner/AppDelegate.swift` (satır 202-204)

**Sorun:**
- APNs token set edildikten hemen sonra FCM token isteniyor
- FCM token almak için APNs token'ın FCM'e verilmesi ve işlenmesi gerekiyor

**Çözüm:**
- `didReceiveRegistrationToken` callback'ini bekle
- Veya en az 2-3 saniye bekle

---

### ❌ HATA #3: Kullanıcı Giriş Yapmadan Token Kaydedilemiyor

**Dosya:** `ios/Runner/AppDelegate.swift` (satır 274-280)

**Sorun:**
```swift
guard let currentUser = Auth.auth().currentUser else {
  print("⚠️ Kullanıcı giriş yapmamış, token kaydedilemiyor")
  return
}
```

- Kullanıcı giriş yapmadan token kaydedilemiyor
- Token geçici olarak saklanmalı

**Çözüm:**
- Token'ı UserDefaults'a kaydet
- Kullanıcı giriş yaptığında Firestore'a kaydet

---

## 7. FOREGROUND/BACKGROUND/TERMINATED STATE ANALİZİ

### 🔴 FOREGROUND STATE

**Sorun:**
- AppDelegate'te `willPresent` handler var (satır 164-176)
- Dart tarafında `FirebaseMessaging.onMessage` handler var
- İki handler çakışabilir, iki kez bildirim gösterilebilir

**Çözüm:**
- AppDelegate'teki foreground handler'ı kaldır
- Sadece Dart tarafında handle et

---

### 🟡 BACKGROUND STATE

**Sorun:**
- Background handler doğru yapılandırılmış (`_firebaseMessagingBackgroundHandler`)
- Ancak `content-available: 1` Cloud Functions'da doğru set edilmiş

**Durum:** ✅ Doğru

---

### 🔴 TERMINATED STATE

**Sorun:**
- Terminated state'de bildirim gelirse `getInitialMessage()` ile kontrol edilmeli
- `lib/main.dart`'ta `_checkInitialMessage()` var ama kullanılmıyor

**Çözüm:**
- `getInitialMessage()` kontrolü yapılmalı
- Bildirim tıklandığında uygun ekrana yönlendirilmeli

---

## 8. DÜZELTME LİSTESİ

### 🔧 DÜZELTME #1: AppDelegate.swift - Permission Request Timing

**Dosya:** `ios/Runner/AppDelegate.swift`  
**Satır:** 111-125

**Şu anki kod:**
```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
  if settings.authorizationStatus == .notDetermined {
    // Permission request
  }
}
```

**Düzeltilmiş kod:**
```swift
// Permission request'i Flutter engine hazır olduktan sonra yap
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
  UNUserNotificationCenter.current().getNotificationSettings { settings in
    if settings.authorizationStatus == .notDetermined {
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ iOS Bildirim izni verildi")
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          } else {
            print("❌ iOS Bildirim izni reddedildi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
          }
        }
      )
    } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
      print("✅ iOS Bildirim izni zaten verilmiş, remote notifications kaydediliyor")
      DispatchQueue.main.async {
        application.registerForRemoteNotifications()
      }
    }
  }
}
```

---

### 🔧 DÜZELTME #2: AppDelegate.swift - FCM Token Timing

**Dosya:** `ios/Runner/AppDelegate.swift`  
**Satır:** 202-204

**Şu anki kod:**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
  self.getAndSaveFCMToken()
}
```

**Düzeltilmiş kod:**
```swift
// APNs token set edildikten sonra FCM token'ı al
// didReceiveRegistrationToken callback'i otomatik çağrılacak
// Eğer callback çağrılmazsa, 3 saniye sonra manuel al
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
  // didReceiveRegistrationToken çağrılmadıysa manuel al
  self.getAndSaveFCMToken()
}
```

---

### 🔧 DÜZELTME #3: AppDelegate.swift - Foreground Handler Kaldır

**Dosya:** `ios/Runner/AppDelegate.swift`  
**Satır:** 164-176

**Şu anki kod:**
```swift
override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  completionHandler([[.alert, .sound, .badge]])
}
```

**Düzeltilmiş kod:**
```swift
// Foreground notification'ları Dart tarafında handle et
// AppDelegate'te sadece loglama yap
override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  let userInfo = notification.request.content.userInfo
  print("📱 Foreground notification alındı (Dart tarafında handle edilecek): \(userInfo)")
  
  // Dart tarafında handle edilecek, burada gösterme
  completionHandler([])
}
```

---

### 🔧 DÜZELTME #4: main.dart - iOS Firebase Initialize Kaldır

**Dosya:** `lib/main.dart`  
**Satır:** 200-212

**Şu anki kod:**
```dart
} else if (!kIsWeb && io.Platform.isIOS) {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(...);
  }
}
```

**Düzeltilmiş kod:**
```dart
} else if (!kIsWeb && io.Platform.isIOS) {
  // iOS'ta Firebase AppDelegate'te zaten initialize ediliyor
  // Burada initialize etme, sadece kontrol et
  if (Firebase.apps.isEmpty) {
    print("⚠️ iOS: Firebase AppDelegate'te initialize edilmemiş, fallback initialize ediliyor");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    print("✅ iOS: Firebase AppDelegate'te zaten initialize edilmiş (${Firebase.apps.length} app(s))");
  }
}
```

---

### 🔧 DÜZELTME #5: firebase_messaging_service.dart - Permission Request Kaldır

**Dosya:** `lib/screens/services/firebase_messaging_service.dart`  
**Satır:** 44-70

**Şu anki kod:**
```dart
Future<void> _requestPermission() async {
  final settings = await messaging.requestPermission(...);
}
```

**Düzeltilmiş kod:**
```dart
Future<void> _requestPermission() async {
  if (kIsWeb) {
    print("Skipping notification permission request on web");
    return;
  }

  // iOS'ta permission AppDelegate'te zaten isteniyor
  // Burada sadece durum kontrolü yap
  final messaging = FirebaseMessaging.instance;

  try {
    print("📱 Bildirim izin durumu kontrol ediliyor...");

    final settings = await messaging.getNotificationSettings();

    print("📱 Bildirim izin durumu: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("✅ Bildirim izni verilmiş");
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Bildirim izni reddedilmiş");
    } else {
      print("⚠️ Bildirim izni henüz belirlenmemiş (AppDelegate'te istenecek)");
    }
  } catch (e) {
    print("❌ Bildirim izin durumu kontrolü hatası: $e");
  }
}
```

---

### 🔧 DÜZELTME #6: AppDelegate.swift - Token Geçici Saklama

**Dosya:** `ios/Runner/AppDelegate.swift`  
**Satır:** 270-333

**Şu anki kod:**
```swift
guard let currentUser = Auth.auth().currentUser else {
  print("⚠️ Kullanıcı giriş yapmamış, token kaydedilemiyor")
  return
}
```

**Düzeltilmiş kod:**
```swift
// Token'ı geçici olarak UserDefaults'a kaydet
UserDefaults.standard.set(token, forKey: "fcmToken_pending")
print("✅ FCM token geçici olarak kaydedildi (UserDefaults)")

// Kullanıcı giriş yapmış mı kontrol et
guard let currentUser = Auth.auth().currentUser else {
  print("⚠️ Kullanıcı giriş yapmamış, token geçici olarak saklandı")
  // Token kullanıcı giriş yaptığında Flutter tarafından kaydedilecek
  return
}

let userId = currentUser.uid

// Token'ı Firestore'a kaydet
// ... (mevcut kod)
```

---

### 🔧 DÜZELTME #7: main.dart - getInitialMessage Kontrolü

**Dosya:** `lib/main.dart`  
**Satır:** 211-228

**Şu anki kod:**
```dart
Future<void> _checkInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Handle
  }
}
```

**Düzeltilmiş kod:**
```dart
// FCMService.initialize() içinde zaten var ama kullanılmıyor
// main.dart'ta da kontrol et
try {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("🔔 Uygulama terminated state'den bildirim ile açıldı");
    print("📋 Initial message: ${initialMessage.notification?.title}");
    print("📋 Data: ${initialMessage.data}");
    
    // Burada uygun ekrana yönlendirme yapılabilir
    // Örneğin: Navigator.pushNamed(context, '/message', arguments: initialMessage.data);
  }
} catch (e) {
  print("❌ Initial message kontrolü hatası: $e");
}
```

---

## 📝 ÖZET: YAPILMASI GEREKENLER

### ✅ HEMEN YAPILMASI GEREKENLER

1. **AppDelegate.swift:**
   - [ ] Permission request timing'i düzelt (1 saniye gecikme ekle)
   - [ ] FCM token timing'i düzelt (3 saniye gecikme veya callback bekle)
   - [ ] Foreground handler'ı kaldır veya Dart'a yönlendir
   - [ ] Token geçici saklama ekle (UserDefaults)

2. **main.dart:**
   - [ ] iOS Firebase initialize'i kaldır (AppDelegate'te zaten var)
   - [ ] getInitialMessage kontrolü ekle

3. **firebase_messaging_service.dart:**
   - [ ] Permission request'i kaldır, sadece durum kontrolü yap

4. **message_screen.dart:**
   - [ ] Permission request'i kaldır (satır 175-183)

### ⚠️ MANUEL KONTROL GEREKLİ

1. **Xcode:**
   - [ ] Push Notifications capability eklendi mi?
   - [ ] Background Modes > Remote notifications işaretli mi?
   - [ ] Doğru entitlements dosyası seçili mi?
   - [ ] Bundle ID doğru mu? (`com.canlipazar.app`)

2. **Firebase Console:**
   - [ ] APNs Authentication Key yüklü mü?
   - [ ] Key ID ve Team ID doğru mu?

3. **Apple Developer Portal:**
   - [ ] App ID'de Push Notifications capability aktif mi?
   - [ ] Provisioning Profile'da Push Notifications var mı?

---

## 🎯 SONUÇ

iOS FCM bildirim sorunlarının ana nedenleri:

1. **Çakışan permission request'leri** (AppDelegate + Dart)
2. **Yanlış timing** (APNs token set edilmeden FCM token isteniyor)
3. **Foreground handler çakışması** (AppDelegate + Dart)
4. **Xcode capabilities eksikliği** (manuel kontrol gerekli)
5. **APNs key eksikliği** (Firebase Console'da kontrol gerekli)

Bu düzeltmeler yapıldıktan sonra iOS bildirimleri çalışmalı.

---

**Not:** Bu rapor tüm olası sorunları kapsar. Her düzeltme adım adım test edilmeli.





























