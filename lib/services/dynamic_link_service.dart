import 'package:cloud_functions/cloud_functions.dart';

/// Firebase Dynamic Links servisi - Production Ready
/// Her ilan için dinamik link oluşturur ve yönetir
/// 
/// Firebase Dynamic Links API kullanarak short link oluşturur
/// Uygulama yüklüyse → İlan sayfasını açar
/// Uygulama yüklü değilse → Store'a yönlendirir
class DynamicLinkService {
  static const String _androidPackageName = 'com.canlipazar';
  static const String _iosBundleId = 'com.canlipazar.app';
  static const String _iosAppStoreId = '6476391295'; // Gerçek App Store ID
  
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// İlan için Dynamic Link oluştur
  /// 
  /// Firebase Dynamic Links API kullanarak short link oluşturur
  /// Uygulama yüklüyse → İlan sayfasını açar
  /// Uygulama yüklü değilse → Store'a yönlendirir
  /// 
  /// [ilanId] - İlan ID'si
  /// [ilanBaslik] - İlan başlığı (Open Graph için)
  /// [ilanAciklama] - İlan açıklaması (Open Graph için)
  /// [ilanResmiUrl] - İlan resmi URL'si (Open Graph için)
  /// 
  /// Returns: Dynamic Link URL'si (short link veya fallback Universal Link)
  Future<String> createDynamicLink({
    required String ilanId,
    required String ilanBaslik,
    required String ilanAciklama,
    required String ilanResmiUrl,
  }) async {
    try {
      print('🔗 Dynamic Link oluşturuluyor - İlan ID: $ilanId');
      
      // Deep link URL'si (Universal Link / App Link)
      final String deepLink = 'https://canlipazar.net/ilan/$ilanId';
      
      // Cloud Functions'ı çağır
      try {
        final callable = _functions.httpsCallable('createDynamicLink');
        
        final result = await callable.call({
          'deepLink': deepLink,
          'androidPackageName': _androidPackageName,
          'iosBundleId': _iosBundleId,
          'iosAppStoreId': _iosAppStoreId,
          'title': ilanBaslik,
          'description': ilanAciklama,
          'imageUrl': ilanResmiUrl,
        });
        
        final data = result.data as Map<String, dynamic>;
        final shortLink = data['shortLink'] as String? ?? deepLink;
        
        print('✅ Dynamic Link oluşturuldu: $shortLink');
        return shortLink;
      } catch (e) {
        // Cloud Functions hatası durumunda fallback olarak Universal Link döndür
        print('⚠️ Cloud Functions hatası, fallback link kullanılıyor: $e');
        print('✅ Fallback Universal Link: $deepLink');
        return deepLink;
      }
    } catch (e, stackTrace) {
      print('❌ Dynamic link oluşturma hatası: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Hata durumunda fallback olarak Universal Link döndür
      final String fallbackLink = 'https://canlipazar.net/ilan/$ilanId';
      print('⚠️ Fallback link kullanılıyor: $fallbackLink');
      return fallbackLink;
    }
  }

  /// Dynamic link'i parse et ve ilan ID'sini çıkar
  /// 
  /// [dynamicLink] - Parse edilecek dynamic link
  /// 
  /// Returns: İlan ID'si veya null
  String? parseDynamicLink(Uri dynamicLink) {
    try {
      final String linkString = dynamicLink.toString();
      
      // Eğer dynamic link ise, deep link'i çıkar
      if (linkString.contains('canlipazar.page.link')) {
        // Dynamic link'ten deep link'i çıkarmak için query parametrelerini kontrol et
        final uri = dynamicLink;
        if (uri.queryParameters.containsKey('link')) {
          final String deepLink = uri.queryParameters['link']!;
          return _extractIlanIdFromDeepLink(deepLink);
        }
        // Eğer query parametresi yoksa, path'i kontrol et
        if (uri.pathSegments.isNotEmpty) {
          // Short link formatı: https://canlipazar.page.link/xxxxx
          // Bu durumda Cloud Functions'tan deep link'i almak gerekir
          // Şimdilik fallback olarak null döndür
          return null;
        }
      }
      
      // Eğer deep link ise, ilan ID'sini çıkar
      return _extractIlanIdFromDeepLink(linkString);
    } catch (e) {
      print('❌ Dynamic link parse hatası: $e');
      return null;
    }
  }

  /// Deep link'ten ilan ID'sini çıkar
  String? _extractIlanIdFromDeepLink(String deepLink) {
    try {
      // /ilan/{ilanId} formatını kontrol et
      if (deepLink.contains('/ilan/')) {
        final List<String> parts = deepLink.split('/ilan/');
        if (parts.length > 1) {
          final String ilanId = parts[1].split('?')[0].split('#')[0];
          return ilanId;
        }
      }
      // Geriye dönük uyumluluk için /animal/ formatını da kontrol et
      if (deepLink.contains('/animal/')) {
        final List<String> parts = deepLink.split('/animal/');
        if (parts.length > 1) {
          final String ilanId = parts[1].split('?')[0].split('#')[0];
          return ilanId;
        }
      }
      return null;
    } catch (e) {
      print('❌ Deep link parse hatası: $e');
      return null;
    }
  }

  /// Dynamic link'i yakala ve callback ile ilan ID'sini döndür
  /// 
  /// [onLinkReceived] - Dynamic link yakalandığında çağrılacak callback
  /// 
  /// NOT: Bu fonksiyon app_links paketi ile entegre edilmelidir
  /// main.dart'ta _initDeepLinkHandler() içinde kullanılır
  Future<void> listenToDynamicLinks({
    required Function(String ilanId) onLinkReceived,
  }) async {
    // Bu fonksiyon app_links paketi ile entegre edilmiştir
    // main.dart'ta _initDeepLinkHandler() içinde kullanılır
    print('ℹ️ Dynamic link dinleme app_links paketi ile yapılıyor');
  }
}
