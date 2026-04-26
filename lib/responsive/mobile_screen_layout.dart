import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/safe_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/user_provider.dart';
import '../utils/global_variables.dart';
import '../utils/animal_colors.dart';
import '../services/fcm_token_service.dart';
import '../screens/animal_discover_screen.dart';
import '../screens/login_screen.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({Key? key}) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController; // for tabs animation
  final ScrollController _homeScrollController = ScrollController();
  int _unreadMessageCount = 0;
  StreamSubscription<DocumentSnapshot>? _unreadMessageSubscription;
  bool _showPhoneDialog = false;
  final TextEditingController _phoneController = TextEditingController();
  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _phoneController.text = '0'; // Başlangıç değeri 0

    // Uygulama başladığında FCM token'ı güncelle
    if (!_isGuest) {
      _updateFCMToken();
      _loadUnreadMessageCount();
      _listenToUnreadMessages();
    }

    // Telefon numarası kontrolü
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isGuest) {
        _checkPhoneNumber();
      }
    });
  }

  // Telefon numarası kontrolü
  void _checkPhoneNumber() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final phoneNumber = data['phoneNumber'] as String? ?? '';

        // Telefon numarası kontrolü
        if (phoneNumber.isEmpty ||
            phoneNumber == '0' ||
            phoneNumber.length < 11) {
          if (mounted) {
            setState(() {
              _showPhoneDialog = true;
            });
            // Dialog'u göster - bir sonraki frame'de
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _showPhoneDialog) {
                _showPhoneNumberDialog();
              }
            });
          }
        }
      } else {
        // Kullanıcı dokümanı yoksa telefon numarası dialog'u göster
        if (mounted) {
          setState(() {
            _showPhoneDialog = true;
          });
          // Dialog'u göster - bir sonraki frame'de
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _showPhoneDialog) {
              _showPhoneNumberDialog();
            }
          });
        }
      }
    } catch (e) {
      print('Telefon numarası kontrolü hatası: $e');
    }
  }

  // Telefon numarası dialog'unu göster
  void _showPhoneNumberDialog() {
    if (!_showPhoneDialog || !mounted) return;

    // Dialog zaten açık mı kontrol et
    if (Navigator.of(context).canPop()) {
      // Dialog zaten açık, tekrar açma
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayınca kapanmasın
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // Dialog kapatılamaz - telefon numarası girilmeden devam edilemez
            return false;
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.phone, color: AnimalColors.warning, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MÜŞTERİLERİN ULAŞABİLMESİ İÇİN TELEFON NUMARANIZI GİRİN',
                    style: SafeFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  style: SafeFonts.poppins(
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    labelStyle: SafeFonts.poppins(
                      color: Color(0xFF757575),
                      fontSize: 14,
                    ),
                    hintText: '0XXXXXXXXXX',
                    hintStyle: SafeFonts.poppins(
                      color: Color(0xFF757575).withOpacity(0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AnimalColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFFFAFAFA),
                    counterStyle: SafeFonts.poppins(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // 0 ile başlamıyorsa 0 ekle
                    if (value.isNotEmpty && !value.startsWith('0')) {
                      _phoneController.value = TextEditingValue(
                        text: '0$value',
                        selection:
                            TextSelection.collapsed(offset: '0$value'.length),
                      );
                    }
                    // 0 silinmeye çalışılırsa engelle
                    if (value.isEmpty) {
                      _phoneController.value = TextEditingValue(
                        text: '0',
                        selection: TextSelection.collapsed(offset: 1),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final phoneNumber = _phoneController.text.trim();

                  // Telefon numarası kontrolü
                  if (phoneNumber.isEmpty ||
                      phoneNumber == '0' ||
                      phoneNumber.length < 11) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Lütfen geçerli bir telefon numarası girin'),
                        backgroundColor: AnimalColors.error,
                      ),
                    );
                    return;
                  }

                  // Firestore'a kaydet
                  try {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .update({
                        'phoneNumber': phoneNumber,
                      });

                      if (mounted) {
                        setState(() {
                          _showPhoneDialog = false;
                        });
                        Navigator.of(context).pop(); // Dialog'u kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Telefon numaranız başarıyla kaydedildi'),
                            backgroundColor: AnimalColors.success,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Telefon numarası kaydedilemedi: $e'),
                        backgroundColor: AnimalColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AnimalColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'KAYDET',
                  style: SafeFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _unreadMessageSubscription?.cancel();
    _homeScrollController.dispose();
    pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    // Misafir modunda üye özel sayfalar kilitli.
    if (_isGuest && (page == 1 || page == 2 || page == 5)) {
      _handleGuestRestrictedAccess();
      return;
    }
    pageController.jumpToPage(page);
  }

  void _handleGuestRestrictedAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik için giriş yapmanız gerekiyor.'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _onHomeNavTap() {
    if (_page == 0) {
      if (_homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      navigationTapped(0);
    }
  }

  // FCM token'ı güncelleyen method (retry mekanizması ile)
  void _updateFCMToken() async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).getUser;
      if (currentUser != null && currentUser.uid != null) {
        // FCMTokenService kullanarak token'ı al ve kaydet (retry mekanizması ile)
        await FCMTokenService().initializeAndSaveToken(forceRetry: true);
        print('✅ FCM token güncelleme işlemi başlatıldı (retry ile)');
      }
    } catch (e) {
      print('❌ FCM token güncelleme hatası: $e');
    }
  }

  // Okunmamış mesaj sayısını yükleyen method
  void _loadUnreadMessageCount() async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).getUser;
      if (currentUser != null && currentUser.uid != null) {
        // Tüm conversation'ları al
        QuerySnapshot conversationsSnapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .where("users", arrayContains: currentUser.uid)
            .get();

        int totalUnreadCount = 0;

        // Her conversation için okunmamış mesaj sayısını hesapla
        for (DocumentSnapshot conversationDoc in conversationsSnapshot.docs) {
          try {
            QuerySnapshot unreadMessages = await FirebaseFirestore.instance
                .collection("conversations")
                .doc(conversationDoc.id)
                .collection("messages")
                .where("recipient", isEqualTo: currentUser.uid)
                .where("isRead", isEqualTo: false)
                .get();

            totalUnreadCount += unreadMessages.docs.length;
          } catch (e) {
            print('❌ Conversation badge count hatası: $e');
          }
        }

        if (mounted) {
          setState(() {
            _unreadMessageCount = totalUnreadCount;
          });
        }
      }
    } catch (e) {
      print('Okunmamış mesaj sayısı yükleme hatası: $e');
    }
  }

  // Okunmamış mesajları dinleyen method
  void _listenToUnreadMessages() {
    _unreadMessageSubscription?.cancel();
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).getUser;
    if (currentUser != null && currentUser.uid != null) {
      _unreadMessageSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted && snapshot.exists) {
          final data = snapshot.data();
          final unreadCount = (data?['unreadMessageCount'] as int?) ?? 0;
          setState(() {
            _unreadMessageCount = unreadCount;
            print(
                '📊 Okunmamış mesaj sayısı güncellendi: $_unreadMessageCount');
          });
        }
      });
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _page == index;
    final isHome = index == 0;
    return GestureDetector(
      onTap: () {
        if (isHome) _onHomeNavTap(); else navigationTapped(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AnimalColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 26 : 24,
              color: isSelected ? AnimalColors.primary : Colors.grey.shade500,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: SafeFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AnimalColors.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(int index, IconData icon, String label) {
    final isSelected = _page == index;
    return GestureDetector(
      onTap: () => navigationTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AnimalColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: isSelected ? 26 : 24,
                  color:
                      isSelected ? AnimalColors.primary : Colors.grey.shade500,
                ),
                if (_unreadMessageCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B6B).withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(minWidth: 18),
                      child: Text(
                        _unreadMessageCount > 99
                            ? '99+'
                            : _unreadMessageCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: SafeFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AnimalColors.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isSelected = _page == 2;
    return GestureDetector(
      onTap: () => navigationTapped(2),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [AnimalColors.primary, Color(0xFF43A047)]
                : [Colors.grey.shade400, Colors.grey.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AnimalColors.primary : Colors.grey)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 22,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              'İlan Ver',
              style: SafeFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          AnimalDiscoverScreen(scrollController: _homeScrollController),
          ...homeScreenItem.sublist(1),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
                _buildNavItemWithBadge(1, Icons.chat_bubble_rounded, 'Mesaj'),
                _buildNavItem(2, Icons.add_circle_rounded, 'İlan Ver'),
                _buildNavItem(3, Icons.medical_services_rounded, 'Vet'),
                _buildNavItem(4, Icons.grass_rounded, 'Yem'),
                _buildNavItem(5, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
