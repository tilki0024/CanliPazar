# 🔧 Platform Alanı Ekleme Cloud Function Rehberi

## 📋 Genel Bakış

Platform alanı eksik olan kullanıcılara otomatik olarak platform ekleyen bir Cloud Function oluşturuldu.

**Fonksiyon Adı:** `addPlatformToUsers`  
**Endpoint:** `https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers`

---

## 🚀 Kullanım

### 1. DRY RUN (Sadece Kontrol - Önerilen)

**Önce kontrol et, sonra ekle:**

```bash
# GET isteği (sadece kontrol)
curl -X GET "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers"

# Veya POST isteği
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": true, "limit": 100}'
```

**Beklenen Sonuç:**
```json
{
  "success": true,
  "message": "Kontrol tamamlandı (DRY RUN)",
  "stats": {
    "total": 100,
    "updated": 25,
    "skipped": 75,
    "errors": 0
  },
  "usersToUpdate": [
    {
      "userId": "user123",
      "platform": "unknown",
      "reason": "Platform alanı eksik, FCM token mevcut"
    }
  ],
  "dryRun": true
}
```

### 2. GERÇEK EKLEME

**Kontrol sonrası gerçekten ekle:**

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": false, "limit": 100}'
```

**Beklenen Sonuç:**
```json
{
  "success": true,
  "message": "Platform alanları eklendi",
  "stats": {
    "total": 100,
    "updated": 25,
    "skipped": 75,
    "errors": 0
  },
  "usersToUpdate": [...],
  "dryRun": false
}
```

---

## 📊 Parametreler

### Query Parametreleri (GET)

- Yok (tüm parametreler POST body'de)

### POST Body Parametreleri

- **`dryRun`** (boolean, varsayılan: `true`)
  - `true`: Sadece kontrol et, ekleme
  - `false`: Gerçekten ekle

- **`limit`** (number, varsayılan: `100`)
  - İşlenecek maksimum kullanıcı sayısı
  - Güvenlik için limit var (çok fazla kullanıcıyı tek seferde işlememek için)

---

## 🔍 Nasıl Çalışır?

### 1. Kullanıcıları Tarar

- Firestore'daki `users` koleksiyonundan kullanıcıları alır
- Varsayılan limit: 100 kullanıcı

### 2. Platform Kontrolü

- Her kullanıcı için `platform` alanını kontrol eder
- Platform alanı varsa ve doluysa atlar
- Platform alanı yoksa veya boşsa işaretler

### 3. Platform Ekleme

- Platform alanı eksik olan kullanıcılara `platform: "unknown"` ekler
- **ÖNEMLİ:** `"unknown"` geçici bir değerdir
- Kullanıcı uygulamayı açtığında `FCMTokenManager` otomatik olarak doğru platform'u (`ios` veya `android`) ekleyecek

### 4. Metadata Ekleme

- `platformAddedAt`: Platform eklendiği zaman (server timestamp)
- `platformAddedBy`: Platform'u ekleyen fonksiyon adı

---

## ⚠️ ÖNEMLİ NOTLAR

### 1. Platform Değeri: "unknown"

**Neden "unknown"?**
- Firestore'da hangi kullanıcının iOS, hangisinin Android olduğunu otomatik tespit edemeyiz
- FCM token formatına bakarak tahmin edilebilir ama güvenilir değil
- Bu yüzden varsayılan olarak `"unknown"` ekliyoruz

**Ne Zaman Düzeltilir?**
- Kullanıcı uygulamayı açtığında
- `FCMTokenManager` otomatik olarak doğru platform'u (`ios` veya `android`) ekleyecek
- `"unknown"` değeri `"ios"` veya `"android"` ile değiştirilecek

### 2. Limit Kullanımı

**Neden Limit Var?**
- Çok fazla kullanıcıyı tek seferde işlemek Firebase'in rate limit'lerini aşabilir
- Varsayılan limit: 100 kullanıcı
- Daha fazla kullanıcı için fonksiyonu birden fazla kez çağırın

### 3. Dry Run Önerilir

**Neden Önce Dry Run?**
- Kaç kullanıcının etkileneceğini görmek için
- Hata olup olmadığını kontrol etmek için
- Gerçek ekleme yapmadan önce test etmek için

---

## 🧪 Test Adımları

### Adım 1: DRY RUN (Kontrol)

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": true, "limit": 10}'
```

