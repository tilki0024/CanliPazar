# 🧪 Deep Linking Test Rehberi

**Tarih:** 2024  
**Durum:** ✅ Universal Links + App Links test rehberi

---

## 📋 TEST SENARYOLARI

### Test 1: iOS Universal Link (Safari)

**Adımlar:**
1. iOS cihazda Safari'yi açın
2. Adres çubuğuna yazın: `https://canlipazar.com/ilan/test123`
3. Enter'a basın

**Beklenen Sonuç:**
- ✅ Uygulama açılmalı
- ✅ İlan detay sayfası açılmalı
- ❌ Tarayıcıda sayfa görünmemeli

**Sorun Giderme:**
- Eğer tarayıcıda sayfa görünüyorsa:
  - `apple-app-site-association` dosyası kontrol edilmeli
  - Associated Domains doğru ayarlanmış mı kontrol edilmeli
  - Apple Developer Portal'da domain doğrulanmış mı kontrol edilmeli

---

### Test 2: iOS Universal Link (WhatsApp)

**Adımlar:**
1. WhatsApp'ta birine link gönderin: `https://canlipazar.com/ilan/test123`
2. Link'e tıklayın

**Beklenen Sonuç:**
- ✅ Uygulama açılmalı
- ✅ İlan detay sayfası açılmalı
- ❌ Tarayıcıya düşmemeli

---

### Test 3: Android App Link (Chrome)

**Adımlar:**
1. Android cihazda Chrome'u açın
2. Adres çubuğuna yazın: `https://canlipazar.com/ilan/test123`
3. Enter'a basın

**Beklenen Sonuç:**
- ✅ Uygulama açılmalı
- ✅ İlan detay sayfası açılmalı
- ❌ Tarayıcıda sayfa görünmemeli

**Sorun Giderme:**
- Eğer tarayıcıda sayfa görünüyorsa:
  - `assetlinks.json` dosyası kontrol edilmeli
  - SHA256 fingerprint doğru mu kontrol edilmeli
  - Android doğrulama durumu kontrol edilmeli:
    ```bash
    adb shell pm get-app-links com.canlipazar
    ```

---

### Test 4: Android App Link (WhatsApp)

**Adımlar:**
1. WhatsApp'ta birine link gönderin: `https://canlipazar.com/ilan/test123`
2. Link'e tıklayın

**Beklenen Sonuç:**
- ✅ Uygulama açılmalı
- ✅ İlan detay sayfası açılmalı
- ❌ Tarayıcıya düşmemeli

---

### Test 5: Uygulama Yüklü Değil (iOS)

**Adımlar:**
1. iOS cihazda uygulamayı silin
2. Safari'de link'e tıklayın: `https://canlipazar.com/ilan/test123`

**Beklenen Sonuç:**
- ✅ Web sayfası açılmalı
- ✅ App Store butonu görünmeli
- ✅ App Store'a yönlendirmeli
- ✅ İndirdikten sonra uygulama açılınca aynı ilan açılmalı

---

### Test 6: Uygulama Yüklü Değil (Android)

**Adımlar:**
1. Android cihazda uygulamayı silin
2. Chrome'da link'e tıklayın: `https://canlipazar.com/ilan/test123`

**Beklenen Sonuç:**
- ✅ Web sayfası açılmalı
- ✅ Play Store butonu görünmeli
- ✅ Play Store'a yönlendirmeli
- ✅ İndirdikten sonra uygulama açılınca aynı ilan açılmalı

---

### Test 7: Open Graph (Facebook)

**Adımlar:**
1. Facebook'ta link paylaşın: `https://canlipazar.com/ilan/test123`
2. Önizlemeyi kontrol edin

**Beklenen Sonuç:**
- ✅ İlan fotoğrafı görünmeli
- ✅ İlan başlığı görünmeli
- ✅ İlan açıklaması görünmeli

**Test Aracı:**
- Facebook Sharing Debugger: https://developers.facebook.com/tools/debug/

---

### Test 8: Open Graph (Twitter)

**Adımlar:**
1. Twitter'da link paylaşın: `https://canlipazar.com/ilan/test123`
2. Önizlemeyi kontrol edin

**Beklenen Sonuç:**
- ✅ İlan fotoğrafı görünmeli
- ✅ İlan başlığı görünmeli
- ✅ İlan açıklaması görünmeli

**Test Aracı:**
- Twitter Card Validator: https://cards-dev.twitter.com/validator

---

### Test 9: Open Graph (WhatsApp)

**Adımlar:**
1. WhatsApp'ta link paylaşın: `https://canlipazar.com/ilan/test123`
2. Önizlemeyi kontrol edin

