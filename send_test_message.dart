import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // Gönderen kullanıcı ID'si (mevcut kullanıcı - bunu değiştirmeniz gerekebilir)
  // Şimdilik test için rastgele bir ID kullanıyoruz
  final senderId = 'TEST_SENDER_${DateTime.now().millisecondsSinceEpoch}';
  final receiverId = 'CtBc8p5lhaSgQDv3oI9jfUwMAmS2';
  
  // Conversation ID oluştur
  final conversationId = senderId.compareTo(receiverId) <= 0
      ? "$senderId-$receiverId"
      : "$receiverId-$senderId";
  
  final messageText = 'Merhaba! Bu otomatik bir test mesajıdır.';
  
  print('📤 Mesaj gönderiliyor...');
  print('Gönderen: $senderId');
  print('Alıcı: $receiverId');
  print('Mesaj: $messageText');
  print('Conversation ID: $conversationId');
  
  try {
    // Mesajı conversations koleksiyonuna ekle
    final messageRef = await firestore.collection("conversations").add({
      "text": messageText,
      "sender": senderId,
      "recipient": receiverId,
      "timestamp": FieldValue.serverTimestamp(),
      "messagesId": conversationId,
      "users": [senderId, receiverId],
      "postId": "",
      "isRead": false,
      "senderName": "Test Kullanıcı",
      "notificationTitle": "Test Kullanıcı",
      "notificationBody": messageText,
    });
    
    // Alıcının unreadMessageCount'unu artır
    await firestore.collection('users').doc(receiverId).update({
      'unreadMessageCount': FieldValue.increment(1),
    });
    
    print('✅ Mesaj başarıyla gönderildi!');
    print('Message ID: ${messageRef.id}');
  } catch (e) {
    print('❌ Hata: $e');
  }
}

