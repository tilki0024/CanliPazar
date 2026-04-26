# iOS Push Notification Sorun Çözüm Raporu

## ✅ YAPILAN DÜZELTMELER

### 1. Runner.entitlements - Production Ortamı
**Dosya:** `ios/Runner/Runner.entitlements`
**Değişiklik:** `aps-environment` = `development` → `production`
**Açıklama:** Production build için production ortamı kullanılmalı

### 2. AppDelegate.swift - APNs Token Sonrası FCM Token Kontrolü
**Dosya:** `ios/Runner/AppDelegate.swift`
**Değişiklik:** `didRegisterForRemoteNotificationsWithDeviceToken` içinde APNs token verildikten sonra FCM token kontrolü eklendi
**Açıklama:** APNs token verildikten sonra FCM token'ın hazır olması için 1 saniye bekleyip kontrol ediyor

### 3. Cloud Functions - Detaylı Hata Log'ları
**Dosya:** `functions/src/index.ts`
**Değişiklikler:**
- Gönderen ve alıcı ID kontrolü eklendi
- Token gönderme hatası için detaylı log'lar eklendi
- Token geçersizlik durumları için özel log'lar eklendi
- Bildirim başarı durumu için detaylı log'lar eklendi

### 4. Cloud Functions - Bildirim Başlığı
**Dosya:** `functions/src/index.ts`
**Değişiklik:** Bildirim başlığı "CANLI PAZARDAN BİR MESAJINIZ VAR!" → "Yeni Mesajın Var"

## ⚠️ MANUEL YAPILMASI GEREKENLER

### 1. Xcode'da Capability Ekleme (KRİTİK)
**Adımlar:**
1. Xcode'da `ios/Runner.xcworkspace` dosyasını açın
2. Project Navigator'da `Runner` target'ını seçin
3. `Signing & Capabilities` sekmesine gidin
4. `+ Capability` butonuna tıklayın
5. `Push Notifications` capability'sini ekleyin
6. `+ Capability` butonuna tekrar tıklayın
7. `Background Modes` capability'sini ekleyin
8. `Background Modes` içinde `Remote notifications` seçeneğini işaretleyin

**Neden Önemli:**
- Bu capability'ler olmadan iOS push notification çalışmaz
- project.pbxproj dosyası otomatik düzenlenemez, Xcode'da manuel eklenmeli

### 2. Cloud Functions Deploy
```bash
cd functions
npm run build
firebase deploy --only functions:onMessageCreated
```

### 3. Firebase Console - APNs Sertifikası Kontrolü
1. Firebase Console > Project Settings > Cloud Messaging
2. APNs Authentication Key veya Certificate yüklü mü kontrol edin
3. Production ve Development sertifikalarını kontrol edin

## 🔍 SORUN TESPİTİ - TÜM OLASILIKLAR

### 1. Token Firestore'a Kaydedilmiyor
**Olası Nedenler:**
- Firebase Auth kullanıcısı giriş yapmamış
- AppDelegate.swift'te `getCurrentUserId()` null dönüyor
- Firestore yazma izinleri yok

**Kontrol:**
- Xcode Console'da "Kullanıcı ID bulunamadı" mesajını kontrol edin
- Firestore'da `users/{userId}/fcmToken` alanını kontrol edin
- Firestore Rules'da yazma izni olduğundan emin olun

**Çözüm:**
- Uygulamayı açın ve giriş yapın
- Xcode Console log'larını kontrol edin
- Firestore Rules'ı kontrol edin

### 2. Cloud Function Tetiklenmiyor
**Olası Nedenler:**
- Function deploy edilmemiş
- Mesajlar yanlış koleksiyona kaydediliyor
- Firestore trigger çalışmıyor

**Kontrol:**
```bash
firebase functions:list | grep onMessageCreated
firebase functions:log --only onMessageCreated
```

**Çözüm:**
- Function'ı deploy edin
- Mesajların `conversations` koleksiyonuna kaydedildiğini kontrol edin
- Firestore trigger'larının aktif olduğunu kontrol edin

### 3. Bildirim Gelmiyor
**Olası Nedenler:**
- Token geçersiz veya boş
- APNs sertifikası yüklenmemiş veya geçersiz
- Capability ayarları eksik
- Bildirim izni verilmemiş

**Kontrol:**
- Firestore'da token'ın geçerli olduğunu kontrol edin (150+ karakter)
- Firebase Console > Cloud Messaging > APNs sertifikasını kontrol edin
- iOS Ayarlar > Bildirimler > CanlıPazar'ı kontrol edin
- Xcode'da capability'leri kontrol edin

