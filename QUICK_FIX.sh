#!/bin/bash

echo "🚀 Flutter Kurulum ve Düzeltme Script'i"
echo "========================================"
echo ""

# Homebrew kontrolü
if command -v brew &> /dev/null; then
    echo "✅ Homebrew kurulu"
    
    # Flutter kurulu mu kontrol et
    if brew list --cask flutter &> /dev/null; then
        echo "✅ Flutter Homebrew ile kurulu"
        FLUTTER_PATH=$(brew --prefix)/bin/flutter
    else
        echo "📦 Flutter kuruluyor (Homebrew ile)..."
        brew install --cask flutter
        FLUTTER_PATH=$(brew --prefix)/bin/flutter
    fi
else
    echo "❌ Homebrew bulunamadı"
    echo ""
    echo "Homebrew kurulumu için:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "Veya Flutter'ı manuel kurun:"
    echo "  cd ~/Desktop"
    echo "  git clone https://github.com/flutter/flutter.git -b stable"
    exit 1
fi

# PATH kontrolü
if [ -f "$FLUTTER_PATH" ]; then
    echo "✅ Flutter bulundu: $FLUTTER_PATH"
    
    # .zshrc'yi güncelle
    if ! grep -q "flutter/bin" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# Flutter PATH (Homebrew)" >> ~/.zshrc
        echo "export PATH=\"\$PATH:$(dirname $FLUTTER_PATH)\"" >> ~/.zshrc
        echo "✅ .zshrc güncellendi"
    fi
    
    # Şu anki session için PATH'i güncelle
    export PATH="$PATH:$(dirname $FLUTTER_PATH)"
    
    echo ""
    echo "✅ Kurulum tamamlandı!"
    echo ""
    echo "Test için:"
    echo "  source ~/.zshrc"
    echo "  flutter --version"
    echo "  flutter doctor"
else
    echo "❌ Flutter bulunamadı"
    exit 1
fi





