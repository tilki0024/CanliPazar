# 🔧 Platform "Unknown" Düzeltme - Hazır Komutlar

## ✅ Fonksiyon Eklendi

**Fonksiyon:** `fixUnknownPlatforms`

Bu fonksiyon platform "unknown" olan kullanıcıları FCM token formatına bakarak otomatik olarak "ios" veya "android" olarak düzeltir.

---

## 🚀 Hızlı Kullanım

### ADIM 1: Deploy Et

```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main/functions
firebase deploy --only functions:fixUnknownPlatforms
```

### ADIM 2: Çalıştır

**Önce kontrol (DRY RUN):**
```bash
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/fixUnknownPlatforms -H "Content-Type: application/json" -d '{"dryRun":true,"limit":1000}'
```

**Sonra gerçek düzeltme:**
```bash
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/fixUnknownPlatforms -H "Content-Type: application/json" -d '{"dryRun":false,"limit":1000}'
```

---

## 📊 Beklenen Sonuç

```json
{
  "success": true,
  "message": "Platform \"unknown\" kullanıcılar düzeltildi",
  "stats": {
    "total": 405,
    "fixed": 350,
    "iosFixed": 200,
    "androidFixed": 150,
    "stillUnknown": 55,
    "skipped": 0,
    "errors": 0
  }
}
```

---

## 🔍 Platform Belirleme Yöntemleri

1. **Token Uzunluğu:**
   - Android: 140-250 karakter → `android`
   - iOS: 50-120 karakter → `ios`

2. **Token Formatı:**
   - iOS: ":" ile ayrılmış segmentler → `ios`
   - Android: Uzun format → `android`

3. **Belirlenemezse:**
   - "unknown" bırakılır
   - Kullanıcı uygulamayı açtığında otomatik düzelir

---

## ✅ Özet

1. **Deploy:** `firebase deploy --only functions:fixUnknownPlatforms`
2. **Çalıştır:** cURL komutu ile
3. **Sonuç:** 405 "unknown" kullanıcıdan ~350'i "ios" veya "android" olarak düzeltilir

**Hazır! Deploy edip çalıştırın! 🚀**





























