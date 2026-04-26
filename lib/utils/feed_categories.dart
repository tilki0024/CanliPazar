import 'package:flutter/material.dart';
import '../models/feed_post.dart';

class FeedCategories {
  static const List<String> categories = [
    'Tüm Yemler',
    
    // Kaba Yemler
    'Saman',
    'Yonca',
    'Yonca Samanı',
    'Fiğ',
    'Korunga',
    'Silaj',
    'Ot Balyası',
    'Çayır Otu',
    'Kuru Ot',
    
    // Konsantre Yemler
    'Karma Yem',
    'Arpa',
    'Arpa Ezmesi',
    'Mısır',
    'Buğday',
    'Yulaf',
    'Çavdar',
    'Tritikale',
    'Soya Küspesi',
    'Ayçiçeği Küspesi',
    'Pancar Küspesi',
    'Pamuk Tohumu Küspesi',
    'Kanola Küspesi',
    'Mısır Gluten Yemi',
    
    // Hayvan Türüne Göre
    'Büyükbaş Yemleri',
    'Küçükbaş Yemleri',
    'Kanatlı Yemleri',
    'Karma Yemler',
    
    // Özel Yemler
    'Süt Yemi',
    'Besi Yemi',
    'Toklu Besi Yemi',
    'Yavru Yemi',
    'Damızlık Yemi',
    'Büyütme Yemi',
    'Laktasyon Yemi',
    
    // Yem Katkıları
    'Premiks',
    'Vitamin Takviyeleri',
    'Mineral Takviyeleri',
    'Tuz',
    'Probiyotikler',
    'Enzimler',
    
    // Özel Durumlar
    'Organik Yemler',
    'Acil Satış',
    'Toplu Satış',
    'Yerli Yem',
    'İthal Yem',
    
    // Form Bazlı
    'Pelet Yem',
    'Granül Yem',
    'Toz Yem',
    'Tane Yem',
    
    // Paketleme Türü
    'Çuvallı Yem',
    'Dökme Yem',
    'Big Bag',
    
    // Ek Kategori
    'Yem Karışımları',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Tüm Yemler': Icons.agriculture,
    'Saman': Icons.grass,
    'Yonca': Icons.local_florist,
    'Yonca Samanı': Icons.grass,
    'Fiğ': Icons.local_florist,
    'Korunga': Icons.local_florist,
    'Silaj': Icons.eco,
    'Ot Balyası': Icons.inventory_2,
    'Çayır Otu': Icons.grass,
    'Kuru Ot': Icons.grass,
    'Karma Yem': Icons.restaurant,
    'Arpa': Icons.grain,
    'Arpa Ezmesi': Icons.grain,
    'Mısır': Icons.grain,
    'Buğday': Icons.grain,
    'Yulaf': Icons.grain,
    'Çavdar': Icons.grain,
    'Tritikale': Icons.grain,
    'Soya Küspesi': Icons.circle,
    'Ayçiçeği Küspesi': Icons.circle,
    'Pancar Küspesi': Icons.circle,
    'Pamuk Tohumu Küspesi': Icons.circle,
    'Kanola Küspesi': Icons.circle,
    'Mısır Gluten Yemi': Icons.circle,
    'Büyükbaş Yemleri': Icons.pets,
    'Küçükbaş Yemleri': Icons.pets,
    'Kanatlı Yemleri': Icons.egg,
    'Karma Yemler': Icons.restaurant,
    'Süt Yemi': Icons.local_drink,
    'Besi Yemi': Icons.restaurant,
    'Toklu Besi Yemi': Icons.restaurant,
    'Yavru Yemi': Icons.child_care,
    'Damızlık Yemi': Icons.favorite,
    'Büyütme Yemi': Icons.trending_up,
    'Laktasyon Yemi': Icons.local_drink,
    'Premiks': Icons.science,
    'Vitamin Takviyeleri': Icons.medication,
    'Mineral Takviyeleri': Icons.medication,
    'Tuz': Icons.science,
    'Probiyotikler': Icons.science,
    'Enzimler': Icons.science,
    'Organik Yemler': Icons.eco,
    'Acil Satış': Icons.flash_on,
    'Toplu Satış': Icons.inventory,
    'Yerli Yem': Icons.home,
    'İthal Yem': Icons.flight,
    'Pelet Yem': Icons.circle,
    'Granül Yem': Icons.circle,
    'Toz Yem': Icons.circle,
    'Tane Yem': Icons.grain,
    'Çuvallı Yem': Icons.inventory_2,
    'Dökme Yem': Icons.local_shipping,
    'Big Bag': Icons.inventory,
    'Yem Karışımları': Icons.blender,
  };

