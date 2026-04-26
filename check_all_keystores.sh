#!/bin/bash

# Beklenen SHA-1
EXPECTED_SHA1="46:ED:FA:0E:75:41:9E:43:B9:24:9F:E9:02:B7:C6:D0:E2:B0:B4:8A"

echo "Beklenen SHA-1: $EXPECTED_SHA1"
echo ""
echo "Tüm keystore dosyalarını kontrol ediyorum..."
echo ""

# Tüm keystore dosyalarını bul
find ~/Desktop -name "*.jks" -o -name "*.keystore" 2>/dev/null | while read keystore; do
    if [ -f "$keystore" ]; then
        echo "=== $keystore ==="
        # Şifre olmadan info al
        keytool -list "$keystore" 2>&1 | head -5
        echo ""
    fi
done

echo ""
echo "Lütfen upload-keystore.jks dosyasının şifresini girin:"
echo "Şifre: (gizli olarak gireceksiniz)"

















