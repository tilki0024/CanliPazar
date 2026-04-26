# ✅ iOS Push Notification Test Checklist

## 🔍 Yapılan Değişiklikleri Kontrol Et

### 1. ✅ Push Notifications Capability Kontrolü

**Xcode'da kontrol edin:**
1. Xcode'da `Runner.xcworkspace` açık mı?
2. Runner target → Signing & Capabilities sekmesi
3. Push Notifications capability'si **işaretli (☑)** mi?

**✅ Başarılı:** Checkbox işaretli ve aktif görünüyor
**❌ Sorun:** Checkbox işaretli değil veya gri görünüyor

---

### 2. ✅ AppDelegate.swift Kontrolü

**Dosya:** `ios/Runner/AppDelegate.swift`

**Kontrol edilmesi gerekenler:**
- [ ] `FirebaseApp.configure()` var mı? (Satır 30)
- [ ] `Messaging.messaging().delegate = self` var mı? (Satır 58)
- [ ] `UNUserNotificationCenter.current().delegate = self` var mı? (Satır 64)
- [ ] `application.registerForRemoteNotifications()` var mı? (Satır 87, 98)
- [ ] `Messaging.messaging().apnsToken = deviceToken` var mı? (Satır 177)
- [ ] `saveTokenToFirestore(token:)` fonksiyonu var mı? (Satır 354)

**✅ Başarılı:** Tüm satırlar mevcut
**❌ Sorun:** Eksik satırlar var

---

### 3. ✅ Flutter Tarafı Kontrolü

**Dosya:** `lib/main.dart`

**Kontrol edilmesi gerekenler:**
- [ ] `FirebaseAnalytics` import edilmiş mi? (Satır 9)
- [ ] `Firebase.initializeApp()` çağrılıyor mu? (Satır 191-213)
- [ ] `FirebaseMessaging.onBackgroundMessage()` ayarlanmış mı? (Satır 262)
- [ ] iOS için `requestPermission()` çağrılmıyor mu? (Satır 292-308)

**✅ Başarılı:** Tüm kontroller geçti
**❌ Sorun:** Eksik veya hatalı kod var

---

### 4. ✅ Firestore User Kaydı Kontrolü

**Dosya:** `lib/resources/auth_methods.dart`

**Kontrol edilmesi gerekenler:**
- [ ] `signUpUser()` fonksiyonunda `platform` alanı ekleniyor mu? (Satır 122-150)
- [ ] Platform değeri `'ios'` veya `'android'` olarak ayarlanıyor mu?

**✅ Başarılı:** Platform alanı ekleniyor
**❌ Sorun:** Platform alanı eksik

---

### 5. ✅ FCM Token Manager Kontrolü

**Dosya:** `lib/services/fcm_token_manager.dart`

**Kontrol edilmesi gerekenler:**
- [ ] `_getPlatform()` fonksiyonu iOS'u doğru tespit ediyor mu? (Satır 135-186)
- [ ] `_saveToFirestore()` fonksiyonu platform ile birlikte kaydediyor mu? (Satır 202-220)
- [ ] Platform "unknown" ise düzeltiliyor mu? (Satır 79-101)

**✅ Başarılı:** Tüm kontroller geçti
**❌ Sorun:** Eksik veya hatalı kod var

---

## 🧪 Test Adımları

### Test 1: Xcode Console Kontrolü

**Adımlar:**
1. Xcode'da projeyi açın
2. Gerçek iOS cihazınızı seçin (simülatör değil!)
3. **Run** butonuna tıklayın (▶️) veya Cmd+R
4. Console'u açın (alt panel, Cmd+Shift+Y)
5. Şu logları arayın:

**✅ Başarılı Loglar:**
```
🚀 AppDelegate: Uygulama başlatılıyor...
✅ AppDelegate: Firebase yapılandırıldı
✅ AppDelegate: Firebase Messaging delegate ayarlandı
✅ AppDelegate: UNUserNotificationCenter delegate ayarlandı
📱 Mevcut bildirim izin durumu: 0
✅ iOS Bildirim izni verildi
📱 APNs device token alındı: [token]
✅ APNs token Firebase Messaging'e verildi
✅ Firebase registration token alındı: [fcmToken]
✅ FCM token Firestore'a kaydedildi: [userId]
```

**❌ Sorun Varsa:**
- Loglar görünmüyorsa → AppDelegate.swift'i kontrol edin
- "APNs device token alındı" görünmüyorsa → Push Notifications capability açık mı?
- "FCM token Firestore'a kaydedildi" görünmüyorsa → Kullanıcı giriş yapmış mı?

