# 🔗 Deep Linking Sistemi - Tam Kurulum Rehberi

## ✅ Yapılan Değişiklikler

### 1. Link Formatı Değişikliği
- **Eski format:** `https://canlipazar.com/animal/{postId}`
- **Yeni format:** `https://canlipazar.com/ilan/{postId}`
- Tüm dosyalarda güncellendi:
  - `lib/services/dynamic_link_service.dart`
  - `lib/screens/animal_detail_screen.dart`
  - `lib/main.dart`
  - `android/app/src/main/AndroidManifest.xml`

### 2. Web Sayfası Oluşturuldu
- **Dosya:** `public/ilan/index.html`
- **Özellikler:**
  - Firebase'den ilan bilgilerini çeker
  - Open Graph meta tags ile sosyal medya önizlemesi
  - Twitter Card desteği
  - Otomatik uygulama yönlendirme
  - Store yönlendirme (uygulama yoksa)

### 3. Android Yapılandırması
- `AndroidManifest.xml` güncellendi
- `/ilan` path'i eklendi
- Geriye dönük uyumluluk için `/animal` path'i korundu

### 4. Deep Link Handler Güncellendi
- `lib/main.dart` içinde `/ilan` path desteği eklendi
- Geriye dönük uyumluluk korundu

## 📋 Yapılması Gerekenler

### 1. Web Sunucusu Yapılandırması

#### A. Firebase Hosting Kurulumu
```bash
# Firebase CLI kurulumu
npm install -g firebase-tools

# Firebase'e giriş
firebase login

# Projeyi başlat
firebase init hosting

# public/ilan/index.html dosyasını deploy et
firebase deploy --only hosting
```

#### B. Web Sunucusu Yapılandırması
Web sunucunuzda şu yapılandırmayı yapın:

**Nginx örneği:**
```nginx
server {
    listen 80;
    server_name canlipazar.com www.canlipazar.com;
    
    # /ilan/{ilanId} path'ini index.html'e yönlendir
    location ~ ^/ilan/(.+)$ {
        try_files $uri $uri/ /ilan/index.html;
    }
    
    # apple-app-site-association dosyası
    location /.well-known/apple-app-site-association {
        default_type application/json;
        add_header Content-Type application/json;
    }
    
    # Android assetlinks.json dosyası
    location /.well-known/assetlinks.json {
        default_type application/json;
        add_header Content-Type application/json;
    }
}
```

### 2. iOS Universal Links Yapılandırması

#### A. apple-app-site-association Dosyası
Web sunucunuzda `https://canlipazar.com/.well-known/apple-app-site-association` dosyası oluşturun:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.canlipazar.app",
        "paths": [
          "/ilan/*",
          "/animal/*"
        ]
      }
    ]
  }
}
```

**ÖNEMLİ:**
- `TEAM_ID` yerine gerçek Apple Team ID'nizi yazın
- Dosya **Content-Type: application/json** olmalı
- Dosya **HTTPS** üzerinden erişilebilir olmalı
- Dosya **gzip** olmamalı

#### B. Apple Developer Portal
1. Apple Developer Portal'a giriş yapın
2. App ID'nizi seçin (`com.canlipazar.app`)
3. **Associated Domains** capability'sini etkinleştirin
4. Şu domain'leri ekleyin:
   - `applinks:canlipazar.com`
   - `applinks:www.canlipazar.com`

### 3. Android App Links Yapılandırması

#### A. assetlinks.json Dosyası
Web sunucunuzda `https://canlipazar.com/.well-known/assetlinks.json` dosyası oluşturun:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.canlipazar.app",
      "sha256_cert_fingerprints": [
        "SHA256_FINGERPRINT_BURAYA"
      ]
    }
  }
]
```

**SHA256 Fingerprint Alma:**
```bash
# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore için
keytool -list -v -keystore /path/to/keystore.jks -alias your-key-alias
```

#### B. AndroidManifest.xml
✅ Zaten güncellendi - `/ilan` path'i eklendi

### 4. Firebase Yapılandırması

#### A. Firebase Hosting
1. Firebase Console'a giriş yapın
2. **Hosting** bölümüne gidin
3. `public/ilan/index.html` dosyasını deploy edin
4. Custom domain ekleyin: `canlipazar.com`

#### B. Firebase Config
`public/ilan/index.html` dosyasındaki Firebase config'i güncelleyin:

```javascript
const firebaseConfig = {
  apiKey: "GERÇEK_API_KEY",
  authDomain: "canlipazar.firebaseapp.com",
  projectId: "canlipazar",
  storageBucket: "canlipazar.appspot.com",
  messagingSenderId: "GERÇEK_SENDER_ID",
  appId: "GERÇEK_APP_ID"
};
```

### 5. Store Linklerini Güncelleme

#### A. App Store Link
`public/ilan/index.html` dosyasında:
```javascript
const appStoreLink = 'https://apps.apple.com/app/canlipazar/idGERÇEK_APP_ID';
```

#### B. Play Store Link
`public/ilan/index.html` dosyasında:
```javascript
const playStoreLink = 'https://play.google.com/store/apps/details?id=com.canlipazar.app';
```

### 6. Test Etme

#### A. iOS Test
1. iPhone'da Safari'de `https://canlipazar.com/ilan/{testIlanId}` açın
2. Uygulama yüklüyse direkt açılmalı
3. Uygulama yoksa App Store'a yönlendirmeli

