import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation Summary Model
/// Sohbet listesi için optimize edilmiş özet bilgiler
class ConversationSummary {
  final String conversationId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? postId;
  final bool isDeleted; // Kullanıcı tarafından silinmiş mi?
  final List<String> users;

  ConversationSummary({
    required this.conversationId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.postId,
    this.isDeleted = false,
    required this.users,
  });

  /// Firestore'dan ConversationSummary oluştur
  factory ConversationSummary.fromFirestore(
    DocumentSnapshot doc,
    String currentUserId,
  ) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Conversation data is null');
    }

    // Diğer kullanıcı ID'sini bul
    final users = List<String>.from(data['users'] ?? []);
    final otherUserId = users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Silinmiş mi kontrol et
    final deletedBy = List<dynamic>.from(data['deletedBy'] ?? []);
    final isDeleted = deletedBy.contains(currentUserId);

    // KRİTİK: Kullanıcı bazlı unreadCounts yapısı
    // Yeni yapı: unreadCounts: { userId: number }
    // Eski yapı (geriye uyumluluk): unreadCount: number
    int unreadCount = 0;
    if (data['unreadCounts'] != null && data['unreadCounts'] is Map) {
      // Yeni yapı: unreadCounts kullan
      final unreadCounts = data['unreadCounts'] as Map<String, dynamic>;
      unreadCount = (unreadCounts[currentUserId] as int?) ?? 0;
    } else if (data['unreadCount'] != null) {
      // Eski yapı (geriye uyumluluk): unreadCount kullan
      // Ancak bu kullanıcı bazlı değil, bu yüzden sadece alıcı için sayıyoruz
      // Eğer currentUserId sender ise 0, recipient ise unreadCount değerini kullan
      final recipientId = data['recipient'] as String?;
      if (currentUserId == recipientId) {
        unreadCount = (data['unreadCount'] as int?) ?? 0;
      } else {
        unreadCount = 0; // Gönderen için unreadCount 0
      }
    }

    return ConversationSummary(
      conversationId: doc.id,
      otherUserId: otherUserId,
      otherUserName: data['otherUserName'] as String?,
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate(),
      unreadCount: unreadCount,
      postId: data['postId'] as String?,
      isDeleted: isDeleted,
      users: users,
    );
  }

  /// Firestore'a kaydetmek için Map'e çevir
  Map<String, dynamic> toFirestore() {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhotoUrl': otherUserPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCount': unreadCount,
      'postId': postId,
      'users': users,
    };
  }

  /// ConversationSummary'i kopyala ve güncelle
  ConversationSummary copyWith({
    String? conversationId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? postId,
    bool? isDeleted,
    List<String>? users,
  }) {
    return ConversationSummary(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      postId: postId ?? this.postId,
      isDeleted: isDeleted ?? this.isDeleted,
      users: users ?? this.users,
    );
  }
}

