import 'package:cloud_firestore/cloud_firestore.dart';

class SlaughterPrice {
  final String region;
  final String regionId;
  final DateTime lastUpdated;
  final Map<String, AnimalPrice> prices; // "büyükbaş", "küçükbaş"

  SlaughterPrice({
    required this.region,
    required this.regionId,
    required this.lastUpdated,
    required this.prices,
  });

  factory SlaughterPrice.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final pricesData = data['prices'] as Map<String, dynamic>? ?? {};
    
    Map<String, AnimalPrice> prices = {};
    pricesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        prices[key] = AnimalPrice.fromMap(value);
      }
    });

    return SlaughterPrice(
      region: data['region'] ?? '',
      regionId: snap.id,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prices: prices,
    );
  }

  factory SlaughterPrice.fromMap(Map<String, dynamic> map) {
    final pricesData = map['prices'] as Map<String, dynamic>? ?? {};
    
    Map<String, AnimalPrice> prices = {};
    pricesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        prices[key] = AnimalPrice.fromMap(value);
      }
    });

    return SlaughterPrice(
      region: map['region'] ?? '',
      regionId: map['regionId'] ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prices: prices,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> pricesJson = {};
    prices.forEach((key, value) {
      pricesJson[key] = value.toJson();
    });

    return {
      'region': region,
      'regionId': regionId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'prices': pricesJson,
    };
  }
}

class AnimalPrice {
  final double canliKg;
  final double kesimKg;
  final double karkasKg;

  AnimalPrice({
    required this.canliKg,
    required this.kesimKg,
    required this.karkasKg,
  });

  factory AnimalPrice.fromMap(Map<String, dynamic> map) {
    return AnimalPrice(
      canliKg: (map['canlı_kg'] ?? map['canli_kg'] ?? 0.0).toDouble(),
      kesimKg: (map['kesim_kg'] ?? 0.0).toDouble(),
      karkasKg: (map['karkas_kg'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canlı_kg': canliKg,
      'kesim_kg': kesimKg,
      'karkas_kg': karkasKg,
    };
  }
}

