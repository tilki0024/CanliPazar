# PhaseScriptExecution Hatası Çözümü

## 🔍 Sorun
```
Command PhaseScriptExecution failed with a nonzero exit code
```

Bu hata genellikle Flutter'ın kurulu olmaması veya Flutter path'inin yanlış ayarlanmasından kaynaklanır.

## ✅ Çözüm Adımları

### ADIM 1: Flutter'ı Yükle

Flutter henüz yüklü değil. Şu adımları takip edin:

1. **Flutter'ı İndir**
   ```bash
   cd ~/Desktop
   curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_stable.zip -o flutter.zip
   unzip flutter.zip
   ```

2. **Flutter'ı PATH'e Ekle** (opsiyonel)
   ```bash
   echo 'export PATH="$PATH:$HOME/Desktop/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Flutter'ı Doğrula**
   ```bash
   ~/Desktop/flutter/bin/flutter doctor
   ```

### ADIM 2: Flutter Path'ini Güncelle

Eğer Flutter farklı bir yerde kuruluysa:

1. Flutter'ın konumunu bul:
   ```bash
   find ~ -name "flutter" -type d 2>/dev/null | grep -E "flutter/bin"
   ```

2. `ios/Flutter/Generated.xcconfig` dosyasını güncelle:
   ```bash
   cd /Users/mustafatilki/Desktop/CanliPazar-main
   flutter pub get
   ```

   Bu komut `Generated.xcconfig` dosyasını otomatik olarak güncelleyecektir.

### ADIM 3: Projeyi Temizle ve Yeniden Build Et

```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main

# Flutter temizle
flutter clean

# Pod'ları temizle
cd ios
rm -rf Pods Podfile.lock .symlinks

# Pod'ları yeniden yükle
pod install --repo-update

# Xcode Derived Data'yı temizle
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### ADIM 4: Xcode'da Build Et

1. Xcode'u aç:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Xcode'da:
   - **Product** > **Clean Build Folder** (⇧⌘K)
   - **Product** > **Build** (⌘B)

## 🔧 Yapılan Düzeltmeler

Build script'leri güncellendi:
- Script'ler artık `flutter_export_environment.sh` dosyasını source ediyor
- Bu sayede `FLUTTER_ROOT` değişkeni doğru ayarlanıyor

## ⚠️ Önemli Notlar

1. **Flutter Kurulumu Zorunlu**: Flutter olmadan iOS build yapılamaz
2. **Xcode Gereksinimleri**: Xcode ve Command Line Tools yüklü olmalı
3. **CocoaPods**: `pod install` komutu çalışmalı

## 🎯 Hızlı Çözüm (Tek Komut)

Flutter yüklüyse:

```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main && \
flutter clean && \
cd ios && \
rm -rf Pods Podfile.lock .symlinks && \
pod install --repo-update && \
rm -rf ~/Library/Developer/Xcode/DerivedData && \
open Runner.xcworkspace
```

Sonra Xcode'da:
- **Product** > **Clean Build Folder** (⇧⌘K)
- **Product** > **Build** (⌘B)

## 📞 Sorun Devam Ederse

1. Flutter'ın doğru yüklendiğini kontrol et:
   ```bash
   ~/Desktop/flutter/bin/flutter doctor
   ```

2. Xcode build log'larını kontrol et:
   - Xcode'da **View** > **Navigators** > **Show Report Navigator**
   - Hata mesajlarını incele

3. Flutter path'ini manuel kontrol et:
   ```bash
   cat ios/Flutter/Generated.xcconfig | grep FLUTTER_ROOT
   ```

































