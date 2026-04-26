# 📱 FCM Token ve Platform Kayıt Rehberi

**Durum:** ✅ Yeni `FCMTokenManager` servisi oluşturuldu ve entegre edildi

---

## 🎯 SORUN

Firestore Database'deki kullanıcı dokümanlarında **eksik alanlar:**
- ❌ `fcmToken`: Cihazın benzersiz bildirim jetonu alanı **yok**
- ❌ `platform`: Cihazın platformunu belirten (`ios` veya `android`) alan **yok**

---

## ✅ ÇÖZÜM

Yeni **`FCMTokenManager`** servisi oluşturuldu. Bu servis:

1. ✅ FCM token'ı alır (`FirebaseMessaging.instance.getToken()`)
2. ✅ Platform bilgisini belirler (`Platform.isIOS` / `Platform.isAndroid`)
3. ✅ Token'ı ve platform bilgisini Firestore'a kaydeder (`users/{userID}`)
4. ✅ Token yenilendiğinde otomatik günceller
5. ✅ Kullanıcı giriş yapmadan önce token alınırsa geçici olarak saklar

---

## 📁 OLUŞTURULAN DOSYA

**Dosya:** `lib/services/fcm_token_manager.dart`

**Özellikler:**
- ✅ Retry mekanizması (3 deneme)
- ✅ Platform tespiti (iOS/Android/Web)
- ✅ Geçici token saklama (kullanıcı giriş yapmadan önce)
- ✅ Token yenilendiğinde otomatik güncelleme
- ✅ Kullanıcı çıkış yaptığında token silme

---

## 🔧 ENTEGRASYON

### 1. ✅ UserProvider Güncellendi

**Dosya:** `lib/providers/user_provider.dart`

**Değişiklikler:**
- Kullanıcı giriş yaptığında `FCMTokenManager().saveTokenToFirestore()` çağrılıyor
- Kullanıcı çıkış yaptığında `FCMTokenManager().deleteToken()` çağrılıyor
- Geçici token kontrolü eklendi

**Kod:**
```dart
// Kullanıcı giriş yaptığında
final fcmManager = FCMTokenManager();
await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
await fcmManager.saveTokenToFirestore(forceRetry: true);
```

---

### 2. ✅ AuthMethods Güncellendi

**Dosya:** `lib/resources/auth_methods.dart`

**Değişiklikler:**
- Signup (kayıt) sonrası token kaydı
- Login (giriş) sonrası token kaydı
- Token doğrulama eklendi

**Kod:**
```dart
// Signup sonrası
final fcmManager = FCMTokenManager();
await fcmManager.checkAndSavePendingToken();
final success = await fcmManager.saveTokenToFirestore(forceRetry: true);
```

---

## 📋 KULLANIM

### Otomatik Kullanım

Token kaydı **otomatik** olarak şu durumlarda yapılır:

1. ✅ **Kullanıcı giriş yaptığında** (`UserProvider` - `authStateChanges`)
2. ✅ **Kullanıcı kayıt olduğunda** (`AuthMethods` - `signUpUser`)
3. ✅ **Kullanıcı login olduğunda** (`AuthMethods` - `loginUser`)
4. ✅ **Uygulama başladığında** (kullanıcı zaten giriş yapmışsa)
5. ✅ **Token yenilendiğinde** (otomatik - `onTokenRefresh`)

### Manuel Kullanım

Eğer manuel olarak token kaydetmek istersen:

```dart
import 'package:animal_trade/services/fcm_token_manager.dart';

// Token'ı kaydet
final fcmManager = FCMTokenManager();
await fcmManager.saveTokenToFirestore(forceRetry: true);

// Geçici token varsa kaydet
await fcmManager.checkAndSavePendingToken();

// Token'ı sil (kullanıcı çıkış yaptığında)
await fcmManager.deleteToken();
```

---

## 🧪 TEST

### 1. Kullanıcı Giriş Yaptığında

**Beklenen:**
1. Kullanıcı giriş yapar
2. Xcode/Android Studio console'da şu loglar görünür:
   ```
   🔄 UserProvider: Kullanıcı giriş yaptı, FCM token kaydı başlatılıyor...
   🔄 FCMTokenManager: Token kaydı başlatılıyor...
   ✅ FCMTokenManager: Kullanıcı giriş yapmış, userId: {userId}
   ✅ FCMTokenManager: FCM token alındı: {token}...
   ✅ FCMTokenManager: Platform belirlendi: ios (veya android)
   ✅ FCMTokenManager: Token Firestore'a kaydedildi
   ✅ UserProvider: FCM token kaydı tamamlandı
   ```

