# 📋 iOS FCM Push Notification - Yapılandırma Kontrol Listesi

Bu liste, iOS uygulamanızda Firebase Cloud Messaging (FCM) push notification'larının çalışması için **TÜM** gerekli yapılandırma adımlarını içerir.

---

## ✅ I. Apple Developer Portal Kontrolleri

### 1. App ID Yapılandırması
- [ ] **Apple Developer Portal** → **Certificates, Identifiers & Profiles** → **Identifiers**
- [ ] Uygulamanızın **App ID**'sini bulun (örn: `com.canlipazar.app`)
- [ ] **Push Notifications** capability'sinin **AÇIK** olduğunu doğrulayın
- [ ] **App Services** bölümünde **Push Notifications** seçeneğinin işaretli olduğunu kontrol edin

### 2. APNs Authentication Key
- [ ] **Apple Developer Portal** → **Certificates, Identifiers & Profiles** → **Keys**
- [ ] APNs Authentication Key (.p8 dosyası) oluşturulmuş mu kontrol edin
- [ ] Key ID ve Team ID'yi not edin (Firebase Console'da gerekli)

---

## ✅ II. Firebase Console Kontrolleri

### 1. APNs Authentication Key Yükleme
- [ ] **Firebase Console** → **Project Settings** → **Cloud Messaging** sekmesi
- [ ] **Apple app configuration** bölümünde **APNs Authentication Key** yüklü mü kontrol edin
- [ ] **Key ID** ve **Team ID** doğru mu kontrol edin
- [ ] **Development** ve **Production** için ayrı ayrı yüklendiğini doğrulayın

### 2. Bundle ID Kontrolü
- [ ] **Firebase Console** → **Project Settings** → **General** sekmesi
- [ ] iOS uygulamanızın **Bundle ID**'si doğru mu kontrol edin (örn: `com.canlipazar.app`)
- [ ] Bundle ID, Apple Developer Portal'daki App ID ile **TAM OLARAK EŞLEŞMELİ**

---

## ✅ III. Xcode Yapılandırması

### 1. Capabilities (Signing & Capabilities)
- [ ] Xcode'da projeyi açın: `ios/Runner.xcworkspace`
- [ ] **Runner** target'ını seçin
- [ ] **Signing & Capabilities** sekmesine gidin
- [ ] **+ Capability** butonuna tıklayın
- [ ] **Push Notifications** capability'sini ekleyin
- [ ] **Background Modes** capability'sini ekleyin (eğer yoksa)
- [ ] **Background Modes** içinde **Remote notifications** seçeneğini işaretleyin

### 2. Signing & Certificates
- [ ] **Signing & Capabilities** sekmesinde **Team** seçili mi kontrol edin
- [ ] **Bundle Identifier** doğru mu kontrol edin (örn: `com.canlipazar.app`)
- [ ] **Automatically manage signing** işaretli mi kontrol edin
- [ ] Provisioning profile otomatik oluşturuldu mu kontrol edin

### 3. Build Settings
- [ ] **Build Settings** sekmesine gidin
- [ ] **Code Signing Identity** → **Debug** → **iOS Developer** seçili mi kontrol edin
- [ ] **Code Signing Identity** → **Release** → **iOS Distribution** seçili mi kontrol edin
- [ ] **Development Team** doğru mu kontrol edin

---

## ✅ IV. Info.plist Yapılandırması

### 1. UIBackgroundModes
- [ ] `ios/Runner/Info.plist` dosyasını açın
- [ ] **UIBackgroundModes** key'i var mı kontrol edin
- [ ] **UIBackgroundModes** array içinde **`remote-notification`** string'i var mı kontrol edin
- [ ] **Örnek:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 2. FirebaseAppDelegateProxyEnabled
- [ ] **FirebaseAppDelegateProxyEnabled** key'i var mı kontrol edin
- [ ] Değeri **`false`** olmalı (manuel yapılandırma için)
- [ ] **Örnek:**
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### 3. Notification Permission Description
- [ ] **NSUserNotificationUsageDescription** key'i var mı kontrol edin
- [ ] Kullanıcıya gösterilecek açıklama metni var mı kontrol edin
- [ ] **Örnek:**
```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app needs to send you notifications about important updates and messages</string>
```

