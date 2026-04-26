import 'package:cloud_firestore/cloud_firestore.dart';

/// Sohbet Modeli
/// Her sohbet için temel bilgileri tutar
class ChatModel {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isDeleted; // Kullanıcı tarafından silinmiş mi?
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore'dan ChatModel oluştur
  factory ChatModel.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Chat data is null');
    }

    // Diğer kullanıcı ID'sini bul
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return ChatModel(
      chatId: doc.id,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      otherUserName: data['otherUserName'] as String?,
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: (data['unreadCount'] as int?) ?? 0,
      isDeleted: (data['deletedBy'] as List<dynamic>?)?.contains(currentUserId) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a kaydetmek için Map'e çevir
  Map<String, dynamic> toFirestore(String currentUserId) {
    return {
      'participants': [currentUserId, otherUserId]..sort(),
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhotoUrl': otherUserPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'deletedBy': isDeleted ? [currentUserId] : [],
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// ChatModel'i kopyala ve güncelle
  ChatModel copyWith({
    String? chatId,
    String? currentUserId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      currentUserId: currentUserId ?? this.currentUserId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}












