/// Firestore `animalType` alanında büyük/küçük harf tutarsızlığı için sorgu varyantları.
/// [whereIn] en fazla 10 değer alır.
List<String> animalTypeWhereInVariants(String uiSelected) {
  if (uiSelected == 'Tümü' || uiSelected == 'Tüm Hayvanlar') {
    return const [];
  }
  final t = uiSelected.trim();
  final lower = t.toLowerCase();
  final variants = <String>{t, lower};

  switch (lower) {
    case 'büyükbaş':
    case 'buyukbas':
      variants.addAll(const [
        'Büyükbaş',
        'büyükbaş',
        'BÜYÜKBAŞ',
        // Diyakritik olmayan/ASCII varyantlar (Firestore'a öyle kaydedilmiş olabilir).
        'buyukbas',
        'BUYUKBAS',
      ]);
      break;
    case 'küçükbaş':
    case 'kucukbas':
      variants.addAll(const [
        'Küçükbaş',
        'küçükbaş',
        'KÜÇÜKBAŞ',
        // Diyakritik olmayan/ASCII varyantlar.
        'kucukbas',
        'KUCUKBAS',
      ]);
      break;
    case 'kanatlı':
    case 'kanatli':
      variants.addAll(const [
        'Kanatlı',
        'kanatlı',
        'KANATLI',
        // ASCII varyantlar.
        'Kanatli',
        'kanatli',
      ]);
      break;
    default:
      variants.add(lower.toUpperCase());
  }

  return variants.take(10).toList();
}

/// İlan kartı / liste için görsel URL (şimdilik orijinal; CDN thumb parametresi eklenebilir).
String listingThumbnailUrl(String originalUrl, {int maxSide = 480}) {
  if (originalUrl.isEmpty) return originalUrl;
  // Firebase Storage: ?alt=media ile gelen URL'lere boyut eklenmez; memCache ile küçültülür.
  return originalUrl;
}

String animalHeroTag(String postId) => 'animal_hero_$postId';

/// Firestore'da `city` alanı bazen büyük/küçük harf veya ASCII/diakritik
/// farklılıklarla kaydedilmiş olabiliyor.
///
/// Bu helper, tek bir şehir seçildiğinde query'yi `whereIn` ile daha kapsayıcı hale getirir.
/// Not: whereIn max ~10 değer alır; burada küçük bir set dönüyoruz.
List<String> cityWhereInVariants(String uiCity) {
  final t = uiCity.trim();
  if (t.isEmpty) return const [];

  final lower = t.toLowerCase();
  final upper = t.toUpperCase();

  // TR karakterleri için ASCII karşılıkları (sadece olası varyant artırmak için)
  String asciiLower = lower
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
  final asciiUpper = asciiLower.toUpperCase();

  final variants = <String>{
    t,
    lower,
    upper,
    asciiLower,
    asciiUpper,
  };

  return variants.take(10).toList();
}
