# 🍎 Apple Developer Portal Rehberi

**iOS FCM Bildirimleri İçin Kritik Kontroller**

---

## 📖 Apple Developer Portal Nedir?

**Apple Developer Portal**, Apple'ın geliştiricilere sağladığı web tabanlı bir platformdur. iOS, macOS, watchOS ve tvOS uygulamaları geliştirmek ve yayınlamak için gerekli tüm kaynakları ve araçları içerir.

**URL:** https://developer.apple.com/account

**Giriş:** Apple ID ile giriş yapılır (ücretli Apple Developer Program üyeliği gerekir - yıllık $99)

---

## 🎯 iOS FCM Bildirimleri İçin Neden Önemli?

iOS'ta push notification göndermek için **mutlaka** Apple Developer Portal'da şunlar yapılandırılmalı:

1. **App ID** - Push Notifications capability'si aktif olmalı
2. **APNs Authentication Key** - Firebase'e yüklenmeli
3. **Provisioning Profile** - Push Notifications capability'si olan profile kullanılmalı

---

## 📋 YAPILMASI GEREKEN KONTROLLER

### 1. ✅ App ID Kontrolü (KRİTİK!)

**Adımlar:**
1. Apple Developer Portal'a git: https://developer.apple.com/account
2. Giriş yap (Apple ID ile)
3. Sol menüden **"Certificates, Identifiers & Profiles"** seç
4. **"Identifiers"** sekmesine git
5. **"App IDs"** seçeneğini seç
6. `com.canlipazar.app` Bundle ID'sini ara

**Kontrol Edilecekler:**
- ✅ Bundle ID: `com.canlipazar.app` mevcut mu?
- ✅ **Push Notifications** capability'si **Enabled** (aktif) mi?
- ✅ Status: **Active** mi?

**Eğer Push Notifications Enabled değilse:**
1. App ID'yi seç
2. **"Edit"** butonuna tıkla
3. **"Push Notifications"** checkbox'ını işaretle
4. **"Save"** butonuna tıkla
5. Değişikliklerin aktif olması birkaç dakika sürebilir

---

### 2. ✅ APNs Authentication Key Kontrolü

**Adımlar:**
1. Apple Developer Portal'da **"Certificates, Identifiers & Profiles"** > **"Keys"** sekmesine git
2. Key ID `94D623A8F4` olan key'i ara

**Kontrol Edilecekler:**
- ✅ Key mevcut mu?
- ✅ **Apple Push Notifications service (APNs)** seçeneği işaretli mi?
- ✅ Key **Active** durumunda mı?
- ✅ Team ID: `9W44LABURS` doğru mu?

**Eğer Key yoksa veya yanlışsa:**
1. **"+"** butonuna tıkla (yeni key oluştur)
2. **Key Name:** "CanliPazar Push Notifications" (veya istediğiniz isim)
3. **"Apple Push Notifications service (APNs)"** checkbox'ını işaretle
4. **"Continue"** > **"Register"**
5. **Key'i indir** (`.p8` dosyası) - ⚠️ **SADECE BİR KEZ İNDİRİLEBİLİR!**
6. **Key ID**'yi not et (örn: `94D623A8F4`)
7. **Team ID**'yi not et (Apple Developer hesabınızın Team ID'si)
8. Firebase Console'a yükle (Project Settings > Cloud Messaging > Apple app configuration)

---

### 3. ✅ Provisioning Profile Kontrolü

**Adımlar:**
1. Apple Developer Portal'da **"Certificates, Identifiers & Profiles"** > **"Profiles"** sekmesine git
2. Development ve Distribution profile'larını kontrol et

**Kontrol Edilecekler:**
- ✅ Profile'da **Push Notifications** capability'si var mı?
- ✅ Bundle ID: `com.canlipazar.app` doğru mu?
- ✅ Profile **Active** durumunda mı?

**Eğer Profile'da Push Notifications yoksa:**
1. Yeni Provisioning Profile oluştur:
   - **"+"** butonuna tıkla
   - **Development** veya **App Store** seç (ihtiyacına göre)
   - App ID'yi seç: `com.canlipazar.app`
   - Certificate'ı seç
   - Device'ları seç (Development için)
   - Profile adını ver
   - **"Generate"** > **"Download"**
2. Xcode'da profile'ı güncelle:
   - Xcode'da projeyi aç
   - **Signing & Capabilities** sekmesine git
   - **Provisioning Profile** dropdown'ından yeni profile'ı seç

---

## 🔍 DETAYLI KONTROL ADIMLARI

### Adım 1: Apple Developer Portal'a Giriş

1. Tarayıcıda şu adrese git: https://developer.apple.com/account
2. Apple ID ile giriş yap
3. Eğer Apple Developer Program üyeliğin yoksa, önce üye ol ($99/yıl)

---

### Adım 2: App ID Kontrolü

**Yol:** Certificates, Identifiers & Profiles > Identifiers > App IDs

**Kontrol Listesi:**
- [ ] `com.canlipazar.app` Bundle ID mevcut mu?
- [ ] **Push Notifications** capability **Enabled** mi?
- [ ] Status **Active** mi?

**Eğer Push Notifications Enabled değilse:**
1. App ID'yi seç
2. **Edit** butonuna tıkla
3. **Push Notifications** checkbox'ını işaretle
4. **Save** butonuna tıkla
5. Birkaç dakika bekle (aktif olması için)

---

### Adım 3: APNs Key Kontrolü

