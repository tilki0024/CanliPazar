# 🚀 Flutter Kurulum Talimatları

## ✅ Hızlı Çözüm (Homebrew ile)

Homebrew kurulu, Flutter'ı kurmak için:

```bash
# Flutter'ı kur
brew install --cask flutter

# Terminal'i yeniden başlat veya
source ~/.zshrc

# Flutter'ı test et
flutter --version
flutter doctor
```

## 📋 Adım Adım

### 1. Flutter Kurulumu

```bash
brew install --cask flutter
```

Bu komut Flutter'ı `/opt/homebrew/Caskroom/flutter/` dizinine kuracak ve PATH'e otomatik ekleyecek.

### 2. Terminal'i Yeniden Başlat

```bash
# Yeni terminal açın veya
source ~/.zshrc
```

### 3. Flutter'ı Doğrula

```bash
flutter --version
# Beklenen: Flutter 3.x.x • channel stable

flutter doctor
# Tüm bileşenlerin ✅ olduğundan emin olun
```

### 4. Projeyi Hazırla

```bash
cd ~/Desktop/CanliPazar-main

# Dependencies
flutter pub get

# iOS dependencies
cd ios
pod install
cd ..
```

### 5. Projeyi Çalıştır

```bash
# Cihaz listesi
flutter devices

# iOS cihazda çalıştır
flutter run -d "Ahmet iPhone'u"
```

## 🔧 Alternatif: Manuel Kurulum

Eğer Homebrew ile sorun yaşarsanız:

```bash
cd ~/Desktop
git clone https://github.com/flutter/flutter.git -b stable

# PATH zaten .zshrc'de var
source ~/.zshrc

flutter --version
```

## ⚠️ Önemli Notlar

1. **İlk kurulum uzun sürebilir** (5-10 dakika)
2. **İnternet bağlantısı gerekli**
3. **Xcode kurulu olmalı** (iOS için)
4. **Android Studio kurulu olmalı** (Android için)

## 🐛 Sorun Giderme

### "brew: command not found"
Homebrew kurulu değil, önce Homebrew'i kurun:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "flutter: command not found" (kurulumdan sonra)
Terminal'i yeniden başlatın veya:
```bash
source ~/.zshrc
```

### "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios
pod install
```

## 📞 Yardım

Kurulumdan sonra hata alırsanız:
1. `flutter doctor -v` çıktısını paylaşın
2. Hata mesajının tamamını paylaşın





