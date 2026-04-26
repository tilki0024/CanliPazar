#!/bin/bash

# Beklenen SHA-1
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo ""
echo "Keystore dosyalarını kontrol ediyorum..."
echo ""

# Yaygın şifreleri dene
PASSWORDS=("upload" "password" "android" "keystore" "123456" "canlipazar2024" "canlipazar" "upload123" "release")

for keystore in ~/Desktop/upload-keystore.jks ~/Desktop/upload-keystore-new.jks ~/Desktop/upload-keystore-current.jks; do
    if [ -f "$keystore" ]; then
        echo "=== $keystore ==="
        for pass in "${PASSWORDS[@]}"; do
            SHA1=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "SHA1:" | awk '{print $2}')
            if [ ! -z "$SHA1" ]; then
                echo "  Şifre: $pass"
                echo "  SHA-1: $SHA1"
                if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
                    echo "  ✅ BU DOĞRU KEYSTORE!"
                    echo "  Alias: $(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')"
                    exit 0
                fi
                echo ""
                break
            fi
        done
    fi
done

echo "Doğru keystore bulunamadı. Lütfen manuel olarak kontrol edin."

