**Yol:** Certificates, Identifiers & Profiles > Keys

**Kontrol Listesi:**
- [ ] Key ID `94D623A8F4` mevcut mu?
- [ ] **Apple Push Notifications service (APNs)** seçeneği işaretli mi?
- [ ] Key **Active** durumunda mı?
- [ ] Team ID `9W44LABURS` doğru mu?

**Eğer Key yoksa:**
1. **"+"** butonuna tıkla
2. Key Name: "CanliPazar Push Notifications"
3. **Apple Push Notifications service (APNs)** işaretle
4. **Continue** > **Register**
5. Key'i indir (`.p8` dosyası) - ⚠️ **SADECE BİR KEZ İNDİRİLEBİLİR!**
6. Key ID ve Team ID'yi not et
7. Firebase Console'a yükle

---

### Adım 4: Provisioning Profile Kontrolü

**Yol:** Certificates, Identifiers & Profiles > Profiles

**Kontrol Listesi:**
- [ ] Development profile'da Push Notifications var mı?
- [ ] Distribution profile'da Push Notifications var mı?
- [ ] Bundle ID `com.canlipazar.app` doğru mu?
- [ ] Profile'lar **Active** durumunda mı?

**Eğer Profile'da Push Notifications yoksa:**
1. Yeni profile oluştur (yukarıdaki adımları takip et)
2. Xcode'da profile'ı güncelle

---

## 📸 GÖRSEL REHBER

### App ID Kontrolü

```
Apple Developer Portal
├── Certificates, Identifiers & Profiles
    ├── Identifiers
        ├── App IDs
            └── com.canlipazar.app
                ├── Bundle ID: com.canlipazar.app ✅
                ├── Push Notifications: Enabled ✅
                └── Status: Active ✅
```

### APNs Key Kontrolü

```
Apple Developer Portal
├── Certificates, Identifiers & Profiles
    ├── Keys
        └── Key ID: 94D623A8F4
            ├── Name: CanliPazar Push Notifications
            ├── Apple Push Notifications service (APNs): ✅
            ├── Key ID: 94D623A8F4 ✅
            ├── Team ID: 9W44LABURS ✅
            └── Status: Active ✅
```

### Provisioning Profile Kontrolü

```
Apple Developer Portal
├── Certificates, Identifiers & Profiles
    ├── Profiles
        ├── Development Profile
        │   ├── App ID: com.canlipazar.app ✅
        │   ├── Push Notifications: ✅
        │   └── Status: Active ✅
        └── Distribution Profile
            ├── App ID: com.canlipazar.app ✅
            ├── Push Notifications: ✅
            └── Status: Active ✅
```

---

## ⚠️ ÖNEMLİ NOTLAR

### 1. APNs Key İndirme
- `.p8` dosyası **SADECE BİR KEZ** indirilebilir
- İndirdikten sonra güvenli bir yerde sakla
- Firebase Console'a yükledikten sonra artık gerekmez (Firebase'de saklanır)

### 2. App ID Değişiklikleri
- App ID'de capability değişiklikleri yapıldıktan sonra birkaç dakika bekle
- Değişikliklerin aktif olması zaman alabilir

### 3. Provisioning Profile Güncelleme
- Profile'da değişiklik yaptıktan sonra Xcode'da güncelle
- Xcode'da **Signing & Capabilities** sekmesinden profile'ı seç

### 4. Team ID
- Team ID, Apple Developer hesabınızın benzersiz kimliğidir
- Firebase Console'a APNs key yüklerken Team ID gerekir
- Team ID'yi Apple Developer Portal'ın sağ üst köşesinde bulabilirsin

---

## 🧪 TEST

Apple Developer Portal kontrollerini yaptıktan sonra:

1. **Xcode'da build et:**
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run
   ```

2. **Bildirim izni iste:**
   - Uygulama açıldığında bildirim izni istenmeli

3. **Token kontrolü:**
   - Xcode console'da FCM token loglanmalı
   - Firestore'da `users/{userId}/fcmToken` alanı dolu olmalı

4. **Test bildirimi gönder:**
   - Firebase Console'dan test bildirimi gönder
   - Veya Cloud Functions'dan test endpoint'ini çağır

---

## 📞 YARDIM

Eğer sorun yaşarsan:

1. **Apple Developer Support:** https://developer.apple.com/support
2. **Firebase Support:** https://firebase.google.com/support
3. **Stack Overflow:** iOS FCM soruları için

---

## ✅ KONTROL LİSTESİ

Apple Developer Portal'da kontrol edilmesi gerekenler:

- [ ] Apple Developer Program üyeliğim var mı?
- [ ] App ID (`com.canlipazar.app`) mevcut mu?
- [ ] App ID'de Push Notifications **Enabled** mi?
- [ ] APNs Authentication Key mevcut mu?
- [ ] APNs Key'de **Apple Push Notifications service (APNs)** işaretli mi?
- [ ] APNs Key **Active** durumunda mı?
- [ ] Key ID ve Team ID doğru mu?
- [ ] Provisioning Profile'da Push Notifications var mı?
- [ ] Profile'lar **Active** durumunda mı?

**Tüm maddeler ✅ ise, Apple Developer Portal tarafı hazır!**

---

**Not:** Bu rehber iOS FCM bildirimleri için Apple Developer Portal'da yapılması gereken kontrolleri kapsar. Kod tarafındaki düzeltmeler için `IOS_FCM_TAM_ANALIZ_RAPORU.md` dosyasına bakın.





























