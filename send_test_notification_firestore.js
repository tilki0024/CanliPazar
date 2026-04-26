/**
 * Firestore'a test ilanı ekleyerek otomatik bildirim sistemini tetikle
 * Bu, onNewAnimalPostCreated Cloud Function'ını tetikleyecek
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Firebase Admin SDK key dosyası gerekli

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://canlipazar-b3697-default-rtdb.europe-west1.firebasedatabase.app'
  });
}

const db = admin.firestore();

async function sendTestNotificationViaNewPost() {
  try {
    console.log('📝 Test ilanı oluşturuluyor...');
    
    // Test için yeni bir ilan oluştur
    const testAnimalData = {
      uid: 'test_user_' + Date.now(), // Test kullanıcı ID'si (kendi ilanı için bildirim almayacak)
      description: '🧪 TEST İLANI - iOS bildirim testi için oluşturuldu',
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

    // Firestore'a test ilanını ekle (bu onNewAnimalPostCreated'i tetikleyecek)
    const docRef = await db.collection('animals').add(testAnimalData);
    
    console.log(`✅ Test ilanı oluşturuldu: ${docRef.id}`);
    console.log('📤 Cloud Function tetikleniyor...');
    console.log('   onNewAnimalPostCreated fonksiyonu çalışacak ve bildirimler gönderilecek');
    console.log('   Her 2 yeni ilanda bir bildirim gönderilecek');
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Test ilanı oluşturma hatası:', error);
    throw error;
  }
}

// Script çalıştırıldığında
sendTestNotificationViaNewPost()
  .then((animalId) => {
    console.log(`\n✅ İşlem tamamlandı! Test ilanı ID: ${animalId}`);
    console.log('📱 Bildirimler birkaç saniye içinde gönderilecek');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Hata:', error);
    process.exit(1);
  });

























