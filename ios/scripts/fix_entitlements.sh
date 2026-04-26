#!/bin/bash

# iOS FCM Entitlements Fix Script
# Debug build'lerde sandbox, Release build'lerde production kullanır

CONFIGURATION="${CONFIGURATION}"
ENTITLEMENTS_FILE="${SRCROOT}/Runner/Runner.entitlements"
DEBUG_ENTITLEMENTS_FILE="${SRCROOT}/Runner/Runner-Debug.entitlements"

echo "🔧 iOS Entitlements Fix Script çalışıyor..."
echo "📱 Build Configuration: ${CONFIGURATION}"

if [ "${CONFIGURATION}" == "Debug" ]; then
    echo "✅ Debug build - Sandbox (development) APNs ortamı kullanılıyor"
    if [ -f "${DEBUG_ENTITLEMENTS_FILE}" ]; then
        cp "${DEBUG_ENTITLEMENTS_FILE}" "${ENTITLEMENTS_FILE}"
        echo "✅ Debug entitlements dosyası kopyalandı"
    else
        echo "⚠️ Debug entitlements dosyası bulunamadı, production kullanılıyor"
    fi
else
    echo "✅ Release/Profile build - Production APNs ortamı kullanılıyor"
    # Production entitlements zaten Runner.entitlements'te
fi

echo "✅ Entitlements fix tamamlandı"






