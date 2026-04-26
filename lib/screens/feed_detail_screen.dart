import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_post.dart';
import 'message_screen.dart' as msg;
import '../utils/safe_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../resources/feed_firestore_methods.dart';
import 'feed_discover_screen.dart';

class FeedDetailScreen extends StatefulWidget {
  final FeedPost feed;

  const FeedDetailScreen({Key? key, required this.feed}) : super(key: key);

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  String? _currentUserId;
  late PageController _pageController;
  Map<String, dynamic>? _sellerData;
  bool _sellerLoading = true;
  bool _hasIncrementedView = false;

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchSellerData();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initFavoriteState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _incrementViewCount();
    });
  }

  void _incrementViewCount() async {
    if (_hasIncrementedView) return;
    if (_currentUserId == widget.feed.uid) {
      _hasIncrementedView = true;
      return;
    }
    if (_currentUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('feeds')
            .doc(widget.feed.postId)
            .update({
          'viewCount': FieldValue.increment(1),
        });
        _hasIncrementedView = true;
      } catch (e) {
        print('❌ Error incrementing view count: $e');
      }
    }
  }

  void _initFavoriteState() async {
    if (_currentUserId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feed.postId)
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
        .collection('feeds')
        .doc(widget.feed.postId);
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
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi başarısız: $e')),
      );
    }
  }

  Future<void> _deleteFeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İlanı Sil'),
        content: Text('Bu ilanı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorColor),
            child: Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await FeedFirestoreMethods().deleteFeed(widget.feed.postId);
        if (result == "success" && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İlan başarıyla silindi'),
              backgroundColor: primaryColor,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $result'),
              backgroundColor: errorColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchSellerData() async {
    setState(() {
      _sellerLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.feed.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _sellerData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Satıcı bilgisi yükleme hatası: $e');
    } finally {
      setState(() {
        _sellerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : textPrimary,
            ),
            onPressed: _toggleFavorite,
          ),
          if (_currentUserId == widget.feed.uid)
            IconButton(
              icon: Icon(Icons.delete, color: errorColor),
              onPressed: _deleteFeed,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraflar
            if (widget.feed.photoUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // Resme tıklandığında tam ekran galeriyi aç
                    _showFullScreenGallery(_currentImageIndex);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 300,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.feed.photoUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: widget.feed.photoUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[300]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.feed.photoUrls.length > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.feed.photoUrls.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve fiyat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Yem kategorisine basınca yem sayfasına yönlendir
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FeedDiscoverScreen(),
                              ),
                            );
                          },
                          child: Text(
                            widget.feed.feedCategory,
                            style: SafeFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###', 'tr_TR').format(widget.feed.priceInTL)} ₺/${widget.feed.priceUnit}',
                        style: SafeFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Badge'ler
                  Wrap(
                    spacing: 8,
                    children: [
                      if (widget.feed.isUrgentSale)
                        _buildBadge('Acil', errorColor),
                      if (widget.feed.isOrganic)
                        _buildBadge('Organik', Colors.green),
                      if (widget.feed.isBulkSale)
                        _buildBadge('Toplu Satış', warningColor),
                      if (widget.feed.isNegotiable)
                        _buildBadge('Pazarlık', warningColor),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Açıklama
                  Text(
                    'Açıklama',
                    style: SafeFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.feed.description,
                    style: SafeFonts.poppins(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Detaylar
                  _buildDetailRow('Miktar',
                      '${_formatQuantity(widget.feed.quantityInKg)} ${widget.feed.quantityUnit}'),
                  _buildDetailRow('Hayvan Türü', widget.feed.animalType),
                  _buildDetailRow('Paketleme', widget.feed.packagingType),
                  if (widget.feed.brand.isNotEmpty)
                    _buildDetailRow('Marka', widget.feed.brand),
                  if (widget.feed.proteinPercentage != null)
                    _buildDetailRow('Protein',
                        '%${widget.feed.proteinPercentage!.toStringAsFixed(1)}'),
                  if (widget.feed.energyValue != null)
                    _buildDetailRow('Enerji Değeri',
                        widget.feed.energyValue!.toStringAsFixed(0)),
                  if (widget.feed.productionDate != null)
                    _buildDetailRow('Üretim Tarihi', widget.feed.productionDate!),
                  if (widget.feed.expiryDate != null)
                    _buildDetailRow('Son Kullanma', widget.feed.expiryDate!),
                  _buildDetailRow('Satıcı Türü', widget.feed.sellerType),
                  _buildDetailRow('Konum', widget.feed.city),
                  SizedBox(height: 24),
                  // Satıcı bilgileri
                  if (!_sellerLoading && _sellerData != null)
                    _buildSellerSection(),
                  SizedBox(height: 24),
                  // İletişim butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => msg.MessagesPage(
                              currentUserUid: _currentUserId ?? '',
                              recipientUid: widget.feed.uid,
                              postId: widget.feed.postId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Mesaj Gönder',
                        style: SafeFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: SafeFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: SafeFonts.poppins(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SafeFonts.poppins(
                fontSize: 14,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    final phoneNumber = _sellerData?['phoneNumber'] as String?;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Satıcı Bilgileri',
            style: SafeFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.feed.profImage.isNotEmpty
                    ? CachedNetworkImageProvider(widget.feed.profImage)
                    : null,
                child: widget.feed.profImage.isEmpty
                    ? Icon(Icons.person, size: 24)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feed.username,
                      style: SafeFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (phoneNumber != null && phoneNumber.isNotEmpty)
                      Text(
                        phoneNumber,
                        style: SafeFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.phone, color: primaryColor),
                  onPressed: () async {
                    final uri = Uri.parse('tel:$phoneNumber');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}';
    }
    return quantity.toStringAsFixed(0);
  }

  void _showFullScreenGallery(int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Görseli Kapat',
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return _FullScreenGallery(
          photoUrls: widget.feed.photoUrls,
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
}

// Tam ekran modern görsel görüntüleyici
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photoUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: widget.photoUrls[index],
                    child: CachedNetworkImage(
                      imageUrl: widget.photoUrls[index],
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[600]!,
                        highlightColor: Colors.grey[400]!,
                        child: Container(
                          color: Colors.grey[600],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.agriculture,
                                  size: 80,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 24),
                                Container(
                                  width: 160,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 100,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 140,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error, color: Colors.white, size: 60),
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
