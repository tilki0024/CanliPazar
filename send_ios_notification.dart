import 'package:firebase_core/firebase_core.dart';
import 'package:animal_trade/services/ios_notification_service.dart';
import 'package:animal_trade/firebase_options.dart';

/// iOS kullanıcılarına özel bildirim göndermek için script
/// 
/// Kullanım:
///   dart run send_ios_notification.dart
/// 
/// Bu script sadece iOS kullanıcılarına "CanlıPazar ile pazar artık elinizde" bildirimi gönderir
Future<void> main() async {
  print('🚀 iOS özel bildirim gönderme script\'i başlatılıyor...');
  
  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase başlatıldı');
    
    // iOS bildirim servisini kullan
    final iosNotificationService = IOSNotificationService();
    
    print('📱 iOS kullanıcılarına bildirim gönderiliyor...');
    print('   Mesaj: "CanlıPazar ile pazar artık elinizde"');
    print('');
    
    final result = await iosNotificationService.sendIOSOnlyNotification();
    
    print('');
    print('📊 Sonuç:');
    print('   - Başarılı: ${result['success']}');
    print('   - Mesaj: ${result['message']}');
    print('   - Gönderilen: ${result['sentCount']}');
    print('   - Başarısız: ${result['failedCount']}');
    print('   - Toplam Kullanıcı: ${result['totalUsers']}');
    print('');
    
    if (result['success'] == true) {
      print('✅ Bildirimler başarıyla gönderildi!');
    } else {
      print('❌ Bildirim gönderme başarısız!');
    }
  } catch (e, stackTrace) {
    print('❌ Hata: $e');
    print('❌ Stack trace: $stackTrace');
  }
}







