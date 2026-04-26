import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Sohbet Servisi
/// Tüm sohbet işlemlerini yönetir
class ChatService {
  // KRİTİK: Lazy getter kullan - instance'ı hemen başlatma
  // Bu, Firestore settings'in AppDelegate'te ayarlanması için zaman tanır
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mevcut kullanıcı ID'sini al
  String? get currentUserId => _auth.currentUser?.uid;

  /// Chat ID oluştur (her zaman aynı sırada)
  String _generateChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Sohbet listesini gerçek zamanlı dinle
  /// Sadece silinmemiş sohbetleri döndürür
  /// Yeni mesaj geldiğinde sohbet otomatik olarak en üste çıkar (lastMessageTime descending)
  Stream<List<ChatModel>> getChatsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true) // En yeni mesaj önce
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) {
            try {
              final chat = ChatModel.fromFirestore(doc, userId);
              // Silinmemiş sohbetleri döndür
              if (chat.isDeleted) return null;
              return chat;
            } catch (e) {
              print('❌ Chat parse hatası: $e');
              return null;
            }
          })
          .where((chat) => chat != null)
          .cast<ChatModel>()
          .toList();
      
      // Ekstra güvenlik: lastMessageTime'e göre tekrar sırala
      chats.sort((a, b) {
        if (a.lastMessageTime != null && b.lastMessageTime != null) {
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        }
        if (a.lastMessageTime != null) return -1;
        if (b.lastMessageTime != null) return 1;
        return 0;
      });
      
      return chats;
    });
  }

  /// Belirli bir sohbeti al
  Future<ChatModel?> getChat(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final chatId = _generateChatId(userId, otherUserId);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .get();

      if (!doc.exists) return null;

      return ChatModel.fromFirestore(doc, userId);
    } catch (e) {
      print('❌ Chat alma hatası: $e');
      return null;
    }
  }

  /// Mesaj gönder
  /// Sohbet yoksa oluşturur, varsa günceller
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String? postId,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    if (text.trim().isEmpty) {
      throw Exception('Mesaj boş olamaz');
    }

    final chatId = _generateChatId(senderId, receiverId);
    final now = DateTime.now();

    try {
      // Batch işlem başlat
      final batch = _firestore.batch();

      // 1. Mesajı ekle (her iki kullanıcının messages koleksiyonuna)
      final messageRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text.trim(),
        timestamp: now,
        isRead: true, // Gönderen için okundu
        postId: postId,
      );

      batch.set(messageRef, message.toFirestore());

      // Alıcının messages koleksiyonuna da ekle
      final receiverMessageRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageRef.id);

      final receiverMessage = message.copyWith(isRead: false); // Alıcı için okunmadı
      batch.set(receiverMessageRef, receiverMessage.toFirestore());

      // 2. Gönderen için sohbeti oluştur/güncelle
      final senderChatRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(chatId);

      final senderChatData = {
        'participants': [senderId, receiverId]..sort(),
        'otherUserId': receiverId,
        'lastMessage': text.trim(),
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCount': 0, // Gönderen için okunmamış yok
        'deletedBy': FieldValue.arrayRemove([senderId]), // Silinmişse geri getir
        'updatedAt': Timestamp.fromDate(now),
      };

      batch.set(senderChatRef, senderChatData, SetOptions(merge: true));

      // 3. Alıcı için sohbeti oluştur/güncelle
      final receiverChatRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(chatId);

      // Alıcının okunmamış mesaj sayısını artır
      final receiverChatDoc = await receiverChatRef.get();
      final currentUnreadCount = receiverChatDoc.exists
          ? (receiverChatDoc.data()?['unreadCount'] as int? ?? 0)
          : 0;

      final receiverChatData = {
        'participants': [senderId, receiverId]..sort(),
        'otherUserId': senderId,
        'lastMessage': text.trim(),
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCount': currentUnreadCount + 1, // Okunmamış mesaj sayısını artır
        'deletedBy': FieldValue.arrayRemove([receiverId]), // Silinmişse geri getir
        'updatedAt': Timestamp.fromDate(now),
      };

      batch.set(receiverChatRef, receiverChatData, SetOptions(merge: true));

      // 4. Alıcının kullanıcı bilgilerini al (sohbet listesinde gösterilmek için)
      final receiverUserDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();

      if (receiverUserDoc.exists) {
        final receiverData = receiverUserDoc.data()!;
        batch.update(senderChatRef, {
          'otherUserName': receiverData['username'] as String?,
          'otherUserPhotoUrl': receiverData['photoUrl'] as String?,
        });
      }

      // Gönderenin kullanıcı bilgilerini al
      final senderUserDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();

      if (senderUserDoc.exists) {
        final senderData = senderUserDoc.data()!;
        batch.update(receiverChatRef, {
          'otherUserName': senderData['username'] as String?,
          'otherUserPhotoUrl': senderData['photoUrl'] as String?,
        });
      }

      // Batch işlemi tamamla
      await batch.commit();

      print('✅ Mesaj gönderildi: $chatId');
    } catch (e) {
      print('❌ Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  /// Mesajları gerçek zamanlı dinle
  Stream<List<MessageModel>> getMessagesStream(String otherUserId) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    final chatId = _generateChatId(userId, otherUserId);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Eski mesajlar önce
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MessageModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Message parse hatası: $e');
              return null;
            }
          })
          .where((message) => message != null)
          .cast<MessageModel>()
          .toList();
    });
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final chatId = _generateChatId(userId, otherUserId);

    try {
      // Okunmamış mesajları bul
      final unreadMessages = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Batch işlem
      final batch = _firestore.batch();
      int unreadCount = 0;

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
        unreadCount++;
      }

      // Sohbetin unreadCount'unu güncelle
      final chatRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId);

      batch.update(chatRef, {
        'unreadCount': FieldValue.increment(-unreadCount),
      });

      await batch.commit();

      print('✅ $unreadCount mesaj okundu olarak işaretlendi');
    } catch (e) {
      print('❌ Mesaj okundu işaretleme hatası: $e');
    }
  }

  /// Sohbeti sil (sadece kullanıcı tarafından)
  Future<void> deleteChat(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final chatId = _generateChatId(userId, otherUserId);

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({
        'deletedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sohbet silindi: $chatId');
    } catch (e) {
      print('❌ Sohbet silme hatası: $e');
      rethrow;
    }
  }

  /// Sohbeti geri getir (silinmiş sohbeti geri yükle)
  Future<void> restoreChat(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final chatId = _generateChatId(userId, otherUserId);

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({
        'deletedBy': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sohbet geri getirildi: $chatId');
    } catch (e) {
      print('❌ Sohbet geri getirme hatası: $e');
    }
  }
}