**Beklenen Sonuç:**
- ✅ İlan fotoğrafı görünmeli
- ✅ İlan başlığı görünmeli
- ✅ İlan açıklaması görünmeli

---

### Test 10: SMS Link

**Adımlar:**
1. SMS'te link gönderin: `https://canlipazar.com/ilan/test123`
2. Link'e tıklayın

**Beklenen Sonuç:**
- ✅ iOS: Uygulama açılmalı
- ✅ Android: Uygulama açılmalı
- ❌ Tarayıcıya düşmemeli

---

## 🔍 DOĞRULAMA ARAÇLARI

### iOS Universal Links
1. **Apple App Site Association Validator:**
   - https://search.developer.apple.com/appsearch-validation-tool/
   - URL: `https://canlipazar.com/ilan/test123`

2. **Manuel Test:**
   ```bash
   # iOS cihazda Notes uygulamasında link yazın
   # Link'e tıklayın
   # Uygulama açılmalı
   ```

### Android App Links
1. **Android App Links Test:**
   ```bash
   # Android cihazda
   adb shell pm get-app-links com.canlipazar
   
   # Beklenen çıktı:
   # com.canlipazar:
   #   Domain verification state:
   #     canlipazar.com: verified
   ```

2. **Manuel Test:**
   ```bash
   # Android cihazda Chrome'da link açın
   # Uygulama açılmalı
   ```

### Open Graph
1. **Facebook Sharing Debugger:**
   - https://developers.facebook.com/tools/debug/
   - URL: `https://canlipazar.com/ilan/test123`

2. **Twitter Card Validator:**
   - https://cards-dev.twitter.com/validator
   - URL: `https://canlipazar.com/ilan/test123`

3. **LinkedIn Post Inspector:**
   - https://www.linkedin.com/post-inspector/
   - URL: `https://canlipazar.com/ilan/test123`

---

## 🚨 SORUN GİDERME

### Sorun 1: iOS Universal Link Çalışmıyor

**Kontrol Listesi:**
- [ ] `apple-app-site-association` dosyası HTTPS üzerinden erişilebilir mi?
- [ ] Content-Type: `application/json` mi?
- [ ] Redirect var mı? (OLMAMALI)
- [ ] Associated Domains doğru ayarlanmış mı?
- [ ] Apple Developer Portal'da domain doğrulanmış mı?

**Çözüm:**
```bash
# Dosyayı kontrol et
curl -I https://canlipazar.com/.well-known/apple-app-site-association

# Beklenen header:
# Content-Type: application/json
# HTTP/1.1 200 OK (redirect OLMAMALI)
```

---

### Sorun 2: Android App Link Çalışmıyor

**Kontrol Listesi:**
- [ ] `assetlinks.json` dosyası HTTPS üzerinden erişilebilir mi?
- [ ] SHA256 fingerprint doğru mu?
- [ ] Package name doğru mu? (`com.canlipazar`)
- [ ] `autoVerify="true"` ayarlı mı?

**Çözüm:**
```bash
# SHA256 fingerprint al
keytool -list -v -keystore android/app/key.jks -alias key | grep SHA256

# assetlinks.json dosyasını kontrol et
curl https://canlipazar.com/.well-known/assetlinks.json

# Android doğrulama durumunu kontrol et
adb shell pm get-app-links com.canlipazar
```

---

### Sorun 3: Open Graph Önizleme Görünmüyor

**Kontrol Listesi:**
- [ ] Meta tag'ler doğru mu?
- [ ] Image URL erişilebilir mi?
- [ ] Image boyutu yeterli mi? (1200x630 önerilir)

**Çözüm:**
```bash
# Facebook Sharing Debugger'da test et
# URL'yi girin ve "Scrape Again" butonuna tıklayın
```

---

## ✅ BAŞARILI TEST KRİTERLERİ

### iOS
- [x] Safari'de link → Uygulama açılıyor
- [x] WhatsApp'ta link → Uygulama açılıyor
- [x] SMS'te link → Uygulama açılıyor
- [x] Uygulama yok → App Store'a yönlendiriyor

### Android
- [x] Chrome'da link → Uygulama açılıyor
- [x] WhatsApp'ta link → Uygulama açılıyor
- [x] SMS'te link → Uygulama açılıyor
- [x] Uygulama yok → Play Store'a yönlendiriyor

### Open Graph
- [x] Facebook'ta önizleme görünüyor
- [x] Twitter'da önizleme görünüyor
- [x] WhatsApp'ta önizleme görünüyor

---

## 📝 NOTLAR

- **Universal Links:** iOS 9+ gerektirir
- **App Links:** Android 6.0+ gerektirir
- **Fallback:** Eski iOS/Android versiyonları için custom scheme kullanılır
- **Test:** Her platformda mutlaka test edilmeli



















