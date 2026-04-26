/**
 * iOS Kullanıcılarına "İyi Geceler" Bildirimi Gönderme Script'i
 * 
 * Kullanım:
 * node send_ios_goodnight_notification.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Firebase service account key

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const messaging = admin.messaging();

async function sendGoodNightNotification() {
  try {
    console.log('🌙 iOS kullanıcılarına "İyi Geceler" bildirimi gönderiliyor...\n');

    // iOS kullanıcılarının FCM token'larını al
    const usersSnapshot = await db
      .collection('users')
      .where('platform', '==', 'ios')
      .where('fcmToken', '!=', null)
      .get();

    if (usersSnapshot.empty) {
      console.log('⚠️  iOS kullanıcısı bulunamadı');
      return;
    }

    console.log(`📱 ${usersSnapshot.size} iOS kullanıcısı bulundu\n`);

    // Token'ları topla
    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      if (fcmToken && fcmToken.trim().length > 0) {
        tokens.push(fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log('⚠️  Geçerli FCM token bulunamadı');
      return;
    }

    console.log(`✅ ${tokens.length} geçerli FCM token bulundu\n`);

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

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batchTokens = tokens.slice(i, i + batchSize);
      
      const message = {
        tokens: batchTokens,
        notification: notification,
        data: {
          type: data.type,
          timestamp: data.timestamp,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'new_posts_channel',
            sound: 'default',
            priority: 'high',
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
        const response = await messaging.sendEachForMulticast(message);
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
    console.log('\n✅ Bildirim gönderme işlemi tamamlandı!');

  } catch (error) {
    console.error('❌ Hata oluştu:', error);
  } finally {
    // Firebase Admin SDK'yı kapat
    await admin.app().delete();
  }
}

// Script'i çalıştır
sendGoodNightNotification()
  .then(() => {
    console.log('\n✅ Script başarıyla tamamlandı');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script hatası:', error);
    process.exit(1);
  });































