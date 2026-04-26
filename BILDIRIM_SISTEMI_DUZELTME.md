# 🔔 Bildirim Sistemi Düzeltme Rehberi

## ✅ Yapılan Düzeltmeler

### 1. Cloud Functions Düzeltmeleri

#### `onNewAnimalPostCreated` Fonksiyonu
- **Sorun**: "unknown" platform'u olan kullanıcılara bildirim gönderilmiyordu
- **Çözüm**: "unknown" platform'u olan kullanıcılar için her iki platforma da bildirim gönderiliyor (geriye dönük uyumluluk)
- **Dosya**: `functions/src/index.ts` (satır 740-748)

#### `onConversationMessageCreated` Fonksiyonu
- **Durum**: ✅ Zaten doğru çalışıyor
- **Özellikler**:
  - Token validation
  - Platform kontrolü
  - Detaylı error handling
  - Geçersiz token temizleme

### 2. Flutter Tarafı Düzeltmeleri

#### FCM Token Yönetimi
- **Durum**: ✅ Zaten doğru çalışıyor
- **Özellikler**:
  - iOS için platform="ios" kesin olarak kaydediliyor
  - Android için platform="android" kesin olarak kaydediliyor
  - "unknown" platform düzeltme mekanizması var
  - Token refresh listener aktif

#### Bildirim Handler'ları
- **Durum**: ✅ Zaten doğru çalışıyor
- **Özellikler**:
  - Foreground notification handling (iOS ve Android)
  - Background notification handling (iOS ve Android)
  - Terminated state notification handling (iOS ve Android)
  - Local notification gösterimi

## 🚀 Deploy Adımları

### Adım 1: Cloud Functions'ı Deploy Et

**ÖNEMLİ**: Cloud Functions'ı deploy etmeden bildirimler çalışmaz!

```bash
# Terminal'de proje root klasöründe:
./deploy_functions.sh

# Veya manuel olarak:
cd functions
npm install
npm run build
firebase deploy --only functions
```

### Adım 2: Deploy Kontrolü

Firebase Console'da kontrol edin:
1. **Firebase Console** → **Functions**
2. Şu fonksiyonların **Active** olduğunu kontrol edin:
   - `onConversationMessageCreated`
   - `onNewAnimalPostCreated`
   - `sendMessageNotificationCallable`

### Adım 3: Test

#### Test 1: Mesaj Bildirimi
1. İki farklı cihazda (veya simülatörde) uygulamayı açın
2. Bir cihazdan diğerine mesaj gönderin
3. Alıcı cihazda bildirim görünmeli

#### Test 2: Yeni İlan Bildirimi
1. Bir cihazdan yeni bir ilan ekleyin
2. Diğer tüm cihazlarda "Yeni ilan eklendi" bildirimi görünmeli

#### Test 3: Log Kontrolü
1. **Firebase Console** → **Functions** → **Logs**
2. Bildirim gönderme loglarını kontrol edin:
   - `📨 Yeni mesaj (alt koleksiyon)`
   - `🆕 Yeni ilan eklendi`
   - `✅ Bildirim başarıyla gönderildi`

## 🔍 Sorun Giderme

### Sorun 1: "Bildirimler hala gelmiyor"

**Kontrol Listesi**:
1. ✅ Cloud Functions deploy edildi mi?
   ```bash
   firebase functions:list
   ```
2. ✅ FCM token'lar Firestore'a kaydediliyor mu?
   - Firebase Console → Firestore → `users` koleksiyonu
   - Kullanıcı dokümanında `fcmToken` alanı var mı?
   - `platform` alanı "ios" veya "android" mi?
3. ✅ Bildirim izinleri verilmiş mi?
   - iOS: Ayarlar → CanlıPazar → Bildirimler
   - Android: Ayarlar → Uygulamalar → CanlıPazar → Bildirimler
4. ✅ Cloud Functions loglarında hata var mı?
   - Firebase Console → Functions → Logs

### Sorun 2: "iOS'ta bildirimler gelmiyor"

**Kontrol Listesi**:
1. ✅ APNs key Firebase'e yüklü mü?
   - Firebase Console → Project Settings → Cloud Messaging → iOS app configuration
2. ✅ Bundle ID doğru mu?
   - Firebase Console: `com.canlipazar.app`
   - Xcode: Target → General → Bundle Identifier
3. ✅ Push Notifications capability ekli mi?
   - Xcode → Target → Signing & Capabilities → Push Notifications
4. ✅ Background Modes → Remote notifications işaretli mi?
   - Xcode → Target → Signing & Capabilities → Background Modes
5. ✅ Gerçek cihazda test ediliyor mu?
   - iOS Simulator'da push notification çalışmaz!

### Sorun 3: "Android'de bildirimler gelmiyor"

**Kontrol Listesi**:
1. ✅ Notification channel'lar oluşturulmuş mu?
   - `messages_channel` (Importance.max)
   - `new_posts_channel` (Importance.max)
2. ✅ Android 13+ notification permission verilmiş mi?
   - Ayarlar → Uygulamalar → CanlıPazar → Bildirimler
3. ✅ FCM token Firestore'a kaydediliyor mu?
   - Firebase Console → Firestore → `users` koleksiyonu
   - `platform` = "android" olmalı

### Sorun 4: "Cloud Functions deploy hatası"

**Çözüm**:
```bash
# Functions klasörüne git
cd functions

# Node modules'u temizle ve yeniden yükle
rm -rf node_modules package-lock.json
npm install

# TypeScript build
npm run build

# Deploy
firebase deploy --only functions
```

## 📊 Başarı Kriterleri

Bildirim sistemi başarılı sayılır eğer:
- ✅ Mesaj gönderildiğinde alıcıya bildirim gidiyor
- ✅ Yeni ilan eklendiğinde tüm kullanıcılara bildirim gidiyor
- ✅ Foreground'da bildirim görünüyor
- ✅ Background'da bildirim görünüyor
- ✅ Terminated state'de bildirim görünüyor
- ✅ Bildirime tıklayınca uygulama açılıyor

## 🎯 Sonraki Adımlar

1. ✅ Cloud Functions'ı deploy edin
2. ⏳ Test edin (mesaj ve ilan bildirimleri)
3. ⏳ Logları kontrol edin
4. ⏳ Sorun varsa yukarıdaki sorun giderme adımlarını takip edin

---

**Not**: Cloud Functions'ı deploy etmeden bildirimler çalışmaz! Mutlaka deploy edin!









