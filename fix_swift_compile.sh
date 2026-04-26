#!/bin/bash

# Swift Compile Hatası Çözüm Script'i

echo "🧹 Temizlik başlatılıyor..."

# Derived Data'yı temizle
echo "📦 Derived Data temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# iOS build klasörünü temizle
echo "📦 iOS build klasörü temizleniyor..."
cd /Users/mustafatilki/Desktop/CanliPazar-main
rm -rf build/ios

# Pod'ları temizle
echo "📦 Pod'lar temizleniyor..."
cd ios
rm -rf Pods Podfile.lock .symlinks

# Pod install
echo "📦 Pod'lar yükleniyor..."
pod install --repo-update

echo "✅ Temizlik tamamlandı!"
echo "🚀 Şimdi Xcode'u aç ve Product > Clean Build Folder yap"



































