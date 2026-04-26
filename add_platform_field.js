/**
 * Platform Alanı Ekleme Scripti
 * 
 * Bu script, Firestore'daki kullanıcı dokümanlarına platform alanını ekler.
 * 
 * Kullanım:
 * 1. Firebase CLI ile giriş yapın: firebase login
 * 2. Bu scripti çalıştırın: node add_platform_field.js
 * 
 * NOT: Bu script tüm kullanıcıları günceller. Dikkatli kullanın!
 */

const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat
const serviceAccount = require('./functions/serviceAccountKey.json'); // Firebase Console'dan indirin

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addPlatformField() {
  try {
    console.log('🔄 Platform alanı ekleniyor...\n');

    // Tüm kullanıcıları al
    const usersSnapshot = await db.collection('users').get();

    if (usersSnapshot.empty) {
      console.log('⚠️  Kullanıcı bulunamadı');
      return;
    }

    console.log(`📊 ${usersSnapshot.size} kullanıcı bulundu\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Her kullanıcıyı kontrol et ve güncelle
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;

      try {
        // Platform alanı zaten varsa atla
        if (userData.platform) {
          console.log(`⏭️  ${userId}: Platform zaten var (${userData.platform})`);
          skippedCount++;
          continue;
        }

        // fcmToken varsa, platform'u ekle
        // NOT: Bu script platform'u otomatik belirleyemez, manuel olarak eklemeniz gerekir
        // Veya iOS/Android kontrolü yaparak ekleyebilirsiniz

        // Şimdilik sadece platform alanı yoksa ekleyin (varsayılan: "ios")
        // DİKKAT: Bu varsayılan değer yanlış olabilir!
        // Manuel kontrol yapmanız önerilir

        console.log(`⚠️  ${userId}: Platform alanı yok, manuel ekleme gerekli`);
        console.log(`   💡 Firebase Console'dan manuel olarak ekleyin:`);
        console.log(`   - users/${userId} dokümanını açın`);
        console.log(`   - "Add field" → platform → string → "ios" veya "android"`);
        console.log('');

        // Opsiyonel: Otomatik ekleme (dikkatli kullanın!)
        // await db.collection('users').doc(userId).update({
        //   platform: 'ios' // veya 'android' - manuel kontrol gerekli!
        // });
        // console.log(`✅ ${userId}: Platform eklendi (ios)`);
        // updatedCount++;

      } catch (error) {
        console.error(`❌ ${userId}: Hata - ${error.message}`);
        errorCount++;
      }
    }

    console.log('\n📊 ÖZET:');
    console.log(`   ✅ Güncellenen: ${updatedCount}`);
    console.log(`   ⏭️  Atlanan: ${skippedCount}`);
    console.log(`   ❌ Hata: ${errorCount}`);
    console.log(`   ⚠️  Manuel ekleme gerekli: ${usersSnapshot.size - updatedCount - skippedCount - errorCount}`);

    console.log('\n💡 NOT: Platform alanını manuel olarak eklemeniz önerilir.');
    console.log('   Çünkü script iOS/Android ayrımını yapamaz.');

  } catch (error) {
    console.error('❌ Hata:', error);
  } finally {
    process.exit(0);
  }
}

// Scripti çalıştır
addPlatformField();





























