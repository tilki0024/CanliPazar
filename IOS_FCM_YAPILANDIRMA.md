# iOS Firebase Cloud Messaging (FCM) Yapılandırması

Bu dokümantasyon iOS için Firebase Cloud Messaging yapılandırmasının tamamlandığını ve yapılan değişiklikleri açıklar.

## ✅ Tamamlanan Yapılandırmalar

### 1. GoogleService-Info.plist Kontrolü
- ✅ Dosya mevcut: `ios/Runner/GoogleService-Info.plist`
- ✅ Bundle ID doğru: `com.canlipazar.app`
- ✅ Firebase proje ID: `canlipazar-b3697`

### 2. AppDelegate.swift Yapılandırması
- ✅ Firebase ve FirebaseMessaging import'ları eklendi
- ✅ `FirebaseApp.configure()` çağrılıyor
- ✅ `UNUserNotificationCenter.current().delegate = self` ayarlandı
- ✅ `Messaging.messaging().delegate = self` ayarlandı
- ✅ `didRegisterForRemoteNotificationsWithDeviceToken` içinde `Messaging.messaging().apnsToken = deviceToken` ayarlandı
- ✅ FCM token konsola yazdırılıyor ve null kontrolü yapılıyor
- ✅ `MessagingDelegate` extension eklendi ve token alınıyor

### 3. Entitlements Yapılandırması
- ✅ `Runner.entitlements` - Production APNs ortamı için
- ✅ `Runner-Debug.entitlements` - Development (Sandbox) APNs ortamı için
- ✅ Build script eklendi: `ios/scripts/fix_entitlements.sh`

### 4. Info.plist Yapılandırması
- ✅ `FirebaseAppDelegateProxyEnabled` = `false` (manuel yapılandırma için)
- ✅ `UIBackgroundModes` içinde `remote-notification` aktif
- ✅ Bildirim izinleri tanımlı

## 🔧 Xcode'da Yapılması Gereken Manuel Adımlar

### 1. Push Notifications Capability Ekleme
1. Xcode'da projeyi açın: `ios/Runner.xcworkspace`
2. Project Navigator'da `Runner` target'ını seçin
3. `Signing & Capabilities` sekmesine gidin
4. `+ Capability` butonuna tıklayın
5. `Push Notifications` capability'sini ekleyin
6. `Background Modes` capability'sini ekleyin (eğer yoksa)
7. `Background Modes` içinde `Remote notifications` seçeneğini işaretleyin

### 2. Entitlements Dosyasını Xcode'a Ekleme
1. Xcode'da `Runner` klasörüne sağ tıklayın
2. `Add Files to "Runner"...` seçeneğini seçin
3. `Runner-Debug.entitlements` dosyasını seçin ve ekleyin
4. Target membership'te `Runner` seçili olduğundan emin olun

### 3. Build Script Ekleme (Opsiyonel - Otomatik Entitlements)
1. Xcode'da `Runner` target'ını seçin
2. `Build Phases` sekmesine gidin
3. `+` butonuna tıklayın ve `New Run Script Phase` seçin
4. Script'i en üste taşıyın (diğer script'lerden önce çalışmalı)
5. Script içeriğine şunu ekleyin:
```bash
"${SRCROOT}/scripts/fix_entitlements.sh"
```
6. `Show environment variables in build log` seçeneğini işaretleyin (debug için)

### 4. APNs Authentication Key Kontrolü (Firebase Console)
1. Firebase Console'a gidin: https://console.firebase.google.com
2. Projenizi seçin: `canlipazar-b3697`
3. Project Settings → Cloud Messaging → iOS app configuration
4. `APNs Authentication Key` bölümünü kontrol edin:
   - ✅ `.p8` dosyası yüklü mü?
   - ✅ Key ID doğru mu?
   - ✅ Team ID doğru mu? (`9W44LA8URS`)

### 5. Build Configuration Kontrolü
- **Debug Build**: Sandbox (development) APNs ortamı kullanılmalı
- **Release Build**: Production APNs ortamı kullanılmalı
- **TestFlight**: Production APNs ortamı kullanılmalı

## 🧪 Test Adımları

### 1. FCM Token Kontrolü
1. Uygulamayı Debug modda çalıştırın
2. Xcode Console'da şu log'ları kontrol edin:
   - `✅ iOS AppDelegate: Firebase yapılandırıldı`
   - `✅ iOS AppDelegate: APNs token alındı`
   - `✅ iOS AppDelegate: FCM registration token alındı`
   - `✅ iOS AppDelegate: FCM token: [TOKEN]`

### 2. Bildirim İzni Kontrolü
1. Uygulama ilk açıldığında bildirim izni isteği görünmeli
2. İzin verildikten sonra token alınmalı

### 3. Test Bildirimi Gönderme
1. Firebase Console → Cloud Messaging → New notification
2. Notification title ve body girin
3. Target → Single device → FCM token'ı yapıştırın
4. Send butonuna tıklayın
5. Bildirim cihazda görünmeli

## 📝 Önemli Notlar

1. **Debug vs Release**: Debug build'lerde sandbox APNs, Release build'lerde production APNs kullanılır
2. **Token Null Kontrolü**: AppDelegate.swift'te token null kontrolü ve retry mekanizması eklendi
3. **FirebaseAppDelegateProxyEnabled**: `false` olarak ayarlandı çünkü manuel yapılandırma yapıyoruz
4. **Background Modes**: `remote-notification` aktif olmalı

## 🐛 Sorun Giderme

### Token Alınamıyorsa:
1. Xcode Console'da hata mesajlarını kontrol edin
2. APNs token alınıyor mu kontrol edin (`didRegisterForRemoteNotificationsWithDeviceToken`)
3. Firebase Console'da APNs Authentication Key doğru mu kontrol edin
4. Bundle ID Firebase Console'daki ile eşleşiyor mu kontrol edin

### Bildirimler Gelmeyorsa:
1. Bildirim izni verildi mi kontrol edin
2. APNs ortamı doğru mu kontrol edin (Debug → Sandbox, Release → Production)
3. Firebase Console'da test bildirimi gönderin
4. Cihazın internet bağlantısını kontrol edin

## ✅ Kontrol Listesi

- [x] GoogleService-Info.plist mevcut ve doğru bundle ID ile eşleşiyor
- [x] AppDelegate.swift'te Firebase yapılandırması tamamlandı
- [x] APNs token Firebase Messaging'e veriliyor
- [x] FCM token konsola yazdırılıyor ve null kontrolü yapılıyor
- [x] Entitlements dosyaları oluşturuldu (Debug ve Release)
- [x] Info.plist'te FirebaseAppDelegateProxyEnabled false
- [ ] Xcode'da Push Notifications capability eklendi (MANUEL)
- [ ] Xcode'da Background Modes capability eklendi (MANUEL)
- [ ] Firebase Console'da APNs Authentication Key yüklü (MANUEL)

## 📞 Destek

Sorun yaşarsanız:
1. Xcode Console log'larını kontrol edin
2. Firebase Console'da APNs yapılandırmasını kontrol edin
3. Bundle ID ve Team ID'nin doğru olduğundan emin olun






