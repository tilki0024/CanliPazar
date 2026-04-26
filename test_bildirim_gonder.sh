#!/bin/bash

# Test bildirimi gönderme scripti
# Kullanım: ./test_bildirim_gonder.sh

USER_ID="CtBc8p5lhaSgQDv3oI9jfUwMAmS2"
FUNCTION_URL="https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToUser"

echo "📤 Test bildirimi gönderiliyor..."
echo "👤 Kullanıcı ID: $USER_ID"
echo "🔗 URL: $FUNCTION_URL"
echo ""

# GET request ile dene (daha basit)
curl -X GET "${FUNCTION_URL}?userId=${USER_ID}&message=Test%20Bildirimi%20-%20Bildirim%20geldi%20mi" \
  -H "Content-Type: application/json" \
  -v

echo ""
echo ""
echo "✅ İstek gönderildi. Sonuç yukarıda görünecek."
echo ""
echo "📱 Eğer bildirim gelmediyse:"
echo "   1. Firestore'da fcmToken alanının dolu olduğunu kontrol et"
echo "   2. Platform alanının 'ios' veya 'android' olduğunu kontrol et"
echo "   3. Uygulamada bildirim izninin verildiğini kontrol et"
echo "   4. Cihazın internete bağlı olduğunu kontrol et"





























