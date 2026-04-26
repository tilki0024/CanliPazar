#!/bin/bash
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

# Genişletilmiş şifre listesi
PASSWORDS=("upload" "android" "key" "release" "prod" "production" "storepass" "keypass" "123456" "12345678" "87654321" "qwerty" "asdfgh" "password" "keystore" "canlipazar" "canlipazar2024" "upload123" "key123" "android123" "release123" "prod123" "freecycle" "uploadkey" "upload_key" "upload-key" "signing" "sign" "app" "app123")

KEYSTORES=(
    "$HOME/Desktop/upload-keystore.jks"
    "$HOME/Desktop/upload-keystore-new.jks"
    "$HOME/Desktop/upload-keystore-current.jks"
    "$HOME/Desktop/upload-keystore-for-reset.jks"
    "$HOME/Desktop/frees_ios_copy copy/android/app/upload-keystore.jks"
)

for keystore in "${KEYSTORES[@]}"; do
    if [ ! -f "$keystore" ]; then
        continue
    fi
    
    echo "=========================================="
    echo "Kontrol: $keystore"
    echo "=========================================="
    
    # Şifresiz dene
    SHA1=$(keytool -list -v "$keystore" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
    if [ ! -z "$SHA1" ]; then
        echo "  Şifre: (şifresiz)"
        echo "  SHA-1: $SHA1"
        if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
            echo ""
            echo "  ✅✅✅ DOĞRU KEYSTORE BULUNDU! ✅✅✅"
            echo "  Dosya: $keystore"
            echo "  Şifre: (şifresiz)"
            ALIAS=$(keytool -list -v "$keystore" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
            echo "  Alias: $ALIAS"
            exit 0
        fi
        echo ""
        continue
    fi
    
    # Şifreli deneme
    for pass in "${PASSWORDS[@]}"; do
        SHA1=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        if [ ! -z "$SHA1" ]; then
            echo "  Şifre: $pass"
            echo "  SHA-1: $SHA1"
            if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
                echo ""
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
done

echo ""
echo "❌ Doğru keystore bulunamadı."
