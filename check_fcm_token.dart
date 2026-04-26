import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';

/// FCM Token ve Platform Kontrol Scripti
/// 
/// Bu script iOS telefon için Firestore'da fcmToken ve platform alanlarını kontrol eder.
/// 
/// Kullanım:
/// 1. Terminal'de: dart run check_fcm_token.dart
/// 2. Veya Flutter projesinde: flutter run -d macos lib/check_fcm_token.dart
Future<void> main() async {
  print('🔄 Firebase başlatılıyor...');
  
  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase başlatıldı');
    
    // Mevcut kullanıcıyı al
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('❌ Kullanıcı giriş yapmamış!');
      print('💡 Lütfen önce uygulamada giriş yapın.');
      return;
    }
    
    final userId = currentUser.uid;
    print('👤 Kullanıcı ID: $userId');
    print('📧 Email: ${currentUser.email ?? "Yok"}');
    
    // Firestore'dan kullanıcı dokümanını al
    print('\n🔄 Firestore\'dan kullanıcı verileri alınıyor...');
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (!userDoc.exists) {
      print('❌ Kullanıcı dokümanı Firestore\'da bulunamadı!');
      return;
    }
    
    final userData = userDoc.data()!;
    
    print('\n📊 KULLANICI VERİLERİ:');
    print('=' * 50);
    
    // FCM Token kontrolü
    final fcmToken = userData['fcmToken'];
    if (fcmToken != null && fcmToken is String && fcmToken.isNotEmpty) {
      print('✅ fcmToken: VAR');
      print('   Token (ilk 30 karakter): ${fcmToken.substring(0, fcmToken.length > 30 ? 30 : fcmToken.length)}...');
      print('   Token uzunluğu: ${fcmToken.length} karakter');
    } else {
      print('❌ fcmToken: YOK veya BOŞ');
      print('   ⚠️  Bu sorun bildirimlerin gelmemesine neden olabilir!');
    }
    
    // Platform kontrolü
    final platform = userData['platform'];
    if (platform != null && platform is String && platform.isNotEmpty) {
      print('✅ platform: VAR');
      print('   Platform: $platform');
      
      if (platform.toLowerCase() == 'ios') {
        print('   ✅ iOS platformu doğru kayıtlı');
      } else if (platform.toLowerCase() == 'android') {
        print('   ⚠️  Platform Android olarak kayıtlı (iOS cihaz için yanlış!)');
      } else {
        print('   ⚠️  Platform bilinmeyen değer: $platform');
      }
    } else {
      print('❌ platform: YOK veya BOŞ');
      print('   ⚠️  Bu sorun bildirimlerin gelmemesine neden olabilir!');
    }
    
    // Diğer önemli alanlar
    print('\n📋 DİĞER ALANLAR:');
    print('=' * 50);
    print('   username: ${userData['username'] ?? "Yok"}');
    print('   email: ${userData['email'] ?? "Yok"}');
    print('   country: ${userData['country'] ?? "Yok"}');
    print('   city: ${userData['city'] ?? "Yok"}');
    
    // Sonuç özeti
    print('\n📊 SONUÇ ÖZETİ:');
    print('=' * 50);
    
    final hasToken = fcmToken != null && fcmToken is String && fcmToken.isNotEmpty;
    final hasPlatform = platform != null && platform is String && platform.isNotEmpty;
    final isIOSPlatform = hasPlatform && platform.toLowerCase() == 'ios';
    
    if (hasToken && isIOSPlatform) {
      print('✅ TÜM KONTROLLER BAŞARILI!');
      print('   ✅ fcmToken kayıtlı');
      print('   ✅ platform iOS olarak kayıtlı');
      print('   ✅ Bildirimler çalışmalı');
    } else if (hasToken && !isIOSPlatform) {
      print('⚠️  KISMİ SORUN VAR!');
      print('   ✅ fcmToken kayıtlı');
      print('   ❌ platform iOS değil veya eksik');
      print('   ⚠️  Platform düzeltilmeli');
    } else if (!hasToken && isIOSPlatform) {
      print('⚠️  KISMİ SORUN VAR!');
      print('   ❌ fcmToken eksik');
      print('   ✅ platform iOS olarak kayıtlı');
      print('   ⚠️  Token kaydedilmeli');
    } else {
      print('❌ SORUN VAR!');
      print('   ❌ fcmToken eksik');
      print('   ❌ platform eksik');
      print('   ⚠️  Her ikisi de kaydedilmeli');
    }
    
    // Çözüm önerileri
    if (!hasToken || !isIOSPlatform) {
      print('\n💡 ÇÖZÜM ÖNERİLERİ:');
      print('=' * 50);
      
      if (!hasToken) {
        print('1. iOS uygulamayı kapatıp açın');
        print('2. Giriş yapın');
        print('3. 10 saniye bekleyin (token kaydı için)');
        print('4. Bu scripti tekrar çalıştırın');
      }
      
      if (!isIOSPlatform) {
        print('1. iOS uygulamayı kapatıp açın');
        print('2. Giriş yapın');
        print('3. FCMTokenManager otomatik olarak platform kaydedecek');
        print('4. Bu scripti tekrar çalıştırın');
      }
      
      print('\n📝 Manuel Düzeltme (Geçici):');
      print('   Firebase Console → Firestore → users → $userId');
      print('   - fcmToken alanını ekleyin (token değeri ile)');
      print('   - platform alanını "ios" olarak ayarlayın');
    }
    
  } catch (e, stackTrace) {
    print('❌ HATA: $e');
    print('📋 Stack Trace:');
    print(stackTrace);
  }
}





























