# Hata Çözüm Talimatları

## 1. Google Fonts AssetManifest.json Hatası

Bu hata genellikle Flutter build cache sorunudur. Şu adımları izleyin:

### Çözüm Adımları:

```bash
# 1. Flutter cache'i temizle
flutter clean

# 2. Dependencies'i yeniden yükle
flutter pub get

# 3. Uygulamayı yeniden build et
flutter run
```

### Alternatif Çözüm (Eğer yukarıdaki işe yaramazsa):

```bash
# 1. Flutter cache'i tamamen temizle
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf ios/Pods
rm -rf ios/.symlinks

# 2. iOS için (eğer iOS'ta çalışıyorsanız)
cd ios
pod deintegrate
pod install
cd ..

# 3. Dependencies'i yeniden yükle
flutter pub get

# 4. Uygulamayı yeniden build et
flutter run
```

### Not:
Google Fonts paketi internetten font indiriyor. Eğer internet bağlantınız yoksa veya Google Fonts API'sine erişemiyorsanız, bu hata oluşabilir. Bu durumda:
- İnternet bağlantınızı kontrol edin
- VPN kullanıyorsanız kapatıp tekrar deneyin

## 2. Cloud Functions INTERNAL Hatası

Cloud Functions hatası için yapılan iyileştirmeler:

### Yapılan İyileştirmeler:

1. **Güvenli Error Handling**: Tüm hatalar yakalanıyor ve INTERNAL hataya düşmüyor
2. **Detaylı Logging**: Hata kodları ve mesajları loglanıyor
3. **Mantıklı Response**: Başarısız gönderimlerde `{success: false, reason: ...}` dönüyor

### Cloud Functions Deploy:

Yeni Cloud Functions kodunu deploy etmek için:

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:sendMessageNotificationCallable,functions:sendListingNotificationCallable
```

### Hata Kontrolü:

Eğer hala INTERNAL hatası alıyorsanız:

1. **Firebase Console'da Logları Kontrol Edin:**
   - Firebase Console → Functions → Logs
   - `sendMessageNotificationCallable` fonksiyonunun loglarını kontrol edin

2. **Fonksiyonun Deploy Edildiğinden Emin Olun:**
   ```bash
   firebase functions:list
   ```

3. **Test Edin:**
   ```bash
   firebase functions:shell
   # Sonra:
   sendMessageNotificationCallable({
     recipientId: "test-recipient-id",
     senderId: "test-sender-id",
     senderUsername: "Test User",
     messageText: "Test mesaj",
     conversationId: "test-conversation-id",
     messageId: "test-message-id",
     postId: "",
     title: "Test Bildirimi"
   })
   ```

## 3. Flutter Tarafında İyileştirmeler

`lib/services/push_notification_service.dart` dosyasında:

- ✅ FirebaseFunctionsException için özel handling eklendi
- ✅ INTERNAL hatası özel olarak loglanıyor
- ✅ Result data kontrolü eklendi (success field kontrolü)

## 4. Test Senaryoları

### Mesaj Bildirimi Testi:

```dart
final result = await PushNotificationService().sendMessageNotification(
  recipientId: "test-recipient-id",
  senderId: "test-sender-id",
  senderUsername: "Test User",
  messageText: "Test mesaj",
  conversationId: "test-conversation-id",
  messageId: "test-message-id",
  postId: "test-post-id",
);

print('Bildirim sonucu: $result'); // true veya false
```

### Hata Senaryoları:

1. **Geçersiz Token**: `{success: false, reason: 'invalid_fcm_token'}`
2. **Alıcı Bulunamadı**: `{success: false, reason: 'recipient_not_found'}`
3. **Firestore Hatası**: `{success: false, reason: 'firestore_error'}`
4. **FCM Gönderim Hatası**: `{success: false, reason: 'send_failed'}`

## 5. Sorun Giderme

### Google Fonts Hatası Devam Ediyorsa:

1. **pubspec.yaml'ı kontrol edin:**
   - `google_fonts: ^6.2.0` versiyonunu kontrol edin
   - `flutter pub upgrade google_fonts` çalıştırın

2. **Manuel Font Yükleme:**
   - Eğer Google Fonts sürekli sorun çıkarıyorsa, Poppins fontunu manuel olarak ekleyebilirsiniz
   - `pubspec.yaml`'a fonts section ekleyin

### Cloud Functions Hatası Devam Ediyorsa:

1. **Firebase Console'da Functions Loglarını Kontrol Edin**
2. **Fonksiyonun Deploy Edildiğinden Emin Olun**
3. **Fonksiyon Parametrelerini Kontrol Edin**
4. **Token Validation'ı Kontrol Edin**

## 6. Önemli Notlar

- ✅ Mevcut sohbetler ve kullanıcı verileri korunuyor
- ✅ Sadece bildirim sistemi refactor edildi
- ✅ iOS ve Android uyumluluğu %100 hedeflendi
- ✅ Production-ready kod yazıldı

## 7. Destek

Eğer sorunlar devam ederse:

1. Firebase Console → Functions → Logs bölümünden detaylı logları kontrol edin
2. Flutter console loglarını kontrol edin
3. Cloud Functions'ın deploy edildiğinden emin olun







