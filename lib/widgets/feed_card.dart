import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post.dart';
import '../utils/safe_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class FeedCard extends StatelessWidget {
  final FeedPost feed;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  const FeedCard({
    Key? key,
    required this.feed,
    this.isGridView = false,
    this.onTap,
    this.onFavorite,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = feed.likes.contains(currentUserId);
    return Material(
      color: FeedCard.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: FeedCard.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FeedCard.dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: isGridView ? 160 : 200,
                      width: double.infinity,
                      child: feed.photoUrls.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.all(8),
                              child: CachedNetworkImage(
                                imageUrl: feed.photoUrls[0],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                memCacheWidth: 800,
                                memCacheHeight: 800,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.agriculture,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: FeedCard.surfaceColor,
                                  child: const Center(
                                      child: Icon(Icons.agriculture, size: 40)),
                                ),
                              ),
                            )
                          : Container(
                              color: FeedCard.surfaceColor,
                              child: const Center(
                                  child: Icon(Icons.agriculture, size: 40)),
                            ),
                    ),
                  ),
                  // Fiyat etiketi - sağ üst köşe
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FeedCard.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${NumberFormat('#,###', 'tr_TR').format(feed.priceInTL)} ₺/${feed.priceUnit}',
                        style: SafeFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Favori butonu - sağ alt köşe
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _buildIconButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      iconColor: isLiked ? Colors.red : FeedCard.primaryColor,
                      onTap: () async {
                        final docRef = FirebaseFirestore.instance
                            .collection('feeds')
                            .doc(feed.postId);
                        try {
                          if (isLiked) {
                            await docRef.update({
                              'likes': FieldValue.arrayRemove([currentUserId])
                            });
                          } else {
                            await docRef.update({
                              'likes': FieldValue.arrayUnion([currentUserId])
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Favori işlemi başarısız: $e')),
                          );
                        }
                        if (onFavorite != null) onFavorite!();
                      },
                    ),
                  ),
                ],
              ),
              // Bilgi alanı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yem kategorisi - tam genişlik
                    Text(
                      feed.feedCategory.isNotEmpty
                          ? feed.feedCategory
                          : feed.feedType,
                      style: SafeFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: FeedCard.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // İlan tarihi
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: FeedCard.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            _getFormattedDate(feed.datePublished),
                            style: SafeFonts.poppins(
                              fontSize: 12,
                              color: FeedCard.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (feed.isUrgentSale || feed.isNegotiable || feed.isOrganic)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (feed.isUrgentSale)
                              _buildBadge('Acil', FeedCard.errorColor),
                            if (feed.isNegotiable)
                              _buildBadge('Pazarlık', FeedCard.warningColor),
                            if (feed.isOrganic)
                              _buildBadge('Organik', Colors.green),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    // Chipler: miktar, hayvan türü, paketleme
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                            'Miktar',
                            '${_formatQuantity(feed.quantityInKg)} ${feed.quantityUnit}',
                            Icons.inventory),
                        _buildInfoChip(
                            'Tür',
                            feed.animalType,
                            Icons.pets),
                        if (feed.packagingType.isNotEmpty)
                          _buildInfoChip(
                              'Paket',
                              feed.packagingType,
                              Icons.inventory_2),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Konum
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: FeedCard.textSecondary),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            feed.city,
                            style: SafeFonts.poppins(
                              fontSize: 12,
                              color: FeedCard.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Satıcı
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: feed.profImage.isNotEmpty
                              ? ResizeImage(
                                  CachedNetworkImageProvider(feed.profImage),
                                  width: 96,
                                  height: 96,
                                )
                              : null,
                          child: feed.profImage.isEmpty
                              ? Icon(Icons.person, size: 16)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feed.username,
                            style: SafeFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: FeedCard.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
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

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FeedCard.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FeedCard.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: FeedCard.primaryColor,
          ),
          SizedBox(width: 4),
          Text(
            value.isNotEmpty ? value : label,
            style: SafeFonts.poppins(
              fontSize: 11,
              color: FeedCard.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, Color? iconColor, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              Icon(icon, size: 18, color: iconColor ?? FeedCard.primaryColor),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) {
      final hours = diff.inHours;
      if (hours < 1) {
        final mins = diff.inMinutes;
        if (mins < 1) return 'Şimdi';
        return '$mins dakika önce';
      }
      return '$hours saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  String _formatQuantity(double quantity) {
    if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}';
    }
    return quantity.toStringAsFixed(0);
  }
}

