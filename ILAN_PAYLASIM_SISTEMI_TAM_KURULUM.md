# 🚀 İlan Paylaşım Sistemi - Production-Ready Tam Kurulum

## 📋 İçindekiler
1. [Genel Bakış](#genel-bakış)
2. [Firebase Dynamic Links Kurulumu](#firebase-dynamic-links-kurulumu)
3. [iOS Universal Links Kurulumu](#ios-universal-links-kurulumu)
4. [Android App Links Kurulumu](#android-app-links-kurulumu)
5. [Flutter Kod Entegrasyonu](#flutter-kod-entegrasyonu)
6. [Sosyal Medya Önizleme (Open Graph)](#sosyal-medya-önizleme-open-graph)
7. [Hata Ayıklama ve Çözümler](#hata-ayıklama-ve-çözümler)
8. [Kontrol Checklist'i](#kontrol-checklisti)

---

## 🎯 Genel Bakış

Bu sistem şu özellikleri sağlar:
- ✅ Her ilan için benzersiz paylaşım linki: `https://canlipazar.com/ilan/{ilanId}`
- ✅ Uygulama yüklüyse → İlan sayfasını açar
- ✅ Uygulama yüklü değilse → App Store / Play Store'a yönlendirir
- ✅ WhatsApp / Telegram / Facebook'ta önizleme gösterir
- ✅ iOS ve Android'de tam destek

---

## 1️⃣ Firebase Dynamic Links Kurulumu

### Adım 1: Firebase Console Ayarları

1. **Firebase Console'a giriş yapın**: https://console.firebase.google.com
2. Projenizi seçin: `canlipazar-b3697`
3. **Dynamic Links** bölümüne gidin (sol menü)
4. **Yeni Dynamic Link domain'i oluşturun**: `canlipazar.page.link`
5. Domain'i doğrulayın (DNS kayıtları gerekebilir)

### Adım 2: Dynamic Links API Key Alma

1. Firebase Console → **Project Settings** → **General**
2. **Web API Key**'i kopyalayın
3. Cloud Functions environment variable olarak ekleyin:

```bash
firebase functions:config:set firebase.api_key="YOUR_API_KEY_HERE"
```

---

## 2️⃣ iOS Universal Links Kurulumu

### Adım 1: Associated Domains Yapılandırması

#### ✅ Runner.entitlements (Zaten Mevcut)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:canlipazar.page.link</string>
		<string>applinks:canlipazar.com</string>
		<string>applinks:www.canlipazar.com</string>
	</array>
</dict>
</plist>
```

#### ✅ Info.plist (Zaten Mevcut)

```xml
<key>FirebaseDynamicLinksCustomDomains</key>
<array>
	<string>https://canlipazar.page.link</string>
</array>
```

### Adım 2: AppDelegate.swift - Universal Links Handling

**KRİTİK**: AppDelegate.swift dosyasına Universal Links handling ekleyin:

```swift
// ios/Runner/AppDelegate.swift dosyasına ekleyin

import UIKit
import Flutter
import Firebase
// ... mevcut import'lar

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // ... mevcut kod ...
  
  // MARK: - Universal Links Handling
  
  /// KRİTİK: Universal Links - Uygulama açıkken veya kapalıyken link'ten açıldığında
  /// iOS 9+ için gerekli
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    print("🔗 [AppDelegate] Universal Link alındı")
    
    // Universal Link kontrolü
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      guard let url = userActivity.webpageURL else {
        print("❌ [AppDelegate] Universal Link URL bulunamadı")
        return false
      }
      
      print("🔗 [AppDelegate] Universal Link URL: \(url)")
      
      // Flutter tarafına bildir
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.canlipazar/universal_link",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("handleUniversalLink", arguments: url.absoluteString)
        print("✅ [AppDelegate] Universal Link Flutter'a gönderildi")
      }
      
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  /// KRİTİK: Custom URL Scheme - canlipazar://ilan/{postId}
  /// iOS 9+ için gerekli
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("🔗 [AppDelegate] Custom URL Scheme alındı: \(url)")
    
    // Custom scheme kontrolü
    if url.scheme == "canlipazar" {
      // Flutter tarafına bildir
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.canlipazar/universal_link",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("handleUniversalLink", arguments: url.absoluteString)
        print("✅ [AppDelegate] Custom URL Scheme Flutter'a gönderildi")
      }
      
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
```

### Adım 3: Apple Developer Portal Ayarları

1. **Apple Developer Portal'a giriş yapın**: https://developer.apple.com
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. App ID'nizi seçin: `com.canlipazar.app`
4. **Associated Domains** capability'sini etkinleştirin
5. Şu domain'leri ekleyin:
   - `applinks:canlipazar.page.link`
   - `applinks:canlipazar.com`
   - `applinks:www.canlipazar.com`

### Adım 4: Web Sunucu - apple-app-site-association Dosyası

**KRİTİK**: Web sunucunuzda şu dosyayı oluşturun:

**Dosya Yolu**: `https://canlipazar.com/.well-known/apple-app-site-association`

**İçerik** (JSON format, Content-Type: application/json):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.canlipazar.app",
        "paths": [
          "/ilan/*",
          "/animal/*"
        ]
      }
    ]
  }
}
```

**ÖNEMLİ NOTLAR**:
- `TEAM_ID` yerine gerçek Apple Developer Team ID'nizi yazın
- Dosya **Content-Type: application/json** olmalı (text/plain değil!)
- Dosya **HTTPS** üzerinden erişilebilir olmalı
- Dosya **redirect** yapmamalı (301/302 yok)
- Dosya **gzip** ile sıkıştırılmamalı

**Nginx Örnek Yapılandırması**:

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '{"applinks":{"apps":[],"details":[{"appID":"TEAM_ID.com.canlipazar.app","paths":["/ilan/*","/animal/*"]}]}}';
}
```

**Apache Örnek Yapılandırması**:

```apache
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
</Files>
```

**Doğrulama**:

```bash
# Terminal'de test edin
curl -I https://canlipazar.com/.well-known/apple-app-site-association

# Beklenen çıktı:
# HTTP/1.1 200 OK
# Content-Type: application/json
```

---

## 3️⃣ Android App Links Kurulumu

### Adım 1: AndroidManifest.xml (Zaten Mevcut)

AndroidManifest.xml dosyasında App Links intent-filter'ları zaten mevcut:

```xml
<!-- Android App Links - https://canlipazar.com/ilan/{postId} -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="canlipazar.com"
        android:pathPrefix="/ilan"/>
</intent-filter>
```

### Adım 2: SHA-256 Fingerprint Alma

**KRİTİK**: Android App Links için SHA-256 fingerprint gerekli.

#### Production (Release) Key:

```bash
# Keystore dosyanızın yolunu belirtin
keytool -list -v -keystore ~/path/to/your/keystore.jks -alias your-key-alias

# SHA-256 fingerprint'i kopyalayın
```

#### Debug Key:

```bash
# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# SHA-256 fingerprint'i kopyalayın
```

### Adım 3: Web Sunucu - assetlinks.json Dosyası

**KRİTİK**: Web sunucunuzda şu dosyayı oluşturun:

**Dosya Yolu**: `https://canlipazar.com/.well-known/assetlinks.json`

**İçerik** (JSON format):

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.canlipazar",
    "sha256_cert_fingerprints": [
      "SHA256_FINGERPRINT_1",
      "SHA256_FINGERPRINT_2"
    ]
  }
}]
```

**ÖNEMLİ NOTLAR**:
- `SHA256_FINGERPRINT_1`: Production (Release) keystore SHA-256 fingerprint
- `SHA256_FINGERPRINT_2`: Debug keystore SHA-256 fingerprint (opsiyonel, test için)
- Dosya **Content-Type: application/json** olmalı
- Dosya **HTTPS** üzerinden erişilebilir olmalı
- Dosya **redirect** yapmamalı

**Nginx Örnek Yapılandırması**:

```nginx
location /.well-known/assetlinks.json {
    default_type application/json;
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '[{"relation":["delegate_permission/common.handle_all_urls"],"target":{"namespace":"android_app","package_name":"com.canlipazar","sha256_cert_fingerprints":["SHA256_FINGERPRINT_1","SHA256_FINGERPRINT_2"]}}]';
}
```

**Doğrulama**:

```bash
# Terminal'de test edin
curl https://canlipazar.com/.well-known/assetlinks.json