**Beklenen:**
- Kaç kullanıcının etkileneceğini gösterir
- Hata olup olmadığını kontrol eder
- Hiçbir değişiklik yapmaz

### Adım 2: Gerçek Ekleme (Küçük Grup)

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": false, "limit": 10}'
```

**Beklenen:**
- İlk 10 kullanıcıya platform ekler
- Sonuçları gösterir

### Adım 3: Firestore Kontrolü

1. Firebase Console → Firestore Database
2. `users` koleksiyonunu aç
3. Platform eklenen kullanıcıları kontrol et
4. `platform: "unknown"` değerini gör

### Adım 4: Tüm Kullanıcılar (Büyük Grup)

```bash
curl -X POST "https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": false, "limit": 1000}'
```

**DİKKAT:** Limit'i yavaş yavaş artırın (100 → 500 → 1000)

---

## 📊 Beklenen Sonuçlar

### Başarılı Sonuç

```json
{
  "success": true,
  "message": "Platform alanları eklendi",
  "stats": {
    "total": 100,
    "updated": 25,
    "skipped": 75,
    "errors": 0
  },
  "usersToUpdate": [
    {
      "userId": "user123",
      "platform": "unknown",
      "reason": "Platform alanı eksik, FCM token mevcut"
    }
  ],
  "dryRun": false
}
```

### Firestore'da Görünen

**Önce:**
```json
{
  "uid": "user123",
  "username": "testuser",
  "fcmToken": "dKx...",
  // platform alanı yok
}
```

**Sonra:**
```json
{
  "uid": "user123",
  "username": "testuser",
  "fcmToken": "dKx...",
  "platform": "unknown",  // ✅ Eklendi
  "platformAddedAt": "2024-12-13T10:00:00Z",
  "platformAddedBy": "addPlatformToUsers_function"
}
```

**Kullanıcı Uygulamayı Açtığında:**
```json
{
  "uid": "user123",
  "username": "testuser",
  "fcmToken": "dKx...",
  "platform": "ios",  // ✅ FCMTokenManager tarafından düzeltildi
  "platformAddedAt": "2024-12-13T10:00:00Z",
  "platformAddedBy": "addPlatformToUsers_function"
}
```

---

## 🔧 Sorun Giderme

### Sorun 1: Fonksiyon Bulunamadı

**Hata:**
```
Function not found: addPlatformToUsers
```

**Çözüm:**
1. Cloud Functions'ı deploy et:
   ```bash
   cd functions
   firebase deploy --only functions:addPlatformToUsers
   ```

### Sorun 2: Rate Limit Hatası

**Hata:**
```
Too many requests
```

**Çözüm:**
- Limit'i azaltın (örn: 50)
- Birkaç dakika bekleyin
- Tekrar deneyin

### Sorun 3: Platform Hala "unknown"

**Sorun:**
- Platform `"unknown"` olarak kaldı

**Çözüm:**
- Kullanıcı uygulamayı açtığında `FCMTokenManager` otomatik düzeltecek
- Veya manuel olarak `"ios"` veya `"android"` ekleyin

---

## 📝 Notlar

1. **Platform "unknown" Geçicidir**
   - Kullanıcı uygulamayı açtığında otomatik düzeltilir
   - Manuel düzeltme gerekmez (ama yapılabilir)

2. **Limit Kullanımı**
   - Çok fazla kullanıcı için fonksiyonu birden fazla kez çağırın
   - Her çağrıda farklı kullanıcılar işlenir (limit sayesinde)

3. **Dry Run Önerilir**
   - Her zaman önce dry run yapın
   - Sonuçları kontrol edin
   - Sonra gerçek ekleme yapın

---

## 🔗 İlgili Dosyalar

- `functions/src/index.ts` - Cloud Function kodu
- `lib/services/fcm_token_manager.dart` - Platform otomatik düzeltme
- `KAPSAMLI_ANALIZ_RAPORU.md` - Detaylı analiz raporu

---

**Son Güncelleme:** 2024-12-13





























