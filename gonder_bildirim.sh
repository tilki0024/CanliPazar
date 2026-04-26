#!/bin/bash

# CanlıPazar Toplu Bildirim Gönderme Scripti
# Bu script tüm kullanıcılara bildirim gönderir

echo "📢 CanlıPazar Toplu Bildirim Gönderiliyor..."
echo ""

# Firebase Cloud Function URL
FUNCTION_URL="https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms"

# Bildirim içeriği
TITLE="CanlıPazar'da ilan verin"
BODY="Binlerce müşteriye ulaşın"

echo "📋 Başlık: $TITLE"
echo "📋 Mesaj: $BODY"
echo ""
echo "⏳ Gönderiliyor..."

# cURL ile POST request gönder
RESPONSE=$(curl -s -X POST \
  "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"$TITLE\",
    \"body\": \"$BODY\",
    \"data\": {
      \"type\": \"promotion\"
    }
  }")

# Sonucu göster
echo ""
echo "📊 Sonuç:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

echo ""
echo "✅ İşlem tamamlandı!"





























