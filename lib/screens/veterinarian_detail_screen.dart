import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/veterinarian.dart';
import '../services/pricing_service.dart';
import 'veterinarian_profile_screen.dart';
import 'message_screen.dart';

class VeterinarianDetailScreen extends StatefulWidget {
  final String veterinarianId;
  final Map<String, dynamic> veterinarianData;

  const VeterinarianDetailScreen({
    Key? key,
    required this.veterinarianId,
    required this.veterinarianData,
  }) : super(key: key);

  @override
  State<VeterinarianDetailScreen> createState() =>
      _VeterinarianDetailScreenState();
}

class _VeterinarianDetailScreenState extends State<VeterinarianDetailScreen> {
  Veterinarian get veterinarian {
    // Geçici çözüm: Map'ten Veterinarian oluştur
    return Veterinarian(
      uid: widget.veterinarianData['uid'] ?? '',
      username: widget.veterinarianData['username'] ?? '',
      photoUrl: widget.veterinarianData['photoUrl'],
      email: widget.veterinarianData['veterinarianEmail'],
      bio: widget.veterinarianData['bio'],
      clinicName: widget.veterinarianData['veterinarianClinicName'],
      phone: widget.veterinarianData['veterinarianPhone'],
      address: widget.veterinarianData['veterinarianAddress'],
      cities: List<String>.from(
          widget.veterinarianData['veterinarianCities'] ?? []),
      licenseNumber: widget.veterinarianData['veterinarianLicenseNumber'],
      specialization: widget.veterinarianData['veterinarianSpecialization'],
      yearsExperience: widget.veterinarianData['veterinarianYearsExperience'],
      workingHours: widget.veterinarianData['veterinarianWorkingHours'],
      available: widget.veterinarianData['veterinarianAvailable'] ?? true,
      description: widget.veterinarianData['veterinarianDescription'],
      consultationFee:
          (widget.veterinarianData['veterinarianConsultationFee'] as num?)
              ?.toDouble(),
      emergencyFee:
          (widget.veterinarianData['veterinarianEmergencyFee'] as num?)
              ?.toDouble(),
      homeVisit: widget.veterinarianData['veterinarianHomeVisit'] ?? false,
      emergencyService:
          widget.veterinarianData['veterinarianEmergencyService'] ?? false,
      animalTypes: List<String>.from(
          widget.veterinarianData['veterinarianAnimalTypes'] ?? []),
      services: List<String>.from(
          widget.veterinarianData['veterinarianServices'] ?? []),
      certifications: List<String>.from(
          widget.veterinarianData['veterinarianCertifications'] ?? []),
      languages: List<String>.from(
          widget.veterinarianData['veterinarianLanguages'] ?? []),
      documents: List<String>.from(
          widget.veterinarianData['veterinarianDocuments'] ?? []),
      photoUrls: List<String>.from(
          widget.veterinarianData['veterinarianPhotoUrls'] ?? []),
      notes: widget.veterinarianData['veterinarianNotes'],
      emergencyPhone: widget.veterinarianData['veterinarianEmergencyPhone'],
      insurance: widget.veterinarianData['veterinarianInsurance'] ?? false,
      regions: List<String>.from(
          widget.veterinarianData['veterinarianRegions'] ?? []),
      serviceDetails: Map<String, dynamic>.from(
          widget.veterinarianData['veterinarianServiceDetails'] ?? {}),
      clinicType: widget.veterinarianData['veterinarianClinicType'],
      education: widget.veterinarianData['veterinarianEducation'],
      university: widget.veterinarianData['veterinarianUniversity'],
      graduationYear: widget.veterinarianData['veterinarianGraduationYear'],
      specializations: List<String>.from(
          widget.veterinarianData['veterinarianSpecializations'] ?? []),
      hasLaboratory:
          widget.veterinarianData['veterinarianHasLaboratory'] ?? false,
      hasSurgery: widget.veterinarianData['veterinarianHasSurgery'] ?? false,
      hasXRay: widget.veterinarianData['veterinarianHasXRay'] ?? false,
      hasUltrasound:
          widget.veterinarianData['veterinarianHasUltrasound'] ?? false,
      equipmentList: widget.veterinarianData['veterinarianEquipmentList'],
      emergencyProtocol:
          widget.veterinarianData['veterinarianEmergencyProtocol'],
      averageRating:
          (widget.veterinarianData['averageRating'] as num?)?.toDouble(),
      totalRatings: widget.veterinarianData['totalRatings'],
      totalPatients: widget.veterinarianData['totalPatients'],
      isVerified: widget.veterinarianData['isVerified'] ?? false,
      isActive: widget.veterinarianData['isActive'] ?? true,
    );
  }

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  Widget _infoCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    // Telefon numaraları için özel işlem
    bool isPhoneNumber = label == 'Telefon' || label == 'Acil Telefon';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: SafeFonts.poppins(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isPhoneNumber
                ? GestureDetector(
                    onTap: () async {
                      final phoneUrl = 'tel:$value';
                      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                        await launchUrl(Uri.parse(phoneUrl));
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Telefon arama başlatılamadı: $value'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: SafeFonts.poppins(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    value,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipList(String label, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(
                        item.toString(),
                        style: SafeFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: primaryColor),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _switchInfo(String label, bool? value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: SafeFonts.poppins(
              color: textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          veterinarian.clinicName ?? 'Veteriner Detayı',
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
        actions: [
          // Sadece veteriner profili sahibi düzenleme butonunu görebilir
          if (FirebaseAuth.instance.currentUser?.uid == widget.veterinarianId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VeterinarianProfileScreen(
                      userId: widget.veterinarianId,
                      existingVeterinarianData: widget.veterinarianData,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () async {
              // Telefon arama işlevi
              final phone = veterinarian.phone;
              if (phone != null) {
                final phoneUrl = 'tel:$phone';
                if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                  await launchUrl(Uri.parse(phoneUrl));
                } else {
                  // Hata durumunda kullanıcıya bilgi ver
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Telefon arama başlatılamadı: $phone'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Telefon numarası yoksa kullanıcıya bilgi ver
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Telefon numarası bulunamadı'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst bilgi kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    backgroundImage: veterinarian.photoUrl != null
                        ? CachedNetworkImageProvider(veterinarian.photoUrl!)
                        : null,
                    child: veterinarian.photoUrl == null
                        ? Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          veterinarian.clinicName ?? 'Veteriner Klinik',
                          style: SafeFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (veterinarian.available)
                          Container(
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
                  ),
                ],
              ),
            ),

            // Klinik Fotoğrafları
            if (veterinarian.photoUrls.isNotEmpty)
              _infoCard(
                title: 'Klinik Fotoğrafları',
                icon: Icons.photo_library,
                children: [
                  _buildPhotoCarousel(),
                ],
              ),

            // İletişim Bilgileri
            _infoCard(
              title: 'İletişim Bilgileri',
              icon: Icons.contact_phone,
              children: [
                _infoRow('Telefon', veterinarian.phone),
                _infoRow('E-posta', veterinarian.email),
                _infoRow('Acil Telefon', veterinarian.emergencyPhone),
                _infoRow('Adres', veterinarian.address),
                _infoRow('Çalışma Saatleri', veterinarian.workingHours),
              ],
            ),

            // Eğitim ve Uzmanlık
            _infoCard(
              title: 'Eğitim ve Uzmanlık',
              icon: Icons.school,
              children: [
                _infoRow('Üniversite', veterinarian.university),
                _infoRow(
                    'Mezuniyet Yılı', veterinarian.graduationYear?.toString()),
                _infoRow(
                    'Deneyim',
                    veterinarian.yearsExperience != null
                        ? '${veterinarian.yearsExperience} yıl'
                        : 'Belirtilmemiş'),
                _infoRow('Ruhsat No', veterinarian.licenseNumber),
                _chipList('Uzmanlık Alanları', veterinarian.specializations),
              ],
            ),

            // Hizmet Bölgesi
            _infoCard(
              title: 'Hizmet Bölgesi',
              icon: Icons.location_on,
              children: [
                _chipList('Hizmet Verilen Şehirler', veterinarian.cities),
                _infoRow('Bölgeler', veterinarian.regions.join(', ')),
              ],
            ),

            // Hizmetler ve Hayvan Türleri
            _infoCard(
              title: 'Hizmetler ve Hayvan Türleri',
              icon: Icons.pets,
              children: [
                _chipList(
                    'Hizmet Verdiği Hayvan Türleri', veterinarian.animalTypes),
                _chipList('Sunulan Hizmetler', veterinarian.services),
              ],
            ),

            // Fiyatlandırma
            _infoCard(
              title: 'Fiyatlandırma',
              icon: Icons.attach_money,
              children: [
                _infoRow(
                    'Muayene Ücreti',
                    veterinarian.consultationFee != null
                        ? PricingService.formatPrice(
                            veterinarian.consultationFee!)
                        : 'Belirtilmemiş'),
                _infoRow(
                    'Acil Ücret',
                    veterinarian.emergencyFee != null
                        ? PricingService.formatPrice(veterinarian.emergencyFee!)
                        : 'Belirtilmemiş'),
              ],
            ),

            // Klinik Özellikleri
            _infoCard(
              title: 'Klinik Özellikleri',
              icon: Icons.medical_services,
              children: [
                _switchInfo('Ev Ziyareti Yapıyor', veterinarian.homeVisit),
                _switchInfo(
                    'Acil Hizmet Veriyor', veterinarian.emergencyService),
                _switchInfo('Laboratuvar Hizmeti', veterinarian.hasLaboratory),
                _switchInfo('Cerrahi Müdahale', veterinarian.hasSurgery),
                _switchInfo('Radyografi (X-Ray)', veterinarian.hasXRay),
                _switchInfo('Ultrasonografi', veterinarian.hasUltrasound),
                _switchInfo(
                    'Mesleki Sorumluluk Sigortası', veterinarian.insurance),
              ],
            ),

            // Ek Bilgiler
            _infoCard(
              title: 'Ek Bilgiler',
              icon: Icons.notes,
              children: [
                _infoRow('Açıklama', veterinarian.description),
                _infoRow('Ekipman Listesi', veterinarian.equipmentList),
                _infoRow(
                    'Acil Durum Protokolü', veterinarian.emergencyProtocol),
                _chipList('Konuşulan Diller', veterinarian.languages),
                _chipList('Sertifikalar', veterinarian.certifications),
                _infoRow('Ek Notlar', veterinarian.notes),
              ],
            ),

            const SizedBox(height: 24),

            // İletişim Butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('Ara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // Telefon arama işlevi
                      final phone = veterinarian.phone;
                      if (phone != null) {
                        final phoneUrl = 'tel:$phone';
                        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                          await launchUrl(Uri.parse(phoneUrl));
                        } else {
                          // Hata durumunda kullanıcıya bilgi ver
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Telefon arama başlatılamadı: $phone'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        // Telefon numarası yoksa kullanıcıya bilgi ver
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Telefon numarası bulunamadı'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('Mesaj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Mesajlaşma işlevi
                      _navigateToMessage();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    return Column(
      children: [
        // İlk fotoğrafı büyük göster
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: Text(
                      'Klinik Fotoğrafları',
                      style: SafeFonts.poppins(color: Colors.white),
                    ),
                  ),
                  body: PageView.builder(
                    itemCount: veterinarian.photoUrls.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: veterinarian.photoUrls[index],
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            fit: BoxFit.cover,
                            placeholder: (BuildContext context, String? url) =>
                                Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            ),
                            errorWidget: (BuildContext context, String? url,
                                    dynamic error) =>
                                Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.error,
                                    color: Colors.white, size: 48),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: veterinarian.photoUrls.first,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: backgroundColor,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: backgroundColor,
                      child: const Icon(Icons.error),
                    ),
                  ),
                  // Fotoğraf sayısı ve tıklama göstergesi
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${veterinarian.photoUrls.length}',
                            style: SafeFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tıklama göstergesi
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Tümünü gör',
                            style: SafeFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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
        const SizedBox(height: 8),
        // Küçük fotoğraf önizlemeleri (sadece 2-3 tane)
        if (veterinarian.photoUrls.length > 1)
          Row(
            children: [
              for (int i = 1; i < veterinarian.photoUrls.length && i < 4; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: veterinarian.photoUrls[i],
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: backgroundColor,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 1),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: backgroundColor,
                          child: const Icon(Icons.error, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _navigateToMessage() async {
    // Mevcut kullanıcının UID'sini al
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj göndermek için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mesaj sayfasına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(
          currentUserUid: currentUser.uid,
          recipientUid: veterinarian.uid,
          postId: '', // Veteriner konuşması için boş postId
        ),
      ),
    );
  }
}
