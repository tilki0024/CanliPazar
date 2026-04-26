# 🔍 Bildirim Debug Rehberi

## 📋 Debug Logları Eklendi

### 1️⃣ Flutter Tarafı (message_screen.dart)

**Eklenen Loglar:**
```dart
🔵 [DEBUG] Mesaj Firestore'a ekleniyor...
   - conversationId: ...
   - sender: ...
   - recipient: ...
   - text: ...
   - messageData keys: ...

✅ [DEBUG] Mesaj alt koleksiyona eklendi: [messageId]
✅ [DEBUG] Cloud Functions trigger tetiklenmeli: conversations/[conversationId]/messages/[messageId]

✅ [DEBUG] Mesaj Firestore'da mevcut, trigger tetiklenmiş olmalı
   - sender: ...
   - recipient: ...
   - timestamp: ...
```

**Kontrol Edilecekler:**
- ✅ Mesaj Firestore'a kaydediliyor mu?
- ✅ conversationId doğru mu?
- ✅ sender ve recipient doğru mu?
- ✅ Mesaj 2 saniye sonra hala Firestore'da mı?

---

### 2️⃣ Cloud Functions Tarafı (index.ts)

**Eklenen Loglar:**

#### A) Trigger Tetiklenme
```
🔵 [DEBUG] ========================================
🔵 [DEBUG] onConversationMessageCreated TRİGGER TETİKLENDİ
🔵 [DEBUG] ========================================
📨 Yeni mesaj (alt koleksiyon): [messageId] - Conversation: [conversationId]
   - Gönderen: [senderId]
   - Alıcı: [recipientId]
   - Mesaj metni: ...
   - postId: ...
   - isRead: ...
```

#### B) Alıcı Bilgileri
```
🔵 [DEBUG] Alıcı bilgileri alındı:
   - recipientId: ...
   - fcmToken: ... (ilk 20 karakter)
   - platform: ...
   - messageNotificationsEnabled: ...
```

#### C) Token Validation
```
🔵 [DEBUG] Token validation yapılıyor...
   - Token uzunluğu: ... karakter
   - Token (ilk 30 karakter): ...

✅ [DEBUG] Token validation başarılı
```

#### D) Bildirim Gönderimi
```
🔵 [DEBUG] admin.messaging().send() çağrılıyor...
✅ [onConversationMessageCreated] Bildirim başarıyla gönderildi: [messageId]
✅ Alıcı: ..., Platform: ...
✅ Token: ...
✅ MessageId: ...
🔵 [DEBUG] ========================================
🔵 [DEBUG] BİLDİRİM BAŞARIYLA GÖNDERİLDİ
🔵 [DEBUG] ========================================
```

#### E) Hata Durumları
```
🔴 [DEBUG] ========================================
🔴 [DEBUG] BİLDİRİM GÖNDERME HATASI
🔴 [DEBUG] ========================================
❌ [onConversationMessageCreated] Bildirim gönderme hatası:
   - Hata kodu: ...
   - Hata mesajı: ...
   - Alıcı ID: ...
   - Platform: ...
   - Token (ilk 30 karakter): ...
   - Token uzunluğu: ... karakter
   - Stack trace: ...
```

---

## 🔍 Sorun Tespit Adımları

### Adım 1: Flutter Loglarını Kontrol Et

**Beklenen Loglar:**
```
💬 MESAJ GÖNDERİLİYOR:
→ Gönderen (sender): [senderId]
→ Alıcı (recipient): [recipientId]

🔵 [DEBUG] Mesaj Firestore'a ekleniyor...
✅ [DEBUG] Mesaj alt koleksiyona eklendi: [messageId]
✅ [DEBUG] Cloud Functions trigger tetiklenmeli: conversations/[conversationId]/messages/[messageId]
✅ [DEBUG] Mesaj Firestore'da mevcut, trigger tetiklenmiş olmalı
```

**Eğer bu loglar yoksa:**
- ❌ Mesaj Firestore'a kaydedilmiyor
- ❌ İnternet bağlantısı sorunu olabilir
- ❌ Firestore yazma izni sorunu olabilir

---

### Adım 2: Cloud Functions Loglarını Kontrol Et

**Firebase Console → Functions → Logs**

**Beklenen Loglar:**
```
🔵 [DEBUG] ========================================
🔵 [DEBUG] onConversationMessageCreated TRİGGER TETİKLENDİ
🔵 [DEBUG] ========================================
```

**Eğer bu loglar yoksa:**
- ❌ Cloud Functions trigger tetiklenmemiş
- ❌ Firestore yazma işlemi başarısız olmuş
- ❌ Trigger yanlış path'te tanımlanmış

---

### Adım 3: Alıcı Bilgilerini Kontrol Et

**Beklenen Loglar:**
```
🔵 [DEBUG] Alıcı bilgileri alındı:
   - recipientId: [userId]
   - fcmToken: [token]... (ilk 20 karakter)
   - platform: ios veya android
   - messageNotificationsEnabled: true
```

**Eğer fcmToken YOK ise:**
- ❌ Alıcının FCM token'ı Firestore'da yok
- ❌ Alıcı token'ını yeniden kaydetmeli

