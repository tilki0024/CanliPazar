import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import '../screens/city_picker_screen.dart';

/// Anasayfa filtreleme için kullanılan sıralama seçenekleri.
enum HomeSortOrder {
  dateNewest,
  dateOldest,
  priceHigh,
  priceLow,
}

/// iOS Action Sheet tarzında filtreleme menüsü.
/// Başlık "Filtrele", sıralama seçenekleri, şehir seç satırı ve İptal butonu.
class HomeFilterActionSheet extends StatelessWidget {
  /// Mevcut sıralama.
  final HomeSortOrder sortOrder;

  /// Mevcut seçili şehir (örn. "Tüm Şehirler" veya "Ankara").
  final String selectedCity;

  /// Sıralama seçeneği seçildiğinde.
  final ValueChanged<HomeSortOrder> onSortSelected;

  /// Şehir seçildiğinde (Şehir Seç satırına tıklanıp picker'dan dönen değer).
  final ValueChanged<String> onCitySelected;

  const HomeFilterActionSheet({
    Key? key,
    required this.sortOrder,
    required this.selectedCity,
    required this.onSortSelected,
    required this.onCitySelected,
  }) : super(key: key);

  static const Color _titleColor = Color(0xFF757575);
  static const Color _optionColor = Color(0xFF3949AB);
  static const Color _dividerColor = Color(0xFFE0E0E0);

  /// Action sheet'i gösterir. [context] kullanılarak [showModalBottomSheet] çağrılır.
  static Future<void> show(
    BuildContext context, {
    required HomeSortOrder sortOrder,
    required String selectedCity,
    required ValueChanged<HomeSortOrder> onSortSelected,
    required ValueChanged<String> onCitySelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HomeFilterActionSheet(
        sortOrder: sortOrder,
        selectedCity: selectedCity,
        onSortSelected: (order) {
          Navigator.of(context).pop();
          onSortSelected(order);
        },
        onCitySelected: (city) {
          onCitySelected(city);
        },
      ),
    );
  }

  Future<void> _openCityPicker(BuildContext context) async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => CityPickerScreen(currentCity: selectedCity),
      ),
    );
    if (picked != null) {
      onCitySelected(picked);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Filtrele',
                style: SafeFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
            ),
            // Sıralama seçenekleri
            _buildOption(
              label: 'İlan Tarihi (Önce en yeni)',
              isSelected: sortOrder == HomeSortOrder.dateNewest,
              onTap: () => onSortSelected(HomeSortOrder.dateNewest),
            ),
            _buildDivider(),
            _buildOption(
              label: 'İlan Tarihi (Önce en eski)',
              isSelected: sortOrder == HomeSortOrder.dateOldest,
              onTap: () => onSortSelected(HomeSortOrder.dateOldest),
            ),
            _buildDivider(),
            _buildOption(
              label: 'Fiyat (Önce en yüksek)',
              isSelected: sortOrder == HomeSortOrder.priceHigh,
              onTap: () => onSortSelected(HomeSortOrder.priceHigh),
            ),
            _buildDivider(),
            _buildOption(
              label: 'Fiyat (Önce en düşük)',
              isSelected: sortOrder == HomeSortOrder.priceLow,
              onTap: () => onSortSelected(HomeSortOrder.priceLow),
            ),
            _buildDivider(),
            _buildOption(
              label: 'ŞEHİR SEÇ: $selectedCity',
              isSelected: false,
              onTap: () => _openCityPicker(context),
            ),
            const SizedBox(height: 16),
            // İptal butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _optionColor,
                    side: const BorderSide(color: _dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: SafeFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _optionColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: _dividerColor,
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SafeFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: _optionColor,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: _optionColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