# Beklenen çıktı: JSON içeriği
```

### Adım 4: Android App Links Doğrulama

Android cihazda App Links'in doğrulandığını kontrol edin:

```bash
# ADB ile kontrol
adb shell pm get-app-links com.canlipazar

# Beklenen çıktı:
# com.canlipazar:
#     ID: ...
#     Signatures: [SHA256_FINGERPRINT]
#     Domain verification state:
#         canlipazar.com: verified
```

---

## 4️⃣ Flutter Kod Entegrasyonu

### Adım 1: Dynamic Link Service Güncelleme

`lib/services/dynamic_link_service.dart` dosyasını güncelleyin:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Dynamic Links servisi - Production Ready
class DynamicLinkService {
  static const String _androidPackageName = 'com.canlipazar';
  static const String _iosBundleId = 'com.canlipazar.app';
  static const String _iosAppStoreId = '6476391295'; // Gerçek App Store ID
  
  // Store URL'leri
  static const String _iosAppStoreUrl = 'https://apps.apple.com/app/id$_iosAppStoreId';
  static const String _androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=$_androidPackageName';
  
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// İlan için Dynamic Link oluştur
  /// 
  /// Firebase Dynamic Links API kullanarak short link oluşturur
  /// Uygulama yüklüyse → İlan sayfasını açar
  /// Uygulama yüklü değilse → Store'a yönlendirir
  /// 
  /// [ilanId] - İlan ID'si
  /// [ilanBaslik] - İlan başlığı (Open Graph için)
  /// [ilanAciklama] - İlan açıklaması (Open Graph için)
  /// [ilanResmiUrl] - İlan resmi URL'si (Open Graph için)
  /// 
  /// Returns: Dynamic Link URL'si (short link)
  Future<String> createDynamicLink({
    required String ilanId,
    required String ilanBaslik,
    required String ilanAciklama,
    required String ilanResmiUrl,
  }) async {
    try {
      print('🔗 Dynamic Link oluşturuluyor - İlan ID: $ilanId');
      
      // Deep link URL'si (Universal Link / App Link)
      final String deepLink = 'https://canlipazar.com/ilan/$ilanId';
      
      // Cloud Functions'ı çağır
      final callable = _functions.httpsCallable('createDynamicLink');
      
      final result = await callable.call({
        'deepLink': deepLink,
        'androidPackageName': _androidPackageName,
        'iosBundleId': _iosBundleId,
        'iosAppStoreId': _iosAppStoreId,
        'title': ilanBaslik,
        'description': ilanAciklama,
        'imageUrl': ilanResmiUrl,
      });
      
      final data = result.data as Map<String, dynamic>;
      final shortLink = data['shortLink'] as String? ?? deepLink;
      
      print('✅ Dynamic Link oluşturuldu: $shortLink');
      return shortLink;
    } catch (e, stackTrace) {
      print('❌ Dynamic Link oluşturma hatası: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Hata durumunda fallback olarak Universal Link döndür
      final String fallbackLink = 'https://canlipazar.com/ilan/$ilanId';
      print('⚠️ Fallback link kullanılıyor: $fallbackLink');
      return fallbackLink;
    }
  }
  
  /// Dynamic link'i parse et ve ilan ID'sini çıkar
  String? parseDynamicLink(Uri dynamicLink) {
    try {
      final String linkString = dynamicLink.toString();
      
      // Firebase Dynamic Links (canlipazar.page.link)
      if (linkString.contains('canlipazar.page.link')) {
        final uri = dynamicLink;
        if (uri.queryParameters.containsKey('link')) {
          final String deepLink = uri.queryParameters['link']!;
          return _extractIlanIdFromDeepLink(deepLink);
        }
        // Short link formatı için Cloud Functions'tan resolve etmek gerekir
        // Şimdilik path'ten ID çıkarmayı deneyelim
        if (uri.pathSegments.isNotEmpty) {
          // Short link için fallback
          return null;
        }
      }
      
      // Universal Link / App Link formatı
      return _extractIlanIdFromDeepLink(linkString);
    } catch (e) {
      print('❌ Dynamic link parse hatası: $e');
      return null;
    }
  }
  
  /// Deep link'ten ilan ID'sini çıkar
  String? _extractIlanIdFromDeepLink(String deepLink) {
    try {
      // /ilan/{ilanId} formatını kontrol et
      if (deepLink.contains('/ilan/')) {
        final List<String> parts = deepLink.split('/ilan/');
        if (parts.length > 1) {
          final String ilanId = parts[1].split('?')[0].split('#')[0];
          return ilanId;
        }
      }
      // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
      if (deepLink.contains('/animal/')) {
        final List<String> parts = deepLink.split('/animal/');
        if (parts.length > 1) {
          final String ilanId = parts[1].split('?')[0].split('#')[0];
          return ilanId;
        }
      }
      return null;
    } catch (e) {
      print('❌ Deep link parse hatası: $e');
      return null;
    }
  }
}
```

