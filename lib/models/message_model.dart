import 'package:cloud_firestore/cloud_firestore.dart';

/// Mesaj Modeli
/// Her mesaj için detaylı bilgileri tutar
class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? postId; // İlan ID'si (varsa)

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.postId,
  });

  /// Firestore'dan MessageModel oluştur
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Message data is null');
    }

    return MessageModel(
      messageId: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
      postId: data['postId'] as String?,
    );
  }

  /// Firestore'a kaydetmek için Map'e çevir
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (postId != null) 'postId': postId,
    };
  }

  /// MessageModel'i kopyala ve güncelle
  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? postId,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
    );
  }

  /// Mesajın gönderen kişi tarafından gönderilip gönderilmediğini kontrol et
  bool isSentBy(String userId) {
    return senderId == userId;
  }
}












