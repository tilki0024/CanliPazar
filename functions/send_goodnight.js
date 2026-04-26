/**
 * iOS Kullanıcılarına "İyi Geceler" Bildirimi Gönderme Script'i
 * 
 * Kullanım:
 * cd functions
 * node send_goodnight.js
 */

const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat (functions ortamında otomatik yapılandırılır)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

async function sendGoodNightNotification() {
  try {
    console.log('🌙 iOS kullanıcılarına "İyi Geceler" bildirimi gönderiliyor...\n');

    // iOS kullanıcılarının FCM token'larını al
    let usersSnapshot;
    
    try {
      // Önce platform='ios' olanları al
      usersSnapshot = await db
        .collection('users')
        .where('platform', '==', 'ios')
        .where('fcmToken', '!=', null)
        .get();
      
      console.log(`📱 Platform='ios' olan ${usersSnapshot.size} kullanıcı bulundu`);
    } catch (error) {
      // Platform field yoksa veya index yoksa, tüm kullanıcıları al
      console.log('⚠️  Platform field sorgusu başarısız, tüm kullanıcılar kontrol ediliyor...');
      usersSnapshot = await db
        .collection('users')
        .where('fcmToken', '!=', null)
        .limit(1000) // Limit ekle
        .get();
    }

    if (usersSnapshot.empty) {
      console.log('⚠️  FCM token\'ı olan kullanıcı bulunamadı');
      return;
    }

    // Token'ları topla (iOS kullanıcılarını filtrele)
    const tokens = [];
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
      return;
    }

    console.log(`✅ ${tokens.length} geçerli FCM token bulundu`);
    console.log(`   - iOS kullanıcıları: ${iosUserCount}`);
    console.log(`   - Platform bilgisi olmayan: ${otherUserCount}\n`);

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

    console.log('📤 Bildirimler gönderiliyor...\n');

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
                `   ❌ Token hatası: ${batchTokens[idx].substring(0, 20)}... - ` +
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
    console.error('Stack trace:', error.stack);
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































