import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// iOS FCM Bildirim Test Script'i
/// 
/// Bu script iOS'ta FCM bildirimlerinin çalışıp çalışmadığını test eder.
/// 
/// Kullanım:
/// 1. Uygulamayı iOS cihazda çalıştırın
/// 2. Bu script'i çalıştırın
/// 3. FCM token'ı kontrol edin
/// 4. Test bildirimi gönderin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 iOS FCM Bildirim Test Script Başlatılıyor...\n');
  
  // Firebase Auth kontrolü
  final auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  
  if (user == null) {
    print('❌ Kullanıcı giriş yapmamış. Lütfen önce giriş yapın.');
    return;
  }
  
  print('✅ Kullanıcı giriş yapmış: ${user.uid}\n');
  
  // FCM token kontrolü
  final messaging = FirebaseMessaging.instance;
  
  try {
    // FCM token'ı al
    String? token = await messaging.getToken();
    
    if (token == null || token.isEmpty) {
      print('❌ FCM token alınamadı!');
      print('⚠️  Kontrol edin:');
      print('   1. iOS cihazda çalıştırdığınızdan emin olun (Simulator çalışmaz)');
      print('   2. Bildirim izni verildiğinden emin olun');
      print('   3. AppDelegate.swift\'te token alımı doğru yapılandırılmış mı kontrol edin');
      return;
    }
    
    print('✅ FCM Token alındı: ${token.substring(0, 20)}...\n');
    
    // Firestore'da token kontrolü
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    
    // storedToken'ı daha üst scope'ta tanımla
    String? storedToken;
    
    if (!userDoc.exists) {
      print('⚠️  Kullanıcı dokümanı Firestore\'da bulunamadı');
    } else {
      final userData = userDoc.data()!;
      storedToken = userData['fcmToken'] as String?;
      final platform = userData['platform'] as String?;
      final tokenUpdatedAt = userData['fcmTokenUpdatedAt'] as Timestamp?;
      
      print('📋 Firestore Token Bilgileri:');
      print('   Token: ${storedToken != null ? storedToken.substring(0, 20) + "..." : "YOK"}');
      print('   Platform: $platform');
      print('   Güncellenme: ${tokenUpdatedAt != null ? tokenUpdatedAt.toDate() : "YOK"}');
      
      if (storedToken == null || storedToken != token) {
        print('\n⚠️  Firestore\'daki token ile mevcut token eşleşmiyor!');
        print('   Token güncelleniyor...');
        
        await firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': 'ios',
        });
        
        print('✅ Token Firestore\'a kaydedildi');
        // Token güncellendi, storedToken'ı da güncelle
        storedToken = token;
      } else {
        print('\n✅ Firestore\'daki token ile mevcut token eşleşiyor');
      }
    }
    
    // Bildirim izni kontrolü
    final settings = await messaging.getNotificationSettings();
    print('\n📱 Bildirim İzin Durumu:');
    print('   Authorization Status: ${settings.authorizationStatus}');
    print('   Alert: ${settings.alert}');
    print('   Badge: ${settings.badge}');
    print('   Sound: ${settings.sound}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('✅ Bildirim izni verilmiş');
    } else {
      print('❌ Bildirim izni verilmemiş!');
      print('   Lütfen uygulama ayarlarından bildirim izni verin');
    }
    
    // APNs token kontrolü (iOS için)
    print('\n📱 APNs Token Kontrolü:');
    print('   Not: APNs token AppDelegate.swift\'te alınır ve FCM\'e verilir');
    print('   Xcode console loglarını kontrol edin:');
    print('   "✅ APNs token alındı ve FCM\'e verildi" mesajını arayın');
    
    // Test özeti
    print('\n📊 TEST ÖZETİ:');
    print('   ✅ FCM Token: Mevcut');
    print('   ${storedToken != null && storedToken == token ? "✅" : "⚠️ "} Firestore Token: ${storedToken != null && storedToken == token ? "Eşleşiyor" : "Eşleşmiyor"}');
    print('   ${settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional ? "✅" : "❌"} Bildirim İzni: ${settings.authorizationStatus}');
    
    print('\n📝 SONRAKI ADIMLAR:');
    print('   1. Firebase Console\'da Cloud Messaging > Send test message');
    print('   2. FCM token\'ı kopyalayın: $token');
    print('   3. Test mesajı gönderin');
    print('   4. Bildirim gelip gelmediğini kontrol edin');
    
    print('\n✅ Test tamamlandı!');
    
  } catch (e, stackTrace) {
    print('❌ Hata oluştu: $e');
    print('Stack trace: $stackTrace');
  }
}































