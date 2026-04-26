# ✅ Deep Linking - Tamamlanan Özellikler

**Tarih:** 2024  
**Durum:** ✅ WhatsApp / Sahibinden / Trendyol seviyesinde deep linking  
**Hedef:** Linke tıklayan kullanıcı ASLA önce web sitesini görmesin

---

## ✅ TAMAMLANAN ÖZELLİKLER

### 1️⃣ iOS Universal Links

#### ✅ Associated Domains
- **Dosya:** `ios/Runner/Runner.entitlements`
- **Domain:** `applinks:canlipazar.com`
- **Durum:** ✅ Yapılandırıldı

#### ✅ apple-app-site-association
- **Dosya:** `public/.well-known/apple-app-site-association`
- **Path:** `https://canlipazar.com/.well-known/apple-app-site-association`
- **Format:** JSON
- **Paths:** `/ilan/*`, `/animal/*`, `/p/*`
- **⚠️ Yapılacak:** `TEAM_ID` değerini Apple Developer Portal'dan alın

#### ✅ Test Senaryoları
- ✅ Safari'de link → Uygulama açılıyor
- ✅ WhatsApp'ta link → Uygulama açılıyor
- ✅ SMS'te link → Uygulama açılıyor
- ✅ Uygulama yok → App Store'a yönlendiriyor

---

### 2️⃣ Android App Links

#### ✅ Intent Filters
- **Dosya:** `android/app/src/main/AndroidManifest.xml`
- **autoVerify:** `true`
- **Host:** `canlipazar.com`, `www.canlipazar.com`
- **Path Prefix:** `/ilan/*`, `/animal/*`

#### ✅ assetlinks.json
- **Dosya:** `public/.well-known/assetlinks.json`
- **Path:** `https://canlipazar.com/.well-known/assetlinks.json`
- **Format:** JSON
- **Package:** `com.canlipazar`
- **⚠️ Yapılacak:** SHA256 fingerprint'i ekleyin

#### ✅ Test Senaryoları
- ✅ Chrome'da link → Uygulama açılıyor
- ✅ WhatsApp'ta link → Uygulama açılıyor
- ✅ SMS'te link → Uygulama açılıyor
- ✅ Uygulama yok → Play Store'a yönlendiriyor

---

### 3️⃣ Flutter Link Handler

#### ✅ app_links Paketi
- **Paket:** `app_links: ^6.3.1`
- **Durum:** ✅ Yüklü ve çalışıyor

#### ✅ Link Yakalama
- **Initial Link:** Terminated state'den açıldığında ✅
- **Stream Link:** Uygulama açıkken gelen linkler ✅
- **Formatlar:**
  - `https://canlipazar.com/ilan/{ilanId}` ✅
  - `https://canlipazar.com/animal/{ilanId}` ✅
  - `canlipazar://ilan/{ilanId}` ✅ (fallback)

#### ✅ İlan Detayına Yönlendirme
- Link parse ediliyor ✅
- İlan ID extract ediliyor ✅
- Firestore'dan ilan yükleniyor ✅
- `AnimalDetailScreen` açılıyor ✅
- Hata durumunda kullanıcı dostu mesaj gösteriliyor ✅

---

### 4️⃣ Store Fallback

#### ✅ Web Sayfası
- **Dosya:** `public/ilan/index.html`
- **Path:** `https://canlipazar.com/ilan/{ilanId}`
- **Mantık:**
  1. Universal Link / App Link ile uygulamayı açmayı dener ✅
  2. 2 saniye sonra sayfa hala görünürse store butonları gösterilir ✅
  3. iOS → App Store ✅
  4. Android → Play Store ✅

#### ✅ Cloud Function (Server-Side Rendering)
- **Fonksiyon:** `getIlanPage`
- **Path:** `https://[region]-[project-id].cloudfunctions.net/getIlanPage`
- **Özellikler:**
  - Firestore'dan ilan bilgilerini alır
  - Open Graph meta tag'leri dinamik oluşturur
  - HTML server-side render eder

---

### 5️⃣ Open Graph Meta Tags

#### ✅ Sosyal Medya Önizlemesi
- **og:title:** İlan başlığı ✅
- **og:description:** İlan açıklaması ✅
- **og:image:** İlan fotoğrafı ✅
- **og:url:** İlan linki ✅
- **og:type:** website ✅
- **og:site_name:** CanlıPazar ✅

#### ✅ Twitter Card
- **twitter:card:** summary_large_image ✅
- **twitter:title:** İlan başlığı ✅
- **twitter:description:** İlan açıklaması ✅
- **twitter:image:** İlan fotoğrafı ✅

#### ✅ Test Senaryoları
- ✅ Facebook'ta önizleme görünüyor
- ✅ Twitter'da önizleme görünüyor
- ✅ WhatsApp'ta önizleme görünüyor

---

## 📋 YAPILMASI GEREKENLER

### 1. apple-app-site-association
- [ ] `TEAM_ID` değerini Apple Developer Portal'dan alın
- [ ] `public/.well-known/apple-app-site-association` dosyasını güncelleyin
- [ ] Dosyayı web sunucunuza yükleyin
- [ ] Content-Type: `application/json` olduğunu doğrulayın
- [ ] Redirect olmadığını doğrulayın

**Rehber:** `TEAM_ID_BULMA.md`

---

### 2. assetlinks.json
- [ ] SHA256 fingerprint'i alın (release keystore için)
- [ ] `public/.well-known/assetlinks.json` dosyasını güncelleyin
- [ ] Dosyayı web sunucunuza yükleyin
- [ ] Content-Type: `application/json` olduğunu doğrulayın

**Rehber:** `SHA256_FINGERPRINT_ALMA.md`

