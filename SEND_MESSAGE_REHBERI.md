# Otomatik Mesaj Gönderme Rehberi

## 🎯 Amaç
Belirli bir kullanıcı ID'sine (`CtBc8p5lhaSgQDv3oI9jfUwMAmS2`) otomatik test mesajı göndermek.

## 📋 Yöntemler

### Yöntem 1: Firebase Console'dan Manuel (En Kolay)

1. Firebase Console'a git: https://console.firebase.google.com
2. Projeyi seç: `canlipazar-b3697`
3. **Firestore Database** > **Data** sekmesine git
4. `conversations` koleksiyonuna yeni bir doküman ekle:

```json
{
  "text": "Merhaba! Bu otomatik bir test mesajıdır.",
  "sender": "TEST_SENDER",
  "recipient": "CtBc8p5lhaSgQDv3oI9jfUwMAmS2",
  "timestamp": [Server Timestamp],
  "messagesId": "TEST_SENDER-CtBc8p5lhaSgQDv3oI9jfUwMAmS2",
  "users": ["TEST_SENDER", "CtBc8p5lhaSgQDv3oI9jfUwMAmS2"],
  "postId": "",
  "isRead": false,
  "senderName": "Test Kullanıcı",
  "notificationTitle": "Test Kullanıcı",
  "notificationBody": "Merhaba! Bu otomatik bir test mesajıdır."
}
```

5. `users` koleksiyonunda `CtBc8p5lhaSgQDv3oI9jfUwMAmS2` kullanıcısını bul
6. `unreadMessageCount` field'ını artır (veya yoksa 1 olarak ekle)

### Yöntem 2: Uygulama İçinden (Önerilen)

Uygulamayı aç ve mesaj gönderme ekranından direkt gönder. Bu en güvenli ve doğru yöntemdir.

### Yöntem 3: Firebase Admin SDK (Gelişmiş)

1. Firebase Console'dan Service Account key indir
2. `serviceAccountKey.json` dosyasını proje root'una koy
3. Node.js script'i çalıştır:
```bash
npm install firebase-admin
node send_message.js
```

## ⚠️ Önemli Notlar

- **Güvenlik**: Direkt Firestore'a yazmak için güvenlik kuralları izin vermiyor olabilir
- **Authentication**: Mesaj göndermek için giriş yapmış bir kullanıcı olması gerekebilir
- **Test**: Test için en iyi yöntem uygulama içinden göndermektir

## 🚀 Hızlı Test

En hızlı yöntem: Uygulamayı aç, mesajlar sekmesine git, yeni mesaj oluştur ve `CtBc8p5lhaSgQDv3oI9jfUwMAmS2` kullanıcısına mesaj gönder.































