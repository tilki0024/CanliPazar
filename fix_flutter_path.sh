#!/bin/bash

# Flutter PATH Düzeltme Script'i

echo "🔍 Flutter kurulumunu arıyorum..."

# Flutter'ı bul
FLUTTER_PATH=$(find ~ -name "flutter" -type f -executable 2>/dev/null | grep "bin/flutter" | head -1)

if [ -z "$FLUTTER_PATH" ]; then
    echo "❌ Flutter bulunamadı!"
    echo ""
    echo "Flutter'ı kurmak için:"
    echo "  cd ~/Desktop"
    echo "  git clone https://github.com/flutter/flutter.git -b stable"
    echo ""
    echo "Veya Homebrew ile:"
    echo "  brew install --cask flutter"
    exit 1
fi

# Flutter dizinini bul
FLUTTER_DIR=$(dirname "$FLUTTER_PATH")
FLUTTER_BIN_DIR=$(dirname "$FLUTTER_DIR")

echo "✅ Flutter bulundu: $FLUTTER_BIN_DIR"

# .zshrc'yi kontrol et
if grep -q "export PATH.*flutter/bin" ~/.zshrc; then
    echo "✅ .zshrc'de Flutter PATH'i var"
    
    # Mevcut PATH'i güncelle
    sed -i '' "s|export PATH=\"\$PATH:\$HOME/Desktop/flutter/bin\"|export PATH=\"\$PATH:$FLUTTER_BIN_DIR\"|g" ~/.zshrc
    echo "✅ .zshrc güncellendi"
else
    # PATH ekle
    echo "" >> ~/.zshrc
    echo "# Flutter PATH" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$FLUTTER_BIN_DIR\"" >> ~/.zshrc
    echo "✅ .zshrc'ye Flutter PATH'i eklendi"
fi

# PATH'i şu anki session için güncelle
export PATH="$PATH:$FLUTTER_BIN_DIR"

echo ""
echo "✅ Flutter PATH düzeltildi!"
echo ""
echo "Test için:"
echo "  source ~/.zshrc"
echo "  flutter --version"
echo "  flutter doctor"





