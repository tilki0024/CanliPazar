# iOS Bildirim Sorunu Çözüm Raporu

Lütfen aşağıdaki adımları dikkatlice takip edin. iOS bildirimlerinin çalışmaması için tespit edilen nedenler:

1. **Back-end Kodu Derlenmemişti:** iOS bildirimleri için gerekli olan `apns-topic` (Bundle ID) başlığı, kaynak kodda (`src/index.ts`) ekliydi ancak derlenmiş dosyaya (`lib/index.js`) yansımamıştı veya eski bir `index.js` dosyası kullanılıyordu.
2. **Eski Dosya Karmaşası:** Ana `functions` klasöründe eski ve eksik bir `index.js` dosyası mevcuttu. Bu dosya silindi ve proje yeniden derlendi.

## 1. APNs Anahtarını Firebase'e Yükleyin (Çok Önemli!)

Uygulamanız Firebase Cloud Messaging (FCM) kullanıyor. FCM'in iOS cihazlara bildirim gönderebilmesi için Apple Push Notifications Service (APNs) anahtarına ihtiyacı vardır.

1. **Firebase Console**'a gidin: [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Projenizi seçin.
3. Sol üstteki **Dişli İkonu** > **Project settings** (Proje ayarları)'na tıklayın.
4. **Cloud Messaging** sekmesine gidin.
5. **Apple app configuration** bölümünde iOS uygulamanızı seçin.
6. **APNs Authentication Key** bölümünde:
   - Eğer "Upload" butonu varsa, `.p8` uzantılı APNs anahtar dosyanızı yükleyin.
   - **Key ID**: Apple Developer Console'dan aldığınız Key ID (örn: `94D623A8F4`).
   - **Team ID**: Apple Developer Console'dan aldığınız Team ID (örn: `9W44LABURS`).
   - Henüz bir anahtarınız yoksa [Apple Developer Console](https://developer.apple.com/account/resources/authkeys/list) üzerinden oluşturun.

## 2. Cloud Functions'ı Yeniden Yükleyin (Deploy)

Sizin için `functions` klasöründe gerekli derleme işlemini (`npm run build`) gerçekleştirdim. Şimdi en güncel ve düzeltilmiş kodları yüklemeniz gerekiyor.

Terminalde şu komutu çalıştırın:

```bash
firebase deploy --only functions
```

## 3. Bundle ID Kontrolü yapın

Kod içerisinde Bundle ID `com.canlipazar.app` olarak ayarlanmıştır. Firebase Console'da iOS uygulamanızın Bundle ID'sinin bu olduğundan emin olun.

Proje Ayarları > General (Genel) > Your apps (Uygulamalarınız) > iOS kısmında "Bundle ID" görebilirsiniz.

## Özet
- ✅ Kod tarafındaki eksikler giderildi ve derlendi.
- ⏳ Sizin yapmanız gereken: APNs anahtarının Firebase Console'da yüklü olduğundan emin olmak ve fonksiyonları deploy etmek.
