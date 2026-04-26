#!/bin/bash

# Cloud Functions Deploy Script
# Bu script tüm Cloud Functions'ları deploy eder

echo "🚀 Cloud Functions deploy başlatılıyor..."
echo ""

# Functions klasörüne git
cd functions

# Firebase login kontrolü
echo "📋 Firebase login kontrolü..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Firebase'e giriş yapılmamış!"
    echo "   Lütfen önce 'firebase login' komutunu çalıştırın"
    exit 1
fi

echo "✅ Firebase'e giriş yapılmış"
echo ""

# NPM dependencies kontrolü
echo "📦 NPM dependencies kontrolü..."
if [ ! -d "node_modules" ]; then
    echo "⚠️ node_modules bulunamadı, npm install çalıştırılıyor..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ npm install başarısız!"
        exit 1
    fi
    echo "✅ npm install tamamlandı"
else
    echo "✅ node_modules mevcut"
fi
echo ""

# TypeScript build
echo "🔨 TypeScript build başlatılıyor..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ TypeScript build başarısız!"
    exit 1
fi
echo "✅ TypeScript build tamamlandı"
echo ""

# Cloud Functions deploy
echo "📤 Cloud Functions deploy başlatılıyor..."
echo "   Bu işlem birkaç dakika sürebilir..."
echo ""

firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Cloud Functions başarıyla deploy edildi!"
    echo ""
    echo "📋 Deploy edilen fonksiyonlar:"
    echo "   - onConversationMessageCreated (mesaj bildirimleri)"
    echo "   - onNewAnimalPostCreated (yeni ilan bildirimleri)"
    echo "   - sendMessageNotificationCallable (callable mesaj bildirimi)"
    echo ""
    echo "🧪 Test için:"
    echo "   1. Bir mesaj gönderin"
    echo "   2. Yeni bir ilan ekleyin"
    echo "   3. Firebase Console → Functions → Logs'dan logları kontrol edin"
    echo ""
else
    echo ""
    echo "❌ Cloud Functions deploy başarısız!"
    echo "   Lütfen hata mesajlarını kontrol edin"
    exit 1
fi