  static const Map<String, Color> categoryColors = {
    'Tüm Yemler': Color(0xFF2E7D32),
    'Saman': Color(0xFF8D6E63),
    'Yonca': Color(0xFF4CAF50),
    'Yonca Samanı': Color(0xFF6B8E23),
    'Fiğ': Color(0xFF66BB6A),
    'Korunga': Color(0xFF81C784),
    'Silaj': Color(0xFF388E3C),
    'Ot Balyası': Color(0xFF6D4C41),
    'Çayır Otu': Color(0xFF9E9E9E),
    'Kuru Ot': Color(0xFF757575),
    'Karma Yem': Color(0xFFFF9800),
    'Arpa': Color(0xFFFFB74D),
    'Arpa Ezmesi': Color(0xFFFFC947),
    'Mısır': Color(0xFFFFA726),
    'Buğday': Color(0xFFFFCC02),
    'Yulaf': Color(0xFFFFD54F),
    'Çavdar': Color(0xFFFFE082),
    'Tritikale': Color(0xFFFFECB3),
    'Soya Küspesi': Color(0xFF795548),
    'Ayçiçeği Küspesi': Color(0xFFFFC107),
    'Pancar Küspesi': Color(0xFFE91E63),
    'Pamuk Tohumu Küspesi': Color(0xFF9E9E9E),
    'Kanola Küspesi': Color(0xFFFFEB3B),
    'Mısır Gluten Yemi': Color(0xFFFFA726),
    'Büyükbaş Yemleri': Color(0xFF6D4C41),
    'Küçükbaş Yemleri': Color(0xFF9E9E9E),
    'Kanatlı Yemleri': Color(0xFFFFC107),
    'Karma Yemler': Color(0xFFFF9800),
    'Süt Yemi': Color(0xFF2196F3),
    'Besi Yemi': Color(0xFFE53935),
    'Toklu Besi Yemi': Color(0xFFD32F2F),
    'Yavru Yemi': Color(0xFF81D4FA),
    'Damızlık Yemi': Color(0xFFE91E63),
    'Büyütme Yemi': Color(0xFF4CAF50),
    'Laktasyon Yemi': Color(0xFF2196F3),
    'Premiks': Color(0xFF9C27B0),
    'Vitamin Takviyeleri': Color(0xFF00BCD4),
    'Mineral Takviyeleri': Color(0xFF009688),
    'Tuz': Color(0xFFE0E0E0),
    'Probiyotikler': Color(0xFF4CAF50),
    'Enzimler': Color(0xFF3F51B5),
    'Organik Yemler': Color(0xFF4CAF50),
    'Acil Satış': Color(0xFFE53935),
    'Toplu Satış': Color(0xFFFF9800),
    'Yerli Yem': Color(0xFF2E7D32),
    'İthal Yem': Color(0xFF2196F3),
    'Pelet Yem': Color(0xFF757575),
    'Granül Yem': Color(0xFF9E9E9E),
    'Toz Yem': Color(0xFFBDBDBD),
    'Tane Yem': Color(0xFFFFB74D),
    'Çuvallı Yem': Color(0xFF8D6E63),
    'Dökme Yem': Color(0xFF616161),
    'Big Bag': Color(0xFF424242),
    'Yem Karışımları': Color(0xFF9C27B0),
  };

  static const List<String> feedTypes = [
    'kaba yem',
    'konsantre yem',
    'yem katkısı',
  ];

