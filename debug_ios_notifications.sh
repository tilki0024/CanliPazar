#!/bin/bash

# iOS Bildirim Debug Script
# APNs key var ama bildirim gelmiyor durumu için detaylı debug

echo "🔍 iOS Bildirim Detaylı Debug Başlatılıyor..."
echo "=================================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Entitlements dosyası kontrolü
echo "1️⃣  Entitlements Dosyası Kontrolü"
echo "--------------------------------"

ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo -e "${GREEN}✅ Runner.entitlements bulundu${NC}"
    
    # APS Environment kontrolü
    if grep -q "aps-environment" "$ENTITLEMENTS_FILE"; then
        APS_ENV=$(grep -A 1 "aps-environment" "$ENTITLEMENTS_FILE" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo -e "${BLUE}📱 APS Environment: $APS_ENV${NC}"
        
        if [ "$APS_ENV" == "development" ]; then
            echo -e "${YELLOW}⚠️  Development mode tespit edildi${NC}"
            echo -e "${YELLOW}   Firebase Console'da Development APNs key kullanılmalı${NC}"
        elif [ "$APS_ENV" == "production" ]; then
            echo -e "${GREEN}✅ Production mode${NC}"
            echo -e "${GREEN}   Firebase Console'da Production APNs key kullanılmalı${NC}"
        else
            echo -e "${RED}❌ Bilinmeyen APS Environment: $APS_ENV${NC}"
        fi
    else
        echo -e "${RED}❌ aps-environment ayarı yok!${NC}"
        echo -e "${YELLOW}   Push Notifications capability Xcode'da eklenmemiş olabilir${NC}"
    fi
    
    # Push Notifications capability kontrolü
    if grep -q "com.apple.developer.aps-environment" "$ENTITLEMENTS_FILE"; then
        echo -e "${GREEN}✅ Push Notifications capability aktif${NC}"
    else
        echo -e "${RED}❌ Push Notifications capability eksik!${NC}"
    fi
else
    echo -e "${RED}❌ Runner.entitlements bulunamadı!${NC}"
    echo -e "${YELLOW}   Xcode'da Push Notifications capability eklenmemiş olabilir${NC}"
fi
echo ""

# 2. Xcode project build settings kontrolü
echo "2️⃣  Xcode Build Settings Kontrolü"
echo "-------------------------------"

if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    # Code Signing Identity kontrolü
    if grep -q "CODE_SIGN_IDENTITY" ios/Runner.xcodeproj/project.pbxproj; then
        echo -e "${GREEN}✅ Code signing yapılandırılmış${NC}"
    else
        echo -e "${YELLOW}⚠️  Code signing yapılandırması bulunamadı${NC}"
    fi
    
    # Development Team kontrolü
    if grep -q "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj; then
        TEAM_ID=$(grep -m 1 "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' "')
        if [ ! -z "$TEAM_ID" ]; then
            echo -e "${GREEN}✅ Development Team ID: $TEAM_ID${NC}"
            echo -e "${BLUE}   Bu Team ID Firebase Console'daki Team ID ile eşleşmeli${NC}"
        else
            echo -e "${YELLOW}⚠️  Development Team ID boş${NC}"
        fi
    else
        echo -e "${RED}❌ Development Team ayarlanmamış!${NC}"
    fi
fi
echo ""

# 3. Provisioning Profile kontrolü
echo "3️⃣  Provisioning Profile Kontrolü"
echo "-------------------------------"

PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILES_DIR" ]; then
    PROFILE_COUNT=$(ls -1 "$PROFILES_DIR"/*.mobileprovision 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ $PROFILE_COUNT provisioning profile bulundu${NC}"
    
    # En son profili kontrol et
    LATEST_PROFILE=$(ls -t "$PROFILES_DIR"/*.mobileprovision 2>/dev/null | head -1)
    if [ ! -z "$LATEST_PROFILE" ]; then
        echo -e "${BLUE}📱 En son profil: $(basename "$LATEST_PROFILE")${NC}"
        
        # Profile'ın push notification içerip içermediğini kontrol et
        if security cms -D -i "$LATEST_PROFILE" 2>/dev/null | grep -q "aps-environment"; then
            echo -e "${GREEN}✅ Profile push notification içeriyor${NC}"
            
            # Environment'ı kontrol et
            PROFILE_ENV=$(security cms -D -i "$LATEST_PROFILE" 2>/dev/null | grep -A 1 "aps-environment" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
            if [ ! -z "$PROFILE_ENV" ]; then
                echo -e "${BLUE}📱 Profile APS Environment: $PROFILE_ENV${NC}"
            fi
        else
            echo -e "${RED}❌ Profile push notification içermiyor!${NC}"
            echo -e "${YELLOW}   Apple Developer Portal'da yeni profile oluşturun${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Provisioning profiles klasörü bulunamadı${NC}"
fi
echo ""

# 4. Firebase yapılandırması detaylı kontrol
echo "4️⃣  Firebase Yapılandırması Detaylı Kontrol"
echo "----------------------------------------"

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    # Bundle ID
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo -e "${BLUE}📱 Firebase Bundle ID: $BUNDLE_ID${NC}"
    
    # GCM Sender ID
    GCM_SENDER_ID=$(grep -A 1 "GCM_SENDER_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ ! -z "$GCM_SENDER_ID" ]; then
        echo -e "${GREEN}✅ GCM Sender ID: $GCM_SENDER_ID${NC}"
    fi
    
    # Project ID
    PROJECT_ID=$(grep -A 1 "PROJECT_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ ! -z "$PROJECT_ID" ]; then
        echo -e "${GREEN}✅ Firebase Project ID: $PROJECT_ID${NC}"
    fi
fi
echo ""

# 5. AppDelegate.swift detaylı kontrol
echo "5️⃣  AppDelegate.swift Detaylı Kontrol"
echo "-----------------------------------"

if [ -f "ios/Runner/AppDelegate.swift" ]; then
    # APNs token handling
    if grep -q "didRegisterForRemoteNotificationsWithDeviceToken" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ APNs token handler var${NC}"
    else
        echo -e "${RED}❌ APNs token handler yok!${NC}"
    fi
    
    # Messaging.messaging().apnsToken kontrolü
    if grep -q "Messaging.messaging().apnsToken" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ APNs token Firebase'e veriliyor${NC}"
    else
        echo -e "${RED}❌ APNs token Firebase'e verilmiyor!${NC}"
        echo -e "${YELLOW}   Bu KRİTİK bir eksiklik!${NC}"
    fi
    
    # didReceiveRegistrationToken kontrolü
    if grep -q "didReceiveRegistrationToken" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}✅ FCM token handler var${NC}"
    else
        echo -e "${YELLOW}⚠️  FCM token handler yok${NC}"
    fi
fi
echo ""

# 6. Podfile.lock kontrolü
echo "6️⃣  Firebase SDK Versiyonları"
echo "---------------------------"

if [ -f "ios/Podfile.lock" ]; then
    # Firebase/Core version
    FIREBASE_CORE=$(grep "Firebase/Core" ios/Podfile.lock | head -1 | sed 's/.*(\(.*\))/\1/')
    if [ ! -z "$FIREBASE_CORE" ]; then
        echo -e "${BLUE}📦 Firebase/Core: $FIREBASE_CORE${NC}"
    fi
    
    # Firebase/Messaging version
    FIREBASE_MESSAGING=$(grep "Firebase/Messaging" ios/Podfile.lock | head -1 | sed 's/.*(\(.*\))/\1/')
    if [ ! -z "$FIREBASE_MESSAGING" ]; then
        echo -e "${BLUE}📦 Firebase/Messaging: $FIREBASE_MESSAGING${NC}"
    fi
    
    # FirebaseMessaging pod version
    FIREBASE_MESSAGING_POD=$(grep "^  - FirebaseMessaging" ios/Podfile.lock | sed 's/.*(\(.*\))/\1/')
    if [ ! -z "$FIREBASE_MESSAGING_POD" ]; then
        echo -e "${BLUE}📦 FirebaseMessaging Pod: $FIREBASE_MESSAGING_POD${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Podfile.lock bulunamadı${NC}"
fi
echo ""

# 7. Öneriler
echo "=================================================="
echo "📋 KRİTİK KONTROL LİSTESİ"
echo "=================================================="
echo ""
echo "Firebase Console'da kontrol edilmesi gerekenler:"
echo ""
echo "1. APNs Key Environment Kontrolü:"
echo "   https://console.firebase.google.com/project/canlipazar-b3697/settings/cloudmessaging"
echo ""
echo "   ✓ APNs Authentication Key yüklü mü?"
echo "   ✓ Key ID doğru mu?"
echo "   ✓ Team ID yukarıdaki Team ID ile eşleşiyor mu?"
echo "   ✓ Key'in environment'ı (dev/prod) entitlements ile uyumlu mu?"
echo ""
echo "2. iOS App Kaydı:"
echo "   ✓ Bundle ID: com.canlipazar.app olarak kayıtlı mı?"
echo "   ✓ GoogleService-Info.plist güncel mi?"
echo ""
echo "3. Xcode'da kontrol edilmesi gerekenler:"
echo "   ✓ Push Notifications capability eklendi mi?"
echo "   ✓ Background Modes → Remote notifications aktif mi?"
echo "   ✓ Signing & Capabilities → Team seçili mi?"
echo "   ✓ Provisioning profile push notification içeriyor mu?"
echo ""
echo "4. Test ortamı:"
echo "   ✓ GERÇEK iOS cihazda test ediliyor mu? (Simulator ÇALIŞMAZ!)"
echo "   ✓ Bildirim izni verildi mi?"
echo "   ✓ Uygulama background'da mı yoksa kapalı mı?"
echo ""
echo "=================================================="
echo ""
echo "🔧 SONRAKİ ADIMLAR:"
echo ""
echo "1. Xcode'u açın ve kontrol edin:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Gerçek iOS cihazda test edin ve Xcode Console'da şu logları arayın:"
echo "   - '✅ [AppDelegate] APNs device token:'"
echo "   - '✅ [AppDelegate] Firebase registration token alındı:'"
echo ""
echo "3. Firebase Console → Functions → Logs bölümünde şu logları kontrol edin:"
echo "   - '[sendMessageNotification] Platform: ios'"
echo "   - '[sendMessageNotification] Bildirim başarıyla gönderildi'"
echo ""
echo "=================================================="
