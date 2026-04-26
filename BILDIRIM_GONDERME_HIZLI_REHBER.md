# 🚀 Bildirim Gönderme - Hızlı Rehber

## ✅ Hazır Komutlar

### Yöntem 1: Terminal'den (En Kolay) ⭐

**macOS/Linux Terminal'de:**

```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main
chmod +x gonder_bildirim.sh
./gonder_bildirim.sh
```

**veya direkt olarak:**

```bash
curl -X POST \
  https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms \
  -H "Content-Type: application/json" \
  -d '{
    "title": "CanlıPazar'\''da ilan verin",
    "body": "Binlerce müşteriye ulaşın",
    "data": {
      "type": "promotion"
    }
  }'
```

---

### Yöntem 2: Node.js Script (Alternatif)

```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main
node gonder_bildirim.js
```

---

### Yöntem 3: Firebase Console (Görsel)

1. **Firebase Console** → https://console.firebase.google.com
2. Proje: **canlipazar-b3697**
3. Sol menü → **Functions**
4. **`sendNotificationToAllPlatforms`** fonksiyonunu bulun
5. Fonksiyonun yanındaki **"..."** (üç nokta) → **"Test function"**
6. **"Triggering event"** bölümüne şu JSON'u yapıştırın:

```json
{
  "title": "CanlıPazar'da ilan verin",
  "body": "Binlerce müşteriye ulaşın",
  "data": {
    "type": "promotion"
  }
}
```

7. **"Test the function"** butonuna tıklayın

---

### Yöntem 4: Postman veya HTTP Client

**URL:**
```
POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms
```

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "title": "CanlıPazar'da ilan verin",
  "body": "Binlerce müşteriye ulaşın",
  "data": {
    "type": "promotion"
  }
}
```

---

## 📊 Beklenen Sonuç

### Başarılı Yanıt:
```json
{
  "success": true,
  "message": "Bildirimler gönderildi",
  "stats": {
    "total": 1523,
    "ios": 856,
    "android": 667,
    "unknown": 0,
    "sent": 1523,
    "failed": 0
  },
  "notification": {
    "title": "CanlıPazar'da ilan verin",
    "body": "Binlerce müşteriye ulaşın"
  }
}
```

---

## ⚡ En Hızlı Yöntem

**Terminal'de şu komutu çalıştırın:**

```bash
curl -X POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms -H "Content-Type: application/json" -d '{"title":"CanlıPazar'\''da ilan verin","body":"Binlerce müşteriye ulaşın","data":{"type":"promotion"}}'
```

**Tek satır, kopyala-yapıştır! 🚀**

---

## ✅ Kontrol

Bildirim gönderildikten sonra:
1. Firebase Console → Cloud Messaging → Reports
2. Gönderim istatistiklerini kontrol edin
3. iOS/Android cihazlarda bildirimi kontrol edin

---

## 🆘 Sorun Giderme

### "Function not found" hatası:
- Firebase Console'da fonksiyonun deploy edildiğinden emin olun
- `cd functions && npm run deploy` çalıştırın

### "Permission denied" hatası:
- Firebase Console'da Functions için gerekli izinler var mı kontrol edin

### "Timeout" hatası:
- Çok fazla kullanıcı varsa birkaç dakika sürebilir
- Bekleyin, işlem devam ediyor olabilir

---

**Hazır! Yukarıdaki komutlardan birini çalıştırın! 🚀**





























