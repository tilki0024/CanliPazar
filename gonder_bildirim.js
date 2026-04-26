// CanlıPazar Toplu Bildirim Gönderme Scripti (Node.js)
// Kullanım: node gonder_bildirim.js

const https = require('https');

const FUNCTION_URL = 'us-central1-canlipazar-b3697.cloudfunctions.net';
const FUNCTION_PATH = '/sendNotificationToAllPlatforms';

const notificationData = {
  title: "CanlıPazar'da ilan verin",
  body: "Binlerce müşteriye ulaşın",
  data: {
    type: "promotion"
  }
};

const postData = JSON.stringify(notificationData);

const options = {
  hostname: FUNCTION_URL,
  path: FUNCTION_PATH,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': postData.length
  }
};

console.log('📢 CanlıPazar Toplu Bildirim Gönderiliyor...');
console.log('');
console.log('📋 Başlık:', notificationData.title);
console.log('📋 Mesaj:', notificationData.body);
console.log('');
console.log('⏳ Gönderiliyor...');

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('');
    console.log('📊 Sonuç:');
    try {
      const json = JSON.parse(data);
      console.log(JSON.stringify(json, null, 2));
      
      if (json.success) {
        console.log('');
        console.log('✅ Başarılı!');
        console.log(`   📊 Toplam: ${json.stats.total} kullanıcı`);
        console.log(`   ✅ Gönderilen: ${json.stats.sent}`);
        console.log(`   ❌ Başarısız: ${json.stats.failed}`);
      } else {
        console.log('');
        console.log('❌ Hata:', json.message);
      }
    } catch (e) {
      console.log(data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Hata:', error.message);
});

req.write(postData);
req.end();





























