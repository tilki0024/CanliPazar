/**
 * Test bildirimi göndermek için script
 * Kullanım: node test-notification.js [userId]
 * Eğer userId verilmezse, ilk bulunan kullanıcıya gönderir
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-adminsdk.json'); // Firebase Admin SDK key dosyası gerekli

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function sendTestNotification(userId = null) {
  try {
    let tokens = [];

    if (userId) {
      // Belirli bir kullanıcıya gönder
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        const token = userData?.fcmToken;
        if (token) {
          tokens.push(token);
          console.log(`✅ Kullanıcı bulundu: ${userId}`);
          console.log(`📱 FCM Token: ${token.substring(0, 20)}...`);
        } else {
          console.error('❌ Kullanıcının FCM token\'ı bulunamadı');
          return;
        }
      } else {
        console.error('❌ Kullanıcı bulunamadı');
        return;
      }
    } else {
      // İlk bulunan kullanıcıya gönder
      const usersSnapshot = await admin.firestore().collection('users')
        .where('fcmToken', '!=', null)
        .limit(1)
        .get();
      
      if (usersSnapshot.empty) {
        console.error('❌ FCM token\'ı olan kullanıcı bulunamadı');
        return;
      }

      usersSnapshot.forEach((doc) => {
        const token = doc.data()?.fcmToken;
        if (token) {
          tokens.push(token);
          console.log(`✅ Kullanıcı bulundu: ${doc.id}`);
          console.log(`📱 FCM Token: ${token.substring(0, 20)}...`);
        }
      });
    }

    if (tokens.length === 0) {
      console.error('❌ FCM token bulunamadı');
      return;
    }

    // Test bildirimi gönder
    const message = {
      token: tokens[0],
      notification: {
        title: "CanlıPazar Test Bildirimi",
        body: "TEST BİLDİRİMİ GELDİ Mİ?",
      },
      data: {
        type: "test",
        message: "TEST BİLDİRİMİ GELDİ Mİ?",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1,
            "mutable-content": 1,
            alert: {
              title: "CanlıPazar Test Bildirimi",
              body: "TEST BİLDİRİMİ GELDİ Mİ?",
            },
            category: "TEST_CATEGORY",
          },
        },
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
      },
    };

    console.log('📤 Test bildirimi gönderiliyor...');
    const response = await admin.messaging().send(message);
    console.log(`✅ Test bildirimi başarıyla gönderildi: ${response}`);
    console.log('📱 Telefonunuzda bildirimi kontrol edin!');
  } catch (error) {
    console.error('❌ Test bildirimi gönderme hatası:', error);
  }
}

// Script çalıştırıldığında
const userId = process.argv[2] || null;
sendTestNotification(userId).then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('❌ Hata:', error);
  process.exit(1);
});









