#!/bin/bash

EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"
KEYSTORE="$HOME/Desktop/upload-keystore.jks"
AAB_FILE="build/app/outputs/bundle/release/app-release.aab"

echo "AAB Dosyasını Doğru Keystore ile İmzalama"
echo "=========================================="
echo ""

if [ ! -f "$KEYSTORE" ]; then
    echo "❌ Keystore dosyası bulunamadı: $KEYSTORE"
    exit 1
fi

if [ ! -f "$AAB_FILE" ]; then
    echo "❌ AAB dosyası bulunamadı: $AAB_FILE"
    exit 1
fi

echo "Keystore: $KEYSTORE"
echo "AAB: $AAB_FILE"
echo ""
echo "Lütfen keystore şifresini girin:"
read -s PASSWORD

echo ""
echo "Keystore kontrol ediliyor..."

SHA1=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$PASSWORD" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')

if [ -z "$SHA1" ]; then
    echo "❌ Keystore açılamadı veya şifre yanlış."
    exit 1
fi

echo "Keystore SHA-1: $SHA1"
echo "Beklenen SHA-1: $EXPECTED_SHA1"

if [ "$SHA1" != "$EXPECTED_SHA1" ]; then
    echo "❌ Bu keystore beklenen SHA-1 ile eşleşmiyor!"
    exit 1
fi

echo "✅ Doğru keystore bulundu!"
ALIAS=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$PASSWORD" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
echo "Alias: $ALIAS"
echo ""

# Key.properties dosyasını güncelle
echo "key.properties dosyası güncelleniyor..."
cat > android/key.properties << EOF
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

# Keystore'u android klasörüne kopyala
cp "$KEYSTORE" android/upload-keystore.jks
echo "Keystore kopyalandı."

# Build.gradle'ı güncelle
echo "Build.gradle güncelleniyor..."
sed -i '' 's|storeFile=.*|storeFile=upload-keystore.jks|' android/app/build.gradle 2>/dev/null || \
sed -i 's|storeFile=.*|storeFile=upload-keystore.jks|' android/app/build.gradle

# AAB'yi yeniden imzala
echo ""
echo "AAB dosyası imzalanıyor..."
flutter clean
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ AAB dosyası başarıyla imzalandı!"
    echo "Dosya: $AAB_FILE"
    echo ""
    echo "İmza kontrolü:"
    keytool -printcert -jarfile "$AAB_FILE" 2>/dev/null | grep -A 3 "Certificate fingerprints"
else
    echo "❌ Build hatası!"
    exit 1
fi

















