/**
 * platform == "unknown" olan kullanıcıları tespit et ve düzelt
 * Bu script Cloud Functions'da çalıştırılabilir veya Firebase Admin SDK ile manuel olarak çalıştırılabilir
 */

import * as admin from "firebase-admin";

/**
 * platform == "unknown" olan kullanıcıları tespit et
 */
export async function findUnknownPlatformUsers(): Promise<string[]> {
  const unknownUserIds: string[] = [];
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

  do {
    let query: admin.firestore.Query = admin.firestore().collection("users");
    
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    
    const usersSnapshot = await query.limit(1000).get();
    
    if (usersSnapshot.empty) {
      break;
    }
    
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const platform = userData.platform;
      
      if (!platform || platform === 'unknown' || platform.trim() === '') {
        unknownUserIds.push(doc.id);
        console.log(`⚠️ Unknown platform kullanıcı bulundu: ${doc.id}, platform: ${platform || 'boş'}`);
      }
    });

    if (usersSnapshot.size > 0) {
      lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
    } else {
      lastDoc = null;
    }
  } while (lastDoc != null);

  return unknownUserIds;
}

/**
 * platform == "unknown" olan kullanıcıların token'larını sil
 * Bu kullanıcılar push bildirimi alamazlar
 */
export async function fixUnknownPlatformUsers(): Promise<{ fixed: number; errors: number }> {
  const unknownUserIds = await findUnknownPlatformUsers();
  let fixed = 0;
  let errors = 0;

  console.log(`📊 Toplam ${unknownUserIds.length} "unknown" platform kullanıcı bulundu`);

  for (const userId of unknownUserIds) {
    try {
      // Token'ı sil - kullanıcı uygulamayı açtığında yeni token kaydedecek
      await admin.firestore().collection('users').doc(userId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
        platform: admin.firestore.FieldValue.delete(),
        fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
        platformFixedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      fixed++;
      console.log(`✅ Kullanıcı düzeltildi: ${userId}`);
    } catch (error) {
      errors++;
      console.error(`❌ Kullanıcı düzeltilemedi: ${userId}, hata: ${error}`);
    }
  }

  console.log(`✅ Toplam ${fixed} kullanıcı düzeltildi, ${errors} hata`);
  return { fixed, errors };
}

/**
 * Cloud Function olarak çalıştırılabilir test function
 */
export const fixUnknownPlatformUsersFunction = async (data: any, context: any) => {
  console.log('🔧 Unknown platform kullanıcıları düzeltme başlatılıyor...');
  const result = await fixUnknownPlatformUsers();
  return result;
};





