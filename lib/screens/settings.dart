import 'package:animal_trade/screens/country_state_city2.dart';
import 'package:animal_trade/screens/country_state_city_picker.dart';
import 'package:animal_trade/screens/privacy_policy.dart';
import 'package:animal_trade/screens/terms_of_use_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animal_trade/screens/liked_posts_screen.dart';
import 'package:animal_trade/screens/login_screen.dart';
import 'package:animal_trade/screens/location_picker_screen.dart';

import 'package:animal_trade/screens/reset_password.dart';
import 'package:flutter/services.dart';
import 'package:animal_trade/utils/utils.dart';
import '../utils/safe_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // AdMob kodları kaldırıldı
  bool isAdLoaded = false;
  
  // Bildirim ayarları
  bool? messageNotificationsEnabled;
  bool? postNotificationsEnabled;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // AdMob kodu kaldırıldı
    _loadNotificationSettings();
  }
  
  // Bildirim ayarlarını yükle
  Future<void> _loadNotificationSettings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          isLoading = false;
          messageNotificationsEnabled = true;
          postNotificationsEnabled = true;
        });
        return;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          messageNotificationsEnabled = data?['messageNotificationsEnabled'] ?? true;
          postNotificationsEnabled = data?['postNotificationsEnabled'] ?? true;
          isLoading = false;
        });
      } else {
        setState(() {
          messageNotificationsEnabled = true;
          postNotificationsEnabled = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Bildirim ayarları yükleme hatası: $e');
      setState(() {
        messageNotificationsEnabled = true;
        postNotificationsEnabled = true;
        isLoading = false;
      });
    }
  }
  
  // Mesaj bildirimlerini aç/kapat
  Future<void> _toggleMessageNotifications(bool value) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      setState(() {
        messageNotificationsEnabled = value;
      });
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'messageNotificationsEnabled': value,
      });
      
      print('✅ Mesaj bildirimleri ${value ? "açıldı" : "kapatıldı"}');
    } catch (e) {
      print('❌ Mesaj bildirimleri güncelleme hatası: $e');
      setState(() {
        messageNotificationsEnabled = !value; // Geri al
      });
    }
  }
  
  // İlan bildirimlerini aç/kapat
  Future<void> _togglePostNotifications(bool value) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      setState(() {
        postNotificationsEnabled = value;
      });
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'postNotificationsEnabled': value,
      });
      
      print('✅ İlan bildirimleri ${value ? "açıldı" : "kapatıldı"}');
    } catch (e) {
      print('❌ İlan bildirimleri güncelleme hatası: $e');
      setState(() {
        postNotificationsEnabled = !value; // Geri al
      });
    }
  }

  void _showReferralInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Referral System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Points info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Earn 10 credits per referral',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rules
                Column(
                  children: [
                    _buildRule(Icons.calendar_today, 'Max 2 referrals per day'),
                    const SizedBox(height: 12),
                    _buildRule(
                        Icons.people_outline, 'Max 3 referrals in total'),
                    const SizedBox(height: 12),
                    _buildRule(Icons.phone_android, 'One referral per device'),
                    const SizedBox(height: 12),
                    _buildRule(Icons.person_add, 'New users only'),
                  ],
                ),
                const SizedBox(height: 24),

                // Close button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRule(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: SafeFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.green).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: SafeFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Ayarlar',
          style: SafeFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          _buildSectionHeader('Bildirimler'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: messageNotificationsEnabled ?? true,
              onChanged: _toggleMessageNotifications,
              title: Text(
                'Mesaj Bildirimleri',
                style: SafeFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Yeni mesajlar için bildirim al',
                style: SafeFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.message_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: postNotificationsEnabled ?? true,
              onChanged: _togglePostNotifications,
              title: Text(
                'İlan Bildirimleri',
                style: SafeFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Yeni ilanlar için bildirim al',
                style: SafeFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            ),
          ),
          _buildSectionHeader('İçerik'),
          _buildSettingsTile(
            icon: Icons.favorite_rounded,
            iconColor: Colors.pink,
            title: 'Beğenilenler',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedPostsScreen(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            },
          ),
          _buildSectionHeader('Hesap'),
          _buildSettingsTile(
            icon: Icons.lock_rounded,
            iconColor: Colors.green,
            title: 'Şifreyi Değiştir',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgetPassword(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.location_on_rounded,
            iconColor: Colors.purple,
            title: 'Konumu Değiştir',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LocationPickerScreen(
                    isFromSettings: true,
                  ),
                ),
              );
            },
          ),
          _buildSectionHeader('Yasal'),
          _buildSettingsTile(
            icon: Icons.privacy_tip_rounded,
            iconColor: Colors.blue,
            title: 'Gizlilik Politikası',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyPage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.gavel_rounded,
            iconColor: Colors.amber,
            title: 'Kullanım Şartları',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TermsOfServicePage(),
                ),
              );
            },
          ),
          _buildSectionHeader('Tehlikeli Alan'),
          _buildSettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red,
            title: 'Hesabı Sil',
            isDestructive: true,
            onTap: () => deleteAccount(context),
          ),
        ],
      ),
    );
  }

  void deleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Hesabı Sil',
                style: SafeFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                style: SafeFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tüm verileriniz silinir ve bu telefon numarasıyla tekrar hesap açamazsınız.',
                style: SafeFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Vazgeç',
                        style: SafeFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Sil',
                        style: SafeFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            await FirebaseFirestore.instance
                .collection('deleted_users')
                .doc(userId)
                .set(userDoc.data()!);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .delete();
          }

          await FirebaseAuth.instance.signOut();

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _toTurkishAuthError(e),
                style: SafeFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } on FirebaseException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _toTurkishFirestoreError(e),
                style: SafeFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hesap silinirken bir hata oluştu. Lütfen tekrar deneyin.',
                style: SafeFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _toTurkishAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Güvenlik nedeniyle tekrar giriş yapmanız gerekiyor. Lütfen çıkış yapıp yeniden giriş yapın.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'network-request-failed':
        return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla istek gönderildi. Lütfen biraz bekleyip tekrar deneyin.';
      case 'invalid-credential':
        return 'Oturum bilgileriniz geçersiz. Lütfen tekrar giriş yapın.';
      default:
        return 'Kimlik doğrulama hatası: ${e.message ?? 'Bilinmeyen hata'}';
    }
  }

  String _toTurkishFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
        return 'Sunucuya ulaşılamıyor. Lütfen daha sonra tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
      default:
        return 'Veri işlemi sırasında bir hata oluştu: ${e.message ?? 'Bilinmeyen hata'}';
    }
  }
}
