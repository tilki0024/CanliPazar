# Firebase Cloud Functions - Mesaj Bildirimleri

Bu klasör, mesaj bildirimleri için Firebase Cloud Functions içerir.

## 📋 Gereksinimler

- Node.js 18+
- Firebase CLI
- Firebase projesi yapılandırılmış olmalı

## 🚀 Kurulum

```bash
# Bağımlılıkları yükle
npm install

# TypeScript'i derle
npm run build

# Cloud Functions'ı deploy et
npm run deploy
# veya
firebase deploy --only functions
```

## 📝 Fonksiyonlar

### `onMessageCreated`
- **Tetikleyici**: `conversations` koleksiyonuna yeni mesaj eklendiğinde
- **Görev**: Alıcıya push bildirimi gönderir
- **Parametreler**: 
  - `text`: Mesaj metni
  - `sender`: Gönderen kullanıcı ID
  - `recipient`: Alıcı kullanıcı ID
  - `senderName`: Gönderen kullanıcı adı

### `onUserTokenUpdated`
- **Tetikleyici**: `users` koleksiyonunda FCM token güncellendiğinde
- **Görev**: Token güncellemelerini loglar (opsiyonel)

## 🔧 Yapılandırma

`firebase.json` dosyasında functions yapılandırması mevcut:

```json
{
  "functions": {
    "source": "functions",
    "predeploy": [
      "npm --prefix \"$RESOURCE_DIR\" run build"
    ]
  }
}
```

## 📊 Loglar

Cloud Functions loglarını görüntülemek için:

```bash
firebase functions:log
```

Veya Firebase Console'dan:
- Firebase Console → Functions → Logs

## 🐛 Sorun Giderme

### Functions deploy edilmiyor
- Node.js versiyonunu kontrol edin: `node --version` (18+ olmalı)
- Firebase CLI'nin güncel olduğundan emin olun: `firebase --version`
- Firebase'e login olduğunuzdan emin olun: `firebase login`

### Bildirimler gönderilmiyor
- Cloud Functions'ın deploy edildiğinden emin olun
- Firestore'da `users/{userId}/fcmToken` alanının dolu olduğunu kontrol edin
- Cloud Functions loglarını kontrol edin

## 📚 Daha Fazla Bilgi

- [Firebase Cloud Functions Dokümantasyonu](https://firebase.google.com/docs/functions)
- [FCM Dokümantasyonu](https://firebase.google.com/docs/cloud-messaging)














