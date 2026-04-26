# 🧪 iOS FCM - Test Rehberi

## 📋 Test Adımları

### 1. Ön Hazırlık

```bash
# 1. Temizlik
flutter clean

# 2. Paketleri yükle
flutter pub get

# 3. iOS pod'ları yükle
cd ios && pod install && cd ..

# 4. Build
flutter build ios
```

---

### 2. Xcode Yapılandırması Kontrolü

#### A. Capabilities Kontrolü
1. Xcode'da `ios/Runner.xcworkspace` açın
2. **Runner** target'ını seçin
3. **Signing & Capabilities** sekmesine gidin
4. Kontrol edin:
   - ✅ **Push Notifications** capability eklendi mi?
   - ✅ **Background Modes** capability eklendi mi?
   - ✅ **Background Modes** → **Remote notifications** işaretli mi?

#### B. Entitlements Kontrolü
1. **Signing & Capabilities** sekmesinde
2. **Entitlements** dosyası görünüyor mu?
3. `Runner.entitlements` dosyasını açın
4. Kontrol edin:
   - ✅ `aps-environment` = `production` mu?

#### C. Bundle ID Kontrolü
1. **Signing & Capabilities** sekmesinde
2. **Bundle Identifier** doğru mu? (örn: `com.canlipazar.app`)
3. Firebase Console'daki Bundle ID ile eşleşiyor mu?

---

### 3. Uygulamayı Çalıştırma

```bash
# iOS cihazda çalıştır
flutter run

# Veya Xcode'dan çalıştır
# Xcode → Product → Run (⌘R)
```

---

### 4. Test Senaryoları

### Test 1: İlk Giriş - Token Kaydı

**Adımlar:**
1. Uygulamayı aç
2. Giriş yap (veya kayıt ol)
3. Notification permission isteğini **KABUL ET**
4. Console log'larını kontrol et

**Beklenen Log'lar:**
```
🔄 UserProvider: Kullanıcı giriş yaptı, FCM token kaydı başlatılıyor...
🔄 FCMTokenManager: Token kaydı başlatılıyor...
✅ FCMTokenManager: Kullanıcı giriş yapmış, userId: {userID}
✅ FCMTokenManager: FCM token alındı: {token}...
✅ FCMTokenManager: Platform belirlendi: ios
✅ FCMTokenManager: Token Firestore'a kaydedildi
✅ UserProvider: FCM token kaydı tamamlandı
```

**Firestore Kontrolü:**
1. Firebase Console → Firestore → `users/{userID}`
2. Kontrol et:
   - ✅ `fcmToken` alanı var mı ve dolu mu?
   - ✅ `platform` alanı var mı ve değeri `ios` mu?
   - ✅ `fcmTokenUpdatedAt` timestamp var mı?

---

### Test 2: Uygulama Yeniden Açılıyor - Token Kontrolü

**Adımlar:**
1. Uygulamayı kapat (background'dan kaldır)
2. Uygulamayı tekrar aç (kullanıcı zaten giriş yapmış)
3. 2-3 saniye bekle
4. Console log'larını kontrol et

**Beklenen Log'lar:**
```
🔄 _checkAndSaveFCMTokenOnAppStart: Kullanıcı giriş yapmış, FCM token kontrolü yapılıyor...
✅ _checkAndSaveFCMTokenOnAppStart: Token ve platform zaten mevcut (token: {token}..., platform: ios)
```

**Firestore Kontrolü:**
- Token hala var mı kontrol et

---

### Test 3: Token Eksik - Otomatik Kayıt

**Adımlar:**
1. Firebase Console → Firestore → `users/{userID}`
2. `fcmToken` alanını manuel olarak **SİL**
3. Uygulamayı yeniden başlat
4. 2-3 saniye bekle
5. Console log'larını kontrol et

**Beklenen Log'lar:**
```
🔄 _checkAndSaveFCMTokenOnAppStart: Kullanıcı giriş yapmış, FCM token kontrolü yapılıyor...
⚠️ _checkAndSaveFCMTokenOnAppStart: Token veya platform eksik, kaydediliyor...
🔄 FCMTokenManager: Token kaydı başlatılıyor...
✅ FCMTokenManager: FCM token alındı: {token}...
✅ FCMTokenManager: Platform belirlendi: ios
✅ FCMTokenManager: Token Firestore'a kaydedildi
✅ _checkAndSaveFCMTokenOnAppStart: FCM token başarıyla kaydedildi
```

**Firestore Kontrolü:**
- Token tekrar kaydedildi mi kontrol et

---

### Test 4: Notification Permission Kontrolü

**Adımlar:**
1. iOS Ayarlar → CanlıPazar → Bildirimler
2. Bildirimleri **KAPAT**
3. Uygulamayı yeniden başlat
4. Console log'larını kontrol et

**Beklenen Log'lar:**
```
⚠️ FCMTokenManager: Bildirim izni verilmemiş (denied)
⚠️ FCMTokenManager: Token kaydı başarısız
```

**Not:** Permission verilmeden token alınamaz!

---

### Test 5: Test Bildirimi Gönderme

**Adımlar:**
1. Firebase Console → Cloud Messaging → **Send test message**
2. FCM token'ı girin (Firestore'dan alın)
3. Başlık ve mesaj yazın
4. **Test** butonuna tıklayın

