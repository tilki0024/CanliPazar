import 'package:flutter/material.dart';

class AnimalCategories {
  static const List<String> categories = [
    'Tüm Hayvanlar',

    // Büyükbaş Kategoriler
    'Süt Sığırı',
    'Et Sığırı',
    'Damızlık Boğa',
    'Düve',
    'Manda',
    'Tosun',

    // Küçükbaş Kategoriler
    'Koyun',
    'Keçi',
    'Kuzu',
    'Oğlak',
    'Koç',
    'Teke',
    'Kurbanlık',

    // Kanatlı ve Adaklık
    'Kanatlı',
    'Adaklık Hayvanlar',

    // Özel Kategoriler
    'Gebe Hayvanlar',
    'Genç Hayvanlar',
    'Damızlık Hayvanlar',
    'Acil Satış',
    'Süt Veren',
    'Et İçin',
    'Organik Beslenmiş',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Süt Sığırı': Icons.local_drink,
    'Et Sığırı': Icons.restaurant,
    'Damızlık Boğa': Icons.pets,
    'Düve': Icons.pets,
    'Manda': Icons.pets,
    'Tosun': Icons.pets,
    'Koyun': Icons.pets,
    'Keçi': Icons.pets,
    'Kuzu': Icons.child_care,
    'Oğlak': Icons.child_care,
    'Koç': Icons.pets,
    'Teke': Icons.pets,
    'Kurbanlık': Icons.favorite,
    'Kanatlı': Icons.egg,
    'Adaklık Hayvanlar': Icons.volunteer_activism,
    'Gebe Hayvanlar': Icons.pregnant_woman,
    'Genç Hayvanlar': Icons.child_care,
    'Damızlık Hayvanlar': Icons.favorite,
    'Acil Satış': Icons.flash_on,
    'Süt Veren': Icons.local_drink,
    'Et İçin': Icons.restaurant,
    'Organik Beslenmiş': Icons.eco,
  };

  static const Map<String, Color> categoryColors = {
    'Süt Sığırı': Colors.blue,
    'Et Sığırı': Colors.red,
    'Damızlık Boğa': Colors.purple,
    'Düve': Colors.pink,
    'Manda': Colors.brown,
    'Tosun': Colors.orange,
    'Koyun': Colors.grey,
    'Keçi': Colors.green,
    'Kuzu': Colors.lightBlue,
    'Oğlak': Colors.lightGreen,
    'Koç': Colors.blueGrey,
    'Teke': Colors.teal,
    'Kurbanlık': Colors.red,
    'Kanatlı': Colors.amber,
    'Adaklık Hayvanlar': Colors.deepOrange,
    'Gebe Hayvanlar': Colors.purple,
    'Genç Hayvanlar': Colors.lightBlue,
    'Damızlık Hayvanlar': Colors.pink,
    'Acil Satış': Colors.red,
    'Süt Veren': Colors.blue,
    'Et İçin': Colors.red,
    'Organik Beslenmiş': Colors.green,
  };

  static const List<String> animalTypes = [
    'büyükbaş',
    'küçükbaş',
    'kanatlı',
  ];

  static const List<String> animalSpecies = [
    'Sığır',
    'Koyun',
    'Keçi',
    'Manda',
    // Kanatlı türleri
    'Tavuk',
    'Hindi',
    'Kaz',
    'Ördek',
    'Bıldırcın',
    'Güvercin',
  ];

