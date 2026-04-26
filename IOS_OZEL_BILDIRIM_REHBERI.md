# 📱 iOS Özel Bildirim Rehberi

## 🎯 Amaç

Sadece iOS kullanıcılarına özel bildirim göndermek: **"CanlıPazar ile pazar artık elinizde"**

## 🚀 Kullanım

### Yöntem 1: Flutter Script ile (Önerilen)

```bash
# Terminal'de proje root klasöründe:
dart run send_ios_notification.dart
```

### Yöntem 2: Flutter Uygulaması İçinden

```dart
import 'package:animal_trade/services/ios_notification_service.dart';

// Bildirim gönder
final iosNotificationService = IOSNotificationService();
final result = await iosNotificationService.sendIOSOnlyNotification();

print('Sonuç: ${result['success']}');
print('Gönderilen: ${result['sentCount']}');
```

### Yöntem 3: Firebase Console'dan (Callable Function)

1. **Firebase Console** → **Functions** → **sendIOSOnlyNotification**
2. **Test** butonuna tıklayın
3. Boş bir JSON gönderin: `{}`
4. **Test** butonuna tıklayın

## 📋 Özellikler

- ✅ **Sadece iOS kullanıcılarına gönderir** (Android'e gönderilmez)
- ✅ **Otomatik token validation** (geçersiz token'lar filtrelenir)
- ✅ **Batch gönderim** (500'lük gruplar halinde)
- ✅ **Hata yönetimi** (geçersiz token'lar otomatik temizlenir)
- ✅ **Detaylı loglama** (Firebase Console'da loglar görülebilir)

## 🔍 Kontrol

### Firebase Console'da Kontrol

1. **Firebase Console** → **Functions** → **Logs**
2. Şu logları arayın:
   - `📱 [sendIOSOnlyNotification] iOS kullanıcılarına özel bildirim gönderiliyor...`
   - `📱 X iOS kullanıcıya bildirim gönderilecek`
   - `✅ Toplam: X başarılı, Y başarısız`

### Firestore'da Kontrol

1. **Firebase Console** → **Firestore** → **users** koleksiyonu
2. `platform == "ios"` filtresi ile iOS kullanıcılarını görüntüleyin
3. Her kullanıcının `fcmToken` alanı olmalı

## ⚠️ Önemli Notlar

1. **Cloud Functions'ı deploy etmeden çalışmaz!**
   ```bash
   ./deploy_functions.sh
   ```

2. **Sadece iOS kullanıcılarına gönderilir**
   - `platform == "ios"` olan kullanıcılar
   - `fcmToken` alanı dolu olan kullanıcılar

3. **Bildirim içeriği:**
   - **Başlık**: "CanlıPazar"
   - **Mesaj**: "CanlıPazar ile pazar artık elinizde"

## 🐛 Sorun Giderme

### Sorun 1: "iOS kullanıcısı bulunamadı"

**Çözüm**:
1. Firestore'da `users` koleksiyonunu kontrol edin
2. `platform == "ios"` olan kullanıcılar var mı?
3. `fcmToken` alanı dolu mu?

### Sorun 2: "Geçerli iOS token bulunamadı"

**Çözüm**:
1. Token validation hatası olabilir
2. Firestore'da token'ların formatını kontrol edin
3. Token'lar 100-200 karakter arasında olmalı

### Sorun 3: "Cloud Functions hatası"

**Çözüm**:
1. Cloud Functions deploy edildi mi?
   ```bash
   firebase functions:list
   ```
2. `sendIOSOnlyNotification` fonksiyonu listede var mı?

## 📊 Örnek Sonuç

```
🚀 iOS özel bildirim gönderme script'i başlatılıyor...
✅ Firebase başlatıldı
📱 iOS kullanıcılarına bildirim gönderiliyor...
   Mesaj: "CanlıPazar ile pazar artık elinizde"

📊 Sonuç:
   - Başarılı: true
   - Mesaj: iOS bildirimleri başarıyla gönderildi
   - Gönderilen: 150
   - Başarısız: 2
   - Toplam Kullanıcı: 152

✅ Bildirimler başarıyla gönderildi!
```

---

**Not**: Bu bildirim sadece iOS kullanıcılarına gönderilir. Android kullanıcıları bu bildirimi almaz.









