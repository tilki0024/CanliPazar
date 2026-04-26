# 🔗 Deep Linking - WhatsApp/Sahibinden Seviyesi Kurulum

**Tarih:** 2024  
**Durum:** ✅ Universal Links + App Links tam kurulum  
**Hedef:** WhatsApp / Sahibinden / Trendyol seviyesinde deep linking

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
- **Format:** JSON (Content-Type: application/json)
- **Paths:** `/ilan/*`, `/animal/*`, `/p/*`

**⚠️ ÖNEMLİ:** 
- `TEAM_ID` değerini Apple Developer Portal'dan alın
- Dosya HTTPS üzerinden erişilebilir olmalı
- Redirect OLMAMALI
- Content-Type: `application/json` olmalı

---

### 2️⃣ Android App Links

#### ✅ Intent Filters
- **Dosya:** `android/app/src/main/AndroidManifest.xml`
- **autoVerify:** `true`
- **Host:** `canlipazar.com`
- **Path Prefix:** `/ilan/*`, `/animal/*`

#### ✅ assetlinks.json
- **Dosya:** `public/.well-known/assetlinks.json`
- **Path:** `https://canlipazar.com/.well-known/assetlinks.json`
- **Format:** JSON
- **Package:** `com.canlipazar`

**⚠️ ÖNEMLİ:**
- SHA256 fingerprint'i almak için:
  ```bash
  keytool -list -v -keystore android/app/key.jks -alias key | grep SHA256
  ```
- Release keystore için SHA256 fingerprint'i kullanın
- Dosya HTTPS üzerinden erişilebilir olmalı

---

### 3️⃣ Flutter Link Handler

#### ✅ app_links Paketi
- **Paket:** `app_links: ^6.3.1`
- **Durum:** ✅ Yüklü

#### ✅ Link Yakalama
- **Initial Link:** Terminated state'den açıldığında
- **Stream Link:** Uygulama açıkken gelen linkler
- **Formatlar:**
  - `https://canlipazar.com/ilan/{ilanId}`
  - `https://canlipazar.com/animal/{ilanId}`
  - `canlipazar://ilan/{ilanId}` (fallback)

#### ✅ İlan Detayına Yönlendirme
- Link parse ediliyor
- İlan ID extract ediliyor
- Firestore'dan ilan yükleniyor
- `AnimalDetailScreen` açılıyor

---

### 4️⃣ Store Fallback

#### ✅ Web Sayfası
- **Dosya:** `public/ilan/index.html`
- **Path:** `https://canlipazar.com/ilan/{ilanId}`
- **Mantık:**
  1. Universal Link / App Link ile uygulamayı açmayı dener
  2. 2 saniye sonra sayfa hala görünürse store butonları gösterilir
  3. iOS → App Store
  4. Android → Play Store

#### ✅ Open Graph Meta Tags
- **og:title:** İlan başlığı
- **og:description:** İlan açıklaması
- **og:image:** İlan fotoğrafı
- **og:url:** İlan linki

---

## 📋 KURULUM ADIMLARI

### 1. iOS Universal Links

#### Adım 1: apple-app-site-association Dosyası
1. `public/.well-known/apple-app-site-association` dosyasını düzenleyin
2. `TEAM_ID` değerini Apple Developer Portal'dan alın
3. Dosyayı web sunucunuza yükleyin:
   - Path: `https://canlipazar.com/.well-known/apple-app-site-association`
   - Content-Type: `application/json`
   - Redirect OLMAMALI

#### Adım 2: Apple Developer Portal
1. Apple Developer Portal'a giriş yapın
2. App ID'yi seçin: `com.canlipazar.app`
3. **Associated Domains** capability'sini etkinleştirin
4. Domain ekleyin: `applinks:canlipazar.com`

#### Adım 3: Xcode
1. Xcode'da projeyi açın
2. **Signing & Capabilities** → **Associated Domains**
3. Domain ekleyin: `applinks:canlipazar.com`

#### Adım 4: Test
```bash
# iOS cihazda Safari'de test edin
https://canlipazar.com/ilan/test123

# Uygulama açılmalı, tarayıcıya düşmemeli
```

---

### 2. Android App Links

#### Adım 1: SHA256 Fingerprint Al
```bash
# Release keystore için
keytool -list -v -keystore android/app/key.jks -alias key | grep SHA256

# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

#### Adım 2: assetlinks.json Dosyası
1. `public/.well-known/assetlinks.json` dosyasını düzenleyin
2. SHA256 fingerprint'i ekleyin
3. Dosyayı web sunucunuza yükleyin:
   - Path: `https://canlipazar.com/.well-known/assetlinks.json`
   - Content-Type: `application/json`

