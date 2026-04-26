# Android Mesaj Bildirimleri - Çözüm Rehberi

## 🎯 Sorun
Android'de mesaj geldiğinde bildirim gönderilmiyor.

## ✅ Yapılan Düzeltmeler

### 1. Bildirim Başlığı Güncellendi
- **Eski**: Gönderen adı
- **Yeni**: "CanlıPazar'dan bir mesajınız var"
- **İçerik**: "Gönderen Adı: Mesaj içeriği"

### 2. Android Bildirim İzinleri
- Android 13+ için `POST_NOTIFICATIONS` izni eklendi
- `permission_handler` ile runtime izin kontrolü
- İzin durumu detaylı loglanıyor

### 3. Detaylı Loglama
- Foreground mesajlar için detaylı log
- Background mesajlar için detaylı log
- Bildirim gönderme süreci adım adım loglanıyor

### 4. Bildirim Kanalı
- Android bildirim kanalı: `messages_channel`
- Yüksek öncelik (high priority)
- Ses ve titreşim aktif

## 🔍 Sorun Tespiti

### Bildirim Gelmiyorsa Kontrol Edin:

1. **Firebase Cloud Functions Deploy Edildi mi?**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions:onConversationMessageCreated
   ```

2. **FCM Token Kontrolü**
   - Firebase Console → Users → Kullanıcı → `fcmToken` alanı dolu mu?
   - Platform = "android" olarak kayıtlı mı?

3. **Bildirim İzinleri**
   - Android 13+: Ayarlar → Uygulamalar → CanlıPazar → Bildirimler → Açık mı?
   - Uygulama içinde izin verildi mi?

4. **Log Kontrolü**
   - Flutter log'larında `[MAIN]` veya `[BACKGROUND]` etiketli mesajlar var mı?
   - Firebase Functions log'larında bildirim gönderme mesajları var mı?

## 📋 Test Adımları

1. **Uygulamayı açın**
2. **Bildirim izni verin** (Android 13+ için)
3. **Başka bir kullanıcıdan mesaj gönderin**
4. **Log'ları kontrol edin:**
   - Flutter: `[MAIN]` veya `[BACKGROUND]` mesajları
   - Firebase Functions: Console → Functions → Logs

## 🔧 Firebase Cloud Functions Deploy

Bildirimlerin çalışması için Firebase Cloud Functions'ı deploy etmeniz gerekiyor:

```bash
cd functions
npm install
firebase deploy --only functions:onConversationMessageCreated
```

## 📱 Bildirim Formatı

- **Başlık**: "CanlıPazar'dan bir mesajınız var"
- **İçerik**: "Gönderen Adı: Mesaj içeriği..."
- **Kanal**: messages_channel
- **Öncelik**: High
- **Ses**: Default
- **Titreşim**: Aktif

## 🐛 Yaygın Sorunlar ve Çözümleri

### Sorun 1: Bildirim hiç gelmiyor
**Çözüm**: Firebase Cloud Functions deploy edilmemiş olabilir
```bash
firebase deploy --only functions
```

### Sorun 2: Foreground'da bildirim gelmiyor
**Çözüm**: Local notification gösterilmesi gerekiyor - kod zaten var
- Log'larda `[MAIN] Local notification gösteriliyor...` mesajını kontrol edin

### Sorun 3: Background'da bildirim gelmiyor
**Çözüm**: FCM otomatik gösterir, ancak:
- Bildirim izni verilmiş olmalı
- FCM token geçerli olmalı
- Platform = "android" olmalı

### Sorun 4: Token yok
**Çözüm**: FCM token kaydı kontrol edilmeli
- `FCMTokenManager().saveTokenToFirestore()` çağrılıyor mu?
- Token Firestore'da kayıtlı mı?

## ✅ Sonuç

Artık Android'de mesaj geldiğinde:
- ✅ Bildirim başlığı: "CanlıPazar'dan bir mesajınız var"
- ✅ Bildirim içeriği: "Gönderen Adı: Mesaj içeriği"
- ✅ Foreground'da local notification gösterilir
- ✅ Background'da FCM otomatik gösterir
- ✅ Detaylı loglama ile sorun tespiti kolaylaştı
















