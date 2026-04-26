import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Test bildirimi gönder
 * HTTP trigger ile çağrılır: https://[region]-[project-id].cloudfunctions.net/sendTestNotification?userId=[userId]
 * Veya userId parametresi olmadan çağrılırsa, en son güncellenen token'a gönderir
 */
export const sendTestNotification = functions.https.onRequest(async (req, res) => {
  let trimmedToken: string | null = null;
  let userDoc: admin.firestore.DocumentSnapshot | null = null;

  try {
    const userId = req.query.userId as string | undefined;
    let fcmToken: string | null = null;

    if (userId) {
      // Belirli bir kullanıcıya gönder
      console.log(`🔍 Kullanıcı ID ile token aranıyor: ${userId}`);
      const userDoc = await admin.firestore().collection("users").doc(userId).get();

      if (!userDoc.exists) {
        res.status(404).json({ error: "Kullanıcı bulunamadı" });
        return;
      }

      const userData = userDoc.data();
      fcmToken = userData?.fcmToken;

      if (!fcmToken || fcmToken.trim().length === 0) {
        res.status(400).json({ error: "Kullanıcının FCM token'ı bulunamadı" });
        return;
      }

      console.log(`✅ Token bulundu: ${fcmToken.substring(0, 20)}...`);
    } else {
      // FCM token'ı olan ilk kullanıcıyı bul
      console.log("🔍 FCM token'ı olan kullanıcı aranıyor...");
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("fcmToken", "!=", null)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        res.status(404).json({ error: "FCM token'ı olan kullanıcı bulunamadı" });
        return;
      }

      const userData = usersSnapshot.docs[0].data();
      fcmToken = userData?.fcmToken || null;
      if (fcmToken) {
        console.log(`✅ Token bulundu: ${fcmToken.substring(0, 20)}...`);
      } else {
        res.status(404).json({ error: "FCM token bulunamadı" });
        return;
      }
    }

    if (!fcmToken) {
      res.status(400).json({ error: "FCM token bulunamadı" });
      return;
    }

    // KRİTİK: Token validation
    trimmedToken = fcmToken.trim();
    if (!trimmedToken || trimmedToken.length < 50 || trimmedToken.length > 500) {
      res.status(400).json({
        error: "Geçersiz FCM token formatı (uzunluk 50-500 arası olmalı)",
        tokenLength: trimmedToken.length
      });
      return;
    }

    // Kullanıcı bilgilerini al (platform kontrolü için)
    userDoc = userId
      ? await admin.firestore().collection("users").doc(userId).get()
      : await admin.firestore()
        .collection("users")
        .where("fcmToken", "==", trimmedToken)
        .limit(1)
        .get()
        .then(snapshot => snapshot.docs[0] || null);

    const userData = userDoc?.data();
    const platform = userData?.platform || 'unknown';

    // Test bildirimi gönder - iOS için %100 uyumlu APNs payload
    const message: admin.messaging.Message = {
      token: trimmedToken,
      notification: {
        title: "🧪 TEST BİLDİRİMİ",
        body: "TEST BİLDİRİMİ GELDİ Mİ?",
      },
      data: {
        type: "test",
        message: "Bu bir test bildirimidir",
        timestamp: new Date().toISOString(),
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: "🧪 TEST BİLDİRİMİ",
              body: "TEST BİLDİRİMİ GELDİ Mİ?",
            },
            sound: "default",
            badge: 1,
            "content-available": 1,
            "mutable-content": 1,
            category: "TEST_CATEGORY",
          },
        },
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
          "apns-expiration": "0",
          "apns-topic": "com.canlipazar.app",
        },
        fcmOptions: {
          analyticsLabel: "test_notification",
        },
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "default",
          sound: "default",
          priority: "high" as const,
          notificationCount: 1,
        },
      },
    };

    console.log(`📤 Test bildirimi gönderiliyor...`);
    console.log(`📱 Token: ${trimmedToken.substring(0, 20)}...`);
    console.log(`📱 Platform: ${platform}`);

    const response = await admin.messaging().send(message);

    console.log(`✅ Test bildirimi başarıyla gönderildi: ${response}`);
    console.log(`✅ Platform: ${platform}`);

    res.status(200).json({
      success: true,
      message: "Test bildirimi gönderildi",
      messageId: response,
      token: trimmedToken.substring(0, 20) + "...",
      platform: platform,
      tokenLength: trimmedToken.length,
    });
  } catch (error: any) {
    console.error("❌ Test bildirimi gönderme hatası:", error);
    console.error(`❌ Hata kodu: ${error.code || 'UNKNOWN'}`);
    console.error(`❌ Hata mesajı: ${error.message || 'Bilinmeyen hata'}`);

    // Token geçersizse detaylı log
    if (error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered') {
      if (trimmedToken) {
        console.error(`❌ Token geçersiz veya kayıtlı değil: ${trimmedToken.substring(0, 20)}...`);
      } else {
        console.error(`❌ Token geçersiz veya kayıtlı değil: (token bulunamadı)`);
      }

      // Geçersiz token'ı Firestore'dan sil
      if (userDoc?.exists) {
        try {
          await admin.firestore().collection('users').doc(userDoc.id).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          console.log(`✅ Geçersiz token Firestore'dan silindi: ${userDoc.id}`);
        } catch (deleteError) {
          console.error(`❌ Token silme hatası: ${deleteError}`);
        }
      }
    }

    res.status(500).json({
      error: "Test bildirimi gönderilemedi",
      code: error.code || 'UNKNOWN',
      message: error.message || 'Bilinmeyen hata',
      details: error.stack || 'Stack trace yok',
    });
  }
});