### Adım 2: Main.dart - Universal Links Handling

`lib/main.dart` dosyasına Universal Links handling ekleyin:

```dart
// lib/main.dart dosyasına ekleyin

import 'package:flutter/services.dart';

class MyApp extends StatefulWidget {
  // ... mevcut kod ...
  
  @override
  void initState() {
    super.initState();
    // ... mevcut kod ...
    
    // KRİTİK: iOS Universal Links için method channel
    if (!kIsWeb && io.Platform.isIOS) {
      _setupUniversalLinksChannel();
    }
  }
  
  /// iOS Universal Links için method channel setup
  void _setupUniversalLinksChannel() {
    const MethodChannel channel = MethodChannel('com.canlipazar/universal_link');
    
    channel.setMethodCallHandler((call) async {
      if (call.method == 'handleUniversalLink') {
        final String link = call.arguments as String;
        print('🔗 [Flutter] Universal Link alındı: $link');
        
        // Context hazır olana kadar bekle
        Future.delayed(Duration(milliseconds: 500), () {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _handleDeepLinkFromStream(link);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final context = navigatorKey.currentContext;
              if (context != null) {
                _handleDeepLinkFromStream(link);
              }
            });
          }
        });
      }
    });
  }
  
  // ... mevcut kod ...
}
```

