# 📱 Bildirim Gönderme Talimatları

## 🎯 Hızlı Yöntem: Firebase Console'dan Manuel Bildirim Gönderme

### Adım 1: Firebase Console'a Git
1. https://console.firebase.google.com adresine git
2. **canlipazar-b3697** projesini seç

### Adım 2: Cloud Messaging'e Git
1. Sol menüden **"Engage"** > **"Cloud Messaging"** seç
2. **"Send your first message"** veya **"New notification"** butonuna tıkla

### Adım 3: Bildirim Bilgilerini Gir
- **Notification title:** `🎉 iOS Bildirimleri Düzeltildi!`
- **Notification text:** `iOS bildirim sistemi başarıyla çalışıyor. Test bildirimi alıyorsunuz!`
- **Target:** `All users` veya `User segment` (iOS kullanıcıları için)

### Adım 4: Gönder
- **"Review"** butonuna tıkla
- **"Publish"** butonuna tıkla

---

## 🔧 Alternatif: Cloud Functions Deploy Et ve Script Kullan

### Adım 1: Cloud Functions'ı Deploy Et
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main/functions
npm run deploy
```

### Adım 2: Bildirim Gönder
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main
node send_broadcast_notification.js "🎉 iOS Bildirimleri Düzeltildi!" "iOS bildirim sistemi başarıyla çalışıyor. Test bildirimi alıyorsunuz!"
```

---

## 📊 Bildirim İstatistikleri

Bildirim gönderildikten sonra Firebase Console'da şunları görebilirsiniz:
- Gönderilen bildirim sayısı
- Açılan bildirim sayısı
- Platform dağılımı (iOS/Android)
- Hata sayısı

---

## ✅ Kontrol Listesi

- [ ] Firebase Console'a giriş yapıldı
- [ ] Doğru proje seçildi (canlipazar-b3697)
- [ ] Bildirim başlığı ve metni girildi
- [ ] Hedef kitle seçildi (Tüm kullanıcılar veya iOS kullanıcıları)
- [ ] Bildirim gönderildi
- [ ] Bildirim istatistikleri kontrol edildi

---

**Not:** Cloud Functions deploy edilmemişse, Firebase Console'dan manuel bildirim gönderme en hızlı yöntemdir.

























