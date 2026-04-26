# 📱 iOS Bildirimi Gönderme - Hızlı Rehber

## ✅ Cloud Function Deploy Edildi!

`sendIOSOnlyNotification` fonksiyonu başarıyla deploy edildi.

## 🚀 Bildirimi Gönderme - 3 Yöntem

### Yöntem 1: Firebase Console'dan (EN KOLAY - ÖNERİLEN)

1. **Firebase Console'u açın**: https://console.firebase.google.com/project/canlipazar-b3697
2. **Functions** sekmesine gidin
3. **sendIOSOnlyNotification** fonksiyonunu bulun
4. **Test** butonuna tıklayın
5. **Request body** alanına şunu yazın:
   ```json
   {}
   ```
6. **Test** butonuna tıklayın
7. Sonuçları görüntüleyin:
   - `sentCount`: Kaç iOS kullanıcıya gönderildi
   - `success`: Başarılı mı?

### Yöntem 2: Flutter Uygulaması İçinden

Uygulamanızı açın ve şu kodu çalıştırın:

```dart
import 'package:animal_trade/services/ios_notification_service.dart';

// Bildirimi gönder
final iosNotificationService = IOSNotificationService();
final result = await iosNotificationService.sendIOSOnlyNotification();

print('Gönderilen: ${result['sentCount']} iOS kullanıcı');
print('Başarılı: ${result['success']}');
```

### Yöntem 3: Terminal'den (Flutter Script)

```bash
# Flutter path'inizi ekleyin (örnek):
export PATH="$PATH:/path/to/flutter/bin"

# Script'i çalıştırın:
dart run send_ios_notification.dart
```

## 📊 Bildirim Detayları

- **Başlık**: "CanlıPazar"
- **Mesaj**: "CanlıPazar ile pazar artık elinizde"
- **Hedef**: Sadece iOS kullanıcıları (`platform == "ios"`)
- **Android**: Bu bildirim Android kullanıcılarına gönderilmez

## ✅ Kontrol

Bildirimin gönderildiğini kontrol etmek için:

1. **Firebase Console** → **Functions** → **Logs**
2. Şu logları arayın:
   - `📱 [sendIOSOnlyNotification] iOS kullanıcılarına özel bildirim gönderiliyor...`
   - `✅ Toplam: X başarılı, Y başarısız`

## 🎯 Hızlı Başlangıç

**En kolay yol**: Firebase Console'dan test edin (Yöntem 1)

1. https://console.firebase.google.com/project/canlipazar-b3697/functions
2. `sendIOSOnlyNotification` → **Test** → `{}` → **Test**

---

**Not**: Cloud Function zaten deploy edildi, direkt kullanabilirsiniz!









