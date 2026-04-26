# iOS Bildirim Sorunu Çözüm Rehberi

## Sorun
Kullanıcı mesaj gönderdiğinde Android cihazlara bildirim geliyor ama iOS cihazlara gelmiyor.

## Olası Nedenler ve Çözümler

### 1. Firebase Console'da APNs Key/Certificate Kontrolü (EN ÖNEMLİ)

#### Adım 1: Firebase Console'u Açın
1. https://console.firebase.google.com/ adresine gidin
2. "canlipazar-b3697" projenizi seçin
3. Sol menüden **Project Settings** (Proje Ayarları) → **Cloud Messaging** sekmesine gidin

#### Adım 2: iOS APNs Yapılandırmasını Kontrol Edin
**Apple app configuration** bölümünde şunları kontrol edin:

**Seçenek A: APNs Authentication Key (Önerilen)**
- ✅ APNs Authentication Key yüklü mü?
- ✅ Key ID doğru mu?
- ✅ Team ID doğru mu?

**Seçenek B: APNs Certificates**
- ✅ Development Certificate yüklü mü?
- ✅ Production Certificate yüklü mü?
- ✅ Sertifikalar süresi dolmamış mı?

#### Adım 3: APNs Key Yoksa Yükleyin

**Apple Developer Portal'dan APNs Key Oluşturma:**

1. https://developer.apple.com/account/resources/authkeys/list adresine gidin
2. **Keys** → **+** (Create a new key) butonuna tıklayın
3. Key Name: "CanlıPazar APNs Key" (veya istediğiniz isim)
4. **Apple Push Notifications service (APNs)** seçeneğini işaretleyin
5. **Continue** → **Register** → **Download** yapın
6. ⚠️ **ÖNEMLİ:** Key'i indirin (.p8 dosyası) - sadece bir kez indirebilirsiniz!
7. **Key ID** ve **Team ID**'yi not alın

**Firebase Console'a APNs Key Yükleme:**

1. Firebase Console → Project Settings → Cloud Messaging
2. **Apple app configuration** bölümünde **Upload** butonuna tıklayın
3. İndirdiğiniz .p8 dosyasını seçin
4. **Key ID** girin
5. **Team ID** girin (Apple Developer Account → Membership → Team ID)
6. **Upload** yapın

### 2. iOS App Bundle ID Kontrolü

Firebase Console'da kayıtlı iOS app'in Bundle ID'si Xcode'daki Bundle ID ile eşleşmeli:

**Firebase Console:**
- Project Settings → General → Your apps → iOS apps
- Bundle ID: `com.canlipazar.app` olmalı

**Xcode:**
1. `ios/Runner.xcworkspace` dosyasını Xcode ile açın
2. Runner → General → Identity → Bundle Identifier
3. Bundle ID: `com.canlipazar.app` olmalı

### 3. iOS Capabilities Kontrolü

Xcode'da Push Notifications capability'si aktif olmalı:

1. Xcode'da projeyi açın
2. Runner target'ı seçin
3. **Signing & Capabilities** sekmesine gidin
4. **+ Capability** butonuna tıklayın
5. **Push Notifications** ekleyin (zaten ekliyse ✅ işareti olmalı)
6. **Background Modes** capability'sini de ekleyin
7. Background Modes altında **Remote notifications** seçeneğini işaretleyin

### 4. Provisioning Profile Kontrolü

1. Xcode → Runner → Signing & Capabilities
2. **Automatically manage signing** seçili olmalı
3. **Team** seçili olmalı
4. Provisioning Profile otomatik oluşturulmalı

### 5. GoogleService-Info.plist Kontrolü

1. `ios/Runner/GoogleService-Info.plist` dosyasının var olduğundan emin olun
2. Dosyanın içeriğinde `BUNDLE_ID` değeri `com.canlipazar.app` olmalı
3. Firebase Console'dan indirilen dosya ile eşleşmeli

### 6. Test Adımları

#### Test 1: Firebase Console'dan Manuel Test Bildirimi

1. Firebase Console → Cloud Messaging
2. **Send your first message** veya **New notification**
3. Notification title ve text girin
4. **Send test message** butonuna tıklayın
5. iOS cihazınızın FCM token'ını girin
6. **Test** butonuna tıklayın

**FCM Token'ı Nasıl Bulunur:**
- Uygulamayı iOS cihazda çalıştırın
- Xcode Console'da şu log'u arayın:
  ```
  ✅ [AppDelegate] Firebase registration token alındı: [TOKEN]
  ```
- Token'ı kopyalayın ve Firebase Console'a yapıştırın

#### Test 2: Gerçek Cihazda Test

⚠️ **ÖNEMLİ:** iOS Simulator'da push bildirimleri ÇALIŞMAZ!

