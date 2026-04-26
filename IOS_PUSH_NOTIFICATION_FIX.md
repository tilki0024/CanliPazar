# iOS Push Notification Sorun Çözümü - Adım Adım Rehber

## ✅ Yapılan Düzeltmeler

### 1. AppDelegate.swift İyileştirmeleri
- ✅ APNs token alınamazsa retry mekanizması eklendi (3 deneme)
- ✅ FCM token alınamazsa retry mekanizması eklendi
- ✅ Token kaydı için Firestore'a direkt yazma eklendi (Flutter tarafına güvenmek yerine)
- ✅ Daha detaylı hata loglama eklendi
- ✅ APNs token nil kontrolü eklendi

### 2. Cloud Functions iOS Payload Optimizasyonu
- ✅ content-available ve mutable-content number olarak ayarlandı (any yerine)
- ✅ apns-expiration header eklendi (0 = hemen gönder)

## 🔧 Xcode'da Yapılması Gereken Manuel Adımlar

### ADIM 1: Push Notifications Capability Ekleme (KRİTİK!)

1. Xcode'da projeyi açın:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Project Navigator'da **Runner** target'ını seçin

3. **Signing & Capabilities** sekmesine gidin

4. Sol üstteki **+ Capability** butonuna tıklayın

5. **Push Notifications** capability'sini arayın ve ekleyin

6. **Background Modes** capability'sini kontrol edin (yoksa ekleyin):
   - **Remote notifications** seçeneğini işaretleyin

### ADIM 2: APNs Key Firebase Console'a Yükleme

1. **Apple Developer Portal**'a gidin: https://developer.apple.com/account

2. **Certificates, Identifiers & Profiles** > **Keys** bölümüne gidin

3. Yeni bir **Key** oluşturun veya mevcut bir key'i kullanın:
   - **Key Name**: CanliPazar Push Notifications (veya istediğiniz isim)
   - **Apple Push Notifications service (APNs)** seçeneğini işaretleyin
   - **Continue** > **Register**

4. Key'i indirin (`.p8` dosyası) - **SADECE BİR KEZ İNDİRİLEBİLİR!**

5. **Key ID**'yi not edin (örn: `94D623A8F4`)

6. **Team ID**'yi not edin (Apple Developer hesabınızın Team ID'si)

7. **Firebase Console**'a gidin: https://console.firebase.google.com

8. Projenizi seçin: **canlipazar-b3697**

9. **Project Settings** > **Cloud Messaging** sekmesine gidin

10. **Apple app configuration** bölümünde:
    - **APNs Authentication Key** seçeneğini seçin
    - İndirdiğiniz `.p8` dosyasını yükleyin
    - **Key ID**'yi girin
    - **Team ID**'yi girin
    - **Upload** butonuna tıklayın

### ADIM 3: Bundle ID Eşleşmesi Kontrolü

1. Xcode'da **Runner** target'ını seçin
2. **General** sekmesinde **Bundle Identifier**'ı kontrol edin
3. **com.canlipazar.app** olduğundan emin olun
4. **GoogleService-Info.plist** dosyasındaki `BUNDLE_ID` ile eşleştiğinden emin olun

### ADIM 4: Entitlements Kontrolü

1. Xcode'da **Runner** target'ını seçin
2. **Signing & Capabilities** sekmesine gidin
3. **Runner.entitlements** dosyasının eklendiğinden emin olun
4. İçinde şunlar olmalı:
   ```xml
   <key>aps-environment</key>
   <string>production</string>
   ```

### ADIM 5: Build ve Test

1. Xcode'da **Product** > **Clean Build Folder** (Shift + Cmd + K)

2. **Product** > **Build** (Cmd + B)

3. Gerçek bir iOS cihazına deploy edin (Simulator'da push notification çalışmaz!)

4. Uygulamayı açın ve bildirim izni verin

5. Xcode Console'da şu logları kontrol edin:
   ```
   ✅ iOS AppDelegate: APNs token alındı: ...
   ✅ iOS AppDelegate: FCM token başarıyla alındı
   ✅ iOS AppDelegate: FCM token Firestore'a başarıyla kaydedildi
   ```

## 🔍 Sorun Giderme

### Sorun: APNs token alınamıyor (Hata 3010)
**Çözüm**: Push Notifications capability Xcode'da eklenmemiş. ADIM 1'i tekrar yapın.

### Sorun: FCM token alınamıyor
**Kontrol edin**:
1. APNs key Firebase Console'a yüklenmiş mi? (ADIM 2)
2. Bundle ID eşleşiyor mu? (ADIM 3)
3. Internet bağlantısı var mı?

### Sorun: Bildirim gelmiyor ama token alınıyor
**Kontrol edin**:
1. Cloud Functions deploy edilmiş mi?
2. Firestore'da `users/{userId}/fcmToken` alanı dolu mu?
3. Test bildirimi gönderin:
   ```bash
   curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP \
     -H "Content-Type: application/json" \
     -d '{"userId": "YOUR_USER_ID", "message": "TEST BİLDİRİMİ"}'
   ```

### Sorun: Bildirim geliyor ama uygulama kapalıyken gelmiyor
**Kontrol edin**:
1. Background Modes > Remote notifications işaretli mi?
2. Info.plist'te `UIBackgroundModes` içinde `remote-notification` var mı?
3. Entitlements dosyasında `aps-environment` = `production` mi?

## 📱 Test Adımları

1. **Uygulamayı gerçek cihaza deploy edin** (Simulator çalışmaz!)

2. **Bildirim izni verin** (ilk açılışta sorulacak)

3. **Xcode Console'da logları kontrol edin**:
   - APNs token alındı mı?
   - FCM token alındı mı?
   - Token Firestore'a kaydedildi mi?

4. **Firebase Console > Firestore**'da kontrol edin:
   - `users/{userId}/fcmToken` alanı dolu mu?

5. **Test bildirimi gönderin**:
   - Cloud Functions HTTP endpoint'i kullanın
   - Veya Firebase Console > Cloud Messaging > Send test message

## ✅ Başarı Kriterleri

- ✅ APNs token başarıyla alınıyor
- ✅ FCM token başarıyla alınıyor
- ✅ Token Firestore'a kaydediliyor
- ✅ Bildirimler geliyor (uygulama açıkken)
- ✅ Bildirimler geliyor (uygulama kapalıyken)
- ✅ Badge sayısı doğru güncelleniyor

## 📞 Destek

Sorun devam ederse:
1. Xcode Console loglarını kontrol edin
2. Firebase Console > Cloud Messaging > Delivery reports kontrol edin
3. Apple Developer Portal > Certificates > Push Notifications kontrol edin