---

## ✅ V. Entitlements Yapılandırması

### 1. Runner.entitlements (Production)
- [ ] `ios/Runner/Runner.entitlements` dosyasını açın
- [ ] **aps-environment** key'i var mı kontrol edin
- [ ] Production build için değeri **`production`** olmalı
- [ ] **Örnek:**
```xml
<key>aps-environment</key>
<string>production</string>
```

### 2. Runner-Debug.entitlements (Development - Opsiyonel)
- [ ] `ios/Runner/Runner-Debug.entitlements` dosyası var mı kontrol edin (opsiyonel)
- [ ] Debug build için değeri **`development`** olmalı
- [ ] **Örnek:**
```xml
<key>aps-environment</key>
<string>development</string>
```

### 3. Xcode'da Entitlements Dosyası
- [ ] Xcode'da **Runner** klasörüne sağ tıklayın
- [ ] **Add Files to "Runner"...** seçeneğini seçin
- [ ] `Runner.entitlements` dosyasını seçin ve ekleyin
- [ ] **Target Membership** → **Runner** işaretli mi kontrol edin

---

## ✅ VI. AppDelegate.swift Yapılandırması

### 1. Import Statements
- [ ] `ios/Runner/AppDelegate.swift` dosyasını açın
- [ ] Şu import'lar var mı kontrol edin:
```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications
```

### 2. Firebase Configuration
- [ ] `FirebaseApp.configure()` çağrılıyor mu kontrol edin
- [ ] `didFinishLaunchingWithOptions` method'unda çağrılmalı

### 3. Messaging Delegate
- [ ] `Messaging.messaging().delegate = self` ayarlanmış mı kontrol edin
- [ ] `MessagingDelegate` extension mevcut mu kontrol edin
- [ ] `didReceiveRegistrationToken` method'u implement edilmiş mi kontrol edin

### 4. UNUserNotificationCenter Delegate
- [ ] `UNUserNotificationCenter.current().delegate = self` ayarlanmış mı kontrol edin
- [ ] `willPresent` method'u implement edilmiş mi kontrol edin (iOS 15+ için `.banner` kullanılmalı)
- [ ] `didReceive` method'u implement edilmiş mi kontrol edin

### 5. APNs Token Handling
- [ ] `didRegisterForRemoteNotificationsWithDeviceToken` method'u mevcut mu kontrol edin
- [ ] `Messaging.messaging().apnsToken = deviceToken` ayarlanmış mı kontrol edin

### 6. Permission Request
- [ ] `UNUserNotificationCenter.current().requestAuthorization` çağrılıyor mu kontrol edin
- [ ] Permission verildikten sonra `application.registerForRemoteNotifications()` çağrılıyor mu kontrol edin

---

## ✅ VII. Podfile Yapılandırması

### 1. Minimum iOS Version
- [ ] `ios/Podfile` dosyasını açın
- [ ] `platform :ios, '15.0'` (veya daha yüksek) ayarlı mı kontrol edin
- [ ] **Örnek:**
```ruby
platform :ios, '15.0'
```

### 2. Firebase Pods
- [ ] `pod install` komutu çalıştırıldı mı kontrol edin
- [ ] `ios/Pods` klasörü mevcut mu kontrol edin
- [ ] Firebase Messaging pod'u yüklü mü kontrol edin

---

## ✅ VIII. Flutter Yapılandırması

### 1. pubspec.yaml
- [ ] `pubspec.yaml` dosyasını açın
- [ ] `firebase_messaging` paketi ekli mi kontrol edin
- [ ] **Örnek:**
```yaml
dependencies:
  firebase_messaging: ^14.7.0
```

### 2. GoogleService-Info.plist
- [ ] `ios/Runner/GoogleService-Info.plist` dosyası mevcut mu kontrol edin
- [ ] Bundle ID doğru mu kontrol edin
- [ ] Firebase Console'dan indirilen dosya ile eşleşiyor mu kontrol edin

---

## ✅ IX. Dart Kod Kontrolleri

### 1. FCM Token Manager
- [ ] `lib/services/fcm_token_manager.dart` dosyası mevcut mu kontrol edin
- [ ] `saveTokenToFirestore()` method'u mevcut mu kontrol edin
- [ ] Platform bilgisi doğru belirleniyor mu kontrol edin (`ios`/`android`)

