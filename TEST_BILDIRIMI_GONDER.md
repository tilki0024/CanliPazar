# Test Bildirimi Gönderme

## ✅ Test Bildirimi Function Hazır

Test bildirimi Cloud Function'ı başarıyla deploy edildi:
- **Function URL**: `https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotification`

## 📱 Test Bildirimi Gönderme Yöntemleri

### Yöntem 1: Otomatik (En Son Token'a Gönder)

Function'ı userId parametresi olmadan çağırırsanız, Firestore'da `fcmToken` alanı olan ilk kullanıcıya gönderir:

```bash
curl -X GET "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotification"
```

### Yöntem 2: Belirli Kullanıcıya Gönder

Belirli bir kullanıcıya göndermek için `userId` parametresi ekleyin:

```bash
curl -X GET "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotification?userId=KULLANICI_ID_BURAYA"
```

## 🔍 Token Kontrolü

Test bildirimi göndermeden önce:

1. **Uygulamayı açın** (Xcode'dan çalıştırın)
2. **Bildirim izni verin** (ilk açılışta istenecek)
3. **Xcode Console'da kontrol edin:**
   ```
   ✅ iOS AppDelegate: FCM token Firestore'a kaydedildi
   ✅ FCM Token Service: Token Firestore'a kaydedildi
   ```

4. **Firestore'da kontrol edin:**
   - Firebase Console > Firestore Database
   - `users/{userId}` dokümanında `fcmToken` alanının olduğunu kontrol edin

## 🧪 Test Bildirimi İçeriği

Gönderilecek bildirim:
- **Başlık**: 🧪 TEST BİLDİRİMİ
- **Metin**: TEST BİLDİRİMİ GELDİ Mİ?
- **Badge**: 1
- **Ses**: Varsayılan ses

## ⚠️ Sorun Giderme

### "FCM token bulunamadı" Hatası

Bu hata, Firestore'da `fcmToken` alanı olan kullanıcı bulunamadığında oluşur.

**Çözüm:**
1. Uygulamayı açın ve bildirim izni verin
2. Birkaç saniye bekleyin (token kaydı için)
3. Firebase Console > Firestore'da `users` koleksiyonunda `fcmToken` alanını kontrol edin
4. Token yoksa, uygulamayı kapatıp tekrar açın

### Belirli Kullanıcıya Gönderme

Kendi kullanıcı ID'nizi bulmak için:
1. Firebase Console > Authentication > Users
2. Veya uygulama içinde kullanıcı profil sayfasında ID'yi kontrol edin
3. Function'ı `?userId=KULLANICI_ID` parametresi ile çağırın

## 📋 Test Adımları

1. ✅ Uygulamayı Xcode'dan çalıştırın
2. ✅ Bildirim izni verin
3. ✅ Xcode Console'da token kaydını kontrol edin
4. ✅ Firestore'da token'ın kaydedildiğini doğrulayın
5. ✅ Test bildirimi function'ını çağırın
6. ✅ Telefonda bildirimi kontrol edin

## 🎯 Başarı Kriterleri

- ✅ Bildirim telefonunuzda görünmeli
- ✅ Başlık: "🧪 TEST BİLDİRİMİ"
- ✅ Metin: "TEST BİLDİRİMİ GELDİ Mİ?"
- ✅ Bildirime tıklayınca uygulama açılmalı








