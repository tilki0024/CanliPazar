import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'veterinarian_detail_screen.dart';

class VeterinarianSearchScreen extends StatefulWidget {
  const VeterinarianSearchScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianSearchScreen> createState() =>
      _VeterinarianSearchScreenState();
}

class _VeterinarianSearchScreenState extends State<VeterinarianSearchScreen> {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCity = 'Tüm Şehirler';
  String _selectedAnimalType = 'Tüm Hayvan Türleri';
  String _selectedService = 'Tüm Hizmetler';
  bool _onlyAvailable = false;
  bool _homeVisit = false;
  bool _emergencyService = false;

  final List<String> cities = [
    'Tüm Şehirler',
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
  ];

  final List<String> animalTypes = [
    'Tüm Hayvan Türleri',
    'Sığır',
    'Koyun',
    'Keçi',
    'Manda',
    'At',
    'Eşek',
    'Tavuk',
    'Hindi',
    'Ördek',
    'Kaz',
    'Domuz',
    'Tavşan',
    'Köpek',
    'Kedi',
    'Kümes Hayvanları',
    'Arı',
    'Balık',
    'Diğer',
  ];

  final List<String> services = [
    'Tüm Hizmetler',
    'Genel Muayene',
    'Aşı Uygulaması',
    'Cerrahi Müdahale',
    'Doğum Yardımı',
    'Suni Tohumlama',
    'Gebelik Teşhisi',
    'Soy Kütüğü Belgesi',
    'Sağlık Raporu',
    'Kan Tahlili',
    'Dışkı Tahlili',
    'İdrar Tahlili',
    'Radyografi (X-Ray)',
    'Ultrasonografi',
    'Mikroskopik İnceleme',
    'Parazit Tedavisi',
    'Antibiyotik Tedavisi',
    'Vitamin Takviyesi',
    'Beslenme Danışmanlığı',
    'Sürü Sağlığı Planı',
    'Acil Müdahale',
    'Ev Ziyareti',
    'Çiftlik Ziyareti',
    'Eğitim ve Danışmanlık',
    'Sertifika Düzenleme',
    'İlaç Reçetesi',
    'Kontrol Muayenesi',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required String selectedValue,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: SafeFonts.poppins(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchFilter({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        label,
        style: SafeFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Veteriner Ara',
          style: SafeFonts.poppins(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama ve Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: backgroundColor,
            child: Column(
              children: [
                // Arama kutusu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Veteriner ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filtreler
                _buildFilterChip(
                  label: 'Şehir',
                  selectedValue: _selectedCity,
                  options: cities,
                  onChanged: (value) => setState(() => _selectedCity = value),
                ),
                _buildFilterChip(
                  label: 'Hayvan Türü',
                  selectedValue: _selectedAnimalType,
                  options: animalTypes,
                  onChanged: (value) =>
                      setState(() => _selectedAnimalType = value),
                ),
                _buildFilterChip(
                  label: 'Hizmet',
                  selectedValue: _selectedService,
                  options: services,
                  onChanged: (value) =>
                      setState(() => _selectedService = value),
                ),

                // Switch filtreler
                _buildSwitchFilter(
                  label: 'Sadece müsait veterinerler',
                  value: _onlyAvailable,
                  onChanged: (value) => setState(() => _onlyAvailable = value),
                ),
                _buildSwitchFilter(
                  label: 'Ev ziyareti yapanlar',
                  value: _homeVisit,
                  onChanged: (value) => setState(() => _homeVisit = value),
                ),
                _buildSwitchFilter(
                  label: 'Acil hizmet verenler',
                  value: _emergencyService,
                  onChanged: (value) =>
                      setState(() => _emergencyService = value),
                ),
              ],
            ),
          ),

          // Sonuçlar
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isVeterinarian', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Bir hata oluştu: ${snapshot.error}',
                      style: SafeFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final veterinarians = snapshot.data?.docs ?? [];

                // Filtreleme
                List<QueryDocumentSnapshot> filteredVeterinarians =
                    veterinarians.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Arama filtresi
                  if (_searchQuery.isNotEmpty) {
                    final clinicName = data['veterinarianClinicName']
                            ?.toString()
                            .toLowerCase() ??
                        '';
                    final phone =
                        data['veterinarianPhone']?.toString().toLowerCase() ??
                            '';
                    final description = data['veterinarianDescription']
                            ?.toString()
                            .toLowerCase() ??
                        '';

                    if (!clinicName.contains(_searchQuery.toLowerCase()) &&
                        !phone.contains(_searchQuery.toLowerCase()) &&
                        !description.contains(_searchQuery.toLowerCase())) {
                      return false;
                    }
                  }

                  // Şehir filtresi
                  if (_selectedCity != 'Tüm Şehirler') {
                    final cities =
                        List<String>.from(data['veterinarianCities'] ?? []);
                    if (!cities.contains(_selectedCity)) {
                      return false;
                    }
                  }

                  // Hayvan türü filtresi
                  if (_selectedAnimalType != 'Tüm Hayvan Türleri') {
                    final animalTypes = List<String>.from(
                        data['veterinarianAnimalTypes'] ?? []);
                    if (!animalTypes.contains(_selectedAnimalType)) {
                      return false;
                    }
                  }

                  // Hizmet filtresi
                  if (_selectedService != 'Tüm Hizmetler') {
                    final services =
                        List<String>.from(data['veterinarianServices'] ?? []);
                    if (!services.contains(_selectedService)) {
                      return false;
                    }
                  }

                  // Müsaitlik filtresi
                  if (_onlyAvailable && data['veterinarianAvailable'] != true) {
                    return false;
                  }

                  // Ev ziyareti filtresi
                  if (_homeVisit && data['veterinarianHomeVisit'] != true) {
                    return false;
                  }

                  // Acil hizmet filtresi
                  if (_emergencyService &&
                      data['veterinarianEmergencyService'] != true) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredVeterinarians.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Arama kriterlerinize uygun veteriner bulunamadı',
                          style: SafeFonts.poppins(
                            fontSize: 16,
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Filtreleri değiştirerek tekrar deneyin',
                          style: SafeFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredVeterinarians.length,
                  itemBuilder: (context, index) {
                    final veterinarian = filteredVeterinarians[index].data()
                        as Map<String, dynamic>;
                    final veterinarianId = filteredVeterinarians[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          veterinarian['veterinarianClinicName'] ??
                              'Veteriner Klinik',
                          style: SafeFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (veterinarian['veterinarianPhone'] != null)
                              Text(
                                '📞 ${veterinarian['veterinarianPhone']}',
                                style: SafeFonts.poppins(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            if (veterinarian['veterinarianCities'] != null &&
                                (veterinarian['veterinarianCities'] as List)
                                    .isNotEmpty)
                              Text(
                                '📍 ${(veterinarian['veterinarianCities'] as List).join(', ')}',
                                style: SafeFonts.poppins(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            if (veterinarian['veterinarianAvailable'] == true)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🟢 Müsait',
                                  style: SafeFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: textSecondary,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VeterinarianDetailScreen(
                                veterinarianId: veterinarianId,
                                veterinarianData: veterinarian,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
