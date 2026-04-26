# 🔍 iOS Bildirim Sorun Çözüm Kontrol Listesi

**Tarih:** 2024  
**Durum:** iOS bildirimleri gelmiyor - Kontrol listesi

---

## ✅ YAPILAN DÜZELTMELER

### 1. ✅ Entitlements Dosyası Düzeltildi
- **Dosya:** `ios/Runner/Runner.entitlements`
- **Değişiklik:** `aps-environment` değeri `development` → `production` olarak değiştirildi
- **Açıklama:** Production build için `production` olmalı

### 2. ✅ Bundle ID Kontrolü
- **Xcode Bundle ID:** `com.canlipazar.app` ✅
- **Firebase Cloud Functions APNs Topic:** `com.canlipazar.app` ✅
- **GoogleService-Info.plist Bundle ID:** `com.canlipazar.app` ✅
- **Tüm referanslar doğru:** ✅

### 3. ✅ Platform Filtresi
- **Durum:** Bildirimler sadece `platform === 'ios'` olan kullanıcılara gönderiliyor ✅
- **Kod:** `functions/src/index.ts` satır 467'de platform kontrolü mevcut ✅

### 4. ✅ Bildirim Mesajı
- **Başlık:** "CanlıPazar 🐄"
- **İçerik:** "Yeni ilanlar eklendi, göz at!"
- **Durum:** ✅ Güncellendi

---

## 🔍 KONTROL EDİLMESİ GEREKENLER

### 1. ⚠️ Xcode Push Notifications Capability

**Kontrol Adımları:**
1. Xcode'da projeyi açın: `ios/Runner.xcworkspace`
2. **Runner** target'ını seçin
3. **Signing & Capabilities** sekmesine gidin
4. **Push Notifications** capability'sinin ekli olduğunu kontrol edin
5. **Background Modes** capability'sinin ekli olduğunu kontrol edin
6. **Background Modes** içinde **Remote notifications** seçeneğinin işaretli olduğunu kontrol edin

**Eksikse Yapılacaklar:**
1. **+ Capability** butonuna tıklayın
2. **Push Notifications** capability'sini ekleyin
3. **Background Modes** capability'sini ekleyin (eğer yoksa)
4. **Background Modes** içinde **Remote notifications** seçeneğini işaretleyin

---

### 2. ⚠️ Apple Developer Portal - App ID

**Kontrol Adımları:**
1. Apple Developer Portal'a gidin: https://developer.apple.com/account
2. **Certificates, Identifiers & Profiles** → **Identifiers** → **App IDs**
3. `com.canlipazar.app` Bundle ID'sini bulun
4. **Push Notifications** capability'sinin **Enabled** olduğunu kontrol edin

**Eksikse Yapılacaklar:**
1. App ID'yi seçin
2. **Edit** butonuna tıklayın
3. **Push Notifications** checkbox'ını işaretleyin
4. **Save** butonuna tıklayın

---

### 3. ⚠️ Firebase Console - APNs Key

**Kontrol Adımları:**
1. Firebase Console'a gidin: https://console.firebase.google.com
2. Projenizi seçin: **canlipazar-b3697**
3. **Project Settings** → **Cloud Messaging** sekmesine gidin
4. **Apple app configuration** bölümünde:
   - **APNs Authentication Key** yüklü mü kontrol edin
   - **Key ID:** `94D623A8F4` doğru mu?
   - **Team ID:** `9W44LABURS` doğru mu?
   - **App:** `com.canlipazar.app` app'ine yüklü mü? (KRİTİK!)

**ÖNEMLİ:** APNs key'in `com.canlipazar.app` app'ine yüklü olduğundan emin olun. Eğer `com.canlipazar` app'ine yüklüyse bildirimler gelmez!

---

### 4. ⚠️ Firestore - Platform Bilgisi

**Kontrol Adımları:**
1. Firebase Console → **Firestore Database**
2. `users` koleksiyonunu açın
3. iOS kullanıcısının dokümanını bulun
4. Şu alanları kontrol edin:
   - `fcmToken`: Dolu mu? (150+ karakter olmalı)
   - `platform`: `ios` olarak kayıtlı mı? (KRİTİK!)
   - `fcmTokenUpdatedAt`: Son güncelleme tarihi var mı?