**Eğer platform "unknown" ise:**
- ❌ Platform bilgisi geçersiz
- ❌ Alıcı token'ını yeniden kaydetmeli

**Eğer messageNotificationsEnabled false ise:**
- ❌ Alıcı mesaj bildirimlerini kapamış
- ❌ Bu normal, bildirim gönderilmeyecek

---

### Adım 4: Token Validation Kontrolü

**Beklenen Loglar:**
```
🔵 [DEBUG] Token validation yapılıyor...
   - Token uzunluğu: 150-200 karakter (normal)
   - Token (ilk 30 karakter): ...

✅ [DEBUG] Token validation başarılı
```

**Eğer token validation başarısız ise:**
- ❌ Token formatı geçersiz
- ❌ Token çok kısa veya çok uzun
- ❌ Token geçersiz karakterler içeriyor

---

### Adım 5: Bildirim Gönderimi Kontrolü

**Başarılı Senaryo:**
```
🔵 [DEBUG] admin.messaging().send() çağrılıyor...
✅ [onConversationMessageCreated] Bildirim başarıyla gönderildi: [messageId]
✅ Alıcı: ..., Platform: ...
✅ Token: ...
✅ MessageId: ...
🔵 [DEBUG] ========================================
🔵 [DEBUG] BİLDİRİM BAŞARIYLA GÖNDERİLDİ
🔵 [DEBUG] ========================================
```

**Hata Senaryosu:**
```
🔴 [DEBUG] ========================================
🔴 [DEBUG] BİLDİRİM GÖNDERME HATASI
🔴 [DEBUG] ========================================
❌ [onConversationMessageCreated] Bildirim gönderme hatası:
   - Hata kodu: messaging/invalid-registration-token
   - Hata mesajı: ...
```

**Olası Hata Kodları:**
- `messaging/invalid-registration-token` → Token geçersiz
- `messaging/registration-token-not-registered` → Token kayıtlı değil
- `messaging/third-party-auth-error` → OAuth 2.0 hatası
- `messaging/quota-exceeded` → Kota aşıldı

---

## 🛠️ Çözüm Adımları

### Sorun 1: Trigger Tetiklenmiyor

**Kontrol:**
1. Firebase Console → Functions → Logs
2. Mesaj gönderildikten sonra logları kontrol et
3. `onConversationMessageCreated` logları görünüyor mu?

**Çözüm:**
```bash
# Cloud Functions'ı yeniden deploy et
cd functions
npm run build
firebase deploy --only functions:onConversationMessageCreated
```

---

### Sorun 2: Token Yok veya Geçersiz

**Kontrol:**
1. Firebase Console → Firestore → users → [userId]
2. `fcmToken` alanı var mı?
3. `platform` alanı "ios" veya "android" mi?

**Çözüm:**
- Alıcı uygulamayı açsın
- Token otomatik kaydedilecek
- Veya manuel olarak token kaydı yapılsın

---

### Sorun 3: Platform = "unknown"

**Kontrol:**
1. Firebase Console → Firestore → users → [userId]
2. `platform` alanı ne?

**Çözüm:**
- Alıcı uygulamayı yeniden başlatsın
- `FCMTokenManager.saveTokenToFirestore()` çağrılsın
- Platform otomatik düzeltilecek

---

### Sorun 4: Bildirim Gönderilmiyor (Token Geçerli)

**Kontrol:**
1. Firebase Console → Functions → Logs
2. Hata kodu ne?

**Çözüm:**
- `messaging/invalid-registration-token` → Token yeniden kaydedilmeli
- `messaging/third-party-auth-error` → Firebase Admin SDK credentials kontrol edilmeli
- `messaging/quota-exceeded` → Firebase quota kontrol edilmeli

---

## 📱 Test Senaryosu

1. **Mesaj Gönder:**
   - Kullanıcı A → Kullanıcı B'ye mesaj gönder
   - Flutter loglarını kontrol et
   - Cloud Functions loglarını kontrol et

2. **Beklenen Sonuç:**
   - ✅ Flutter: Mesaj Firestore'a kaydedildi
   - ✅ Cloud Functions: Trigger tetiklenmiş
   - ✅ Cloud Functions: Bildirim gönderilmiş
   - ✅ Kullanıcı B: Bildirim almış

3. **Hata Durumu:**
   - ❌ Flutter: Mesaj kaydedilmedi → İnternet/Firestore sorunu
   - ❌ Cloud Functions: Trigger tetiklenmedi → Trigger sorunu
   - ❌ Cloud Functions: Token yok → Token kayıt sorunu
   - ❌ Cloud Functions: Bildirim gönderilemedi → FCM sorunu

---

## ✅ Başarı Kriterleri

1. ✅ Flutter loglarında mesaj kaydedildi görünüyor
2. ✅ Cloud Functions loglarında trigger tetiklenmiş görünüyor
3. ✅ Cloud Functions loglarında bildirim gönderilmiş görünüyor
4. ✅ Kullanıcı bildirim almış

---

## 📞 Destek

Eğer sorun devam ederse:
1. Flutter loglarını paylaş
2. Cloud Functions loglarını paylaş
3. Firebase Console → Firestore → users → [userId] → fcmToken ve platform değerlerini kontrol et
4. Firebase Console → Functions → Logs → Hata mesajlarını kontrol et