---

### Test 2: Firestore Kontrolü

**Adımlar:**
1. Firebase Console → Firestore Database
2. `users` koleksiyonunu seçin
3. Kullanıcınızın dokümanını açın (doküman ID = kullanıcı UID)
4. Şu alanları kontrol edin:

**✅ Başarılı:**
```json
{
  "fcmToken": "chZOWO2xSWCb1KaDnP6Mz7:APA91bH_...",  // ✅ Var
  "platform": "ios",  // ✅ "ios" olmalı (boş veya "unknown" değil)
  "fcmTokenUpdatedAt": "2025-01-13T10:16:24Z"  // ✅ Timestamp var
}
```

**❌ Sorun Varsa:**
- `fcmToken` yoksa → FCM token alınamamış, Xcode console'u kontrol edin
- `platform` yoksa veya "unknown" ise → Platform bilgisi kaydedilmemiş
- `platform` boşsa → Kullanıcı kaydı sırasında eklenmemiş

---

### Test 3: Push Notification Testi

**Adımlar:**
1. Firebase Console → Cloud Messaging
2. **"New notification"** butonuna tıklayın
3. Notification başlığı ve mesajı yazın
4. **"Send test message"** butonuna tıklayın
5. FCM token'ı girin (Firestore'dan kopyalayın)
6. **"Test"** butonuna tıklayın

**✅ Başarılı:**
- iOS cihazda bildirim görünür
- Bildirime tıklandığında uygulama açılır

**❌ Sorun Varsa:**
- Bildirim gelmiyorsa → Push Notifications capability açık mı?
- FCM token geçersizse → Token yenilenmiş olabilir, Firestore'dan yeni token'ı alın

---

## 📊 Hızlı Kontrol Listesi

### Kod Kontrolü:
- [ ] Push Notifications capability açık (Xcode'da)
- [ ] AppDelegate.swift doğru yapılandırılmış
- [ ] Flutter tarafı doğru yapılandırılmış
- [ ] Platform alanı kullanıcı kaydı sırasında ekleniyor
- [ ] FCM token Firestore'a kaydediliyor

### Test Kontrolü:
- [ ] Xcode console'da APNs token logları görünüyor
- [ ] Xcode console'da FCM token logları görünüyor
- [ ] Firestore'da `fcmToken` alanı var
- [ ] Firestore'da `platform: "ios"` alanı var
- [ ] Test push notification geldi

---

## 🎯 Sonuç Değerlendirmesi

### ✅ Tüm Kontroller Geçti:
**Tebrikler!** iOS push notification sistemi çalışıyor. Artık:
- FCM token'lar Firestore'a kaydediliyor
- Platform bilgisi doğru kaydediliyor
- Push notification'lar çalışıyor

### ⚠️ Bazı Kontroller Başarısız:
**Hangi kontroller başarısız?**
1. Push Notifications capability kapalıysa → Xcode'da açın
2. Xcode console'da loglar görünmüyorsa → AppDelegate.swift'i kontrol edin
3. Firestore'da `fcmToken` yoksa → FCM token alınamamış, console'u kontrol edin
4. Firestore'da `platform` yoksa veya "unknown" ise → Platform bilgisi kaydedilmemiş

---

## 🔧 Sorun Giderme

### Sorun 1: Push Notifications Capability Kapalı
**Çözüm:** Xcode → Runner target → Signing & Capabilities → "+ Capability" → "Push Notifications"

### Sorun 2: FCM Token Alınamıyor
**Kontrol:**
- APNs token alındı mı? (Xcode console)
- Firebase Messaging delegate ayarlandı mı?
- GoogleService-Info.plist doğru mu?

### Sorun 3: Platform "unknown" Görünüyor
**Çözüm:**
- Uygulamayı kapatıp açın
- Giriş yapın
- 10-15 saniye bekleyin
- Firestore'da kontrol edin

### Sorun 4: Push Notification Gelmiyor
**Kontrol:**
- Push Notifications capability açık mı?
- Bildirim izni verildi mi? (iOS Settings)
- FCM token Firestore'da var mı?
- Test notification gönderildi mi?

---

## ✅ Özet

**Yapmanız gerekenler:**
1. ✅ Tüm kontrolleri yapın (yukarıdaki checklist)
2. ✅ Xcode console'da logları kontrol edin
3. ✅ Firestore'da `fcmToken` ve `platform: "ios"` kontrol edin
4. ✅ Test push notification gönderin

**Tüm kontroller geçtiyse → iOS push notification sistemi çalışıyor! 🎉**





