### Adım 3: Deep Link Handling Güncelleme

`lib/main.dart` dosyasındaki `_navigateToDeepLink` fonksiyonunu güncelleyin:

```dart
void _navigateToDeepLink(BuildContext context, String deepLink) {
  try {
    final uri = Uri.parse(deepLink);
    String? postId;
    
    print('🔗 Deep link parse ediliyor: $deepLink');
    
    // canlipazar://ilan/{postId} formatı
    if (uri.scheme == 'canlipazar' && (uri.host == 'ilan' || uri.host == 'animal')) {
      postId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      print('✅ Custom scheme link: postId=$postId');
    } 
    // https://canlipazar.com/ilan/{postId} formatı (Universal Link / App Link)
    else if (uri.scheme == 'https' && 
             (uri.host == 'canlipazar.com' || 
              uri.host == 'www.canlipazar.com')) {
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'ilan') {
        postId = uri.pathSegments[1];
        print('✅ Universal/App Link (/ilan/): postId=$postId');
      } 
      // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
      else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'animal') {
        postId = uri.pathSegments[1];
        print('✅ Universal/App Link (/animal/): postId=$postId');
      }
    } 
    // Firebase Dynamic Links (canlipazar.page.link)
    else if (uri.scheme == 'https' && uri.host == 'canlipazar.page.link') {
      // Dynamic link'ten deep link'i çıkar
      if (uri.queryParameters.containsKey('link')) {
        final String extractedLink = uri.queryParameters['link']!;
        print('✅ Dynamic Link: extractedLink=$extractedLink');
        
        // /ilan/ formatını kontrol et
        if (extractedLink.contains('/ilan/')) {
          final List<String> parts = extractedLink.split('/ilan/');
          if (parts.length > 1) {
            postId = parts[1].split('?')[0].split('#')[0];
            print('✅ Dynamic Link (/ilan/): postId=$postId');
          }
        }
        // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
        else if (extractedLink.contains('/animal/')) {
          final List<String> parts = extractedLink.split('/animal/');
          if (parts.length > 1) {
            postId = parts[1].split('?')[0].split('#')[0];
            print('✅ Dynamic Link (/animal/): postId=$postId');
          }
        }
      }
      // Short link formatı: canlipazar.page.link/xxxxx
      else if (uri.pathSegments.isNotEmpty) {
        // Short link için Cloud Functions'tan resolve etmek gerekir
        print('⚠️ Short link formatı, Cloud Functions resolve gerekebilir');
        // Şimdilik path'ten ID çıkarmayı deneyelim (fallback)
      }
    }
    
    // İlan sayfasına yönlendir
    if (postId != null && postId.isNotEmpty) {
      print('✅ İlan sayfasına yönlendiriliyor: $postId');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('animals')
                .doc(postId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return Scaffold(
                  appBar: AppBar(title: Text('Hata')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('İlan bulunamadı'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                final animal = AnimalPost.fromSnap(snapshot.data!);
                return AnimalDetailScreen(animal: animal);
              } catch (e) {
                return Scaffold(
                  appBar: AppBar(title: Text('Hata')),
                  body: Center(child: Text('İlan yüklenemedi: $e')),
                );
              }
            },
          ),
        ),
      );
    } else {
      print('⚠️ İlan ID bulunamadı: $deepLink');
    }
  } catch (e) {
    print('❌ Deep link parse hatası: $e');
  }
}
```

