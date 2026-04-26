# iOS Push Bildirim Sistemi Kurulum Rehberi

## 📋 Dosya Yapısı

```
ios/
└── Runner/
    ├── AppDelegate.swift          ✅ Güncellendi
    └── NotificationManager.swift   ✅ Yeni oluşturuldu

functions/
├── src/
│   └── notificationService.js     ✅ Yeni oluşturuldu
└── APNS_PAYLOAD_EXAMPLE.json      ✅ Örnek payload
```

## 🔧 1. AppDelegate.swift Güncellemeleri

**Dosya Yolu:** `ios/Runner/AppDelegate.swift`

### Yapılan Değişiklikler:
- ✅ Push bildirim sistemi kurulumu eklendi
- ✅ NotificationManager entegrasyonu
- ✅ APNs token yönetimi
- ✅ Uygulama açıldığında badge sıfırlama
- ✅ Terminated state bildirim handling

## 📱 2. NotificationManager.swift

**Dosya Yolu:** `ios/Runner/NotificationManager.swift`

### Özellikler:
- ✅ Bildirim izni isteme
- ✅ Badge yönetimi (güncelleme, sıfırlama, artırma, azaltma)
- ✅ APNs token backend'e gönderme
- ✅ Bildirim içeriği parse etme
- ✅ UNUserNotificationCenterDelegate implementasyonu

## 🔑 3. APNs Yapılandırması

### Gerekli Adımlar:

1. **Apple Developer Console'dan .p8 Anahtarı İndirin:**
   - https://developer.apple.com/account/resources/authkeys/list
   - "Create a key" butonuna tıklayın
   - "Apple Push Notifications service (APNs)" seçeneğini işaretleyin
   - Key ID'yi not edin
   - .p8 dosyasını indirin

2. **.p8 Dosyasını Projeye Ekleyin:**
   ```
   functions/
   └── keys/
       └── AuthKey_XXXXXXXXXX.p8
   ```

3. **notificationService.js'i Yapılandırın:**
   - `YOUR_KEY_ID` → Key ID'nizi yazın
   - `YOUR_TEAM_ID` → Team ID'nizi yazın (Apple Developer Console'dan)
   - `.p8` dosya yolunu kontrol edin

## 📦 4. NPM Paketleri

`functions/package.json` dosyasına ekleyin:

```json
{
  "dependencies": {
    "apn": "^3.0.0"
  }
}
```

Kurulum:
```bash
cd functions
npm install apn
```

## 🎯 5. Capabilities Ayarları

### Xcode'da Yapılacaklar:

1. **Push Notifications Capability:**
   - Xcode'da projeyi açın
   - Target → Signing & Capabilities
   - "+ Capability" → "Push Notifications" ekleyin

2. **Background Modes:**
   - "+ Capability" → "Background Modes"
   - "Remote notifications" seçeneğini işaretleyin

3. **Info.plist Kontrolü:**
   - `UIBackgroundModes` içinde `remote-notification` olmalı
   - ✅ Zaten mevcut

## 🔔 6. Bildirim İzni

Bildirim izni otomatik olarak isteniyor:
- Uygulama ilk açıldığında
- `NotificationManager.shared.requestNotificationPermission()` çağrıldığında

## 📊 7. Badge Yönetimi

### Badge Güncelleme:
```swift
// Badge sayısını güncelle
NotificationManager.shared.updateBadge(count: 5)

// Badge'i sıfırla (uygulama açıldığında)
NotificationManager.shared.resetBadge()

// Badge'i artır
NotificationManager.shared.incrementBadge()

// Badge'i azalt
NotificationManager.shared.decrementBadge()
```

### Otomatik Badge Güncelleme:
- Bildirim geldiğinde otomatik güncellenir
- Uygulama açıldığında sıfırlanır (AppDelegate'de)

## 🚀 8. Backend Kullanımı

### Firebase Cloud Functions ile:

Mevcut `functions/src/index.ts` dosyası zaten APNs payload'ını doğru şekilde gönderiyor.

### Direkt APNs ile (notificationService.js):

```javascript
const { getNotificationService } = require('./src/notificationService');

const notificationService = getNotificationService();

await notificationService.sendMessageNotification(
  deviceToken,
  {
    title: 'CanlıPazardan bir mesajınız var',
    body: 'Merhaba, nasılsın?',
    senderId: 'user123',
    receiverId: 'user456',
    messageId: 'msg789',
    text: 'Merhaba, nasılsın?'
  },
  5 // Okunmamış mesaj sayısı
);
```

## ✅ 9. Test Etme

1. **Uygulamayı Çalıştırın:**
   ```bash
   flutter run
   ```

2. **Bildirim İzni Kontrolü:**
   - Uygulama açıldığında bildirim izni istenmeli
   - İzin verildikten sonra APNs token alınmalı

3. **Test Bildirimi Gönderin:**
   - Firebase Console'dan test bildirimi gönderebilirsiniz
   - Veya Cloud Functions'ı tetikleyerek

4. **Badge Kontrolü:**
   - Bildirim geldiğinde uygulama ikonunda sayı görünmeli
   - Uygulama açıldığında badge sıfırlanmalı

## 📝 10. Önemli Notlar

- ✅ Firebase Messaging zaten APNs kullanıyor, ekstra kurulum gerekmez
- ✅ Mevcut sistem çalışıyor, NotificationManager ekstra özellikler sağlıyor
- ✅ Badge yönetimi otomatik çalışıyor
- ✅ Terminated state bildirimleri destekleniyor

## 🔍 Sorun Giderme

### Bildirim Gelmiyor:
1. APNs token'ın alındığını kontrol edin (console log)
2. Bildirim izninin verildiğini kontrol edin
3. Firebase Console'dan test bildirimi gönderin

### Badge Güncellenmiyor:
1. `NotificationManager.shared.updateBadge()` çağrıldığını kontrol edin
2. Main thread'de çalıştığından emin olun
3. Uygulama ikonunda badge izninin verildiğini kontrol edin

### Token Backend'e Gitmiyor:
1. `sendTokenToBackend()` fonksiyonunu kontrol edin
2. Backend API URL'ini kontrol edin
3. User ID'nin doğru alındığını kontrol edin












