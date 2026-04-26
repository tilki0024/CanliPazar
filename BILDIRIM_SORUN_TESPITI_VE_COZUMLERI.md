# iOS Push Notification Sorun Tespiti ve Çözümleri

## 🔍 Tespit Edilen Sorunlar

### 1. ✅ DOĞRU OLANLAR

#### main.dart
- ✅ Firebase Messaging import edilmiş
- ✅ Background message handler ayarlanmış
- ✅ FCMService initialize ediliyor
- ✅ Notification permissions isteniyor
- ✅ Local notifications setup edilmiş

#### AppDelegate.swift
- ✅ Firebase, FirebaseMessaging, FirebaseFirestore, FirebaseAuth import edilmiş
- ✅ Messaging.messaging().delegate = self ayarlanmış
- ✅ UNUserNotificationCenter.current().delegate = self ayarlanmış
- ✅ requestPushAuthorization() çağrılıyor
- ✅ registerForRemoteNotifications() çağrılıyor
- ✅ didRegisterForRemoteNotificationsWithDeviceToken içinde APNs token FCM'e veriliyor
- ✅ saveTokenToFirestore() fonksiyonu mevcut ve çalışıyor
- ✅ messaging(_:didReceiveRegistrationToken:) içinde token Firestore'a kaydediliyor

#### Info.plist
- ✅ UIBackgroundModes içinde remote-notification var
- ✅ FirebaseAppDelegateProxyEnabled = false (manuel yapılandırma için doğru)

#### GoogleService-Info.plist
- ✅ Dosya mevcut ve doğru konumda
- ✅ Bundle ID doğru: com.canlipazar.app
- ✅ Project ID doğru: canlipazar-b3697

#### Entitlements
- ✅ Runner.entitlements mevcut (production)
- ✅ Runner-Debug.entitlements mevcut (development)
- ✅ CODE_SIGN_ENTITLEMENTS project.pbxproj'de ayarlanmış

#### Cloud Functions
- ✅ onMessageCreated function'ı mevcut ve deploy edilmiş
- ✅ conversations koleksiyonunu dinliyor
- ✅ Token kontrolü yapılıyor
- ✅ iOS APNs payload'ı doğru

#### Flutter Token Service
- ✅ FCMTokenService mevcut ve çalışıyor
- ✅ UserProvider'da auth state değişikliğinde token kaydediliyor
- ✅ AuthMethods'da signup/login sonrası token kaydediliyor

### 2. ⚠️ SORUNLAR VE ÇÖZÜMLER

#### SORUN 1: Runner.entitlements'te aps-environment = "development"
**Dosya:** `ios/Runner/Runner.entitlements`
**Sorun:** Production build için `production` olmalı
**Çözüm:** Production build için `production` yapılmalı (Debug için development doğru)

#### SORUN 2: project.pbxproj'de SystemCapabilities eksik
**Dosya:** `ios/Runner.xcodeproj/project.pbxproj`
**Sorun:** Push Notifications ve Background Modes capability'leri Xcode proje dosyasında tanımlı değil
**Çözüm:** Xcode'da manuel olarak eklenmeli (project.pbxproj otomatik düzenlenemez)

#### SORUN 3: AppDelegate.swift'te didRegisterForRemoteNotificationsWithDeviceToken içinde token Firestore'a kaydedilmiyor
**Dosya:** `ios/Runner/AppDelegate.swift`
**Sorun:** APNs token alındığında FCM token henüz hazır olmayabilir
**Çözüm:** FCM token'ı ayrı bir fonksiyonda kontrol edip kaydetmek daha iyi (zaten yapılmış)

#### SORUN 4: Cloud Functions'ta token kontrolü iyileştirilebilir
**Dosya:** `functions/src/index.ts`
**Durum:** Token kontrolü var ama daha detaylı hata log'ları eklenebilir

## 🔧 YAPILMASI GEREKEN DÜZELTMELER

### 1. Runner.entitlements'i Production için düzelt
```xml
<key>aps-environment</key>
<string>production</string>
```

