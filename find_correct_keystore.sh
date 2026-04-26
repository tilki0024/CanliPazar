#!/bin/bash

EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo "=========================================="
echo ""

# Tüm keystore dosyalarını bul
KEYSTORES=$(find ~/Desktop -type f \( -name "*.jks" -o -name "*.keystore" \) 2>/dev/null)

if [ -z "$KEYSTORES" ]; then
    echo "Keystore dosyası bulunamadı!"
    exit 1
fi

# Yaygın şifreler
PASSWORDS=("upload" "password" "android" "keystore" "123456" "canlipazar2024" "canlipazar" "upload123" "release" "key" "key123" "android123" "")

for keystore in $KEYSTORES; do
    echo "Kontrol ediliyor: $keystore"
    
    # Önce şifresiz dene
    SHA1=$(keytool -list -v "$keystore" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
    
    if [ ! -z "$SHA1" ]; then
        echo "  Şifre: (şifresiz)"
        echo "  SHA-1: $SHA1"
        if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
            echo "  ✅✅✅ DOĞRU KEYSTORE BULUNDU! ✅✅✅"
            echo "  Dosya: $keystore"
            ALIAS=$(keytool -list -v "$keystore" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
            echo "  Alias: $ALIAS"
            exit 0
        fi
        echo ""
        continue
    fi
    
    # Şifreli deneme
    for pass in "${PASSWORDS[@]}"; do
        if [ -z "$pass" ]; then
            continue
        fi
        
        SHA1=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        
        if [ ! -z "$SHA1" ]; then
            echo "  Şifre: $pass"
            echo "  SHA-1: $SHA1"
            if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
                echo "  ✅✅✅ DOĞRU KEYSTORE BULUNDU! ✅✅✅"
                echo "  Dosya: $keystore"
                echo "  Şifre: $pass"
                ALIAS=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
                echo "  Alias: $ALIAS"
                exit 0
            fi
            echo ""
            break
        fi
    done
    echo ""
done

echo "❌ Doğru keystore bulunamadı."
echo "Lütfen keystore şifresini manuel olarak girin veya dosyayı kontrol edin."

