---

## 5️⃣ Sosyal Medya Önizleme (Open Graph)

### Adım 1: Web Sayfası - Open Graph Meta Tag'leri

Web sunucunuzda ilan sayfası için Open Graph meta tag'leri ekleyin.

**Dosya Yolu**: `https://canlipazar.com/ilan/{ilanId}` (veya Cloud Functions ile dinamik)

**HTML Örneği**:

```html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Open Graph Meta Tags -->
    <meta property="og:type" content="website">
    <meta property="og:title" content="İlan Başlığı">
    <meta property="og:description" content="İlan Açıklaması">
    <meta property="og:image" content="https://canlipazar.com/ilan-resmi.jpg">
    <meta property="og:url" content="https://canlipazar.com/ilan/ILAN_ID">
    <meta property="og:site_name" content="CanlıPazar">
    
    <!-- Twitter Card Meta Tags -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="İlan Başlığı">
    <meta name="twitter:description" content="İlan Açıklaması">
    <meta name="twitter:image" content="https://canlipazar.com/ilan-resmi.jpg">
    
    <!-- iOS Universal Links -->
    <meta name="apple-itunes-app" content="app-id=6476391295">
    
    <!-- Android App Links -->
    <link rel="alternate" href="android-app://com.canlipazar/https/canlipazar.com/ilan/ILAN_ID">
    
    <title>İlan Başlığı - CanlıPazar</title>
</head>
<body>
    <!-- İlan içeriği -->
    <h1>İlan Başlığı</h1>
    <p>İlan Açıklaması</p>
    <img src="https://canlipazar.com/ilan-resmi.jpg" alt="İlan Resmi">
    
    <!-- Uygulama yüklü değilse Store'a yönlendir -->
    <script>
        // iOS için
        if (/iPhone|iPad|iPod/.test(navigator.userAgent)) {
            window.location.href = 'https://apps.apple.com/app/id6476391295';
        }
        // Android için
        else if (/Android/.test(navigator.userAgent)) {
            window.location.href = 'https://play.google.com/store/apps/details?id=com.canlipazar';
        }
    </script>
</body>
</html>
```

### Adım 2: Cloud Functions - Dinamik HTML Sayfası

`functions/src/ilanPageFunction.ts` dosyasını güncelleyin (zaten mevcut, kontrol edin):