**Çözüm:**
- Token'ı yeniden kaydedin
- APNs sertifikasını Firebase Console'a yükleyin
- Xcode'da capability'leri ekleyin
- Bildirim izni verin

### 4. iOS Capability Ayarları Eksik
**Olası Nedenler:**
- Xcode'da manuel olarak eklenmemiş
- project.pbxproj dosyasında SystemCapabilities tanımlı değil

**Kontrol:**
- Xcode'da Runner target > Signing & Capabilities
- Push Notifications capability'si var mı?
- Background Modes > Remote notifications işaretli mi?

**Çözüm:**
- Xcode'da manuel olarak ekleyin (yukarıdaki adımları takip edin)

### 5. Entitlements Dosyası Yanlış
**Olası Nedenler:**
- `aps-environment` = `development` (production build için)
- Entitlements dosyası projeye eklenmemiş

**Kontrol:**
- `ios/Runner/Runner.entitlements` dosyasını kontrol edin
- `aps-environment` = `production` olmalı (production build için)

**Çözüm:**
- ✅ Düzeltildi: `aps-environment` = `production` yapıldı

### 6. AppDelegate.swift'te Token Kaydı Çalışmıyor
**Olası Nedenler:**
- Firebase Auth kullanıcısı giriş yapmamış
- `getCurrentUserId()` null dönüyor
- Firestore yazma hatası

**Kontrol:**
- Xcode Console'da token kayıt log'larını kontrol edin
- "Kullanıcı ID bulunamadı" mesajını kontrol edin
- Firestore yazma hatalarını kontrol edin

**Çözüm:**
- ✅ Düzeltildi: APNs token alındıktan sonra FCM token kontrolü eklendi
- Uygulamayı açın ve giriş yapın

### 7. Cloud Functions'ta Token Kontrolü Başarısız
**Olası Nedenler:**
- Token null veya boş
- Token tipi yanlış (string değil)
- Token çok kısa

**Kontrol:**
- Cloud Functions log'larını kontrol edin
- "Token tipi" ve "uzunluk" log'larını kontrol edin

**Çözüm:**
- ✅ Düzeltildi: Token kontrolü iyileştirildi, detaylı log'lar eklendi

## 📋 KONTROL LİSTESİ

### iOS Native
- [x] AppDelegate.swift'te tüm delegate'ler ayarlanmış
- [x] Token Firestore'a kaydediliyor
- [x] APNs token FCM'e veriliyor
- [x] Info.plist'te UIBackgroundModes doğru
- [x] Entitlements dosyaları mevcut ve doğru
- [ ] **Xcode'da Push Notifications capability eklendi (MANUEL)**
- [ ] **Xcode'da Background Modes capability eklendi (MANUEL)**

### Flutter
- [x] main.dart'ta FCM initialize ediliyor
- [x] Background handler ayarlanmış
- [x] FCMTokenService çalışıyor
- [x] UserProvider'da token kaydı yapılıyor
- [x] AuthMethods'da token kaydı yapılıyor

### Cloud Functions
- [x] onMessageCreated function'ı mevcut
- [x] Token kontrolü iyileştirildi
- [x] iOS APNs payload'ı doğru
- [x] Detaylı hata log'ları eklendi
- [ ] **Function deploy edildi mi? (KONTROL ET)**

### Firebase Konfigürasyonu
- [x] GoogleService-Info.plist doğru konumda
- [x] Bundle ID eşleşiyor
- [ ] **APNs sertifikası Firebase Console'a yüklenmiş mi? (KONTROL ET)**

## 🚀 SONRAKI ADIMLAR

1. **Xcode'da Capability Ekleme (KRİTİK - MANUEL)**
   - Push Notifications capability ekle
   - Background Modes > Remote notifications işaretle

2. **Cloud Functions Deploy**
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions:onMessageCreated
   ```

3. **Test**
   - Uygulamayı iOS cihazda çalıştırın
   - Giriş yapın
   - Firestore'da token'ın kaydedildiğini kontrol edin
   - Test mesajı gönderin
   - Bildirimin geldiğini kontrol edin

4. **Firebase Console Kontrolü**
   - APNs sertifikasının yüklü olduğunu kontrol edin
   - Cloud Messaging ayarlarını kontrol edin

## 📝 NOTLAR

- Tüm kod değişiklikleri tamamlandı
- Xcode'da capability ekleme MANUEL olarak yapılmalı
- Cloud Functions deploy edilmeli
- APNs sertifikası Firebase Console'a yüklenmeli
- Test edilene kadar bildirimler çalışmayabilir








