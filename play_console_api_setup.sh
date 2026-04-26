#!/bin/bash

# Google Play Console API ile Certificate Yükleme Script'i
# Bu script, Google Play Console API'sini kullanarak certificate yükler

echo "🔐 Google Play Console API Setup"
echo "================================"
echo ""

# 1. Google Cloud Console'da Service Account oluştur
echo "1️⃣ Google Cloud Console'da Service Account oluşturun:"
echo "   - https://console.cloud.google.com/ adresine gidin"
echo "   - Projenizi seçin veya yeni proje oluşturun"
echo "   - APIs & Services → Credentials → Create Credentials → Service Account"
echo "   - Service account oluşturun ve JSON key'i indirin"
echo ""

# 2. Play Console'da API erişimi ver
echo "2️⃣ Play Console'da API erişimi verin:"
echo "   - https://play.google.com/console → Settings → API access"
echo "   - Service account'u ekleyin"
echo "   - 'Manage production releases' yetkisi verin"
echo ""

# 3. Gerekli paketleri yükle
echo "3️⃣ Gerekli paketleri yükleyin:"
echo "   pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib"
echo ""

# 4. Script'i çalıştır
echo "4️⃣ Script'i çalıştırın:"
echo "   python upload_certificate.py"
echo ""

echo "⚠️  Not: Bu işlem için Google Cloud Console ve Play Console erişiminiz gerekir."
echo ""
















