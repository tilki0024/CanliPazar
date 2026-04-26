#!/bin/bash
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo "Tüm masaüstündeki keystore dosyalarını arıyorum..."
echo ""

# Tüm keystore dosyalarını bul
KEYSTORES=$(find ~/Desktop -type f \( -name "*.jks" -o -name "*.keystore" \) 2>/dev/null)

# Genişletilmiş şifre listesi
PASSWORDS=("BlueSky2024!" "BlueSky2024" "bluesky2024!" "bluesky2024" "BlueSky" "bluesky" "upload" "android" "key" "release" "123456" "password" "keystore" "canlipazar" "canlipazar2024" "upload123" "key123" "android123" "release123" "freecycle" "uploadkey" "upload_key" "upload-key" "signing" "sign" "app" "app123" "")

for keystore in $KEYSTORES; do
    echo "Kontrol: $keystore"
    
    for pass in "${PASSWORDS[@]}"; do
        if [ -z "$pass" ]; then
            SHA1=$(keytool -list -v "$keystore" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        else
            SHA1=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
        fi
        
        if [ ! -z "$SHA1" ]; then
            if [ -z "$pass" ]; then
                echo "  Şifre: (şifresiz)"
            else
                echo "  Şifre: $pass"
            fi
            echo "  SHA-1: $SHA1"
            
            if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
                echo ""
                echo "  ✅✅✅ DOĞRU KEYSTORE BULUNDU! ✅✅✅"
                echo "  Dosya: $keystore"
                if [ -z "$pass" ]; then
                    echo "  Şifre: (şifresiz)"
                else
                    echo "  Şifre: $pass"
                fi
                if [ -z "$pass" ]; then
                    ALIAS=$(keytool -list -v "$keystore" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
                else
                    ALIAS=$(keytool -list -v -keystore "$keystore" -storepass "$pass" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
                fi
                echo "  Alias: $ALIAS"
                echo ""
                echo "Şimdi bu keystore ile AAB dosyasını imzalayacağım..."
                exit 0
            fi
            break
        fi
    done
    echo ""
done

echo "❌ Doğru keystore bulunamadı."