```typescript
// functions/src/ilanPageFunction.ts

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * İlan sayfası için HTML oluştur
 * Path: https://canlipazar.com/ilan/{ilanId}
 */
export const ilanPage = functions.https.onRequest(async (req, res) => {
  const ilanId = req.path.split('/ilan/')[1]?.split('?')[0]?.split('#')[0];
  
  if (!ilanId) {
    res.status(404).send('İlan bulunamadı');
    return;
  }
  
  try {
    // Firestore'dan ilan bilgilerini al
    const ilanDoc = await admin.firestore().collection('animals').doc(ilanId).get();
    
    if (!ilanDoc.exists) {
      res.status(404).send('İlan bulunamadı');
      return;
    }
    
    const ilanData = ilanDoc.data()!;
    const ilanBaslik = ilanData.animalBreed || ilanData.animalSpecies || 'İlan';
    const ilanAciklama = ilanData.description || 'Hayvan alım satımı';
    const ilanResmi = ilanData.photoUrls?.[0] || 'https://canlipazar.com/default-image.jpg';
    const ilanFiyat = ilanData.priceInTL || 0;
    
    // HTML oluştur
    const html = `
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Open Graph Meta Tags -->
    <meta property="og:type" content="website">
    <meta property="og:title" content="${ilanBaslik} - ${ilanFiyat} ₺">
    <meta property="og:description" content="${ilanAciklama.substring(0, 200)}">
    <meta property="og:image" content="${ilanResmi}">
    <meta property="og:url" content="https://canlipazar.com/ilan/${ilanId}">
    <meta property="og:site_name" content="CanlıPazar">
    
    <!-- Twitter Card Meta Tags -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${ilanBaslik} - ${ilanFiyat} ₺">
    <meta name="twitter:description" content="${ilanAciklama.substring(0, 200)}">
    <meta name="twitter:image" content="${ilanResmi}">
    
    <!-- iOS Universal Links -->
    <meta name="apple-itunes-app" content="app-id=6476391295">
    
    <!-- Android App Links -->
    <link rel="alternate" href="android-app://com.canlipazar/https/canlipazar.com/ilan/${ilanId}">
    
    <title>${ilanBaslik} - CanlıPazar</title>
</head>
<body>
    <h1>${ilanBaslik}</h1>
    <p>${ilanAciklama}</p>
    <p>Fiyat: ${ilanFiyat} ₺</p>
    <img src="${ilanResmi}" alt="${ilanBaslik}">
    
    <!-- Uygulama yüklü değilse Store'a yönlendir -->
    <script>
        // iOS için
        if (/iPhone|iPad|iPod/.test(navigator.userAgent)) {
            window.location.href = 'https://apps.apple.com/app/id6476391295';
        }
        // Android için
        else if (/Android/.test(navigator.userAgent)) {
            window.location.href = 'https://play.google.com/store/apps/details?id=com.canlipazar';
        }
    </script>
</body>
</html>
    `;
    
    res.set('Content-Type', 'text/html');
    res.send(html);
  } catch (error) {
    console.error('İlan sayfası oluşturma hatası:', error);
    res.status(500).send('Sunucu hatası');
  }
});
```

---

## 6️⃣ Hata Ayıklama ve Çözümler

### Sorun 1: "Link tıklanıyor ama uygulama açılmıyor"

#### iOS için Çözümler:

1. **Associated Domains kontrolü**:
   ```bash
   # Xcode'da kontrol edin
   # Target → Signing & Capabilities → Associated Domains
   # applinks:canlipazar.com olmalı
   ```

2. **apple-app-site-association dosyası kontrolü**:
   ```bash
   curl -I https://canlipazar.com/.well-known/apple-app-site-association
   # Content-Type: application/json olmalı
   ```

3. **Team ID kontrolü**:
   ```bash
   # Apple Developer Portal'da Team ID'nizi kontrol edin
   # apple-app-site-association dosyasında doğru Team ID kullanın
   ```

4. **Universal Links test**:
   ```bash
   # iPhone'da Safari'de test edin
   # https://canlipazar.com/ilan/test123
   # Link'e uzun basın → "Open in CanlıPazar" görünmeli
   ```

#### Android için Çözümler:

1. **App Links doğrulama**:
   ```bash
   adb shell pm get-app-links com.canlipazar
   # canlipazar.com: verified olmalı
   ```

2. **assetlinks.json kontrolü**:
   ```bash
   curl https://canlipazar.com/.well-known/assetlinks.json
   # JSON içeriği dönmeli
   ```

3. **SHA-256 fingerprint kontrolü**:
   ```bash
   # assetlinks.json dosyasında doğru SHA-256 fingerprint olmalı
   keytool -list -v -keystore ~/path/to/keystore.jks -alias your-alias
   ```

