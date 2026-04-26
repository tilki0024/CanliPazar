import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import '../utils/turkish_cities.dart';

/// 81 ilin listelendiği, arama yapılabilen şehir seçim ekranı.
/// Seçilen şehir [Navigator.pop] ile döndürülür.
class CityPickerScreen extends StatefulWidget {
  /// Mevcut seçili şehir (vurgulama için).
  final String? currentCity;

  const CityPickerScreen({Key? key, this.currentCity}) : super(key: key);

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _filteredCities = List.from(turkishCities);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCities = List.from(turkishCities));
      return;
    }
    setState(() {
      _filteredCities = turkishCities
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectCity(String city) {
    Navigator.of(context).pop(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212121),
        title: Text(
          'Şehir Seç',
          style: SafeFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Şehir ara...',
                hintStyle: SafeFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: SafeFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF212121),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCities.length,
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                final isSelected = city == widget.currentCity;
                return InkWell(
                  onTap: () => _selectCity(city),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            city,
                            style: SafeFonts.poppins(
                              fontSize: 16,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: const Color(0xFF212121),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
