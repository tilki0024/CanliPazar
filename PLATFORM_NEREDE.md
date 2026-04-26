# 📍 Platform Alanı Nerede Yazılıyor?

## ✅ CEVAP: `users` Koleksiyonunda

**`platform` alanı `users` koleksiyonundaki her kullanıcı dokümanına yazılır.**

## 📊 Firestore Yapısı

```
Firestore Database
└── users (koleksiyon)
    └── {userId} (doküman)
        ├── fcmToken: "dKx..." ✅
        ├── platform: "ios" ✅
        ├── username: "..."
        ├── email: "..."
        └── ... (diğer kullanıcı alanları)
```

## 🔍 Kod İncelemesi

**Dosya:** `lib/services/fcm_token_manager.dart`

**Kod:**
```dart
// Satır 179-183
await _firestore.collection('users').doc(userId).update({
  'fcmToken': token,
  'platform': platform,  // ✅ Platform burada yazılıyor
  'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
});
```

**Yapılan İşlem:**
1. `users` koleksiyonunu seç
2. Kullanıcının dokümanını bul (`doc(userId)`)
3. `platform` alanını güncelle (`update()`)
4. Değer: `"ios"` veya `"android"`

## 🎯 Firebase Console'da Kontrol

### Adımlar:

1. **Firebase Console** → **Firestore Database**
2. Sol menüden **`users`** koleksiyonunu seç
3. Kullanıcının dokümanını aç (doküman ID = kullanıcı UID)
4. Şu alanları kontrol et:
   ```json
   {
     "fcmToken": "dKx...",     // ✅ Burada
     "platform": "ios",        // ✅ Burada (users içinde)
     "username": "...",
     "email": "..."
   }
   ```

## 📝 Örnek Doküman Yapısı

**Koleksiyon:** `users`  
**Doküman ID:** `HIZSJ8sGvjO2x7IKOD8rZTS1gqD3` (örnek)

**İçerik:**
```json
{
  "uid": "HIZSJ8sGvjO2x7IKOD8rZTS1gqD3",
  "username": "emircan",
  "email": "emircan@example.com",
  "fcmToken": "dKx1234567890...",  // ✅ FCM Token
  "platform": "ios",               // ✅ Platform (users içinde)
  "country": "Türkiye",
  "city": "Ardahan",
  "photoUrl": "...",
  "bio": "...",
  // ... diğer alanlar
}
```

## ⚠️ ÖNEMLİ NOTLAR

1. **`platform` alanı `users` koleksiyonunda olmalı**
   - ❌ `animals` koleksiyonunda değil
   - ❌ `conversations` koleksiyonunda değil
   - ✅ `users` koleksiyonunda

2. **Her kullanıcı dokümanında ayrı ayrı yazılır**
   - Her kullanıcının kendi `platform` değeri var
   - iOS kullanıcı: `platform: "ios"`
   - Android kullanıcı: `platform: "android"`

3. **Otomatik yazılır**
   - `FCMTokenManager` servisi otomatik olarak yazar
   - Kullanıcı giriş yaptığında
   - Uygulama başladığında (kullanıcı zaten giriş yapmışsa)
   - Token yenilendiğinde

## 🔧 Manuel Kontrol

### Eğer `platform` alanı yoksa:

1. **iOS uygulamayı kapat**
2. **iOS uygulamayı aç**
3. **Giriş yap**
4. **10 saniye bekle** (token kaydı için)
5. **Firestore'da kontrol et:**
   - `users/{userId}` dokümanını aç
   - `platform` alanı `"ios"` olarak görünmeli

### Manuel Düzeltme (Geçici):

1. **Firebase Console** → **Firestore** → **`users`** koleksiyonu
2. Kullanıcının dokümanını aç
3. **"Add field"** butonuna tıkla
4. **Field name:** `platform`
5. **Field type:** `string`
6. **Field value:** `ios` (iOS için) veya `android` (Android için)
7. **Save**

**⚠️ Not:** Manuel düzeltme geçicidir. Uygulama tekrar açıldığında `FCMTokenManager` otomatik olarak düzeltecektir.

## 🧪 Test

### Test 1: Platform Kontrolü

1. **Firebase Console** → **Firestore** → **`users`** koleksiyonu
2. Kullanıcının dokümanını aç
3. `platform` alanını kontrol et
4. Değer: `"ios"` veya `"android"` olmalı

### Test 2: Cloud Functions Logları

Mesaj gönderildiğinde Cloud Functions log'larında:
```
✅ Alıcı token bulundu (platform: ios): dKx...
```

Bu log, `platform` alanının `users` koleksiyonundan okunduğunu gösterir.

## 📊 Cloud Functions'da Kullanım

**Dosya:** `functions/src/index.ts`

**Kod:**
```typescript
// Satır 226-239
const recipientDoc = await admin
    .firestore()
    .collection("users")  // ✅ users koleksiyonundan
    .doc(recipientId)
    .get();

const recipientData = recipientDoc.data();
const recipientToken = recipientData?.fcmToken;
const recipientPlatform = recipientData?.platform; // ✅ users içinden okunuyor
```

**Yapılan İşlem:**
1. `users` koleksiyonundan alıcının dokümanını al
2. `platform` alanını oku
3. Platform kontrolü yap (iOS/Android)

## 🎯 Özet

- ✅ **`platform` alanı `users` koleksiyonunda yazılır**
- ✅ **Her kullanıcı dokümanında (`users/{userId}`) ayrı ayrı**
- ✅ **Otomatik olarak `FCMTokenManager` tarafından yazılır**
- ✅ **Cloud Functions `users` koleksiyonundan okur**

## 🔗 İlgili Dosyalar

- `lib/services/fcm_token_manager.dart` - Platform yazma kodu
- `functions/src/index.ts` - Platform okuma kodu (Cloud Functions)
- `TOKEN_KONTROL_REHBERI.md` - Token kontrol rehberi





























