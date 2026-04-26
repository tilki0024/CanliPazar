# 🔑 iOS APNs Key Firebase Console'a Yükleme Rehberi

## 📋 Gerekli Bilgiler

- **APNs Key Dosyası**: `/Users/mustafatilki/Desktop/AuthKey_94D623A8F4.p8`
- **Key ID**: `94D623A8F4`
- **Team ID**: `9W44LABURS` (project.pbxproj'den alındı)
- **Bundle ID**: `com.canlipazar.app`

## 🚀 Adım Adım Yükleme

### 1. Firebase Console'a Giriş
1. https://console.firebase.google.com adresine gidin
2. Projenizi seçin: **canlipazar-b3697**

### 2. Cloud Messaging Ayarlarına Git
1. Sol menüden **⚙️ Project Settings** (Proje Ayarları) tıklayın
2. Üst menüden **Cloud Messaging** sekmesine tıklayın
3. Sayfayı aşağı kaydırın, **Apple app configuration** bölümünü bulun

### 3. APNs Authentication Key Yükleme
1. **APNs Authentication Key** bölümünde **Upload** butonuna tıklayın
2. Şu bilgileri girin:
   - **Key ID**: `94D623A8F4`
   - **Team ID**: `9W44LABURS`
   - **Key dosyası**: `/Users/mustafatilki/Desktop/AuthKey_94D623A8F4.p8` dosyasını seçin
3. **Upload** butonuna tıklayın

### 4. Doğrulama
1. Yükleme başarılı olduğunda yeşil bir onay mesajı göreceksiniz
2. **Key ID** ve **Team ID** bilgilerinin doğru göründüğünü kontrol edin

## ✅ Kontrol Listesi

- [ ] APNs Authentication Key Firebase Console'a yüklendi
- [ ] Key ID doğru: `94D623A8F4`
- [ ] Team ID doğru: `9W44LABURS`
- [ ] Bundle ID doğru: `com.canlipazar.app`
- [ ] Apple Developer Portal'da Push Notifications capability aktif
- [ ] Xcode'da Push Notifications capability ekli

## 🧪 Test

Yeni ilan eklendiğinde iOS kullanıcılarına bildirim gitmeli:
1. Uygulamayı iOS cihazda çalıştırın
2. Yeni bir ilan ekleyin
3. iOS cihazlarda bildirim gelip gelmediğini kontrol edin

## 📝 Notlar

- APNs key dosyası (`.p8`) sadece bir kez indirilebilir, güvenli tutun
- Key ID ve Team ID bilgileri Firebase Console'da görünecek
- Yükleme sonrası bildirimler hemen çalışmaya başlamalı































