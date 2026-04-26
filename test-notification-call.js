/**
 * Test bildirimi göndermek için HTTP callable function çağırma scripti
 * Kullanım: node test-notification-call.js
 */

const https = require('https');

// Firebase Project ID
const PROJECT_ID = 'canlipazar-b3697';
const REGION = 'us-central1';

// Cloud Function URL
const FUNCTION_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/sendTestNotification`;

// Test bildirimi gönder (userId parametresi opsiyonel)
function sendTestNotification(userId = null) {
  const data = JSON.stringify({
    data: {
      userId: userId,
      message: "TEST BİLDİRİMİ GELDİ Mİ?",
    },
  });

  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  console.log('📤 Test bildirimi gönderiliyor...');
  console.log(`🔗 URL: ${FUNCTION_URL}`);
  console.log(`📝 Data: ${data}`);

  const req = https.request(FUNCTION_URL, options, (res) => {
    let responseData = '';

    res.on('data', (chunk) => {
      responseData += chunk;
    });

    res.on('end', () => {
      try {
        const result = JSON.parse(responseData);
        if (result.result) {
          console.log('✅ Test bildirimi başarıyla gönderildi!');
          console.log(`📊 Sonuç: ${JSON.stringify(result.result, null, 2)}`);
        } else {
          console.error('❌ Hata:', result.error || responseData);
        }
      } catch (e) {
        console.error('❌ Response parse hatası:', e);
        console.log('📄 Raw response:', responseData);
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
const userId = process.argv[2] || null;
sendTestNotification(userId);

