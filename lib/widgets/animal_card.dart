import 'package:flutter/material.dart';
import 'dart:ui' show FilterQuality;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/animal_post.dart';
import '../utils/safe_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/animal_firestore_filters.dart';

class AnimalCard extends StatelessWidget {
  final AnimalPost animal;
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

  /// Kart yüksekliği (120 görsel + bilgi); satıcı alta + satır aralıkları için tampon.
  static const double _cardMaxHeight = 252.0;

  /// Başlık ↔ ilk satır (kart boyu sabit; Spacer bu aralığı dengeler).
  static const double _gapAfterTitle = 6.0;

  /// Tarih/saat satırı ↔ yaş–kilo (ay) ↔ şehir arası — kart büyümeden açılır.
  static const double _gapTimeAyCity = 11.0;

  /// Görsel alanı: toplam yüksekliğin ~%50’si (120 / 240).
  static const double _imageHeight = 120.0;

  static const double _borderRadius = 12.0;

  const AnimalCard({
    Key? key,
    required this.animal,
    this.isGridView = false,
    this.onTap,
    this.onFavorite,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AnimalCard.backgroundColor,
      elevation: 2.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: const BorderSide(color: AnimalCard.dividerColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _cardMaxHeight),
          child: SizedBox(
            height: _cardMaxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Resim alanı (~%50) ---
                SizedBox(
                  height: _imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_borderRadius),
                        ),
                        child: animal.photoUrls.isNotEmpty
                            ? Hero(
                                tag: animalHeroTag(animal.postId),
                                child: CachedNetworkImage(
                                imageUrl: listingThumbnailUrl(animal.photoUrls[0]),
                                memCacheWidth: isGridView ? 320 : 520,
                                memCacheHeight: isGridView ? 200 : 320,
                                maxWidthDiskCache: isGridView ? 480 : 800,
                                maxHeightDiskCache: isGridView ? 360 : 600,
                                width: double.infinity,
                                height: _imageHeight,
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 36,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                                    errorWidget: (context, url, error) =>
                                    Container(
                                  color: AnimalCard.surfaceColor,
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 36),
                                  ),
                                ),
                              ),
                            )
                            : Container(
                                color: AnimalCard.surfaceColor,
                                child: const Center(
                                  child: Icon(Icons.pets, size: 36),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AnimalCard.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${NumberFormat('#,###', 'tr_TR').format(animal.priceInTL)} ₺',
                            style: SafeFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- Bilgi alanı (kalan ~%50) ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          (animal.animalBreed.isNotEmpty
                              ? animal.animalBreed
                              : animal.animalSpecies),
                          style: SafeFonts.poppins(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AnimalCard.textPrimary,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: _gapAfterTitle),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AnimalCard.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getFormattedDate(animal.datePublished),
                                style: SafeFonts.poppins(
                                  fontSize: 11,
                                  color: AnimalCard.textSecondary,
                                  height: 1.15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _gapTimeAyCity),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(
                                'Yaş',
                                '${animal.ageInMonths} ay',
                                Icons.cake,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildInfoChip(
                                'Ağırlık',
                                '${animal.weightInKg.toStringAsFixed(0)} kg',
                                Icons.monitor_weight,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _gapTimeAyCity),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AnimalCard.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                animal.city,
                                style: SafeFonts.poppins(
                                  fontSize: 11,
                                  color: AnimalCard.textSecondary,
                                  height: 1.15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10.0,
                              backgroundImage: animal.profImage.isNotEmpty
                                  ? CachedNetworkImageProvider(animal.profImage)
                                  : null,
                              child: animal.profImage.isEmpty
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                animal.username,
                                style: SafeFonts.poppins(
                                  fontSize: 11.0,
                                  color: AnimalCard.textSecondary,
                                  fontWeight: FontWeight.w400,
                                  height: 1.15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AnimalCard.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AnimalCard.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: AnimalCard.primaryColor,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : label,
              style: SafeFonts.poppins(
                fontSize: 11.0,
                color: AnimalCard.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
}
