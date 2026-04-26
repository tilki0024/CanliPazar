# 🔑 SHA256 Fingerprint Alma Rehberi

**Amaç:** Android App Links için `assetlinks.json` dosyasına SHA256 fingerprint eklemek

---

## 📋 ADIMLAR

### 1. Release Keystore için SHA256 Fingerprint

```bash
# Release keystore için
keytool -list -v -keystore android/app/key.jks -alias key | grep SHA256

# Çıktı örneği:
# SHA256: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB
```

**⚠️ ÖNEMLİ:**
- Release keystore için SHA256 fingerprint kullanılmalı
- Debug keystore için değil!

---

### 2. Debug Keystore için SHA256 Fingerprint (Test Amaçlı)

```bash
# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

**⚠️ NOT:** Debug keystore sadece test için kullanılır, production'da kullanılmaz.

---

### 3. assetlinks.json Dosyasını Güncelle

1. `public/.well-known/assetlinks.json` dosyasını açın
2. `SHA256_FINGERPRINT_HERE` yerine gerçek SHA256 fingerprint'i yapıştırın
3. Dosyayı kaydedin

**Örnek:**
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.canlipazar",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB"
      ]
    }
  }
]
```

---

### 4. Web Sunucusuna Yükle

```bash
# Dosyayı web sunucusuna yükleyin
scp public/.well-known/assetlinks.json user@server:/var/www/canlipazar.com/.well-known/

# Dosya izinlerini ayarlayın
chmod 644 /var/www/canlipazar.com/.well-known/assetlinks.json

# Content-Type header'ını ayarlayın (Nginx örneği)
# location /.well-known/assetlinks.json {
#     default_type application/json;
# }
```

---

### 5. Doğrulama

```bash
# Dosyanın erişilebilir olduğunu kontrol edin
curl https://canlipazar.com/.well-known/assetlinks.json

# Beklenen çıktı: JSON dosyası içeriği
```

---

## ⚠️ ÖNEMLİ NOTLAR

1. **Release Keystore:** Production için release keystore'un SHA256 fingerprint'i kullanılmalı
2. **Debug Keystore:** Sadece test için, production'da kullanılmaz
3. **Format:** SHA256 fingerprint iki nokta üst üste (:) ile ayrılmış olmalı
4. **Content-Type:** `application/json` olmalı
5. **HTTPS:** Dosya HTTPS üzerinden erişilebilir olmalı

---

## 🔍 TROUBLESHOOTING

### Sorun: Keystore Bulunamadı

**Çözüm:**
```bash
# Keystore dosyasının yerini kontrol edin
ls -la android/app/key.jks

# Eğer farklı bir yerdeyse, tam path kullanın
keytool -list -v -keystore /full/path/to/key.jks -alias key | grep SHA256
```

### Sorun: SHA256 Fingerprint Görünmüyor

**Çözüm:**
```bash
# Tüm fingerprint'leri göster
keytool -list -v -keystore android/app/key.jks -alias key

# SHA256 satırını manuel olarak bulun
```

---

## ✅ DOĞRULAMA

Android cihazda doğrulama:
```bash
adb shell pm get-app-links com.canlipazar

# Beklenen çıktı:
# com.canlipazar:
#   Domain verification state:
#     canlipazar.com: verified
```



