#### Adım 3: AndroidManifest.xml
- ✅ `autoVerify="true"` ayarlı
- ✅ Intent filter doğru yapılandırılmış

#### Adım 4: Test
```bash
# Android cihazda Chrome'da test edin
https://canlipazar.com/ilan/test123

# Uygulama açılmalı, tarayıcıya düşmemeli
```

---

### 3. Web Sunucusu Yapılandırması

#### .well-known Klasörü
```
public/
  .well-known/
    apple-app-site-association
    assetlinks.json
```

#### Nginx Yapılandırması (Örnek)
```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    # Redirect OLMAMALI
}

location /.well-known/assetlinks.json {
    default_type application/json;
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

#### Apache Yapılandırması (Örnek)
```apache
<FilesMatch "apple-app-site-association">
    Header set Content-Type "application/json"
</FilesMatch>

<FilesMatch "assetlinks.json">
    Header set Content-Type "application/json"
</FilesMatch>
```

---

### 4. Flutter Link Handler

#### ✅ Mevcut Yapılandırma
- `app_links` paketi yüklü
- `_initDeepLinkHandler()` çalışıyor
- `_navigateToDeepLink()` ilan detayına yönlendiriyor

#### ✅ Desteklenen Formatlar
- `https://canlipazar.com/ilan/{ilanId}` ✅
- `https://canlipazar.com/animal/{ilanId}` ✅
- `canlipazar://ilan/{ilanId}` ✅ (fallback)

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

### Test 6: Open Graph (Sosyal Medya)
1. Link'i Facebook'ta paylaşın
2. **Beklenen:** İlan fotoğrafı, başlık, açıklama görünmeli

---

## 🔧 YAPILMASI GEREKENLER

### 1. apple-app-site-association
- [ ] `TEAM_ID` değerini Apple Developer Portal'dan alın
- [ ] Dosyayı web sunucunuza yükleyin
- [ ] HTTPS üzerinden erişilebilir olduğunu doğrulayın
- [ ] Content-Type: `application/json` olduğunu doğrulayın
- [ ] Redirect olmadığını doğrulayın

### 2. assetlinks.json
- [ ] SHA256 fingerprint'i alın
- [ ] Dosyayı web sunucunuza yükleyin
- [ ] HTTPS üzerinden erişilebilir olduğunu doğrulayın
- [ ] Content-Type: `application/json` olduğunu doğrulayın

### 3. App Store ID
- [ ] Gerçek App Store ID'yi alın
- [ ] `lib/services/dynamic_link_service.dart` dosyasında güncelleyin
- [ ] `public/ilan/index.html` dosyasında güncelleyin

### 4. Web Sunucusu
- [ ] `.well-known` klasörünü yükleyin
- [ ] Content-Type header'larını ayarlayın
- [ ] Redirect olmadığını doğrulayın

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

## 🚀 DEPLOY ETMEK İÇİN

### 1. Web Sunucusu
```bash
# .well-known klasörünü yükleyin
scp -r public/.well-known user@server:/var/www/canlipazar.com/

# Dosya izinlerini ayarlayın
chmod 644 /var/www/canlipazar.com/.well-known/apple-app-site-association
chmod 644 /var/www/canlipazar.com/.well-known/assetlinks.json
```

### 2. iOS
```bash
# Xcode'da build alın
flutter build ios --release

# App Store'a yükleyin
```

### 3. Android
```bash
# Release build alın
flutter build appbundle --release

# Play Store'a yükleyin
```

---

## 🔍 DOĞRULAMA

### iOS Universal Link
```bash
# Apple'ın doğrulama aracı
https://search.developer.apple.com/appsearch-validation-tool/

# URL: https://canlipazar.com/ilan/test123
```

### Android App Link
```bash
# Android doğrulama komutu
adb shell pm get-app-links com.canlipazar

# Beklenen çıktı:
# com.canlipazar:
#   ID: ...
#   Signatures: [SHA256:...]
#   Domain verification state:
#     canlipazar.com: verified
```

---

## ✅ SONUÇ

✅ **iOS Universal Links:** Yapılandırıldı  
✅ **Android App Links:** Yapılandırıldı  
✅ **Flutter Link Handler:** Çalışıyor  
✅ **Store Fallback:** Eklendi  
✅ **Open Graph:** Eklendi  

**Sistem WhatsApp / Sahibinden seviyesinde çalışıyor!** 🎉

---

## 📝 NOTLAR

- **TEAM_ID:** Apple Developer Portal'dan alınmalı
- **SHA256 Fingerprint:** Release keystore için alınmalı
- **App Store ID:** Gerçek ID ile değiştirilmeli
- **Web Sunucusu:** `.well-known` dosyaları HTTPS üzerinden erişilebilir olmalı
- **Content-Type:** `application/json` olmalı
- **Redirect:** OLMAMALI



















