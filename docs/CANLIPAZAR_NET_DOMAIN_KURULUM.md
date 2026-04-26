# canlipazar.net Domain ve Deep Link Kurulumu

## 1. Firebase Hosting – canlipazar.net DNS Kayıtları

### Adımlar

1. **Firebase Console** → Projenizi seçin → **Hosting** → **Add custom domain** (veya "Connect domain").
2. **canlipazar.net** yazın ve devam edin.
3. Firebase size **domain sahipliği doğrulaması** için bir **TXT** kaydı ve **Hosting** için **A** kayıtları gösterecektir.

### DNS’e eklenecek kayıtlar (örnek; Firebase Console’daki değerleri kullanın)

Firebase, domain’i eklerken size tam değerleri verir. Genelde şu yapı kullanılır:

| Tür | Ad / Host | Değer | TTL |
|-----|-----------|--------|-----|
| **TXT** | `@` veya `canlipazar.net` | Firebase’in verdiği doğrulama metni (örn. `firebase=proje-id`) | 3600 |
| **A** | `@` veya `canlipazar.net` | `151.101.1.195` | 3600 |
| **A** | `@` veya `canlipazar.net` | `151.101.65.195` | 3600 |

> **Önemli:**  
> - TXT ve A kayıtlarının **tam değerlerini** mutlaka **Firebase Console**’da “Add custom domain” adımında gördüğünüz metinden alın.  
> - Bazı sağlayıcılar kök domain için sadece bir A kaydı kabul eder; ikinci A’yı desteklemiyorsa Firebase destek dokümanına veya “Custom domain” sayfasındaki notlara bakın.

### www alt alanı (isteğe bağlı)

`www.canlipazar.net` de kullanacaksanız Firebase’de ayrıca “Add custom domain” ile `www.canlipazar.net` ekleyin; genelde **CNAME** ile `canlipazar-b3697.web.app` veya Firebase’in söylediği hedefe yönlendirilir.

### Doğrulama

- Firebase Console’da domain’in yanında **“Connected”** / **“Verified”** görünene kadar bekleyin (birkaç dakika – 48 saat arası sürebilir).
- DNS’i kontrol etmek için:
  - TXT: `nslookup -type=TXT canlipazar.net`
  - A: `nslookup canlipazar.net`

---

## 2. Universal Links (iOS) – apple-app-site-association

Domain doğrulandıktan ve Hosting + Functions deploy edildikten sonra:

**URL:** `https://canlipazar.net/.well-known/apple-app-site-association`  
(Bu dosya projede `public/.well-known/apple-app-site-association` içinde; Firebase Hosting ile deploy edilince canlipazar.net’te yayında olur.)

- **Content-Type:** `application/json`
- **HTTPS** zorunludur; Firebase Hosting SSL sağlar.
- Xcode’da **Runner.entitlements** içinde `applinks:canlipazar.net` tanımlı olmalı (projede yapıldı).

---

## 3. App Links (Android) – assetlinks.json

**URL:** `https://canlipazar.net/.well-known/assetlinks.json`  
Bu adres, **getWellKnown** Cloud Function tarafından sunulur (Firebase Hosting rewrite ile).

- **SHA256 parmak izi:** Play App Signing kullanıyorsanız **Google Play Console** → Uygulama → **Setup** → **App signing** içindeki SHA-256’yı kullanın. Yerel keystore için: `keytool -list -v -keystore your.keystore`
- SHA256’yı Cloud Function’da kullanmak için: Firebase’de Functions config’e `ANDROID_SHA256_FINGERPRINT` ekleyin veya `functions/src/ilanPageFunction.ts` içindeki `getWellKnown` fonksiyonunda `SHA256_FINGERPRINT_HERE` yerine parmak izinizi yazın (iki nokta üst üste olmadan, küçük harf, örn. `aa:bb:cc:...` → `AABBCC...` formatında değil, Google’ın beklediği tek satır formatında).

Doğrulama:  
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://canlipazar.net&relation=delegate_permission/common.handle_all_urls

---

## 4. Link formatı ve uygulama tarafı

- **Paylaşım / deep link formatı:** `https://canlipazar.net/ilan/[ilan_id]`
- Tarayıcıda bu link açıldığında:
  - Uygulama yüklüyse: iOS Universal Links / Android App Links ile uygulama açılır.
  - Uygulama yoksa: Firebase Hosting’deki **ilan landing sayfası** (getIlanPage Cloud Function) gösterilir; ilan özeti (resim, başlık) ve **“Uygulamayı Aç”** / mağaza butonları sunulur.

---

## 5. Özet kontrol listesi

- [ ] Firebase Console’da Hosting’e **canlipazar.net** custom domain olarak eklendi.
- [ ] Domain sahipliği için **TXT** kaydı eklendi ve doğrulandı.
- [ ] **A** kayıtları (Firebase’in verdiği IP’ler) eklendi.
- [ ] `firebase deploy --only hosting` (ve gerekirse `firebase deploy --only functions:getIlanPage`) çalıştırıldı.
- [ ] `https://canlipazar.net/.well-known/apple-app-site-association` ve `https://canlipazar.net/.well-known/assetlinks.json` tarayıcıda açılıyor.
- [ ] iOS’ta **Runner.entitlements** içinde `applinks:canlipazar.net` var.
- [ ] Android **AndroidManifest.xml** içinde `canlipazar.net` için intent-filter’lar var.
- [ ] `https://canlipazar.net/ilan/BIR_ILAN_ID` tarayıcıda ilan özeti ve “Uygulamayı Aç” sayfasını gösteriyor.
