#!/bin/bash
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"
KEYSTORE="$HOME/Desktop/upload-keystore.jks"

echo "Keystore dosyasını kontrol ediyorum..."
echo "Eğer şifre istenirse, şifreyi girin."
echo ""

SHA1=$(keytool -list -v -keystore "$KEYSTORE" 2>&1 | grep "SHA1:" | awk '{print $2}' | tr -d ':')

if [ ! -z "$SHA1" ]; then
    FORMATTED_SHA1=$(echo "$SHA1" | sed 's/\(..\)/\1:/g; s/:$//')
    echo "Bulunan SHA-1: $FORMATTED_SHA1"
    echo "Beklenen SHA-1: $EXPECTED_SHA1"
    if [ "$FORMATTED_SHA1" == "$EXPECTED_SHA1" ]; then
        echo "✅ DOĞRU KEYSTORE BULUNDU!"
        echo ""
        echo "Keystore bilgileri:"
        keytool -list -v -keystore "$KEYSTORE" 2>&1 | grep -E "(Alias name|Valid from|Certificate fingerprints)"
    else
        echo "❌ Bu keystore beklenen SHA-1 ile eşleşmiyor."
    fi
else
    echo "❌ Keystore okunamadı veya şifre gerekiyor."
fi
