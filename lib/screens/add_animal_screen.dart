import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/animal_categories.dart';
import '../services/pricing_service.dart';
import '../widgets/price_tag.dart';
import '../resources/animal_firestore_methods.dart';
import '../resources/auth_methods.dart';
import '../models/user.dart' as model;
import '../utils/safe_fonts.dart';
import 'add_feed_screen.dart';
import 'location_picker_screen.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({Key? key}) : super(key: key);

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLocationChecking = true; // Konum kontrolü yapılıyor mu
  bool _hasLocation = false; // Kullanıcının konumu var mı

  // Form verileri
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _transportInfoController =
      TextEditingController();
  final TextEditingController _parentInfoController = TextEditingController();
  final TextEditingController _veterinarianContactController =
      TextEditingController();

  String _selectedAnimalType = AnimalCategories.animalTypes.first;
  String _selectedSpecies = AnimalCategories.animalSpecies.first;
  String _selectedBreed = ''; // Bu initState'de düzgün set edilecek
  String _selectedGender = AnimalCategories.genders.first;
  String _selectedHealthStatus = AnimalCategories.healthStatuses.first;
  String _selectedPurpose = AnimalCategories.purposes.first;
  String _selectedSellerType = AnimalCategories.sellerTypes.first;

  bool _isPregnant = false;
  bool _isNegotiable = false;
  bool _isUrgentSale = false;

  List<File> _selectedImages = [];
  List<String> _selectedVaccinations = [];

  // Adres bilgileri (mevcut kullanıcıdan alınacak)
  String _country = '';
  String _state = '';
  String _city = '';

  // AnimalDiscoverScreen'den alınan tasarım renkleri
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF424242);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Responsive helper methods
  bool get isSmallScreen => MediaQuery.of(context).size.width < 360;
  bool get isMediumScreen =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();

    // Breed'i doğru şekilde initialize et
    final availableBreeds =
        AnimalCategories.getBreedsForSpecies(_selectedSpecies);
    if (availableBreeds.isNotEmpty) {
      _selectedBreed = availableBreeds.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();

    _transportInfoController.dispose();
    _parentInfoController.dispose();
    _veterinarianContactController.dispose();
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Konum kontrolü yapılıyorsa loading göster
    if (_isLocationChecking) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: _buildLocationCheckingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingWidget()
          : SafeArea(
              child: Column(
                children: [
                  _buildModernAppBar(),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildBasicInfoStep(),
                          _buildAnimalDetailsStep(),
                          _buildHealthInfoStep(),
                          _buildPriceAndPhotosStep(),
                          _buildReviewStep(),
                        ],
                      ),
                    ),
                  ),
                  _buildModernNavigationButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationCheckingWidget() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Konum bilginiz kontrol ediliyor...',
              style: SafeFonts.poppins(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'İlan Ekle',
            style: SafeFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Temel Bilgiler';
      case 1:
        return 'Hayvan Detayları';
      case 2:
        return 'Sağlık Bilgileri';
      case 3:
        return 'Fiyat ve Fotoğraflar';
      case 4:
        return 'Önizleme';
      default:
        return '';
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(40),
          margin: EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated loading indicator
              Container(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    // Outer circle
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    // Inner circle
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          warningColor,
                        ),
                      ),
                    ),
                    // Center icon
                    Center(
                      child: Text(
                        '🐄',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'İlanınız Yayınlanıyor',
                style: SafeFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Lütfen bekleyiniz...',
                style: SafeFonts.poppins(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),

              SizedBox(height: 16),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(
                        0.3 + (index * 0.2),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgressIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(5, (index) {
              bool isCompleted = index < _currentStep;
              bool isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? warningColor
                            : isCurrent
                                ? primaryColor
                                : dividerColor,
                        border: Border.all(
                          color: isCompleted
                              ? warningColor
                              : isCurrent
                                  ? primaryColor
                                  : dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: SafeFonts.poppins(
                                  color:
                                      isCurrent ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),

                    // Progress line
                    if (index < 4)
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? warningColor : dividerColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          SizedBox(height: 8),

          // Progress percentage
          Text(
            '${((_currentStep + 1) / 5 * 100).round()}% Tamamlandı',
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildModernProgressIndicator(),
            SizedBox(height: 8),
            // Header card - AnimalDiscoverScreen stilinde
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🐄', style: TextStyle(fontSize: 24)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temel Bilgiler',
                          style: SafeFonts.poppins(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Hayvanınızın temel özelliklerini girin',
                          style: SafeFonts.poppins(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // İlan Tipi Seçimi - Hayvan İlanı / Yem İlanı
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Hayvan İlanı - mevcut akışı devam ettirir (hiçbir şey yapmaz)
                    },
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('🐐🐄', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 12),
                          Text(
                            'Hayvan İlanı',
                            style: SafeFonts.poppins(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Yem İlanı - AddFeedScreen'e yönlendir
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFeedScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: warningColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.agriculture,
                              color: warningColor, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'Yem İlanı',
                            style: SafeFonts.poppins(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Animal type selection cards - AnimalDiscoverScreen stilinde
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pets, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hayvan Bilgileri',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Hayvan Türü',
                    value: _selectedAnimalType,
                    items: AnimalCategories.animalTypes,
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimalType = value!;
                        final availableSpecies =
                            AnimalCategories.getSpeciesForType(value);
                        if (!availableSpecies.contains(_selectedSpecies)) {
                          _selectedSpecies = availableSpecies.first;
                        }

                        // Breed'i de kontrol et ve gerekirse reset et
                        final availableBreeds =
                            AnimalCategories.getBreedsForSpecies(
                                _selectedSpecies);
                        if (!availableBreeds.contains(_selectedBreed)) {
                          _selectedBreed = availableBreeds.first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Tür',
                    value: _selectedSpecies,
                    items:
                        AnimalCategories.getSpeciesForType(_selectedAnimalType),
                    icon: Icons.pets,
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecies = value!;
                        final availableBreeds =
                            AnimalCategories.getBreedsForSpecies(value);
                        if (!availableBreeds.contains(_selectedBreed)) {
                          _selectedBreed = availableBreeds.first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Irk',
                    value: _selectedBreed,
                    items:
                        AnimalCategories.getBreedsForSpecies(_selectedSpecies),
                    icon: Icons.star,
                    onChanged: (value) {
                      print('🔍 Breed changed to: $value');
                      setState(() {
                        _selectedBreed = value!;
                      });
                      print('🔍 Breed set to: $_selectedBreed');
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Cinsiyet',
                    value: _selectedGender,
                    items: AnimalCategories.genders,
                    icon:
                        _selectedGender == 'Erkek' ? Icons.male : Icons.female,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // İlan Açıklaması
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'İlan Açıklaması',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final charCount = _descriptionController.text.length;
                      final isValid = charCount >= 10;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: dividerColor),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              style: SafeFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'İlanınız hakkında detaylı bilgi verin...',
                                hintStyle: SafeFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              maxLines: 5,
                              minLines: 3,
                              onChanged: (value) {
                                setState(() {});
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'İlan açıklaması gereklidir';
                                }
                                if (value.length < 10) {
                                  return 'Açıklama en az 10 karakter olmalıdır';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Minimum 10 karakter',
                                style: SafeFonts.poppins(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                '$charCount/10',
                                style: SafeFonts.poppins(
                                  fontSize: 11,
                                  color: isValid ? primaryColor : textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 80), // Navigation button space
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernProgressIndicator(),
          SizedBox(height: 8),
          // Header card - AnimalDiscoverScreen stilinde
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.info_outline, color: primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hayvan Detayları',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Yaş, ağırlık ve diğer detayları girin',
                        style: SafeFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Yaş ve doğum tarihi card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cake, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yaş Bilgileri',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Ay ve Yaş kutucukları
                Row(
                  children: [
                    // Ay kutucuğu
                    Expanded(
                      child: Container(
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
                              'Ay',
                              style: SafeFonts.poppins(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _monthController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ay girin',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: SafeFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Yaş kutucuğu
                    Expanded(
                      child: Container(
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
                              'Yaş',
                              style: SafeFonts.poppins(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Yaş girin',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: SafeFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Ağırlık ve amaç card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fiziksel Özellikler',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Ağırlık
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _weightController,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ağırlık (kg)',
                      labelStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.monitor_weight,
                          color: primaryColor, size: 18),
                      suffixText: 'kg',
                      suffixStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ağırlık gereklidir';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 0 || weight > 2000) {
                        return 'Geçerli bir ağırlık girin (0-2000 kg)';
                      }
                      return null;
                    },
                  ),
                ),

                SizedBox(height: 16),

                // Amaç
                _buildModernDropdownField(
                  label: 'Amaç',
                  value: _selectedPurpose,
                  items: AnimalCategories.purposes,
                  icon: Icons.flag,
                  onChanged: (value) {
                    setState(() {
                      _selectedPurpose = value!;
                    });
                  },
                ),

                // Hamilelik durumu (sadece dişi hayvanlar için)
                if (_selectedGender == 'Dişi') ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pregnant_woman,
                            color: primaryColor, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gebe',
                            style: SafeFonts.poppins(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isPregnant,
                          onChanged: (value) {
                            setState(() {
                              _isPregnant = value;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20),

          // Ebeveyn bilgisi card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.family_restroom, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ebeveyn Bilgisi (Opsiyonel)',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _parentInfoController,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Anne/baba ırk bilgileri',
                      labelStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Anne/baba ırk bilgileri...',
                      hintStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(Icons.family_restroom,
                          color: primaryColor, size: 18),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 80), // Navigation button space
        ],
      ),
    );
  }

  Widget _buildHealthInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernProgressIndicator(),
          SizedBox(height: 8),
          // Header card - AnimalDiscoverScreen stilinde
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.health_and_safety,
                      color: primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sağlık Bilgileri',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Sağlık durumu ve aşı bilgilerini girin',
                        style: SafeFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Sağlık durumu card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sağlık Durumu',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildModernDropdownField(
                  label: 'Sağlık Durumu',
                  value: _selectedHealthStatus,
                  items: AnimalCategories.healthStatuses,
                  icon: Icons.health_and_safety,
                  onChanged: (value) {
                    setState(() {
                      _selectedHealthStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Aşılar card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vaccines, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yapılan Aşılar',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AnimalCategories.vaccineTypes.map((vaccine) {
                    final isSelected = _selectedVaccinations.contains(vaccine);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedVaccinations.remove(vaccine);
                          } else {
                            _selectedVaccinations.add(vaccine);
                          }
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryColor : dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            if (isSelected) SizedBox(width: 6),
                            Text(
                              vaccine,
                              style: SafeFonts.poppins(
                                color: isSelected ? Colors.white : textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Veteriner iletişim card - Kompakt versiyon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
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
                    Icon(Icons.medical_services, color: primaryColor, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Veteriner İletişim (Opsiyonel)',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _veterinarianContactController,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Veteriner bilgileri',
                      labelStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Adı ve telefon numarası...',
                      hintStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(Icons.medical_services,
                          color: primaryColor, size: 16),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 60), // Navigation button space - azaltıldı
        ],
      ),
    );
  }

  Widget _buildPriceAndPhotosStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Fiyat ve Fotoğraflar',
              style: SafeFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 20),

            // Fiyat
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: TextFormField(
                controller: _priceController,
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Fiyat (TL)',
                  labelStyle: SafeFonts.poppins(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon:
                      Icon(Icons.attach_money, color: primaryColor, size: 18),
                  prefixText: '₺ ',
                  prefixStyle: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gereklidir';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Geçerli bir fiyat girin (0\'dan büyük olmalı)';
                  }
                  // Fiyat kısıtlaması kaldırıldı - sadece 0'dan büyük olması yeterli
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

            // Fiyat önizlemesi
            if (_priceController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              PriceTag(
                price: double.tryParse(_priceController.text) ?? 0,
                isNegotiable: _isNegotiable,
                isUrgent: _isUrgentSale,
              ),
            ],

            SizedBox(height: 16),

            // Pazarlık ve acil satış
            SwitchListTile(
              title: Text('Pazarlık Yapılabilir'),
              value: _isNegotiable,
              onChanged: (value) {
                setState(() {
                  _isNegotiable = value;
                });
              },
              activeColor: primaryColor,
            ),

            SwitchListTile(
              title: Text('Acil Satış'),
              value: _isUrgentSale,
              onChanged: (value) {
                setState(() {
                  _isUrgentSale = value;
                });
              },
              activeColor: warningColor,
            ),

            SizedBox(height: 16),

            // Satıcı tipi
            _buildModernDropdownField(
              label: 'Satıcı Tipi',
              value: _selectedSellerType,
              items: AnimalCategories.sellerTypes,
              icon: Icons.business,
              onChanged: (value) {
                setState(() {
                  _selectedSellerType = value!;
                });
              },
            ),

            SizedBox(height: 16),

            // Nakliye bilgisi
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: TextFormField(
                controller: _transportInfoController,
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Nakliye Bilgisi',
                  labelStyle: SafeFonts.poppins(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: 'Nakliye şartları ve bilgileri...',
                  hintStyle: SafeFonts.poppins(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon:
                      Icon(Icons.local_shipping, color: primaryColor, size: 18),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
            ),

            SizedBox(height: 20),

            // Fotoğraf seçimi
            Text(
              'Fotoğraflar (En az 3 adet, en fazla 10)',
              style: SafeFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildPhotoSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernProgressIndicator(),
            SizedBox(height: 8),
            // Kompakt header
            Row(
              children: [
                Icon(Icons.preview, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'İlan Önizleme',
                  style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // İlan önizlemesi - Modern card tasarımı
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık bölümü
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$_selectedBreed $_selectedSpecies',
                                style: SafeFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Fiyat (küçük)
                            if (_priceController.text.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: _isUrgentSale
                                      ? LinearGradient(
                                          colors: [
                                            Color(0xFFE91E63),
                                            Color(0xFFC2185B)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Color(0xFF2E7D32),
                                            Color(0xFF388E3C)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  PricingService.formatPrice(
                                      double.tryParse(_priceController.text) ??
                                          0),
                                  style: SafeFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Temel bilgiler - Kompakt chip'ler
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _selectedAnimalType,
                                style: SafeFonts.poppins(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'Erkek'
                                    ? Color(0xFF2196F3).withOpacity(0.1)
                                    : Color(0xFFE91E63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedGender == 'Erkek'
                                      ? Color(0xFF2196F3).withOpacity(0.3)
                                      : Color(0xFFE91E63).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _selectedGender,
                                style: SafeFonts.poppins(
                                  color: _selectedGender == 'Erkek'
                                      ? Color(0xFF2196F3)
                                      : Color(0xFFE91E63),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // İçerik bölümü - Kompakt
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İlan Açıklaması - Kompakt
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.edit_note,
                                color: primaryColor, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'İlan Açıklaması',
                                    style: SafeFonts.poppins(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _descriptionController.text.isEmpty
                                        ? 'Açıklama girilmemiş'
                                        : _descriptionController.text,
                                    style: SafeFonts.poppins(
                                      color: _descriptionController.text.isEmpty
                                          ? textSecondary
                                          : textPrimary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Fotoğraf sayısı - Kompakt
                        Row(
                          children: [
                            Icon(Icons.photo_library,
                                color: primaryColor, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Fotoğraflar: ',
                              style: SafeFonts.poppins(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedImages.length >= 3
                                    ? primaryColor.withOpacity(0.1)
                                    : warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedImages.length >= 3
                                      ? primaryColor.withOpacity(0.3)
                                      : warningColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_selectedImages.length}/10',
                                style: SafeFonts.poppins(
                                  color: _selectedImages.length >= 3
                                      ? primaryColor
                                      : warningColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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

            SizedBox(height: 16),

            // Kompakt uyarı
            if (_selectedImages.length < 3)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: warningColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: warningColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En az 3 fotoğraf eklemeniz önerilir',
                        style: SafeFonts.poppins(
                          color: warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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

  Widget _buildPhotoSelector() {
    return Column(
      children: [
        // Seçilen fotoğraflar
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return _buildAddPhotoButton();
                }
                return _buildPhotoItem(_selectedImages[index], index);
              },
            ),
          ),
        ] else ...[
          _buildAddPhotoButton(),
        ],

        SizedBox(height: 8),
        Text(
          'Seçilen: ${_selectedImages.length}/10',
          style: TextStyle(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _pickImages,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: textSecondary),
            Text('Fotoğraf\nEkle', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(File photo, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(photo),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: Container(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: Icon(Icons.arrow_back_ios, size: 16),
                    label: Text(
                      'Önceki',
                      style: SafeFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: Container(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _currentStep == 4
                      ? _publishListing
                      : () {
                          print('🔘 Sonraki button pressed!');
                          _nextStep();
                        },
                  icon: Icon(
                    _currentStep == 4
                        ? Icons.publish_rounded
                        : Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  label: Text(
                    _currentStep == 4 ? 'İlanı Yayınla' : 'İleri',
                    style: SafeFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentStep == 4 ? warningColor : primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _loadUserLocation({bool showDialogIfMissing = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLocationChecking = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final country = data['country'] ?? '';
        final state = data['state'] ?? '';
        final city = data['city'] ?? '';

        setState(() {
          _country = country;
          _state = state;
          _city = city;
          _hasLocation = country.isNotEmpty && city.isNotEmpty;
          _isLocationChecking = false;
        });

        // Konum yoksa dialog göster (sadece ilk kontrolde)
        if (!_hasLocation && mounted && showDialogIfMissing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLocationRequiredDialog();
          });
        }
      } else {
        setState(() {
          _isLocationChecking = false;
        });
        // Kullanıcı belgesi yoksa konum dialog'u göster (sadece ilk kontrolde)
        if (mounted && showDialogIfMissing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLocationRequiredDialog();
          });
        }
      }
    } catch (e) {
      print('Konum yükleme hatası: $e');
      setState(() {
        _isLocationChecking = false;
      });
    }
  }

  void _showLocationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_off,
                  color: warningColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Konum Gerekli',
                  style: SafeFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İlan ekleyebilmek için önce konumunuzu belirlemeniz gerekmektedir.',
                style: SafeFonts.poppins(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Konumunuz ilanlarınızda görüntülenecek ve alıcıların sizi bulmasını kolaylaştıracaktır.',
                        style: SafeFonts.poppins(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Geri dön
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Vazgeç',
                style: SafeFonts.poppins(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLocationPicker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Konum Belirle',
                    style: SafeFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLocationPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(
          isFromSettings: false,
        ),
      ),
    );

    // Konum seçildikten sonra tekrar kontrol et (dialog gösterme)
    await _loadUserLocation(showDialogIfMissing: false);

    // Hala konum yoksa geri dön
    if (!_hasLocation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Konum belirlenmedi. İlan eklemek için konum gereklidir.'),
          backgroundColor: warningColor,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12;
    months += now.month - birthDate.month;

    // Eğer gün henüz gelmemişse bir ay çıkar
    if (now.day < birthDate.day) {
      months--;
    }

    return months.clamp(0, 240); // 0-240 ay arası sınırla
  }

  void _nextStep() {
    print('🚀 _nextStep called, current step: $_currentStep');
    if (_currentStep < 4) {
      print('🔍 Calling _validateCurrentStep...');
      if (_validateCurrentStep()) {
        print('✅ Validation passed, navigating to next step');
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('❌ Validation failed, staying on current step');
      }
    } else {
      print('⚠️ Already at last step');
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    print('🔍 Validating step $_currentStep');
    print(
        '🔍 Current values - Type: $_selectedAnimalType, Species: $_selectedSpecies, Breed: $_selectedBreed');

    switch (_currentStep) {
      case 0: // Temel bilgiler
        // Description kontrolü
        final description = _descriptionController.text;
        print('🔍 Description length: ${description.length}');
        print('🔍 Description: "$description"');

        if (description.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İlan açıklaması gereklidir'),
              backgroundColor: errorColor,
            ),
          );
          return false;
        }

        if (description.length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Açıklama en az 10 karakter olmalıdır (Şu an: ${description.length} karakter)'),
              backgroundColor: warningColor,
            ),
          );
          return false;
        }

        // Dropdown'ları kontrol et
        if (_selectedBreed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lütfen hayvan ırkını seçiniz'),
              backgroundColor: errorColor,
            ),
          );
          return false;
        }

        final isValid = _formKey.currentState?.validate() ?? false;
        print('🔍 Form validation result: $isValid');

        if (isValid) {
          print('✅ All validations passed for step 0');
        } else {
          print('❌ Form validation failed');
        }

        return isValid;

      case 1: // Hayvan detayları
        if (_monthController.text.isEmpty && _ageController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ay veya yaş bilgisi gereklidir')),
          );
          return false;
        }

        if (_weightController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ağırlık gereklidir')),
          );
          return false;
        }

        final weight = double.tryParse(_weightController.text);
        if (weight == null || weight < 0 || weight > 2000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçerli bir ağırlık girin (0-2000 kg)')),
          );
          return false;
        }

        // Ay validasyonu
        if (_monthController.text.isNotEmpty) {
          final month = int.tryParse(_monthController.text);
          if (month == null || month < 0 || month > 240) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Geçerli bir ay girin (0-240)')),
            );
            return false;
          }
        }

        // Yaş validasyonu
        if (_ageController.text.isNotEmpty) {
          final age = int.tryParse(_ageController.text);
          if (age == null || age < 0 || age > 20) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Geçerli bir yaş girin (0-20)')),
            );
            return false;
          }
        }

        return true;

      case 2: // Sağlık bilgileri
        return true; // Opsiyonel

      case 3: // Fiyat ve fotoğraflar
        if (_priceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fiyat gereklidir')),
          );
          return false;
        }

        final price = double.tryParse(_priceController.text);
        if (price == null || price <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçerli bir fiyat girin')),
          );
          return false;
        }

        // Fiyat kısıtlaması kaldırıldı - sadece 0'dan büyük kontrolü yapılıyor

        if (_selectedImages.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('En az 3 fotoğraf eklemelisiniz')),
          );
          return false;
        }

        return true;

      case 4: // Önizleme
        return true;

      default:
        return true;
    }
  }

  void _pickImages() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En fazla 10 fotoğraf seçebilirsiniz')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    for (var image in images) {
      if (_selectedImages.length < 10) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _publishListing() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fotoğrafları byte'lara çevir
      List<Uint8List> imageBytes = await _convertImagesToBytes();

      // İlan oluştur
      await _createAnimalPost(imageBytes);

      // Loading'i kapat
      setState(() {
        _isLoading = false;
      });

      // Başarı bildirimi göster
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildSuccessDialog();
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildErrorDialog(error);
      },
    );
  }

  Future<List<Uint8List>> _convertImagesToBytes() async {
    List<Uint8List> imageBytes = [];

    for (File image in _selectedImages) {
      // Görseli sıkıştır
      final compressedBytes = await _compressImage(image);
      imageBytes.add(compressedBytes);
    }

    return imageBytes;
  }

  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 1200,
        minHeight: 1200,
        quality: 70, // %70 kalite
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return result;
      }
      // Sıkıştırma başarısız olursa orijinal dosyayı oku
      return await imageFile.readAsBytes();
    } catch (e) {
      print('❌ Görsel sıkıştırma hatası: $e');
      // Hata durumunda orijinal dosyayı oku
      return await imageFile.readAsBytes();
    }
  }

  Future<void> _createAnimalPost(List<Uint8List> imageBytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    // Kullanıcı bilgilerini al
    final model.User userData = await AuthMethods().getUserDetails();

    // AnimalFirestoreMethods servisini kullan
    final String result = await AnimalFirestoreMethods().uploadAnimal(
      description: _descriptionController.text,
      files: imageBytes,
      uid: user.uid,
      username: userData.username?.isEmpty == true
          ? 'Bilinmeyen'
          : userData.username ?? 'Bilinmeyen',
      profImage: userData.photoUrl ?? '',
      country: _country,
      state: _state,
      city: _city,
      animalType: _selectedAnimalType.toLowerCase(),
      animalSpecies: _selectedSpecies,
      animalBreed: _selectedBreed,
      ageInMonths: _monthController.text.isNotEmpty
          ? int.parse(_monthController.text)
          : (_ageController.text.isNotEmpty
              ? int.parse(_ageController.text) * 12
              : 0),
      gender: _selectedGender,
      weightInKg: double.parse(_weightController.text),
      priceInTL: double.parse(_priceController.text),
      healthStatus: _selectedHealthStatus,
      vaccinations: _selectedVaccinations,
      purpose: _selectedPurpose,
      isPregnant: _isPregnant,
      birthDate: null,
      parentInfo: _parentInfoController.text.isEmpty
          ? null
          : _parentInfoController.text,
      certificates: [], // TODO: Implement certificate upload
      isNegotiable: _isNegotiable,
      sellerType: _selectedSellerType,
      transportInfo: _transportInfoController.text,
      isUrgentSale: _isUrgentSale,
      veterinarianContact: _veterinarianContactController.text.isEmpty
          ? null
          : _veterinarianContactController.text,
      additionalInfo: {},
    );

    if (result != "success") {
      throw Exception('Hayvan ilanı kaydedilemedi: $result');
    }
  }

  // Modern UI Helper Methods
  Widget _buildStepHeaderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            spreadRadius: 1,
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SafeFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: SafeFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: SafeFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    IconData? icon,
    String? emoji,
    required Function(String?) onChanged,
  }) {
    // Safety check: value items listesinde var mı?
    final safeValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    if (safeValue != value) {
      print(
          '⚠️ Warning: $label dropdown value "$value" not in items list. Using "$safeValue" instead.');
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        icon: Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
            size: 20,
          ),
        ),
        style: SafeFonts.poppins(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: SafeFonts.poppins(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: SafeFonts.poppins(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.only(left: 12, right: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: emoji != null
                ? Text(emoji, style: TextStyle(fontSize: 18))
                : Icon(icon, color: primaryColor, size: 18),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 50, minHeight: 40),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _buildModernTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: TextFormField(
        controller: controller,
        style: SafeFonts.poppins(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: SafeFonts.poppins(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: SafeFonts.poppins(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: warningColor,
                size: 50,
              ),
            ),

            SizedBox(height: 20),

            Text(
              'İlan Başarıyla Yayınlandı!',
              style: SafeFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            Text(
              'Hayvan ilanınız başarıyla yayınlandı. Ana sayfada görünmeye başlayacak.',
              style: SafeFonts.poppins(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dialog'u kapat
                      // Form'u temizle ve başa dön
                      _resetForm();
                    },
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Yeni İlan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dialog'u kapat
                    },
                    icon: Icon(Icons.close),
                    label: Text('Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(String error) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: errorColor,
                size: 50,
              ),
            ),

            SizedBox(height: 20),

            Text(
              'İlan Yayınlanamadı',
              style: SafeFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            Text(
              'Bir hata oluştu: $error',
              style: SafeFonts.poppins(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                },
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _descriptionController.clear();
      _priceController.clear();
      _weightController.clear();
      _transportInfoController.clear();
      _parentInfoController.clear();
      _veterinarianContactController.clear();

      _selectedAnimalType = AnimalCategories.animalTypes.first;
      _selectedSpecies = AnimalCategories.animalSpecies.first;
      _selectedBreed = AnimalCategories.animalBreeds.first;
      _selectedGender = AnimalCategories.genders.first;
      _selectedHealthStatus = AnimalCategories.healthStatuses.first;
      _selectedPurpose = AnimalCategories.purposes.first;
      _selectedSellerType = AnimalCategories.sellerTypes.first;

      _isPregnant = false;
      _isNegotiable = false;
      _isUrgentSale = false;

      _selectedImages.clear();
      _selectedVaccinations.clear();
      _monthController.clear();
      _ageController.clear();
    });

    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