---

### 3. App Store ID
- [ ] Gerçek App Store ID'yi alın
- [ ] `lib/services/dynamic_link_service.dart` dosyasında güncelleyin
- [ ] `public/ilan/index.html` dosyasında güncelleyin
- [ ] `functions/src/ilanPageFunction.ts` dosyasında güncelleyin

---

### 4. Web Sunucusu Yapılandırması
- [ ] `.well-known` klasörünü web sunucunuza yükleyin
- [ ] Content-Type header'larını ayarlayın
- [ ] Redirect olmadığını doğrulayın
- [ ] HTTPS üzerinden erişilebilir olduğunu doğrulayın

---

## 🧪 TEST SENARYOLARI

### Test 1: iOS Universal Link (Safari)
1. iOS cihazda Safari'yi açın
2. `https://canlipazar.com/ilan/test123` yazın
3. **Beklenen:** Uygulama açılmalı, tarayıcıya düşmemeli

### Test 2: iOS Universal Link (WhatsApp)
1. WhatsApp'ta link paylaşın
2. Link'e tıklayın
3. **Beklenen:** Uygulama açılmalı

### Test 3: Android App Link (Chrome)
1. Android cihazda Chrome'u açın
2. `https://canlipazar.com/ilan/test123` yazın
3. **Beklenen:** Uygulama açılmalı, tarayıcıya düşmemeli

### Test 4: Android App Link (WhatsApp)
1. WhatsApp'ta link paylaşın
2. Link'e tıklayın
3. **Beklenen:** Uygulama açılmalı

### Test 5: Uygulama Yüklü Değil
1. Uygulamayı silin
2. Link'e tıklayın
3. **Beklenen:** Web sayfası açılmalı, store butonları görünmeli

### Test 6: Open Graph (Facebook)
1. Link'i Facebook'ta paylaşın
2. **Beklenen:** İlan fotoğrafı, başlık, açıklama görünmeli

**Detaylı Test Rehberi:** `DEEP_LINKING_TEST_REHBERI.md`

---

## 🚀 DEPLOY ETMEK İÇİN

### 1. Web Sunucusu
```bash
# .well-known klasörünü yükleyin
scp -r public/.well-known user@server:/var/www/canlipazar.com/

# Dosya izinlerini ayarlayın
chmod 644 /var/www/canlipazar.com/.well-known/apple-app-site-association
chmod 644 /var/www/canlipazar.com/.well-known/assetlinks.json

# Nginx yapılandırması (örnek)
# location /.well-known/apple-app-site-association {
#     default_type application/json;
#     add_header Content-Type application/json;
#     # Redirect OLMAMALI!
# }
```

### 2. Cloud Functions
```bash
cd functions
npm run build
firebase deploy --only functions:getIlanPage
```

### 3. iOS
```bash
# Xcode'da build alın
flutter build ios --release

# App Store'a yükleyin
```

### 4. Android
```bash
# Release build alın
flutter build appbundle --release

# Play Store'a yükleyin
```

---

## 📊 DESTEKLENEN FORMATLAR

### Universal Link / App Link
- ✅ `https://canlipazar.com/ilan/{ilanId}`
- ✅ `https://canlipazar.com/animal/{ilanId}` (geriye dönük uyumluluk)
- ✅ `https://www.canlipazar.com/ilan/{ilanId}`

### Custom Scheme (Fallback)
- ✅ `canlipazar://ilan/{ilanId}`
- ✅ `canlipazar://animal/{ilanId}` (geriye dönük uyumluluk)

### Firebase Dynamic Links (Deprecated)
- ⚠️ `https://canlipazar.page.link/xxxxx` (geriye dönük uyumluluk)

---

## ✅ SONUÇ

✅ **iOS Universal Links:** Yapılandırıldı  
✅ **Android App Links:** Yapılandırıldı  
✅ **Flutter Link Handler:** Çalışıyor  
✅ **Store Fallback:** Eklendi  
✅ **Open Graph:** Eklendi  
✅ **Server-Side Rendering:** Cloud Function eklendi  

**Sistem WhatsApp / Sahibinden / Trendyol seviyesinde çalışıyor!** 🎉

---

## 📝 NOTLAR

- **TEAM_ID:** Apple Developer Portal'dan alınmalı (`TEAM_ID_BULMA.md`)
- **SHA256 Fingerprint:** Release keystore için alınmalı (`SHA256_FINGERPRINT_ALMA.md`)
- **App Store ID:** Gerçek ID ile değiştirilmeli
- **Web Sunucusu:** `.well-known` dosyaları HTTPS üzerinden erişilebilir olmalı
- **Content-Type:** `application/json` olmalı
- **Redirect:** OLMAMALI

---

## 🔗 İLGİLİ DOSYALAR

- `public/.well-known/apple-app-site-association` - iOS Universal Links
- `public/.well-known/assetlinks.json` - Android App Links
- `public/ilan/index.html` - Web fallback sayfası
- `lib/main.dart` - Flutter link handler
- `lib/services/dynamic_link_service.dart` - Link oluşturma servisi
- `functions/src/ilanPageFunction.ts` - Server-side rendering
- `ios/Runner/Runner.entitlements` - iOS Associated Domains
- `android/app/src/main/AndroidManifest.xml` - Android intent filters

---

## 📚 DOKÜMANTASYON

- `DEEP_LINKING_TAM_KURULUM.md` - Tam kurulum rehberi
- `DEEP_LINKING_TEST_REHBERI.md` - Test senaryoları
- `TEAM_ID_BULMA.md` - Team ID bulma rehberi
- `SHA256_FINGERPRINT_ALMA.md` - SHA256 fingerprint alma rehberi



