### 2. Xcode'da Capability Ekleme (Manuel)
1. Xcode'da `ios/Runner.xcworkspace` açın
2. Runner target > Signing & Capabilities
3. + Capability > Push Notifications
4. + Capability > Background Modes > Remote notifications işaretleyin

### 3. Cloud Functions'ı yeniden deploy et
```bash
cd functions
npm run build
firebase deploy --only functions:onMessageCreated
```

### 4. Token Kontrolü
- Firestore'da `users/{userId}/fcmToken` alanının dolu olduğunu kontrol edin
- Xcode Console'da token log'larını kontrol edin

## 📋 KONTROL LİSTESİ

### iOS Native Tarafı
- [ ] AppDelegate.swift'te tüm delegate'ler ayarlanmış
- [ ] Token Firestore'a kaydediliyor
- [ ] APNs token FCM'e veriliyor
- [ ] Info.plist'te UIBackgroundModes doğru
- [ ] Entitlements dosyaları mevcut
- [ ] Xcode'da Push Notifications capability eklendi (MANUEL)
- [ ] Xcode'da Background Modes capability eklendi (MANUEL)

### Flutter Tarafı
- [ ] main.dart'ta FCM initialize ediliyor
- [ ] Background handler ayarlanmış
- [ ] FCMTokenService çalışıyor
- [ ] UserProvider'da token kaydı yapılıyor
- [ ] AuthMethods'da token kaydı yapılıyor

### Cloud Functions
- [ ] onMessageCreated function'ı deploy edilmiş
- [ ] Token kontrolü yapılıyor
- [ ] iOS APNs payload'ı doğru
- [ ] Hata log'ları yeterli

### Firebase Konfigürasyonu
- [ ] GoogleService-Info.plist doğru konumda
- [ ] Bundle ID eşleşiyor
- [ ] APNs sertifikası Firebase Console'a yüklenmiş (KONTROL ET)

## 🚨 EN YAYGIN SORUNLAR

### 1. Token Firestore'a Kaydedilmiyor
**Neden:**
- Firebase Auth kullanıcısı giriş yapmamış
- AppDelegate.swift'te getCurrentUserId() null dönüyor

**Çözüm:**
- Uygulamayı açın ve giriş yapın
- Xcode Console'da "Kullanıcı ID bulunamadı" mesajını kontrol edin
- Firebase Auth kullanıcısının giriş yaptığından emin olun

### 2. Cloud Function Tetiklenmiyor
**Neden:**
- Function deploy edilmemiş
- Mesajlar yanlış koleksiyona kaydediliyor

**Çözüm:**
- `firebase functions:list` ile function'ın deploy edildiğini kontrol edin
- Mesajların `conversations` koleksiyonuna kaydedildiğini kontrol edin

### 3. Bildirim Gelmiyor
**Neden:**
- Token geçersiz veya boş
- APNs sertifikası yüklenmemiş
- Capability ayarları eksik

**Çözüm:**
- Firestore'da token'ın geçerli olduğunu kontrol edin (150+ karakter)
- Firebase Console > Cloud Messaging > APNs sertifikasını kontrol edin
- Xcode'da capability'leri ekleyin

### 4. iOS Capability Ayarları Eksik
**Neden:**
- Xcode'da manuel olarak eklenmemiş

**Çözüm:**
- Xcode'da Runner target > Signing & Capabilities
- Push Notifications ve Background Modes ekleyin

## 🔍 DEBUG ADIMLARI

### 1. Token Kontrolü
```bash
# Firestore Console'da kontrol edin:
# users/{userId}/fcmToken alanının dolu olduğundan emin olun
```

### 2. Cloud Functions Log
```bash
cd functions
firebase functions:log --only onMessageCreated
```

### 3. iOS Console Log
- Xcode'da Console'u açın
- "FCM token" veya "Firestore'a kaydedildi" mesajlarını kontrol edin

### 4. Test Bildirimi
```bash
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP \
  -H "Content-Type: application/json" \
  -d '{"userId": "YOUR_USER_ID", "message": "TEST"}'
```