### 2. Auth Methods
- [ ] `lib/resources/auth_methods.dart` dosyasını açın
- [ ] `signUpUser()` method'unda FCM token kaydı yapılıyor mu kontrol edin
- [ ] `loginUser()` method'unda FCM token kaydı yapılıyor mu kontrol edin

### 3. User Provider
- [ ] `lib/providers/user_provider.dart` dosyasını açın
- [ ] Auth state değiştiğinde FCM token kaydı yapılıyor mu kontrol edin
- [ ] `initialize()` method'unda token kaydı yapılıyor mu kontrol edin

### 4. Main.dart
- [ ] `lib/main.dart` dosyasını açın
- [ ] Firebase Messaging initialize ediliyor mu kontrol edin
- [ ] Notification permission request yapılıyor mu kontrol edin
- [ ] Foreground notification handler ayarlanmış mı kontrol edin

---

## ✅ X. Test ve Doğrulama

### 1. Build ve Run
- [ ] `flutter clean` komutu çalıştırıldı mı
- [ ] `flutter pub get` komutu çalıştırıldı mı
- [ ] `cd ios && pod install && cd ..` komutu çalıştırıldı mı
- [ ] `flutter build ios` komutu başarılı mı

### 2. Firestore Kontrolü
- [ ] Uygulamayı iOS cihazda çalıştırın
- [ ] Kullanıcı girişi yapın
- [ ] Firebase Console → Firestore → `users/{userID}` dokümanını kontrol edin
- [ ] **`fcmToken`** alanı var mı ve dolu mu kontrol edin
- [ ] **`platform`** alanı var mı ve değeri **`ios`** mu kontrol edin

### 3. Notification Test
- [ ] Firebase Console → Cloud Messaging → **Send test message**
- [ ] FCM token'ı girin (Firestore'dan alın)
- [ ] Test bildirimi gönderin
- [ ] iOS cihazda bildirim geldi mi kontrol edin

---

## 🎯 Özet Kontrol Listesi

### Kritik Adımlar (MUTLAKA YAPILMALI):
1. ✅ Apple Developer Portal → Push Notifications capability AÇIK
2. ✅ Firebase Console → APNs Authentication Key yüklü
3. ✅ Xcode → Push Notifications capability eklendi
4. ✅ Info.plist → UIBackgroundModes → remote-notification eklendi
5. ✅ Entitlements → aps-environment = production
6. ✅ AppDelegate.swift → Messaging delegate ayarlandı
7. ✅ AppDelegate.swift → APNs token FCM'e veriliyor
8. ✅ Dart kod → FCM token Firestore'a kaydediliyor
9. ✅ Firestore → fcmToken ve platform alanları mevcut

### Opsiyonel Adımlar (ÖNERİLİR):
- [ ] Runner-Debug.entitlements (development için)
- [ ] Notification service extension (rich notification için)
- [ ] Badge handling
- [ ] Silent push notification handling

---

## 📝 Notlar

- **Bundle ID** her yerde aynı olmalı (Apple Developer Portal, Firebase Console, Xcode, Info.plist)
- **APNs Authentication Key** hem Development hem Production için yüklenmeli
- **Entitlements** dosyası Xcode'da doğru target'a eklenmeli
- **FCM Token** kullanıcı giriş yaptıktan sonra otomatik kaydedilmeli
- **Platform** bilgisi otomatik olarak `ios` olarak kaydedilmeli

---

## 🔧 Sorun Giderme

### Token Kaydedilmiyor:
1. Firestore security rules kontrol edin
2. Kullanıcı giriş yapmış mı kontrol edin
3. Notification permission verilmiş mi kontrol edin
4. Console log'larını kontrol edin

### Bildirim Gelmiyor:
1. APNs Authentication Key doğru mu kontrol edin
2. Bundle ID eşleşiyor mu kontrol edin
3. Entitlements dosyası doğru mu kontrol edin
4. FCM token geçerli mi kontrol edin
5. Cloud Functions log'larını kontrol edin

---

**Bu kontrol listesini kullanarak tüm adımları tek tek kontrol edin ve eksik olanları tamamlayın!** ✅





























