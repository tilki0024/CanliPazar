/**
 * Yeni İlan Bildirimi Test Script'i
 * 
 * Bu script yeni bir ilan oluşturarak onNewAnimalPostCreated Cloud Function'ını tetikler
 * ve iOS kullanıcılarına bildirim gönderilmesini test eder.
 */

const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function testNewPostNotification() {
  try {
    console.log('🧪 Yeni ilan bildirimi test ediliyor...\n');

    // Test için yeni bir ilan oluştur
    const testAnimalData = {
      uid: 'test_user_id', // Test kullanıcı ID'si (kendi ilanı için bildirim almayacak)
      description: '🧪 TEST İLANI - Yeni ilan bildirimi testi için oluşturuldu',
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

    console.log('📝 Test ilanı oluşturuluyor...');
    
    // Firestore'a test ilanını ekle (bu onNewAnimalPostCreated'i tetikleyecek)
    const docRef = await db.collection('animals').add(testAnimalData);
    
    console.log(`✅ Test ilanı oluşturuldu: ${docRef.id}`);
    console.log('\n📤 Cloud Function tetikleniyor...');
    console.log('   onNewAnimalPostCreated fonksiyonu çalışacak ve bildirimler gönderilecek');
    console.log('\n⏳ Bildirimlerin gönderilmesi birkaç saniye sürebilir...');
    console.log('   Firebase Console > Functions > Logs bölümünden logları kontrol edebilirsiniz');
    
    // 5 saniye bekle (Cloud Function'ın çalışması için)
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Test ilanını sil (isteğe bağlı - test için bırakılabilir)
    console.log('\n🗑️  Test ilanı siliniyor...');
    await docRef.delete();
    console.log('✅ Test ilanı silindi');
    
    console.log('\n✅ Test tamamlandı!');
    console.log('\n📱 iOS cihazlarda bildirim gelip gelmediğini kontrol edin:');
    console.log('   - "Yeni İlan Eklendi! 🐄" başlıklı bildirim');
    console.log('   - "Yeni ilanlar eklendi, hemen göz at!" içeriği');
    
  } catch (error) {
    console.error('❌ Test hatası:', error);
    console.error('Stack trace:', error.stack);
  } finally {
    // Firebase Admin SDK'yı kapat
    if (admin.apps.length > 0) {
      await admin.app().delete();
    }
  }
}

// Script'i çalıştır
testNewPostNotification()
  .then(() => {
    console.log('\n✅ Script başarıyla tamamlandı');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script hatası:', error);
    process.exit(1);
  });

