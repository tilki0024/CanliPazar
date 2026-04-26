import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_post.dart';
import 'message_screen.dart';
import 'profile_screen2.dart';
import '../utils/safe_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transporter.dart';
import '../services/transporter_service.dart';
import '../services/dynamic_link_service.dart';
import 'transporter_list_screen.dart';
import 'transporter_detail_screen.dart';
import '../utils/animal_firestore_filters.dart';

class AnimalDetailScreen extends StatefulWidget {
  final AnimalPost animal;

  const AnimalDetailScreen({Key? key, required this.animal}) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  String? _currentUserId;
  late PageController _pageController;
  Map<String, dynamic>? _sellerData;
  bool _sellerLoading = true;
  List<Transporter> _nearbyTransporters = [];
  bool _transportersLoading = true;

  // ProfileScreen2 renk paleti
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  bool _hasIncrementedView = false; // Aynı sayfa açılışında sadece 1 kez artır

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchSellerData();
    _fetchNearbyTransporters();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initFavoriteState();

    // Sayfa açıldığında görüntülenme sayısını artır (sadece 1 kez) + görselleri önbelleğe al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _incrementViewCount();
      _precacheDetailImages();
    });
  }

  void _precacheDetailImages() {
    final urls = widget.animal.photoUrls;
    if (urls.isEmpty || !mounted) return;
    final n = urls.length < 4 ? urls.length : 4;
    for (var i = 0; i < n; i++) {
      final u = urls[i];
      if (u.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(u), context);
    }
  }

  void _incrementViewCount() async {
    // Aynı sayfa açılışında sadece 1 kez artır
    if (_hasIncrementedView) {
      return;
    }

    // İlan sahibi kendi ilanına bakıyorsa sayacı artırma
    if (_currentUserId == widget.animal.uid) {
      print('ℹ️ İlan sahibi kendi ilanına bakıyor, sayac artırılmıyor');
      _hasIncrementedView =
          true; // Artırılmadı ama işaretle (tekrar kontrol etmesin)
      return;
    }

    // Sadece ilan sahibi olmayan kullanıcılar görüntülediğinde artır
    if (_currentUserId != null) {
      try {
        print(
            '🔍 Görüntülenme sayacı artırılıyor - PostId: ${widget.animal.postId}');
        await FirebaseFirestore.instance
            .collection('animals')
            .doc(widget.animal.postId)
            .update({
          'viewCount': FieldValue.increment(3), // 3'er 3'er artır
        });
        _hasIncrementedView = true; // Artırıldı olarak işaretle
        print('✅ Görüntülenme sayacı başarıyla artırıldı (+3)');
      } catch (e) {
        print('❌ Error incrementing view count: $e');
      }
    } else {
      print('ℹ️ Kullanıcı giriş yapmamış, sayac artırılmıyor');
    }
  }

  void _initFavoriteState() async {
    if (_currentUserId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('animals')
        .doc(widget.animal.postId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likes = List.from(data['likes'] ?? []);
      setState(() {
        _isFavorited = likes.contains(_currentUserId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) return;
    setState(() {
      _isFavorited = !_isFavorited;
    });
    final docRef = FirebaseFirestore.instance
        .collection('animals')
        .doc(widget.animal.postId);
    try {
      if (_isFavorited) {
        await docRef.update({
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
      }
    } catch (e) {
      setState(() {
        _isFavorited = !_isFavorited; // revert
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi başarısız: $e')),
      );
    }
  }

  void _shareAnimal() async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Dynamic link oluştur
      final dynamicLinkService = DynamicLinkService();

      // İlan başlığı oluştur
      final String ilanBaslik = widget.animal.animalBreed.isNotEmpty
          ? '${widget.animal.animalBreed} - ${widget.animal.animalSpecies}'
          : widget.animal.animalSpecies;

      // İlan açıklaması oluştur
      final String ilanAciklama = widget.animal.description.isNotEmpty
          ? widget.animal.description.length > 100
              ? '${widget.animal.description.substring(0, 100)}...'
              : widget.animal.description
          : '$ilanBaslik ilanı - ${NumberFormat('#,###', 'tr_TR').format(widget.animal.priceInTL)} ₺';

      // İlan resmi URL'si
      final String ilanResmiUrl =
          widget.animal.photoUrls.isNotEmpty ? widget.animal.photoUrls[0] : '';

      // Dynamic link oluştur
      final String dynamicLink = await dynamicLinkService.createDynamicLink(
        ilanId: widget.animal.postId,
        ilanBaslik: ilanBaslik,
        ilanAciklama: ilanAciklama,
        ilanResmiUrl: ilanResmiUrl,
      );

      // Loading'i kapat
      Navigator.pop(context);

      // Paylaş modalını göster
      _showShareModal(dynamicLink);
    } catch (e) {
      // Loading'i kapat
      Navigator.pop(context);

      // Hata durumunda fallback link kullan
      final String fallbackLink =
          'https://canlipazar.net/ilan/${widget.animal.postId}';
      _showShareModal(fallbackLink);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Link oluşturulurken hata oluştu, alternatif link kullanılıyor'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showShareModal(String shareText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title ve Link
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        'Paylaş',
                        style: SafeFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Tıklanabilir link
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                // Deep link'e tıklayınca direkt uygulamaya yönlendir
                                try {
                                  await launchUrl(
                                    Uri.parse(shareText),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  // Link açılamazsa kopyala
                                  Clipboard.setData(
                                      ClipboardData(text: shareText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Link kopyalandı')),
                                  );
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        shareText,
                                        style: SafeFonts.poppins(
                                          fontSize: 12,
                                          color: primaryColor,
                                        ).copyWith(
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.open_in_new,
                                        size: 16, color: primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: shareText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Link kopyalandı')),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(Icons.copy,
                                  size: 16, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Share options
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // First row: WhatsApp, Facebook
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareOption(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: Color(0xFF25D366),
                            onTap: () async {
                              Navigator.pop(context);
                              // WhatsApp'ta link preview göstermek için direkt linki paylaş
                              // whatsapp://send?text=... formatı link preview göstermez
                              try {
                                // share_plus paketi ile WhatsApp'a direkt link paylaş
                                // Bu sayede WhatsApp link preview gösterir ve Universal Link çalışır
                                await Share.share(
                                  shareText,
                                  subject:
                                      '${widget.animal.animalSpecies} İlanı',
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('WhatsApp açılamadı')),
                                );
                              }
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.share,
                            label: 'Facebook',
                            color: Color(0xFF1877F2),
                            onTap: () async {
                              Navigator.pop(context);
                              // Facebook'ta link preview göstermek için direkt linki paylaş
                              try {
                                await Share.share(
                                  shareText,
                                  subject:
                                      '${widget.animal.animalSpecies} İlanı',
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Facebook açılamadı')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Second row: Email, SMS, Copy, More
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareOption(
                            icon: Icons.email,
                            label: 'E-posta',
                            color: Colors.grey[700]!,
                            onTap: () async {
                              Navigator.pop(context);
                              final emailUrl =
                                  'mailto:?subject=${Uri.encodeComponent('${widget.animal.animalSpecies} İlanı')}&body=${Uri.encodeComponent(shareText)}';
                              try {
                                await launchUrl(Uri.parse(emailUrl),
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('E-posta uygulaması açılamadı')),
                                );
                              }
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.message,
                            label: 'SMS',
                            color: Colors.grey[700]!,
                            onTap: () async {
                              Navigator.pop(context);
                              final smsUrl =
                                  'sms:?body=${Uri.encodeComponent(shareText)}';
                              try {
                                await launchUrl(Uri.parse(smsUrl),
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('SMS uygulaması açılamadı')),
                                );
                              }
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.link,
                            label: 'Kopyala',
                            color: Colors.grey[700]!,
                            onTap: () {
                              Navigator.pop(context);
                              Clipboard.setData(ClipboardData(text: shareText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Link kopyalandı')),
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.more_horiz,
                            label: 'Daha Fazla',
                            color: Colors.grey[700]!,
                            onTap: () async {
                              Navigator.pop(context);
                              await Share.share(shareText,
                                  subject:
                                      '${widget.animal.animalSpecies} İlanı');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: SafeFonts.poppins(
              fontSize: 12,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSellerData() async {
    setState(() {
      _sellerLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.animal.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _sellerData = doc.data();
          _sellerLoading = false;
        });
      } else {
        setState(() {
          _sellerLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sellerLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyTransporters() async {
    setState(() {
      _transportersLoading = true;
    });
    try {
      print(
          'Animal city: ${widget.animal.city}, state: ${widget.animal.state}');

      final transporters = await TransporterService.getNearbyTransporters(
        city: widget.animal.city,
        state: widget.animal.state,
        limit: 3,
      );

      print('Found ${transporters.length} nearby transporters');

      setState(() {
        _nearbyTransporters = transporters;
        _transportersLoading = false;
      });
    } catch (e) {
      print('Error fetching nearby transporters: $e');
      setState(() {
        _transportersLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.animal.animalBreed.isNotEmpty
              ? widget.animal.animalBreed
              : widget.animal.animalSpecies,
          style: SafeFonts.poppins(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          // Paylaş butonu (WhatsApp, Facebook vb.)
          IconButton(
            icon: Icon(Icons.share_outlined, color: textPrimary),
            onPressed: _shareAnimal,
            tooltip: 'Paylaş',
          ),
          // Favori butonu
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? errorColor : textPrimary,
            ),
            onPressed: () async {
              await _toggleFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorited
                      ? 'Favorilere eklendi'
                      : 'Favorilerden çıkarıldı'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildImageCarousel(),
          _buildCard(
            icon: null, // Emoji ile gösterilecek
            title: 'Hayvan Bilgileri',
            child: _buildAnimalInfo(),
            emoji: _getAnimalTypeEmoji(
                widget.animal.animalType, widget.animal.animalSpecies),
          ),
          if (widget.animal.description.isNotEmpty)
            _buildCard(
              icon: Icons.description,
              title: 'Açıklama',
              child: _buildDescription(),
            ),
          _buildCard(
            icon: Icons.currency_lira, // TL simgesi, yoksa kaldırılabilir
            title: 'Fiyat Bilgileri',
            child: _buildPriceInfo(),
          ),
          _buildCard(
            icon: Icons.health_and_safety,
            title: 'Sağlık Bilgileri',
            child: _buildHealthInfo(),
          ),
          _buildCard(
            icon: Icons.person,
            title: 'Satıcı Bilgileri',
            child: _buildSellerInfo(),
          ),
          _buildCard(
            icon: Icons.location_on,
            title: 'Konum',
            child: _buildLocationInfo(),
          ),
          _buildCard(
            icon: Icons.local_shipping,
            title: 'Yakındaki Nakliyeciler',
            child: _buildNearbyTransporters(),
          ),
          SizedBox(height: 100),
        ],
      ),
      floatingActionButton: _buildContactButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCard(
      {String? emoji,
      IconData? icon,
      required String title,
      required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null)
                Text(
                  emoji,
                  style: TextStyle(fontSize: 22),
                )
              else if (icon != null)
                Icon(icon, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.animal.photoUrls.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor, width: 1),
            ),
            child: Center(
              child: Icon(Icons.pets, size: 80, color: textSecondary),
            ),
          ),
        ),
      );
    }
    final size = MediaQuery.of(context).size;
    final cacheW = (size.width * 2).round().clamp(400, 1200);
    final cacheH = (size.width * 1.5).round().clamp(300, 900);
    return GestureDetector(
      onTap: () {
        _showFullScreenGallery(_currentImageIndex);
      },
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor, width: 1),
          color: surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: PageView.builder(
                  controller: _pageController,
                  allowImplicitScrolling: false,
                  physics: const ClampingScrollPhysics(),
                  itemCount: widget.animal.photoUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                    if (index + 1 < widget.animal.photoUrls.length) {
                      final next = widget.animal.photoUrls[index + 1];
                      if (next.isNotEmpty) {
                        precacheImage(
                            CachedNetworkImageProvider(next), context);
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    final imageWidget = CachedNetworkImage(
                      imageUrl: widget.animal.photoUrls[index],
                      memCacheWidth: cacheW,
                      memCacheHeight: cacheH,
                      maxWidthDiskCache: cacheW,
                      maxHeightDiskCache: cacheH,
                      fadeInDuration: const Duration(milliseconds: 120),
                      fadeOutDuration: Duration.zero,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[300],
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: surfaceColor,
                        child:
                            Icon(Icons.error, size: 50, color: textSecondary),
                      ),
                    );
                    return RepaintBoundary(
                      child: index == 0
                          ? Hero(
                              tag: animalHeroTag(widget.animal.postId),
                              child: imageWidget,
                            )
                          : imageWidget,
                    );
                  },
                ),
              ),
              // Sağ üst köşe - Favori butonu (Paylaş butonu kaldırıldı, sadece AppBar'da)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favori butonu
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          await _toggleFavorite();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFavorited
                                  ? 'Favorilere eklendi'
                                  : 'Favorilerden çıkarıldı'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: _isFavorited ? errorColor : primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Alt orta - Sayfa göstergeleri
              if (widget.animal.photoUrls.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        widget.animal.photoUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == entry.key
                              ? primaryColor
                              : dividerColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Fiyat overlay
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${NumberFormat('#,###', 'tr_TR').format(widget.animal.priceInTL)} ₺'
                        .replaceAll(',', '.'),
                    style: SafeFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenGallery(int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Görseli Kapat',
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return _FullScreenGallery(
          photoUrls: widget.animal.photoUrls,
          initialIndex: initialIndex,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  Widget _buildAnimalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Tür', widget.animal.animalType.toUpperCase()),
        _buildInfoRow('Cins', widget.animal.animalSpecies),
        _buildInfoRow('Irk', widget.animal.animalBreed),
        _buildInfoRow('Cinsiyet', widget.animal.gender),
        _buildInfoRow('Yaş', '${widget.animal.ageInMonths} ay'),
        _buildInfoRow(
            'Ağırlık', '${widget.animal.weightInKg.toStringAsFixed(0)} kg'),
        _buildInfoRow('Amaç', widget.animal.purpose),
        if (widget.animal.isPregnant)
          _buildInfoRow('Durum', 'Gebe', color: warningColor),
        // Sadece ilan sahibi görüntülenme sayısını görebilir
        if (_currentUserId == widget.animal.uid)
          _buildInfoRow('Görüntülenme', '${widget.animal.viewCount} kez',
              color: infoColor),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      children: [
        // Icon(Icons.attach_money, color: primaryColor), // KALDIRILDI
        // Fiyat
        Text(
          '${NumberFormat('#,###', 'tr_TR').format(widget.animal.priceInTL)} ₺'
              .replaceAll(',', '.'),
          style: SafeFonts.poppins(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.animal.isNegotiable)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildBadge('Pazarlık', warningColor),
          ),
        if (widget.animal.isUrgentSale)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildBadge('Acil', errorColor),
          ),
      ],
    );
  }

  Widget _buildHealthInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Sağlık Durumu', widget.animal.healthStatus),
        if (widget.animal.vaccinations.isNotEmpty)
          _buildInfoRow('Aşılar', widget.animal.vaccinations.join(', ')),
        if (widget.animal.veterinarianContact != null)
          _buildInfoRow(
              'Veteriner İletişim', widget.animal.veterinarianContact!),
      ],
    );
  }

  Widget _buildSellerInfo() {
    if (_sellerLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[400]!,
        highlightColor: Colors.grey[200]!,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
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
    final data = _sellerData;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen2(
              uid: widget.animal.uid,
              snap: data,
              userId: widget.animal.uid,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.animal.profImage.isNotEmpty
                ? ResizeImage(
                    CachedNetworkImageProvider(widget.animal.profImage),
                    width: 96,
                    height: 96,
                  )
                : null,
            child: widget.animal.profImage.isEmpty
                ? Icon(Icons.person, size: 20)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animal.username,
                  style: SafeFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.animal.sellerType,
                  style: SafeFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                if (data != null) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      // Satış sayısı
                      Icon(Icons.shopping_cart, color: primaryColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${data['totalSales'] ?? 0} satış',
                        style: SafeFonts.poppins(
                          fontSize: 12,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Ortalama puan
                      Icon(Icons.star, color: warningColor, size: 16),
                      SizedBox(width: 2),
                      Text(
                        data['averageRating'] != null
                            ? data['averageRating'].toStringAsFixed(1)
                            : '-',
                        style: SafeFonts.poppins(
                          fontSize: 12,
                          color: warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/5.0',
                        style: SafeFonts.poppins(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, color: errorColor, size: 18),
        SizedBox(width: 8),
        Text(
          widget.animal.city,
          style: SafeFonts.poppins(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.animal.description,
      style: SafeFonts.poppins(
        fontSize: 14,
        color: textSecondary,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: SafeFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: SafeFonts.poppins(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SafeFonts.poppins(
                color: color ?? textPrimary,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.animal.uid;

    if (isOwner) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // SATILDI Butonu
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text('SATILDI',
                    style: SafeFonts.poppins(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Satıldı Olarak İşaretle'),
                      content: Text(
                          'Bu ilanı satıldı olarak işaretlemek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                          child: Text('Evet, Satıldı'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;

                      // İlanı satıldı olarak işaretle
                      await FirebaseFirestore.instance
                          .collection('animals')
                          .doc(widget.animal.postId)
                          .update({
                        'saleStatus': 'sold',
                        'soldDate': DateTime.now(),
                        'isActive': false,
                      });

                      // Kullanıcının satış sayısını ve puanını artır
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get();

                      if (userDoc.exists) {
                        final userData = userDoc.data() ?? {};
                        final currentSales =
                            (userData['totalSales'] as int? ?? 0) + 1;
                        final currentRating =
                            (userData['averageRating'] as double? ?? 0.0);
                        final currentRatings =
                            (userData['totalRatings'] as int? ?? 0);

                        // Puanı hesapla: mevcut puan + 1 (basit sistem)
                        // Eğer ilk satışsa 5.0, değilse ortalama al
                        double newRating;
                        if (currentRatings == 0) {
                          newRating = 5.0; // İlk satış için 5 puan
                        } else {
                          // Mevcut puanların ortalamasına 5 ekleyip tekrar ortalama al
                          double totalPoints =
                              (currentRating * currentRatings) + 5.0;
                          newRating = totalPoints / (currentRatings + 1);
                        }

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .update({
                          'totalSales': currentSales,
                          'averageRating': newRating,
                          'totalRatings': currentRatings + 1,
                        });
                      }

                      if (mounted) {
                        Navigator.of(context).pop(); // Detay sayfasını kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'İlan satıldı olarak işaretlendi. Satış ve puanınız güncellendi!'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('İşlem başarısız: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            SizedBox(width: 12),
            // İlanı Sil Butonu
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.delete, color: errorColor),
                label: Text('İlanı Sil',
                    style: SafeFonts.poppins(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('İlanı Sil'),
                      content:
                          Text('Bu ilanı silmek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Sil',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('animals')
                          .doc(widget.animal.postId)
                          .delete();
                      Navigator.of(context).pop(); // Detay sayfasını kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('İlan silindi')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silme işlemi başarısız: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          _showContactOptions();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 20),
            SizedBox(width: 8),
            Text(
              'Satıcı ile İletişime Geç',
              style:
                  SafeFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions() async {
    final phoneNumber =
        _sellerData != null ? (_sellerData!['phoneNumber'] ?? '') : '';

    print('_showContactOptions - SellerData: $_sellerData');
    print('_showContactOptions - PhoneNumber: $phoneNumber');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İletişim Seçenekleri',
              style: SafeFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.message, color: primaryColor),
              title: Text('Mesaj Gönder',
                  style: SafeFonts.poppins(color: Colors.black)),
              subtitle: Text('Uygulama içi mesajlaşma',
                  style: SafeFonts.poppins(color: Colors.grey[700])),
              onTap: () {
                Navigator.pop(context);
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        currentUserUid: currentUser.uid,
                        recipientUid: widget.animal.uid,
                        postId: widget.animal.postId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Giriş yapmanız gerekiyor')),
                  );
                }
              },
            ),
            if (phoneNumber.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Telefon',
                    style: SafeFonts.poppins(color: Colors.black)),
                subtitle: GestureDetector(
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Arama başlatılamadı')),
                      );
                    }
                  },
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: phoneNumber));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Telefon numarası kopyalandı')),
                    );
                  },
                  child: Text(
                    phoneNumber,
                    style: SafeFonts.poppins(
                      color: Colors.blue,
                      fontSize: 16,
                    ).copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Arama başlatılamadı')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getAnimalTypeEmoji(String animalType, String animalSpecies) {
    final type = animalType.toLowerCase();
    final species = animalSpecies.toLowerCase();
    // Öncelik: Keçi türleri > Koyun türleri > Büyükbaş > Diğer
    if (species.contains('keçi') ||
        species.contains('oğlak') ||
        species.contains('teke') ||
        type.contains('keçi')) {
      return '🐐';
    } else if (species.contains('koyun') ||
        species.contains('kuzu') ||
        species.contains('koç') ||
        type.contains('koyun')) {
      return '🐑';
    } else if (type.contains('büyükbaş') ||
        species.contains('sığır') ||
        species.contains('manda') ||
        species.contains('boğa') ||
        species.contains('düve') ||
        species.contains('tosun')) {
      return '🐄';
    } else {
      return '🐾';
    }
  }

  Widget _buildNearbyTransporters() {
    if (_transportersLoading) {
      return Column(
        children: [
          _buildTransportersShimmer(),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.visibility, size: 16),
              label: Text('Tüm Nakliyecileri Gör'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransporterListScreen(
                      city: widget.animal.city,
                      state: widget.animal.state,
                      title: '${widget.animal.city} Nakliyecileri',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_nearbyTransporters.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Bu bölgede henüz nakliyeci bulunmuyor.',
              style: SafeFonts.poppins(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._nearbyTransporters
              .take(3)
              .map((transporter) => _buildTransporterItem(transporter)),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.visibility, size: 16),
            label: Text(_nearbyTransporters.isEmpty
                ? 'Nakliyecileri Ara'
                : 'Tüm Nakliyecileri Gör'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterListScreen(
                    city: widget.animal.city,
                    state: widget.animal.state,
                    title: '${widget.animal.city} Nakliyecileri',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransportersShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey[400]!,
          highlightColor: Colors.grey[200]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransporterItem(Transporter transporter) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransporterDetailScreen(
                transporterData: transporter.toMap(),
              ),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: transporter.profileImage != null
                  ? ResizeImage(
                      CachedNetworkImageProvider(transporter.profileImage!),
                      width: 96,
                      height: 96,
                    )
                  : null,
              child: transporter.profileImage == null
                  ? Icon(Icons.local_shipping, size: 20, color: primaryColor)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transporter.companyName,
                    style: SafeFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: warningColor, size: 12),
                      SizedBox(width: 2),
                      Text(
                        transporter.rating?.toStringAsFixed(1) ?? '-',
                        style: SafeFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: warningColor,
                        ),
                      ),
                      Text(
                        '/5',
                        style: SafeFonts.poppins(
                          fontSize: 9,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.local_shipping, color: infoColor, size: 12),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${transporter.totalTrips ?? 0} seyahat',
                          style: SafeFonts.poppins(
                            fontSize: 9,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: errorColor, size: 12),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${transporter.cities.take(3).join(', ')}${transporter.cities.length > 3 ? '...' : ''}',
                          style: SafeFonts.poppins(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transporter.minPrice != null &&
                      transporter.maxPrice != null)
                    Text(
                      '${NumberFormat('#,###', 'tr_TR').format(transporter.minPrice)}-${NumberFormat('#,###', 'tr_TR').format(transporter.maxPrice)}₺',
                      style: SafeFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    )
                  else if (transporter.pricePerKm != null)
                    Text(
                      '${NumberFormat('#,###', 'tr_TR').format(transporter.pricePerKm)}₺/km',
                      style: SafeFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.phone, size: 16, color: successColor),
                        onPressed: () => _callTransporter(transporter),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 2),
                      IconButton(
                        icon:
                            Icon(Icons.message, size: 16, color: primaryColor),
                        onPressed: () => _messageTransporter(transporter),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callTransporter(Transporter transporter) async {
    final uri = Uri(scheme: 'tel', path: transporter.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama başlatılamadı')),
      );
    }
  }

  void _messageTransporter(Transporter transporter) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: currentUser.uid,
            recipientUid: transporter.userId,
            postId: '', // Nakliyeci mesajı olduğu için postId boş
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapmanız gerekiyor')),
      );
    }
  }
}

// Tam ekran modern görsel görüntüleyici (zoom, önbellek, shimmer)
class _FullScreenGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  const _FullScreenGallery(
      {Key? key, required this.photoUrls, this.initialIndex = 0})
      : super(key: key);

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final m = _transformationController.value;
    final s = m.getMaxScaleOnAxis();
    if (s > 1.2) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cacheW = (size.width * 2).round().clamp(600, 1600);
    final cacheH = (size.height * 2).round().clamp(600, 1600);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.photoUrls.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                _transformationController.value = Matrix4.identity();
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: widget.photoUrls[index],
                    child: GestureDetector(
                      onDoubleTap: _onDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        panEnabled: true,
                        child: CachedNetworkImage(
                        imageUrl: widget.photoUrls[index],
                        memCacheWidth: cacheW,
                        memCacheHeight: cacheH,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[600]!,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[800],
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.error, color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
                );
              },
            ),
            // Kapatma butonu
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
            // Dots göstergesi
            if (widget.photoUrls.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      widget.photoUrls.length,
                      (i) => Container(
                            width: 10,
                            height: 10,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentIndex == i
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
