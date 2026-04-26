# 📱 Mesaj Bildirim Sistemi Dokümantasyonu

## 🎯 Genel Bakış

Bu sistem, Flutter ve Firebase kullanarak tam çalışır bir chat mesaj bildirim sistemi sağlar. Kullanıcılar birbirlerine mesaj gönderdiğinde, alıcıya push bildirimi gönderilir.

## 📋 Sistem Bileşenleri

### 1. Cloud Functions (Backend)
- **Konum**: `functions/src/index.ts`
- **Görev**: Yeni mesaj oluşturulduğunda bildirim gönderme
- **Tetikleyici**: `conversations` koleksiyonuna yeni mesaj eklendiğinde

### 2. Flutter FCM Token Service
- **Konum**: `lib/services/fcm_token_service.dart`
- **Görev**: FCM token'ı al ve Firestore'a kaydet
- **Çalışma Zamanı**: Uygulama açıldığında, token yenilendiğinde

### 3. Flutter Bildirim Alma
- **Konum**: `lib/screens/message_screen.dart`, `lib/main.dart`
- **Görev**: Bildirimleri al, göster ve yönlendir

## 🗄️ Firestore Koleksiyon Yapısı

### `users/{userId}`
```json
{
  "fcmToken": "dGhpcyBpcyBhIHRva2Vu...",
  "fcmTokenUpdatedAt": "2025-11-07T23:00:00Z",
  "username": "kullanici_adi",
  "email": "email@example.com"
}
```

### `conversations/{messageId}`
```json
{
  "text": "Merhaba, nasılsın?",
  "sender": "user1_id",
  "recipient": "user2_id",
  "timestamp": "2025-11-07T23:00:00Z",
  "messagesId": "conversation_id",
  "users": ["user1_id", "user2_id"],
  "postId": "post_id",
  "isRead": false,
  "senderName": "Ahmet"
}
```

## 🚀 Kurulum Adımları

### 1. Cloud Functions Kurulumu

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### 2. Flutter Bağımlılıkları

`pubspec.yaml` dosyasında zaten mevcut:
- `firebase_messaging`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `flutter_local_notifications`

### 3. Android Yapılandırması

`android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}
```

`AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 4. iOS Yapılandırması

`ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

Push notification capability'yi Xcode'da etkinleştirin.

## 📱 Kullanım Senaryoları

### Senaryo 1: Uygulama Açıldığında

1. `FCMTokenService.initializeAndSaveToken()` çağrılır
2. Bildirim izni istenir
3. FCM token alınır
4. Token Firestore'da `users/{userId}/fcmToken` olarak kaydedilir

### Senaryo 2: Mesaj Gönderildiğinde

1. Kullanıcı mesaj gönderir (`message_screen.dart` → `_handleSubmitted`)
2. Mesaj Firestore'a eklenir (`conversations` koleksiyonu)
3. Cloud Function tetiklenir (`onMessageCreated`)
4. Alıcının `fcmToken`'ı alınır
5. FCM ile bildirim gönderilir

### Senaryo 3: Bildirim Alındığında

#### Uygulama Ön Planda
- `FirebaseMessaging.onMessage` tetiklenir
- `flutterLocalNotificationsPlugin.show()` ile bildirim gösterilir
- Kullanıcı bildirime tıklarsa mesaj ekranına yönlendirilir

#### Uygulama Arka Planda
- `FirebaseMessaging.onMessageOpenedApp` tetiklenir
- Mesaj ekranına yönlendirilir

#### Uygulama Kapalı
- `FirebaseMessaging.instance.getInitialMessage()` ile kontrol edilir
- Uygulama açıldığında mesaj ekranına yönlendirilir

## 🔧 Kod Örnekleri

### FCM Token Kaydetme

```dart
// Otomatik olarak main.dart'ta çalışır
await FCMTokenService().initializeAndSaveToken();
```

### Mesaj Gönderme

```dart
await FirebaseFirestore.instance.collection("conversations").add({
  "text": "Merhaba!",
  "sender": currentUserId,
  "recipient": recipientId,
  "timestamp": FieldValue.serverTimestamp(),
  "senderName": "Ahmet",
  // ... diğer alanlar
});
// Cloud Function otomatik olarak bildirim gönderir
```

### Bildirim Alma ve İşleme

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'message') {
    // Bildirimi göster
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      message.notification?.title ?? "Yeni mesaj",
      message.notification?.body ?? "",
      // ...
    );
  }
});
```

## 🐛 Sorun Giderme

### Bildirimler Gelmiyor

1. **FCM Token kontrolü:**
   ```dart
   String? token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. **Firestore'da token var mı kontrol et:**
   ```javascript
   // Firebase Console'da
   users/{userId}/fcmToken
   ```

3. **Cloud Functions loglarını kontrol et:**
   ```bash
   firebase functions:log
   ```

### Token Güncellenmiyor

- `FCMTokenService` otomatik olarak token yenilemeyi dinler
- `onTokenRefresh` listener'ı aktif olmalı

### Bildirim İzni Reddedildi

- Android: Ayarlar → Uygulamalar → CanlıPazar → Bildirimler
- iOS: Ayarlar → CanlıPazar → Bildirimler

## 📊 Test Etme

### 1. Test Mesajı Gönderme

```dart
// Test için mesaj gönder
await FirebaseFirestore.instance.collection("conversations").add({
  "text": "Test mesajı",
  "sender": "test_user_id",
  "recipient": "target_user_id",
  "timestamp": FieldValue.serverTimestamp(),
  "senderName": "Test Kullanıcı",
  "messagesId": "test_conversation_id",
  "users": ["test_user_id", "target_user_id"],
  "postId": "",
});
```

### 2. Cloud Function Test

```bash
# Cloud Functions'ı test et
firebase functions:shell
# Sonra:
onMessageCreated({text: "Test", sender: "user1", recipient: "user2"})
```

## 🔒 Güvenlik

- FCM token'lar sadece kullanıcının kendi dokümanında saklanır
- Cloud Functions Firestore rules'a uyar
- Bildirimler sadece alıcıya gönderilir

## 📝 Notlar

- Cloud Functions deploy edilmeden bildirimler çalışmaz
- iOS'ta APNs sertifikası gerekli
- Android'de `google-services.json` doğru yapılandırılmalı

## 🚀 Deployment

```bash
# Cloud Functions deploy
cd functions
npm install
npm run build
firebase deploy --only functions

# Flutter build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

**Son Güncelleme**: 2025-11-07
**Versiyon**: 1.0.0