### Sorun 2: "iOS'ta çalışıyor Android'te çalışmıyor"

#### Çözümler:

1. **AndroidManifest.xml kontrolü**:
   ```xml
   <!-- android:autoVerify="true" olmalı -->
   <intent-filter android:autoVerify="true">
   ```

2. **Package name kontrolü**:
   ```xml
   <!-- AndroidManifest.xml'de package name doğru olmalı -->
   <manifest package="com.canlipazar">
   ```

3. **App Links doğrulama**:
   ```bash
   adb shell pm verify-app-links --re-verify com.canlipazar
   ```

### Sorun 3: "WhatsApp'ta önizleme çıkmıyor"

#### Çözümler:

1. **Open Graph meta tag'leri kontrolü**:
   ```html
   <!-- og:title, og:description, og:image olmalı -->
   <meta property="og:title" content="İlan Başlığı">
   <meta property="og:description" content="İlan Açıklaması">
   <meta property="og:image" content="https://canlipazar.com/resim.jpg">
   ```

2. **Görsel URL kontrolü**:
   ```bash
   # Görsel URL'si HTTPS olmalı ve erişilebilir olmalı
   curl -I https://canlipazar.com/resim.jpg
   # HTTP/1.1 200 OK dönmeli
   ```

3. **WhatsApp cache temizleme**:
   - WhatsApp'ta link'i tekrar paylaşın
   - WhatsApp cache'i temizleyin (Ayarlar → Depolama → Cache temizle)

4. **Open Graph Debugger test**:
   ```bash
   # Facebook Debugger ile test edin
   # https://developers.facebook.com/tools/debug/
   # URL'yi girin ve "Scrape Again" butonuna tıklayın
   ```

---

## 7️⃣ Kontrol Checklist'i

### ✅ Firebase Console

- [ ] Dynamic Links domain oluşturuldu: `canlipazar.page.link`
- [ ] Domain doğrulandı
- [ ] API Key alındı ve Cloud Functions'a eklendi

### ✅ iOS Yapılandırması

- [ ] `Runner.entitlements` dosyasında Associated Domains var
- [ ] `Info.plist` dosyasında FirebaseDynamicLinksCustomDomains var
- [ ] `AppDelegate.swift` dosyasında Universal Links handling var
- [ ] Apple Developer Portal'da Associated Domains etkin
- [ ] `apple-app-site-association` dosyası web sunucuda mevcut
- [ ] `apple-app-site-association` dosyası Content-Type: application/json
- [ ] Team ID doğru

### ✅ Android Yapılandırması

- [ ] `AndroidManifest.xml` dosyasında App Links intent-filter var
- [ ] `android:autoVerify="true"` ayarlı
- [ ] SHA-256 fingerprint alındı
- [ ] `assetlinks.json` dosyası web sunucuda mevcut
- [ ] `assetlinks.json` dosyasında doğru SHA-256 fingerprint var
- [ ] App Links doğrulandı (`adb shell pm get-app-links`)

### ✅ Flutter Kod

- [ ] `DynamicLinkService` güncellendi
- [ ] `main.dart` dosyasında Universal Links handling var
- [ ] Deep link parsing doğru çalışıyor
- [ ] İlan sayfasına yönlendirme çalışıyor

### ✅ Web Sunucu

- [ ] `apple-app-site-association` dosyası mevcut
- [ ] `assetlinks.json` dosyası mevcut
- [ ] Open Graph meta tag'leri mevcut
- [ ] İlan sayfası dinamik olarak oluşturuluyor

### ✅ Test

- [ ] iOS'ta Universal Links çalışıyor
- [ ] Android'de App Links çalışıyor
- [ ] WhatsApp'ta önizleme görünüyor
- [ ] Telegram'da önizleme görünüyor
- [ ] Facebook'ta önizleme görünüyor
- [ ] Uygulama yüklüyse ilan sayfası açılıyor
- [ ] Uygulama yüklü değilse Store'a yönlendiriliyor

---

## 🎉 Tamamlandı!

Bu kurulum ile ilan paylaşım sistemi production-ready olarak çalışacaktır. Herhangi bir sorunla karşılaşırsanız, yukarıdaki "Hata Ayıklama ve Çözümler" bölümüne bakın.