3. Firestore'da `users/{userId}` dokümanında:
   - ✅ `fcmToken`: Token değeri var
   - ✅ `platform`: `ios` veya `android` var
   - ✅ `fcmTokenUpdatedAt`: Timestamp var

---

### 2. Token Yenilendiğinde

**Beklenen:**
1. Token otomatik yenilenir (iOS/Android tarafından)
2. `onTokenRefresh` callback'i tetiklenir
3. Yeni token otomatik olarak Firestore'a kaydedilir

---

### 3. Kullanıcı Çıkış Yaptığında

**Beklenen:**
1. Kullanıcı çıkış yapar
2. Token Firestore'dan silinir
3. Geçici token (varsa) temizlenir

---

## 🔍 FİRESTORE KONTROLÜ

### Firestore'da Kontrol Et

1. Firebase Console'a git
2. Firestore Database > `users` koleksiyonuna git
3. Bir kullanıcı dokümanını aç
4. Şu alanların olduğunu kontrol et:
   - ✅ `fcmToken`: String (token değeri)
   - ✅ `platform`: String (`ios` veya `android`)
   - ✅ `fcmTokenUpdatedAt`: Timestamp

**Örnek Doküman:**
```json
{
  "uid": "user123",
  "username": "testuser",
  "email": "test@example.com",
  "fcmToken": "dK8xYz2...", // ✅ VAR
  "platform": "ios", // ✅ VAR
  "fcmTokenUpdatedAt": "2024-01-01T12:00:00Z" // ✅ VAR
}
```

---

## ⚠️ SORUN GİDERME

### Token Kaydedilmiyor

**Kontrol Listesi:**
1. ✅ Kullanıcı giriş yapmış mı? (`FirebaseAuth.instance.currentUser != null`)
2. ✅ Bildirim izni verilmiş mi? (`AuthorizationStatus.authorized` veya `provisional`)
3. ✅ FCM token alınabiliyor mu? (`FirebaseMessaging.instance.getToken()`)
4. ✅ Firestore'a yazma izni var mı? (Firestore rules kontrolü)

**Log Kontrolü:**
Xcode/Android Studio console'da şu logları ara:
- `🔄 FCMTokenManager: Token kaydı başlatılıyor...`
- `✅ FCMTokenManager: FCM token alındı`
- `✅ FCMTokenManager: Token Firestore'a kaydedildi`

---

### Platform Bilgisi Yanlış

**Kontrol:**
- iOS cihazda `platform: "ios"` olmalı
- Android cihazda `platform: "android"` olmalı

**Eğer yanlışsa:**
- `_getPlatform()` metodunu kontrol et
- Platform detection doğru çalışıyor mu?

---

### Token Yenilenmiyor

**Kontrol:**
- `_setupTokenRefreshListener()` çağrılıyor mu?
- `onTokenRefresh` listener aktif mi?

**Log Kontrolü:**
- `🔄 FCMTokenManager: Token yenilendi` logu görünüyor mu?

---

## 📊 ÖZET

### ✅ Yapılanlar

1. ✅ Yeni `FCMTokenManager` servisi oluşturuldu
2. ✅ `UserProvider` güncellendi
3. ✅ `AuthMethods` güncellendi
4. ✅ Retry mekanizması eklendi
5. ✅ Platform tespiti eklendi
6. ✅ Geçici token saklama eklendi
7. ✅ Token yenilendiğinde otomatik güncelleme eklendi

### 🎯 Sonuç

Artık kullanıcı giriş yaptığında veya uygulama başladığında:
- ✅ FCM token otomatik alınır
- ✅ Platform bilgisi otomatik belirlenir
- ✅ Her ikisi de Firestore'a kaydedilir
- ✅ Token yenilendiğinde otomatik güncellenir

**Firestore'da `fcmToken` ve `platform` alanları artık otomatik olarak doldurulacak!**

---

**Not:** Bu servis mevcut `FCMTokenService` ile birlikte çalışır. İkisi de aynı işi yapar ama `FCMTokenManager` daha güvenilir ve basit bir API sunar.





























