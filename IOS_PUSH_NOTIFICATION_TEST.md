# 🧪 iOS Push Notification Test Rehberi

## ✅ Key Yükleme Kontrolü

### Firebase Console Kontrolü

1. **Firebase Console** → **Project Settings** → **Cloud Messaging**
2. **iOS app configuration** bölümünde kontrol edin:
   - [ ] **Key ID**: `KZX5R849P3` görünüyor mu?
   - [ ] **Team ID**: Doğru Team ID görünüyor mu?
   - [ ] **Status**: **Active** (Aktif) mi?
   - [ ] **Bundle ID**: `com.canlipazar.app` doğru mu?

---

## 🔍 Xcode Kontrolü

### 1. Push Notifications Capability

1. Xcode'u açın
2. **Target** → **Signing & Capabilities**
3. Kontrol edin:
   - [ ] **Push Notifications** capability ekli mi?
   - [ ] Eğer yoksa → **+ Capability** → **Push Notifications** ekleyin

### 2. Background Modes

1. **Signing & Capabilities** → **Background Modes**
2. Kontrol edin:
   - [ ] **Remote notifications** işaretli mi?
   - [ ] Eğer yoksa → İşaretleyin

### 3. Bundle Identifier

1. **Target** → **General** → **Bundle Identifier**
2. Kontrol edin:
   - [ ] **Bundle Identifier**: `com.canlipazar.app` doğru mu?

### 4. Signing

1. **Target** → **Signing & Capabilities**
2. Kontrol edin:
   - [ ] **Team**: Doğru team seçili mi?
   - [ ] **Automatically manage signing**: İşaretli mi?

---

## 📱 Test Adımları

### Adım 1: Gerçek iOS Cihazda Uygulamayı Çalıştırın

**ÖNEMLİ**: iOS Simulator'da push notification çalışmaz! Mutlaka gerçek cihazda test edin.

1. **Gerçek iOS cihazınızı** Mac'inize bağlayın
2. Xcode'da cihazı seçin
3. **Run** (▶️) butonuna tıklayın
4. Uygulama cihazda açılmalı

### Adım 2: Bildirim İzni Verin

1. Uygulama açıldığında bildirim izni isteği çıkmalı
2. **Allow** (İzin Ver) butonuna tıklayın
3. Eğer izin isteği çıkmazsa:
   - iOS **Ayarlar** → **CanlıPazar** → **Bildirimler**
   - Bildirimleri **Açık** yapın

### Adım 3: FCM Token Kontrolü

1. **Firestore Console**'a gidin: https://console.firebase.google.com
2. **Firestore Database** → **users** koleksiyonuna gidin
3. Kendi kullanıcı dokümanınızı bulun
4. Kontrol edin:
   - [ ] **fcmToken** alanı dolu mu? (150+ karakter olmalı)
   - [ ] **platform** alanı `ios` mu?
   - [ ] **fcmTokenUpdatedAt** alanı var mı?

**Eğer token yoksa veya platform="unknown" ise**:
- Uygulamayı kapatıp tekrar açın
- AppDelegate loglarını kontrol edin (Xcode Console)

### Adım 4: AppDelegate Loglarını Kontrol Edin

Xcode Console'da şu logları görmelisiniz:

```
✅ AppDelegate: Firebase yapılandırıldı
✅ AppDelegate: Firebase Messaging delegate ayarlandı
✅ AppDelegate: UNUserNotificationCenter delegate ayarlandı
✅ [AppDelegate] iOS Bildirim izni verildi
📱 [AppDelegate] APNs TOKEN ALINDI
✅ [AppDelegate] APNs token Firebase Messaging'e verildi
🔄 [AppDelegate] FCM TOKEN ALINDI
✅ [AppDelegate] FCM token Firestore'a kaydedildi
```

**Eğer bu loglar görünmüyorsa**:
- Uygulamayı kapatıp tekrar açın
- Bildirim iznini kontrol edin
- Xcode Console'da hata mesajlarını kontrol edin

