/**
 * iOS Kullanıcılarına "İyi Geceler" Bildirimi Gönderme Script'i (Firestore üzerinden)
 * 
 * Bu script Firebase Admin SDK kullanmadan, sadece Firestore üzerinden
 * Cloud Functions'ı tetikleyerek bildirim gönderir.
 * 
 * Kullanım:
 * node send_ios_goodnight_firestore.js
 */

const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat (service account key gerekli)
// Alternatif: GOOGLE_APPLICATION_CREDENTIALS environment variable kullan
if (!admin.apps.length) {
  try {
    // Önce serviceAccountKey.json dosyasını dene
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin SDK service account key ile başlatıldı');
  } catch (error) {
    // Service account key yoksa, application default credentials kullan
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log('✅ Firebase Admin SDK application default credentials ile başlatıldı');
  }
}

const db = admin.firestore();
const messaging = admin.messaging();

async function sendGoodNightNotification() {
  try {
    console.log('🌙 iOS kullanıcılarına "İyi Geceler" bildirimi gönderiliyor...\n');

    // iOS kullanıcılarının FCM token'larını al
    // Platform kontrolü yap, eğer platform yoksa tüm kullanıcıları al
    let usersSnapshot;
    
    try {
      usersSnapshot = await db
        .collection('users')
        .where('platform', '==', 'ios')
        .where('fcmToken', '!=', null)
        .get();
    } catch (error) {
      // Platform field yoksa, sadece fcmToken kontrolü yap
      console.log('⚠️  Platform field bulunamadı, tüm kullanıcılar kontrol ediliyor...');
      usersSnapshot = await db
        .collection('users')
        .where('fcmToken', '!=', null)
        .get();
    }

    if (usersSnapshot.empty) {
      console.log('⚠️  FCM token\'ı olan kullanıcı bulunamadı');
      return;
    }

    console.log(`📱 ${usersSnapshot.size} kullanıcı bulundu\n`);

    // Token'ları topla (iOS kullanıcılarını filtrele)
    const tokens = [];
    let iosUserCount = 0;
    
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const platform = userData.platform;
      
      // iOS kullanıcılarını filtrele (platform yoksa hepsini al)
      if ((!platform || platform === 'ios') && fcmToken && fcmToken.trim().length > 0) {
        tokens.push(fcmToken);
        if (platform === 'ios') {
          iosUserCount++;
        }
      }
    });

    if (tokens.length === 0) {
      console.log('⚠️  Geçerli FCM token bulunamadı');
      return;
    }

    console.log(`✅ ${tokens.length} geçerli FCM token bulundu`);
    if (iosUserCount > 0) {
      console.log(`   (${iosUserCount} iOS kullanıcısı, ${tokens.length - iosUserCount} diğer platform)\n`);
    } else {
      console.log(`   (Platform bilgisi olmayan kullanıcılar dahil)\n`);
    }

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
  } finally {
    // Firebase Admin SDK'yı kapat
    if (admin.apps.length > 0) {
      await admin.app().delete();
    }
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































