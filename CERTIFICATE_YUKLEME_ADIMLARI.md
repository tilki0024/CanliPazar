# Play Console'a Certificate Yükleme - Adım Adım Rehber

## 📱 Adım 1: Play Console'a Giriş

1. Tarayıcınızda şu adrese gidin: **https://play.google.com/console**
2. Google hesabınızla giriş yapın
3. **CanliPazar** uygulamanızı seçin

## 🔐 Adım 2: App Signing Bölümüne Gitme

1. Sol menüden **"Setup"** (Kurulum) seçeneğine tıklayın
2. Açılan alt menüden **"App signing"** (Uygulama İmzalama) seçeneğine tıklayın

## 📤 Adım 3: Upload Key Certificate Yükleme

### Senaryo A: İlk Kez Certificate Yüklüyorsanız veya Reset Yapıyorsanız

1. **"Upload key certificate"** bölümünü bulun
2. **"Reset upload key"** veya **"Request upload key reset"** butonuna tıklayın
3. Açılan pencerede:
   - **"Upload a new certificate"** seçeneğini seçin
   - **"Choose file"** veya **"Browse"** butonuna tıklayın
   - Masaüstündeki **`upload_certificate_final.pem`** dosyasını seçin
   - **"Upload"** veya **"Save"** butonuna tıklayın

### Senaryo B: Mevcut Certificate'i Değiştiriyorsanız

1. **"Upload key certificate"** bölümünde **"Edit"** veya **"Change"** butonuna tıklayın
2. **"Upload new certificate"** seçeneğini seçin
3. Masaüstündeki **`upload_certificate_final.pem`** dosyasını seçin
4. **"Save"** butonuna tıklayın

## ✅ Adım 4: Doğrulama

1. Certificate yüklendikten sonra, Play Console'da SHA-1'in şu olduğunu görmelisiniz:
   ```
   0F:C7:FC:BD:99:B9:95:F2:14:7F:E6:AE:A4:A9:BE:D5:AA:1D:92:5D
   ```
2. Bu SHA-1'i görüyorsanız, certificate başarıyla yüklenmiştir ✅

## 📦 Adım 5: AAB Dosyasını Yükleme

1. Sol menüden **"Production"** (Üretim) veya **"Testing"** (Test) seçeneğine gidin
2. **"Create new release"** (Yeni sürüm oluştur) butonuna tıklayın
3. **"Upload"** veya **"Browse files"** butonuna tıklayın
4. Şu dosyayı seçin:
   ```
   /Users/mustafatilki/Desktop/CanliPazar-main/build/app/outputs/bundle/release/app-release.aab
   ```
5. Dosya yüklendikten sonra, sürüm notlarını ekleyin
6. **"Review release"** (Sürümü gözden geçir) butonuna tıklayın
7. **"Start rollout to Production"** (Üretime başlat) butonuna tıklayın

## 🖼️ Görsel Rehber

### App Signing Sayfası Görünümü:
```
┌─────────────────────────────────────┐
│  Setup > App signing                │
├─────────────────────────────────────┤
│                                     │
│  Upload key certificate             │
│  ┌─────────────────────────────┐   │
│  │ [Reset upload key] [Edit]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  App signing key                    │
│  (Google Play tarafından yönetilir) │
│                                     │
└─────────────────────────────────────┘
```

## ⚠️ Önemli Notlar

- Certificate yükleme işlemi birkaç dakika sürebilir
- Certificate yüklendikten sonra, AAB dosyasını yükleyebilirsiniz
- Eğer hata alırsanız, certificate dosyasının doğru formatta olduğundan emin olun (PEM formatı)

## 🆘 Sorun Giderme

### "Certificate format is invalid" hatası alırsanız:
- Certificate dosyasının `.pem` uzantılı olduğundan emin olun
- Dosyayı bir metin editöründe açın ve `-----BEGIN CERTIFICATE-----` ile başladığından emin olun

### "SHA-1 mismatch" hatası alırsanız:
- Keystore'un doğru olduğundan emin olun
- Certificate'in bu keystore'dan export edildiğinden emin olun

### "Upload key already exists" hatası alırsanız:
- Önce "Reset upload key" yapmanız gerekebilir
- Veya mevcut certificate'i değiştirmeniz gerekebilir

## 📞 Yardım

Eğer sorun yaşarsanız:
1. Play Console'daki hata mesajını not edin
2. Certificate dosyasının doğru yüklendiğinden emin olun
3. Keystore bilgilerini kontrol edin

## 📋 Dosya Konumları

- **Certificate:** `~/Desktop/upload_certificate_final.pem`
- **Keystore:** `~/Desktop/upload-keystore-final.jks`
- **AAB:** `~/Desktop/CanliPazar-main/build/app/outputs/bundle/release/app-release.aab`
