#### B. Android Test
1. Android'de Chrome'da `https://canlipazar.com/ilan/{testIlanId}` açın
2. Uygulama yüklüyse direkt açılmalı
3. Uygulama yoksa Play Store'a yönlendirmeli

#### C. Sosyal Medya Test
1. WhatsApp'ta link paylaşın
2. Fotoğraf, başlık ve açıklama görünmeli
3. Instagram DM'de test edin
4. Facebook'ta test edin

## 🔍 Sorun Giderme

### Problem: iOS'ta Universal Link çalışmıyor
**Çözüm:**
1. `apple-app-site-association` dosyasının doğru yerde olduğundan emin olun
2. Apple Developer Portal'da Associated Domains aktif mi kontrol edin
3. Dosyanın Content-Type'ı `application/json` olmalı
4. Dosya gzip olmamalı

### Problem: Android'de App Link çalışmıyor
**Çözüm:**
1. `assetlinks.json` dosyasının doğru yerde olduğundan emin olun
2. SHA256 fingerprint'in doğru olduğundan emin olun
3. AndroidManifest.xml'de `android:autoVerify="true"` olmalı
4. Uygulamayı yeniden yükleyin

### Problem: Sosyal medyada önizleme görünmüyor
**Çözüm:**
1. Open Graph meta tags'in doğru olduğundan emin olun
2. Görsel URL'sinin erişilebilir olduğundan emin olun
3. Facebook Debugger'da test edin: https://developers.facebook.com/tools/debug/
4. Twitter Card Validator'da test edin: https://cards-dev.twitter.com/validator

## 📝 Notlar

- Geriye dönük uyumluluk için `/animal` path'i hala destekleniyor
- Web sayfası Firebase'den ilan bilgilerini çekiyor, bu yüzden Firebase yapılandırması gerekli
- Store linklerini gerçek değerlerle değiştirmeyi unutmayın
- iOS ve Android için ayrı test cihazları kullanın

## ✅ Tamamlanan Özellikler

- ✅ Link formatı `/ilan/{ilanId}` olarak değiştirildi
- ✅ Web sayfası oluşturuldu (Open Graph meta tags ile)
- ✅ Android yapılandırması güncellendi
- ✅ Deep link handler güncellendi
- ✅ Paylaşım fonksiyonu güncellendi
- ✅ Store yönlendirme mantığı eklendi
- ✅ Geriye dönük uyumluluk korundu

## 🚀 Sonraki Adımlar

1. Web sunucusunu yapılandırın
2. `apple-app-site-association` dosyasını oluşturun
3. `assetlinks.json` dosyasını oluşturun
4. Firebase config'i güncelleyin
5. Store linklerini güncelleyin
6. Test edin























