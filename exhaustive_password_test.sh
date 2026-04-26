#!/bin/bash
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"
KEYSTORE="$HOME/Desktop/upload-keystore.jks"

# Çok genişletilmiş şifre listesi
PASSWORDS=(
    "BlueSky2024!" "BlueSky2024" "bluesky2024!" "bluesky2024" "BLUESKY2024!" "BLUESKY2024"
    "BlueSky" "bluesky" "BLUESKY" "BlueSky!" "bluesky!"
    "upload" "Upload" "UPLOAD" "upload123" "Upload123" "UPLOAD123"
    "android" "Android" "ANDROID" "android123" "Android123"
    "key" "Key" "KEY" "key123" "Key123"
    "release" "Release" "RELEASE" "release123" "Release123"
    "123456" "12345678" "87654321" "password" "Password" "PASSWORD"
    "keystore" "Keystore" "KEYSTORE" "keystore123"
    "canlipazar" "CanliPazar" "CANLIPAZAR" "canlipazar2024" "CanliPazar2024"
    "freecycle" "Freecycle" "FREECYCLE"
    "uploadkey" "UploadKey" "upload_key" "upload-key"
    "signing" "Signing" "SIGNING" "sign" "Sign"
    "app" "App" "APP" "app123"
    "prod" "Prod" "PROD" "production" "Production"
    "storepass" "keypass" "storepass123" "keypass123"
    "" # şifresiz
)

echo "upload-keystore.jks için şifre aranıyor..."
echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo ""

for pass in "${PASSWORDS[@]}"; do
    if [ -z "$pass" ]; then
        SHA1=$(keytool -list -v "$KEYSTORE" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        PASS_DISPLAY="(şifresiz)"
    else
        SHA1=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$pass" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        PASS_DISPLAY="$pass"
    fi
    
    if [ ! -z "$SHA1" ]; then
        echo "✅ Şifre bulundu: $PASS_DISPLAY"
        echo "   SHA-1: $SHA1"
        if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
            echo ""
            echo "🎉🎉🎉 DOĞRU KEYSTORE VE ŞİFRE BULUNDU! 🎉🎉🎉"
            echo "Dosya: $KEYSTORE"
            echo "Şifre: $PASS_DISPLAY"
            ALIAS=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$pass" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
            if [ -z "$ALIAS" ] && [ -z "$pass" ]; then
                ALIAS=$(keytool -list -v "$KEYSTORE" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
            fi
            echo "Alias: $ALIAS"
            exit 0
        fi
        break
    fi
done

echo "❌ Doğru şifre bulunamadı."
exit 1
