import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPost {
  final String description;
  final String uid;
  final String username;
  final String postId;
  final DateTime datePublished;
  final List<String> photoUrls;
  final String profImage;
  final String country;
  final String state;
  final String city;

  // Yem-specific alanlar
  final String feedType; // "kaba yem", "konsantre yem", "yem katkısı"
  final String feedCategory; // "saman", "yonca", "karma yem", vb.
  final String animalType; // "büyükbaş", "küçükbaş", "kanatlı", "karma"
  final double quantityInKg; // kg cinsinden miktar
  final String quantityUnit; // "kg", "ton"
  final double priceInTL; // TL cinsinden fiyat
  final String priceUnit; // "kg", "ton", "çuval"
  final String brand; // Marka
  final String? productionDate; // Üretim tarihi
  final String? expiryDate; // Son kullanma tarihi
  final double? proteinPercentage; // Protein yüzdesi
  final double? energyValue; // Enerji değeri
  final bool isOrganic; // Organik mi
  final String packagingType; // "çuvallı", "dökme", "big bag"
  final bool isUrgentSale; // Acil satış
  final bool isBulkSale; // Toplu satış
  final bool isLocal; // Yerli/İthal (true = yerli)
  final String sellerType; // "bireysel", "çiftlik", "kooperatif", "yem fabrikası"
  final String transportInfo; // Nakliye bilgileri
  final bool isNegotiable; // Pazarlık yapılabilir mi
  final Map<String, dynamic>? additionalInfo; // Ek bilgiler

  // Mevcut sistemden devam edenler
  final List<dynamic> likes;
  final List<dynamic> saved;
  final bool isActive; // İlan aktif mi
  final DateTime? soldDate; // Satış tarihi
  final String? buyerUid; // Alıcı uid
  final int viewCount; // Görüntülenme sayısı

  // Satış değerlendirme sistemi için yeni alanlar
  final String saleStatus; // "active", "pending", "sold"
  final double? salePrice; // Gerçek satış fiyatı
  final bool hasRating; // Değerlendirme var mı
  final String? ratingId; // İlgili değerlendirme ID'si
  final bool canBeRated; // Değerlendirilebilir mi

  FeedPost({
    required this.description,
    required this.uid,
    required this.username,
    required this.postId,
    required this.datePublished,
    required this.photoUrls,
    required this.profImage,
    required this.country,
    required this.state,
    required this.city,
    required this.feedType,
    required this.feedCategory,
    required this.animalType,
    required this.quantityInKg,
    required this.quantityUnit,
    required this.priceInTL,
    required this.priceUnit,
    required this.brand,
    this.productionDate,
    this.expiryDate,
    this.proteinPercentage,
    this.energyValue,
    required this.isOrganic,
    required this.packagingType,
    required this.isUrgentSale,
    required this.isBulkSale,
    required this.isLocal,
    required this.sellerType,
    required this.transportInfo,
    required this.isNegotiable,
    this.additionalInfo,
    required this.likes,
    required this.saved,
    required this.isActive,
    this.soldDate,
    this.buyerUid,
    this.viewCount = 0,
    required this.saleStatus,
    this.salePrice,
    required this.hasRating,
    this.ratingId,
    required this.canBeRated,
  });

  static FeedPost fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>? ?? {};

    print('📋 FeedPost.fromSnap - Document ID: ${snap.id}');
    print('📋 FeedPost.fromSnap - Available keys: ${snapshot.keys.toList()}');

    try {
      return FeedPost(
        description: snapshot["description"] ?? '',
        uid: snapshot["uid"] ?? '',
        username: snapshot["username"] ?? '',
        postId: snapshot["postId"] ?? snap.id,
        datePublished: snapshot["datePublished"]?.toDate() ?? DateTime.now(),
        photoUrls: List<String>.from(snapshot["photoUrls"] ?? []),
        profImage: snapshot["profImage"] ?? '',
        country: snapshot["country"] ?? '',
        state: snapshot["state"] ?? '',
        city: snapshot["city"] ?? '',
        feedType: snapshot["feedType"] ?? '',
        feedCategory: snapshot["feedCategory"] ?? '',
        animalType: snapshot["animalType"] ?? '',
        quantityInKg: _safeGetDouble(snapshot["quantityInKg"]),
        quantityUnit: snapshot["quantityUnit"] ?? 'kg',
        priceInTL: _safeGetDouble(snapshot["priceInTL"]),
        priceUnit: snapshot["priceUnit"] ?? 'kg',
        brand: snapshot["brand"] ?? '',
        productionDate: snapshot["productionDate"],
        expiryDate: snapshot["expiryDate"],
        proteinPercentage: snapshot["proteinPercentage"] != null
            ? _safeGetDouble(snapshot["proteinPercentage"])
            : null,
        energyValue: snapshot["energyValue"] != null
            ? _safeGetDouble(snapshot["energyValue"])
            : null,
        isOrganic: snapshot["isOrganic"] ?? false,
        packagingType: snapshot["packagingType"] ?? 'çuvallı',
        isUrgentSale: snapshot["isUrgentSale"] ?? false,
        isBulkSale: snapshot["isBulkSale"] ?? false,
        isLocal: snapshot["isLocal"] ?? true,
        sellerType: snapshot["sellerType"] ?? '',
        transportInfo: snapshot["transportInfo"] ?? '',
        isNegotiable: snapshot["isNegotiable"] ?? false,
        additionalInfo: snapshot["additionalInfo"],
        likes: snapshot["likes"] ?? [],
        saved: snapshot["saved"] ?? [],
        isActive: snapshot["isActive"] ?? true,
        soldDate: snapshot["soldDate"]?.toDate(),
        buyerUid: snapshot["buyerUid"],
        viewCount: snapshot["viewCount"] ?? 0,
        saleStatus: snapshot["saleStatus"] ?? "active",
        salePrice: snapshot["salePrice"] != null
            ? _safeGetDouble(snapshot["salePrice"])
            : null,
        hasRating: snapshot["hasRating"] ?? false,
        ratingId: snapshot["ratingId"],
        canBeRated: snapshot["canBeRated"] ?? false,
      );
    } catch (e) {
      print('❌ Error in FeedPost.fromSnap: $e');
      print('📋 Snapshot data: $snapshot');
      rethrow;
    }
  }

  static FeedPost fromMap(Map<String, dynamic> data) {
    print('📋 FeedPost.fromMap - Available keys: ${data.keys.toList()}');

    try {
      return FeedPost(
        description: data["description"] ?? '',
        uid: data["uid"] ?? '',
        username: data["username"] ?? '',
        postId: data["postId"] ?? '',
        datePublished: data["datePublished"]?.toDate() ?? DateTime.now(),
        photoUrls: List<String>.from(data["photoUrls"] ?? []),
        profImage: data["profImage"] ?? '',
        country: data["country"] ?? '',
        state: data["state"] ?? '',
        city: data["city"] ?? '',
        feedType: data["feedType"] ?? '',
        feedCategory: data["feedCategory"] ?? '',
        animalType: data["animalType"] ?? '',
        quantityInKg: _safeGetDouble(data["quantityInKg"]),
        quantityUnit: data["quantityUnit"] ?? 'kg',
        priceInTL: _safeGetDouble(data["priceInTL"]),
        priceUnit: data["priceUnit"] ?? 'kg',
        brand: data["brand"] ?? '',
        productionDate: data["productionDate"],
        expiryDate: data["expiryDate"],
        proteinPercentage: data["proteinPercentage"] != null
            ? _safeGetDouble(data["proteinPercentage"])
            : null,
        energyValue: data["energyValue"] != null
            ? _safeGetDouble(data["energyValue"])
            : null,
        isOrganic: data["isOrganic"] ?? false,
        packagingType: data["packagingType"] ?? 'çuvallı',
        isUrgentSale: data["isUrgentSale"] ?? false,
        isBulkSale: data["isBulkSale"] ?? false,
        isLocal: data["isLocal"] ?? true,
        sellerType: data["sellerType"] ?? '',
        transportInfo: data["transportInfo"] ?? '',
        isNegotiable: data["isNegotiable"] ?? false,
        additionalInfo: data["additionalInfo"],
        likes: data["likes"] ?? [],
        saved: data["saved"] ?? [],
        isActive: data["isActive"] ?? true,
        soldDate: data["soldDate"]?.toDate(),
        buyerUid: data["buyerUid"],
        viewCount: data["viewCount"] ?? 0,
        saleStatus: data["saleStatus"] ?? "active",
        salePrice: data["salePrice"] != null
            ? _safeGetDouble(data["salePrice"])
            : null,
        hasRating: data["hasRating"] ?? false,
        ratingId: data["ratingId"],
        canBeRated: data["canBeRated"] ?? false,
      );
    } catch (e) {
      print('❌ Error in FeedPost.fromMap: $e');
      print('📋 Map data: $data');
      rethrow;
    }
  }

  // Helper methods for safe type conversion
  static double _safeGetDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        "description": description,
        "uid": uid,
        "username": username,
        "postId": postId,
        "datePublished": datePublished,
        "photoUrls": photoUrls,
        "profImage": profImage,
        "country": country,
        "state": state,
        "city": city,
        "feedType": feedType,
        "feedCategory": feedCategory,
        "animalType": animalType,
        "quantityInKg": quantityInKg,
        "quantityUnit": quantityUnit,
        "priceInTL": priceInTL,
        "priceUnit": priceUnit,
        "brand": brand,
        "productionDate": productionDate,
        "expiryDate": expiryDate,
        "proteinPercentage": proteinPercentage,
        "energyValue": energyValue,
        "isOrganic": isOrganic,
        "packagingType": packagingType,
        "isUrgentSale": isUrgentSale,
        "isBulkSale": isBulkSale,
        "isLocal": isLocal,
        "sellerType": sellerType,
        "transportInfo": transportInfo,
        "isNegotiable": isNegotiable,
        "additionalInfo": additionalInfo,
        "likes": likes,
        "saved": saved,
        "isActive": isActive,
        "soldDate": soldDate,
        "buyerUid": buyerUid,
        "viewCount": viewCount,
        "saleStatus": saleStatus,
        "salePrice": salePrice,
        "hasRating": hasRating,
        "ratingId": ratingId,
        "canBeRated": canBeRated,
      };
}

