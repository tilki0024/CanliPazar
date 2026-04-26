import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalPost {
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

  // Hayvan-specific alanlar
  final String animalType; // "büyükbaş", "küçükbaş"
  final String animalSpecies; // "sığır", "koyun", "keçi", "manda"
  final String animalBreed; // "holstein", "angus", "merinos"
  final int ageInMonths; // ay cinsinden yaş
  final String gender; // "erkek", "dişi"
  final double weightInKg; // kg cinsinden ağırlık
  final double priceInTL; // TL cinsinden fiyat
  final String healthStatus; // "sağlıklı", "aşılı", "hasta"
  final List<String> vaccinations; // ["şap", "brucella", "tuberculin"]
  final String purpose; // "süt", "et", "damızlık", "yün"
  final bool isPregnant; // hamilelik durumu
  final DateTime? birthDate; // doğum tarihi
  final String? parentInfo; // ebeveyn bilgisi
  final List<String> certificates; // sertifika URL'leri
  final bool isNegotiable; // pazarlık yapılabilir mi
  final String sellerType; // "bireysel", "çiftlik", "kooperatif"
  final String transportInfo; // nakliye bilgileri
  final bool isUrgentSale; // acil satış
  final String? veterinarianContact; // veteriner iletişim
  final Map<String, dynamic>? additionalInfo; // ek bilgiler

  // Mevcut sistemden devam edenler
  final List<dynamic> likes;
  final List<dynamic> saved;
  final bool isActive; // ilan aktif mi
  final DateTime? soldDate; // satış tarihi
  final String? buyerUid; // alıcı uid

  // Satış değerlendirme sistemi için yeni alanlar
  final String saleStatus; // "active", "pending", "sold"
  final double? salePrice; // gerçek satış fiyatı
  final bool hasRating; // değerlendirme var mı
  final String? ratingId; // ilgili değerlendirme ID'si
  final bool canBeRated; // değerlendirilebilir mi
  final int viewCount; // görüntülenme sayısı

  AnimalPost({
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
    required this.animalType,
    required this.animalSpecies,
    required this.animalBreed,
    required this.ageInMonths,
    required this.gender,
    required this.weightInKg,
    required this.priceInTL,
    required this.healthStatus,
    required this.vaccinations,
    required this.purpose,
    required this.isPregnant,
    this.birthDate,
    this.parentInfo,
    required this.certificates,
    required this.isNegotiable,
    required this.sellerType,
    required this.transportInfo,
    required this.isUrgentSale,
    this.veterinarianContact,
    this.additionalInfo,
    required this.likes,
    required this.saved,
    required this.isActive,
    this.soldDate,
    this.buyerUid,
    required this.saleStatus,
    this.salePrice,
    required this.hasRating,
    this.ratingId,
    required this.canBeRated,
    this.viewCount = 0,
  });

  static AnimalPost fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>? ?? {};

    // print('📋 AnimalPost.fromSnap - Document ID: ${snap.id}');
    // print('📋 AnimalPost.fromSnap - Available keys: ${snapshot.keys.toList()}');

    try {
      return AnimalPost(
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
        animalType: snapshot["animalType"] ?? '',
        animalSpecies: snapshot["animalSpecies"] ?? '',
        animalBreed: snapshot["animalBreed"] ?? '',
        ageInMonths: _safeGetInt(snapshot["ageInMonths"]),
        gender: snapshot["gender"] ?? '',
        weightInKg: _safeGetDouble(snapshot["weightInKg"]),
        priceInTL: _safeGetDouble(snapshot["priceInTL"]),
        healthStatus: snapshot["healthStatus"] ?? '',
        vaccinations: List<String>.from(snapshot["vaccinations"] ?? []),
        purpose: snapshot["purpose"] ?? '',
        isPregnant: snapshot["isPregnant"] ?? false,
        birthDate: snapshot["birthDate"]?.toDate(),
        parentInfo: snapshot["parentInfo"],
        certificates: List<String>.from(snapshot["certificates"] ?? []),
        isNegotiable: snapshot["isNegotiable"] ?? false,
        sellerType: snapshot["sellerType"] ?? '',
        transportInfo: snapshot["transportInfo"],
        isUrgentSale: snapshot["isUrgentSale"] ?? false,
        veterinarianContact: snapshot["veterinarianContact"],
        additionalInfo: snapshot["additionalInfo"],
        likes: snapshot["likes"] ?? [],
        saved: snapshot["saved"] ?? [],
        isActive: snapshot["isActive"] ?? true, // Default true
        soldDate: snapshot["soldDate"]?.toDate(),
        buyerUid: snapshot["buyerUid"],
        saleStatus: snapshot["saleStatus"] ?? "active",
        salePrice: snapshot["salePrice"] != null
            ? _safeGetDouble(snapshot["salePrice"])
            : null,
        hasRating: snapshot["hasRating"] ?? false,
        ratingId: snapshot["ratingId"],
        canBeRated: snapshot["canBeRated"] ?? false,
        viewCount: _safeGetInt(snapshot["viewCount"]),
      );
    } catch (e) {
      print('❌ Error in AnimalPost.fromSnap: $e');
      print('📋 Snapshot data: $snapshot');
      rethrow;
    }
  }

  static AnimalPost fromMap(Map<String, dynamic> data) {
    // print('📋 AnimalPost.fromMap - Available keys: ${data.keys.toList()}');

    try {
      return AnimalPost(
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
        animalType: data["animalType"] ?? '',
        animalSpecies: data["animalSpecies"] ?? '',
        animalBreed: data["animalBreed"] ?? '',
        ageInMonths: _safeGetInt(data["ageInMonths"]),
        gender: data["gender"] ?? '',
        weightInKg: _safeGetDouble(data["weightInKg"]),
        priceInTL: _safeGetDouble(data["priceInTL"]),
        healthStatus: data["healthStatus"] ?? '',
        vaccinations: List<String>.from(data["vaccinations"] ?? []),
        purpose: data["purpose"] ?? '',
        isPregnant: data["isPregnant"] ?? false,
        birthDate: data["birthDate"]?.toDate(),
        parentInfo: data["parentInfo"],
        certificates: List<String>.from(data["certificates"] ?? []),
        isNegotiable: data["isNegotiable"] ?? false,
        sellerType: data["sellerType"] ?? '',
        transportInfo: data["transportInfo"],
        isUrgentSale: data["isUrgentSale"] ?? false,
        veterinarianContact: data["veterinarianContact"],
        additionalInfo: data["additionalInfo"],
        likes: data["likes"] ?? [],
        saved: data["saved"] ?? [],
        isActive: data["isActive"] ?? true, // Default true
        soldDate: data["soldDate"]?.toDate(),
        buyerUid: data["buyerUid"],
        saleStatus: data["saleStatus"] ?? "active",
        salePrice: data["salePrice"] != null
            ? _safeGetDouble(data["salePrice"])
            : null,
        hasRating: data["hasRating"] ?? false,
        ratingId: data["ratingId"],
        canBeRated: data["canBeRated"] ?? false,
        viewCount: _safeGetInt(data["viewCount"]),
      );
    } catch (e) {
      print('❌ Error in AnimalPost.fromMap: $e');
      print('📋 Map data: $data');
      rethrow;
    }
  }

  // Helper methods for safe type conversion
  static int _safeGetInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

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
        "animalType": animalType,
        "animalSpecies": animalSpecies,
        "animalBreed": animalBreed,
        "ageInMonths": ageInMonths,
        "gender": gender,
        "weightInKg": weightInKg,
        "priceInTL": priceInTL,
        "healthStatus": healthStatus,
        "vaccinations": vaccinations,
        "purpose": purpose,
        "isPregnant": isPregnant,
        "birthDate": birthDate,
        "parentInfo": parentInfo,
        "certificates": certificates,
        "isNegotiable": isNegotiable,
        "sellerType": sellerType,
        "transportInfo": transportInfo,
        "isUrgentSale": isUrgentSale,
        "veterinarianContact": veterinarianContact,
        "additionalInfo": additionalInfo,
        "likes": likes,
        "saved": saved,
        "isActive": isActive,
        "soldDate": soldDate,
        "buyerUid": buyerUid,
        "saleStatus": saleStatus,
        "salePrice": salePrice,
        "hasRating": hasRating,
        "ratingId": ratingId,
        "canBeRated": canBeRated,
      };
}
