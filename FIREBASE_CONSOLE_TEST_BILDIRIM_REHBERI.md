# 🔍 Firebase Console'da Test Bildirimi Gönderme Rehberi

## 📋 Adım Adım Talimatlar

### Yöntem 1: Cloud Messaging Sekmesi (Önerilen)

1. **Firebase Console'a gidin:**
   - https://console.firebase.google.com
   - Projenizi seçin: **canlipazar-b3697**

2. **Sol menüden "Cloud Messaging" seçin:**
   - Sol menüde **"⚙️ Project Settings"** (Proje Ayarları) tıklayın
   - Üst menüden **"Cloud Messaging"** sekmesine tıklayın

3. **"Send test message" butonunu bulun:**
   - Sayfanın üst kısmında **"Send test message"** veya **"Test message gönder"** butonu olmalı
   - Eğer göremiyorsanız, sayfayı aşağı kaydırın

4. **Test bildirimi gönderin:**
   - **FCM registration token**: iOS kullanıcının `fcmToken` değerini girin
   - **Notification title**: "Test Bildirimi"
   - **Notification text**: "Bu bir test bildirimidir"
   - **Send test message** butonuna tıklayın

---

### Yöntem 2: Engage → Cloud Messaging

1. **Firebase Console'a gidin:**
   - https://console.firebase.google.com
   - Projenizi seçin: **canlipazar-b3697**

2. **Sol menüden "Engage" seçin:**
   - Sol menüde **"Engage"** (Etkileşim) bölümünü bulun
   - **"Cloud Messaging"** seçeneğine tıklayın

3. **"New notification" veya "Send test message" butonunu bulun:**
   - Sayfanın üst kısmında butonlar olmalı
   - **"Send test message"** veya **"Test message"** butonuna tıklayın

4. **Test bildirimi gönderin:**
   - **FCM registration token**: iOS kullanıcının `fcmToken` değerini girin
   - **Notification title**: "Test Bildirimi"
   - **Notification text**: "Bu bir test bildirimidir"
   - **Send** butonuna tıklayın

---

### Yöntem 3: Cloud Messaging API (Alternatif)

Eğer yukarıdaki yöntemler çalışmazsa:

1. **Firebase Console → Project Settings → Cloud Messaging**
2. **"Cloud Messaging API (V1)"** bölümünü bulun
3. **"Send test message"** linkini arayın

---

## 🎯 iOS Kullanıcı Token'ını Bulma

### Firestore'dan Token Bulma

1. **Firebase Console** → **Firestore Database**
2. **`users`** koleksiyonunu seç
3. iOS kullanıcının dokümanını bul:
   - `platform: "ios"` olan kullanıcı
   - Veya kullanıcı ID'sini biliyorsanız direkt açın
4. **`fcmToken`** alanını kopyalayın
   - Uzun bir string olmalı (150+ karakter)
   - Örnek: `dKx1234567890...`

---

## 🧪 Alternatif Test Yöntemleri

### Yöntem 1: Cloud Functions ile Test

**Mevcut fonksiyon: `sendTestNotificationToiOS`**

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationToiOS"
```

Bu fonksiyon sadece iOS kullanıcılarına test bildirimi gönderir.

---

### Yöntem 2: Belirli Kullanıcıya Test Bildirimi

**Mevcut fonksiyon: `sendNotificationToUser`**

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToUser?userId=KULLANICI_ID" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test bildirimi"}'
```

**KULLANICI_ID**: iOS kullanıcının Firestore doküman ID'si

---

### Yöntem 3: Terminal ile Test

**FCM token ile direkt test:**

```bash
# iOS kullanıcının fcmToken değerini alın (Firestore'dan)
# Sonra şu komutu çalıştırın:

curl -X POST "https://fcm.googleapis.com/v1/projects/canlipazar-b3697/messages:send" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "FCM_TOKEN_BURAYA",
      "notification": {
        "title": "Test Bildirimi",
        "body": "Bu bir test bildirimidir"
      },
      "apns": {
        "payload": {
          "aps": {
            "alert": {
              "title": "Test Bildirimi",
              "body": "Bu bir test bildirimidir"
            },
            "sound": "default",
            "badge": 1
          }
        },
        "headers": {
          "apns-topic": "com.canlipazar.app"
        }
      }
    }
  }'
```

**Not:** Bu yöntem için `gcloud` CLI kurulu olmalı ve Firebase'e giriş yapmış olmalısınız.

---

## 📱 Firebase Console Görsel Rehber

### Adım 1: Firebase Console Ana Sayfa

```
Firebase Console
├── Sol Menü
│   ├── ⚙️ Project Settings (Proje Ayarları)
│   ├── Engage (Etkileşim)
│   │   └── Cloud Messaging
│   └── ...
```

### Adım 2: Project Settings → Cloud Messaging

```
Project Settings
├── General (Genel)
├── Cloud Messaging ← BURAYA TIKLAYIN
│   ├── Cloud Messaging API (V1)
│   ├── Apple app configuration
│   └── Send test message ← BURAYA TIKLAYIN
└── ...
```

### Adım 3: Send Test Message Formu

```
Send test message
├── FCM registration token: [TOKEN_BURAYA]
├── Notification title: [BAŞLIK_BURAYA]
├── Notification text: [METİN_BURAYA]
└── [Send test message] butonu
```

---

## 🔍 Bulamıyorsanız

### Sorun 1: "Send test message" Butonu Görünmüyor

**Çözüm:**
- Sayfayı aşağı kaydırın
- Farklı bir sekme deneyin (Cloud Messaging, Engage)
- Tarayıcıyı yenileyin (F5 veya Cmd+R)

### Sorun 2: Cloud Messaging Sekmesi Yok

**Çözüm:**
- Firebase Console'da doğru projeyi seçtiğinizden emin olun
- Proje ayarlarına gidin: **⚙️ Project Settings**
- Üst menüden **Cloud Messaging** sekmesini arayın

### Sorun 3: Farklı Firebase Console Versiyonu

**Çözüm:**
- Firebase Console'un yeni versiyonunda menü yapısı değişmiş olabilir
- **Engage** → **Cloud Messaging** yolunu deneyin
- Veya **⚙️ Project Settings** → **Cloud Messaging** yolunu deneyin

---

## 🎯 En Kolay Yol: Cloud Functions ile Test

Firebase Console'da bulamıyorsanız, Cloud Functions ile test edebilirsiniz:

### iOS Kullanıcılarına Test Bildirimi

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationToiOS"
```

### Belirli Kullanıcıya Test Bildirimi

```bash
# iOS kullanıcının ID'sini Firestore'dan bulun
# Örnek: HIZSJ8sGvjO2x7IKOD8rZTS1gqD3

curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToUser?userId=HIZSJ8sGvjO2x7IKOD8rZTS1gqD3" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test bildirimi - iOS"}'
```

---

## 📝 Özet

### Firebase Console'da Bulma

1. **⚙️ Project Settings** → **Cloud Messaging** → **Send test message**
2. Veya **Engage** → **Cloud Messaging** → **Send test message**

### Alternatif: Cloud Functions

1. **`sendTestNotificationToiOS`** - Tüm iOS kullanıcılarına
2. **`sendNotificationToUser`** - Belirli kullanıcıya

---

**Hangi yöntemi denediniz? Sonuç ne oldu?** 🔍





