**Beklenen:**
- ✅ iOS cihazda bildirim görünmeli
- ✅ Bildirime tıklayınca uygulama açılmalı

---

### Test 6: Cloud Functions Bildirimi

**Adımlar:**
1. Başka bir kullanıcıdan mesaj gönder
2. Console log'larını kontrol et
3. iOS cihazda bildirim gelmeli

**Beklenen:**
- ✅ Bildirim iOS cihazda görünmeli
- ✅ Badge sayısı güncellenmeli
- ✅ Bildirime tıklayınca mesaj ekranı açılmalı

---

## 🔍 Sorun Giderme

### Sorun 1: Token Kaydedilmiyor

**Kontrol Listesi:**
1. ✅ Notification permission verilmiş mi?
2. ✅ Kullanıcı giriş yapmış mı?
3. ✅ Firestore security rules doğru mu?
4. ✅ Console log'larında hata var mı?

**Çözüm:**
```dart
// Console log'larını kontrol et:
// ❌ FCMTokenManager: Bildirim izni verilmemiş
// ❌ FCMTokenManager: FCM token alınamadı
// ❌ FCMTokenManager: Token Firestore'a kaydedilemedi
```

---

### Sorun 2: Platform "unknown" Olarak Kaydediliyor

**Kontrol:**
```dart
// FCMTokenManager içinde _getPlatform() method'u:
if (io.Platform.isIOS) {
  return 'ios'; // ✅ Doğru
}
```

**Çözüm:**
- Import kontrolü: `import 'dart:io' ...`
- Platform detection doğru çalışıyor mu?

---

### Sorun 3: Bildirim Gelmiyor

**Kontrol Listesi:**
1. ✅ APNs Authentication Key yüklü mü?
2. ✅ Bundle ID eşleşiyor mu?
3. ✅ Entitlements doğru mu?
4. ✅ FCM token geçerli mi?
5. ✅ Cloud Functions log'larında hata var mı?

**Çözüm:**
- Firebase Console → Cloud Messaging → APNs Authentication Key kontrol et
- Xcode → Capabilities → Push Notifications kontrol et
- Cloud Functions log'larını kontrol et

---

### Sorun 4: Token Yenilenmiyor

**Kontrol:**
```dart
// FCMTokenManager içinde _setupTokenRefreshListener() çalışıyor mu?
_messaging.onTokenRefresh.listen((String newToken) async {
  // Token yenilendiğinde çağrılmalı
});
```

**Çözüm:**
- Token refresh listener doğru çalışıyor mu?
- Console log'larında "Token yenilendi" mesajı var mı?

---

## 📊 Başarı Kriterleri

### ✅ Token Kaydı Başarılı:
- Firestore'da `fcmToken` alanı var ve dolu
- Firestore'da `platform` alanı var ve değeri `ios`
- Console log'larında başarı mesajları var

### ✅ Bildirim Çalışıyor:
- Test bildirimi iOS cihazda görünüyor
- Cloud Functions bildirimi iOS cihazda görünüyor
- Bildirime tıklayınca uygulama açılıyor

### ✅ Token Yenileme Çalışıyor:
- Token yenilendiğinde Firestore'da güncelleniyor
- Console log'larında "Token yenilendi" mesajı var

---

## 🎯 Test Sonucu

### Başarılı Test:
- ✅ Tüm test senaryoları geçti
- ✅ Token Firestore'a kaydedildi
- ✅ Bildirimler çalışıyor
- ✅ Token yenileme çalışıyor

### Başarısız Test:
- ❌ Hangi test başarısız?
- ❌ Console log'larında hangi hata var?
- ❌ Firestore'da token var mı?
- ❌ Notification permission verilmiş mi?

---

**Test sonuçlarını not edin ve sorun varsa log'ları paylaşın!** 📝





























