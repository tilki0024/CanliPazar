import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// KRİTİK: Firebase Admin SDK başlatma - IAM yetkilerini otomatik kullanır
// Cloud Functions ortamında Application Default Credentials (ADC) otomatik olarak kullanılır
// Google Cloud IAM üzerinden 'Firebase Cloud Messaging Admin' rolü otomatik kullanılır
if (!admin.apps.length) {
  admin.initializeApp();
}

// KRİTİK: FCM Token Validation Helper
/**
 * FCM token formatını doğrula
 * iOS token'ları genellikle 163 karakter uzunluğunda olur
 * Android token'ları genellikle 152 karakter uzunluğunda olur
 */
function _isValidFCMToken(token: string): boolean {
  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    return false;
  }

  const trimmedToken = token.trim();

  // Minimum uzunluk kontrolü (FCM token'ları genellikle 100+ karakter)
  // Ancak daha kısa olabilir, bu yüzden 50 karakter minimum yapıyoruz
  if (trimmedToken.length < 50) {
    console.log(`⚠️ Token çok kısa: ${trimmedToken.length} karakter`);
    return false;
  }

  // Maksimum uzunluk kontrolü
  if (trimmedToken.length > 500) {
    console.log(`⚠️ Token çok uzun: ${trimmedToken.length} karakter`);
    return false;
  }

  // Token format kontrolü (base64 benzeri karakterler içermeli)
  // [A-Za-z0-9_\-:]+ formatında olur (Android token'larında : olabilir)
  const tokenPattern = /^[A-Za-z0-9_\-:]+$/;
  if (!tokenPattern.test(trimmedToken)) {
    console.log(`⚠️ Token geçersiz karakter içeriyor: ${trimmedToken.substring(0, 20)}...`);
    return false;
  }

  return true;
}

// Sohbet sistemi Cloud Functions'larını import et
export * from './chatFunctions';

// KARGAS fiyat güncelleme Cloud Functions'larını import et
export * from './slaughterPriceFunctions';

// Test bildirimi Cloud Function'ını import et
export * from './testNotification';

// Dynamic Link Cloud Function'ını import et
export * from './dynamicLinkFunctions';

// İlan sayfası Cloud Function'ını import et
export * from './ilanPageFunction';

// Notification helpers'ı import et
import {
  isValidFCMToken,
  normalizePlatform,
  createIOSPayload,
  createAndroidPayload,
  createUnknownPlatformPayload,
  sendFCMessage,
} from './notificationHelpers';

/**
 * Yeni mesaj bildirimi gönder (messages/{chatId}/messages/{messageId} yapısı için)
 * Firestore'da messages koleksiyonuna yeni mesaj eklendiğinde tetiklenir
 */


/**
 * Yeni mesaj bildirimi gönder (messages/{messageId} yapısı için)
 * Firestore'da messages koleksiyonuna yeni mesaj eklendiğinde tetiklenir
 * Alıcının FCM token'ını users/{userId}/fcmToken alanından alır
 */
