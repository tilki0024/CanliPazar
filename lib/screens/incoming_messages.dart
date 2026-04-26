import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/screens/message_screen.dart';
import '../models/user.dart';
import '../models/conversation_summary.dart';
import '../utils/animal_colors.dart';
import '../utils/safe_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class IncomingMessagesPage extends StatefulWidget {
  final String currentUserUid;

  const IncomingMessagesPage({Key? key, required this.currentUserUid})
      : super(key: key);

  @override
  _IncomingMessagesPageState createState() => _IncomingMessagesPageState();
}

class _IncomingMessagesPageState extends State<IncomingMessagesPage> {
  // Conversation summaries - optimize edilmiş yapı
  Map<String, ConversationSummary> _conversationSummaries = {};
  
  // Pagination için değişkenler
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _limit = 20;
  
  // Stream subscription - gerçek zamanlı güncellemeler için
  StreamSubscription<QuerySnapshot>? _conversationsStreamSubscription;
  
  // Kullanıcı cache'i - performans için
  final Map<String, User> _userCache = {};
  
  // PostId cache'i - hızlı erişim için
  final Map<String, String> _postIdCache = {};
  
  // ScrollController - pagination için listener eklenecek
  final ScrollController _scrollController = ScrollController();

  // Sohbet silme - mesajları silmek yerine hidden olarak işaretle
  // Böylece yeni mesaj geldiğinde tekrar görünsün
  Future<void> _deleteConversation(
      String currentUserUid, String recipientUid) async {
    try {
      print('🗑️ Sohbet silme başlatılıyor: currentUser=$currentUserUid, recipient=$recipientUid');
      
      // Bu kullanıcı ile olan tüm mesajları bul
      QuerySnapshot conversations = await FirebaseFirestore.instance
          .collection("conversations")
          .where("users", arrayContains: currentUserUid)
          .get();
      
      print('📋 Bulunan toplam conversation sayısı: ${conversations.docs.length}');
      
      List<String> conversationIds = [];
      for (var conversation in conversations.docs) {
        final data = conversation.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        List<dynamic> users = (data["users"] as List<dynamic>?) ?? [];
        String sender = (data["sender"] as String?) ?? "";
        String recipient = (data["recipient"] as String?) ?? "";
        
        // Bu kullanıcı ile olan tüm mesajları bul
        if ((users.contains(recipientUid) && users.contains(currentUserUid)) ||
            (sender == recipientUid && recipient == currentUserUid) ||
            (sender == currentUserUid && recipient == recipientUid)) {
          conversationIds.add(conversation.id);
          print('✅ Eşleşen conversation bulundu: ${conversation.id}');
        }
      }
      
      if (conversationIds.isEmpty) {
        print('⚠️ Silinecek conversation bulunamadı');
        return;
      }
      
      print('🔄 ${conversationIds.length} conversation güncelleniyor...');
      
      // Batch işlem ile tüm conversation'ları güncelle
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      // Mesajları silmek yerine deletedBy alanına ekle
      // Sadece silen kullanıcının görünümünden kaldırılacak
      // Karşı tarafın görünümünde kalacak
      for (String conversationId in conversationIds) {
        DocumentReference docRef = FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversationId);
        
        batch.update(docRef, {
          'deletedBy': FieldValue.arrayUnion([currentUserUid]),
        });
      }
      
      // Batch commit - tüm güncellemeleri tek seferde yap
      await batch.commit();
      
      print('✅ ${conversationIds.length} sohbet silindi (deletedBy)');
      
      // UI'ı güncelle - silinmiş sohbeti listeden kaldır
      if (mounted) {
        setState(() {
          _conversationSummaries.remove(recipientUid);
        });
      }
      
      print('✅ Sohbet gizlendi: $recipientUid');
    } catch (e, stackTrace) {
      print('❌ Sohbet silme hatası: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sohbet silinirken bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Scroll listener ekle - pagination için
    _scrollController.addListener(_onScroll);
    
    // KRİTİK: initState'te await kullanma, hemen UI render et
    // İlk yükleme arka planda yapılacak
    _initializeConversations();
  }
  
  /// Conversation'ları başlat - await kullanmadan
  void _initializeConversations() {
    // İlk yükleme - await kullanmadan, hemen UI render et
    _loadMoreConversations();
    
    // Stream subscription - gerçek zamanlı güncellemeler için
    // WhatsApp mantığı: lastMessageTime'a göre sırala (en yeni mesaj önce)
    _conversationsStreamSubscription = FirebaseFirestore.instance
        .collection("conversations")
        .where("users", arrayContains: widget.currentUserUid)
        .orderBy("lastMessageTime", descending: true) // WhatsApp mantığı: lastMessageTime kullan
        .limit(50) // İlk 50 conversation'ı dinle
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      bool hasUpdates = false;
      
      for (var change in snapshot.docChanges) {
        try {
          final data = change.doc.data();
          if (data is! Map<String, dynamic>) continue;
          
          // Silinmiş sohbetleri kontrol et
          final deletedBy = List<dynamic>.from(data["deletedBy"] ?? []);
          if (deletedBy.contains(widget.currentUserUid)) {
            // Silinmiş sohbet - listeden kaldır
            final otherUserId = _getOtherUserId(data);
            if (otherUserId.isNotEmpty) {
              _conversationSummaries.remove(otherUserId);
              hasUpdates = true;
            }
            continue;
          }
          
          // Conversation summary oluştur
          final summary = ConversationSummary.fromFirestore(
            change.doc,
            widget.currentUserUid,
          );
          
          // Yeni mesaj geldiğinde deletedBy'dan kaldır
          if (change.type == DocumentChangeType.added || 
              change.type == DocumentChangeType.modified) {
            final deletedByList = List<dynamic>.from(data["deletedBy"] ?? []);
            if (deletedByList.contains(widget.currentUserUid)) {
              change.doc.reference.update({
                'deletedBy': FieldValue.arrayRemove([widget.currentUserUid]),
              });
            }
          }
          
          // Summary'yi güncelle
          _conversationSummaries[summary.otherUserId] = summary;
          hasUpdates = true;
          
          // PostId cache'e ekle
          if (summary.postId != null && summary.postId!.isNotEmpty) {
            _postIdCache[summary.otherUserId] = summary.postId!;
          }
          
          // Kullanıcı bilgisini arka planda yükle
          if (!_userCache.containsKey(summary.otherUserId)) {
            _loadUserAsync(summary.otherUserId);
          }
        } catch (e) {
          print('❌ Conversation stream hatası: $e');
        }
      }
      
      // UI'yi güncelle
      if (hasUpdates && mounted) {
        setState(() {});
        _updateAppBadgeCount();
      }
    });
  }
  
  /// Diğer kullanıcı ID'sini çıkar
  String _getOtherUserId(Map<String, dynamic> data) {
    final users = List<String>.from(data['users'] ?? []);
    return users.firstWhere(
      (id) => id != widget.currentUserUid,
      orElse: () => '',
    );
  }
  
  /// Kullanıcı bilgisini arka planda yükle
  void _loadUserAsync(String userId) {
    _getUser(userId).then((user) {
      if (mounted && !_userCache.containsKey(userId)) {
        _userCache[userId] = user;
        setState(() {});
      }
    }).catchError((e) {
      print('❌ Kullanıcı yükleme hatası: $e');
    });
  }
  
  // Scroll listener - pagination için
  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore && _hasMore) {
      _loadMoreConversations();
    }
  }

  // Conversation listesini build et - WhatsApp mantığı
  Widget _buildConversationsList() {
    // Conversation summaries'i sırala - WhatsApp mantığı
    // 1. En son mesaj atan kişi her zaman en üstte (lastMessageAt'a göre)
    // 2. Okunmamış mesaj sayısı sadece badge olarak gösterilir, sıralamayı etkilemez
    final summaries = _conversationSummaries.values.toList()
      ..sort((a, b) {
        // WhatsApp mantığı: En son mesaj atan kişi en üstte
        if (a.lastMessageAt != null && b.lastMessageAt != null) {
          return b.lastMessageAt!.compareTo(a.lastMessageAt!); // En yeni önce
        }
        if (a.lastMessageAt != null) return -1;
        if (b.lastMessageAt != null) return 1;
        return 0;
      });

    if (summaries.isEmpty && !_isLoadingMore) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AnimalColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: AnimalColors.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                "Gelen kutunuz boş",
                style: SafeFonts.poppins(
                  color: Color(0xFF212121),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Diğer kullanıcılarla iletişime geçtiğinizde mesajlar burada görünecek",
                textAlign: TextAlign.center,
                style: SafeFonts.poppins(
                  color: Color(0xFF757575),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: summaries.length + (_hasMore && _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator
        if (index == summaries.length) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AnimalColors.primary,
              ),
            ),
          );
        }
        
        final summary = summaries[index];
        final cachedUser = _userCache[summary.otherUserId];
        
        // Kullanıcı cache'de yoksa skeleton göster
        if (cachedUser == null) {
          return _buildConversationItemSkeleton();
        }
        
        return _buildConversationItemFromSummary(summary, cachedUser);
      },
    );
  }

  @override
  void dispose() {
    _conversationsStreamSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getPostIdAndRedirect(String recipientUid) async {
    // Cache'den postId'yi al (hızlı erişim)
    String postId = _postIdCache[recipientUid] ?? "";
    
    // Cache'den kullanıcı bilgisini al (hızlı erişim)
    User? cachedUser = _userCache[recipientUid];
    
    // HEMEN mesaj ekranına git - postId ve kullanıcı cache'den geliyor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(
          currentUserUid: widget.currentUserUid,
          recipientUid: recipientUid,
          postId: postId, // Cache'den gelen postId
          recipientUser: cachedUser, // Cache'den gelen kullanıcı - hemen AppBar'da gösterilir
        ),
      ),
    );
    
    // PostId cache'de yoksa arka planda yükle ve cache'e ekle
    if (postId.isEmpty) {
      try {
        String fetchedPostId = await _getPostId(recipientUid);
        if (fetchedPostId.isNotEmpty) {
          _postIdCache[recipientUid] = fetchedPostId;
          print('✅ PostId cache\'e eklendi: $fetchedPostId');
        }
      } catch (e) {
        print("PostId yükleme hatası (önemli değil): $e");
      }
    }
    
    // Kullanıcı cache'de yoksa arka planda yükle (önemli değil, zaten sayfa açıldı)
    if (cachedUser == null) {
      try {
        User fetchedUser = await _getUser(recipientUid);
        _userCache[recipientUid] = fetchedUser;
        print('✅ Kullanıcı cache\'e eklendi: $recipientUid');
      } catch (e) {
        print("Kullanıcı yükleme hatası (önemli değil): $e");
      }
    }
  }

  // PostId'yi al - önce cache'den, sonra summary'den
  Future<String> _getPostId(String recipientUid) async {
    // Önce cache'den kontrol et
    if (_postIdCache.containsKey(recipientUid)) {
      return _postIdCache[recipientUid]!;
    }
    
    // Summary'den al
    final summary = _conversationSummaries[recipientUid];
    if (summary?.postId != null && summary!.postId!.isNotEmpty) {
      _postIdCache[recipientUid] = summary.postId!;
      return summary.postId!;
    }
    
    // Cache'de yoksa Firestore'dan çek
    try {
      QuerySnapshot conversations = await FirebaseFirestore.instance
          .collection("conversations")
          .where("users", arrayContains: widget.currentUserUid)
          .get();
      for (var conversation in conversations.docs) {
        final data = conversation.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        List<dynamic> users = data["users"] ?? [];
        if (users.contains(recipientUid)) {
          String postId = data["postId"] ?? "";
          if (postId.isNotEmpty) {
            _postIdCache[recipientUid] = postId;
          }
          return postId;
        }
      }
    } catch (e) {
      print('❌ PostId yükleme hatası: $e');
    }
    return "";
  }

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
            color: Color(0xFF212121), // textPrimary
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: AnimalColors.primary),
      ),
      body: Container(
        color: Colors.white,
        child: _buildConversationsList(),
      ),
    );
  }

  // Pagination destekli conversation yükleme - optimize edilmiş
  Future<void> _loadMoreConversations() async {
    if (_isLoadingMore || !_hasMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // WhatsApp mantığı: lastMessageTime'a göre sırala (en yeni mesaj önce)
      Query query = FirebaseFirestore.instance
          .collection("conversations")
          .where("users", arrayContains: widget.currentUserUid)
          .orderBy("lastMessageTime", descending: true) // WhatsApp mantığı: lastMessageTime kullan
          .limit(_limit);

      // Pagination - son dokümandan sonra başla
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot conversationsSnapshot;
      try {
        conversationsSnapshot = await query.get();
      } catch (e) {
        // orderBy hatası - fallback (lastMessageTime yoksa timestamp kullan)
        print('⚠️ lastMessageTime orderBy hatası, fallback kullanılıyor: $e');
        Query fallbackQuery = FirebaseFirestore.instance
            .collection("conversations")
            .where("users", arrayContains: widget.currentUserUid)
            .orderBy("timestamp", descending: true) // Fallback: timestamp kullan
            .limit(_limit);
        
        if (_lastDocument != null) {
          fallbackQuery = fallbackQuery.startAfterDocument(_lastDocument!);
        }
        
        try {
          conversationsSnapshot = await fallbackQuery.get();
        } catch (e2) {
          // Timestamp de yoksa, sıralama olmadan çek
          print('⚠️ timestamp orderBy hatası, sıralama olmadan çekiliyor: $e2');
          Query noOrderQuery = FirebaseFirestore.instance
              .collection("conversations")
              .where("users", arrayContains: widget.currentUserUid)
              .limit(_limit);
          
          if (_lastDocument != null) {
            noOrderQuery = noOrderQuery.startAfterDocument(_lastDocument!);
          }
          
          conversationsSnapshot = await noOrderQuery.get();
          
          // Manuel sıralama - önce lastMessageTime, sonra timestamp
          conversationsSnapshot.docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            
            // Önce lastMessageTime'a göre sırala
            final aLastMsgTime = aData?['lastMessageTime'] as Timestamp?;
            final bLastMsgTime = bData?['lastMessageTime'] as Timestamp?;
            if (aLastMsgTime != null && bLastMsgTime != null) {
              return bLastMsgTime.compareTo(aLastMsgTime);
            }
            if (aLastMsgTime != null) return -1;
            if (bLastMsgTime != null) return 1;
            
            // lastMessageTime yoksa timestamp'e göre sırala
            final aTs = aData?['timestamp'] as Timestamp?;
            final bTs = bData?['timestamp'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
        }
      }

      if (!mounted) return;

      if (conversationsSnapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      _lastDocument = conversationsSnapshot.docs.last;

      // Conversation summaries'i parse et - N+1 query yok!
      final Set<String> userIds = {};
      
      for (var doc in conversationsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          
          // Silinmiş sohbetleri atla
          final deletedBy = List<dynamic>.from(data["deletedBy"] ?? []);
          if (deletedBy.contains(widget.currentUserUid)) {
            continue;
          }
          
          // Conversation summary oluştur
          final summary = ConversationSummary.fromFirestore(doc, widget.currentUserUid);
          
          // Summary'yi ekle/güncelle
          _conversationSummaries[summary.otherUserId] = summary;
          userIds.add(summary.otherUserId);
          
          // PostId cache'e ekle
          if (summary.postId != null && summary.postId!.isNotEmpty) {
            _postIdCache[summary.otherUserId] = summary.postId!;
          }
        } catch (e) {
          print('❌ Conversation parse hatası: $e');
        }
      }

      // Batch olarak kullanıcı bilgilerini yükle
      await _loadUsersBatch(userIds.toList());
      
      // State'i güncelle
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = conversationsSnapshot.docs.length >= _limit;
        });
      }
      
      // Badge count'u güncelle
      _updateAppBadgeCount();
      
    } catch (e) {
      print("❌ Conversation yükleme hatası: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  
  // Batch olarak kullanıcı bilgilerini yükle - performans için
  Future<void> _loadUsersBatch(List<String> userIds) async {
    if (userIds.isEmpty) {
      print('⚠️ Yüklenecek kullanıcı yok');
      return;
    }
    
    try {
      // Cache'de olmayan kullanıcıları filtrele
      List<String> uncachedIds = userIds.where((uid) => !_userCache.containsKey(uid)).toList();
      
      print('👥 ${uncachedIds.length} kullanıcı bilgisi yüklenecek');
      
      if (uncachedIds.isEmpty) {
        print('✅ Tüm kullanıcılar cache\'de');
        return;
      }
      
      // Batch olarak yükle (Firestore'da whereIn ile max 10, bu yüzden chunk'lara böl)
      for (int i = 0; i < uncachedIds.length; i += 10) {
        List<String> chunk = uncachedIds.skip(i).take(10).toList();
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        print('👥 ${userSnapshot.docs.length} kullanıcı bilgisi yüklendi');
        
        for (DocumentSnapshot doc in userSnapshot.docs) {
          try {
            User user = User.fromSnap(doc);
            _userCache[doc.id] = user;
            print('✅ Kullanıcı cache\'lendi: ${doc.id} - ${user.username}');
          } catch (e) {
            print('❌ Kullanıcı parse hatası (${doc.id}): $e');
          }
        }
      }
      
      print('✅ Toplam ${_userCache.length} kullanıcı cache\'de');
    } catch (e) {
      print("❌ Error loading users batch: $e");
    }
  }

  // Uygulama ikonunda badge count'u güncelle - optimize edilmiş
  Future<void> _updateAppBadgeCount() async {
    if (kIsWeb) return;
    
    try {
      // Conversation summaries'den toplam okunmamış mesaj sayısını hesapla
      int unreadCount = _conversationSummaries.values
          .fold(0, (sum, summary) => sum + summary.unreadCount);
      
      print('📊 Okunmamış mesaj sayısı: $unreadCount');
      
      // Badge count'u Firestore'da kullanıcıya kaydet (bildirim için)
      if (widget.currentUserUid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserUid)
              .update({
            'unreadMessageCount': unreadCount,
            'unreadMessageCountUpdatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Badge count Firestore\'a kaydedildi: $unreadCount');
        } catch (e) {
          print('❌ Badge count kaydetme hatası: $e');
        }
      }
    } catch (e) {
      print('❌ Badge count güncelleme hatası: $e');
    }
  }



  Future<User> _getUser(String uid) async {
    // Önce cache'den kontrol et
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }
    
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      
      if (!doc.exists) {
        // Kullanıcı yoksa varsayılan kullanıcı döndür
        print('⚠️ Kullanıcı bulunamadı: $uid');
        User defaultUser = User(
          uid: uid,
          username: 'Kullanıcı',
          email: '',
          photoUrl: '',
          bio: '',
          followers: [],
          following: [],
        );
        _userCache[uid] = defaultUser;
        return defaultUser;
      }
      
      User user = User.fromSnap(doc);
      _userCache[uid] = user; // Cache'e ekle
      return user;
    } catch (e) {
      print('❌ Kullanıcı yükleme hatası: $e');
      // Hata durumunda varsayılan kullanıcı döndür
      User defaultUser = User(
        uid: uid,
        username: 'Kullanıcı',
        email: '',
        photoUrl: '',
        bio: '',
        followers: [],
        following: [],
      );
      _userCache[uid] = defaultUser;
      return defaultUser;
    }
  }
  
  // Sohbet öğesi widget'ı - summary'den oluştur
  Widget _buildConversationItemFromSummary(
    ConversationSummary summary,
    User user,
  ) {
    String username = user.username ?? summary.otherUserName ?? "Kullanıcı";
    String profilePhotoUrl = user.photoUrl ?? summary.otherUserPhotoUrl ?? "";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            _getPostIdAndRedirect(summary.otherUserId);
          },
          onLongPress: () {
            _showDeleteDialog(summary.otherUserId, username);
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null,
                  backgroundColor: AnimalColors.secondary.withOpacity(0.2),
                  child: profilePhotoUrl.isEmpty
                      ? Icon(Icons.person,
                          color: AnimalColors.primary, size: 28)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: SafeFonts.poppins(
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        summary.lastMessage ?? 'Mesaj yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SafeFonts.poppins(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  children: [
                    if (summary.lastMessageAt != null)
                      Text(
                        _formatTimestampFromDateTime(summary.lastMessageAt!),
                        style: SafeFonts.poppins(
                          color: Color(0xFF757575),
                          fontSize: 12,
                        ),
                      ),
                    SizedBox(height: 4),
                    // Okunmamış mesaj sayısı badge'i
                    _buildUnreadBadgeFromCount(summary.unreadCount),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatTimestampFromDateTime(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays} gün önce";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours} saat önce";
    } else if (diff.inMinutes >= 1) {
      return "${diff.inMinutes} dakika önce";
    } else {
      return "Az önce";
    }
  }
  
  Widget _buildUnreadBadgeFromCount(int unreadCount) {
    if (unreadCount == 0) {
      return SizedBox.shrink();
    }
    
    return Container(
      width: unreadCount > 9 ? 24 : 20,
      height: 20,
      decoration: BoxDecoration(
        color: Color(0xFF25D366), // WhatsApp yeşili
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: SafeFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  // Yükleme skeleton widget'ı
  Widget _buildConversationItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Silme dialogu
  void _showDeleteDialog(String recipientUid, String username) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
            '$username ile olan sohbeti silmek istediğinize emin misiniz?',
            style: SafeFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: SafeFonts.poppins(
                  color: Color(0xFF757575),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteConversation(widget.currentUserUid, recipientUid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sohbet silindi'),
                      backgroundColor: AnimalColors.primary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                'Sil',
                style: SafeFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}


