# OAuth 2.0 Authentication Hatası Çözüm Rehberi

## Sorun
```
FirebaseMessagingError: Request is missing required authentication credential. Expected OAuth 2 access token...
```

## Çözüm

### 1. Google Cloud IAM Rolleri Kontrolü

Firebase Cloud Functions'ın FCM bildirimleri gönderebilmesi için gerekli IAM rollerini kontrol edin:

#### Adım 1: Google Cloud Console'a gidin
1. [Google Cloud Console](https://console.cloud.google.com/) → IAM & Admin → Service Accounts
2. Cloud Functions service account'unu bulun:
   - Format: `PROJECT_ID@appspot.gserviceaccount.com`
   - Örnek: `canlipazar-b3697@appspot.gserviceaccount.com`

#### Adım 2: Gerekli rolleri ekleyin
Service account'a şu rolleri ekleyin:
- **Firebase Cloud Messaging Admin** (Önerilen)
- VEYA **Firebase Admin SDK Administrator Service Agent**

#### Adım 3: Rolleri ekleme
1. Service account'u seçin
2. "PERMISSIONS" sekmesine gidin
3. "GRANT ACCESS" butonuna tıklayın
4. "ADD ANOTHER ROLE" ile rolleri ekleyin
5. "SAVE" butonuna tıklayın

### 2. Firebase Console Kontrolü

#### Adım 1: Firebase Console'a gidin
1. [Firebase Console](https://console.firebase.google.com/) → Project Settings → Service Accounts
2. "Generate new private key" butonuna tıklayın (sadece test için gerekli)
3. Service account key dosyasını indirin (sadece local test için)

#### Adım 2: Cloud Functions ortamında
**ÖNEMLİ:** Cloud Functions ortamında service account key dosyası **GEREKMEZ**!
- Cloud Functions otomatik olarak Application Default Credentials (ADC) kullanır
- Google Cloud IAM rolleri yeterlidir
- `admin.initializeApp()` boş çağrılabilir

### 3. Kod Değişiklikleri

#### ✅ Doğru Kullanım (Cloud Functions)
```typescript
import * as admin from "firebase-admin";

// Cloud Functions ortamında otomatik Application Default Credentials kullanılır
if (!admin.apps.length) {
  admin.initializeApp({
    // Credential belirtmeye gerek yok
    // Otomatik olarak Google Cloud IAM üzerinden yetkilendirme yapılır
  });
}

// FCM HTTP v1 API kullanımı (modern API)
const message: admin.messaging.Message = {
  token: fcmToken,
  notification: {
    title: "Başlık",
    body: "İçerik",
  },
  // ... diğer ayarlar
};

const response = await admin.messaging().send(message);
```

#### ❌ Yanlış Kullanım (Eski API)
```typescript
// ESKİ API - KULLANMAYIN
await admin.messaging().sendToDevice(token, {
  notification: { ... }
});
```

### 4. Test

#### Adım 1: Cloud Functions'ı deploy edin
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

#### Adım 2: Logları kontrol edin
```bash
firebase functions:log
```

#### Adım 3: Test bildirimi gönderin
1. Uygulamadan mesaj gönderin
2. Cloud Functions loglarını kontrol edin
3. "Bildirim başarıyla gönderildi" mesajını arayın

### 5. Sorun Giderme

#### Hata: "OAuth 2.0 authentication hatası"
**Çözüm:**
1. Google Cloud Console → IAM & Admin → Service Accounts
2. Cloud Functions service account'una "Firebase Cloud Messaging Admin" rolünü ekleyin
3. 5-10 dakika bekleyin (IAM değişiklikleri yayılması için)
4. Cloud Functions'ı yeniden deploy edin

#### Hata: "Service account key gerekli"
**Çözüm:**
- Cloud Functions ortamında service account key **GEREKMEZ**
- Sadece Google Cloud IAM rolleri yeterlidir
- Local test için service account key kullanabilirsiniz

#### Hata: "APNs authentication hatası" (iOS)
**Çözüm:**
1. Firebase Console → Project Settings → Cloud Messaging → iOS App
2. APNs Authentication Key (p8) yüklü mü kontrol edin
3. Key ID ve Team ID doğru mu kontrol edin
4. Bundle ID doğru mu kontrol edin: `com.canlipazar.app`

### 6. Özet

✅ **Yapılması Gerekenler:**
1. Google Cloud IAM'de "Firebase Cloud Messaging Admin" rolünü ekleyin
2. `admin.initializeApp()` boş çağrılabilir (Cloud Functions ortamında)
3. `admin.messaging().send()` kullanın (modern FCM HTTP v1 API)
4. Eski `sendToDevice` API'sini kullanmayın

❌ **Yapılmaması Gerekenler:**
1. Service account key dosyasını Cloud Functions'a yüklemeyin (gerekmez)
2. Eski `sendToDevice` API'sini kullanmayın
3. Manuel OAuth 2.0 token almayın (otomatik yapılır)

### 7. İletişim

Sorun devam ederse:
1. Cloud Functions loglarını kontrol edin
2. Google Cloud IAM rolleri kontrol edin
3. Firebase Console → Project Settings → Service Accounts kontrol edin