1. Gerçek iOS cihazı Mac'e bağlayın
2. Xcode'da cihazı seçin (Simulator değil!)
3. Uygulamayı çalıştırın (Run)
4. Bildirim izni verin
5. Başka bir kullanıcıdan mesaj gönderin

### 7. Log Kontrolü

#### iOS Cihaz Logları (Xcode Console)

Uygulamayı Xcode'dan çalıştırdığınızda şu logları kontrol edin:

**✅ Başarılı Durum:**
```
✅ AppDelegate: Firebase yapılandırıldı
✅ AppDelegate: Firebase Messaging delegate ayarlandı
✅ [AppDelegate] iOS Bildirim izni verildi
📱 [AppDelegate] Remote notifications kaydediliyor...
📱 [AppDelegate] APNs device token: [TOKEN]
✅ [AppDelegate] APNs token Firebase Messaging'e verildi
✅ [AppDelegate] Firebase registration token alındı: [FCM_TOKEN]
```

**❌ Sorunlu Durum:**
```
❌ [AppDelegate] FCM token alınamadı!
❌ [AppDelegate] APNs token Firebase Messaging'e verilmemiş
❌ iOS Bildirim izni reddedildi
```

#### Cloud Functions Logları

Firebase Console → Functions → Logs bölümünde şu logları kontrol edin:

**✅ Başarılı Durum:**
```
✅ [sendMessageNotification] Token alındı: [TOKEN]
✅ [sendMessageNotification] Platform: ios
✅ [sendMessageNotification] Bildirim başarıyla gönderildi: [MESSAGE_ID]
```

**❌ Sorunlu Durum:**
```
❌ [sendMessageNotification] FCM token yok veya boş
❌ [sendMessageNotification] Bildirim gönderilemedi
❌ [FCM Send] Geçersiz token tespit edildi
```

### 8. Sık Karşılaşılan Hatalar

#### Hata 1: "APNs token not set"
**Çözüm:** Firebase Console'da APNs Key/Certificate yüklenmemiş. Yukarıdaki Adım 3'ü takip edin.

#### Hata 2: "Invalid registration token"
**Çözüm:** 
- Token development ortamında üretilmiş ama production APNs kullanılıyor olabilir
- Uygulamayı silip yeniden yükleyin
- Token'ın yeniden üretilmesini bekleyin

#### Hata 3: "Platform unknown"
**Çözüm:**
- Firestore'da kullanıcının `platform` alanı "ios" olmalı
- `fixUnknownPlatforms` Cloud Function'ını çalıştırın:
  ```bash
  curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/fixUnknownPlatforms \
    -H "Content-Type: application/json" \
    -d '{"dryRun": false, "limit": 1000}'
  ```

#### Hata 4: Simulator'da bildirim gelmiyor
**Çözüm:** iOS Simulator push bildirimleri desteklemez. Gerçek cihazda test edin.

### 9. Hızlı Kontrol Listesi

- [ ] Firebase Console'da APNs Key/Certificate yüklü mü?
- [ ] Bundle ID Firebase ve Xcode'da aynı mı? (`com.canlipazar.app`)
- [ ] Xcode'da Push Notifications capability'si aktif mi?
- [ ] Xcode'da Background Modes → Remote notifications aktif mi?
- [ ] GoogleService-Info.plist dosyası doğru mu?
- [ ] Gerçek iOS cihazda test ediliyor mu? (Simulator değil!)
- [ ] iOS cihazda bildirim izni verilmiş mi?
- [ ] Xcode Console'da APNs token alındı mı?
- [ ] Xcode Console'da FCM token alındı mı?
- [ ] Firestore'da kullanıcının `platform` alanı "ios" mu?
- [ ] Firestore'da kullanıcının `fcmToken` alanı dolu mu?

### 10. Acil Çözüm

Eğer yukarıdaki adımları takip ettiyseniz ve hala çalışmıyorsa:

1. **Uygulamayı iOS cihazdan silin**
2. **Xcode'da Clean Build Folder yapın** (Product → Clean Build Folder)
3. **Pods'u yeniden yükleyin:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```
4. **Uygulamayı yeniden derleyin ve yükleyin**
5. **Bildirim iznini yeniden verin**
6. **Test edin**

## Sonraki Adımlar

1. Önce **Firebase Console'da APNs Key kontrolü** yapın (En önemli!)
2. Xcode'da **Push Notifications capability** kontrolü yapın
3. **Gerçek iOS cihazda** test edin
4. Logları kontrol edin ve sonuçları paylaşın

## Destek

Sorun devam ederse, şu bilgileri paylaşın:
- Xcode Console logları (özellikle APNs ve FCM token logları)
- Firebase Functions logları
- Firebase Console'da APNs yapılandırması screenshot'u
- iOS sürümü ve cihaz modeli
