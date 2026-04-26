# Firebase Dynamic Links Kurulum Rehberi

## Özet

Bu projede Firebase Dynamic Links sistemi entegre edilmiştir. Her ilan için dinamik link oluşturulur ve paylaşılabilir.

## Özellikler

✅ Uygulama yüklüyse direkt ilan sayfasını açar
✅ Uygulama yüklü değilse App Store/Play Store'a yönlendirir
✅ Sosyal medya önizlemesi (başlık, açıklama, resim)
✅ iOS Associated Domains ayarları
✅ Android intent-filter ayarları
✅ Flutter tarafında dynamic link oluşturma ve yakalama

## Kurulum Adımları

### 1. Firebase Console Ayarları

1. Firebase Console'a giriş yapın: https://console.firebase.google.com
2. Projenizi seçin
3. **Dynamic Links** bölümüne gidin
4. Yeni bir Dynamic Link domain'i oluşturun: `canlipazar.page.link`
5. Domain'i doğrulayın

### 2. iOS Ayarları

#### Associated Domains

`ios/Runner/Runner.entitlements` dosyasına şu satırlar eklenmiştir:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:canlipazar.page.link</string>
    <string>applinks:canlipazar.com</string>
</array>
```

#### Info.plist

`ios/Runner/Info.plist` dosyasına şu satırlar eklenmiştir:

```xml
<key>FirebaseDynamicLinksCustomDomains</key>
<array>
    <string>https://canlipazar.page.link</string>
</array>
```

#### Apple Developer Portal

1. Apple Developer Portal'a giriş yapın
2. App ID'nizi seçin (`com.canlipazar.app`)
3. **Associated Domains** capability'sini etkinleştirin
4. Şu domain'leri ekleyin:
   - `applinks:canlipazar.page.link`
   - `applinks:canlipazar.com`

### 3. Android Ayarları

#### AndroidManifest.xml

`android/app/src/main/AndroidManifest.xml` dosyasına şu intent-filter eklenmiştir:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="canlipazar.page.link"/>
</intent-filter>
```

#### Digital Asset Links

1. `https://canlipazar.com/.well-known/assetlinks.json` dosyası oluşturun:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.canlipazar.app",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT"
    ]
  }
}]
```

2. SHA256 fingerprint'i almak için:
```bash
keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 4. Cloud Functions

`functions/src/dynamicLinkFunctions.ts` dosyası oluşturulmuştur ve `createDynamicLink` fonksiyonu eklenmiştir.

#### Cloud Functions Deploy

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:createDynamicLink
```

#### Firebase API Key Ayarlama

Cloud Functions'ta Firebase API key'i ayarlayın:

```bash
firebase functions:config:set firebase.api_key="YOUR_FIREBASE_API_KEY"
```

Veya environment variable olarak:

```bash
firebase functions:config:set firebase.api_key="YOUR_FIREBASE_API_KEY"
```

### 5. App Store ID Güncelleme

`lib/services/dynamic_link_service.dart` dosyasında App Store ID'yi güncelleyin:

```dart
static const String _iosAppStoreId = '123456789'; // Gerçek App Store ID ile değiştirin
```

## Kullanım

### Dynamic Link Oluşturma

```dart
final dynamicLinkService = DynamicLinkService();

final String dynamicLink = await dynamicLinkService.createDynamicLink(
  ilanId: 'animal123',
  ilanBaslik: 'Holstein Sığır',
  ilanAciklama: 'Sağlıklı ve genç Holstein sığır satılık',
  ilanResmiUrl: 'https://example.com/image.jpg',
);
```

### Dynamic Link Yakalama

Dynamic link'ler otomatik olarak yakalanır ve ilan detay sayfasına yönlendirilir. `main.dart` içinde `_initDeepLinkHandler()` fonksiyonu bu işlemi yapar.

## Test

### iOS Test

1. Uygulamayı iOS cihaza yükleyin
2. Dynamic link'i Safari'de açın
3. Uygulama açılmalı ve ilan sayfasına yönlendirilmeli

### Android Test

1. Uygulamayı Android cihaza yükleyin
2. Dynamic link'i Chrome'da açın
3. Uygulama açılmalı ve ilan sayfasına yönlendirilmeli

## Sorun Giderme

### Link açılmıyor

1. Associated Domains doğru ayarlanmış mı kontrol edin
2. Digital Asset Links doğru yapılandırılmış mı kontrol edin
3. Firebase Console'da Dynamic Links domain'i doğru mu kontrol edin

### Cloud Functions hatası

1. Firebase API key doğru ayarlanmış mı kontrol edin
2. Cloud Functions deploy edilmiş mi kontrol edin
3. Firebase Console'da Cloud Functions loglarını kontrol edin

## Notlar

- Firebase Dynamic Links artık deprecated olduğu için, bu sistem Cloud Functions üzerinden çalışır
- Yeni projeler için Firebase App Check ve App Links kullanılması önerilir
- Mevcut projeler için bu sistem çalışmaya devam edecektir






























