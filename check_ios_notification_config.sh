#!/bin/bash

# iOS Bildirim Yapılandırması Kontrol Script'i
# Bu script iOS bildirim yapılandırmasını kontrol eder

echo "🔍 iOS Bildirim Yapılandırması Kontrol Ediliyor..."
echo "=================================================="
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hata sayacı
ERRORS=0
WARNINGS=0

# 1. GoogleService-Info.plist kontrolü
echo "1️⃣  GoogleService-Info.plist Kontrolü"
echo "-----------------------------------"
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist bulundu${NC}"
    
    # Bundle ID kontrolü
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ "$BUNDLE_ID" == "com.canlipazar.app" ]; then
        echo -e "${GREEN}✅ Bundle ID doğru: $BUNDLE_ID${NC}"
    else
        echo -e "${RED}❌ Bundle ID yanlış: $BUNDLE_ID (Beklenen: com.canlipazar.app)${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ GoogleService-Info.plist bulunamadı!${NC}"
    echo -e "${YELLOW}   Firebase Console'dan indirip ios/Runner/ klasörüne koyun${NC}"
    ((ERRORS++))
fi
echo ""

# 2. Info.plist kontrolü
echo "2️⃣  Info.plist Kontrolü"
echo "--------------------"
if [ -f "ios/Runner/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist bulundu${NC}"
    
    # FirebaseAppDelegateProxyEnabled kontrolü
    if grep -q "FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist; then
        echo -e "${GREEN}✅ FirebaseAppDelegateProxyEnabled ayarı var${NC}"
    else
        echo -e "${YELLOW}⚠️  FirebaseAppDelegateProxyEnabled ayarı yok (opsiyonel)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ Info.plist bulunamadı!${NC}"
    ((ERRORS++))
fi
echo ""

# 3. AppDelegate.swift kontrolü
echo "3️⃣  AppDelegate.swift Kontrolü"
echo "----------------------------"
if [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo -e "${GREEN}✅ AppDelegate.swift bulundu${NC}"
    
    # Firebase import kontrolü
    if grep -q "import Firebase" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ Firebase import edilmiş${NC}"
    else
        echo -e "${RED}❌ Firebase import edilmemiş!${NC}"
        ((ERRORS++))
    fi
    
    # FirebaseMessaging import kontrolü
    if grep -q "import FirebaseMessaging" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ FirebaseMessaging import edilmiş${NC}"
    else
        echo -e "${RED}❌ FirebaseMessaging import edilmemiş!${NC}"
        ((ERRORS++))
    fi
    
    # FirebaseApp.configure kontrolü
    if grep -q "FirebaseApp.configure()" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ FirebaseApp.configure() çağrılıyor${NC}"
    else
        echo -e "${RED}❌ FirebaseApp.configure() çağrılmıyor!${NC}"
        ((ERRORS++))
    fi
    
    # Messaging.messaging().delegate kontrolü
    if grep -q "Messaging.messaging().delegate" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ Messaging delegate ayarlanıyor${NC}"
    else
        echo -e "${RED}❌ Messaging delegate ayarlanmıyor!${NC}"
        ((ERRORS++))
    fi
    
    # UNUserNotificationCenter.current().delegate kontrolü
    if grep -q "UNUserNotificationCenter.current().delegate" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ UNUserNotificationCenter delegate ayarlanıyor${NC}"
    else
        echo -e "${RED}❌ UNUserNotificationCenter delegate ayarlanmıyor!${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ AppDelegate.swift bulunamadı!${NC}"
    ((ERRORS++))
fi
echo ""

# 4. Podfile kontrolü
echo "4️⃣  Podfile Kontrolü"
echo "-----------------"
if [ -f "ios/Podfile" ]; then
    echo -e "${GREEN}✅ Podfile bulundu${NC}"
    
    # Firebase/Messaging kontrolü
    if grep -q "Firebase/Messaging" ios/Podfile; then
        echo -e "${GREEN}✅ Firebase/Messaging pod'u var${NC}"
    else
        echo -e "${YELLOW}⚠️  Firebase/Messaging pod'u yok (flutter_local_notifications kullanılıyor olabilir)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ Podfile bulunamadı!${NC}"
    ((ERRORS++))
fi
echo ""

# 5. Xcode project kontrolü
echo "5️⃣  Xcode Project Kontrolü"
echo "------------------------"
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✅ Xcode project bulundu${NC}"
    
    # Bundle ID kontrolü
    XCODE_BUNDLE_ID=$(grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
    if [ "$XCODE_BUNDLE_ID" == "com.canlipazar.app" ]; then
        echo -e "${GREEN}✅ Xcode Bundle ID doğru: $XCODE_BUNDLE_ID${NC}"
    else
        echo -e "${YELLOW}⚠️  Xcode Bundle ID: $XCODE_BUNDLE_ID (Beklenen: com.canlipazar.app)${NC}"
        echo -e "${YELLOW}   Manuel olarak Xcode'da kontrol edin${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ Xcode project bulunamadı!${NC}"
    ((ERRORS++))
fi
echo ""

# 6. Flutter dependencies kontrolü
echo "6️⃣  Flutter Dependencies Kontrolü"
echo "-------------------------------"
if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✅ pubspec.yaml bulundu${NC}"
    
    # firebase_messaging kontrolü
    if grep -q "firebase_messaging:" pubspec.yaml; then
        echo -e "${GREEN}✅ firebase_messaging dependency var${NC}"
    else
        echo -e "${RED}❌ firebase_messaging dependency yok!${NC}"
        ((ERRORS++))
    fi
    
    # flutter_local_notifications kontrolü
    if grep -q "flutter_local_notifications:" pubspec.yaml; then
        echo -e "${GREEN}✅ flutter_local_notifications dependency var${NC}"
    else
        echo -e "${YELLOW}⚠️  flutter_local_notifications dependency yok${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ pubspec.yaml bulunamadı!${NC}"
    ((ERRORS++))
fi
echo ""

# 7. Özet
echo "=================================================="
echo "📊 ÖZET"
echo "=================================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Tüm kontroller başarılı!${NC}"
    echo ""
    echo "Sonraki Adımlar:"
    echo "1. Firebase Console'da APNs Key/Certificate kontrolü yapın"
    echo "2. Xcode'da Push Notifications capability kontrolü yapın"
    echo "3. Gerçek iOS cihazda test edin (Simulator değil!)"
    echo ""
    echo "Detaylı rehber: IOS_BILDIRIM_KONTROL_REHBERI.md"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS uyarı bulundu${NC}"
    echo ""
    echo "Uyarılar kritik olmayabilir, ama kontrol etmeniz önerilir."
    echo ""
    echo "Sonraki Adımlar:"
    echo "1. Firebase Console'da APNs Key/Certificate kontrolü yapın"
    echo "2. Xcode'da Push Notifications capability kontrolü yapın"
    echo "3. Gerçek iOS cihazda test edin (Simulator değil!)"
    echo ""
    echo "Detaylı rehber: IOS_BILDIRIM_KONTROL_REHBERI.md"
else
    echo -e "${RED}❌ $ERRORS hata bulundu!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS uyarı bulundu${NC}"
    fi
    echo ""
    echo "Lütfen yukarıdaki hataları düzeltin."
    echo ""
    echo "Detaylı rehber: IOS_BILDIRIM_KONTROL_REHBERI.md"
fi
echo "=================================================="
