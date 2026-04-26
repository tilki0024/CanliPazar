import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/slaughter_price.dart';

class SlaughterPriceService {
  // KRİTİK: Lazy getter kullan - instance'ı hemen başlatma
  // Bu, Firestore settings'in AppDelegate'te ayarlanması için zaman tanır
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Bölgeye göre fiyatları getir
  Future<SlaughterPrice?> getPricesByRegion(String region) async {
    try {
      final query = await _firestore
          .collection('slaughter_prices')
          .where('region', isEqualTo: region)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return SlaughterPrice.fromSnap(query.docs.first);
    } catch (e) {
      print('❌ Bölge fiyatları getirme hatası: $e');
      return null;
    }
  }

  // Tüm bölgeleri getir
  Future<List<String>> getAllRegions() async {
    try {
      final query = await _firestore
          .collection('slaughter_prices')
          .orderBy('region')
          .get();

      return query.docs
          .map((doc) => (doc.data()['region'] as String?) ?? '')
          .where((region) => region.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      print('❌ Bölgeler getirme hatası: $e');
      return [];
    }
  }

  // Real-time fiyat güncellemeleri
  Stream<SlaughterPrice?> streamPricesByRegion(String region) {
    return _firestore
        .collection('slaughter_prices')
        .where('region', isEqualTo: region)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return SlaughterPrice.fromSnap(snapshot.docs.first);
    });
  }

  // En güncel fiyatları getir (tüm bölgeler)
  Future<List<SlaughterPrice>> getLatestPrices() async {
    try {
      final query = await _firestore
          .collection('slaughter_prices')
          .orderBy('lastUpdated', descending: true)
          .get();

      return query.docs
          .map((doc) => SlaughterPrice.fromSnap(doc))
          .toList();
    } catch (e) {
      print('❌ Güncel fiyatlar getirme hatası: $e');
      return [];
    }
  }

  // Tüm bölgeler için real-time stream
  Stream<List<SlaughterPrice>> streamAllPrices() {
    return _firestore
        .collection('slaughter_prices')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SlaughterPrice.fromSnap(doc))
          .toList();
    });
  }
}









