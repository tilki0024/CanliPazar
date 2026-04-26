const admin = require('firebase-admin');
const serviceAccount = require('./functions/serviceAccountKey.json');

// Firebase Admin SDK'yı başlat
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const messaging = admin.messaging();

async function sendIOSOnlyNotification() {
  try {
    console.log('📱 iOS kullanıcılarına özel bildirim gönderiliyor...');
    console.log('   Mesaj: "CanlıPazar ile pazar artık elinizde"');
    console.log('');

    // Tüm iOS kullanıcılarını al
    const iosUsersSnapshot = await db
      .collection('users')
      .where('platform', '==', 'ios')
      .where('fcmToken', '!=', null)
      .get();

    if (iosUsersSnapshot.empty) {
      console.log('⚠️ iOS kullanıcısı bulunamadı');
      return;
    }

    console.log(`📱 ${iosUsersSnapshot.size} iOS kullanıcıya bildirim gönderilecek`);

    // Bildirim payload'ı
    const notification = {
      title: 'CanlıPazar',
      body: 'CanlıPazar ile pazar artık elinizde',
    };

    const notificationData = {
      type: 'ios_special',
      title: notification.title,
      body: notification.body,
    };

    // iOS token'larını topla
    const iosTokens = [];
    const validUserIds = [];

    iosUsersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const userId = doc.id;

      if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim().length > 0) {
        // Token validation (100-200 karakter arası)
        const trimmedToken = fcmToken.trim();
        if (trimmedToken.length >= 100 && trimmedToken.length <= 200) {
          iosTokens.push(trimmedToken);
          validUserIds.push(userId);
        } else {
          console.log(`⚠️ Geçersiz token filtrelendi: ${userId}`);
        }
      }
    });

    if (iosTokens.length === 0) {
      console.log('⚠️ Geçerli iOS token bulunamadı');
      return;
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

      const iosMessage = {
        tokens: batchTokens,
        // iOS için notification field'ını kaldırdık -> APNs payload kullanıyoruz
        // notification: notification,
        data: notificationData,
        // iOS için özel APNs ayarları
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
              category: 'IOS_SPECIAL_CATEGORY',
            },
          },
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
            'apns-expiration': '0',
            'apns-topic': 'com.canlipazar.app',
          },
          fcmOptions: {
            analyticsLabel: 'ios_special_notification',
          },
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(iosMessage);
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
              const errorMessage = resp.error?.message || 'Bilinmeyen hata';
              const userId = batchUserIds[idx];

              console.log(
                `❌ iOS Token hatası (userId: ${userId}): ` +
                `${batchTokens[idx].substring(0, 20)}... - ` +
                `Code: ${errorCode}, Message: ${errorMessage}`
              );

              // Geçersiz token'ı Firestore'dan sil
              if (errorCode === 'messaging/invalid-registration-token' ||
                errorCode === 'messaging/registration-token-not-registered') {
                db.collection('users').doc(userId).update({
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
      } catch (error) {
        console.error(`❌ iOS Batch gönderme hatası:`, error);
        totalFailureCount += batchTokens.length;
      }
    }

    console.log('');
    console.log('📊 Sonuç:');
    console.log(`   - Gönderilen: ${totalSuccessCount}`);
    console.log(`   - Başarısız: ${totalFailureCount}`);
    console.log(`   - Toplam Kullanıcı: ${iosUsersSnapshot.size}`);
    console.log('');

    if (totalSuccessCount > 0) {
      console.log('✅ Bildirimler başarıyla gönderildi!');
    } else {
      console.log('❌ Bildirim gönderme başarısız!');
    }
  } catch (error) {
    console.error('❌ Hata:', error);
  }
}

// Script'i çalıştır
sendIOSOnlyNotification()
  .then(() => {
    console.log('✅ Script tamamlandı');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script hatası:', error);
    process.exit(1);
  });









