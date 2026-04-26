# iOS Push Notification Debug Rehberi

## Sorun Giderme Adımları

### 1. Token Kontrolü
```bash
# Firestore'da token'ın kaydedildiğini kontrol et
# users/{userId}/fcmToken alanının dolu olduğundan emin ol
```

### 2. Cloud Functions Log Kontrolü
```bash
cd functions
firebase functions:log --only onMessageCreated
```

### 3. iOS Console Log Kontrolü
- Xcode'da Console'u açın
- "FCM token" veya "Firestore'a kaydedildi" mesajlarını kontrol edin
- Hata mesajlarını kontrol edin

### 4. Bildirim İzni Kontrolü
- iOS Ayarlar > Bildirimler > CanlıPazar
- Bildirimlerin açık olduğundan emin olun

### 5. Capability Kontrolü
- Xcode'da Runner target > Signing & Capabilities
- Push Notifications capability'sinin eklendiğinden emin olun
- Background Modes > Remote notifications'in işaretli olduğundan emin olun

### 6. Test Bildirimi Gönderme
```bash
# Cloud Functions test endpoint'i kullan
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP \
  -H "Content-Type: application/json" \
  -d '{"userId": "YOUR_USER_ID", "message": "TEST BİLDİRİMİ"}'
```

## Yaygın Sorunlar

### Token Firestore'a Kaydedilmiyor
- AppDelegate.swift'te `saveTokenToFirestore()` fonksiyonu çalışıyor mu kontrol edin
- Firebase Auth kullanıcısı giriş yapmış mı kontrol edin
- Console log'larında hata var mı kontrol edin

### Cloud Function Tetiklenmiyor
- Firestore'da `conversations` koleksiyonuna yeni mesaj eklendiğinde function tetikleniyor mu kontrol edin
- Cloud Functions log'larını kontrol edin
- Function deploy edilmiş mi kontrol edin

### Bildirim Gelmiyor
- Token geçerli mi kontrol edin (150+ karakter olmalı)
- APNs sertifikası doğru mu kontrol edin
- Entitlements dosyasında `aps-environment` doğru mu kontrol edin








