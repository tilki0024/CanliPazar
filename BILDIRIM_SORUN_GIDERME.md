# Bildirim Sorun Giderme Rehberi

## 🔍 Sorun Tespiti

Bildirimler çalışmıyorsa aşağıdaki adımları kontrol edin:

### 1. Token Firestore'a Kaydediliyor mu?

**Kontrol:**
```bash
# Firestore Console'da kontrol edin:
# users/{userId}/fcmToken alanının dolu olduğundan emin olun
```

**Çözüm:**
- Uygulamayı açın ve giriş yapın
- Xcode Console'da "FCM token Firestore'a kaydedildi" mesajını kontrol edin
- Eğer kaydedilmiyorsa, Firebase Auth kullanıcısının giriş yaptığından emin olun

### 2. Cloud Function Çalışıyor mu?

**Kontrol:**
```bash
cd functions
firebase functions:log --only onMessageCreated
```

**Çözüm:**
- Function deploy edilmiş mi kontrol edin: `firebase functions:list`
- Eğer deploy edilmemişse: `firebase deploy --only functions:onMessageCreated`
- Log'larda hata var mı kontrol edin

### 3. iOS Capability Ayarları

**Kontrol:**
- Xcode'da `Runner` target > `Signing & Capabilities`
- `Push Notifications` capability'si ekli mi?
- `Background Modes` > `Remote notifications` işaretli mi?

**Çözüm:**
- Xcode'da manuel olarak ekleyin (project.pbxproj otomatik düzenlenemez)

### 4. Bildirim İzni

**Kontrol:**
- iOS Ayarlar > Bildirimler > CanlıPazar
- Bildirimler açık mı?

**Çözüm:**
- Uygulamayı açın ve bildirim izni verin
- Eğer reddedildiyse, iOS Ayarlar'dan manuel olarak açın

### 5. APNs Sertifikası

**Kontrol:**
- Firebase Console > Project Settings > Cloud Messaging
- APNs Authentication Key veya Certificate yüklü mü?

**Çözüm:**
- APNs sertifikasını Firebase Console'a yükleyin
- Production ve Development sertifikalarını kontrol edin

### 6. Test Bildirimi

**Test:**
```bash
# Cloud Functions test endpoint'i kullan
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP \
  -H "Content-Type: application/json" \
  -d '{"userId": "YOUR_USER_ID", "message": "TEST BİLDİRİMİ"}'
```

## 📋 Kontrol Listesi

- [ ] Token Firestore'a kaydediliyor (`users/{userId}/fcmToken`)
- [ ] Cloud Function deploy edilmiş (`onMessageCreated`)
- [ ] iOS Capability ayarları yapılmış (Push Notifications, Background Modes)
- [ ] Bildirim izni verilmiş
- [ ] APNs sertifikası Firebase'e yüklenmiş
- [ ] Mesajlar `conversations` koleksiyonuna kaydediliyor
- [ ] Alıcının FCM token'ı geçerli (150+ karakter)

## 🚀 Hızlı Çözüm

1. **Cloud Functions Deploy:**
```bash
cd functions
npm run build
firebase deploy --only functions:onMessageCreated
```

2. **Token Kontrolü:**
- Uygulamayı açın
- Xcode Console'da token log'larını kontrol edin
- Firestore'da token'ın kaydedildiğini doğrulayın

3. **Test:**
- İki farklı kullanıcı ile mesaj gönderin
- Bildirimin geldiğini kontrol edin

## 📞 Destek

Sorun devam ederse:
1. Xcode Console log'larını kontrol edin
2. Cloud Functions log'larını kontrol edin
3. Firestore'da token'ın kaydedildiğini doğrulayın
4. APNs sertifikasının doğru yüklendiğini kontrol edin








