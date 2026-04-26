# 🔑 Firebase Console'a APNs Authentication Key Yükleme Rehberi

## 📋 Gerekli Bilgiler

- **Key Dosyası**: `AuthKey_KZX5R849P3.p8` ✅
- **Key ID**: `KZX5R849P3` ✅ (dosya adından)
- **Team ID**: Apple Developer Portal'dan alınacak

---

## 🔍 Adım 1: Apple Developer Portal'dan Team ID Alın

1. **Apple Developer Portal**'a gidin: https://developer.apple.com/account
2. Sağ üst köşede **Membership** bölümüne tıklayın
3. **Team ID**'yi kopyalayın (örnek: `ABC123DEF4`)

**Not**: Team ID genellikle 10 karakterlik bir string'dir (harf ve rakam karışık).

---

## 🔧 Adım 2: Firebase Console'a Key Yükleyin

### 2.1 Firebase Console'a Gidin

1. **Firebase Console**'a gidin: https://console.firebase.google.com
2. Projenizi seçin: **canlipazar-b3697**
3. Sol menüden **⚙️ Project Settings** (Proje Ayarları) tıklayın
4. Üst menüden **Cloud Messaging** sekmesine tıklayın

### 2.2 iOS App Bölümünü Bulun

1. **Cloud Messaging** sayfasında aşağı kaydırın
2. **Apple app configuration** veya **iOS app configuration** bölümünü bulun
3. **APNs Authentication Key** bölümünü bulun

### 2.3 Key'i Yükleyin

1. **Upload** veya **Yükle** butonuna tıklayın
2. **Key ID** alanına: `KZX5R849P3` yazın
3. **Team ID** alanına: Apple Developer Portal'dan aldığınız Team ID'yi yazın
4. **Key dosyası** alanına: `AuthKey_KZX5R849P3.p8` dosyasını seçin
5. **Upload** veya **Kaydet** butonuna tıklayın

### 2.4 Doğrulama

1. Key yüklendikten sonra **Key ID** ve **Team ID** görünmeli
2. **Status** (Durum) **Active** (Aktif) olmalı
3. Yeşil bir onay işareti görünmeli

---

## ✅ Adım 3: Kontrol Edin

### 3.1 Firebase Console Kontrolü

- [ ] Key ID: `KZX5R849P3` görünüyor mu?
- [ ] Team ID: Doğru Team ID görünüyor mu?
- [ ] Status: **Active** (Aktif) mi?
- [ ] Bundle ID: `com.canlipazar.app` doğru mu?

### 3.2 Xcode Kontrolü

- [ ] Xcode → Target → Signing & Capabilities
- [ ] **Push Notifications** capability ekli mi?
- [ ] **Background Modes** → **Remote notifications** işaretli mi?
- [ ] **Bundle Identifier**: `com.canlipazar.app` doğru mu?

---

## 🧪 Adım 4: Test Edin

### 4.1 Gerçek iOS Cihazda Test

1. **Gerçek iOS cihazda** uygulamayı çalıştırın (Simulator'da çalışmaz!)
2. Bildirim izni verin
3. FCM token'ın Firestore'a kaydedildiğini kontrol edin:
   - Firestore → `users` → `{userId}` → `fcmToken` alanı dolu mu?
   - `platform` alanı `ios` mu?

### 4.2 Bildirim Testi

1. Başka bir cihazdan veya test kullanıcısından mesaj gönderin
2. iOS cihazda bildirim gelmeli:
   - **Foreground**: Bildirim görünmeli
   - **Background**: Bildirim görünmeli
   - **Terminated**: Bildirim görünmeli

---

## 🔍 Sorun Giderme

### Sorun: "Key upload failed" (Key yükleme başarısız)

**Olası Nedenler**:
- Key ID yanlış yazılmış
- Team ID yanlış yazılmış
- Key dosyası bozuk

**Çözüm**:
1. Key ID'yi tekrar kontrol edin: `KZX5R849P3`
2. Team ID'yi Apple Developer Portal'dan tekrar alın
3. Key dosyasını tekrar kontrol edin

### Sorun: "Key uploaded but not active" (Key yüklendi ama aktif değil)

**Olası Nedenler**:
- Key dosyası yanlış
- Key ID veya Team ID yanlış

**Çözüm**:
1. Key'i silin
2. Yeni key oluşturun
3. Tekrar yükleyin

### Sorun: "Bildirimler hala gelmiyor"

**Kontrol Listesi**:
1. ✅ Key yüklü mü? (Firebase Console'da kontrol edin)
2. ✅ Bundle ID doğru mu? (`com.canlipazar.app`)
3. ✅ Push Notifications capability ekli mi? (Xcode)
4. ✅ Background Modes → Remote notifications işaretli mi? (Xcode)
5. ✅ Bildirim izni verilmiş mi? (iOS Ayarlar)
6. ✅ FCM token Firestore'a kaydediliyor mu?
7. ✅ Platform="ios" olarak kaydediliyor mu?
8. ✅ Gerçek cihazda test ediliyor mu? (Simulator'da çalışmaz)

---

## 📊 Key Bilgileri Özeti

```
Key Dosyası: AuthKey_KZX5R849P3.p8
Key ID: KZX5R849P3
Team ID: [Apple Developer Portal'dan alınacak]
Bundle ID: com.canlipazar.app
```

---

## ✅ Başarı Kriterleri

Key başarıyla yüklendikten sonra:
- ✅ Firebase Console'da Key ID ve Team ID görünmeli
- ✅ Status: **Active** (Aktif) olmalı
- ✅ iOS cihazda bildirimler gelmeli

---

## 🎯 Sonraki Adımlar

1. ✅ Key'i Firebase Console'a yükleyin
2. ✅ Xcode'da Push Notifications capability'yi kontrol edin
3. ✅ Gerçek iOS cihazda test edin
4. ✅ Bildirimlerin geldiğini doğrulayın

---

**Not**: Key yüklendikten sonra iOS push notification'ları çalışmaya başlamalı. Eğer hala çalışmıyorsa, yukarıdaki sorun giderme adımlarını takip edin.