  // Kategorileri yem türlerine göre eşleştirme
  static const Map<String, String> categoryToFeedType = {
    // Kaba Yemler
    'Saman': 'kaba yem',
    'Yonca': 'kaba yem',
    'Yonca Samanı': 'kaba yem',
    'Fiğ': 'kaba yem',
    'Korunga': 'kaba yem',
    'Silaj': 'kaba yem',
    'Ot Balyası': 'kaba yem',
    'Çayır Otu': 'kaba yem',
    'Kuru Ot': 'kaba yem',
    
    // Konsantre Yemler
    'Karma Yem': 'konsantre yem',
    'Arpa': 'konsantre yem',
    'Arpa Ezmesi': 'konsantre yem',
    'Mısır': 'konsantre yem',
    'Buğday': 'konsantre yem',
    'Yulaf': 'konsantre yem',
    'Çavdar': 'konsantre yem',
    'Tritikale': 'konsantre yem',
    'Soya Küspesi': 'konsantre yem',
    'Ayçiçeği Küspesi': 'konsantre yem',
    'Pancar Küspesi': 'konsantre yem',
    'Pamuk Tohumu Küspesi': 'konsantre yem',
    'Kanola Küspesi': 'konsantre yem',
    'Mısır Gluten Yemi': 'konsantre yem',
    'Süt Yemi': 'konsantre yem',
    'Besi Yemi': 'konsantre yem',
    'Toklu Besi Yemi': 'konsantre yem',
    'Yavru Yemi': 'konsantre yem',
    'Damızlık Yemi': 'konsantre yem',
    'Büyütme Yemi': 'konsantre yem',
    'Laktasyon Yemi': 'konsantre yem',
    
    // Yem Katkıları
    'Premiks': 'yem katkısı',
    'Vitamin Takviyeleri': 'yem katkısı',
    'Mineral Takviyeleri': 'yem katkısı',
    'Tuz': 'yem katkısı',
    'Probiyotikler': 'yem katkısı',
    'Enzimler': 'yem katkısı',
  };

  // Yem türüne göre kategorileri getir
  static List<String> getCategoriesByFeedType(String feedType) {
    if (feedType == 'kaba yem') {
      return [
        'Saman',
        'Yonca',
        'Yonca Samanı',
        'Fiğ',
        'Korunga',
        'Silaj',
        'Ot Balyası',
        'Çayır Otu',
        'Kuru Ot',
      ];
    } else if (feedType == 'konsantre yem') {
      return [
        'Karma Yem',
        'Arpa',
        'Arpa Ezmesi',
        'Mısır',
        'Buğday',
        'Yulaf',
        'Çavdar',
        'Tritikale',
        'Soya Küspesi',
        'Ayçiçeği Küspesi',
        'Pancar Küspesi',
        'Pamuk Tohumu Küspesi',
        'Kanola Küspesi',
        'Mısır Gluten Yemi',
        'Süt Yemi',
        'Besi Yemi',
        'Toklu Besi Yemi',
        'Yavru Yemi',
        'Damızlık Yemi',
        'Büyütme Yemi',
        'Laktasyon Yemi',
      ];
    } else if (feedType == 'yem katkısı') {
      return [
        'Premiks',
        'Vitamin Takviyeleri',
        'Mineral Takviyeleri',
        'Tuz',
        'Probiyotikler',
        'Enzimler',
      ];
    }
    return categories.where((c) => c != 'Tüm Yemler').toList();
  }

  static const List<String> animalTypes = [
    'büyükbaş',
    'küçükbaş',
    'kanatlı',
    'karma',
  ];

  static const List<String> quantityUnits = [
    'kg',
    'ton',
  ];

  static const List<String> priceUnits = [
    'kg',
    'ton',
    'çuval',
  ];

  static const List<String> packagingTypes = [
    'çuvallı',
    'dökme',
    'big bag',
  ];

