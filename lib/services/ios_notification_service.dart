import 'package:cloud_functions/cloud_functions.dart';

/// iOS kullanıcılarına özel bildirim gönderme servisi
/// "CanlıPazar ile pazar artık elinizde" mesajı
class IOSNotificationService {
  static final IOSNotificationService _instance = IOSNotificationService._internal();
  factory IOSNotificationService() => _instance;
  IOSNotificationService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Sadece iOS kullanıcılarına özel bildirim gönder
  /// 
  /// Bu fonksiyon Cloud Functions'daki sendIOSOnlyNotification fonksiyonunu çağırır
  /// ve sadece iOS kullanıcılarına "CanlıPazar ile pazar artık elinizde" bildirimi gönderir
  Future<Map<String, dynamic>> sendIOSOnlyNotification() async {
    try {
      print('📱 [IOSNotificationService] iOS kullanıcılarına özel bildirim gönderiliyor...');

      final callable = _functions.httpsCallable('sendIOSOnlyNotification');
      
      final result = await callable.call();

      print('✅ [IOSNotificationService] Bildirim gönderme sonucu: $result');
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'sentCount': result.data['sentCount'] ?? 0,
        'failedCount': result.data['failedCount'] ?? 0,
        'totalUsers': result.data['totalUsers'] ?? 0,
      };
    } catch (e, stackTrace) {
      print('❌ [IOSNotificationService] Bildirim gönderme hatası: $e');
      print('❌ [IOSNotificationService] Stack trace: $stackTrace');
      
      return {
        'success': false,
        'message': 'Bildirim gönderme hatası: $e',
        'sentCount': 0,
        'failedCount': 0,
        'totalUsers': 0,
      };
    }
  }
}









