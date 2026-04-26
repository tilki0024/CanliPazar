# iOS Push Notification Test Adımları

## ✅ Tamamlanan İşlemler

1. ✅ **Capability'ler Eklendi** - Xcode'da Push Notifications ve Background Modes eklendi
2. ✅ **Cloud Functions Deploy Edildi** - `onMessageCreated` function'ı başarıyla deploy edildi
3. ✅ **AppDelegate.swift Düzeltildi** - Token Firestore'a kaydediliyor
4. ✅ **Entitlements Düzeltildi** - Production ortamı için `production` yapıldı
5. ✅ **Cloud Functions İyileştirildi** - Detaylı log'lar ve hata kontrolü eklendi

## 🔍 Son Kontroller

### 1. Background Modes İçinde Remote Notifications İşaretli mi?
**Kontrol:**
- Xcode'da `Runner` target > `Signing & Capabilities`
- `Background Modes` capability'sini açın
- `Remote notifications` seçeneğinin işaretli olduğundan emin olun

### 2. Push Notifications Capability Aktif mi?
**Kontrol:**
- Xcode'da `Runner` target > `Signing & Capabilities`
- `Push Notifications` capability'sinin ekli olduğundan emin olun
- Herhangi bir hata mesajı var mı kontrol edin

## 🧪 Test Adımları

### 1. Uygulamayı Temiz Build ile Çalıştırın
```bash
cd ios
flutter clean
flutter pub get
cd ..
flutter run
```

### 2. Token Kontrolü
**Xcode Console'da şu mesajları kontrol edin:**
```
✅ iOS AppDelegate: FCM token başarıyla alındı
✅ iOS AppDelegate: FCM token Firestore'a kaydedildi: {userId}
```

**Firestore Console'da kontrol edin:**
- `users/{userId}/fcmToken` alanının dolu olduğundan emin olun
- Token uzunluğu 150+ karakter olmalı

### 3. Bildirim İzni Kontrolü
- Uygulama açıldığında bildirim izni isteği gelmeli
- iOS Ayarlar > Bildirimler > CanlıPazar > Bildirimler açık olmalı

### 4. Test Mesajı Gönderme
**İki farklı kullanıcı ile:**
1. Kullanıcı A ile giriş yapın
2. Kullanıcı B ile giriş yapın (farklı cihaz veya simulator)
3. Kullanıcı A'dan Kullanıcı B'ye mesaj gönderin
4. Kullanıcı B'nin cihazında bildirim gelmeli

### 5. Cloud Functions Log Kontrolü
```bash
cd functions
firebase functions:log --only onMessageCreated
```

**Beklenen log'lar:**
```
📨 Yeni mesaj: {messageId}
Gönderen: {senderId}, Alıcı: {recipientId}
✅ Alıcı token bulundu: {token}...
📊 Okunmamış mesaj sayısı: {count}
✅ Bildirim başarıyla gönderildi: {response}
```

## 🚨 Sorun Giderme

### Bildirim Gelmiyorsa

#### 1. Token Kontrolü
- Firestore'da `users/{userId}/fcmToken` alanını kontrol edin
- Token null veya boş mu?
- Token uzunluğu yeterli mi? (150+ karakter)

**Çözüm:**
- Uygulamayı kapatıp açın
- Giriş yapın
- Xcode Console'da token log'larını kontrol edin

#### 2. Cloud Functions Log Kontrolü
```bash
firebase functions:log --only onMessageCreated
```

**Hata mesajları:**
- "Alıcı token bulunamadı" → Token Firestore'a kaydedilmemiş
- "Bildirim gönderme hatası" → Token geçersiz veya APNs sertifikası sorunu

#### 3. APNs Sertifikası Kontrolü
- Firebase Console > Project Settings > Cloud Messaging
- APNs Authentication Key veya Certificate yüklü mü?
- Production ve Development sertifikaları doğru mu?

#### 4. Capability Kontrolü
- Xcode'da `Runner` target > `Signing & Capabilities`
- Push Notifications capability'si ekli mi?
- Background Modes > Remote notifications işaretli mi?

#### 5. Bildirim İzni Kontrolü
- iOS Ayarlar > Bildirimler > CanlıPazar
- Bildirimler açık mı?
- Uygulama içinde bildirim izni verildi mi?

## 📊 Beklenen Davranış

### Uygulama Açıkken (Foreground)
- Bildirim ekranda gösterilmeli
- Badge sayısı güncellenmeli
- Ses çalmalı

### Uygulama Arka Plandayken (Background)
- Bildirim gösterilmeli
- Badge sayısı güncellenmeli
- Bildirime tıklandığında mesaj sayfasına yönlendirilmeli

### Uygulama Kapalıyken (Terminated)
- Bildirim gösterilmeli
- Badge sayısı güncellenmeli
- Bildirime tıklandığında uygulama açılıp mesaj sayfasına yönlendirilmeli

## ✅ Başarı Kriterleri

- [ ] Token Firestore'a kaydediliyor
- [ ] Cloud Function tetikleniyor
- [ ] Bildirim gönderiliyor
- [ ] Bildirim cihazda görünüyor
- [ ] Badge sayısı güncelleniyor
- [ ] Bildirime tıklandığında mesaj sayfasına yönlendiriliyor

## 🔧 Hala Çalışmıyorsa

1. **Xcode Console Log'larını Kontrol Edin**
   - "FCM token" mesajlarını arayın
   - "Firestore'a kaydedildi" mesajlarını arayın
   - Hata mesajlarını kontrol edin

2. **Cloud Functions Log'larını Kontrol Edin**
   ```bash
   firebase functions:log --only onMessageCreated
   ```

3. **Firestore'da Token Kontrolü**
   - `users/{userId}/fcmToken` alanını kontrol edin
   - Token geçerli mi? (150+ karakter)

4. **Firebase Console Kontrolü**
   - APNs sertifikası yüklü mü?
   - Cloud Messaging ayarları doğru mu?

5. **Test Bildirimi Gönderin**
   ```bash
   curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP \
     -H "Content-Type: application/json" \
     -d '{"userId": "YOUR_USER_ID", "message": "TEST BİLDİRİMİ"}'
   ```








