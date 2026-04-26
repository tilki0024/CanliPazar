import 'package:animal_trade/screens/animal_discover_screen.dart';
import 'package:animal_trade/screens/add_animal_screen.dart';
import 'package:animal_trade/screens/veterinarian_discover_screen.dart';
import 'package:animal_trade/screens/feed_discover_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animal_trade/screens/incoming_messages.dart';
import 'package:animal_trade/screens/profile_screen2.dart';
import 'package:animal_trade/screens/login_screen.dart';

// Web ekran boyutu eşik değeri - 900 piksel genişliğinden büyük ekranlar web düzeni kullanacak
const webScreenSize = 9000;

/// KRİTİK: homeScreenItem getter
/// Bu getter build() metodunda çağrılıyor, bu yüzden Firestore instance'ına erişim güvenli
/// Ancak StreamBuilder içinde FirebaseFirestore.instance kullanımı instance'ı başlatır
/// Bu yüzden bu getter sadece runApp()'tan SONRA çağrılmalı
/// 
/// NOT: Bu getter MobileScreenLayout ve WebScreenLayout'ta build() metodunda çağrılıyor
/// Bu, runApp()'tan sonra olduğu için güvenli
List<Widget> get homeScreenItem {
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bool isGuest = currentUserUid.isEmpty;
  
  return [
    const AnimalDiscoverScreen(), // Ana hayvan listesi sayfası
    isGuest
        ? const _GuestModePlaceholder(
            title: 'Mesajlar için giriş yapın',
            subtitle: 'Mesajlaşma özelliğini kullanmak için hesabınıza giriş yapın.',
            icon: Icons.chat_bubble_outline,
          )
        : IncomingMessagesPage(
            currentUserUid: currentUserUid,
          ),
    isGuest
        ? const _GuestModePlaceholder(
            title: 'İlan vermek için giriş yapın',
            subtitle: 'Misafir modunda ilan ekleme kapalıdır.',
            icon: Icons.add_circle_outline,
          )
        : const AddAnimalScreen(),
    const VeterinarianDiscoverScreen(), // Veteriner discover sayfası
    const FeedDiscoverScreen(), // Yemler sayfası
    // KRİTİK: StreamBuilder içinde FirebaseFirestore.instance kullanımı instance'ı başlatır
    // Bu getter build() metodunda çağrıldığı için güvenli (runApp()'tan sonra)
    // Ancak yine de dikkatli olmalıyız - eğer bu getter runApp()'tan önce çağrılırsa sorun olur
    isGuest
        ? const _GuestModePlaceholder(
            title: 'Profil için giriş yapın',
            subtitle: 'Misafir modunda profil ekranı kapalıdır.',
            icon: Icons.person_outline,
          )
        : StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ProfileScreen2(
                  uid: currentUserUid,
                  snap: snapshot.data,
                  userId: currentUserUid,
                );
              } else {
                return const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                    ),
                  ),
                );
              }
            },
          )
  ];
}

class _GuestModePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _GuestModePlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}

// Ana navigasyon ikonları
const List<IconData> navIcons = [
  Icons.home, // Ana sayfa
  Icons.message, // Mesajlar
  Icons.add_circle_outline, // İlan ekle
  Icons.local_hospital, // Veterinerler
  Icons.person, // Profil
];

// Navigasyon etiketleri
const List<String> navLabels = [
  'Ana Sayfa',
  'Mesajlar',
  'İlan Ver',
  'Veterinerler',
  'Profil',
];