  static const List<String> animalBreeds = [
    // Sığır ırkları
    'Angus',
    'Belçika Mavisi',
    'Boz Irk',
    'Brown Swiss',
    'Hereford',
    'Holstein',
    'Jersey',
    'Limuzin',
    'Montofon',
    'Red Holstein',
    'Simmental',
    'Şarole',
    'Yerli Kara',

    // Koyun ırkları
    'Akkaraman',
    'Alman Karabaş',
    'Çine Çapari',
    'Dağlıç',
    'France',
    'Hemşin',
    'İvesi',
    'Kangal',
    'Karakul',
    'Kıvırcık',
    'Merinos',
    'Morkaraman',
    'Sakız',
    'Zwartbles',

    // Keçi ırkları
    'Angora',
    'Çanakkale',
    'Gökçeada',
    'Halep',
    'Honamli',
    'Kilis',
    'Kıl Keçisi',
    'Malta',
    'Norduz',
    'Saanen',

    // Manda ırkları
    'Afyon Mandası',
    'Anadolu Mandası',
    'Karabük Mandası',
    'Murrah',
    'Nili Ravi',

    // Kanatlı ırkları
    'Ameraucana',
    'Ataks',
    'Beyaz Hindi',
    'Brahma',
    'Bronz Hindi',
    'Çin Kazı',
    'Japon Bıldırcın',
    'Jumbo Bıldırcın',
    'Ligorin',
    'Macar Kazı',
    'Melez',
    'Miro',
    'Pekin Ördeği',
    'Plymouth Rock',
    'Posta Güvercini',
    'Rhode Island',
    'Rouen',
    'Sasso',
    'Sussex',
    'Taklacı',
    'Toulouse',
  ];

  static const List<String> healthStatuses = [
    'Sağlıklı',
    'Aşılı',
    'Hasta',
    'Tedavi Gören',
    'Karantinada',
    'Veteriner Kontrolü Gerekli',
  ];

  static const List<String> vaccineTypes = [
    'Şap',
    'Brucella',
    'Tuberculin',
    'Antraks',
    'Enterotoksemi',
    'Bluetongue',
    'Tetanos',
    'Viral Diyare',
    'Rhinotracheitis',
    'Parainfluenza',
    'RSV',
    'Pasteurella',
    'Salmonella',
    'E. Coli',
    'Rotavirus',
    'Coronavirus',
  ];

  static const List<String> purposes = [
    'Süt',
    'Et',
    'Damızlık',
    'Yün',
    'Yapağı',
    'Tiftik',
    'Kıl',
    'Deri',
    'Gübre',
    'Çift Gücü',
    'Hobi',
    'Çiftlik Süsü',
    'Adaklık',
    'Kurbanlık',
  ];

  static const List<String> sellerTypes = [
    'Bireysel',
    'Çiftlik',
    'Kooperatif',
    'Tarım İşletmesi',
    'Hayvancılık Şirketi',
    'Veteriner Hekim',
    'Ziraat Mühendisi',
    'Gıda Mühendisi',
    'Hayvan Bakım Uzmanı',
  ];

  static const List<String> genders = [
    'Erkek',
    'Dişi',
  ];