export const onNewMessageCreated = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const messageId = context.params.messageId;

    // Mesaj verilerini al
    const text = messageData.text || "";
    const receiverId = messageData.receiverId || messageData.receiver || "";
    const senderId = messageData.senderId || messageData.sender || "";

    console.log(`📨 Yeni mesaj: ${messageId}`);
    console.log(`Gönderen: ${senderId}, Alıcı: ${receiverId}`);

    // Eğer gönderen ve alıcı aynıysa bildirim gönderme
    if (senderId === receiverId) {
      console.log("⚠️ Gönderen ve alıcı aynı, bildirim gönderilmiyor");
      return null;
    }

    // Alıcı ID kontrolü
    if (!receiverId || receiverId.trim().length === 0) {
      console.log("❌ Alıcı ID bulunamadı");
      return null;
    }

    // Alıcının kullanıcı bilgilerini al
    try {
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      if (!recipientDoc.exists) {
        console.log(`❌ Alıcı bulunamadı: ${receiverId}`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const recipientToken = recipientData?.fcmToken;

      if (!recipientToken || typeof recipientToken !== 'string' || recipientToken.trim().length === 0) {
        console.log(`⚠️ Alıcının FCM token'ı yok veya geçersiz: ${receiverId}`);
        return null;
      }

      console.log(`✅ Alıcı token bulundu: ${recipientToken.substring(0, 20)}...`);

      // Gönderen kullanıcı bilgilerini al (bildirim başlığı için)
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderData = senderDoc.data();
      const senderUsername = senderData?.username || "Birisi";
      console.log(`✅ Gönderen kullanıcı adı: ${senderUsername}`);

      // Alıcının okunmamış mesaj sayısını hesapla
      const unreadMessagesSnapshot = await admin
        .firestore()
        .collection("messages")
        .where("receiverId", "==", receiverId)
        .where("isRead", "==", false)
        .get();

      const unreadCount = unreadMessagesSnapshot.size > 0 ? unreadMessagesSnapshot.size : 1;
      console.log(`📊 Okunmamış mesaj sayısı: ${unreadCount}`);

      // Bildirim payload'ı oluştur
      // KRİTİK: Kullanıcı isteği - "kullanıcı_adı size mesaj gönderdi" formatı
      const notification = {
        title: `${senderUsername} size mesaj gönderdi`,
        body: text.length > 100 ? text.substring(0, 100) + "..." : text,
      };

      const data = {
        type: "message",
        senderId: senderId,
        receiverId: receiverId,
        messageId: messageId,
        text: text,
        unreadCount: unreadCount.toString(),
      };

      // FCM mesajı oluştur
      const message: admin.messaging.Message = {
        token: recipientToken.trim(),
        notification: notification,
        data: {
          type: data.type,
          senderId: data.senderId,
          receiverId: data.receiverId,
          messageId: data.messageId,
          text: data.text,
          unreadCount: data.unreadCount,
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "messages_channel",
            sound: "default",
            priority: "high" as const,
            notificationCount: unreadCount,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: unreadCount,
              "content-available": 1 as any,
              "mutable-content": 1 as any,
              alert: {
                title: notification.title,
                body: notification.body,
              },
              category: "MESSAGE_CATEGORY",
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          fcmOptions: {
            analyticsLabel: "message_notification",
          },
        },
      };

      // Bildirimi gönder
      const response = await admin.messaging().send(message);
      console.log(`✅ Bildirim başarıyla gönderildi: ${response}`);

      return null;
    } catch (error) {
      console.error(`❌ Bildirim gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Yeni mesaj oluşturulduğunda bildirim gönder
 * Firestore'da conversations/{conversationId}/messages/{messageId} alt koleksiyonuna yeni mesaj eklendiğinde tetiklenir
 */
export const onConversationMessageCreated = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const conversationId = context.params.conversationId;
    const messageId = context.params.messageId;

    // Mesaj verilerini al
    const text = messageData.text || "";
    // KRİTİK: Flutter tarafında "sender" ve "recipient" field'ları kullanılıyor
    const senderId = messageData.sender || messageData.senderId || "";
    const recipientId = messageData.recipient || messageData.receiverId || "";
    const postId = messageData.postId || "";
    const isRead = messageData.isRead || false;

    console.log(`🔵 [DEBUG] ========================================`);
    console.log(`🔵 [DEBUG] onConversationMessageCreated TRİGGER TETİKLENDİ`);
    console.log(`🔵 [DEBUG] ========================================`);
    console.log(`📨 Yeni mesaj (alt koleksiyon): ${messageId} - Conversation: ${conversationId}`);
    console.log(`   - Gönderen (sender): ${senderId}`);
    console.log(`   - Alıcı (recipient): ${recipientId}`);
    console.log(`   - Mesaj metni: ${text.substring(0, text.length > 50 ? 50 : text.length)}...`);
    console.log(`   - postId: ${postId || 'yok'}`);
    console.log(`   - isRead: ${isRead}`);
    console.log(`   - messageData keys: ${Object.keys(messageData).join(', ')}`);

    // Gönderen ve alıcı kontrolü
    if (!senderId || senderId.trim().length === 0) {
      console.log("❌ Gönderen ID bulunamadı");
      return null;
    }

    if (!recipientId || recipientId.trim().length === 0) {
      console.log("❌ Alıcı ID bulunamadı");
      return null;
    }

    // Eğer gönderen ve alıcı aynıysa bildirim gönderme
    if (senderId === recipientId) {
      console.log("⚠️ Gönderen ve alıcı aynı, bildirim gönderilmiyor");
      return null;
    }

    // Alıcının kullanıcı bilgilerini al
    try {
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();

      if (!recipientDoc.exists) {
        console.log(`❌ Alıcı bulunamadı: ${recipientId}`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const recipientToken = recipientData?.fcmToken;
      const recipientPlatform = recipientData?.platform;

      console.log(`🔵 [DEBUG] Alıcı bilgileri alındı:`);
      console.log(`   - recipientId: ${recipientId}`);
      console.log(`   - fcmToken: ${recipientToken ? recipientToken.substring(0, 20) + '...' : 'YOK'}`);
      console.log(`   - platform: ${recipientPlatform || 'YOK'}`);
      console.log(`   - messageNotificationsEnabled: ${recipientData?.messageNotificationsEnabled ?? true}`);

      // Token kontrolü - önce token'ı al
      if (!recipientToken || typeof recipientToken !== 'string' || recipientToken.trim().length === 0) {
        console.log(`❌ [onConversationMessageCreated] Alıcının FCM token'ı yok veya geçersiz: ${recipientId}`);
        console.log(`   - Token tipi: ${typeof recipientToken}`);
        console.log(`   - Token değeri: ${recipientToken || 'null/undefined'}`);
        console.log(`   - ÇÖZÜM: Alıcı uygulamayı yeniden açsın (token yenilensin)`);
        console.log(`🔵 [DEBUG] ========================================`);
        return null;
      }

      console.log(`✅ [onConversationMessageCreated] Alıcının FCM token'ı mevcut: ${recipientToken.substring(0, 20)}...`);

      const trimmedToken = recipientToken.trim();

      // KRİTİK: Platform kontrolü - "unknown" kullanıcılara bildirim gönderme
      // Eğer platform "unknown" ise, token'dan platform'u tahmin etmeye çalış
      let normalizedPlatform = recipientPlatform ? recipientPlatform.toLowerCase().trim() : '';

      if (!normalizedPlatform || normalizedPlatform === 'unknown' || normalizedPlatform === '') {
        console.log(`⚠️ [onConversationMessageCreated] Alıcının platform bilgisi geçersiz/unknown: ${recipientId}`);
        console.log(`   - Platform: ${recipientPlatform || 'boş'}`);
        console.log(`   - Token'dan platform tahmin ediliyor...`);

        // Token uzunluğundan platform tahmin et
        // iOS token'ları genellikle ~163 karakter, Android ~152 karakter
        const tokenLength = trimmedToken.length;
        if (tokenLength >= 150 && tokenLength <= 180) {
          // iOS token'ı gibi görünüyor
          normalizedPlatform = 'ios';
          console.log(`   - Token uzunluğu (${tokenLength}) iOS'a benziyor, platform "ios" olarak ayarlandı`);

          // Firestore'da platform'u güncelle
          try {
            await admin.firestore().collection('users').doc(recipientId).update({
              platform: 'ios',
              platformFixedBy: 'onConversationMessageCreated_auto_fix',
              platformFixedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`   ✅ Platform Firestore'da "ios" olarak güncellendi`);
          } catch (updateError) {
            console.error(`   ❌ Platform güncelleme hatası: ${updateError}`);
          }
        } else if (tokenLength >= 140 && tokenLength <= 160) {
          // Android token'ı gibi görünüyor
          normalizedPlatform = 'android';
          console.log(`   - Token uzunluğu (${tokenLength}) Android'e benziyor, platform "android" olarak ayarlandı`);

          // Firestore'da platform'u güncelle
          try {
            await admin.firestore().collection('users').doc(recipientId).update({
              platform: 'android',
              platformFixedBy: 'onConversationMessageCreated_auto_fix',
              platformFixedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`   ✅ Platform Firestore'da "android" olarak güncellendi`);
          } catch (updateError) {
            console.error(`   ❌ Platform güncelleme hatası: ${updateError}`);
          }
        } else {
          // Platform belirlenemedi, varsayılan olarak iOS dene (çoğu kullanıcı iOS)
          normalizedPlatform = 'ios';
          console.log(`   ⚠️ Platform belirlenemedi, varsayılan olarak "ios" kullanılıyor`);
          console.log(`   - Token uzunluğu: ${tokenLength} karakter`);
        }
      }

      // Platform sadece "ios" veya "android" olmalı
      if (normalizedPlatform !== 'ios' && normalizedPlatform !== 'android') {
        console.log(`❌ [onConversationMessageCreated] Geçersiz platform: ${normalizedPlatform} (userId: ${recipientId})`);
        console.log(`   - Sadece "ios" veya "android" kabul edilir`);
        console.log(`   - ÇÖZÜM: Alıcı uygulamayı yeniden açsın (platform güncellensin)`);
        return null;
      }

      console.log(`✅ [onConversationMessageCreated] Platform doğrulandı: ${normalizedPlatform}`);

      console.log(`✅ [onConversationMessageCreated] Platform doğrulandı: ${normalizedPlatform}`);

      // Bildirim ayarları kontrolü
      const messageNotificationsEnabled = recipientData?.messageNotificationsEnabled ?? true;
      if (!messageNotificationsEnabled) {
        console.log(`⏭️ Alıcı mesaj bildirimlerini kapalı: ${recipientId}`);
        return null;
      }

      // Gönderen kullanıcı bilgilerini al (bildirim başlığı için)
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderData = senderDoc.data();
      const senderUsername = senderData?.username || "Birisi";
      console.log(`✅ Gönderen kullanıcı adı: ${senderUsername}`);

      // KRİTİK: Kullanıcı isteği - Her mesaj geldiğinde badge 1 olsun
      // Sohbete girildiğinde badge sıfırlanacak (Flutter tarafında)
      const unreadCount = 1; // Her mesaj için badge 1
      console.log(`📊 Badge sayısı: ${unreadCount} (her mesaj için 1)`);

      // Bildirim payload'ı oluştur
      // KRİTİK: Kullanıcı isteği - "kullanıcı_adı size mesaj gönderdi" formatı
      const notification = {
        title: `${senderUsername} size mesaj gönderdi`,
        body: text.length > 100 ? text.substring(0, 100) + "..." : text, // Mesaj içeriği
      };

      const data = {
        type: "message",
        conversationId: conversationId,
        // KRİTİK: Kullanıcı isteği - sadece type ve conversationId gerekli
        // Diğer alanlar opsiyonel (geriye uyumluluk için)
        senderId: senderId,
        receiverId: recipientId,
        messageId: messageId,
        postId: postId || "",
        text: text,
        unreadCount: unreadCount.toString(),
      };

      // KRİTİK: Token validation - daha esnek kontrol
      // trimmedToken zaten yukarıda tanımlanmış
      console.log(`🔵 [DEBUG] Token validation yapılıyor...`);
      console.log(`   - Token uzunluğu: ${trimmedToken.length} karakter`);
      console.log(`   - Token (ilk 30 karakter): ${trimmedToken.substring(0, 30)}...`);
      console.log(`   - Platform: ${normalizedPlatform}`);

      // Token validation'ı daha esnek yap - sadece çok açık hataları yakala
      if (!trimmedToken || trimmedToken.length < 50) {
        console.log(`❌ [onConversationMessageCreated] Token çok kısa: ${trimmedToken.length} karakter`);
        console.log(`   - Minimum 50 karakter gerekli`);
        return null;
      }

      if (trimmedToken.length > 500) {
        console.log(`❌ [onConversationMessageCreated] Token çok uzun: ${trimmedToken.length} karakter`);
        console.log(`   - Maksimum 500 karakter kabul edilir`);
        return null;
      }

      console.log(`✅ [DEBUG] Token validation başarılı`);

      // KRİTİK: iOS ÇİFT BİLDİRİM SORUNU ÇÖZÜMÜ
      // iOS için notification field KULLANMA - sadece apns payload kullan
      // Android için notification field kullan
      // Bu sayede iOS'ta çift bildirim önlenir

      // FCM mesajı oluştur - Platform bazlı payload
      const message: admin.messaging.Message = {
        token: trimmedToken,
        // KRİTİK: iOS için notification field'ını KALDIRDIK
        // iOS apns.payload.aps.alert kullanacak
        // KRİTİK: Android için notification field'ını KALDIRDIK (Çift bildirim çözümü)
        // Android message handler (data-only) yerel bildirim gösterecek
        // notification: notification, // ARTIK KULLANILMIYOR
        data: {
          type: String(data.type || ''),
          senderId: String(data.senderId || ''),
          receiverId: String(data.receiverId || ''),
          conversationId: String(data.conversationId || ''),
          messageId: String(data.messageId || ''),
          postId: String(data.postId || ''),
          text: String(data.text || ''),
          unreadCount: String(data.unreadCount || '0'),
          senderUsername: String(senderUsername || ''), // KRİTİK: Flutter tarafında kullanılmak üzere
          title: String(notification.title || ''), // KRİTİK: Flutter tarafında kullanılmak üzere
        },
        android: {
          priority: "high" as const,
          // KRİTİK: notification object KALDIRILDI (Çift bildirim ve boş bildirim çözümü)
          // Android System otomatik bildirim göstermeyecek
          // App background handler (data-only message) yerel bildirim gösterecek
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: unreadCount,
              "content-available": 1,
              "mutable-content": 1,
              alert: {
                title: notification.title,
                body: notification.body,
              },
              category: "MESSAGE_CATEGORY",
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
            "apns-expiration": "0",
            "apns-topic": "com.canlipazar.app",
          },
          fcmOptions: {
            analyticsLabel: "message_notification",
          },
        },
      };

      console.log(`🔵 [DEBUG] Mesaj payload oluşturuldu:`)
      console.log(`   - Platform: ${normalizedPlatform}`);
      console.log(`   - notification field: ${normalizedPlatform === 'android' ? 'VAR (Android için)' : 'YOK (iOS için çift bildirim önleme)'}`);

      // Bildirimi gönder - detaylı error handling
      try {
        console.log(`📤 [onConversationMessageCreated] Bildirim gönderiliyor...`);
        console.log(`   - Alıcı: ${recipientId}`);
        console.log(`   - Platform: ${normalizedPlatform}`);
        console.log(`   - Token: ${trimmedToken.substring(0, 20)}...`);
        console.log(`   - Token uzunluğu: ${trimmedToken.length} karakter`);
        console.log(`   - Başlık: ${notification.title}`);
        console.log(`   - İçerik: ${notification.body}`);
        console.log(`   - Android Channel: messages_channel`);
        console.log(`   - iOS Bundle ID: com.canlipazar.app`);

        // KRİTİK: Firebase Admin SDK başlatma kontrolü - IAM yetkilerini otomatik kullanır
        if (!admin.apps.length) {
          admin.initializeApp();
        }

        // KRİTİK: FCM HTTP v1 API kullanımı - IAM yetkilerini otomatik kullanır
        console.log(`📤 [onConversationMessageCreated] Bildirim gönderiliyor (FCM HTTP v1 API)...`);
        console.log(`   - Token: ${trimmedToken.substring(0, 20)}...`);
        console.log(`   - Platform: ${normalizedPlatform}`);

        const response = await admin.messaging().send(message);
        console.log(`✅ [onConversationMessageCreated] Bildirim başarıyla gönderildi: ${response}`);
        console.log(`✅ Alıcı: ${recipientId}, Platform: ${normalizedPlatform}`);
        console.log(`✅ Token: ${trimmedToken.substring(0, 20)}...`);
        console.log(`✅ MessageId: ${response}`);
        console.log(`🔵 [DEBUG] ========================================`);
        console.log(`🔵 [DEBUG] BİLDİRİM BAŞARIYLA GÖNDERİLDİ`);
        console.log(`🔵 [DEBUG] ========================================`);
        return response;
      } catch (sendError: any) {
        console.error(`🔴 [DEBUG] ========================================`);
        console.error(`🔴 [DEBUG] BİLDİRİM GÖNDERME HATASI`);
        console.error(`🔴 [DEBUG] ========================================`);
        console.error(`❌ [onConversationMessageCreated] Bildirim gönderme hatası:`);
        console.error(`   - Hata kodu: ${sendError.code || 'UNKNOWN'}`);
        console.error(`   - Hata mesajı: ${sendError.message || 'Bilinmeyen hata'}`);
        console.error(`   - Alıcı ID: ${recipientId}`);
        console.error(`   - Platform: ${normalizedPlatform || recipientPlatform || 'bilinmiyor'}`);
        console.error(`   - Token (ilk 30 karakter): ${trimmedToken.substring(0, 30)}...`);
        console.error(`   - Token uzunluğu: ${trimmedToken.length} karakter`);
        console.error(`   - ConversationId: ${conversationId}`);
        console.error(`   - MessageId: ${messageId}`);
        console.error(`   - Stack trace: ${sendError.stack || 'N/A'}`);
        console.error(`   - Full error: ${JSON.stringify(sendError, null, 2)}`);

        // KRİTİK: OAuth 2.0 authentication hatası için özel handling
        if (sendError.code === 'messaging/third-party-auth-error' ||
          sendError.code === 'messaging/authentication-error' ||
          sendError.message?.includes('OAuth 2') ||
          sendError.message?.includes('authentication credential')) {
          console.error(`❌ [onConversationMessageCreated] OAuth 2.0 authentication hatası`);
          console.error(`   - Hata kodu: ${sendError.code || 'UNKNOWN'}`);
          console.error(`   - Hata mesajı: ${sendError.message || 'N/A'}`);
          console.error(`   - ÇÖZÜM ADIMLARI:`);
          console.error(`   1. Google Cloud Console → IAM & Admin → Service Accounts`);
          console.error(`   2. Cloud Functions service account'u bulun (örn: PROJECT_ID@appspot.gserviceaccount.com)`);
          console.error(`   3. 'Firebase Cloud Messaging Admin' rolünü ekleyin`);
          console.error(`   4. Veya 'Firebase Admin SDK Administrator Service Agent' rolünü ekleyin`);
          console.error(`   5. Firebase Console → Project Settings → Service Accounts kontrol edin`);
          console.error(`   6. APNs certificate/key doğru yapılandırılmış mı kontrol edin (iOS için)`);
          console.error(`   7. iOS için: APNs Authentication Key (p8) yüklü mü?`);
          console.error(`   8. Key ID ve Team ID doğru mu?`);
          console.error(`   - NOT: Cloud Functions ortamında Application Default Credentials otomatik kullanılır`);
          console.error(`   - Service account key dosyası gerekmez, IAM rolleri yeterlidir`);
        }

        // Token geçersizse logla ve Firestore'dan sil
        if (sendError.code === 'messaging/invalid-registration-token' ||
          sendError.code === 'messaging/registration-token-not-registered') {
          console.error(`❌ [onConversationMessageCreated] Token geçersiz veya kayıtlı değil`);
          console.error(`   - Token (ilk 20 karakter): ${trimmedToken.substring(0, 20)}...`);
          console.error(`   - Alıcı ID: ${recipientId}`);
          console.error(`   - Platform: ${normalizedPlatform}`);

          // Geçersiz token'ı Firestore'dan sil
          try {
            await admin.firestore().collection('users').doc(recipientId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
              fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
              platformInvalidatedReason: 'invalid_token_on_notification_send',
            });
            console.log(`✅ [onConversationMessageCreated] Geçersiz token Firestore'dan silindi: ${recipientId}`);
          } catch (deleteError) {
            console.error(`❌ [onConversationMessageCreated] Token silme hatası: ${deleteError}`);
          }
        }

        return null;
      }

      return null;
    } catch (error) {
      console.error(`❌ Bildirim gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Yeni mesaj oluşturulduğunda bildirim gönder (ESKİ SİSTEM - conversations/{messageId})
 * Firestore'da conversations koleksiyonuna yeni mesaj eklendiğinde tetiklenir
 */
export const onMessageCreated = functions.firestore
  .document("conversations/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const messageId = context.params.messageId;

    // Mesaj verilerini al
    const text = messageData.text || "";
    const senderId = messageData.sender || "";
    const recipientId = messageData.recipient || "";
    const postId = messageData.postId || "";

    console.log(`📨 Yeni mesaj: ${messageId}`);
    console.log(`Gönderen: ${senderId}, Alıcı: ${recipientId}`);
    console.log(`Mesaj metni: ${text.substring(0, 50)}...`);

    // Gönderen ve alıcı kontrolü
    if (!senderId || senderId.trim().length === 0) {
      console.log("❌ Gönderen ID bulunamadı");
      return null;
    }

    if (!recipientId || recipientId.trim().length === 0) {
      console.log("❌ Alıcı ID bulunamadı");
      return null;
    }

    // Eğer gönderen ve alıcı aynıysa bildirim gönderme
    if (senderId === recipientId) {
      console.log("⚠️ Gönderen ve alıcı aynı, bildirim gönderilmiyor");
      return null;
    }

    // Alıcının kullanıcı bilgilerini al
    try {
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();

      if (!recipientDoc.exists) {
        console.log(`❌ Alıcı bulunamadı: ${recipientId}`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const recipientToken = recipientData?.fcmToken;
      const recipientPlatform = recipientData?.platform; // iOS kontrolü için

      // Bildirim ayarları kontrolü
      const messageNotificationsEnabled = recipientData?.messageNotificationsEnabled ?? true;
      if (!messageNotificationsEnabled) {
        console.log(`⏭️ Alıcı mesaj bildirimlerini kapalı: ${recipientId}`);
        return null;
      }

      if (!recipientToken || typeof recipientToken !== 'string' || recipientToken.trim().length === 0) {
        console.log(`⚠️ Alıcının FCM token'ı yok veya geçersiz: ${recipientId}`);
        console.log(`⚠️ Token tipi: ${typeof recipientToken}, uzunluk: ${recipientToken?.length || 0}`);
        return null;
      }

      // KRİTİK iOS DÜZELTME: Token validation ve platform kontrolü
      const trimmedToken = recipientToken.trim();

      // Token validation
      if (!_isValidFCMToken(trimmedToken)) {
        console.log(`❌ Geçersiz FCM token formatı: ${trimmedToken.substring(0, 20)}...`);
        return null;
      }

      // KRİTİK: iOS için platform kontrolü
      const isIOS = recipientPlatform === 'ios' || recipientPlatform === 'iOS' || !recipientPlatform || recipientPlatform === 'unknown';
      console.log(`✅ Alıcı token bulundu (platform: ${recipientPlatform || 'bilinmiyor'}): ${trimmedToken.substring(0, 20)}...`);
      console.log(`✅ iOS bildirimi gönderiliyor: ${isIOS}`);

      // Gönderen kullanıcı bilgilerini al (bildirim başlığı için)
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderData = senderDoc.data();
      const senderUsername = senderData?.username || "Birisi";

      // Alıcının okunmamış mesaj sayısını hesapla
      // Bu alıcıya gönderilmiş ve henüz okunmamış tüm mesajları say
      const unreadMessagesSnapshot = await admin
        .firestore()
        .collection("conversations")
        .where("recipient", "==", recipientId)
        .where("isRead", "==", false)
        .get();

      const unreadCount = unreadMessagesSnapshot.size > 0 ? unreadMessagesSnapshot.size : 1;
      console.log(`📊 Okunmamış mesaj sayısı: ${unreadCount}`);

      // Bildirim payload'ı oluştur
      // KRİTİK: Kullanıcı isteği - "kullanıcı_adı size mesaj gönderdi" formatı
      const notificationBody = text.length > 100 ? text.substring(0, 100) + "..." : text;
      const notification = {
        title: `${senderUsername} size mesaj gönderdi`,
        body: notificationBody, // Mesaj içeriği
      };

      const data = {
        type: "message",
        senderId: senderId,
        receiverId: recipientId,
        messageId: messageId,
        conversationId: messageId, // Eski sistem için conversationId = messageId
        postId: postId || "",
        text: text,
        unreadCount: unreadCount.toString(), // Badge sayısını data'ya da ekle
      };

      // FCM mesajı oluştur - iOS için %100 uyumlu APNs payload
      const message: admin.messaging.Message = {
        token: trimmedToken,
        notification: notification,
        data: {
          type: data.type,
          senderId: data.senderId,
          receiverId: data.receiverId,
          messageId: data.messageId,
          conversationId: data.conversationId,
          postId: data.postId,
          text: data.text,
          unreadCount: data.unreadCount,
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "messages_channel",
            sound: "default",
            priority: "high" as const,
            notificationCount: unreadCount, // Android badge count
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: unreadCount, // Gerçek okunmamış mesaj sayısı
              "content-available": 1, // iOS terminated state için kritik - number olarak
              "mutable-content": 1, // iOS için mutable content (ekran kapalıyken bildirim için) - number olarak
              alert: {
                title: notification.title,
                body: notification.body,
              },
              category: "MESSAGE_CATEGORY", // iOS için kategori
            },
          },
          headers: {
            "apns-priority": "10", // Yüksek öncelik - terminated state için
            "apns-push-type": "alert", // Alert tipi bildirim
            "apns-expiration": "0", // Hemen gönder, expire olmasın
            "apns-topic": "com.canlipazar.app", // iOS bundle ID - KRİTİK!
          },
          fcmOptions: {
            // iOS için ek seçenekler
            analyticsLabel: "message_notification",
          },
        },
      };

      // Bildirimi gönder - detaylı error handling
      try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Bildirim başarıyla gönderildi: ${response}`);
        console.log(`✅ Alıcı: ${recipientId}, Platform: ${recipientPlatform || 'bilinmiyor'}`);
        console.log(`✅ Token: ${trimmedToken.substring(0, 20)}...`);
        console.log(`✅ Bildirim başlığı: ${notification.title}`);
        console.log(`✅ Bildirim metni: ${notification.body}`);
        return response;
      } catch (sendError: any) {
        console.error(`❌ Bildirim gönderme hatası:`, sendError);
        console.error(`❌ Hata kodu: ${sendError.code || 'UNKNOWN'}`);
        console.error(`❌ Hata mesajı: ${sendError.message || 'Bilinmeyen hata'}`);

        // Token geçersizse logla ve Firestore'dan sil
        if (sendError.code === 'messaging/invalid-registration-token' ||
          sendError.code === 'messaging/registration-token-not-registered') {
          console.error(`❌ Token geçersiz veya kayıtlı değil: ${trimmedToken.substring(0, 20)}...`);
          console.error(`❌ Alıcı ID: ${recipientId}`);

          // Geçersiz token'ı Firestore'dan sil
          try {
            await admin.firestore().collection('users').doc(recipientId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
            console.log(`✅ Geçersiz token Firestore'dan silindi: ${recipientId}`);
          } catch (deleteError) {
            console.error(`❌ Token silme hatası: ${deleteError}`);
          }
        }

        return null;
      }

      return null;
    } catch (error) {
      console.error(`❌ Bildirim gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Kullanıcı token'ı güncellendiğinde log tut (opsiyonel)
 */
export const onUserTokenUpdated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const userId = context.params.userId;

    // FCM token değişti mi kontrol et
    if (beforeData.fcmToken !== afterData.fcmToken) {
      console.log(`🔄 Kullanıcı token güncellendi: ${userId}`);
      console.log(`Eski token: ${beforeData.fcmToken?.substring(0, 20)}...`);
      console.log(`Yeni token: ${afterData.fcmToken?.substring(0, 20)}...`);
    }

    return null;
  });

/**
 * Yeni ilan eklendiğinde tüm kullanıcılara bildirim gönder (iOS ve Android)
 * Firestore'da animals koleksiyonuna yeni ilan eklendiğinde tetiklenir
 * Her yeni ilan eklendiğinde iOS ve Android kullanıcılarına "Yeni ilan eklendi" bildirimi gönderilir
 */
export const onNewAnimalPostCreated = functions.firestore
  .document("animals/{animalId}")
  .onCreate(async (snap, context) => {
    const animalData = snap.data();
    const animalId = context.params.animalId;

    console.log(`🆕 Yeni hayvan ilanı eklendi: ${animalId}`);
    console.log(`İlan sahibi: ${animalData.uid || "Bilinmiyor"}`);

    try {
      // KRİTİK: Her 2 ilan için 1 bildirim gönderme mekanizması
      // Firestore'da counter document'i tutuyoruz
      const counterRef = admin.firestore().collection('system').doc('animalPostCounter');
      
      // Transaction ile atomic counter artırma
      const counterDoc = await admin.firestore().runTransaction(async (transaction) => {
        const counterSnap = await transaction.get(counterRef);
        const currentCount = counterSnap.exists ? (counterSnap.data()?.count || 0) : 0;
        const newCount = currentCount + 1;
        
        // Counter'ı güncelle
        if (counterSnap.exists) {
          transaction.update(counterRef, { count: newCount });
        } else {
          transaction.set(counterRef, { count: newCount });
        }
        
        return { count: newCount, shouldSend: newCount >= 2 };
      });
      
      console.log(`📊 Hayvan ilanı counter: ${counterDoc.count}/2`);
      
      // Eğer counter 2'ye ulaşmadıysa bildirim gönderme
      if (!counterDoc.shouldSend) {
        console.log(`⏳ Bildirim gönderilmeyecek (${counterDoc.count}/2 ilan bekleniyor)`);
        return null;
      }
      
      // Counter 2'ye ulaştı, bildirim gönder ve counter'ı sıfırla
      await counterRef.update({ count: 0 });
      console.log(`✅ Counter sıfırlandı, bildirim gönderiliyor...`);

      // KRİTİK: İlan sahibi ID'sini önce al (forEach'ten önce)
      const postOwnerId = animalData.uid || "";
      console.log(`📋 İlan sahibi: ${postOwnerId}`);

      // Tüm kullanıcıları al (batch işleme ile - daha güvenilir)
      // Firestore query limiti 1000, bu yüzden batch işleme kullanıyoruz
      const iosTokens: string[] = [];
      const androidTokens: string[] = [];
      let iosUserCount = 0;
      let androidUserCount = 0;
      let totalUsersChecked = 0;
      let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

      // Batch işleme ile tüm kullanıcıları al
      do {
        let query: admin.firestore.Query = admin.firestore().collection("users");

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(1000).get();
        totalUsersChecked += usersSnapshot.size;

        if (usersSnapshot.empty) {
          break;
        }

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const fcmToken = userData.fcmToken;
          const userId = doc.id;
          const platform = userData.platform;

          // Token kontrolü - boş string ve null kontrolü
          if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
            return; // Geçersiz token
          }

          // Token validation
          const trimmedToken = fcmToken.trim();
          if (!_isValidFCMToken(trimmedToken)) {
            return; // Geçersiz token formatı
          }

          // KRİTİK: İlan sahibine bildirim gönderme
          if (userId === postOwnerId) {
            return; // İlan sahibine bildirim gönderme
          }

          // KRİTİK: Platform bilgisi kontrolü - "unknown" kullanıcılara bildirim gönderme
          const normalizedPlatform = platform ? platform.toLowerCase().trim() : '';

          // Platform sadece "ios" veya "android" olmalı
          if (normalizedPlatform === 'ios') {
            iosTokens.push(trimmedToken);
            iosUserCount++;
          } else if (normalizedPlatform === 'android') {
            androidTokens.push(trimmedToken);
            androidUserCount++;
          } else {
            // Platform "unknown" veya geçersiz ise bildirim gönderme
            console.log(`⚠️ [onNewAnimalPostCreated] Platform bilgisi geçersiz/unknown: ${userId}, platform: ${platform || 'boş'}`);
            return; // Bu kullanıcıya bildirim gönderme
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null);

      console.log(`📱 Toplam ${totalUsersChecked} kullanıcı kontrol edildi`);
      console.log(`📊 Platform dağılımı: iOS=${iosUserCount}, Android=${androidUserCount}`);
      console.log(`📊 Toplam token: ${iosTokens.length + androidTokens.length}`);

      if (iosTokens.length === 0 && androidTokens.length === 0) {
        console.log("⚠️ Bildirim gönderilecek kullanıcı bulunamadı");
        console.log("⚠️ Olası nedenler:");
        console.log("   - Tüm token'lar geçersiz");
        return null;
      }

      // Bildirim payload'ı
      // KRİTİK: Kullanıcı isteği - Her 2 ilan için 1 bildirim
      // Title: "CanlıPazar", Body: "Yeni İlanlar Eklendi!"
      // postOwnerId zaten yukarıda tanımlı
      const notification = {
        title: "CanlıPazar", // Kullanıcı isteği: "CanlıPazar"
        body: "Yeni İlanlar Eklendi!", // Kullanıcı isteği: "Yeni İlanlar Eklendi!"
      };

      const data = {
        type: "listing", // Kullanıcı isteği: type = "listing"
        listingId: animalId, // Kullanıcı isteği: listingId = animalId
        // Geriye uyumluluk için ek alanlar
        animalId: animalId,
        postOwnerId: postOwnerId,
      };

      // Bildirimleri gönder (iOS ve Android ayrı ayrı)
      const batchSize = 500;
      let totalSuccessCount = 0;
      let totalFailureCount = 0;

      // iOS kullanıcılarına bildirim gönder
      if (iosTokens.length > 0) {
        console.log(`✅ ${iosTokens.length} iOS kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < iosTokens.length; i += batchSize) {
          const batchTokens = iosTokens.slice(i, i + batchSize);
          const iosMessage: admin.messaging.MulticastMessage = {
            tokens: batchTokens,
            // KRİTİK: iOS için notification field'ı kaldırıldı (çift bildirim/gönderim sorunu çözümü)
            // Sadece apns payload kullanılacak
            // notification: notification,
            data: {
              type: String(data.type || ''),
              animalId: String(data.animalId || ''),
              postOwnerId: String(data.postOwnerId || ''),
            },
            // iOS için özel APNs ayarları
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  "content-available": 1,
                  "mutable-content": 1,
                  alert: {
                    title: notification.title,
                    body: notification.body,
                  },
                  category: "NEW_POST_CATEGORY",
                },
              },
              headers: {
                "apns-priority": "10",
                "apns-push-type": "alert",
                "apns-expiration": "0",
                "apns-topic": "com.canlipazar.app",
              },
              fcmOptions: {
                analyticsLabel: "new_post_notification",
              },
            },
          };

          try {
            // KRİTİK: Token validation - geçersiz token'ları filtrele
            const validTokens = batchTokens.filter(token => _isValidFCMToken(token));
            if (validTokens.length === 0) {
              console.log(`⚠️ iOS Batch ${Math.floor(i / batchSize) + 1}: Tüm token'lar geçersiz, atlandı`);
              totalFailureCount += batchTokens.length;
              continue;
            }

            if (validTokens.length < batchTokens.length) {
              console.log(`⚠️ iOS Batch ${Math.floor(i / batchSize) + 1}: ${batchTokens.length - validTokens.length} geçersiz token filtrelendi`);
              totalFailureCount += (batchTokens.length - validTokens.length);
            }

            // Geçerli token'larla mesaj oluştur
            const validMessage: admin.messaging.MulticastMessage = {
              ...iosMessage,
              tokens: validTokens,
            };

            const response = await admin.messaging().sendEachForMulticast(validMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            console.log(
              `📤 iOS Batch ${Math.floor(i / batchSize) + 1}: ` +
              `${response.successCount} başarılı, ` +
              `${response.failureCount} başarısız`
            );

            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  const errorCode = resp.error?.code || 'UNKNOWN';
                  const errorMessage = resp.error?.message || "Bilinmeyen hata";
                  console.log(
                    `❌ iOS Token hatası: ${validTokens[idx].substring(0, 20)}... - ` +
                    `Code: ${errorCode}, Message: ${errorMessage}`
                  );

                  // Geçersiz token'ı Firestore'dan sil
                  if (errorCode === 'messaging/invalid-registration-token' ||
                    errorCode === 'messaging/registration-token-not-registered') {
                    // Token'a sahip kullanıcıyı bul ve token'ı sil
                    admin.firestore().collection('users')
                      .where('fcmToken', '==', validTokens[idx])
                      .limit(1)
                      .get()
                      .then(snapshot => {
                        if (!snapshot.empty) {
                          snapshot.docs[0].ref.update({
                            fcmToken: admin.firestore.FieldValue.delete(),
                          });
                          console.log(`✅ Geçersiz token Firestore'dan silindi: ${snapshot.docs[0].id}`);
                        }
                      })
                      .catch(err => console.error(`❌ Token silme hatası: ${err}`));
                  }
                }
              });
            }
          } catch (error: any) {
            console.error(`❌ iOS Batch gönderme hatası:`, error);
            console.error(`❌ Hata kodu: ${error.code || 'UNKNOWN'}`);
            console.error(`❌ Hata mesajı: ${error.message || 'Bilinmeyen hata'}`);
            totalFailureCount += batchTokens.length;
          }
        }
      }

      // Android kullanıcılarına bildirim gönder
      if (androidTokens.length > 0) {
        console.log(`✅ ${androidTokens.length} Android kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < androidTokens.length; i += batchSize) {
          const batchTokens = androidTokens.slice(i, i + batchSize);
          const androidMessage: admin.messaging.MulticastMessage = {
            tokens: batchTokens,
            // notification: notification,
            data: {
              type: String(data.type || ''),
              animalId: String(data.animalId || ''),
              postOwnerId: String(data.postOwnerId || ''),
              // KRİTİK: App background handler için title ve body ekle
              title: String(notification.title || ''),
              body: String(notification.body || ''),
            },
            // Android için özel ayarlar
            android: {
              priority: "high" as const,
              // KRİTİK: notification object KALDIRILDI
              // Böylece Android System otomatik bildirim göstermez (boş bildirim sorunu çözümü)
              // App background handler (data-only message) yerel bildirim gösterecek (çift bildirim çözümü)
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(androidMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            console.log(
              `📤 Android Batch ${Math.floor(i / batchSize) + 1}: ` +
              `${response.successCount} başarılı, ` +
              `${response.failureCount} başarısız`
            );

            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  console.log(
                    `❌ Android Token hatası: ${batchTokens[idx].substring(0, 20)}... - ` +
                    `${resp.error?.message || "Bilinmeyen hata"}`
                  );
                }
              });
            }
          } catch (error) {
            console.error(`❌ Android Batch gönderme hatası:`, error);
            totalFailureCount += batchTokens.length;
          }
        }
      }

      console.log(
        `✅ Toplam: ${totalSuccessCount} başarılı (iOS: ${iosUserCount}, Android: ${androidUserCount}), ${totalFailureCount} başarısız`
      );

      return null;
    } catch (error) {
      console.error(`❌ Yeni ilan bildirimi gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Yeni Feed (Yem) ilanı eklendiğinde tüm kullanıcılara bildirim gönder
 */
export const onNewFeedPostCreated = functions.firestore
  .document("feeds/{feedId}")
  .onCreate(async (snap, context) => {
    const feedData = snap.data();
    const feedId = context.params.feedId;

    console.log(`🆕 Yeni yem ilanı eklendi: ${feedId}`);
    console.log(`İlan sahibi: ${feedData.uid || "Bilinmiyor"}`);

    try {
      console.log(`✅ Yeni yem ilanı bildirimi gönderiliyor...`);

      // KRİTİK: İlan sahibi ID'sini önce al (forEach'ten önce)
      const postOwnerId = feedData.uid || "";
      console.log(`📋 İlan sahibi: ${postOwnerId}`);

      // Tüm kullanıcıları al (batch işleme ile - daha güvenilir)
      const iosTokens: string[] = [];
      const androidTokens: string[] = [];
      let iosUserCount = 0;
      let androidUserCount = 0;
      let totalUsersChecked = 0;
      let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

      // Batch işleme ile tüm kullanıcıları al
      do {
        let query: admin.firestore.Query = admin.firestore().collection("users");

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(1000).get();
        totalUsersChecked += usersSnapshot.size;

        if (usersSnapshot.empty) {
          break;
        }

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const fcmToken = userData.fcmToken;
          const userId = doc.id;
          const platform = userData.platform;

          // Token kontrolü - boş string ve null kontrolü
          if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
            return; // Geçersiz token
          }

          // Token validation
          const trimmedToken = fcmToken.trim();
          if (!_isValidFCMToken(trimmedToken)) {
            return; // Geçersiz token formatı
          }

          // KRİTİK: Kullanıcı isteği - TÜM kullanıcılara bildirim gönder
          // İlan sahibine de bildirim gönderilecek (kullanıcı isteği)
          // postNotificationsEnabled kontrolü kaldırıldı (kullanıcı isteği)

          // Platform bilgisi kontrolü
          if (platform === 'ios' || platform === 'iOS' || !platform || platform === 'unknown') {
            iosTokens.push(trimmedToken);
            iosUserCount++;
          }

          if (platform === 'android' || platform === 'Android') {
            androidTokens.push(trimmedToken);
            androidUserCount++;
          } else if (!platform || platform === 'unknown') {
            // Platform bilgisi yoksa/unknown ise Android'e de gönder (geriye dönük uyumluluk)
            androidTokens.push(trimmedToken);
            androidUserCount++;
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null);

      console.log(`📱 Toplam ${totalUsersChecked} kullanıcı kontrol edildi`);
      console.log(`📊 Platform dağılımı: iOS=${iosUserCount}, Android=${androidUserCount}`);
      console.log(`📊 Toplam token: ${iosTokens.length + androidTokens.length}`);

      if (iosTokens.length === 0 && androidTokens.length === 0) {
        console.log("⚠️ Bildirim gönderilecek kullanıcı bulunamadı");
        return null;
      }

      // Bildirim payload'ı
      // KRİTİK: Yem ilanı için özelleştirilmiş mesaj
      // feedCategory ve brand bilgilerini kullanarak dinamik mesaj oluştur
      const feedCategory = feedData.feedCategory || feedData.feedType || "Yem";
      const brand = feedData.brand || "";
      
      // Mesaj formatı: "{feedCategory} Yem İlanı Eklendi Bakabilirsin!"
      // Örnek: "Silaj Yem İlanı Eklendi Bakabilirsin!" veya "Arpa Yem İlanı Eklendi Bakabilirsin!"
      let notificationTitle = `${feedCategory} Yem İlanı Eklendi`;
      let notificationBody = "Bakabilirsin!";
      
      // Eğer marka bilgisi varsa, body'ye ekle
      if (brand && brand.trim().length > 0) {
        notificationBody = `${brand} markası - Bakabilirsin!`;
      }
      
      const notification = {
        title: notificationTitle,
        body: notificationBody,
      };
      
      console.log(`📢 Yem ilanı bildirim mesajı: ${notificationTitle} - ${notificationBody}`);

      const data = {
        type: "listing", // Kullanıcı isteği: type = "listing"
        listingId: feedId, // Kullanıcı isteği: listingId = feedId
        // Geriye uyumluluk için ek alanlar
        feedId: feedId,
        postOwnerId: postOwnerId,
      };

      // Bildirimleri gönder (iOS ve Android ayrı ayrı)
      const batchSize = 500;
      let totalSuccessCount = 0;
      let totalFailureCount = 0;

      // iOS kullanıcılarına bildirim gönder
      if (iosTokens.length > 0) {
        console.log(`✅ ${iosTokens.length} iOS kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < iosTokens.length; i += batchSize) {
          const batchTokens = iosTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const iosMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            // KRİTİK: iOS için notification field'ı kaldırıldı (çift bildirim/gönderim sorunu çözümü)
            // Sadece apns payload kullanılacak
            // notification: notification,
            data: {
              type: String(data.type || ''),
              feedId: String(data.feedId || ''),
              postOwnerId: String(data.postOwnerId || ''),
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  "content-available": 1,
                  "mutable-content": 1,
                  alert: {
                    title: notification.title,
                    body: notification.body,
                  },
                  category: "NEW_POST_CATEGORY",
                },
              },
              headers: {
                "apns-priority": "10",
                "apns-push-type": "alert",
                "apns-expiration": "0",
                "apns-topic": "com.canlipazar.app",
              },
              fcmOptions: {
                analyticsLabel: "new_post_notification",
              },
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(iosMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;
          } catch (error: any) {
            console.error(`❌ iOS Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      // Android kullanıcılarına bildirim gönder
      if (androidTokens.length > 0) {
        console.log(`✅ ${androidTokens.length} Android kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < androidTokens.length; i += batchSize) {
          const batchTokens = androidTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const androidMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            // KRİTİK: Android için notification field'ı kaldırıldı (çift bildirim sorunu çözümü)
            // notification: notification,
            data: {
              type: String(data.type || ''),
              feedId: String(data.feedId || ''),
              postOwnerId: String(data.postOwnerId || ''),
              // KRİTİK: App background handler için title ve body ekle
              title: String(notification.title || ''),
              body: String(notification.body || ''),
            },
            // Android için özel ayarlar
            android: {
              priority: "high" as const,
              // KRİTİK: notification object KALDIRILDI
              // Böylece Android System otomatik bildirim göstermez (boş bildirim sorunu çözümü)
              // App background handler (data-only message) yerel bildirim gösterecek (çift bildirim çözümü)
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(androidMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;
          } catch (error) {
            console.error(`❌ Android Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      console.log(`✅ Toplam: ${totalSuccessCount} başarılı, ${totalFailureCount} başarısız`);

      return null;
    } catch (error) {
      console.error(`❌ Yeni yem ilanı bildirimi gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Yeni İlan Bildirimi - listings/{listingId} → onCreate
 * Kullanıcı isteği: listings collection'ına yeni ilan eklendiğinde tüm kullanıcılara bildirim gönder
 */
export const onNewListingCreated = functions.firestore
  .document("listings/{listingId}")
  .onCreate(async (snap, context) => {
    const listingData = snap.data();
    const listingId = context.params.listingId;

    console.log(`🆕 Yeni ilan eklendi (listings): ${listingId}`);
    console.log(`⚠️ BU FONKSIYON DEVRE DISI BIRAKILDI - onNewAnimalPostCreated kullaniliyor`);
    return null;

    /*
    console.log(`İlan sahibi: ${listingData.uid || listingData.userId || "Bilinmiyor"}`);

    try {
      console.log(`✅ Yeni ilan bildirimi gönderiliyor...`);

      // KRİTİK: İlan sahibi ID'sini önce al
      const postOwnerId = listingData.uid || listingData.userId || "";
      console.log(`📋 İlan sahibi: ${postOwnerId}`);

      // Tüm kullanıcıları al (batch işleme ile - daha güvenilir)
      const iosTokens: string[] = [];
      const androidTokens: string[] = [];
      let iosUserCount = 0;
      let androidUserCount = 0;
      let totalUsersChecked = 0;
      let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

      // Batch işleme ile tüm kullanıcıları al
      do {
        let query: admin.firestore.Query = admin.firestore().collection("users");

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(1000).get();
        totalUsersChecked += usersSnapshot.size;

        if (usersSnapshot.empty) {
          break;
        }

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const fcmToken = userData.fcmToken;
          const userId = doc.id;
          const platform = userData.platform;

          // Token kontrolü - boş string ve null kontrolü
          if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
            return; // Geçersiz token
          }

          // Token validation
          const trimmedToken = fcmToken.trim();
          if (!_isValidFCMToken(trimmedToken)) {
            return; // Geçersiz token formatı
          }

          // KRİTİK: Platform kontrolü - sadece "ios" veya "android" kabul et
          // "unknown" platform'a sahip kullanıcılara bildirim gönderme
          if (!platform || platform === 'unknown' || platform.trim() === '') {
            return; // Platform bilgisi geçersiz/unknown
          }

          const normalizedPlatform = platform.toLowerCase().trim();
          if (normalizedPlatform !== 'ios' && normalizedPlatform !== 'android') {
            return; // Geçersiz platform
          }

          // Platform bilgisi kontrolü
          if (normalizedPlatform === 'ios') {
            iosTokens.push(trimmedToken);
            iosUserCount++;
          } else if (normalizedPlatform === 'android') {
            androidTokens.push(trimmedToken);
            androidUserCount++;
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null);

      console.log(`📱 Toplam ${totalUsersChecked} kullanıcı kontrol edildi`);
      console.log(`📊 Platform dağılımı: iOS=${iosUserCount}, Android=${androidUserCount}`);
      console.log(`📊 Toplam token: ${iosTokens.length + androidTokens.length}`);

      if (iosTokens.length === 0 && androidTokens.length === 0) {
        console.log("⚠️ Bildirim gönderilecek kullanıcı bulunamadı");
        console.log("⚠️ Olası nedenler:");
        console.log("   - Tüm token'lar geçersiz");
        console.log("   - Tüm kullanıcıların platform bilgisi 'unknown'");
        return null;
      }

      // Bildirim payload'ı
      // KRİTİK: Kullanıcı isteği - Title: "Yeni İlan Eklendi", Body: "Göz At"
      const notification = {
        title: "Yeni İlan Eklendi", // Kullanıcı isteği: "Yeni İlan Eklendi"
        body: "Göz At", // Kullanıcı isteği: "Göz At"
      };

      const data = {
        type: "listing",
        listingId: listingId,
      };

      // Bildirimleri gönder (iOS ve Android ayrı ayrı)
      const batchSize = 500;
      let totalSuccessCount = 0;
      let totalFailureCount = 0;

      // iOS kullanıcılarına bildirim gönder
      if (iosTokens.length > 0) {
        console.log(`✅ ${iosTokens.length} iOS kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < iosTokens.length; i += batchSize) {
          const batchTokens = iosTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const iosMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            notification: notification,
            data: data,
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  "content-available": 1,
                  "mutable-content": 1,
                  alert: {
                    title: notification.title,
                    body: notification.body,
                  },
                  category: "NEW_LISTING_CATEGORY",
                },
              },
              headers: {
                "apns-priority": "10",
                "apns-push-type": "alert",
                "apns-expiration": "0",
                "apns-topic": "com.canlipazar.app",
              },
              fcmOptions: {
                analyticsLabel: "new_listing_notification",
              },
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(iosMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            console.log(
              `📤 iOS Batch ${Math.floor(i / batchSize) + 1}: ` +
              `${response.successCount} başarılı, ` +
              `${response.failureCount} başarısız`
            );

            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  const errorCode = resp.error?.code || 'UNKNOWN';
                  console.log(
                    `❌ iOS Token hatası: ${validTokens[idx].substring(0, 20)}... - ` +
                    `Code: ${errorCode}`
                  );

                  // Geçersiz token'ı Firestore'dan sil
                  if (errorCode === 'messaging/invalid-registration-token' ||
                    errorCode === 'messaging/registration-token-not-registered') {
                    admin.firestore().collection('users')
                      .where('fcmToken', '==', validTokens[idx])
                      .limit(1)
                      .get()
                      .then(snapshot => {
                        if (!snapshot.empty) {
                          snapshot.docs[0].ref.update({
                            fcmToken: admin.firestore.FieldValue.delete(),
                          });
                          console.log(`✅ Geçersiz token Firestore'dan silindi`);
                        }
                      })
                      .catch(err => console.error(`❌ Token silme hatası: ${err}`));
                  }
                }
              });
            }
          } catch (error: any) {
            console.error(`❌ iOS Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      // Android kullanıcılarına bildirim gönder
      if (androidTokens.length > 0) {
        console.log(`✅ ${androidTokens.length} Android kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < androidTokens.length; i += batchSize) {
          const batchTokens = androidTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const androidMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            notification: notification,
            data: data,
            android: {
              priority: "high" as const,
              notification: {
                channelId: "listings_channel",
                sound: "default",
                priority: "high" as const,
                notificationCount: 1,
              },
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(androidMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            console.log(
              `📤 Android Batch ${Math.floor(i / batchSize) + 1}: ` +
              `${response.successCount} başarılı, ` +
              `${response.failureCount} başarısız`
            );

            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  console.log(
                    `❌ Android Token hatası: ${batchTokens[idx].substring(0, 20)}... - ` +
                    `${resp.error?.message || "Bilinmeyen hata"}`
                  );
                }
              });
            }
          } catch (error) {
            console.error(`❌ Android Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      console.log(
        `✅ Toplam: ${totalSuccessCount} başarılı (iOS: ${iosUserCount}, Android: ${androidUserCount}), ${totalFailureCount} başarısız`
      );

      return null;
    }
    */
  });

/**
 * Yeni Post (Eşya) ilanı eklendiğinde tüm kullanıcılara bildirim gönder
 */
export const onNewPostCreated = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const postData = snap.data();
    const postId = context.params.postId;

    console.log(`🆕 Yeni eşya ilanı eklendi: ${postId}`);
    console.log(`İlan sahibi: ${postData.uid || "Bilinmiyor"}`);

    try {
      console.log(`✅ Yeni eşya ilanı bildirimi gönderiliyor...`);

      // İlan sahibine bildirim gönderme (kendi ilanı için bildirim almasın)
      const postOwnerId = postData.uid || "";

      // Tüm kullanıcıları al (batch işleme ile - daha güvenilir)
      const iosTokens: string[] = [];
      const androidTokens: string[] = [];
      let iosUserCount = 0;
      let androidUserCount = 0;
      let totalUsersChecked = 0;
      let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

      // Batch işleme ile tüm kullanıcıları al
      do {
        let query: admin.firestore.Query = admin.firestore().collection("users");

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(1000).get();
        totalUsersChecked += usersSnapshot.size;

        if (usersSnapshot.empty) {
          break;
        }

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const fcmToken = userData.fcmToken;
          const userId = doc.id;
          const platform = userData.platform;

          // Token kontrolü - boş string ve null kontrolü
          if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
            return; // Geçersiz token
          }

          // Token validation
          const trimmedToken = fcmToken.trim();
          if (!_isValidFCMToken(trimmedToken)) {
            return; // Geçersiz token formatı
          }

          // KRİTİK: Kullanıcı isteği - TÜM kullanıcılara bildirim gönder
          // İlan sahibine de bildirim gönderilecek (kullanıcı isteği)
          // postNotificationsEnabled kontrolü kaldırıldı (kullanıcı isteği)

          // Platform bilgisi kontrolü
          if (platform === 'ios' || platform === 'iOS' || !platform || platform === 'unknown') {
            iosTokens.push(trimmedToken);
            iosUserCount++;
          }

          if (platform === 'android' || platform === 'Android') {
            androidTokens.push(trimmedToken);
            androidUserCount++;
          } else if (!platform || platform === 'unknown') {
            // Platform bilgisi yoksa/unknown ise Android'e de gönder (geriye dönük uyumluluk)
            androidTokens.push(trimmedToken);
            androidUserCount++;
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null);

      console.log(`📱 Toplam ${totalUsersChecked} kullanıcı kontrol edildi`);
      console.log(`📊 Platform dağılımı: iOS=${iosUserCount}, Android=${androidUserCount}`);
      console.log(`📊 Toplam token: ${iosTokens.length + androidTokens.length}`);

      if (iosTokens.length === 0 && androidTokens.length === 0) {
        console.log("⚠️ Bildirim gönderilecek kullanıcı bulunamadı");
        return null;
      }

      // Bildirim payload'ı
      // KRİTİK: Kullanıcı isteği - Title: "Yeni İlan Eklendi", Body: "Göz At"
      const notification = {
        title: "Yeni İlan Eklendi", // Kullanıcı isteği: "Yeni İlan Eklendi"
        body: "Göz At", // Kullanıcı isteği: "Göz At"
      };

      const data = {
        type: "new_post",
        postId: postId,
        postOwnerId: postOwnerId,
      };

      // Bildirimleri gönder (iOS ve Android ayrı ayrı)
      const batchSize = 500;
      let totalSuccessCount = 0;
      let totalFailureCount = 0;

      // iOS kullanıcılarına bildirim gönder
      if (iosTokens.length > 0) {
        console.log(`✅ ${iosTokens.length} iOS kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < iosTokens.length; i += batchSize) {
          const batchTokens = iosTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const iosMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            // KRİTİK: iOS için notification field'ı kaldırıldı (çift bildirim/gönderim sorunu çözümü)
            // Sadece apns payload kullanılacak
            // notification: notification,
            data: {
              type: String(data.type || ''),
              postId: String(data.postId || ''),
              postOwnerId: String(data.postOwnerId || ''),
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  "content-available": 1,
                  "mutable-content": 1,
                  alert: {
                    title: notification.title,
                    body: notification.body,
                  },
                  category: "NEW_POST_CATEGORY",
                },
              },
              headers: {
                "apns-priority": "10",
                "apns-push-type": "alert",
                "apns-expiration": "0",
                "apns-topic": "com.canlipazar.app",
              },
              fcmOptions: {
                analyticsLabel: "new_post_notification",
              },
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(iosMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;
          } catch (error: any) {
            console.error(`❌ iOS Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      // Android kullanıcılarına bildirim gönder
      if (androidTokens.length > 0) {
        console.log(`✅ ${androidTokens.length} Android kullanıcıya bildirim gönderiliyor`);

        for (let i = 0; i < androidTokens.length; i += batchSize) {
          const batchTokens = androidTokens.slice(i, i + batchSize);
          const validTokens = batchTokens.filter(token => _isValidFCMToken(token));

          if (validTokens.length === 0) continue;

          const androidMessage: admin.messaging.MulticastMessage = {
            tokens: validTokens,
            // KRİTİK: Android için notification field'ı kaldırıldı (çift bildirim sorunu çözümü)
            // notification: notification,
            data: {
              type: String(data.type || ''),
              postId: String(data.postId || ''),
              postOwnerId: String(data.postOwnerId || ''),
              // KRİTİK: App background handler için title ve body ekle
              title: String(notification.title || ''),
              body: String(notification.body || ''),
            },
            // Android için özel ayarlar
            android: {
              priority: "high" as const,
              // KRİTİK: notification object KALDIRILDI
              // Böylece Android System otomatik bildirim göstermez (boş bildirim sorunu çözümü)
              // App background handler (data-only message) yerel bildirim gösterecek (çift bildirim çözümü)
            },
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(androidMessage);
            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;
          } catch (error) {
            console.error(`❌ Android Batch gönderme hatası:`, error);
            totalFailureCount += validTokens.length;
          }
        }
      }

      console.log(`✅ Toplam: ${totalSuccessCount} başarılı, ${totalFailureCount} başarısız`);

      return null;
    } catch (error) {
      console.error(`❌ Yeni eşya ilanı bildirimi gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Günlük otomatik bildirimler - Yeni ilanlar ve uygun fiyatlı ilanlar
 * Her 3 saatte bir çalışır (Europe/Istanbul timezone)
 */
export const sendDailyNotifications = functions.pubsub
  .schedule("0 9,12,15,18,21 * * *") // Her gün 5 kez: 09:00, 12:00, 15:00, 18:00, 21:00 (cron format)
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    console.log("📢 Günlük otomatik bildirimler başlatılıyor (her gün 5 kez)...");

    try {
      // 5 farklı bildirim mesajı
      const notificationMessages = [
        {
          title: "CanlıPazar 🐄",
          body: "YENİ İLANLAR EKLENDİ GÖZ AT"
        },
        {
          title: "CanlıPazar 🐄",
          body: "UYGUN FİYATLI HAYVANLAR VAR Bİ BAK İSTERSEN"
        },
        {
          title: "CanlıPazar 🐄",
          body: "YAKININIZDAN İLANLAR EKLENDİ"
        },
        {
          title: "CanlıPazar 🐄",
          body: "SİZDE İLAN VERİN BİNLERCE MÜŞTERİYE ULAŞSIN"
        },
        {
          title: "CanlıPazar 🐄",
          body: "YENİ İLANLAR EKLENDİ GÖZ AT" // 5. bildirim için tekrar ilk mesaj
        }
      ];

      // Rastgele bir mesaj seç (günün saatine göre)
      const currentHour = new Date().getHours();
      let messageIndex = 0;

      if (currentHour === 9) messageIndex = 0;      // Sabah: YENİ İLANLAR
      else if (currentHour === 12) messageIndex = 1; // Öğle: UYGUN FİYATLI
      else if (currentHour === 15) messageIndex = 2; // Öğleden sonra: YAKININIZDAN
      else if (currentHour === 18) messageIndex = 3; // Akşam: İLAN VERİN
      else if (currentHour === 21) messageIndex = 4; // Gece: YENİ İLANLAR (tekrar)
      else messageIndex = Math.floor(Math.random() * notificationMessages.length); // Fallback: rastgele

      const selectedMessage = notificationMessages[messageIndex];
      console.log(`📨 Seçilen mesaj (${currentHour}:00): "${selectedMessage.body}"`);

      // Tüm kullanıcıları al (FCM token'ı olanlar) - batch olarak
      let allTokens: string[] = [];
      let lastDoc: admin.firestore.DocumentSnapshot | null = null;
      let totalUsers = 0;

      do {
        let query: admin.firestore.Query = admin.firestore().collection('users');

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(500).get();
        totalUsers += usersSnapshot.size;

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const token = userData?.fcmToken;

          if (token && typeof token === 'string' && token.trim().length > 50) {
            allTokens.push(token.trim());
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null && allTokens.length < 10000); // Maksimum 10,000 token

      console.log(`📊 Toplam ${totalUsers} kullanıcı kontrol edildi, ${allTokens.length} geçerli token bulundu`);

      if (allTokens.length === 0) {
        console.log("⚠️ FCM token'ı olan kullanıcı bulunamadı");
        return null;
      }

      const data = {
        type: "daily_notification",
        messageType: messageIndex.toString(),
      };

      // Bildirimleri gönder (batch - 500 mesaj'a kadar, otomatik parça parça)
      const batchSize = 500;
      let successCount = 0;
      let failureCount = 0;

      console.log(`📱 ${allTokens.length} kullanıcıya bildirim gönderilecek (${Math.ceil(allTokens.length / batchSize)} batch - otomatik parça parça)`);

      for (let i = 0; i < allTokens.length; i += batchSize) {
        const batchTokens = allTokens.slice(i, i + batchSize);

        // Geçerli token'ları filtrele
        const validTokens = batchTokens.filter(token =>
          token &&
          typeof token === 'string' &&
          token.trim().length > 50
        );

        if (validTokens.length === 0) {
          console.log(`⚠️ Batch ${Math.floor(i / batchSize) + 1}: Geçerli token yok, atlanıyor`);
          failureCount += batchTokens.length;
          continue;
        }

        const batchMessages = validTokens.map((token) => ({
          token: token.trim(),
          notification: {
            title: selectedMessage.title,
            body: selectedMessage.body,
          },
          data: {
            type: "daily_notification",
            messageType: messageIndex.toString(),
          },
          android: {
            priority: "high" as const,
            notification: {
              channelId: "daily_notifications_channel",
              sound: "default",
              priority: "high" as const,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                "content-available": 1 as any,
                "mutable-content": 1 as any,
                alert: {
                  title: selectedMessage.title,
                  body: selectedMessage.body,
                },
                category: "DAILY_NOTIFICATION_CATEGORY",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-push-type": "alert",
            },
          },
        }));

        try {
          console.log(`📤 Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(allTokens.length / batchSize)} gönderiliyor: ${validTokens.length} geçerli token`);
          const response = await admin.messaging().sendAll(batchMessages);
          successCount += response.successCount;
          failureCount += (response.failureCount + (batchTokens.length - validTokens.length));

          console.log(
            `✅ Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(allTokens.length / batchSize)} tamamlandı: ` +
            `${response.successCount} başarılı, ${response.failureCount} başarısız (${batchTokens.length - validTokens.length} geçersiz token)`
          );

          // Batch'ler arasında kısa bir bekleme (rate limiting için)
          if (i + batchSize < allTokens.length) {
            await new Promise(resolve => setTimeout(resolve, 300)); // 300ms bekleme
          }
        } catch (error: any) {
          console.error(`❌ Batch ${Math.floor(i / batchSize) + 1} gönderme hatası:`, error.code || error.message || error);
          failureCount += batchMessages.length;
        }
      }

      console.log(
        `✅ Günlük bildirimler tamamlandı: ` +
        `${successCount} başarılı, ${failureCount} başarısız ` +
        `(Mesaj: "${selectedMessage.body}")`
      );

      return null;
    } catch (error) {
      console.error(`❌ Günlük bildirim gönderme hatası:`, error);
      return null;
    }
  });

/**
 * Test bildirimi gönder (HTTP endpoint)
 * APNs entegrasyonunu test etmek için kullanılır
 * Kullanım: POST https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP
 * Body: { "userId": "optional_user_id", "message": "TEST BİLDİRİMİ GELDİ Mİ?" }
 * veya GET: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendTestNotificationHTTP?message=TEST
 */
export const sendTestNotificationHTTP = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // Kullanıcı ID'sini al (opsiyonel - eğer gönderilmezse ilk bulunan kullanıcıya gönder)
    const userId = req.body?.userId || req.query?.userId || null;
    const testMessage = req.body?.message || req.query?.message || "TEST BİLDİRİMİ GELDİ Mİ?";

    let tokens: string[] = [];

    if (userId) {
      // Belirli bir kullanıcıya gönder
      console.log(`🔍 Kullanıcı ID ile arama: ${userId}`);
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        const token = userData?.fcmToken;
        console.log(`📱 Kullanıcı bulundu: ${userId}, token type: ${typeof token}, token length: ${token?.length || 0}`);
        if (token && typeof token === 'string' && token.trim().length > 0) {
          tokens.push(token);
          console.log(`✅ Token bulundu ve eklendi: ${token.substring(0, 20)}...`);
        } else {
          console.log(`⚠️ Token geçersiz veya boş: ${userId}`);
          res.status(400).json({
            success: false,
            error: `Kullanıcının FCM token'ı bulunamadı veya geçersiz. Token type: ${typeof token}, length: ${token?.length || 0}`
          });
          return;
        }
      } else {
        console.log(`❌ Kullanıcı Firestore'da bulunamadı: ${userId}`);
        // Alternatif: Authentication'dan kontrol et
        try {
          const authUser = await admin.auth().getUser(userId);
          console.log(`✅ Kullanıcı Authentication'da bulundu: ${authUser.uid}, email: ${authUser.email}`);
          res.status(404).json({
            success: false,
            error: `Kullanıcı Firestore'da bulunamadı (Authentication'da var: ${authUser.email || 'email yok'}). Lütfen uygulamayı açıp profil oluşturun.`
          });
        } catch (authError) {
          console.log(`❌ Kullanıcı Authentication'da da bulunamadı: ${userId}`);
          res.status(404).json({ success: false, error: "Kullanıcı bulunamadı (ne Firestore'da ne Authentication'da)" });
        }
        return;
      }
    } else {
      // TÜM kullanıcılara gönder (Android ve iOS)
      console.log('📤 Tüm kullanıcılara bildirim gönderiliyor...');

      // Tüm kullanıcıları al (batch olarak)
      let lastDoc: admin.firestore.DocumentSnapshot | null = null;
      let totalUsers = 0;
      let totalTokens = 0;

      do {
        let query: admin.firestore.Query = admin.firestore().collection('users');

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(500).get(); // Her seferinde 500 kullanıcı

        console.log(`📊 ${usersSnapshot.size} kullanıcı kontrol ediliyor...`);
        totalUsers += usersSnapshot.size;

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const token = userData?.fcmToken;

          // Token kontrolü - daha detaylı
          if (!token) {
            if (totalTokens < 3) {
              console.log(`⚠️ Token yok: ${doc.id} - fcmToken field: ${userData?.fcmToken || 'undefined'}`);
            }
            return;
          }

          if (typeof token !== 'string') {
            if (totalTokens < 3) {
              console.log(`⚠️ Token string değil: ${doc.id} - type: ${typeof token}, value: ${token}`);
            }
            return;
          }

          const trimmedToken = token.trim();
          if (trimmedToken.length === 0) {
            if (totalTokens < 3) {
              console.log(`⚠️ Token boş string: ${doc.id}`);
            }
            return;
          }

          if (trimmedToken.length < 50) {
            if (totalTokens < 3) {
              console.log(`⚠️ Token çok kısa: ${doc.id} - length: ${trimmedToken.length}, value: ${trimmedToken.substring(0, 30)}`);
            }
            return;
          }

          // Geçerli token
          tokens.push(trimmedToken);
          totalTokens++;
          if (totalTokens <= 5) {
            console.log(`✅ Token bulundu: ${doc.id} - ${trimmedToken.substring(0, 30)}... (length: ${trimmedToken.length})`);
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null && tokens.length < 10000); // Maksimum 10,000 token (güvenlik için)

      console.log(`📊 Toplam ${totalUsers} kullanıcı kontrol edildi, ${totalTokens} geçerli token bulundu`);
    }

    if (tokens.length === 0) {
      res.status(400).json({ success: false, error: "FCM token bulunamadı" });
      return;
    }

    // Test bildirimi gönder (batch olarak - maksimum 500 mesaj, otomatik parça parça)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    console.log(`📤 ${tokens.length} kullanıcıya bildirim gönderilecek (${Math.ceil(tokens.length / batchSize)} batch - otomatik parça parça)`);

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);

      // Geçerli token'ları filtrele (boş, null, undefined olmayanlar)
      const validTokens = batchTokens.filter(token =>
        token &&
        typeof token === 'string' &&
        token.trim().length > 0 &&
        token.length > 50 // FCM token'lar genellikle 150+ karakter
      );

      if (validTokens.length === 0) {
        console.log(`⚠️ Batch ${Math.floor(i / batchSize) + 1}: Geçerli token yok, atlanıyor`);
        failureCount += batchTokens.length;
        continue;
      }

      const batchMessages = validTokens.map((token) => ({
        token: token.trim(),
        notification: {
          title: "CanlıPazar",
          body: testMessage,
        },
        data: {
          type: "announcement",
          message: testMessage,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1 as any,
              "mutable-content": 1 as any,
              alert: {
                title: "CanlıPazar",
                body: testMessage,
              },
              category: "ANNOUNCEMENT_CATEGORY",
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "messages_channel",
            sound: "default",
            priority: "high" as const,
            notificationCount: 1,
          },
        },
      }));

      try {
        console.log(`📤 Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(tokens.length / batchSize)} gönderiliyor: ${validTokens.length} geçerli token`);
        const response = await admin.messaging().sendAll(batchMessages);
        successCount += response.successCount;
        failureCount += (response.failureCount + (batchTokens.length - validTokens.length));

        // Başarısız olan token'ları detaylı logla (ilk 5 hatayı)
        if (response.responses) {
          let errorCount = 0;
          response.responses.forEach((resp, idx) => {
            if (!resp.success && errorCount < 5) {
              const errorCode = resp.error?.code || 'UNKNOWN';
              const errorMessage = resp.error?.message || 'Bilinmeyen hata';
              console.log(`❌ Token başarısız (batch ${Math.floor(i / batchSize) + 1}, index ${idx}): [${errorCode}] ${errorMessage}`);
              errorCount++;
            }
          });
        }

        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(tokens.length / batchSize)} tamamlandı: ${response.successCount} başarılı, ${response.failureCount} başarısız (${batchTokens.length - validTokens.length} geçersiz token)`);

        // Batch'ler arasında kısa bir bekleme (rate limiting için)
        if (i + batchSize < tokens.length) {
          await new Promise(resolve => setTimeout(resolve, 300)); // 300ms bekleme
        }
      } catch (error: any) {
        console.error(`❌ Batch ${Math.floor(i / batchSize) + 1} gönderme hatası:`, error.code || error.message || error);
        failureCount += batchMessages.length;
      }
    }

    console.log(`✅ Test bildirimi tamamlandı: ${successCount} başarılı, ${failureCount} başarısız`);

    res.status(200).json({
      success: true,
      sent: successCount,
      failed: failureCount,
      total: tokens.length,
      message: `${successCount} kullanıcıya test bildirimi gönderildi (${failureCount} başarısız)`,
    });
  } catch (error: any) {
    console.error("❌ Test bildirimi gönderme hatası:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Geçersiz token'ı Firestore'dan sil
 */
async function _removeInvalidToken(token: string): Promise<void> {
  try {
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('fcmToken', '==', token)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      const userId = usersSnapshot.docs[0].id;
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      console.log(`✅ Geçersiz token silindi: ${userId}`);
    }
  } catch (error) {
    console.error(`❌ Token silme hatası: ${error}`);
  }
}

/**
 * iOS kullanıcılarına test bildirimi gönder
 * HTTP trigger ile çağrılır: https://[region]-[project-id].cloudfunctions.net/sendTestNotificationToiOS
 * Sadece platform: "ios" olan kullanıcılara gönderir
 */
export const sendTestNotificationToiOS = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const testMessage = req.body?.message || req.query?.message || "🧪 iOS Test Bildirimi - Bildirim geldi mi?";

    console.log('🍎 iOS kullanıcılarına test bildirimi gönderiliyor...');

    // iOS kullanıcılarını bul (platform: "ios" olanlar VEYA platform alanı olmayan ama token'ı olanlar)
    let tokens: string[] = [];
    let lastDoc: admin.firestore.DocumentSnapshot | null = null;
    let totalUsers = 0;
    let totalTokens = 0;

    // Önce platform: "ios" olanları bul
    do {
      let query: admin.firestore.Query = admin.firestore()
        .collection('users')
        .where('platform', '==', 'ios');

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const usersSnapshot = await query.limit(500).get();

      console.log(`📊 ${usersSnapshot.size} iOS kullanıcı kontrol ediliyor...`);
      totalUsers += usersSnapshot.size;

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const token = userData?.fcmToken;

        // Token kontrolü
        if (!token || typeof token !== 'string') {
          return;
        }

        const trimmedToken = token.trim();
        if (trimmedToken.length === 0 || trimmedToken.length < 50) {
          return;
        }

        // Geçerli token
        tokens.push(trimmedToken);
        totalTokens++;
        if (totalTokens <= 5) {
          console.log(`✅ iOS Token bulundu: ${doc.id} - ${trimmedToken.substring(0, 30)}...`);
        }
      });

      if (usersSnapshot.size > 0) {
        lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
      } else {
        lastDoc = null;
      }
    } while (lastDoc != null && tokens.length < 10000);

    // Eğer platform: "ios" olan kullanıcı bulunamadıysa veya az bulunduysa, 
    // "unknown" platform kullanıcılarını da dahil et (çoğu muhtemelen iOS)
    if (tokens.length < 10) {
      console.log('⚠️ platform: "ios" olan kullanıcı az bulundu, "unknown" platform kullanıcıları da dahil ediliyor...');
      lastDoc = null;

      do {
        let query: admin.firestore.Query = admin.firestore()
          .collection('users')
          .where('fcmToken', '!=', null);

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(500).get();

        console.log(`📊 ${usersSnapshot.size} kullanıcı kontrol ediliyor (unknown platform dahil)...`);
        totalUsers += usersSnapshot.size;

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const token = userData?.fcmToken;
          const platform = userData?.platform;

          // Token kontrolü
          if (!token || typeof token !== 'string') {
            return;
          }

          const trimmedToken = token.trim();
          if (trimmedToken.length === 0 || trimmedToken.length < 50) {
            return;
          }

          // iOS veya unknown platform kullanıcılarını dahil et
          // Android kullanıcılarını hariç tut
          if (platform === 'ios' || platform === 'unknown' || !platform) {
            // Token zaten eklenmemişse ekle
            if (!tokens.includes(trimmedToken)) {
              tokens.push(trimmedToken);
              totalTokens++;
              if (totalTokens <= 5) {
                console.log(`✅ Token bulundu: ${doc.id} - platform: ${platform || 'undefined'} - ${trimmedToken.substring(0, 30)}...`);
              }
            }
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null && tokens.length < 1000); // Daha fazla kullanıcı için limit artırıldı
    }

    console.log(`📊 Toplam ${totalUsers} kullanıcı kontrol edildi, ${totalTokens} geçerli token bulundu`);

    if (tokens.length === 0) {
      res.status(400).json({
        success: false,
        error: "iOS kullanıcısı bulunamadı veya FCM token'ı yok",
        totalUsers: totalUsers,
        totalTokens: totalTokens
      });
      return;
    }

    // iOS test bildirimi gönder (batch olarak)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    console.log(`📤 ${tokens.length} iOS kullanıcıya bildirim gönderilecek (${Math.ceil(tokens.length / batchSize)} batch)`);

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);

      const validTokens = batchTokens.filter(token =>
        token &&
        typeof token === 'string' &&
        token.trim().length > 0 &&
        token.length > 50
      );

      if (validTokens.length === 0) {
        console.log(`⚠️ Batch ${Math.floor(i / batchSize) + 1}: Geçerli token yok, atlanıyor`);
        failureCount += batchTokens.length;
        continue;
      }

      const batchMessages = validTokens.map((token) => ({
        token: token.trim(),
        notification: {
          title: "🍎 CanlıPazar iOS Test",
          body: testMessage,
        },
        data: {
          type: "test",
          platform: "ios",
          message: testMessage,
          timestamp: new Date().toISOString(),
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1 as any,
              "mutable-content": 1 as any,
              alert: {
                title: "CanlıPazar",
                body: testMessage,
              },
              category: "ANNOUNCEMENT_CATEGORY",
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
            "apns-expiration": "0",
            "apns-topic": "com.canlipazar.app",
          },
          fcmOptions: {
            analyticsLabel: "ios_announcement",
          },
        },
      }));

      try {
        console.log(`📤 Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(tokens.length / batchSize)} gönderiliyor: ${validTokens.length} iOS token`);
        const response = await admin.messaging().sendAll(batchMessages);
        successCount += response.successCount;
        failureCount += (response.failureCount + (batchTokens.length - validTokens.length));

        // Başarısız olan token'ları detaylı logla
        if (response.responses) {
          let errorCount = 0;
          response.responses.forEach((resp, idx) => {
            if (!resp.success && errorCount < 10) {
              const errorCode = resp.error?.code || 'UNKNOWN';
              const errorMessage = resp.error?.message || 'Bilinmeyen hata';
              console.log(`❌ Token başarısız (batch ${Math.floor(i / batchSize) + 1}, index ${idx}): [${errorCode}] ${errorMessage}`);

              // Geçersiz token'ları Firestore'dan sil
              if (errorCode === 'messaging/invalid-registration-token' ||
                errorCode === 'messaging/registration-token-not-registered') {
                console.log(`🗑️ Geçersiz token tespit edildi, Firestore'dan silinecek: ${validTokens[idx]?.substring(0, 20)}...`);
                // Token'ı Firestore'dan sil (async, blocking olmadan)
                _removeInvalidToken(validTokens[idx]).catch(err => {
                  console.error(`❌ Token silme hatası: ${err}`);
                });
              }
              errorCount++;
            }
          });
        }

        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1} tamamlandı: ${response.successCount} başarılı, ${response.failureCount} başarısız`);

        // Batch'ler arasında kısa bir bekleme
        if (i + batchSize < tokens.length) {
          await new Promise(resolve => setTimeout(resolve, 300));
        }
      } catch (error: any) {
        console.error(`❌ Batch ${Math.floor(i / batchSize) + 1} gönderme hatası:`, error.code || error.message || error);
        failureCount += batchMessages.length;
      }
    }

    console.log(`✅ iOS test bildirimi tamamlandı: ${successCount} başarılı, ${failureCount} başarısız`);

    res.status(200).json({
      success: true,
      platform: "ios",
      sent: successCount,
      failed: failureCount,
      total: tokens.length,
      totalUsers: totalUsers,
      message: `${successCount} iOS kullanıcıya test bildirimi gönderildi (${failureCount} başarısız)`,
    });
  } catch (error: any) {
    console.error("❌ iOS test bildirimi gönderme hatası:", error);
    res.status(500).json({
      success: false,
      error: error.message,
      platform: "ios"
    });
  }
});

/**
 * Android kullanıcılarına test bildirimi gönder
 * HTTP trigger ile çağrılır: https://[region]-[project-id].cloudfunctions.net/sendTestNotificationToAndroid
 * Sadece platform: "android" olan kullanıcılara gönderir
 */
export const sendTestNotificationToAndroid = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const testMessage = req.body?.message || req.query?.message || "🧪 Android Test Bildirimi - Bildirim geldi mi?";

    console.log('🤖 Android kullanıcılarına test bildirimi gönderiliyor...');

    // Android kullanıcılarını bul (platform: "android" olanlar VEYA platform alanı olmayan ama token'ı olanlar)
    let tokens: string[] = [];
    let lastDoc: admin.firestore.DocumentSnapshot | null = null;
    let totalUsers = 0;
    let totalTokens = 0;

    // Önce platform: "android" olanları bul
    do {
      let query: admin.firestore.Query = admin.firestore()
        .collection('users')
        .where('platform', '==', 'android');

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const usersSnapshot = await query.limit(500).get();

      console.log(`📊 ${usersSnapshot.size} Android kullanıcı kontrol ediliyor...`);
      totalUsers += usersSnapshot.size;

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const token = userData?.fcmToken;

        // Token kontrolü
        if (!token || typeof token !== 'string') {
          return;
        }

        const trimmedToken = token.trim();
        if (trimmedToken.length === 0 || trimmedToken.length < 50) {
          return;
        }

        // Geçerli token
        tokens.push(trimmedToken);
        totalTokens++;
        if (totalTokens <= 5) {
          console.log(`✅ Android Token bulundu: ${doc.id} - ${trimmedToken.substring(0, 30)}...`);
        }
      });

      if (usersSnapshot.size > 0) {
        lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
      } else {
        lastDoc = null;
      }
    } while (lastDoc != null && tokens.length < 10000);

    // Eğer platform: "android" olan kullanıcı bulunamadıysa, platform alanı olmayan ama token'ı olan tüm kullanıcıları kontrol et
    if (tokens.length === 0) {
      console.log('⚠️ platform: "android" olan kullanıcı bulunamadı, tüm kullanıcılar kontrol ediliyor...');
      lastDoc = null;

      do {
        let query: admin.firestore.Query = admin.firestore()
          .collection('users')
          .where('fcmToken', '!=', null);

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.limit(500).get();

        console.log(`📊 ${usersSnapshot.size} kullanıcı kontrol ediliyor (platform filtresi yok)...`);
        totalUsers += usersSnapshot.size;

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const token = userData?.fcmToken;
          const platform = userData?.platform;

          // iOS değilse Android olarak kabul et (platform belirtilmemişse)
          if (platform === 'ios') {
            return; // iOS kullanıcılarını atla
          }

          // Token kontrolü
          if (!token || typeof token !== 'string') {
            return;
          }

          const trimmedToken = token.trim();
          if (trimmedToken.length === 0 || trimmedToken.length < 50) {
            return;
          }

          // Geçerli token
          tokens.push(trimmedToken);
          totalTokens++;
          if (totalTokens <= 5) {
            console.log(`✅ Token bulundu: ${doc.id} - platform: ${platform || 'undefined'} - ${trimmedToken.substring(0, 30)}...`);
          }
        });

        if (usersSnapshot.size > 0) {
          lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
        } else {
          lastDoc = null;
        }
      } while (lastDoc != null && tokens.length < 100);
    }

    console.log(`📊 Toplam ${totalUsers} kullanıcı kontrol edildi, ${totalTokens} geçerli token bulundu`);

    if (tokens.length === 0) {
      res.status(400).json({
        success: false,
        error: "Android kullanıcısı bulunamadı veya FCM token'ı yok",
        totalUsers: totalUsers,
        totalTokens: totalTokens
      });
      return;
    }

    // Android test bildirimi gönder (batch olarak)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    console.log(`📤 ${tokens.length} Android kullanıcıya bildirim gönderilecek (${Math.ceil(tokens.length / batchSize)} batch)`);

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);

      const validTokens = batchTokens.filter(token =>
        token &&
        typeof token === 'string' &&
        token.trim().length > 0 &&
        token.length > 50
      );

      if (validTokens.length === 0) {
        console.log(`⚠️ Batch ${Math.floor(i / batchSize) + 1}: Geçerli token yok, atlanıyor`);
        failureCount += batchTokens.length;
        continue;
      }

      const batchMessages = validTokens.map((token) => ({
        token: token.trim(),
        notification: {
          title: "🤖 CanlıPazar Android",
          body: testMessage,
        },
        data: {
          type: "test",
          platform: "android",
          message: testMessage,
          timestamp: new Date().toISOString(),
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "messages_channel",
            sound: "default",
            priority: "high" as const,
            notificationCount: 1,
            title: "🤖 CanlıPazar Android",
            body: testMessage,
          },
        },
      }));

      try {
        console.log(`📤 Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(tokens.length / batchSize)} gönderiliyor: ${validTokens.length} Android token`);
        const response = await admin.messaging().sendAll(batchMessages);
        successCount += response.successCount;
        failureCount += (response.failureCount + (batchTokens.length - validTokens.length));

        // Başarısız olan token'ları detaylı logla
        if (response.responses) {
          let errorCount = 0;
          response.responses.forEach((resp, idx) => {
            if (!resp.success && errorCount < 10) {
              const errorCode = resp.error?.code || 'UNKNOWN';
              const errorMessage = resp.error?.message || 'Bilinmeyen hata';
              console.log(`❌ Token başarısız (batch ${Math.floor(i / batchSize) + 1}, index ${idx}): [${errorCode}] ${errorMessage}`);

              // Geçersiz token'ları Firestore'dan sil
              if (errorCode === 'messaging/invalid-registration-token' ||
                errorCode === 'messaging/registration-token-not-registered') {
                console.log(`🗑️ Geçersiz token tespit edildi, Firestore'dan silinecek: ${validTokens[idx]?.substring(0, 20)}...`);
                _removeInvalidToken(validTokens[idx]).catch(err => {
                  console.error(`❌ Token silme hatası: ${err}`);
                });
              }
              errorCount++;
            }
          });
        }

        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1} tamamlandı: ${response.successCount} başarılı, ${response.failureCount} başarısız`);

        // Batch'ler arasında kısa bir bekleme
        if (i + batchSize < tokens.length) {
          await new Promise(resolve => setTimeout(resolve, 300));
        }
      } catch (error: any) {
        console.error(`❌ Batch ${Math.floor(i / batchSize) + 1} gönderme hatası:`, error.code || error.message || error);
        failureCount += batchMessages.length;
      }
    }

    console.log(`✅ Android test bildirimi tamamlandı: ${successCount} başarılı, ${failureCount} başarısız`);

    res.status(200).json({
      success: true,
      platform: "android",
      sent: successCount,
      failed: failureCount,
      total: tokens.length,
      totalUsers: totalUsers,
      message: `${successCount} Android kullanıcıya test bildirimi gönderildi (${failureCount} başarısız)`,
    });
  } catch (error: any) {
    console.error("❌ Android test bildirimi gönderme hatası:", error);
    res.status(500).json({
      success: false,
      error: error.message,
      platform: "android"
    });
  }
});

/**
 * NOT: 30 GÜNDE OTOMATİK SİLME ÖZELLİĞİ KALDIRILDI
 * 
 * İlanlar artık otomatik olarak silinmeyecek.
 * Kullanıcılar istedikleri zaman manuel olarak silebilirler.
 * 
 * Eğer gelecekte otomatik silme özelliği eklenmek istenirse,
 * burada bir scheduled function oluşturulabilir, ancak şu an için
 * bu özellik devre dışı bırakılmıştır.
 * 
 * Örnek kod (KULLANILMAYACAK):
 * export const deleteOldPosts = functions.pubsub
 *   .schedule("0 0 * * *") // Her gün gece yarısı
 *   .timeZone("Europe/Istanbul")
 *   .onRun(async (context) => {
 *     const thirtyDaysAgo = new Date();
 *     thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
 *     // ... silme işlemi
 *   });
 */

/**
 * iOS kullanıcılarına ilan verme teşviki bildirimi gönder
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendPostEncouragementNotification
 */
export const sendPostEncouragementNotification = functions.https.onRequest(async (req, res) => {
  try {
    console.log('📢 iOS kullanıcılarına "İlan Ver" teşviki bildirimi gönderiliyor...');

    // iOS kullanıcılarının FCM token'larını al
    let usersSnapshot;

    try {
      // Önce platform='ios' olanları al
      usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('platform', '==', 'ios')
        .where('fcmToken', '!=', null)
        .get();

      console.log(`📱 Platform='ios' olan ${usersSnapshot.size} kullanıcı bulundu`);
    } catch (error) {
      // Platform field yoksa veya index yoksa, tüm kullanıcıları al
      console.log('⚠️  Platform field sorgusu başarısız, tüm kullanıcılar kontrol ediliyor...');
      usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('fcmToken', '!=', null)
        .limit(1000)
        .get();
    }

    if (usersSnapshot.empty) {
      console.log('⚠️  FCM token\'ı olan kullanıcı bulunamadı');
      res.status(200).json({
        success: false,
        message: 'FCM token\'ı olan kullanıcı bulunamadı',
        count: 0,
      });
      return;
    }

    // Token'ları topla - SADECE iOS kullanıcıları
    const tokens: string[] = [];
    let iosCount = 0;
    let androidCount = 0;
    let noPlatformCount = 0;

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const platform = userData.platform;

      // Platform kontrolü - SADECE iOS kullanıcıları
      if (platform && platform !== 'ios') {
        if (platform === 'android') {
          androidCount++;
        }
        return; // iOS değilse atla
      }

      // Platform belirtilmemişse de atla (iOS'a göndermeyelim)
      if (!platform) {
        noPlatformCount++;
        return; // Platform bilgisi yoksa atla
      }

      // iOS kullanıcısı ve geçerli token varsa ekle
      if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length > 0) {
        tokens.push(fcmToken.trim());
        iosCount++;
      }
    });

    console.log(`📊 Platform dağılımı: iOS=${iosCount}, Android=${androidCount}, Platform bilgisi yok=${noPlatformCount}`);

    if (tokens.length === 0) {
      console.log('⚠️  Geçerli FCM token bulunamadı');
      res.status(200).json({
        success: false,
        message: 'Geçerli FCM token bulunamadı',
        count: 0,
      });
      return;
    }

    console.log(`📤 ${tokens.length} kullanıcıya bildirim gönderiliyor...`);

    // Bildirim mesajı
    const notification = {
      title: 'CanlıPazar',
      body: 'Herkes Telefon Başındayken İlan Ver İlanın Binlerce Kullanıcıya Ulaşsın',
    };

    // Bildirimleri gönder (batch olarak)
    const batchSize = 500; // FCM batch limit
    let successCount = 0;
    let failureCount = 0;

    console.log('📤 Bildirimler gönderiliyor...');

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);

      // Geçerli token'ları filtrele
      const validTokens = batchTokens.filter(token =>
        token &&
        typeof token === 'string' &&
        token.trim().length > 50
      );

      if (validTokens.length === 0) {
        console.log(`⚠️ Batch ${Math.floor(i / batchSize) + 1}: Geçerli token yok, atlanıyor`);
        failureCount += batchTokens.length;
        continue;
      }

      // Multicast message oluştur (sendEachForMulticast için)
      const multicastMessage: admin.messaging.MulticastMessage = {
        tokens: validTokens.map(token => token.trim()),
        notification: notification,
        data: {
          type: 'post_encouragement',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          timestamp: new Date().toISOString(),
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1 as any, // iOS terminated state için kritik
              'mutable-content': 1 as any, // iOS için mutable content
              alert: {
                title: notification.title,
                body: notification.body,
              },
              category: 'POST_ENCOURAGEMENT_CATEGORY',
            },
          },
          headers: {
            'apns-priority': '10', // Yüksek öncelik
            'apns-push-type': 'alert', // Alert tipi bildirim
            'apns-expiration': '0', // Hemen gönder
            'apns-topic': 'com.canlipazar.app', // iOS bundle ID
          },
          fcmOptions: {
            analyticsLabel: 'post_encouragement_notification',
          },
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'default_channel',
            sound: 'default',
            priority: 'high' as const,
          },
        },
      };

      try {
        // sendEachForMulticast kullan (diğer başarılı fonksiyonlarda kullanılan metod)
        const response = await admin.messaging().sendEachForMulticast(multicastMessage);
        successCount += response.successCount;
        failureCount += response.failureCount;

        // Başarısız olanları detaylı logla
        if (response.responses) {
          let errorCount = 0;
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              errorCount++;
              if (errorCount <= 5) { // İlk 5 hatayı logla
                console.error(`❌ Token ${idx} hatası:`, resp.error?.code || 'Bilinmeyen kod', resp.error?.message || 'Bilinmeyen hata');
              }
            }
          });
          if (errorCount > 5) {
            console.error(`❌ Toplam ${errorCount} token hatası var (sadece ilk 5 gösterildi)`);
          }
        }

        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1}: ${response.successCount} başarılı, ${response.failureCount} başarısız`);
      } catch (error: any) {
        console.error(`❌ Batch ${Math.floor(i / batchSize) + 1} hatası:`, error?.message || error);
        failureCount += validTokens.length;
      }
    }

    console.log(`✅ Toplam: ${successCount} başarılı, ${failureCount} başarısız`);

    res.status(200).json({
      success: true,
      message: 'Bildirimler gönderildi',
      total: tokens.length,
      successCount: successCount,
      failureCount: failureCount,
    });
  } catch (error) {
    console.error('❌ Bildirim gönderme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Bildirim gönderme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * iOS kullanıcılarına "İyi Geceler" bildirimi gönder
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendGoodNightNotification
 */
export const sendGoodNightNotification = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🌙 iOS kullanıcılarına "İyi Geceler" bildirimi gönderiliyor...');

    // iOS kullanıcılarının FCM token'larını al
    let usersSnapshot;

    try {
      // Önce platform='ios' olanları al
      usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('platform', '==', 'ios')
        .where('fcmToken', '!=', null)
        .get();

      console.log(`📱 Platform='ios' olan ${usersSnapshot.size} kullanıcı bulundu`);
    } catch (error) {
      // Platform field yoksa veya index yoksa, tüm kullanıcıları al
      console.log('⚠️  Platform field sorgusu başarısız, tüm kullanıcılar kontrol ediliyor...');
      usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('fcmToken', '!=', null)
        .limit(1000)
        .get();
    }

    if (usersSnapshot.empty) {
      console.log('⚠️  FCM token\'ı olan kullanıcı bulunamadı');
      res.status(200).json({
        success: false,
        message: 'FCM token\'ı olan kullanıcı bulunamadı',
        count: 0,
      });
      return;
    }

    // Token'ları topla (iOS kullanıcılarını filtrele)
    const tokens: string[] = [];
    let iosUserCount = 0;
    let otherUserCount = 0;

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const platform = userData.platform;

      if (fcmToken && fcmToken.trim().length > 0) {
        if (platform === 'ios') {
          tokens.push(fcmToken);
          iosUserCount++;
        } else if (!platform) {
          // Platform bilgisi yoksa, iOS olabilir (eski kayıtlar)
          tokens.push(fcmToken);
          otherUserCount++;
        }
      }
    });

    if (tokens.length === 0) {
      console.log('⚠️  Geçerli iOS FCM token bulunamadı');
      res.status(200).json({
        success: false,
        message: 'Geçerli iOS FCM token bulunamadı',
        count: 0,
      });
      return;
    }

    console.log(`✅ ${tokens.length} geçerli FCM token bulundu`);
    console.log(`   - iOS kullanıcıları: ${iosUserCount}`);
    console.log(`   - Platform bilgisi olmayan: ${otherUserCount}`);

    // Bildirim payload'ı
    const notification = {
      title: 'CanlıPazar',
      body: 'İyi Geceler Diler 🌙',
    };

    const data = {
      type: 'goodnight',
      timestamp: new Date().toISOString(),
    };

    // Multicast mesaj oluştur (500 token'a kadar)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    console.log('📤 Bildirimler gönderiliyor...');

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);

      const message: admin.messaging.MulticastMessage = {
        tokens: batchTokens,
        notification: notification,
        data: {
          type: data.type,
          timestamp: data.timestamp,
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'new_posts_channel',
            sound: 'default',
            priority: 'high' as const,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1,
              alert: {
                title: notification.title,
                body: notification.body,
              },
            },
          },
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(message);
        successCount += response.successCount;
        failureCount += response.failureCount;

        console.log(
          `📤 Batch ${Math.floor(i / batchSize) + 1}: ` +
          `${response.successCount} başarılı, ` +
          `${response.failureCount} başarısız`
        );

        // Başarısız token'ları logla
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.log(
                `❌ Token hatası: ${batchTokens[idx].substring(0, 20)}... - ` +
                `${resp.error?.message || 'Bilinmeyen hata'}`
              );
            }
          });
        }
      } catch (error) {
        console.error(`❌ Batch gönderme hatası:`, error);
        failureCount += batchTokens.length;
      }
    }

    console.log('\n📊 ÖZET:');
    console.log(`   ✅ Başarılı: ${successCount}`);
    console.log(`   ❌ Başarısız: ${failureCount}`);
    console.log(`   📱 Toplam: ${tokens.length}`);

    // Detaylı istatistikler
    const stats = {
      totalTokens: tokens.length,
      successCount: successCount,
      failureCount: failureCount,
      confirmedIOSUsers: iosUserCount,
      unknownPlatformUsers: otherUserCount,
      successRate: tokens.length > 0 ? ((successCount / tokens.length) * 100).toFixed(2) + '%' : '0%',
    };

    console.log('\n📊 DETAYLI İSTATİSTİKLER:');
    console.log(`   Toplam Token: ${stats.totalTokens}`);
    console.log(`   ✅ Başarılı: ${stats.successCount} (${stats.successRate})`);
    console.log(`   ❌ Başarısız: ${stats.failureCount}`);
    console.log(`   📱 Kesin iOS: ${stats.confirmedIOSUsers}`);
    console.log(`   ❓ Platform Bilgisi Yok: ${stats.unknownPlatformUsers}`);

    res.status(200).json({
      success: true,
      message: 'Bildirimler başarıyla gönderildi',
      ...stats,
    });
  } catch (error) {
    console.error('❌ Hata oluştu:', error);
    res.status(500).json({
      success: false,
      message: 'Bildirim gönderme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Test: Yeni ilan bildirimi test et
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/testNewPostNotification
 */
export const testNewPostNotification = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🧪 Yeni ilan bildirimi test ediliyor...');

    // Test için yeni bir ilan oluştur
    const testAnimalData = {
      uid: 'test_user_id_' + Date.now(), // Test kullanıcı ID'si (kendi ilanı için bildirim almayacak)
      description: '🧪 TEST İLANI - Yeni ilan bildirimi testi için oluşturuldu',
      username: 'Test Kullanıcı',
      datePublished: admin.firestore.FieldValue.serverTimestamp(),
      photoUrls: [],
      profImage: '',
      country: 'Türkiye',
      state: 'İstanbul',
      city: 'İstanbul',
      animalType: 'büyükbaş',
      animalSpecies: 'sığır',
      animalBreed: 'holstein',
      ageInMonths: 24,
      gender: 'dişi',
      weightInKg: 450,
      priceInTL: 15000,
      healthStatus: 'sağlıklı',
      vaccinations: ['şap', 'brucella'],
      purpose: 'süt',
      isPregnant: false,
      isNegotiable: true,
      sellerType: 'bireysel',
      transportInfo: 'Nakliye mümkün',
      isUrgentSale: false,
      likes: [],
      saved: [],
      isActive: true,
    };

    console.log('📝 Test ilanı oluşturuluyor...');

    // Firestore'a test ilanını ekle (bu onNewAnimalPostCreated'i tetikleyecek)
    const docRef = await admin.firestore().collection('animals').add(testAnimalData);

    console.log(`✅ Test ilanı oluşturuldu: ${docRef.id}`);
    console.log('📤 Cloud Function tetikleniyor...');
    console.log('   onNewAnimalPostCreated fonksiyonu çalışacak ve bildirimler gönderilecek');

    res.status(200).json({
      success: true,
      message: 'Test ilanı oluşturuldu ve bildirimler gönderiliyor',
      animalId: docRef.id,
      note: 'onNewAnimalPostCreated Cloud Function tetiklendi. Bildirimler birkaç saniye içinde gönderilecek.',
    });
  } catch (error) {
    console.error('❌ Test hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Test ilanı oluşturma hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Test ilanını sil
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/deleteTestPost
 * Query param: ?animalId=muHvZZPAnfxlbjFOcUOy
 */
export const deleteTestPost = functions.https.onRequest(async (req, res) => {
  try {
    const animalId = req.query.animalId as string || req.body?.animalId;

    if (!animalId) {
      res.status(400).json({
        success: false,
        message: 'animalId parametresi gerekli',
      });
      return;
    }

    console.log(`🗑️  Test ilanı siliniyor: ${animalId}`);

    // Test ilanını sil
    await admin.firestore().collection('animals').doc(animalId).delete();

    console.log(`✅ Test ilanı silindi: ${animalId}`);

    res.status(200).json({
      success: true,
      message: 'Test ilanı başarıyla silindi',
      animalId: animalId,
    });
  } catch (error) {
    console.error('❌ Silme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Test ilanı silme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Belirli bir kullanıcıya test bildirimi gönder
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToUser
 * Query param: ?userId=CtBc8p5lhaSgQDv3oI9jfUwMAmS2
 * veya POST body: { "userId": "CtBc8p5lhaSgQDv3oI9jfUwMAmS2", "message": "Test mesajı" }
 */
export const sendNotificationToUser = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const userId = (req.query.userId as string) || req.body?.userId;
    const customMessage = req.body?.message || req.query.message as string || 'Test bildirimi - CanlıPazar';

    if (!userId) {
      res.status(400).json({
        success: false,
        message: 'userId parametresi gerekli',
      });
      return;
    }

    console.log(`📤 Kullanıcıya bildirim gönderiliyor: ${userId}`);

    // Kullanıcı bilgilerini al
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı',
        userId: userId,
      });
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    const platform = userData?.platform;

    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      res.status(400).json({
        success: false,
        message: 'Kullanıcının FCM token\'ı yok',
        userId: userId,
        platform: platform,
      });
      return;
    }

    console.log(`✅ Kullanıcı bulundu: ${userId}, Platform: ${platform || 'bilinmiyor'}, Token: ${fcmToken.substring(0, 20)}...`);

    // Bildirim payload'ı
    const notification = {
      title: 'CanlıPazar Test Bildirimi',
      body: customMessage,
    };

    const data = {
      type: 'test_notification',
      userId: userId,
      timestamp: new Date().toISOString(),
    };

    // FCM mesajı oluştur
    const message: admin.messaging.Message = {
      token: fcmToken.trim(),
      notification: notification,
      data: {
        type: data.type,
        userId: data.userId,
        timestamp: data.timestamp,
      },
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'default_channel',
          sound: 'default',
          priority: 'high' as const,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'content-available': 1,
            'mutable-content': 1,
            alert: {
              title: notification.title,
              body: notification.body,
            },
          },
        },
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
          'apns-expiration': '0',
          'apns-topic': 'com.canlipazar.app', // iOS bundle ID
        },
        fcmOptions: {
          analyticsLabel: 'test_notification',
        },
      },
    };

    // Bildirimi gönder
    try {
      const response = await admin.messaging().send(message);
      console.log(`✅ Bildirim başarıyla gönderildi: ${response}`);
      console.log(`✅ Kullanıcı: ${userId}, Platform: ${platform || 'bilinmiyor'}`);

      res.status(200).json({
        success: true,
        message: 'Bildirim başarıyla gönderildi',
        userId: userId,
        platform: platform || 'bilinmiyor',
        messageId: response,
        notification: notification,
      });
    } catch (sendError: any) {
      console.error(`❌ Bildirim gönderme hatası:`, sendError);
      console.error(`❌ Hata kodu: ${sendError.code || 'UNKNOWN'}`);
      console.error(`❌ Hata mesajı: ${sendError.message || 'Bilinmeyen hata'}`);

      res.status(500).json({
        success: false,
        message: 'Bildirim gönderme hatası',
        userId: userId,
        platform: platform || 'bilinmiyor',
        error: sendError.code || 'UNKNOWN',
        errorMessage: sendError.message || 'Bilinmeyen hata',
      });
    }
  } catch (error: any) {
    console.error('❌ Test bildirimi hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Test bildirimi hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Platform alanı eksik olan kullanıcılara platform ekle
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers
 * 
 * Bu fonksiyon:
 * 1. Tüm kullanıcıları tarar
 * 2. Platform alanı eksik olanları bulur
 * 3. FCM token'ına bakarak platform tahmin etmeye çalışır
 * 4. Platform ekler (varsayılan: "unknown", kullanıcı uygulamayı açtığında düzeltilir)
 * 
 * Kullanım:
 * - GET: https://us-central1-canlipazar-b3697.cloudfunctions.net/addPlatformToUsers
 * - POST: { "dryRun": true } - Sadece kontrol et, ekleme
 * - POST: { "dryRun": false } - Gerçekten ekle
 */
export const addPlatformToUsers = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const dryRun = req.body?.dryRun !== false; // Varsayılan: true (sadece kontrol)
    const limit = req.body?.limit || 100; // Varsayılan: 100 kullanıcı

    console.log(`🔄 Platform alanı ekleme işlemi başlatılıyor...`);
    console.log(`📊 Mod: ${dryRun ? 'DRY RUN (sadece kontrol)' : 'GERÇEK EKLEME'}`);
    console.log(`📊 Limit: ${limit} kullanıcı`);

    // Tüm kullanıcıları al
    const usersSnapshot = await admin
      .firestore()
      .collection('users')
      .limit(limit)
      .get();

    if (usersSnapshot.empty) {
      res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı',
      });
      return;
    }

    console.log(`📊 ${usersSnapshot.size} kullanıcı bulundu`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    const usersToUpdate: Array<{ userId: string; platform: string; reason: string }> = [];

    // Her kullanıcıyı kontrol et
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;
      const currentPlatform = userData.platform;
      const fcmToken = userData.fcmToken;

      try {
        // Platform alanı zaten varsa atla
        if (currentPlatform && typeof currentPlatform === 'string' && currentPlatform.trim().length > 0) {
          skippedCount++;
          continue;
        }

        // Platform tahmin etmeye çalış
        let platform = 'unknown';
        let reason = 'Platform alanı eksik';

        // FCM token'ına bakarak platform tahmin et (güvenilir değil ama deneyebiliriz)
        if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length > 0) {
          // iOS token'ları genellikle 64 karakter, Android token'ları genellikle daha uzun
          // Ancak bu kesin değil, bu yüzden "unknown" kullanıyoruz
          // Kullanıcı uygulamayı açtığında FCMTokenManager doğru platform'u ekleyecek
          platform = 'unknown';
          reason = 'Platform alanı eksik, FCM token mevcut (kullanıcı uygulamayı açtığında düzeltilecek)';
        } else {
          platform = 'unknown';
          reason = 'Platform alanı eksik, FCM token yok';
        }

        usersToUpdate.push({ userId, platform, reason });

        // Dry run değilse, platform ekle
        if (!dryRun) {
          await doc.ref.update({
            platform: platform,
            platformAddedAt: admin.firestore.FieldValue.serverTimestamp(),
            platformAddedBy: 'addPlatformToUsers_function',
          });
          updatedCount++;
          console.log(`✅ ${userId}: Platform eklendi (${platform})`);
        } else {
          updatedCount++;
          console.log(`🔍 ${userId}: Platform eklenecek (${platform}) - DRY RUN`);
        }
      } catch (error: any) {
        errorCount++;
        console.error(`❌ ${userId}: Hata - ${error.message}`);
      }
    }

    const result = {
      success: true,
      message: dryRun ? 'Kontrol tamamlandı (DRY RUN)' : 'Platform alanları eklendi',
      stats: {
        total: usersSnapshot.size,
        updated: updatedCount,
        skipped: skippedCount,
        errors: errorCount,
      },
      usersToUpdate: usersToUpdate.slice(0, 20), // İlk 20 kullanıcıyı göster
      dryRun: dryRun,
    };

    console.log(`📊 İşlem tamamlandı:`);
    console.log(`   ✅ Güncellenen: ${updatedCount}`);
    console.log(`   ⏭️  Atlanan: ${skippedCount}`);
    console.log(`   ❌ Hata: ${errorCount}`);

    res.status(200).json(result);
  } catch (error: any) {
    console.error('❌ Platform ekleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Platform ekleme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Tüm platformlara (iOS + Android) bildirim gönder
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms
 * 
 * Kullanım:
 * POST: {
 *   "title": "Yeni ilanlar yayında 🐄",
 *   "body": "Bölgenizde yeni hayvan ilanları eklendi. Göz atmak ister misiniz?",
 *   "data": { "type": "new_posts" } // Opsiyonel
 * }
 */
/**
 * Tüm kullanıcılara bildirim gönder (sınırsız - batch işleme ile)
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/sendNotificationToAllPlatforms
 * 
 * Kullanım:
 * POST: {
 *   "title": "CanlıPazar'da ilan verin",
 *   "body": "Binlerce müşteriye ulaşın",
 *   "data": { "type": "promotion" } // Opsiyonel
 * }
 */
export const sendNotificationToAllPlatforms = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // Bildirim içeriğini al
    const title = req.body?.title || req.query.title as string || 'CanlıPazar';
    const body = req.body?.body || req.query.body as string || 'Yeni bildiriminiz var';
    const customData = req.body?.data || { type: 'general_notification' };

    console.log(`📤 Tüm kullanıcılara bildirim gönderiliyor...`);
    console.log(`📋 Başlık: ${title}`);
    console.log(`📋 Mesaj: ${body}`);

    // Tüm kullanıcıları al (sınırsız - batch işleme ile)
    const allTokens: string[] = [];
    const platformTokens: { ios: string[]; android: string[]; unknown: string[] } = {
      ios: [],
      android: [],
      unknown: []
    };
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    let totalUsers = 0;
    let batchCount = 0;
    let iosCount = 0;
    let androidCount = 0;
    let unknownCount = 0;

    // Tüm kullanıcıları batch'ler halinde al (Firestore limit: 1000)
    while (true) {
      try {
        let query = admin
          .firestore()
          .collection('users')
          .where('fcmToken', '!=', null)
          .limit(1000);

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.get();

        if (usersSnapshot.empty) {
          break;
        }

        batchCount++;
        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const fcmToken = userData.fcmToken;
          const platform = userData.platform;

          if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length >= 50) {
            const trimmedToken = fcmToken.trim();
            allTokens.push(trimmedToken);
            totalUsers++;

            // Platform'a göre token'ları ayır
            if (platform === 'ios') {
              platformTokens.ios.push(trimmedToken);
              iosCount++;
            } else if (platform === 'android') {
              platformTokens.android.push(trimmedToken);
              androidCount++;
            } else {
              platformTokens.unknown.push(trimmedToken);
              unknownCount++;
            }
          }
        });

        lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];

        console.log(`📊 Batch ${batchCount}: ${usersSnapshot.size} kullanıcı, Toplam: ${totalUsers}`);

        // Son batch ise çık
        if (usersSnapshot.size < 1000) {
          break;
        }
      } catch (error) {
        console.log('⚠️  Kullanıcı sorgusu başarısız:', error);
        break;
      }
    }

    if (allTokens.length === 0) {
      console.log('⚠️  FCM token\'ı olan kullanıcı bulunamadı');
      res.status(200).json({
        success: false,
        message: 'FCM token\'ı olan kullanıcı bulunamadı',
        stats: {
          total: 0,
          sent: 0,
          failed: 0,
        },
      });
      return;
    }

    console.log(`✅ Toplam ${allTokens.length} kullanıcıya bildirim gönderilecek`);
    console.log(`📊 Platform dağılımı: iOS=${iosCount}, Android=${androidCount}, Unknown=${unknownCount}`);

    // FCM sendMulticast ile platform'a göre batch gönder (her batch 500 token - FCM limit)
    const batchSize = 500;
    let sentCount = 0;
    let failedCount = 0;
    const batchPromises: Promise<admin.messaging.BatchResponse>[] = [];

    // iOS token'larını batch'ler halinde gönder
    for (let i = 0; i < platformTokens.ios.length; i += batchSize) {
      const iosBatch = platformTokens.ios.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;

      console.log(`📤 iOS Batch ${batchNumber}/${Math.ceil(platformTokens.ios.length / batchSize)}: ${iosBatch.length} bildirim gönderiliyor...`);

      const iosMessage: admin.messaging.MulticastMessage = {
        tokens: iosBatch,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: customData.type || 'general_notification',
          timestamp: new Date().toISOString(),
          ...customData,
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1,
              'mutable-content': 1,
              alert: {
                title: title,
                body: body,
              },
            },
          },
        },
      };

      batchPromises.push(
        admin.messaging().sendMulticast(iosMessage)
          .then((response) => {
            sentCount += response.successCount;
            failedCount += response.failureCount;
            console.log(`✅ iOS Batch ${batchNumber}: ${response.successCount} başarılı, ${response.failureCount} başarısız`);
            return response;
          })
          .catch((error) => {
            console.error(`❌ iOS Batch ${batchNumber} hatası:`, error);
            failedCount += iosBatch.length;
            return { successCount: 0, failureCount: iosBatch.length } as admin.messaging.BatchResponse;
          })
      );
    }

    // Android token'larını batch'ler halinde gönder
    for (let i = 0; i < platformTokens.android.length; i += batchSize) {
      const androidBatch = platformTokens.android.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;

      console.log(`📤 Android Batch ${batchNumber}/${Math.ceil(platformTokens.android.length / batchSize)}: ${androidBatch.length} bildirim gönderiliyor...`);

      const androidMessage: admin.messaging.MulticastMessage = {
        tokens: androidBatch,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: customData.type || 'general_notification',
          timestamp: new Date().toISOString(),
          ...customData,
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'default_channel',
            sound: 'default',
            priority: 'high' as const,
          },
        },
      };

      batchPromises.push(
        admin.messaging().sendMulticast(androidMessage)
          .then((response) => {
            sentCount += response.successCount;
            failedCount += response.failureCount;
            console.log(`✅ Android Batch ${batchNumber}: ${response.successCount} başarılı, ${response.failureCount} başarısız`);
            return response;
          })
          .catch((error) => {
            console.error(`❌ Android Batch ${batchNumber} hatası:`, error);
            failedCount += androidBatch.length;
            return { successCount: 0, failureCount: androidBatch.length } as admin.messaging.BatchResponse;
          })
      );
    }

    // Unknown platform token'larını batch'ler halinde gönder (iOS varsayarak)
    for (let i = 0; i < platformTokens.unknown.length; i += batchSize) {
      const unknownBatch = platformTokens.unknown.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;

      console.log(`📤 Unknown Batch ${batchNumber}/${Math.ceil(platformTokens.unknown.length / batchSize)}: ${unknownBatch.length} bildirim gönderiliyor...`);

      const unknownMessage: admin.messaging.MulticastMessage = {
        tokens: unknownBatch,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: customData.type || 'general_notification',
          timestamp: new Date().toISOString(),
          ...customData,
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1,
              'mutable-content': 1,
              alert: {
                title: title,
                body: body,
              },
            },
          },
        },
      };

      batchPromises.push(
        admin.messaging().sendMulticast(unknownMessage)
          .then((response) => {
            sentCount += response.successCount;
            failedCount += response.failureCount;
            console.log(`✅ Unknown Batch ${batchNumber}: ${response.successCount} başarılı, ${response.failureCount} başarısız`);
            return response;
          })
          .catch((error) => {
            console.error(`❌ Unknown Batch ${batchNumber} hatası:`, error);
            failedCount += unknownBatch.length;
            return { successCount: 0, failureCount: unknownBatch.length } as admin.messaging.BatchResponse;
          })
      );
    }

    // Tüm batch'leri bekle
    await Promise.allSettled(batchPromises);

    console.log(`✅ Bildirim gönderme tamamlandı: ${sentCount} başarılı, ${failedCount} başarısız`);

    res.status(200).json({
      success: true,
      message: 'Bildirimler gönderildi',
      stats: {
        total: totalUsers,
        ios: iosCount,
        android: androidCount,
        unknown: unknownCount,
        sent: sentCount,
        failed: failedCount,
      },
      notification: {
        title: title,
        body: body,
      },
    });
  } catch (error) {
    console.error('❌ Bildirim gönderme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Bildirim gönderme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});


/**
 * Platform "unknown" olan kullanıcıları düzelt
 * FCM token formatına ve diğer ipuçlarına bakarak platform'u belirler
 * HTTP endpoint: https://us-central1-canlipazar-b3697.cloudfunctions.net/fixUnknownPlatforms
 * 
 * Kullanım:
 * POST: {
 *   "dryRun": false,  // true = sadece kontrol, false = gerçek düzeltme
 *   "limit": 1000     // Maksimum kaç kullanıcı düzeltilecek
 * }
 */
export const fixUnknownPlatforms = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const dryRun = req.body?.dryRun === true; // Varsayılan: false (gerçek düzeltme)
    const limit = req.body?.limit || 1000; // Maksimum kaç kullanıcı

    console.log(`🔄 Platform "unknown" düzeltme işlemi başlatılıyor...`);
    console.log(`📊 Mod: ${dryRun ? 'DRY RUN (sadece kontrol)' : 'GERÇEK DÜZELTME'}`);
    console.log(`📊 Limit: ${limit} kullanıcı`);

    // Platform "unknown" veya platform alanı olmayan kullanıcıları al
    // FCM token'ı olan tüm kullanıcıları al (pagination ile)
    const allUsers: Array<{ doc: admin.firestore.QueryDocumentSnapshot; data: any }> = [];
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    let batchCount = 0;

    while (allUsers.length < limit) {
      try {
        let query = admin
          .firestore()
          .collection('users')
          .where('fcmToken', '!=', null)
          .limit(1000);

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const usersSnapshot = await query.get();

        if (usersSnapshot.empty) {
          break;
        }

        batchCount++;
        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const currentPlatform = userData.platform;

          // Platform "unknown" veya yok ise ekle
          if (!currentPlatform || currentPlatform === 'unknown' || (typeof currentPlatform === 'string' && currentPlatform.trim() === '')) {
            if (allUsers.length < limit) {
              allUsers.push({ doc, data: userData });
            }
          }
        });

        lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];

        console.log(`📊 Batch ${batchCount}: ${usersSnapshot.size} kullanıcı kontrol edildi, ${allUsers.length} "unknown" bulundu`);

        // Limit'e ulaştıysak veya son batch ise çık
        if (allUsers.length >= limit || usersSnapshot.size < 1000) {
          break;
        }
      } catch (error) {
        console.log('⚠️  Kullanıcı sorgusu başarısız:', error);
        break;
      }
    }

    if (allUsers.length === 0) {
      res.status(200).json({
        success: false,
        message: 'Platform "unknown" olan kullanıcı bulunamadı',
        stats: {
          total: 0,
          fixed: 0,
          skipped: 0,
          errors: 0,
        },
      });
      return;
    }

    console.log(`📊 Toplam ${allUsers.length} "unknown" platform kullanıcı bulundu`);

    let fixedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    let iosFixed = 0;
    let androidFixed = 0;
    let stillUnknown = 0;

    // Her kullanıcıyı kontrol et ve düzelt
    for (const { doc, data: userData } of allUsers) {
      const userId = doc.id;
      const fcmToken = userData.fcmToken;

      try {
        let detectedPlatform = 'unknown';
        let detectionMethod = '';

        // FCM token formatına bakarak platform tahmin et
        if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length > 0) {
          const token = fcmToken.trim();

          // Yöntem 1: Token uzunluğu
          // Android token'ları genellikle 150+ karakter
          // iOS token'ları genellikle 64-100 karakter
          if (token.length >= 140 && token.length <= 250) {
            // Android token'ları genellikle daha uzun
            detectedPlatform = 'android';
            detectionMethod = 'token_length';
          } else if (token.length >= 50 && token.length <= 120) {
            // iOS token'ları genellikle daha kısa
            detectedPlatform = 'ios';
            detectionMethod = 'token_length';
          } else {
            // Yöntem 2: Token formatı
            // iOS token'ları genellikle ":" ile ayrılmış segmentler içerir
            if (token.includes(':') && token.split(':').length >= 3) {
              detectedPlatform = 'ios';
              detectionMethod = 'token_format';
            } else if (token.length > 120) {
              detectedPlatform = 'android';
              detectionMethod = 'token_length_long';
            } else {
              // Belirsiz, "unknown" bırak
              detectedPlatform = 'unknown';
              detectionMethod = 'unable_to_detect';
            }
          }
        } else {
          // FCM token yok, "unknown" bırak
          detectedPlatform = 'unknown';
          detectionMethod = 'no_fcm_token';
        }

        // Eğer platform belirlenebildiyse güncelle
        if (detectedPlatform !== 'unknown') {
          if (!dryRun) {
            await doc.ref.update({
              platform: detectedPlatform,
              platformFixedAt: admin.firestore.FieldValue.serverTimestamp(),
              platformFixedBy: 'fixUnknownPlatforms_function',
              platformDetectionMethod: detectionMethod,
            });
            fixedCount++;

            if (detectedPlatform === 'ios') {
              iosFixed++;
            } else if (detectedPlatform === 'android') {
              androidFixed++;
            }

            console.log(`✅ ${userId}: Platform düzeltildi (${detectedPlatform}) - Yöntem: ${detectionMethod}`);
          } else {
            fixedCount++;
            console.log(`🔍 ${userId}: Platform düzeltilecek (${detectedPlatform}) - Yöntem: ${detectionMethod} - DRY RUN`);
          }
        } else {
          stillUnknown++;
          console.log(`⚠️ ${userId}: Platform belirlenemedi, "unknown" bırakıldı`);
        }
      } catch (error: any) {
        errorCount++;
        console.error(`❌ ${userId}: Hata - ${error.message}`);
      }
    }

    const result = {
      success: true,
      message: dryRun ? 'Kontrol tamamlandı (DRY RUN)' : 'Platform "unknown" kullanıcılar düzeltildi',
      stats: {
        total: allUsers.length,
        fixed: fixedCount,
        iosFixed: iosFixed,
        androidFixed: androidFixed,
        stillUnknown: stillUnknown,
        skipped: skippedCount,
        errors: errorCount,
      },
      dryRun: dryRun,
    };

    console.log(`📊 İşlem tamamlandı:`);
    console.log(`   ✅ Düzeltilen: ${fixedCount} (iOS: ${iosFixed}, Android: ${androidFixed})`);
    console.log(`   ⚠️  Hala unknown: ${stillUnknown}`);
    console.log(`   ⏭️  Atlanan: ${skippedCount}`);
    console.log(`   ❌ Hata: ${errorCount}`);

    res.status(200).json(result);
  } catch (error: any) {
    console.error('❌ Platform düzeltme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Platform düzeltme hatası',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Mesaj bildirimi gönder (Callable Function)
 * Production-ready, çökmeyen, iOS & Android uyumlu
 */
export const sendMessageNotificationCallable = functions.https.onCall(async (data, context) => {
  const startTime = Date.now();

  try {
    // Input validation
    const recipientId = data?.recipientId;
    const senderId = data?.senderId;
    const senderUsername = data?.senderUsername || 'Birisi';
    const messageText = data?.messageText || '';
    const conversationId = data?.conversationId || '';
    const messageId = data?.messageId || '';
    const postId = data?.postId || '';
    // KRİTİK: Kullanıcı isteği - "kullanıcı_adı size mesaj gönderdi" formatı
    // Eğer title parametresi gönderilmemişse, senderUsername ile oluştur
    const title = data?.title || `${senderUsername} size mesaj gönderdi`;

    console.log(`📤 [sendMessageNotification] Bildirim gönderiliyor...`);
    console.log(`   - Alıcı: ${recipientId}`);
    console.log(`   - Gönderen: ${senderId} (${senderUsername})`);
    console.log(`   - Mesaj: ${messageText.substring(0, 50)}${messageText.length > 50 ? '...' : ''}`);

    // Kritik parametreler kontrolü
    if (!recipientId || typeof recipientId !== 'string' || recipientId.trim().length === 0) {
      console.error(`❌ [sendMessageNotification] Geçersiz recipientId: ${recipientId}`);
      return {
        success: false,
        reason: 'invalid_recipient_id',
        message: 'Alıcı ID gerekli',
      };
    }

    if (!senderId || typeof senderId !== 'string' || senderId.trim().length === 0) {
      console.error(`❌ [sendMessageNotification] Geçersiz senderId: ${senderId}`);
      return {
        success: false,
        reason: 'invalid_sender_id',
        message: 'Gönderen ID gerekli',
      };
    }

    // Alıcının kullanıcı bilgilerini al
    let recipientDoc;
    try {
      recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
    } catch (error: any) {
      console.error(`❌ [sendMessageNotification] Firestore okuma hatası:`, error);
      return {
        success: false,
        reason: 'firestore_error',
        message: 'Kullanıcı bilgileri alınamadı',
      };
    }

    if (!recipientDoc.exists) {
      console.error(`❌ [sendMessageNotification] Alıcı bulunamadı: ${recipientId}`);
      return {
        success: false,
        reason: 'recipient_not_found',
        message: 'Alıcı bulunamadı',
      };
    }

    const recipientData = recipientDoc.data();
    if (!recipientData) {
      console.error(`❌ [sendMessageNotification] Alıcı verisi boş: ${recipientId}`);
      return {
        success: false,
        reason: 'recipient_data_empty',
        message: 'Alıcı verisi boş',
      };
    }

    const recipientToken = recipientData.fcmToken;
    const recipientPlatform = normalizePlatform(recipientData.platform);

    // Token validation - esnek kontrol
    // Önce token'ın varlığını kontrol et
    if (!recipientToken || typeof recipientToken !== 'string' || recipientToken.trim().length === 0) {
      console.error(`❌ [sendMessageNotification] FCM token yok veya boş: ${recipientId}`);
      console.error(`   - Token tipi: ${typeof recipientToken}`);
      console.error(`   - Token değeri: ${recipientToken || 'null/undefined/empty'}`);
      return {
        success: false,
        reason: 'missing_fcm_token',
        message: 'Alıcının FCM token\'ı Firestore\'da yok veya boş',
        platform: recipientPlatform,
      };
    }

    const trimmedToken = recipientToken.trim();

    // Token uzunluk kontrolü (çok kısa token'lar geçersiz olabilir)
    if (trimmedToken.length < 50) {
      console.warn(`⚠️ [sendMessageNotification] Token çok kısa: ${trimmedToken.length} karakter`);
      console.warn(`   - Token (ilk 30 karakter): ${trimmedToken.substring(0, Math.min(30, trimmedToken.length))}...`);
      console.warn(`   - Bu token muhtemelen geçersiz ama FCM'e gönderip kontrol ediyoruz`);
    }

    // Token format kontrolü (log için, göndermeyi engellemez)
    const tokenPattern = /^[A-Za-z0-9_\-:]+$/;
    if (!tokenPattern.test(trimmedToken)) {
      console.warn(`⚠️ [sendMessageNotification] Token formatı standart değil`);
      console.warn(`   - Token (ilk 50 karakter): ${trimmedToken.substring(0, 50)}...`);
      console.warn(`   - FCM kendi validation'ını yapacak, göndermeyi deniyoruz`);
    }

    console.log(`✅ [sendMessageNotification] Token alındı: ${trimmedToken.substring(0, 20)}...`);
    console.log(`   - Token uzunluğu: ${trimmedToken.length} karakter`);
    console.log(`   - Platform: ${recipientPlatform}`);

    // Okunmamış mesaj sayısını hesapla (güvenli)
    let unreadCount = 1; // Default değer
    try {
      if (conversationId && conversationId.trim().length > 0) {
        const unreadMessagesSnapshot = await admin
          .firestore()
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .where("recipient", "==", recipientId)
          .where("isRead", "==", false)
          .get();

        unreadCount = unreadMessagesSnapshot.size > 0 ? unreadMessagesSnapshot.size : 1;
        console.log(`📊 [sendMessageNotification] Okunmamış mesaj sayısı: ${unreadCount}`);
      }
    } catch (error: any) {
      console.warn(`⚠️ [sendMessageNotification] Okunmamış mesaj sayısı hesaplanamadı:`, error);
      // Hata durumunda default değer kullanılır
    }

    // Bildirim içeriği
    // KRİTİK: Kullanıcı isteği - başlıkta kullanıcı adı var, body'de sadece mesaj içeriği
    const notificationTitle = title;
    const notificationBody = messageText.length > 100 ? messageText.substring(0, 100) + "..." : messageText;

    // Data payload (tüm string olmalı)
    const notificationData: Record<string, string> = {
      type: "message",
      senderId: senderId,
      receiverId: recipientId,
      conversationId: conversationId,
      messageId: messageId,
      postId: postId || "",
      text: messageText,
      unreadCount: unreadCount.toString(),
      senderUsername: senderUsername,
      title: notificationTitle,
    };

    // Platform'a göre FCM mesajı oluştur
    let message: admin.messaging.Message;

    if (recipientPlatform === 'ios') {
      // iOS payload
      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        apns: createIOSPayload(notificationTitle, notificationBody, unreadCount, notificationData),
      };
    } else if (recipientPlatform === 'android') {
      // Android payload
      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        android: createAndroidPayload(unreadCount, "messages_channel"),
      };
    } else {
      // Unknown platform - fallback (hem iOS hem Android payload'ı)
      console.warn(`⚠️ [sendMessageNotification] Platform bilinmiyor, fallback payload kullanılıyor`);
      const unknownPayload = createUnknownPlatformPayload(
        notificationTitle,
        notificationBody,
        unreadCount,
        notificationData,
        "messages_channel"
      );

      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        android: unknownPayload.android,
        apns: unknownPayload.apns,
      };
    }

    // Bildirimi gönder (güvenli)
    const sendResult = await sendFCMessage(message);

    const duration = Date.now() - startTime;

    if (sendResult.success) {
      console.log(`✅ [sendMessageNotification] Bildirim başarıyla gönderildi: ${sendResult.messageId}`);
      console.log(`   - Süre: ${duration}ms`);
      console.log(`   - Platform: ${recipientPlatform}`);

      return {
        success: true,
        messageId: sendResult.messageId,
        recipientId: recipientId,
        platform: recipientPlatform,
        unreadCount: unreadCount,
        duration: duration,
      };
    } else {
      console.error(`❌ [sendMessageNotification] Bildirim gönderilemedi`);
      console.error(`   - Hata: ${sendResult.error}`);
      console.error(`   - Hata kodu: ${sendResult.errorCode}`);
      console.error(`   - Süre: ${duration}ms`);
      console.error(`   - Token (ilk 30 karakter): ${trimmedToken.substring(0, 30)}...`);

      // Geçersiz token hatası özel olarak işle
      if (sendResult.errorCode === 'messaging/invalid-registration-token' ||
        sendResult.errorCode === 'messaging/registration-token-not-registered') {
        console.error(`⚠️ [sendMessageNotification] Token geçersiz veya kayıtlı değil`);
        console.error(`   - Alıcının token'ını güncellemesi gerekiyor`);
        console.error(`   - Token Firestore'da eski olabilir: ${trimmedToken.substring(0, 20)}...`);
        console.error(`   - Token uzunluğu: ${trimmedToken.length} karakter`);
        console.error(`   - Platform: ${recipientPlatform}`);
        console.error(`   - Olası nedenler:`);
        console.error(`     1. Token development ortamında üretilmiş ama production APNs kullanılıyor`);
        console.error(`     2. Token simulator'da üretilmiş (geçersiz)`);
        console.error(`     3. Token APNs token set edilmeden önce üretilmiş`);
        console.error(`     4. Token farklı bundle ID için üretilmiş`);
        console.error(`   - Geçersiz token Firestore'dan siliniyor...`);

        // KRİTİK: Geçersiz token'ı Firestore'dan sil
        try {
          await admin.firestore().collection('users').doc(recipientId).update({
            'fcmToken': admin.firestore.FieldValue.delete(),
            'fcmTokenInvalidatedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`✅ [sendMessageNotification] Geçersiz token Firestore'dan silindi: ${recipientId}`);
        } catch (deleteError: any) {
          console.error(`❌ [sendMessageNotification] Token silme hatası:`, deleteError);
        }

        return {
          success: false,
          reason: 'invalid_fcm_token',
          message: 'Alıcının FCM token\'ı geçersiz veya kayıtlı değil. Token Firestore\'dan silindi, kullanıcı token\'ını güncellemeli.',
          recipientId: recipientId,
          platform: recipientPlatform,
          duration: duration,
          tokenLength: trimmedToken.length,
          tokenDeleted: true,
        };
      }

      return {
        success: false,
        reason: sendResult.errorCode || 'send_failed',
        message: sendResult.error || 'Bildirim gönderilemedi',
        recipientId: recipientId,
        platform: recipientPlatform,
        duration: duration,
      };
    }
  } catch (error: any) {
    const duration = Date.now() - startTime;
    console.error(`❌ [sendMessageNotification] Beklenmeyen hata:`, error);
    console.error(`   - Süre: ${duration}ms`);
    console.error(`   - Stack: ${error.stack || 'N/A'}`);

    // INTERNAL hataya düşmemek için response döndür
    return {
      success: false,
      reason: 'internal_error',
      message: error.message || 'Beklenmeyen hata oluştu',
      error: error.toString(),
      duration: duration,
    };
  }
});

/**
 * İlan bildirimi gönder (Callable Function)
 * Yeni ilan eklendiğinde veya ilana yorum yapıldığında çağrılır
 * Production-ready, çökmeyen, iOS & Android uyumlu
 */
export const sendListingNotificationCallable = functions.https.onCall(async (data, context) => {
  const startTime = Date.now();

  try {
    // Input validation
    const recipientId = data?.recipientId;
    const senderId = data?.senderId;
    const senderUsername = data?.senderUsername || 'Birisi';
    const listingId = data?.listingId || '';
    const listingTitle = data?.listingTitle || '';
    const messageText = data?.messageText || '';
    const notificationType = data?.notificationType || 'listing_comment'; // 'new_listing' veya 'listing_comment'
    const title = data?.title || "CanlıPazardan Yeni İlan Bildirimi";

    console.log(`📤 [sendListingNotification] Bildirim gönderiliyor...`);
    console.log(`   - Alıcı: ${recipientId}`);
    console.log(`   - Gönderen: ${senderId} (${senderUsername})`);
    console.log(`   - İlan: ${listingId}`);
    console.log(`   - Tip: ${notificationType}`);

    // Kritik parametreler kontrolü
    if (!recipientId || typeof recipientId !== 'string' || recipientId.trim().length === 0) {
      console.error(`❌ [sendListingNotification] Geçersiz recipientId: ${recipientId}`);
      return {
        success: false,
        reason: 'invalid_recipient_id',
        message: 'Alıcı ID gerekli',
      };
    }

    if (!listingId || typeof listingId !== 'string' || listingId.trim().length === 0) {
      console.error(`❌ [sendListingNotification] Geçersiz listingId: ${listingId}`);
      return {
        success: false,
        reason: 'invalid_listing_id',
        message: 'İlan ID gerekli',
      };
    }

    // Alıcının kullanıcı bilgilerini al
    let recipientDoc;
    try {
      recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
    } catch (error: any) {
      console.error(`❌ [sendListingNotification] Firestore okuma hatası:`, error);
      return {
        success: false,
        reason: 'firestore_error',
        message: 'Kullanıcı bilgileri alınamadı',
      };
    }

    if (!recipientDoc.exists) {
      console.error(`❌ [sendListingNotification] Alıcı bulunamadı: ${recipientId}`);
      return {
        success: false,
        reason: 'recipient_not_found',
        message: 'Alıcı bulunamadı',
      };
    }

    const recipientData = recipientDoc.data();
    if (!recipientData) {
      console.error(`❌ [sendListingNotification] Alıcı verisi boş: ${recipientId}`);
      return {
        success: false,
        reason: 'recipient_data_empty',
        message: 'Alıcı verisi boş',
      };
    }

    const recipientToken = recipientData.fcmToken;
    const recipientPlatform = normalizePlatform(recipientData.platform);

    // Token validation - kritik kontrol
    if (!isValidFCMToken(recipientToken)) {
      console.error(`❌ [sendListingNotification] Geçersiz FCM token: ${recipientId}`);
      console.error(`   - Token: ${recipientToken ? recipientToken.substring(0, 20) + '...' : 'null/undefined'}`);
      return {
        success: false,
        reason: 'invalid_fcm_token',
        message: 'Alıcının FCM token\'ı geçersiz veya eksik',
        platform: recipientPlatform,
      };
    }

    const trimmedToken = recipientToken.trim();
    console.log(`✅ [sendListingNotification] Token geçerli: ${trimmedToken.substring(0, 20)}...`);
    console.log(`   - Platform: ${recipientPlatform}`);

    // Bildirim içeriği
    let notificationTitle = title;
    let notificationBody = '';

    if (notificationType === 'new_listing') {
      notificationBody = listingTitle || 'Yeni ilan eklendi';
    } else if (notificationType === 'listing_comment') {
      notificationBody = `${senderUsername}: ${messageText}`;
    } else {
      notificationBody = messageText || 'Yeni bildirim';
    }

    // Data payload (tüm string olmalı)
    const notificationData: Record<string, string> = {
      type: "listing",
      notificationType: notificationType,
      senderId: senderId || "",
      receiverId: recipientId,
      listingId: listingId,
      listingTitle: listingTitle || "",
      text: messageText,
      senderUsername: senderUsername,
      title: notificationTitle,
    };

    // Platform'a göre FCM mesajı oluştur
    let message: admin.messaging.Message;

    if (recipientPlatform === 'ios') {
      // iOS payload
      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        apns: createIOSPayload(notificationTitle, notificationBody, 0, notificationData),
      };
    } else if (recipientPlatform === 'android') {
      // Android payload
      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        android: createAndroidPayload(0, "listings_channel"),
      };
    } else {
      // Unknown platform - fallback
      console.warn(`⚠️ [sendListingNotification] Platform bilinmiyor, fallback payload kullanılıyor`);
      const unknownPayload = createUnknownPlatformPayload(
        notificationTitle,
        notificationBody,
        0,
        notificationData,
        "listings_channel"
      );

      message = {
        token: trimmedToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: notificationData,
        android: unknownPayload.android,
        apns: unknownPayload.apns,
      };
    }

    // Bildirimi gönder (güvenli)
    const sendResult = await sendFCMessage(message);

    const duration = Date.now() - startTime;

    if (sendResult.success) {
      console.log(`✅ [sendListingNotification] Bildirim başarıyla gönderildi: ${sendResult.messageId}`);
      console.log(`   - Süre: ${duration}ms`);
      console.log(`   - Platform: ${recipientPlatform}`);

      return {
        success: true,
        messageId: sendResult.messageId,
        recipientId: recipientId,
        platform: recipientPlatform,
        listingId: listingId,
        duration: duration,
      };
    } else {
      console.error(`❌ [sendListingNotification] Bildirim gönderilemedi`);
      console.error(`   - Hata: ${sendResult.error}`);
      console.error(`   - Hata kodu: ${sendResult.errorCode}`);
      console.error(`   - Süre: ${duration}ms`);

      return {
        success: false,
        reason: sendResult.errorCode || 'send_failed',
        message: sendResult.error || 'Bildirim gönderilemedi',
        recipientId: recipientId,
        platform: recipientPlatform,
        duration: duration,
      };
    }
  } catch (error: any) {
    const duration = Date.now() - startTime;
    console.error(`❌ [sendListingNotification] Beklenmeyen hata:`, error);
    console.error(`   - Süre: ${duration}ms`);
    console.error(`   - Stack: ${error.stack || 'N/A'}`);

    // INTERNAL hataya düşmemek için response döndür
    return {
      success: false,
      reason: 'internal_error',
      message: error.message || 'Beklenmeyen hata oluştu',
      error: error.toString(),
      duration: duration,
    };
  }
});

/**
 * Sadece iOS kullanıcılarına özel bildirim gönder
 * "CanlıPazar ile pazar artık elinizde" mesajı
 */
export const sendIOSOnlyNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log(`📱 [sendIOSOnlyNotification] iOS kullanıcılarına özel bildirim gönderiliyor...`);

    // Tüm iOS kullanıcılarını al
    const iosUsersSnapshot = await admin
      .firestore()
      .collection("users")
      .where("platform", "==", "ios")
      .where("fcmToken", "!=", null)
      .get();

    if (iosUsersSnapshot.empty) {
      console.log("⚠️ iOS kullanıcısı bulunamadı");
      return {
        success: false,
        message: "iOS kullanıcısı bulunamadı",
        sentCount: 0,
      };
    }

    console.log(`📱 ${iosUsersSnapshot.size} iOS kullanıcıya bildirim gönderilecek`);

    // Bildirim payload'ı
    const notification = {
      title: "CanlıPazar",
      body: "CanlıPazar ile pazar artık elinizde",
    };

    const notificationData = {
      type: "ios_special",
      title: notification.title,
      body: notification.body,
    };

    // iOS token'larını topla
    const iosTokens: string[] = [];
    const validUserIds: string[] = [];

    iosUsersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const userId = doc.id;

      if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length > 0) {
        // Token validation
        if (_isValidFCMToken(fcmToken.trim())) {
          iosTokens.push(fcmToken.trim());
          validUserIds.push(userId);
        } else {
          console.log(`⚠️ Geçersiz token filtrelendi: ${userId}`);
        }
      }
    });

    if (iosTokens.length === 0) {
      console.log("⚠️ Geçerli iOS token bulunamadı");
      return {
        success: false,
        message: "Geçerli iOS token bulunamadı",
        sentCount: 0,
      };
    }

    console.log(`✅ ${iosTokens.length} geçerli iOS token bulundu`);

    // Batch size (FCM limit: 500)
    const batchSize = 500;
    let totalSuccessCount = 0;
    let totalFailureCount = 0;

    // iOS kullanıcılarına bildirim gönder
    for (let i = 0; i < iosTokens.length; i += batchSize) {
      const batchTokens = iosTokens.slice(i, i + batchSize);
      const batchUserIds = validUserIds.slice(i, i + batchSize);

      const iosMessage: admin.messaging.MulticastMessage = {
        tokens: batchTokens,
        notification: notification,
        data: notificationData,
        // iOS için özel APNs ayarları
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1,
              "mutable-content": 1,
              alert: {
                title: notification.title,
                body: notification.body,
              },
              category: "IOS_SPECIAL_CATEGORY",
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
            "apns-expiration": "0",
            "apns-topic": "com.canlipazar.app",
          },
          fcmOptions: {
            analyticsLabel: "ios_special_notification",
          },
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(iosMessage);
        totalSuccessCount += response.successCount;
        totalFailureCount += response.failureCount;

        console.log(
          `📤 iOS Batch ${Math.floor(i / batchSize) + 1}: ` +
          `${response.successCount} başarılı, ` +
          `${response.failureCount} başarısız`
        );

        // Başarısız token'ları temizle
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errorCode = resp.error?.code || 'UNKNOWN';
              const errorMessage = resp.error?.message || "Bilinmeyen hata";
              const userId = batchUserIds[idx];

              console.log(
                `❌ iOS Token hatası (userId: ${userId}): ` +
                `${batchTokens[idx].substring(0, 20)}... - ` +
                `Code: ${errorCode}, Message: ${errorMessage}`
              );

              // Geçersiz token'ı Firestore'dan sil
              if (errorCode === 'messaging/invalid-registration-token' ||
                errorCode === 'messaging/registration-token-not-registered') {
                admin.firestore().collection('users').doc(userId).update({
                  fcmToken: admin.firestore.FieldValue.delete(),
                }).then(() => {
                  console.log(`✅ Geçersiz token Firestore'dan silindi: ${userId}`);
                }).catch(err => {
                  console.error(`❌ Token silme hatası: ${err}`);
                });
              }
            }
          });
        }
      } catch (error: any) {
        console.error(`❌ iOS Batch gönderme hatası:`, error);
        console.error(`❌ Hata kodu: ${error.code || 'UNKNOWN'}`);
        console.error(`❌ Hata mesajı: ${error.message || 'Bilinmeyen hata'}`);
        totalFailureCount += batchTokens.length;
      }
    }

    console.log(
      `✅ Toplam: ${totalSuccessCount} başarılı, ${totalFailureCount} başarısız`
    );

    return {
      success: true,
      message: "iOS bildirimleri başarıyla gönderildi",
      sentCount: totalSuccessCount,
      failedCount: totalFailureCount,
      totalUsers: iosUsersSnapshot.size,
    };
  } catch (error: any) {
    console.error(`❌ [sendIOSOnlyNotification] Bildirim gönderme hatası:`, error);
    throw new functions.https.HttpsError(
      error.code || 'internal',
      error.message || 'iOS bildirim gönderme hatası'
    );
  }
});