### Adım 5: Bildirim Testi

#### Test 1: Foreground (Uygulama Açıkken)

1. Uygulamayı açık tutun
2. Başka bir cihazdan veya test kullanıcısından mesaj gönderin
3. **Bildirim görünmeli** (ekranın üstünde)

#### Test 2: Background (Uygulama Arka Planda)

1. Uygulamayı arka plana alın (Home tuşuna basın)
2. Başka bir cihazdan veya test kullanıcısından mesaj gönderin
3. **Bildirim görünmeli** (bildirim merkezinde)

#### Test 3: Terminated (Uygulama Kapalı)

1. Uygulamayı tamamen kapatın (App Switcher'dan swipe up)
2. Başka bir cihazdan veya test kullanıcısından mesaj gönderin
3. **Bildirim görünmeli** (bildirim merkezinde)
4. Bildirime tıklayın → Uygulama açılmalı

---

## 🔍 Sorun Giderme

### Sorun 1: "FCM token alınamıyor"

**Olası Nedenler**:
- APNs token alınamıyor
- Bildirim izni verilmemiş
- Firebase yapılandırması hatalı

**Çözüm**:
1. Xcode Console'da hata mesajlarını kontrol edin
2. Bildirim iznini kontrol edin (iOS Ayarlar)
3. Uygulamayı kapatıp tekrar açın

### Sorun 2: "FCM token Firestore'a kaydedilmiyor"

**Olası Nedenler**:
- Kullanıcı giriş yapmamış
- Firestore yazma izni yok
- Network bağlantısı yok

**Çözüm**:
1. Kullanıcı giriş yapmış mı kontrol edin
2. Firestore Security Rules'u kontrol edin
3. Network bağlantısını kontrol edin

### Sorun 3: "Bildirimler hala gelmiyor"

**Kontrol Listesi**:
1. ✅ Key yüklü mü? (Firebase Console)
2. ✅ Bundle ID doğru mu? (`com.canlipazar.app`)
3. ✅ Push Notifications capability ekli mi? (Xcode)
4. ✅ Background Modes → Remote notifications işaretli mi? (Xcode)
5. ✅ Bildirim izni verilmiş mi? (iOS Ayarlar)
6. ✅ FCM token Firestore'a kaydediliyor mu?
7. ✅ Platform="ios" olarak kaydediliyor mu?
8. ✅ Gerçek cihazda test ediliyor mu? (Simulator'da çalışmaz)

**Ek Kontroller**:
- Firebase Console → Cloud Messaging → Test mesaj gönderin
- Cloud Functions loglarını kontrol edin
- Xcode Console'da hata mesajlarını kontrol edin

### Sorun 4: "Bildirim geliyor ama görünmüyor"

**Olası Nedenler**:
- Foreground'da local notification gösterilmiyor
- Background handler çalışmıyor

**Çözüm**:
1. Xcode Console'da logları kontrol edin
2. `_showLocalNotification` fonksiyonunun çağrıldığını kontrol edin
3. Flutter local notifications plugin'inin initialize edildiğini kontrol edin

---

## 📊 Başarı Kriterleri

Test başarılı sayılır eğer:
- ✅ FCM token Firestore'a kaydediliyor
- ✅ Platform="ios" olarak kaydediliyor
- ✅ Foreground'da bildirim görünüyor
- ✅ Background'da bildirim görünüyor
- ✅ Terminated state'de bildirim görünüyor
- ✅ Bildirime tıklayınca uygulama açılıyor

---

## 🎯 Sonraki Adımlar

1. ✅ Key'i Firebase Console'a yüklediniz
2. ⏳ Xcode'da Push Notifications capability'yi kontrol edin
3. ⏳ Gerçek iOS cihazda test edin
4. ⏳ Bildirimlerin geldiğini doğrulayın

---

**Not**: Test sırasında sorun yaşarsanız, Xcode Console'daki logları paylaşın. Bu loglar sorunun kaynağını bulmamıza yardımcı olacaktır.










