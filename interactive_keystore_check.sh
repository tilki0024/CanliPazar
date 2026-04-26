#!/bin/bash
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo ""
echo "upload-keystore.jks dosyasını kontrol ediyorum..."
echo "Lütfen şifreyi manuel olarak girmeniz gerekecek."
echo ""

KEYSTORE="$HOME/Desktop/upload-keystore.jks"

# En yaygın şifreleri dene
echo "Yaygın şifreleri deniyorum..."
for pass in "upload" "android" "key" "release" "123456" "password" "keystore" "canlipazar" "freecycle" "upload123" "key123" "release123"; do
    SHA1=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$pass" 2>/dev/null | grep "SHA1:" | head -1 | awk '{print $2}')
    if [ ! -z "$SHA1" ]; then
        echo "Şifre bulundu: $pass"
        echo "SHA-1: $SHA1"
        if [ "$SHA1" == "$EXPECTED_SHA1" ]; then
            echo ""
            echo "✅✅✅ DOĞRU KEYSTORE VE ŞİFRE BULUNDU! ✅✅✅"
            echo "Dosya: $KEYSTORE"
            echo "Şifre: $pass"
            ALIAS=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$pass" 2>/dev/null | grep "Alias name:" | head -1 | awk '{print $3}')
            echo "Alias: $ALIAS"
            exit 0
        fi
    fi
done

echo ""
echo "❌ Yaygın şifrelerle eşleşme bulunamadı."
echo "Lütfen upload-keystore.jks dosyasının şifresini manuel olarak girin."