**Sorun Varsa:**
- Platform `unknown` veya `android` ise, uygulamayı yeniden başlatın
- FCM token yoksa, uygulamayı yeniden başlatın ve bildirim izni verin

---

### 5. ⚠️ Firebase Cloud Functions Deploy

**Kontrol:**
1. Functions'ın deploy edildiğinden emin olun:
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions:onNewAnimalPostCreated
   ```

2. Firebase Console → **Functions** sekmesinde `onNewAnimalPostCreated` fonksiyonunun aktif olduğunu kontrol edin

---

### 6. ⚠️ Test İlanı Ekleme

**Test Adımları:**
1. Uygulamada 2 yeni hayvan ilanı ekleyin
2. Firebase Console → **Functions** → **Logs** sekmesine gidin
3. `onNewAnimalPostCreated` fonksiyonunun çalıştığını kontrol edin
4. Log'larda şu mesajları arayın:
   - `✅ 2 ilan tamamlandı! Bildirim gönderiliyor...`
   - `📊 iOS kullanıcı sayısı: X`
   - `✅ X iOS kullanıcıya bildirim gönderiliyor`

**Sorun Varsa:**
- Log'larda `⚠️ Bildirim gönderilecek iOS kullanıcı bulunamadı` görüyorsanız:
  - Firestore'da kullanıcının `platform: 'ios'` olduğundan emin olun
  - FCM token'ın geçerli olduğundan emin olun

---

## 🧪 TEST ADIMLARI

### Test 1: Platform Bilgisi Kontrolü
1. iOS cihazda uygulamayı açın
2. Giriş yapın
3. Firebase Console → Firestore → `users/{userId}` dokümanını kontrol edin
4. `platform` alanının `ios` olduğundan emin olun

### Test 2: FCM Token Kontrolü
1. iOS cihazda uygulamayı açın
2. Bildirim izni verin
3. Firebase Console → Firestore → `users/{userId}` dokümanını kontrol edin
4. `fcmToken` alanının dolu olduğundan (150+ karakter) emin olun

### Test 3: Bildirim Testi
1. 2 yeni hayvan ilanı ekleyin
2. Firebase Console → Functions → Logs'u kontrol edin
3. Bildirim gönderildiğini doğrulayın
4. iOS cihazda bildirimin geldiğini kontrol edin

---

## 📋 ÖZET KONTROL LİSTESİ

- [ ] Xcode'da **Push Notifications** capability ekli mi?
- [ ] Xcode'da **Background Modes** → **Remote notifications** işaretli mi?
- [ ] Apple Developer Portal'da App ID'de **Push Notifications** enabled mi?
- [ ] Firebase Console'da APNs key `com.canlipazar.app` app'ine yüklü mü?
- [ ] Firestore'da kullanıcının `platform: 'ios'` olarak kayıtlı mı?
- [ ] Firestore'da kullanıcının `fcmToken` dolu mu?
- [ ] Firebase Cloud Functions deploy edildi mi?
- [ ] Test ilanları eklendiğinde Functions log'larında bildirim gönderildiği görünüyor mu?

---

## 🔧 HIZLI ÇÖZÜMLER

### Sorun: Platform "unknown" olarak kayıtlı
**Çözüm:**
1. Uygulamayı tamamen kapatın
2. Uygulamayı yeniden açın
3. Giriş yapın
4. Firestore'da `platform: 'ios'` olduğunu kontrol edin

### Sorun: FCM Token yok
**Çözüm:**
1. iOS Ayarlar → Uygulama → Bildirimler → İzin ver
2. Uygulamayı yeniden başlatın
3. Firestore'da `fcmToken` alanının dolu olduğunu kontrol edin

### Sorun: Bildirimler gelmiyor ama Functions çalışıyor
**Çözüm:**
1. Firebase Console → Cloud Messaging → APNs key kontrolü
2. APNs key'in `com.canlipazar.app` app'ine yüklü olduğundan emin olun
3. Xcode'da Push Notifications capability'sinin ekli olduğundan emin olun

---

## 📞 DESTEK

Eğer tüm kontrolleri yaptıktan sonra hala bildirimler gelmiyorsa:
1. Firebase Console → Functions → Logs'u kontrol edin
2. Hata mesajlarını not edin
3. Firestore'da kullanıcı dokümanını kontrol edin
4. Xcode console log'larını kontrol edin





















