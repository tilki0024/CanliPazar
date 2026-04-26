# Podfile "No such module 'Flutter'" Hatası Çözümü

## 🔍 Sorun
```
No such module 'Flutter'
/Users/mustafatilki/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.3/ios/url_launcher_ios/Sources/url_launcher_ios/messages.g.swift:10:10
```

## ✅ Çözüm: Xcode'dan Pod Install

### Adım 1: Xcode'u Aç
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main
open ios/Runner.xcworkspace
```

### Adım 2: Terminal'den Pod Install
Xcode açıldıktan sonra:

1. Xcode'un alt kısmındaki **Terminal** sekmesine tıkla (veya View > Show Terminal)
2. Şu komutu çalıştır:
   ```bash
   cd /Users/mustafatilki/Desktop/CanliPazar-main/ios
   pod install --repo-update
   ```

### Adım 3: Alternatif - Xcode'dan Build
Eğer pod install çalışmazsa:

1. Xcode'da **Product** > **Clean Build Folder** (⇧⌘K)
2. Xcode'da **Product** > **Build** (⌘B)
3. Xcode otomatik olarak pod'ları yükleyecek

## 🔧 Manuel Çözüm (Eğer yukarıdakiler çalışmazsa)

### Flutter Path'ini Bul
1. Terminal'de şu komutu çalıştır:
   ```bash
   which flutter
   ```
   
2. Eğer Flutter bulunursa, path'i not et (örn: `/usr/local/flutter`)

3. `ios/Flutter/Generated.xcconfig` dosyasını aç ve `FLUTTER_ROOT` değerini güncelle:
   ```
   FLUTTER_ROOT=/usr/local/flutter
   ```
   (Bulduğun path'i yaz)

### Pod'ları Temizle ve Yeniden Yükle
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main/ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
```

## 📱 Xcode'dan Çalıştırma

1. Xcode'da **Runner** target'ını seç
2. Üstteki cihaz seçiciden **gerçek bir iOS cihaz** seç
3. **Product** > **Run** (⌘R) veya Play butonuna tıkla

Xcode otomatik olarak:
- Pod'ları yükleyecek
- Flutter framework'ünü bulacak
- Projeyi derleyecek

## ⚠️ Not

Eğer Flutter komutu bulunamıyorsa:
- Flutter'ı yükle: https://docs.flutter.dev/get-started/install
- Veya Flutter path'ini PATH'e ekle

Xcode genellikle kendi Flutter path'ini bulabilir, bu yüzden Xcode'dan direkt çalıştırmayı dene!



































