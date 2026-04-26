# Cloud Functions Deploy Talimatları

## 🔍 Sorun Tespiti

Debug console'da görülen `[firebase_functions/internal] INTERNAL` hatası, Cloud Function'ın henüz deploy edilmediğini veya eski versiyonunun çalıştığını gösteriyor.

## ✅ Çözüm: Cloud Functions'ı Deploy Et

### Adım 1: Functions Klasörüne Git
```bash
cd functions
```

### Adım 2: Dependencies'i Kontrol Et
```bash
npm install
```

### Adım 3: TypeScript Build
```bash
npm run build
```

Eğer build başarılıysa (hiç hata yoksa), devam edin.

### Adım 4: Cloud Functions'ı Deploy Et

**Sadece bildirim fonksiyonlarını deploy et:**
```bash
firebase deploy --only functions:sendMessageNotificationCallable,functions:sendListingNotificationCallable
```

**VEYA tüm fonksiyonları deploy et:**
```bash
firebase deploy --only functions
```

### Adım 5: Deploy Sonrası Kontrol

Deploy başarılı olduktan sonra:

1. **Firebase Console'da Kontrol:**
   - Firebase Console → Functions
   - `sendMessageNotificationCallable` fonksiyonunun varlığını kontrol edin
   - Son deploy zamanını kontrol edin

2. **Test Et:**
   - Flutter uygulamasında bir mesaj gönderin
   - Debug console'da artık INTERNAL hatası görmemelisiniz
   - Başarılı durumda: `✅ [PushNotificationService] Bildirim başarıyla gönderildi`
   - Başarısız durumda: `⚠️ [PushNotificationService] Bildirim gönderilemedi - Reason: ...`

## 🐛 Hala Sorun Varsa

### 1. Firebase Console'da Logları Kontrol Edin

Firebase Console → Functions → Logs bölümünden:
- `sendMessageNotificationCallable` fonksiyonunun loglarını kontrol edin
- Hata mesajlarını okuyun
- Özellikle şu logları arayın:
  - `📤 [sendMessageNotification] Bildirim gönderiliyor...`
  - `❌ [sendMessageNotification] ...` (hata logları)
  - `✅ [sendMessageNotification] Bildirim başarıyla gönderildi`

### 2. Fonksiyonun Deploy Edildiğinden Emin Olun

```bash
firebase functions:list
```

Bu komut tüm deploy edilmiş fonksiyonları listeler. `sendMessageNotificationCallable` listede olmalı.

### 3. Manuel Test

Firebase Console → Functions → `sendMessageNotificationCallable` → Test sekmesinden manuel test yapabilirsiniz:

```json
{
  "data": {
    "recipientId": "test-recipient-id",
    "senderId": "test-sender-id",
    "senderUsername": "Test User",
    "messageText": "Test mesaj",
    "conversationId": "test-conversation-id",
    "messageId": "test-message-id",
    "postId": "",
    "title": "Test Bildirimi"
  }
}
```

## 📋 Beklenen Sonuçlar

### Başarılı Durum:
```json
{
  "success": true,
  "messageId": "projects/.../messages/...",
  "recipientId": "...",
  "platform": "ios" | "android" | "unknown",
  "unreadCount": 1,
  "duration": 123
}
```

### Başarısız Durum (Token Yok):
```json
{
  "success": false,
  "reason": "invalid_fcm_token",
  "message": "Alıcının FCM token'ı geçersiz veya eksik",
  "platform": "ios" | "android" | "unknown"
}
```

### Başarısız Durum (Diğer):
```json
{
  "success": false,
  "reason": "recipient_not_found" | "firestore_error" | "send_failed" | "internal_error",
  "message": "...",
  "recipientId": "...",
  "platform": "...",
  "duration": 123
}
```

## ⚠️ Önemli Notlar

1. **Deploy Süresi**: İlk deploy 5-10 dakika sürebilir
2. **Cold Start**: İlk çağrı biraz yavaş olabilir (cold start)
3. **Log Gecikmesi**: Firebase Console'da loglar 1-2 dakika gecikmeli görünebilir
4. **Token Kontrolü**: Alıcının `fcmToken` alanının Firestore'da dolu olduğundan emin olun

## 🔧 Hızlı Sorun Giderme

### Sorun: "Function not found"
**Çözüm**: Fonksiyonu deploy edin (yukarıdaki adımları izleyin)

### Sorun: "INTERNAL error"
**Çözüm**: 
1. Firebase Console → Functions → Logs'tan detaylı hatayı kontrol edin
2. Fonksiyonun deploy edildiğinden emin olun
3. TypeScript build'in başarılı olduğundan emin olun

### Sorun: "Invalid FCM token"
**Çözüm**: 
1. Alıcının `fcmToken` alanını Firestore'da kontrol edin
2. Token'ın geçerli olduğundan emin olun (100-200 karakter arası)
3. Token'ın boş/null olmadığından emin olun

### Sorun: "Recipient not found"
**Çözüm**: 
1. `recipientId`'nin doğru olduğundan emin olun
2. Firestore'da `users/{recipientId}` dokümanının var olduğundan emin olun