  static const List<String> sellerTypes = [
    'Bireysel',
    'Çiftlik',
    'Kooperatif',
    'Yem Fabrikası',
    'Tarım İşletmesi',
    'Hayvancılık Şirketi',
    'Toptancı',
    'Bayi',
  ];

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.agriculture;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? const Color(0xFF2E7D32);
  }

  static bool matchesCategory(FeedPost feed, String category) {
    switch (category) {
      case 'Tüm Yemler':
        return true;
      
      // Kaba Yemler
      case 'Saman':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('saman');
      case 'Yonca':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('yonca') &&
               !feed.feedCategory.toLowerCase().contains('samanı');
      case 'Yonca Samanı':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('yonca') &&
               feed.feedCategory.toLowerCase().contains('samanı');
      case 'Fiğ':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('fiğ');
      case 'Korunga':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('korunga');
      case 'Silaj':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('silaj');
      case 'Ot Balyası':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               (feed.feedCategory.toLowerCase().contains('ot balyası') ||
               feed.feedCategory.toLowerCase().contains('balya'));
      case 'Çayır Otu':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('çayır');
      case 'Kuru Ot':
        return feed.feedType.toLowerCase() == 'kaba yem' &&
               feed.feedCategory.toLowerCase().contains('kuru ot');
      
      // Konsantre Yemler
      case 'Karma Yem':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('karma');
      case 'Arpa':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('arpa') &&
               !feed.feedCategory.toLowerCase().contains('ezmesi');
      case 'Arpa Ezmesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('arpa') &&
               feed.feedCategory.toLowerCase().contains('ezmesi');
      case 'Mısır':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('mısır');
      case 'Buğday':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('buğday');
      case 'Yulaf':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('yulaf');
      case 'Çavdar':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('çavdar');
      case 'Tritikale':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('tritikale');
      case 'Soya Küspesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('soya');
      case 'Ayçiçeği Küspesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('ayçiçeği');
      case 'Pancar Küspesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('pancar');
      case 'Pamuk Tohumu Küspesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('pamuk');
      case 'Kanola Küspesi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('kanola');
      case 'Mısır Gluten Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('gluten');
      
      // Hayvan Türüne Göre
      case 'Büyükbaş Yemleri':
        return feed.animalType.toLowerCase() == 'büyükbaş';
      case 'Küçükbaş Yemleri':
        return feed.animalType.toLowerCase() == 'küçükbaş';
      case 'Kanatlı Yemleri':
        return feed.animalType.toLowerCase() == 'kanatlı';
      case 'Karma Yemler':
        return feed.animalType.toLowerCase() == 'karma';
      
      // Özel Yemler
      case 'Süt Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('süt');
      case 'Besi Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('besi') &&
               !feed.feedCategory.toLowerCase().contains('toklu');
      case 'Toklu Besi Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('toklu') &&
               feed.feedCategory.toLowerCase().contains('besi');
      case 'Yavru Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('yavru');
      case 'Damızlık Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('damızlık');
      case 'Büyütme Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('büyütme');
      case 'Laktasyon Yemi':
        return feed.feedType.toLowerCase() == 'konsantre yem' &&
               feed.feedCategory.toLowerCase().contains('laktasyon');
      
      // Yem Katkıları
      case 'Premiks':
        return feed.feedCategory.toLowerCase().contains('premiks');
      case 'Vitamin Takviyeleri':
        return feed.feedCategory.toLowerCase().contains('vitamin');
      case 'Mineral Takviyeleri':
        return feed.feedCategory.toLowerCase().contains('mineral');
      case 'Tuz':
        return feed.feedCategory.toLowerCase().contains('tuz');
      case 'Probiyotikler':
        return feed.feedCategory.toLowerCase().contains('probiyotik');
      case 'Enzimler':
        return feed.feedCategory.toLowerCase().contains('enzim');
      
      // Özel Durumlar
      case 'Organik Yemler':
        return feed.isOrganic;
      case 'Acil Satış':
        return feed.isUrgentSale;
      case 'Toplu Satış':
        return feed.isBulkSale;
      case 'Yerli Yem':
        return feed.isLocal;
      case 'İthal Yem':
        return !feed.isLocal;
      
      // Form Bazlı
      case 'Pelet Yem':
        return feed.packagingType.toLowerCase().contains('pelet') ||
               feed.feedCategory.toLowerCase().contains('pelet');
      case 'Granül Yem':
        return feed.packagingType.toLowerCase().contains('granül') ||
               feed.feedCategory.toLowerCase().contains('granül');
      case 'Toz Yem':
        return feed.packagingType.toLowerCase().contains('toz') ||
               feed.feedCategory.toLowerCase().contains('toz');
      case 'Tane Yem':
        return feed.packagingType.toLowerCase().contains('tane') ||
               feed.feedCategory.toLowerCase().contains('tane');
      
      // Paketleme Türü
      case 'Çuvallı Yem':
        return feed.packagingType.toLowerCase() == 'çuvallı';
      case 'Dökme Yem':
        return feed.packagingType.toLowerCase() == 'dökme';
      case 'Big Bag':
        return feed.packagingType.toLowerCase().contains('big bag') ||
               feed.packagingType.toLowerCase().contains('bigbag');
      
      case 'Yem Karışımları':
        return feed.feedCategory.toLowerCase().contains('karışım') ||
               feed.feedCategory.toLowerCase().contains('mix');
      
      default:
        return false;
    }
  }
}

