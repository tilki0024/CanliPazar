import * as admin from "firebase-admin";

/**
 * FCM Token Validation Helper
 * Geçersiz token'ları tespit eder ve loglar
 */
export function isValidFCMToken(token: string | null | undefined): boolean {
  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    console.log(`⚠️ [Token Validation] Token null, undefined veya boş`);
    return false;
  }

  const trimmedToken = token.trim();

  // Minimum uzunluk kontrolü (FCM token'ları genellikle 100+ karakter)
  // iOS token'ları: ~163 karakter
  // Android token'ları: ~152 karakter
  // Ancak bazı token'lar daha kısa olabilir, bu yüzden 50 karakter minimum yapıyoruz
  if (trimmedToken.length < 50) {
    console.log(`⚠️ [Token Validation] Token çok kısa: ${trimmedToken.length} karakter (minimum: 50)`);
    return false;
  }

  // Maksimum uzunluk kontrolü (FCM token'ları genellikle 200 karakterden az)
  // Ancak bazı token'lar daha uzun olabilir, bu yüzden 500 karakter maksimum yapıyoruz
  if (trimmedToken.length > 500) {
    console.log(`⚠️ [Token Validation] Token çok uzun: ${trimmedToken.length} karakter (maksimum: 500)`);
    return false;
  }

  // Token format kontrolü (base64 benzeri karakterler içermeli)
  // FCM token'ları genellikle: [A-Za-z0-9_-:]+ formatında olur
  // Özellikle Android token'larında ':' karakteri olabilir
  const tokenPattern = /^[A-Za-z0-9_\-:]+$/;
  if (!tokenPattern.test(trimmedToken)) {
    console.log(`⚠️ [Token Validation] Token geçersiz karakter içeriyor`);
    console.log(`   - Token (ilk 50 karakter): ${trimmedToken.substring(0, 50)}...`);
    return false;
  }

  return true;
}

/**
 * Platform'u normalize et
 * iOS, Android, unknown durumlarını güvenli şekilde ele alır
 */
export function normalizePlatform(platform: string | null | undefined): 'ios' | 'android' | 'unknown' {
  if (!platform || typeof platform !== 'string') {
    return 'unknown';
  }

  const normalized = platform.toLowerCase().trim();

  if (normalized === 'ios' || normalized === 'iphone' || normalized === 'ipad') {
    return 'ios';
  }

  if (normalized === 'android') {
    return 'android';
  }

  return 'unknown';
}

/**
 * iOS için FCM payload oluştur
 */
export function createIOSPayload(
  title: string,
  body: string,
  unreadCount: number,
  data: Record<string, string>
): admin.messaging.ApnsConfig {
  return {
    payload: {
      aps: {
        sound: "default",
        badge: unreadCount,
        "content-available": 1,
        "mutable-content": 1,
        alert: {
          title: title,
          body: body,
        },
        category: "MESSAGE_CATEGORY",
      },
    },
    headers: {
      "apns-priority": "10",
      "apns-push-type": "alert",
      "apns-expiration": "0",
      "apns-topic": "com.canlipazar.app",
      // KRİTİK: aps-environment header'ı ekle
      // Development token'lar için development, production için production
      // Firebase otomatik olarak doğru environment'ı kullanır, ama manuel override edebiliriz
      // Not: Firebase genellikle otomatik olarak doğru environment'ı tespit eder
    },
    fcmOptions: {
      analyticsLabel: "message_notification",
    },
  };
}

/**
 * Android için FCM payload oluştur
 */
export function createAndroidPayload(
  unreadCount: number,
  channelId: string = "messages_channel"
): admin.messaging.AndroidConfig {
  return {
    priority: "high" as const,
    notification: {
      channelId: channelId,
      sound: "default",
      priority: "high" as const,
      notificationCount: unreadCount,
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
    },
  };
}

/**
 * Unknown platform için fallback payload oluştur
 * Hem iOS hem Android payload'larını içerir
 */
export function createUnknownPlatformPayload(
  title: string,
  body: string,
  unreadCount: number,
  data: Record<string, string>,
  channelId: string = "messages_channel"
): {
  android: admin.messaging.AndroidConfig;
  apns: admin.messaging.ApnsConfig;
} {
  return {
    android: createAndroidPayload(unreadCount, channelId),
    apns: createIOSPayload(title, body, unreadCount, data),
  };
}

/**
 * FCM mesajı gönder ve hataları güvenli şekilde ele al
 */
export async function sendFCMessage(
  message: admin.messaging.Message
): Promise<{
  success: boolean;
  messageId?: string;
  error?: string;
  errorCode?: string;
}> {
  try {
    // KRİTİK: Firebase Admin SDK'nın başlatıldığından emin ol
    if (!admin.apps.length) {
      admin.initializeApp();
    }

    // KRİTİK: FCM HTTP v1 API kullanımı - IAM yetkilerini otomatik kullanır
    const response = await admin.messaging().send(message);
    return {
      success: true,
      messageId: response,
    };
  } catch (error: any) {
    // KRİTİK: OAuth 2.0 authentication hatası için özel handling
    if (error.code === 'messaging/third-party-auth-error' ||
      error.code === 'messaging/authentication-error' ||
      error.message?.includes('OAuth 2') ||
      error.message?.includes('authentication credential') ||
      error.message?.includes('missing required authentication')) {
      console.error(`❌ [FCM Send] OAuth 2.0 authentication hatası`);
      console.error(`   - Hata kodu: ${error.code || 'UNKNOWN'}`);
      console.error(`   - Hata mesajı: ${error.message || 'N/A'}`);
      console.error(`   - ÇÖZÜM ADIMLARI:`);
      console.error(`   1. Google Cloud Console → IAM & Admin → Service Accounts`);
      console.error(`   2. Cloud Functions service account'u bulun`);
      console.error(`   3. 'Firebase Cloud Messaging Admin' rolünü ekleyin`);
      console.error(`   4. Detaylı rehber: functions/OAUTH2_FIX_GUIDE.md`);

      return {
        success: false,
        error: 'OAuth 2.0 authentication hatası - Google Cloud IAM rolleri kontrol edilmeli',
        errorCode: error.code || 'UNKNOWN',
      };
    }
    // Geçersiz token hatası - token'ı logla ve ayıkla
    if (error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered') {
      // Token'ı güvenli şekilde al (Message tipi union olduğu için)
      const token = 'token' in message ? message.token : 'unknown';
      const tokenStr = typeof token === 'string' ? token : 'unknown';
      console.error(`❌ [FCM Send] Geçersiz token tespit edildi`);
      console.error(`   - Token (ilk 30 karakter): ${tokenStr !== 'unknown' ? tokenStr.substring(0, 30) + '...' : 'unknown'}`);
      console.error(`   - Token uzunluğu: ${tokenStr !== 'unknown' ? tokenStr.length : 'N/A'} karakter`);
      console.error(`   - Hata kodu: ${error.code}`);
      console.error(`   - Hata mesajı: ${error.message || 'N/A'}`);

      return {
        success: false,
        error: 'Geçersiz FCM token - Token Firestore\'da eski olabilir veya geçersiz',
        errorCode: error.code,
      };
    }

    // Diğer hatalar
    console.error(`❌ [FCM Send] Bildirim gönderme hatası:`, error);
    console.error(`❌ [FCM Send] Hata kodu: ${error.code || 'unknown'}`);
    console.error(`❌ [FCM Send] Hata mesajı: ${error.message || 'Bilinmeyen hata'}`);

    return {
      success: false,
      error: error.message || 'Bilinmeyen hata',
      errorCode: error.code || 'unknown',
    };
  }
}

