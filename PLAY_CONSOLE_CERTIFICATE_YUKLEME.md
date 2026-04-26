# Play Console'a Certificate Yükleme - Adım Adım Rehber

## 📱 Adım 1: Play Console'a Giriş

1. Tarayıcınızda şu adrese gidin: **https://play.google.com/console**
2. Google hesabınızla giriş yapın
3. Uygulamanızı (CanliPazar) seçin

## 🔐 Adım 2: App Signing Bölümüne Gitme

1. Sol menüden **"Setup"** (Kurulum) seçeneğine tıklayın
2. Açılan menüden **"App signing"** (Uygulama İmzalama) seçeneğine tıklayın

## 📤 Adım 3: Upload Key Certificate Yükleme

### Seçenek A: Reset Upload Key (Önerilen - İlk kez yüklüyorsanız)

1. **"Upload key certificate"** bölümünü bulun
2. **"Reset upload key"** veya **"Request upload key reset"** butonuna tıklayın
3. Açılan pencerede:
   - **"Upload a new certificate"** seçeneğini seçin
   - **"Choose file"** veya **"Browse"** butonuna tıklayın
   - Masaüstündeki **`upload_certificate_reset.pem`** dosyasını seçin
   - **"Upload"** veya **"Save"** butonuna tıklayın

### Seçenek B: Mevcut Certificate'i Değiştirme

1. **"Upload key certificate"** bölümünde **"Edit"** veya **"Change"** butonuna tıklayın
2. **"Upload new certificate"** seçeneğini seçin
3. Masaüstündeki **`upload_certificate_reset.pem`** dosyasını seçin
4. **"Save"** butonuna tıklayın

## ✅ Adım 4: Doğrulama

1. Certificate yüklendikten sonra, Play Console'da SHA-1'in şu olduğunu görmelisiniz:
   ```
   37:D4:1F:21:E0:3A:E4:FF:DD:04:E2:1D:EA:73:F4:D8:3D:8A:23:7C
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

## 📞 Yardım

Eğer sorun yaşarsanız:
1. Play Console'daki hata mesajını not edin
2. Certificate dosyasının doğru yüklendiğinden emin olun
3. Keystore bilgilerini kontrol edin
















