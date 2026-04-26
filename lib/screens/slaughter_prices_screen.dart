import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import 'package:intl/intl.dart';
import '../models/slaughter_price.dart';
import '../services/slaughter_price_service.dart';
import 'package:shimmer/shimmer.dart';

class SlaughterPricesScreen extends StatefulWidget {
  const SlaughterPricesScreen({Key? key}) : super(key: key);

  @override
  State<SlaughterPricesScreen> createState() => _SlaughterPricesScreenState();
}

class _SlaughterPricesScreenState extends State<SlaughterPricesScreen> {
  final SlaughterPriceService _service = SlaughterPriceService();
  String _selectedRegion = 'Marmara';
  String _selectedAnimalType = 'büyükbaş';
  List<String> _regions = [];

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const List<String> turkishRegions = [
    'Marmara',
    'Ege',
    'Akdeniz',
    'İç Anadolu',
    'Karadeniz',
    'Doğu Anadolu',
    'Güneydoğu Anadolu',
  ];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    final regions = await _service.getAllRegions();
    setState(() {
      _regions = regions.isNotEmpty ? regions : turkishRegions;
      _selectedRegion = _regions.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'KARGAS Fiyatları',
          style: SafeFonts.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: EdgeInsets.all(16),
            color: surfaceColor,
            child: Column(
              children: [
                // Bölge seçici
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'Bölge Seçin',
                    prefixIcon: Icon(Icons.location_on, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRegion = value;
                      });
                    }
                  },
                ),
                SizedBox(height: 12),
                // Hayvan türü seçici
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimalTypeButton('büyükbaş', 'Büyükbaş', Icons.pets),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildAnimalTypeButton('küçükbaş', 'Küçükbaş', Icons.pets),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Fiyat kartları
          Expanded(
            child: StreamBuilder<SlaughterPrice?>(
              stream: _service.streamPricesByRegion(_selectedRegion),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Fiyatlar yüklenirken hata oluştu',
                          style: SafeFonts.poppins(color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final priceData = snapshot.data;
                if (priceData == null || priceData.prices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Bu bölge için fiyat bilgisi bulunamadı',
                          style: SafeFonts.poppins(color: textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fiyatlar yakında güncellenecek',
                          style: SafeFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final animalPrice = priceData.prices[_selectedAnimalType];
                if (animalPrice == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Bu hayvan türü için fiyat bulunamadı',
                          style: SafeFonts.poppins(color: textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fiyatlar yakında güncellenecek',
                          style: SafeFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Fiyatların 0 olup olmadığını kontrol et
                if (animalPrice.canliKg == 0 && animalPrice.kesimKg == 0 && animalPrice.karkasKg == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Bu bölge için fiyat bilgisi henüz güncellenmedi',
                          style: SafeFonts.poppins(color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fiyatlar her gün otomatik güncellenir',
                          style: SafeFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Son güncelleme bilgisi
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.update, color: primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Son Güncelleme: ${_formatDate(priceData.lastUpdated)}',
                              style: SafeFonts.poppins(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Fiyat kartları
                      _buildPriceCard(
                        'Canlı Kg Fiyatı',
                        animalPrice.canliKg,
                        Icons.scale,
                        Colors.blue,
                      ),
                      SizedBox(height: 16),
                      _buildPriceCard(
                        'Kesim Kg Fiyatı',
                        animalPrice.kesimKg,
                        Icons.restaurant,
                        Colors.orange,
                      ),
                      SizedBox(height: 16),
                      _buildPriceCard(
                        'Karkas Kg Fiyatı',
                        animalPrice.karkasKg,
                        Icons.inventory_2,
                        Colors.red,
                      ),
                      SizedBox(height: 24),
                      // Bilgi kartı
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Bilgi',
                                  style: SafeFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '• Canlı Kg: Hayvanın canlı ağırlığı üzerinden fiyat\n'
                              '• Kesim Kg: Kesim sonrası ağırlık üzerinden fiyat\n'
                              '• Karkas Kg: Karkas (kemiksiz et) ağırlığı üzerinden fiyat',
                              style: SafeFonts.poppins(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedAnimalType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnimalType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : textSecondary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: SafeFonts.poppins(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(String title, double price, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SafeFonts.poppins(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###.##', 'tr_TR').format(price)} ₺/kg',
                  style: SafeFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
    }
  }
}