  static const List<String> farmTypes = [
    'Süt Çiftliği',
    'Et Çiftliği',
    'Damızlık Çiftliği',
    'Organik Çiftlik',
    'Entegre Çiftlik',
    'Hobi Çiftliği',
    'Aile Çiftliği',
    'Ticari Çiftlik',
    'Kooperatif Çiftlik',
    'Devlet Çiftliği',
  ];

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.pets;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }

  static bool isBigAnimal(String animalType) {
    return animalType.toLowerCase() == 'büyükbaş';
  }

  static bool isSmallAnimal(String animalType) {
    return animalType.toLowerCase() == 'küçükbaş';
  }

  static List<String> getSpeciesForType(String animalType) {
    if (isBigAnimal(animalType)) {
      return ['Sığır', 'Manda'];
    } else if (isSmallAnimal(animalType)) {
      return ['Koyun', 'Keçi'];
    } else if (animalType.toLowerCase() == 'kanatlı') {
      return ['Tavuk', 'Hindi', 'Kaz', 'Ördek', 'Bıldırcın', 'Güvercin'];
    }
    return animalSpecies;
  }

  // Hayvan türüne göre tüm cinsleri getir (büyükbaş, küçükbaş, kanatlı)
  static List<String> getBreedsForType(String animalType) {
    if (isBigAnimal(animalType)) {
      // Sığır + Manda ırkları
      return [
        // Sığır ırkları
        'Angus', 'Belçika Mavisi', 'Boz Irk', 'Brown Swiss', 'Hereford',
        'Holstein', 'Jersey', 'Limuzin', 'Montofon', 'Red Holstein',
        'Simmental', 'Şarole', 'Yerli Kara',
        // Manda ırkları
        'Afyon Mandası', 'Anadolu Mandası', 'Karabük Mandası', 'Murrah',
        'Nili Ravi',
      ];
    } else if (isSmallAnimal(animalType)) {
      // Koyun + Keçi ırkları
      return [
        // Koyun ırkları
        'Akkaraman', 'Alman Karabaş', 'Çine Çapari', 'Dağlıç', 'France',
        'Hemşin', 'İvesi', 'Kangal', 'Karakul', 'Kıvırcık',
        'Merinos', 'Morkaraman', 'Sakız', 'Zwartbles',
        // Keçi ırkları
        'Angora', 'Çanakkale', 'Gökçeada', 'Halep', 'Honamli',
        'Kilis', 'Kıl Keçisi', 'Malta', 'Norduz', 'Saanen',
      ];
    } else if (animalType.toLowerCase() == 'kanatlı') {
      return [
        'Ameraucana',
        'Ataks',
        'Beyaz Hindi',
        'Brahma',
        'Bronz Hindi',
        'Çin Kazı',
        'Japon Bıldırcın',
        'Jumbo Bıldırcın',
        'Ligorin',
        'Macar Kazı',
        'Melez',
        'Miro',
        'Pekin Ördeği',
        'Plymouth Rock',
        'Posta Güvercini',
        'Rhode Island',
        'Rouen',
        'Sasso',
        'Sussex',
        'Taklacı',
        'Toulouse',
      ];
    }
    return animalBreeds;
  }

  static List<String> getBreedsForSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'sığır':
        return animalBreeds
            .where((breed) => [
                  'Angus',
                  'Belçika Mavisi',
                  'Boz Irk',
                  'Brown Swiss',
                  'Hereford',
                  'Holstein',
                  'Jersey',
                  'Limuzin',
                  'Montofon',
                  'Red Holstein',
                  'Simmental',
                  'Şarole',
                  'Yerli Kara'
                ].contains(breed))
            .toList();
      case 'koyun':
        return animalBreeds
            .where((breed) => [
                  'Akkaraman',
                  'Alman Karabaş',
                  'Çine Çapari',
                  'Dağlıç',
                  'France',
                  'Hemşin',
                  'İvesi',
                  'Kangal',
                  'Karakul',
                  'Kıvırcık',
                  'Merinos',
                  'Morkaraman',
                  'Sakız',
                  'Zwartbles'
                ].contains(breed))
            .toList();
      case 'keçi':
        return animalBreeds
            .where((breed) => [
                  'Angora',
                  'Çanakkale',
                  'Gökçeada',
                  'Halep',
                  'Honamli',
                  'Kilis',
                  'Kıl Keçisi',
                  'Malta',
                  'Norduz',
                  'Saanen'
                ].contains(breed))
            .toList();
      case 'manda':
        return animalBreeds
            .where((breed) => [
                  'Afyon Mandası',
                  'Anadolu Mandası',
                  'Karabük Mandası',
                  'Murrah',
                  'Nili Ravi'
                ].contains(breed))
            .toList();
      case 'tavuk':
        return [
          'Ameraucana',
          'Ataks',
          'Brahma',
          'Ligorin',
          'Melez',
          'Plymouth Rock',
          'Rhode Island',
          'Sasso',
          'Sussex',
        ];
      case 'hindi':
        return [
          'Beyaz Hindi',
          'Bronz Hindi',
        ];
      case 'kaz':
        return [
          'Çin Kazı',
          'Macar Kazı',
        ];
      case 'ördek':
        return [
          'Pekin Ördeği',
          'Rouen',
          'Toulouse',
        ];
      case 'bıldırcın':
        return [
          'Japon Bıldırcın',
          'Jumbo Bıldırcın',
        ];
      case 'güvercin':
        return [
          'Miro',
          'Posta Güvercini',
          'Taklacı',
        ];
      default:
        return animalBreeds;
    }
  }
}
