/**
 * Tüm kullanıcılara bildirim göndermek için script
 * Kullanım: node send_broadcast_notification.js
 */

const https = require('https');

// Firebase Project ID
const PROJECT_ID = 'canlipazar-b3697';
const REGION = 'us-central1';

// Cloud Function URL
const FUNCTION_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/sendBroadcastNotification`;

// Bildirim gönder
function sendBroadcastNotification(title, body) {
  const data = JSON.stringify({
    title: title || '🎉 iOS Bildirimleri Düzeltildi!',
    body: body || 'iOS bildirim sistemi başarıyla çalışıyor. Test bildirimi alıyorsunuz!'
  });

  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  console.log('📤 Tüm kullanıcılara bildirim gönderiliyor...');
  console.log(`🔗 URL: ${FUNCTION_URL}`);
  console.log(`📝 Başlık: ${data.title || 'Varsayılan'}`);
  console.log(`📝 Mesaj: ${data.body || 'Varsayılan'}`);

  const req = https.request(FUNCTION_URL, options, (res) => {
    let responseData = '';

    res.on('data', (chunk) => {
      responseData += chunk;
    });

    res.on('end', () => {
      try {
        const result = JSON.parse(responseData);
        if (result.success) {
          console.log('✅ Bildirimler başarıyla gönderildi!');
          console.log(`📊 İstatistikler:`);
          console.log(`   - Toplam kullanıcı: ${result.stats?.totalUsers || 'N/A'}`);
          console.log(`   - Token bulunan: ${result.stats?.tokensFound || 'N/A'}`);
          console.log(`   - Başarılı: ${result.stats?.successCount || 'N/A'}`);
          console.log(`   - Başarısız: ${result.stats?.failureCount || 'N/A'}`);
          console.log(`   - iOS: ${result.stats?.iosCount || 'N/A'}`);
          console.log(`   - Android: ${result.stats?.androidCount || 'N/A'}`);
          console.log(`   - Bilinmeyen: ${result.stats?.unknownCount || 'N/A'}`);
        } else {
          console.error('❌ Hata:', result.message || result.error || responseData);
        }
      } catch (e) {
        console.error('❌ Response parse hatası:', e);
        console.log('📄 Raw response:', responseData);
        
        // 404 hatası kontrolü
        if (responseData.includes('404') || responseData.includes('Page not found')) {
          console.error('\n⚠️  Cloud Function deploy edilmemiş görünüyor!');
          console.error('📝 Çözüm: Firebase Functions\'ı deploy edin:');
          console.error('   cd functions && npm run deploy');
        }
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Request hatası:', error);
  });

  req.write(data);
  req.end();
}

// Script çalıştırıldığında
const title = process.argv[2] || '🎉 iOS Bildirimleri Düzeltildi!';
const body = process.argv[3] || 'iOS bildirim sistemi başarıyla çalışıyor. Test bildirimi alıyorsunuz!';

sendBroadcastNotification(title, body);

























