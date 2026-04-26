import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../utils/animal_colors.dart';
import 'chat_detail_view.dart';

/// Sohbet Listesi Ekranı
/// Tüm sohbetleri listeler, gerçek zamanlı güncellenir
class ChatListView extends StatefulWidget {
  final String currentUserId;

  const ChatListView({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _ChatListViewState createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final ChatService _chatService = ChatService();
  final Map<String, User> _userCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimalColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mesajlar',
          style: SafeFonts.poppins(
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: AnimalColors.primary),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AnimalColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: SafeFonts.poppins(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: AnimalColors.primary.withOpacity(0.5),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Henüz sohbet yok',
                    style: SafeFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Diğer kullanıcılarla iletişime geçtiğinizde\nsohbetler burada görünecek',
                    textAlign: TextAlign.center,
                    style: SafeFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatItem(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    return FutureBuilder<User?>(
      future: _getUser(chat.otherUserId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return Dismissible(
          key: Key(chat.chatId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.red,
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteDialog(chat);
          },
          onDismissed: (direction) {
            _chatService.deleteChat(chat.otherUserId);
          },
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailView(
                    currentUserId: widget.currentUserId,
                    otherUserId: chat.otherUserId,
                    otherUserName: user?.username ?? chat.otherUserName ?? 'Kullanıcı',
                    otherUserPhotoUrl: user?.photoUrl ?? chat.otherUserPhotoUrl,
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Profil Fotoğrafı
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AnimalColors.primary.withOpacity(0.1),
                    backgroundImage: (user?.photoUrl != null &&
                            user!.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: (user?.photoUrl == null ||
                            user!.photoUrl!.isEmpty)
                        ? Icon(
                            Icons.person,
                            color: AnimalColors.primary,
                            size: 28,
                          )
                        : null,
                  ),
                  SizedBox(width: 12),
                  // Mesaj Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?.username ?? chat.otherUserName ?? 'Kullanıcı',
                                style: SafeFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.lastMessageTime != null)
                              Text(
                                _formatTime(chat.lastMessageTime!),
                                style: SafeFonts.poppins(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.lastMessage ?? 'Mesaj yok',
                                style: SafeFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.unreadCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AnimalColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  chat.unreadCount > 99
                                      ? '99+'
                                      : chat.unreadCount.toString(),
                                  style: SafeFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<User?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final user = User.fromSnap(doc);
      _userCache[userId] = user;
      return user;
    } catch (e) {
      print('❌ Kullanıcı yükleme hatası: $e');
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Bugün
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Dün
      return 'Dün';
    } else if (difference.inDays < 7) {
      // Bu hafta
      return DateFormat('EEEE', 'tr_TR').format(dateTime);
    } else {
      // Daha eski
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Future<bool> _showDeleteDialog(ChatModel chat) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Sohbeti Sil',
              style: SafeFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Bu sohbeti silmek istediğinize emin misiniz?',
              style: SafeFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'İptal',
                  style: SafeFonts.poppins(
                    color: Color(0xFF757575),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Sil',
                  style: SafeFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}












