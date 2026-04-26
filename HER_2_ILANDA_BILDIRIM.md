# 🔔 Her 2 İlanda Bir Bildirim Sistemi

## ✅ Güncelleme Tamamlandı

**Fonksiyon:** `onNewAnimalPostCreated`

Bu fonksiyon artık **her 2 ilanda bir** tüm kullanıcılara "Yeni İlan Eklendi" bildirimi gönderir.

---

## 🔄 Nasıl Çalışıyor?

### 1. Counter Sistemi
- Her yeni ilan eklendiğinde bir counter artırılır
- Counter Firestore'da `system/notificationCounter` dokümanında tutulur
- Counter değeri: `count` alanında

### 2. Bildirim Mantığı
- **Her 2 ilanda bir** bildirim gönderilir
- Counter 2'ye bölündüğünde bildirim tetiklenir
- Örnek: 2. ilan, 4. ilan, 6. ilan, 8. ilan... → Bildirim gönderilir

### 3. Bildirim İçeriği
```
Başlık: "Yeni İlan Eklendi! 🐄"
Mesaj: "2 yeni ilan eklendi, hemen göz at!"
```

### 4. Kullanıcı Kapsamı
- ✅ **Tüm platformlar:** iOS, Android, Unknown
- ✅ **Tüm kullanıcılar:** FCM token'ı olan herkes
- ❌ **İlan sahibi hariç:** Kendi ilanı için bildirim almaz

---

## 📊 Örnek Senaryo

| İlan Sayısı | Counter | Bildirim Gönderilir mi? |
|------------|---------|------------------------|
| 1. ilan     | 1       | ❌ Hayır (1 % 2 = 1) |
| 2. ilan     | 2       | ✅ Evet (2 % 2 = 0) |
| 3. ilan     | 3       | ❌ Hayır (3 % 2 = 1) |
| 4. ilan     | 4       | ✅ Evet (4 % 2 = 0) |
| 5. ilan     | 5       | ❌ Hayır (5 % 2 = 1) |
| 6. ilan     | 6       | ✅ Evet (6 % 2 = 0) |

---

## 🔧 Teknik Detaylar

### Firestore Yapısı
```
system/
  └── notificationCounter/
      ├── count: number (ilan sayacı)
      └── lastUpdated: timestamp
```

### Bildirim Gönderimi
- **Batch Size:** 500 token (FCM limit)
- **Platform Desteği:** iOS, Android, Unknown
- **Öncelik:** High
- **Sound:** Default
- **Badge:** iOS için +1

---

## 🚀 Deploy

Fonksiyon otomatik olarak çalışır. Yeni bir ilan eklendiğinde:

1. Counter artırılır
2. Counter 2'ye bölünüyorsa bildirim gönderilir
3. Tüm kullanıcılara (ilan sahibi hariç) bildirim ulaşır

**Manuel deploy gerekmez** - Cloud Function otomatik tetiklenir.

---

## 📝 Log Örnekleri

### Bildirim Gönderilmediğinde:
```
🆕 Yeni ilan eklendi: abc123
📊 İlan sayacı: 1 (Her 2 ilanda 1 bildirim gönderilecek)
⏭️ Bildirim atlandı (1 % 2 = 1, 2'ye ulaşmadı)
```

### Bildirim Gönderildiğinde:
```
🆕 Yeni ilan eklendi: def456
📊 İlan sayacı: 2 (Her 2 ilanda 1 bildirim gönderilecek)
✅ 2 ilan tamamlandı! Bildirim gönderiliyor... (Toplam: 2 ilan)
📱 1000 kullanıcıya bildirim gönderilecek
📊 Platform dağılımı: iOS=200, Android=700, Unknown=100
✅ 1000 kullanıcıya bildirim gönderiliyor
📤 Batch 1: 500 başarılı, 0 başarısız
📤 Batch 2: 500 başarılı, 0 başarısız
✅ Bildirim gönderme tamamlandı: 1000 başarılı, 0 başarısız
```

---

## ✅ Özet

- ✅ Her 2 ilanda bir bildirim gönderilir
- ✅ Tüm platformlara (iOS, Android, Unknown) gönderilir
- ✅ İlan sahibi bildirim almaz
- ✅ Otomatik çalışır (manuel işlem gerekmez)
- ✅ Batch gönderim (500 token/batch)

**Sistem hazır! Yeni ilanlar eklendiğinde otomatik olarak çalışacak! 🚀**





























