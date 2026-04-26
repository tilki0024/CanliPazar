import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/feed_categories.dart';
import '../resources/feed_firestore_methods.dart';
import '../resources/auth_methods.dart';
import '../utils/safe_fonts.dart';

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({Key? key}) : super(key: key);

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _energyController = TextEditingController();
  final TextEditingController _productionDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _transportInfoController = TextEditingController();

  String _selectedFeedType = FeedCategories.feedTypes.first;
  String _selectedFeedCategory = FeedCategories.categories[1]; // İlk kategori
  String _selectedAnimalType = FeedCategories.animalTypes.first;
  String _selectedQuantityUnit = FeedCategories.quantityUnits.first;
  String _selectedPriceUnit = FeedCategories.priceUnits.first;
  String _selectedPackagingType = FeedCategories.packagingTypes.first;
  String _selectedSellerType = FeedCategories.sellerTypes.first;

  bool _isOrganic = false;
  bool _isUrgentSale = false;
  bool _isBulkSale = false;
  bool _isLocal = true;
  bool _isNegotiable = false;

  List<File> _selectedImages = [];
  String _country = '';
  String _state = '';
  String _city = '';

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _proteinController.dispose();
    _energyController.dispose();
    _productionDateController.dispose();
    _expiryDateController.dispose();
    _transportInfoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _country = data['country'] ?? '';
          _state = data['state'] ?? '';
          _city = data['city'] ?? '';
        });
      }
    } catch (e) {
      print('Konum yükleme hatası: $e');
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  Future<void> _uploadFeed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen en az bir fotoğraf seçin')),
      );
      return;
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Dialog kapatılamaz
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'İlanınız yayınlanıyor...',
                  style: SafeFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final userData = await AuthMethods().getUserDetails();

      List<Uint8List> imageBytes = [];
      for (var file in _selectedImages) {
        // Görseli sıkıştır
        final compressedBytes = await _compressImage(file);
        imageBytes.add(compressedBytes);
      }

      final result = await FeedFirestoreMethods().uploadFeed(
        description: _descriptionController.text.trim(),
        files: imageBytes,
        uid: user.uid,
        username: userData.username ?? 'Kullanıcı',
        profImage: userData.photoUrl ?? '',
        country: _country,
        state: _state,
        city: _city,
        feedType: _selectedFeedType,
        feedCategory: _selectedFeedCategory,
        animalType: _selectedAnimalType,
        quantityInKg: double.tryParse(_quantityController.text) ?? 0,
        quantityUnit: _selectedQuantityUnit,
        priceInTL: double.tryParse(_priceController.text) ?? 0,
        priceUnit: _selectedPriceUnit,
        brand: _brandController.text.trim(),
        productionDate: _productionDateController.text.trim().isEmpty
            ? null
            : _productionDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : _expiryDateController.text.trim(),
        proteinPercentage: _proteinController.text.trim().isEmpty
            ? null
            : double.tryParse(_proteinController.text),
        energyValue: _energyController.text.trim().isEmpty
            ? null
            : double.tryParse(_energyController.text),
        isOrganic: _isOrganic,
        packagingType: _selectedPackagingType,
        isUrgentSale: _isUrgentSale,
        isBulkSale: _isBulkSale,
        isLocal: _isLocal,
        sellerType: _selectedSellerType,
        transportInfo: _transportInfoController.text.trim(),
        isNegotiable: _isNegotiable,
        additionalInfo: null,
      );

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);
      }

      if (result == "success") {
        if (mounted) {
          // Anasayfaya yönlendir
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        throw Exception(result);
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  bool _hasUnsavedChanges() {
    return _descriptionController.text.isNotEmpty ||
        _priceController.text.isNotEmpty ||
        _quantityController.text.isNotEmpty ||
        _selectedImages.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış'),
        content: Text('Kaydedilmemiş değişiklikler var. Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çık'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        title: Text(
          'Yem İlanı Ekle',
          style: SafeFonts.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
        body: Form(
          key: _formKey,
          child: Stepper(
          currentStep: _currentStep,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text('Geri'),
                    ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        details.stepIndex < 2 ? 'Devam' : 'Yayınla',
                        style: SafeFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (details.stepIndex == 0) ...[
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                    ),
                  ],
                ],
              ),
            );
          },
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _uploadFeed();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          steps: [
            Step(
              title: Text('Temel Bilgiler'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? 'Açıklama gerekli' : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFeedType,
                    decoration: InputDecoration(labelText: 'Yem Türü'),
                    items: FeedCategories.feedTypes.map((type) {
                      String displayName = type;
                      if (type == 'kaba yem') displayName = 'Kaba Yem';
                      else if (type == 'konsantre yem') displayName = 'Konsantre Yem';
                      else if (type == 'yem katkısı') displayName = 'Yem Katkısı';
                      return DropdownMenuItem(
                        value: type,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFeedType = value!;
                        // Yem türü değiştiğinde kategoriyi sıfırla ve ilk kategoriyi seç
                        final availableCategories = FeedCategories.getCategoriesByFeedType(_selectedFeedType);
                        if (availableCategories.isNotEmpty) {
                          _selectedFeedCategory = availableCategories.first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFeedCategory,
                    decoration: InputDecoration(labelText: 'Yem Kategorisi'),
                    items: FeedCategories.getCategoriesByFeedType(_selectedFeedType)
                        .map((category) {
                      return DropdownMenuItem(
                          value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedFeedCategory = value!),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedAnimalType,
                    decoration: InputDecoration(labelText: 'Hayvan Türü'),
                    items: FeedCategories.animalTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAnimalType = value!),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(labelText: 'Marka'),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: 'Miktar'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty ? 'Miktar gerekli' : null,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedQuantityUnit,
                          decoration: InputDecoration(labelText: 'Birim'),
                          items: FeedCategories.quantityUnits.map((unit) {
                            return DropdownMenuItem(
                                value: unit, child: Text(unit));
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedQuantityUnit = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              title: Text('Fiyat ve Detaylar'),
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: 'Fiyat'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty ? 'Fiyat gerekli' : null,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriceUnit,
                          decoration: InputDecoration(labelText: 'Birim'),
                          items: FeedCategories.priceUnits.map((unit) {
                            return DropdownMenuItem(
                                value: unit, child: Text(unit));
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedPriceUnit = value!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPackagingType,
                    decoration: InputDecoration(labelText: 'Paketleme Türü'),
                    items: FeedCategories.packagingTypes.map((type) {
                      return DropdownMenuItem(
                          value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPackagingType = value!),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _proteinController,
                    decoration: InputDecoration(labelText: 'Protein Yüzdesi (%)'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _energyController,
                    decoration: InputDecoration(labelText: 'Enerji Değeri'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _productionDateController,
                    decoration: InputDecoration(labelText: 'Üretim Tarihi'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(labelText: 'Son Kullanma Tarihi'),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSellerType,
                    decoration: InputDecoration(labelText: 'Satıcı Türü'),
                    items: FeedCategories.sellerTypes.map((type) {
                      return DropdownMenuItem(
                          value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSellerType = value!),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _transportInfoController,
                    decoration: InputDecoration(labelText: 'Nakliye Bilgileri'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Step(
              title: Text('Fotoğraflar ve Seçenekler'),
              content: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Fotoğraf Ekle'),
                  ),
                  SizedBox(height: 16),
                  if (_selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.file(_selectedImages[index],
                                fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Organik'),
                    value: _isOrganic,
                    onChanged: (value) =>
                        setState(() => _isOrganic = value ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Acil Satış'),
                    value: _isUrgentSale,
                    onChanged: (value) =>
                        setState(() => _isUrgentSale = value ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Toplu Satış'),
                    value: _isBulkSale,
                    onChanged: (value) =>
                        setState(() => _isBulkSale = value ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Yerli Yem'),
                    value: _isLocal,
                    onChanged: (value) =>
                        setState(() => _isLocal = value ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Pazarlık Yapılabilir'),
                    value: _isNegotiable,
                    onChanged: (value) =>
                        setState(() => _isNegotiable = value ?? false),
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

  // Yem ilanı fotoğrafları sıkıştırma metodu
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
      print('❌ Yem ilanı görsel sıkıştırma hatası: $e');
      // Hata durumunda orijinal dosyayı oku
      return await imageFile.readAsBytes();
    }
  }
}
