# 📱 iOS Build Rehberi

## 🚀 Xcode ile Build Etme

### Adım 1: Xcode'u Aç
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main/ios
open Runner.xcworkspace
```

**ÖNEMLİ:** `.xcworkspace` dosyasını açın, `.xcodeproj` değil!

---

### Adım 2: Build Ayarları

1. **Xcode'da üst menüden:**
   - Product → Scheme → **Runner** seçin
   - Product → Destination → **Any iOS Device** veya **iPhone** seçin

2. **Signing & Capabilities:**
   - Runner target'ını seçin
   - **Signing & Capabilities** sekmesine gidin
   - **Team** seçin (Apple Developer hesabınız)
   - **Bundle Identifier:** `com.canlipazar.app` kontrol edin
   - **Automatically manage signing** işaretli olsun

---

### Adım 3: Build

#### A) Release Build (TestFlight/App Store için)
1. **Product → Scheme → Edit Scheme**
2. **Run** sekmesi → **Build Configuration:** **Release** seçin
3. **Product → Build** (⌘B) veya **Product → Archive** (⌘⇧B)

#### B) Archive (TestFlight/App Store için)
1. **Product → Archive** (⌘⇧B)
2. Archive tamamlandığında **Organizer** penceresi açılır
3. **Distribute App** butonuna tıklayın
4. **App Store Connect** seçin
5. **Upload** seçin
6. **Next** → **Next** → **Upload**

---

## 🔧 Terminal ile Build (Flutter PATH'te ise)

### Flutter PATH Kontrolü
```bash
which flutter
# Eğer sonuç boşsa, Flutter PATH'te değil
```

### Flutter PATH Ekleme
```bash
# ~/.zshrc veya ~/.bash_profile dosyasına ekleyin:
export PATH="$PATH:/path/to/flutter/bin"
```

### Build Komutları
```bash
cd /Users/mustafatilki/Desktop/CanliPazar-main

# Clean
flutter clean

# Dependencies
flutter pub get

# iOS Pods
cd ios && pod install && cd ..

# Release Build
flutter build ios --release

# Archive (Xcode gerekli)
flutter build ipa
```

---

## 📋 Önemli Notlar

### 1. CocoaPods Uyarısı
```
[!] CocoaPods did not set the base configuration...
```
Bu uyarı normaldir ve build'i engellemez.

### 2. Signing
- Apple Developer hesabınız olmalı
- Team seçilmeli
- Bundle ID doğru olmalı: `com.canlipazar.app`

### 3. Version
- Şu anki sürüm: **2.0.7+46**
- iOS'ta: `CFBundleShortVersionString` = 2.0.7
- iOS'ta: `CFBundleVersion` = 46

---

## ✅ Build Başarı Kontrolü

### Xcode Console'da Göreceğiniz:
```
✅ BUILD SUCCEEDED
```

### Archive Başarılı ise:
- **Organizer** penceresi açılır
- Archive listesinde yeni build görünür
- **Distribute App** butonu aktif olur

---

## 🚨 Hata Çözümleri

### Hata 1: "No signing certificate"
**Çözüm:** Xcode → Preferences → Accounts → Apple ID ekleyin

### Hata 2: "Bundle identifier already exists"
**Çözüm:** Bundle ID'yi değiştirin veya mevcut App ID'yi kullanın

### Hata 3: "Pod install failed"
**Çözüm:**
```bash
cd ios
pod deintegrate
pod install
```

---

## 📤 TestFlight'a Yükleme

1. **Archive** tamamlandıktan sonra **Organizer** açılır
2. **Distribute App** → **App Store Connect**
3. **Upload** → **Next** → **Next** → **Upload**
4. App Store Connect'te build'in işlenmesini bekleyin (5-10 dakika)
5. TestFlight'ta build görünecek

---

**Başarılar! 🎉**







