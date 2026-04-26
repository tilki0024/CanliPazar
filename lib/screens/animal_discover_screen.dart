import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_post.dart';
import '../widgets/animal_card.dart';
import '../utils/animal_categories.dart';
import '../services/pricing_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'animal_detail_screen.dart';
import '../utils/safe_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/home_filter_action_sheet.dart';
import 'login_screen.dart';
import '../utils/animal_firestore_filters.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Kategori önbellek girdisi: liste, pagination cursor ve devamı var mı bilgisi.
class _CategoryCacheEntry {
  final List<AnimalPost> list;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  _CategoryCacheEntry(this.list, this.lastDoc, this.hasMore);
}

class AnimalDiscoverScreen extends StatefulWidget {
  /// Dışarıdan verilirse (örn. alt navigasyonda "Ana Sayfa" tekrar tıklanınca scroll-to-top için) bu controller kullanılır.
  final ScrollController? scrollController;

  const AnimalDiscoverScreen({Key? key, this.scrollController}) : super(key: key);

  @override
  State<AnimalDiscoverScreen> createState() => _AnimalDiscoverScreenState();
}

class _AnimalDiscoverScreenState extends State<AnimalDiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _appLinks = AppLinks();

  bool isGridView = true;
  String selectedCategory = 'Tüm Hayvanlar';
  String selectedPurpose = 'Tümü'; // Yeni filtre: Kullanım Amacı
  String selectedAnimalType = 'Tümü';
  String searchQuery = '';
  RangeValues priceRange = RangeValues(0, 500000); // Fiyat aralığını artırdık
  RangeValues ageRange = RangeValues(0, 120);
  String selectedGender = 'Tümü';
  String selectedHealthStatus = 'Tümü';
  String selectedCity = 'Tüm Şehirler';
  String selectedBreed = 'Tümü'; // Cins filtresi
  /// Akıllı aramadan çıkarılan tür (sığır, koyun, keçi, manda, tavuk vb.). Firestore sorgusunda kullanılır.
  String selectedAnimalSpecies = 'Tümü';
  /// Arama metninden çıkarılan kelimeler; fallback ve client-side eşleşmede kullanılır (büyük/küçük harf duyarsız).
  List<String> _searchKeywords = [];
  HomeSortOrder _homeSortOrder = HomeSortOrder.dateNewest;
  bool showFilters = false;
  bool showUrgentOnly = false; // Acil satış filtresi
  int filteredResultsCount = 0; // Filtrelenen sonuç sayısı
  int _totalAnimalsCount = 0; // Toplam hayvan sayısı (Firebase'den)
  bool _isFetchingTotalCount = false; // Toplam sayı yükleniyor mu
  bool _isFiltering =
      false; // Filtreleme işlemi devam ediyor mu (sayı hesaplanırken)

  // Local state for immediate updates
  List<AnimalPost> _allAnimals = [];
  List<AnimalPost> _filteredAnimals = [];

  // Track if filters have been modified from defaults
  bool _filtersModified = false;

  // Pagination state
  int _limit = 15;
  /// İlk açılışta kategori (Büyükbaş/Küçükbaş) için tek batch boyutu; hızlı ilk gösterim için.
  static const int _initialCategoryBatchSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;
  late final ScrollController _scrollController;
  bool _ownsScrollController = false;

  /// Kategori verisi önbelleği: sekme geçişinde anında gösterim ve tekrar tıklamada gecikme yok.
  static const List<String> _popularTypesForPrefetch = ['Büyükbaş', 'Küçükbaş'];
  final Map<String, _CategoryCacheEntry> _categoryCache = {};
  bool _prefetchDone = false;

  final TextEditingController _searchController = TextEditingController();

  /// Deep link stream - dispose'da iptal edilir (memory leak önleme)
  StreamSubscription<Uri>? _appLinksSubscription;

  // Debounce timer - slider kaydırırken kasma önler
  Timer? _filterDebounceTimer;
  // Memory leak ve çakışma önleyici işlem ID'si
  int _loadingOperationId = 0;

  // Classic color palette - ProfileScreen2'den alındı
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);

  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Responsive helper methods
  bool get isSmallScreen => MediaQuery.of(context).size.width < 360;
  bool get isMediumScreen =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 600;

  double get filterPanelMaxHeight =>
      MediaQuery.of(context).size.height * (isSmallScreen ? 0.8 : 0.7);
  double get filterPanelMaxWidth =>
      isLargeScreen ? 400.0 : MediaQuery.of(context).size.width * 0.95;

  int get maxVisibleCategories => isSmallScreen
      ? 4
      : isMediumScreen
          ? 6
          : 8;

  /// Filtrelenmiş listeyi seçilen sıralama kriterine göre döndürür.
  List<AnimalPost> get _sortedFilteredAnimals {
    final list = List<AnimalPost>.from(_filteredAnimals);
    switch (_homeSortOrder) {
      case HomeSortOrder.dateNewest:
        list.sort((a, b) => b.datePublished.compareTo(a.datePublished));
        break;
      case HomeSortOrder.dateOldest:
        list.sort((a, b) => a.datePublished.compareTo(b.datePublished));
        break;
      case HomeSortOrder.priceHigh:
        list.sort((a, b) => b.priceInTL.compareTo(a.priceInTL));
        break;
      case HomeSortOrder.priceLow:
        list.sort((a, b) => a.priceInTL.compareTo(b.priceInTL));
        break;
    }
    return list;
  }

  // Türkiye şehirleri listesi
  static const List<String> turkishCities = [
    'Tüm Şehirler',
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    initDeepLinks();
    _scrollController.addListener(_onScroll);
    // Firestore'un hazır olması için widget build edildikten sonra yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialAnimals();
      _fetchTotalCount(); // Toplam hayvan sayısını al
    });
    Future.delayed(const Duration(milliseconds: 800), _prefetchPopularCategories);
  }

  void initDeepLinks() {
    _appLinksSubscription?.cancel();
    _appLinksSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('Gelen Link: $uri');

      // Link yapımız: https://tilki0024.github.io/ilanapps/123
      if (uri.path.contains('ilanapps')) {
        String ilanId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

        if (ilanId.isEmpty) return;
        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('animals')
                  .doc(ilanId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'İlan yükleniyor...',
                            style: SafeFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      title: Text('Hata'),
                      backgroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'İlan bulunamadı',
                            style: SafeFonts.poppins(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İlan silinmiş veya mevcut değil olabilir',
                            style: SafeFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                try {
                  final animal = AnimalPost.fromSnap(snapshot.data!);
                  return AnimalDetailScreen(animal: animal);
                } catch (e) {
                  print('❌ İlan parse hatası: $e');
                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      title: Text('Hata'),
                      backgroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'İlan yüklenemedi',
                            style: SafeFonts.poppins(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hata: $e',
                            style: SafeFonts.poppins(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    _filterDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final threshold = max * 0.80; // %80 eşiği
    if (_scrollController.position.pixels >= threshold &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isInitialLoading) {
      _loadMoreAnimals();
    }
  }

  Future<void> _refresh() async {
    // Pagination'ı sıfırla ve baştan yükle
    await _loadInitialAnimals();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (!showFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showFilters = true;
                        });
                      },
                      icon: Icon(Icons.search, color: primaryColor),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hayvan Ara',
                            style: SafeFonts.poppins(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: dividerColor),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
              ),
            if (showFilters)
              SliverToBoxAdapter(child: _buildSearchAndFilters()),
            if (!showFilters)
              SliverToBoxAdapter(child: _buildActiveFiltersSummary()),
            SliverToBoxAdapter(
              child: Container(
                height: isSmallScreen ? 45 : 50,
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 4 : 8,
                    vertical: isSmallScreen ? 4 : 8),
                child: _buildDynamicQuickFilters(),
              ),
            ),
            ..._buildAnimalListSlivers(),
          ],
        ),
      ),
      floatingActionButton: _buildViewToggle(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CanlıPazar',
            style: SafeFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: InkWell(
            onTap: () {
              HomeFilterActionSheet.show(
                context,
                sortOrder: _homeSortOrder,
                selectedCity: selectedCity,
                onSortSelected: (order) {
                  setState(() => _homeSortOrder = order);
                },
                onCitySelected: (city) {
                  _applyCityFilter(city);
                },
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.dehaze, color: primaryColor, size: 26),
            ),
          ),
        ),
      ),
      actions: [
        if (FirebaseAuth.instance.currentUser == null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Giriş Yap',
                  style: SafeFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isAllCityFilterValue(String? city) {
    if (city == null) return true;
    final normalized = city.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'tüm şehirler' || normalized == 'hepsi';
  }

  void _applyCityFilter(String? city) {
    final nextCity = _isAllCityFilterValue(city) ? 'Tüm Şehirler' : city!.trim();
    print('🌆 Şehir filtresi seçildi: $nextCity');
    setState(() {
      selectedCity = nextCity;
      _allAnimals = [];
      _filteredAnimals = [];
      _lastDocument = null;
      _hasMoreData = true;
    });
    if (_scrollController.hasClients) {
      try {
        _scrollController.jumpTo(0);
      } catch (_) {}
    }
    _onFilterChanged(immediate: true);
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: backgroundColor,
      child: isGridView ? _buildGridShimmer() : _buildListShimmer(),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
            6,
            (index) => SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resim placeholder
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        // İçerik placeholder
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık placeholder
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Fiyat placeholder
                              Container(
                                height: 14,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Chip placeholder
                              Row(
                                children: [
                                  Container(
                                    height: 20,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 20,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Resim placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // İçerik placeholder
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık placeholder
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fiyat placeholder
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chip placeholder
                      Row(
                        children: [
                          Container(
                            height: 24,
                            width: 60,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 24,
                            width: 50,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hayvan Ara - Filtrelemenin üstünde akıllı arama (debounce + post-frame ile kasma önlenir)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: RepaintBoundary(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _filterDebounceTimer?.cancel();
                  _filterDebounceTimer = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _applySmartSearchFromQuery(value);
                      });
                    },
                  );
                },
                decoration: InputDecoration(
                labelText: 'Hayvan Ara',
                hintText: 'Örn: Kahramanmaraş inek, erkek dana, dişi düve',
                hintStyle: SafeFonts.poppins(
                  fontSize: 13,
                  color: textSecondary.withOpacity(0.8),
                ),
                labelStyle: SafeFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 22),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: SafeFonts.poppins(fontSize: 15, color: textPrimary),
            ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrele',
                  style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (_filtersModified)
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: Text(
                          'Sıfırla',
                          style: SafeFonts.poppins(
                            color: warningColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => setState(() => showFilters = false),
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Fiyat Hızlı Seçenekleri - Hayvan türüne göre dinamik
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payments_rounded,
                          color: primaryColor, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('Fiyat Aralığı',
                        style: SafeFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getDynamicPriceOptions(),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Yaş Hızlı Seçenekleri - Hayvan türüne göre dinamik
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.calendar_month_rounded,
                          color: Colors.orange, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('Yaş Aralığı',
                        style: SafeFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getDynamicAgeOptions(),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Cins Filtresi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => _showBreedSelectionDialog(),
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                        selectedBreed == 'Tümü'
                            ? Icons
                                .category_rounded // Tüm cinsler için farklı simge
                            : Icons
                                .pets_rounded, // Belirli cins için pets simgesi
                        color: Colors.indigo,
                        size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedBreed == 'Tümü' ? 'Tüm Cinsler' : selectedBreed,
                        style: SafeFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Cinsiyet - Chip seçimi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.pets_rounded,
                          color: Colors.purple, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('Cinsiyet',
                        style: SafeFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: ['Tümü', 'Erkek', 'Dişi'].map((gender) {
                    final isSelected = selectedGender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedGender = gender);
                          _onFilterChanged();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          margin:
                              EdgeInsets.only(right: gender != 'Dişi' ? 8 : 0),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: SafeFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected ? Colors.white : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Şehir ve Sağlık
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCitySelectionDialog(),
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: Colors.red.shade400, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Şehir',
                                    style: SafeFonts.poppins(
                                        fontSize: 10, color: textSecondary)),
                                Text(
                                  selectedCity == 'Tüm Şehirler'
                                      ? 'Tümü'
                                      : selectedCity,
                                  style: SafeFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.health_and_safety_rounded,
                            color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedHealthStatus,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: textSecondary, size: 20),
                              style: SafeFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary),
                              items: [
                                'Tümü',
                                ...AnimalCategories.healthStatuses
                              ]
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedHealthStatus = value!);
                                _onFilterChanged();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Sonuç butonu
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isInitialLoading || _isFiltering)
                    ? null
                    : () {
                        // Veriler zaten _onFilterChanged içinde yüklendiği için
                        // Sadece paneli kapatıyoruz
                        setState(() => showFilters = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                  disabledForegroundColor: Colors.white,
                ),
                child: (_isInitialLoading || _isFiltering)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            _isFiltering ? 'Hesaplanıyor...' : 'Yükleniyor...',
                            style: SafeFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 22),
                          SizedBox(width: 10),
                          Text(
                            _areFiltersModified()
                                ? 'Sonuçları Göster (${filteredResultsCount})'
                                : 'Tüm Hayvanları Göster',
                            style: SafeFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                title,
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: SafeFonts.poppins(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: SafeFonts.poppins(
                      color: textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSelectDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: textSecondary, size: 20),
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 12,
                ),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SafeFonts.poppins(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return GestureDetector(
      onTap: () async {
        _clearConflictingFilters('category', category);

        setState(() {
          selectedCategory = category;
          priceRange = RangeValues(0, 500000);
          ageRange = RangeValues(0, 120);
          _isInitialLoading = true;
          _allAnimals = [];
          _filteredAnimals = [];
          _lastDocument = null;
          _hasMoreData = true;
        });
        await _loadInitialAnimals(singleBatchOnly: true);
        if (!mounted) return;
        _fetchCategoryCount();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6),
        decoration: BoxDecoration(
          color: selectedCategory == category
              ? primaryColor.withOpacity(0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedCategory == category
                ? primaryColor.withOpacity(0.3)
                : dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: SafeFonts.poppins(
            color: selectedCategory == category ? primaryColor : textPrimary,
            fontWeight: selectedCategory == category
                ? FontWeight.w600
                : FontWeight.w500,
            fontSize: isSmallScreen ? 11 : 12, // Biraz büyüttüm
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildMoreCategoriesButton() {
    return GestureDetector(
      onTap: () {
        // Show all categories in a bottom sheet or dialog
        _showAllCategoriesDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              size: isSmallScreen ? 12 : 14,
              color: textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            Text(
              'Daha Fazla',
              style: SafeFonts.poppins(
                color: textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 10 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tüm Kategoriler',
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Categories grid
            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: AnimalCategories.categories.length,
                itemBuilder: (context, index) {
                  final category = AnimalCategories.categories[index];
                  return GestureDetector(
                    onTap: () async {
                      // Önce state'i güncelle ve eski verileri temizle
                      selectedCategory = category;

                      _clearConflictingFilters('category', category);

                      // Fiyat ve yaş aralığını sıfırla (yeni kategori için uygun aralıklar gösterilsin)
                      setState(() {
                        priceRange = RangeValues(0, 500000);
                        ageRange = RangeValues(0, 120);
                      });

                      Navigator.pop(context);

                      // Trigger filter update after dialog closes
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        setState(() {
                          _isInitialLoading = true;
                          _allAnimals = [];
                          _filteredAnimals = [];
                          _lastDocument = null;
                          _hasMoreData = true;
                        });
                        await _loadInitialAnimals(singleBatchOnly: true);
                        _fetchCategoryCount();
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedCategory == category
                            ? primaryColor.withOpacity(0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedCategory == category
                              ? primaryColor.withOpacity(0.3)
                              : dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AnimalCategories.getCategoryIcon(category),
                            size: 16,
                            color: selectedCategory == category
                                ? primaryColor
                                : textSecondary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: SafeFonts.poppins(
                                color: selectedCategory == category
                                    ? primaryColor
                                    : textPrimary,
                                fontWeight: selectedCategory == category
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCitySelectionDialog() {
    String citySearchQuery = '';
    List<String> filteredCities = List.from(turkishCities);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filter cities based on search query
          if (citySearchQuery.isNotEmpty) {
            filteredCities = turkishCities
                .where((city) =>
                    city.toLowerCase().contains(citySearchQuery.toLowerCase()))
                .toList();
          } else {
            filteredCities = List.from(turkishCities);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Şehir Seçin',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          selectedCity = 'Tüm Şehirler';
                          Navigator.pop(context);
                          // Trigger filter update after dialog closes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _onFilterChanged();
                          });
                        },
                        child: Text(
                          'Tümü',
                          style: SafeFonts.poppins(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dividerColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        hintStyle: SafeFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: primaryColor, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          citySearchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Cities list
                Expanded(
                  child: filteredCities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                color: textSecondary,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Şehir bulunamadı',
                                style: SafeFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '"$citySearchQuery" için sonuç yok',
                                style: SafeFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];
                            return ListTile(
                              title: Text(
                                city,
                                style: SafeFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: selectedCity == city
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              leading: selectedCity == city
                                  ? Icon(Icons.check_circle,
                                      color: primaryColor, size: 20)
                                  : Icon(Icons.location_city,
                                      color: textSecondary, size: 20),
                              onTap: () {
                                _applyCityFilter(city);
                                Navigator.pop(context);
                              },
                              tileColor: selectedCity == city
                                  ? primaryColor.withOpacity(0.1)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Cins seçim diyaloğu - kategorilere göre gruplandırılmış
  void _showBreedSelectionDialog() {
    String breedSearchQuery = '';

    // AnimalCategories'den tüm cinsleri kategorilere göre al
    final Map<String, List<String>> breedsByCategory = {
      'Büyükbaş': AnimalCategories.getBreedsForType('büyükbaş'),
      'Küçükbaş': AnimalCategories.getBreedsForType('küçükbaş'),
      'Kanatlı': AnimalCategories.getBreedsForType('kanatlı'),
    };

    // Toplam cins sayısı
    final totalBreeds =
        breedsByCategory.values.fold<int>(0, (sum, list) => sum + list.length);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Arama sonuçlarını filtrele
          Map<String, List<String>> filteredBreeds = {};
          if (breedSearchQuery.isNotEmpty) {
            breedsByCategory.forEach((category, breeds) {
              final filtered = breeds
                  .where((breed) => breed
                      .toLowerCase()
                      .contains(breedSearchQuery.toLowerCase()))
                  .toList();
              if (filtered.isNotEmpty) {
                filteredBreeds[category] = filtered;
              }
            });
          } else {
            filteredBreeds = Map.from(breedsByCategory);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cins Seçin',
                        style: SafeFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          selectedBreed = 'Tümü';
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _onFilterChanged();
                          });
                        },
                        child: Text(
                          'Temizle',
                          style: SafeFonts.poppins(
                            color: warningColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (value) {
                      setDialogState(() {
                        breedSearchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cins ara...',
                      hintStyle: SafeFonts.poppins(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: textSecondary),
                      filled: true,
                      fillColor: surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Tüm Cinsler seçeneği
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    onTap: () {
                      selectedBreed = 'Tümü';
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onFilterChanged();
                      });
                    },
                    tileColor: selectedBreed == 'Tümü'
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      selectedBreed == 'Tümü'
                          ? Icons.check_circle
                          : Icons.all_inclusive,
                      color: selectedBreed == 'Tümü'
                          ? primaryColor
                          : textSecondary,
                      size: 24,
                    ),
                    title: Text(
                      'Tüm Cinsler',
                      style: SafeFonts.poppins(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: selectedBreed == 'Tümü'
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalBreeds cins',
                        style: SafeFonts.poppins(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Kategorilere göre cins listesi
                Expanded(
                  child: filteredBreeds.isEmpty
                      ? Center(
                          child: Text(
                            'Cins bulunamadı',
                            style: SafeFonts.poppins(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Büyükbaş
                            if (filteredBreeds['Büyükbaş']?.isNotEmpty ?? false)
                              _buildBreedCategory(
                                'Büyükbaş',
                                '🐄',
                                Colors.brown,
                                filteredBreeds['Büyükbaş']!,
                              ),

                            // Küçükbaş
                            if (filteredBreeds['Küçükbaş']?.isNotEmpty ?? false)
                              _buildBreedCategory(
                                'Küçükbaş',
                                '🐑',
                                Colors.green,
                                filteredBreeds['Küçükbaş']!,
                              ),

                            // Kanatlı
                            if (filteredBreeds['Kanatlı']?.isNotEmpty ?? false)
                              _buildBreedCategory(
                                'Kanatlı',
                                '🐔',
                                Colors.orange,
                                filteredBreeds['Kanatlı']!,
                              ),

                            SizedBox(height: 16),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Kategori başlığı ve cinsleri oluştur
  Widget _buildBreedCategory(
    String categoryName,
    String emoji,
    Color color,
    List<String> breeds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori başlığı
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                categoryName,
                style: SafeFonts.poppins(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${breeds.length}',
                  style: SafeFonts.poppins(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Cins chip'leri
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: breeds.map((breed) {
            final isSelected = selectedBreed == breed;

            return GestureDetector(
              onTap: () {
                selectedBreed = breed;
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onFilterChanged();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    Text(
                      breed,
                      style: SafeFonts.poppins(
                        color: isSelected ? Colors.white : textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Hızlı filtre seçimi (Ana Kategori)
  // Hızlı filtre seçimi (Ana Kategori)
  Future<void> _selectQuickFilter(String type) async {
    // Hızlı filtre değişiminde eski arama sonuçlarını temizle + en üste dön
    searchQuery = '';
    _searchKeywords = [];
    _searchController.clear();

    if (_scrollController.hasClients) {
      try {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    }

    selectedPurpose = 'Tümü';
    selectedAnimalType = type;
    _clearConflictingFilters('animalType', type);
    _categoryCache.clear();

    final key = _categoryCacheKey();
    final cached = _categoryCache[key];

    if (cached != null && cached.list.isNotEmpty) {
      setState(() {
        _allAnimals = List<AnimalPost>.from(cached.list);
        _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
        _lastDocument = cached.lastDoc;
        _hasMoreData = cached.hasMore;
        _isInitialLoading = false;
        _isLoadingMore = false;
        if (_filteredAnimals.isNotEmpty) {
          filteredResultsCount = _filteredAnimals.length;
        }
      });
      _fetchCategoryCount();
      _refreshCategoryCacheInBackground();
      return;
    }

    setState(() {
      _isInitialLoading = true;
      _allAnimals = [];
      _filteredAnimals = [];
      _lastDocument = null;
      _hasMoreData = true;
    });
    await _loadInitialAnimals(singleBatchOnly: true);
    _fetchCategoryCount();
  }

  // Alt filtre seçimi (Kullanım Amacı)
  void _selectSubFilter(String purpose) {
    String newValue = selectedPurpose == purpose ? 'Tümü' : purpose;
    setState(() {
      selectedPurpose = newValue;
    });
    // Alt filtre değiştiğinde de pagination ile yükle
    _loadInitialAnimals();
    _fetchCategoryCount();
  }

  Widget _buildDynamicQuickFilters() {
    List<Widget> filters = [];

    // Şehir filtresi (Her zaman en başta göster, seçiliyse)
    if (selectedCity != 'Tüm Şehirler') {
      filters.add(_buildQuickFilterChip(selectedCity, true, () {
        setState(() => selectedCity = 'Tüm Şehirler');
        _onFilterChanged();
      }));
      filters.add(SizedBox(width: 8));
      filters.add(Container(height: 20, width: 1, color: dividerColor));
      filters.add(SizedBox(width: 8));
    }

    // Ana kategori seçili değilse
    if (selectedAnimalType == 'Tümü') {
      // 0. Tüm Hayvanlar (En Başta)
      filters.add(_buildCategoryChip('Tüm Hayvanlar'));
      filters.add(SizedBox(width: 8));

      // 1. Ana Türler
      filters.add(_buildQuickFilterChip(
          'Büyükbaş', false, () => _selectQuickFilter('Büyükbaş')));
      filters.add(SizedBox(width: 8));
      filters.add(_buildQuickFilterChip(
          'Küçükbaş', false, () => _selectQuickFilter('Küçükbaş')));
      filters.add(SizedBox(width: 8));
      filters.add(_buildQuickFilterChip(
          'Kanatlı', false, () => _selectQuickFilter('Kanatlı')));
      filters.add(SizedBox(width: 8));

      // 2. Acil Satış
      filters.add(_buildQuickFilterChip('Acil Satış', showUrgentOnly, () {
        setState(() {
          showUrgentOnly = !showUrgentOnly;
          _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
          filteredResultsCount = _filteredAnimals.length;
        });
        _fetchCategoryCount();
      }));
      filters.add(SizedBox(width: 8));

      // 3. Popüler Kategoriler
      int maxCats = 5;
      for (var category in AnimalCategories.categories.skip(1).take(maxCats)) {
        filters.add(_buildCategoryChip(category));
        filters.add(SizedBox(width: 8));
      }

      // 4. Daha Fazla Butonu
      filters.add(_buildMoreCategoriesButton());
    } else {
      // Bir kategori seçili (Örn: Büyükbaş) -> Detay Modu

      // Geri Dön Butonu
      filters.add(
        InkWell(
          onTap: () => _selectQuickFilter('Tümü'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: dividerColor),
            ),
            child: Icon(Icons.arrow_back, size: 20, color: textPrimary),
          ),
        ),
      );
      filters.add(SizedBox(width: 8));

      // Seçili Kategori (Vurgulu)
      filters.add(_buildQuickFilterChip(
          selectedAnimalType, true, () => _selectQuickFilter('Tümü')));
      filters.add(SizedBox(width: 8));

      // Dikey çizgi
      filters.add(Container(
        height: 24,
        width: 1,
        color: dividerColor,
        margin: EdgeInsets.symmetric(horizontal: 4),
      ));
      filters.add(SizedBox(width: 8));

      // Acil Satış (Her zaman burada olsun)
      filters.add(_buildQuickFilterChip('Acil', showUrgentOnly, () {
        setState(() {
          showUrgentOnly = !showUrgentOnly;
          _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
          filteredResultsCount = _filteredAnimals.length;
        });
        _fetchCategoryCount();
      }));
      filters.add(SizedBox(width: 8));

      // Alt Kategoriler (Purpose) - Firebase kayıtlarına göre güncellendi
      List<String> subCategories = [];
      if (selectedAnimalType == 'Büyükbaş') {
        subCategories = ['Süt', 'Et', 'Damızlık', 'Kurbanlık'];
      } else if (selectedAnimalType == 'Küçükbaş') {
        subCategories = ['Damızlık', 'Kurbanlık', 'Adaklık', 'Süt'];
      } else if (selectedAnimalType == 'Kanatlı') {
        // Kanatlı için DB'de 'Yumurta' yoksa 'Süt' (temsili) veya 'Et' olabilir.
        // Şimdilik UI'da kullanıcı alışkanlığı için böyle bırakıyorum veya 'Et' olarak güncelliyorum.
        subCategories = ['Yumurtalık', 'Et', 'Süs'];
      }

      for (var sub in subCategories) {
        filters.add(_buildQuickFilterChip(
            sub, selectedPurpose == sub, () => _selectSubFilter(sub)));
        filters.add(SizedBox(width: 8));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: filters,
      ),
    );
  }

  Widget _buildQuickFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryColor, Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: SafeFonts.poppins(
            color: isSelected ? Colors.white : textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Unused legacy filter panel (kept for reference). Consider removal if not needed.
  Widget _buildFilterPanel() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gelişmiş Filtreler',
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Temizle',
                  style: SafeFonts.poppins(
                    color: warningColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Fiyat aralığı
          Text(
            'Fiyat Aralığı',
            style: SafeFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${PricingService.formatPriceRange(priceRange.start, priceRange.end)}',
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: dividerColor,
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: priceRange,
              min: 0,
              max: 500000,
              divisions: 50,
              labels: RangeLabels(
                PricingService.formatPrice(priceRange.start),
                PricingService.formatPrice(priceRange.end),
              ),
              onChanged: (values) {
                setState(() => priceRange = values);
              },
              onChangeEnd: (values) {
                _onFilterChanged();
              },
            ),
          ),

          SizedBox(height: 16),

          // Yaş aralığı
          Text(
            'Yaş Aralığı',
            style: SafeFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${ageRange.start.round()}-${ageRange.end.round()} ay',
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: dividerColor,
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: ageRange,
              min: 0,
              max: 120,
              divisions: 20,
              labels: RangeLabels(
                '${ageRange.start.round()} ay',
                '${ageRange.end.round()} ay',
              ),
              onChanged: (values) {
                setState(() => ageRange = values);
              },
              onChangeEnd: (values) {
                _onFilterChanged();
              },
            ),
          ),

          SizedBox(height: 16),

          // Cinsiyet ve sağlık durumu
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cinsiyet',
                    labelStyle: SafeFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Tümü', 'Erkek', 'Dişi']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(
                              gender,
                              style: SafeFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                    _onFilterChanged();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedHealthStatus,
                  style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sağlık Durumu',
                    labelStyle: SafeFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Tümü', ...AnimalCategories.healthStatuses]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: SafeFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedHealthStatus = value!;
                    });
                    _onFilterChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Unused legacy category tabs (kept for reference). Consider removal if not needed.
  Widget _buildCategoryTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Kategoriler',
                style: SafeFonts.poppins(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AnimalCategories.categories.length,
              itemBuilder: (context, index) {
                final category = AnimalCategories.categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        // Fiyat ve yaş aralığını sıfırla (yeni kategori için uygun aralıklar gösterilsin)
                        priceRange = RangeValues(0, 500000);
                        ageRange = RangeValues(0, 120);
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withOpacity(0.3)
                              : dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AnimalCategories.getCategoryIcon(category),
                            size: 16,
                            color: isSelected ? primaryColor : textSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            category,
                            style: SafeFonts.poppins(
                              color: isSelected ? primaryColor : textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lazy-load: SliverGrid / SliverList ile sadece görünen kartlar oluşturulur.
  List<Widget> _buildAnimalListSlivers() {
    if (_isInitialLoading) {
      return [SliverToBoxAdapter(child: _buildShimmerLoading())];
    }

    if (_filteredAnimals.isEmpty) {
      final bool hasCategoryFilter =
          selectedAnimalType != 'Tümü' || selectedCategory != 'Tüm Hayvanlar';
      final String emptyTitle = hasCategoryFilter
          ? 'Bu kategoride henüz ilan bulunmamaktadır'
          : 'Kriterlere uygun ilan bulunamadı';
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🐄', style: TextStyle(fontSize: 48)),
                      SizedBox(width: 16),
                      Text('🐑', style: TextStyle(fontSize: 48)),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    emptyTitle,
                    style: SafeFonts.poppins(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Filtreleri değiştirmeyi deneyin',
                    style: SafeFonts.poppins(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _clearAllFilters,
                    icon: Icon(Icons.clear_all, size: 20),
                    label: Text(
                      'Tüm Filtreleri Temizle',
                      style: SafeFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final animals = _sortedFilteredAnimals;
    final double screenW = MediaQuery.of(context).size.width;
    final List<Widget> out = <Widget>[];

    if (isGridView) {
      const double padH = 16.0;
      const double spacing = 8.0;
      const double cardH = 252.0;
      final double cellW = (screenW - padH * 2 - spacing) / 2;
      final double aspect = cellW / cardH;

      out.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final animal = animals[index];
                return RepaintBoundary(
                  child: AnimalCard(
                    key: ValueKey<String>('grid_${animal.postId}'),
                    animal: animal,
                    isGridView: true,
                    onTap: () => _navigateToAnimalDetail(animal),
                    onFavorite: () => _toggleFavorite(animal),
                  ),
                );
              },
              childCount: animals.length,
              addAutomaticKeepAlives: true,
            ),
          ),
        ),
      );
    } else {
      out.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final animal = animals[index];
              return RepaintBoundary(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: AnimalCard(
                    key: ValueKey<String>('list_${animal.postId}'),
                    animal: animal,
                    isGridView: false,
                    onTap: () => _navigateToAnimalDetail(animal),
                    onFavorite: () => _toggleFavorite(animal),
                  ),
                ),
              );
            },
            childCount: animals.length,
            addAutomaticKeepAlives: true,
          ),
        ),
      );
    }

    if (_isLoadingMore) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          ),
        ),
      );
    } else if (!_hasMoreData && _filteredAnimals.isNotEmpty) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Tüm ilanlar gösterildi',
                style: SafeFonts.poppins(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return out;
  }

  // Toplam hayvan sayısını Firebase'den al
  Future<void> _fetchTotalCount() async {
    if (_isFetchingTotalCount) return;

    setState(() {
      _isFetchingTotalCount = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _totalAnimalsCount = snapshot.count ?? 0;
          _isFetchingTotalCount = false;
        });
        print('📊 Toplam hayvan sayısı: $_totalAnimalsCount');
      }
    } catch (e) {
      print('❌ Toplam sayı alınamadı: $e');
      // Fallback: isActive filtresi olmadan dene
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('animals')
            .count()
            .get();

        if (mounted) {
          setState(() {
            _totalAnimalsCount = snapshot.count ?? 0;
            _isFetchingTotalCount = false;
          });
          print('📊 Toplam hayvan sayısı (fallback): $_totalAnimalsCount');
        }
      } catch (e2) {
        print('❌ Toplam sayı alınamadı (fallback): $e2');
        if (mounted) {
          setState(() {
            _isFetchingTotalCount = false;
          });
        }
      }
    }
  }

  // Kategori filtresine göre hayvan sayısını hesapla
  Future<void> _fetchCategoryCount() async {
    if (!mounted) return;

    // Sadece filtreler değiştiyse loading göster (yanıp sönmeyi önlemek için)
    if (_areFiltersModified()) {
      setState(() {
        _isFiltering = true;
      });
    }

    try {
      // Sorgu oluştur - _buildAnimalQuery'ye benzer ama count için
      Query query = FirebaseFirestore.instance.collection('animals');

      // Fiyat ve Yaş Filtreleri (Firestore'da sadece 1 adet Range filtresi kullanılabilir)
      // Bu yüzden önceliği Fiyata veriyoruz, eğer fiyat varsayılan ise Yaşa bakıyoruz.

      bool priceFiltered = priceRange.start > 0 || priceRange.end < 500000;
      bool ageFiltered = ageRange.start > 0 || ageRange.end < 120;

      // Index Hatası Önlemi:
      // Normalde Range filtresi + Equality filtresi composite index gerektirir.
      // Ancak "isActive" filtresi kritik olduğu için eklemeliyiz.
      // EĞER index hatası verirse, catch bloğu devreye girip local sayıyı gösterecektir.
      // Bu, yanlış (inactive dahil) sayı göstermekten daha iyidir.
      query = query.where('isActive', isEqualTo: true);

      /* Range filtresi kontrolü (isActive yukarıda her zaman eklendi)
      if (priceFiltered || ageFiltered) {
         // ...
      } else {
         // ...
      }
      */

      // Kategori filtrelemesi - Veritabanında 'category' alanı yok, bu yüzden 'animalSpecies' üzerinden filtreliyoruz
      if (selectedCategory != 'Tüm Hayvanlar') {
        // Kategoriden tür çıkarımı yap
        String? speciesToFilter;

        if (selectedCategory.contains('Sığır') ||
            selectedCategory == 'Düve' ||
            selectedCategory == 'Tosun' ||
            selectedCategory == 'Damızlık Boğa' ||
            selectedCategory == 'Dana') {
          speciesToFilter = 'sığır';
        } else if (selectedCategory.contains('Koyun') ||
            selectedCategory == 'Koç' ||
            selectedCategory == 'Kuzu') {
          speciesToFilter = 'koyun';
        } else if (selectedCategory.contains('Keçi') ||
            selectedCategory == 'Oğlak' ||
            selectedCategory == 'Teke') {
          speciesToFilter = 'keçi';
        } else if (selectedCategory == 'Manda') {
          speciesToFilter = 'manda';
        } else if (selectedCategory == 'Kanatlı') {
          final kv = animalTypeWhereInVariants('Kanatlı');
          if (kv.length == 1) {
            query = query.where('animalType', isEqualTo: kv.first);
          } else if (kv.isNotEmpty) {
            query = query.where('animalType', whereIn: kv);
          }
        }

        if (speciesToFilter != null) {
          query = query.where('animalSpecies', isEqualTo: speciesToFilter);
        }

        // Not: "Gebe Hayvanlar" vb. gibi durum filtreleri için kesin count alamıyoruz
        // çünkü isPregnant alanı boolean ve sorgulanabilir ama complex query kısıtlamaları olabilir.
        if (selectedCategory == 'Gebe Hayvanlar') {
          query = query.where('isPregnant', isEqualTo: true);
        } else if (selectedCategory == 'Acil Satış') {
          query = query.where('isUrgentSale', isEqualTo: true);
        }
      }

      // Tür filtrelemesi (Firestore'da büyük/küçük harf tutarsızlığına karşı whereIn)
      if (selectedAnimalType != 'Tümü') {
        final v = animalTypeWhereInVariants(selectedAnimalType);
        if (v.length == 1) {
          query = query.where('animalType', isEqualTo: v.first);
        } else if (v.isNotEmpty) {
          query = query.where('animalType', whereIn: v);
        }
      }

      // Şehir filtrelemesi
      if (!_isAllCityFilterValue(selectedCity)) {
        final cityVariants = cityWhereInVariants(selectedCity);
        if (cityVariants.length == 1) {
          query = query.where('city', isEqualTo: cityVariants.first);
        } else if (cityVariants.isNotEmpty) {
          query = query.where('city', whereIn: cityVariants);
        }
      }

      // Cins filtrelemesi (Alan adı: animalBreed)
      if (selectedBreed != 'Tümü') {
        query = query.where('animalBreed', isEqualTo: selectedBreed);
      }

      // Cinsiyet filtrelemesi
      if (selectedGender != 'Tümü') {
        query = query.where('gender', isEqualTo: selectedGender);
      }

      // Sağlık durumu filtrelemesi
      if (selectedHealthStatus != 'Tümü') {
        query = query.where('healthStatus', isEqualTo: selectedHealthStatus);
      }

      // Kullanım amacı filtrelemesi
      if (selectedPurpose != 'Tümü') {
        query = query.where('purpose', isEqualTo: selectedPurpose);
      }

      // Acil satış filtrelemesi (Alan adı: isUrgentSale)
      if (showUrgentOnly) {
        query = query.where('isUrgentSale', isEqualTo: true);
      }

      // Fiyat Filtresi
      if (priceFiltered) {
        // Değerleri yuvarla (Int gibi davran)
        double startPrice = priceRange.start.roundToDouble();
        double endPrice = priceRange.end.roundToDouble();

        query = query.where('priceInTL', isGreaterThanOrEqualTo: startPrice);
        // Max değer 500.000 ise ve 500k+ seçildiyse üst limit koyma
        if (priceRange.end < 500000) {
          query = query.where('priceInTL', isLessThanOrEqualTo: endPrice);
        }
      }
      // Yaş Filtresi (Sadece fiyat filtrelenmemişse uygulanabilir)
      else if (ageFiltered) {
        // Değerleri yuvarla
        double startAge = ageRange.start.roundToDouble();
        double endAge = ageRange.end.roundToDouble();

        query = query.where('ageInMonths', isGreaterThanOrEqualTo: startAge);
        // Max değer 120 ise ve 120+ seçildiyse üst limit koyma
        if (ageRange.end < 120) {
          query = query.where('ageInMonths', isLessThanOrEqualTo: endAge);
        }
      }

      // Count sorgusunu çalıştır
      final countSnapshot = await query.count().get();

      if (mounted) {
        setState(() {
          int serverCount = countSnapshot.count ?? 0;

          if (!_hasMoreData) {
            // Eğer tüm verileri yüklediysek, kesin sayı local veridir
            filteredResultsCount = _filteredAnimals.length;
          } else {
            // Hala yüklenecek veri varsa, server sayısını kullan ama localden az olmasın
            if (serverCount < _filteredAnimals.length) {
              filteredResultsCount = _filteredAnimals.length;
            } else {
              filteredResultsCount = serverCount;
            }
          }

          _isFiltering = false;
        });
        print('📊 Filtre sonuç sayısı: $filteredResultsCount');
      }
    } catch (e) {
      print('❌ Filtre sayısı alınamadı: $e');
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.contains('https://console.firebase.google.com')) {
        print('⚠️ Firestore index eksik olabilir. Oluşturma linki: ${e.message}');
      }
      // Hata durumunda mevcut yüklenmiş hayvanları say
      if (mounted) {
        setState(() {
          filteredResultsCount = _filteredAnimals.length;
          _isFiltering = false;
        });
      }
    }
  }

  Future<QuerySnapshot> _buildAnimalQuery(
      {DocumentSnapshot? startAfter, int? limitOverride}) async {
    final int effectiveLimit = limitOverride ?? _limit;
    try {
      Query query = FirebaseFirestore.instance.collection('animals');

      query = query.where('isActive', isEqualTo: true);

      if (!_isAllCityFilterValue(selectedCity)) {
        final cityVariants = cityWhereInVariants(selectedCity);
        if (cityVariants.length == 1) {
          query = query.where('city', isEqualTo: cityVariants.first);
        } else if (cityVariants.isNotEmpty) {
          query = query.where('city', whereIn: cityVariants);
        }
      }

      if (selectedAnimalSpecies != 'Tümü' &&
          selectedAnimalSpecies.isNotEmpty) {
        query = query.where('animalSpecies', isEqualTo: selectedAnimalSpecies);
      }

      if (selectedAnimalType != 'Tümü' &&
          selectedAnimalType != 'Tüm Hayvanlar') {
        final v = animalTypeWhereInVariants(selectedAnimalType);
        if (v.length == 1) {
          query = query.where('animalType', isEqualTo: v.first);
        } else if (v.isNotEmpty) {
          query = query.where('animalType', whereIn: v);
        }
      }

      if (showUrgentOnly) {
        query = query.where('isUrgentSale', isEqualTo: true);
      }

      query = query.orderBy('datePublished', descending: true);
      query = query.limit(effectiveLimit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return await query.get();
    } catch (e) {
      print('⚠️ İdeal sorgu başarısız (Muhtemelen index eksik): $e');
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.contains('https://console.firebase.google.com')) {
        print('⚠️ Firestore index linki: ${e.message}');
      }
      try {
        // Fallback: city filtresini koru; böylece Antalya seçince yanlış şehirlerden
        // ilk sayfada hiç sonuç dönmesin.
        Query fallback = FirebaseFirestore.instance
            .collection('animals')
            .where('isActive', isEqualTo: true);

        if (!_isAllCityFilterValue(selectedCity)) {
          final cityVariants = cityWhereInVariants(selectedCity);
          if (cityVariants.length == 1) {
            fallback = fallback.where('city', isEqualTo: cityVariants.first);
          } else if (cityVariants.isNotEmpty) {
            fallback = fallback.where('city', whereIn: cityVariants);
          }
        }

        fallback = fallback.orderBy('datePublished', descending: true);
        fallback = fallback.limit(effectiveLimit);

        if (startAfter != null) {
          fallback = fallback.startAfterDocument(startAfter);
        }
        return await fallback.get();
      } catch (_) {
        Query query = FirebaseFirestore.instance
            .collection('animals')
            .orderBy('datePublished', descending: true)
            .limit(effectiveLimit);

        if (startAfter != null) {
          query = query.startAfterDocument(startAfter);
        }
        return await query.get();
      }
    }
  }

  String _categoryCacheKey() {
    return '${selectedAnimalType}_${selectedCity}_$showUrgentOnly';
  }

  /// Pre-fetch ve arka plan yenileme için: state değiştirmeden verilen parametrelerle tek batch çeker.
  Future<_CategoryCacheEntry> _fetchCategoryBatchForCache(
    String animalType, {
    String city = 'Tüm Şehirler',
    bool showUrgent = false,
  }) async {
    try {
      final typeVariants = animalTypeWhereInVariants(animalType);
      Query query = FirebaseFirestore.instance
          .collection('animals')
          .where('isActive', isEqualTo: true);
      if (typeVariants.length == 1) {
        query = query.where('animalType', isEqualTo: typeVariants.first);
      } else if (typeVariants.isNotEmpty) {
        query = query.where('animalType', whereIn: typeVariants);
      }
      if (!_isAllCityFilterValue(city)) {
        final cityVariants = cityWhereInVariants(city);
        if (cityVariants.length == 1) {
          query = query.where('city', isEqualTo: cityVariants.first);
        } else if (cityVariants.isNotEmpty) {
          query = query.where('city', whereIn: cityVariants);
        }
      }
      if (showUrgent) {
        query = query.where('isUrgentSale', isEqualTo: true);
      }
      query = query.orderBy('datePublished', descending: true).limit(_initialCategoryBatchSize);
      final snapshot = await query.get();
      List<AnimalPost> list = [];
      for (var doc in snapshot.docs) {
        try {
          list.add(AnimalPost.fromSnap(doc));
        } catch (_) {}
      }
      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      bool hasMore = snapshot.docs.length >= _initialCategoryBatchSize;
      return _CategoryCacheEntry(list, lastDoc, hasMore);
    } catch (e) {
      return _CategoryCacheEntry([], null, false);
    }
  }

  void _prefetchPopularCategories() async {
    if (_prefetchDone || !mounted) return;
    _prefetchDone = true;
    for (final type in _popularTypesForPrefetch) {
      if (!mounted) return;
      final entry = await _fetchCategoryBatchForCache(type);
      if (!mounted) return;
      _categoryCache['${type}_Tüm Şehirler_false'] = entry;
    }
  }

  void _refreshCategoryCacheInBackground() {
    final key = _categoryCacheKey();
    _fetchCategoryBatchForCache(
      selectedAnimalType,
      city: selectedCity,
      showUrgent: showUrgentOnly,
    ).then((entry) {
      if (mounted) {
        _categoryCache[key] = entry;
      }
    });
  }

  Future<void> _loadInitialAnimals({bool singleBatchOnly = false}) async {
    if (_isLoadingMore || !mounted) return;

    final int currentOpId = ++_loadingOperationId;
    final int batchLimit = singleBatchOnly ? _initialCategoryBatchSize : _limit;

    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = true;
      _allAnimals = [];
      _filteredAnimals = [];
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      final snapshot = await _buildAnimalQuery(
        startAfter: _lastDocument,
        limitOverride: singleBatchOnly ? _initialCategoryBatchSize : null,
      );

      if (currentOpId != _loadingOperationId || !mounted) return;

      if (!_isAllCityFilterValue(selectedCity)) {
        print('🌆 [Ham veri] city=$selectedCity rawDocs=${snapshot.docs.length}');
      }

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
      } else {
        _lastDocument = snapshot.docs.last;

        List<AnimalPost> batchAnimals = [];
        for (var doc in snapshot.docs) {
          try {
            final animal = AnimalPost.fromSnap(doc);
            batchAnimals.add(animal);
          } catch (e) {
            print('Error parsing animal: $e');
          }
        }

        _allAnimals.addAll(batchAnimals);
        if (snapshot.docs.length < batchLimit) {
          _hasMoreData = false;
        }
      }

      if (currentOpId != _loadingOperationId || !mounted) return;

      setState(() {
        _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
        if (!_isAllCityFilterValue(selectedCity)) {
          print('🌆 [Ekranda görünen] city=$selectedCity filtered=${_filteredAnimals.length}');
        }
        if (!_hasMoreData) {
          filteredResultsCount = _filteredAnimals.length;
        } else if (filteredResultsCount < _filteredAnimals.length) {
          filteredResultsCount = _filteredAnimals.length;
        }
        _isInitialLoading = false;
        _isLoadingMore = false;
      });

      if (singleBatchOnly && mounted && currentOpId == _loadingOperationId) {
        _categoryCache[_categoryCacheKey()] = _CategoryCacheEntry(
          List<AnimalPost>.from(_allAnimals),
          _lastDocument,
          _hasMoreData,
        );
      }

      if (mounted && currentOpId == _loadingOperationId && _filteredAnimals.isEmpty && _searchKeywords.isNotEmpty && !singleBatchOnly) {
        await _loadFallbackSearch();
      }
    } catch (e) {
      print("Error loading initial animals: $e");
      if (mounted && currentOpId == _loadingOperationId) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Tam eşleşme bulunamadığında: sadece şehir (veya filtre yok) ile çekip kelimeleri tek tek arayan geniş sonuç.
  Future<void> _loadFallbackSearch() async {
    if (!mounted || _searchKeywords.isEmpty) return;
    try {
      Query query = FirebaseFirestore.instance.collection('animals').where('isActive', isEqualTo: true);
      if (!_isAllCityFilterValue(selectedCity)) {
        final cityVariants = cityWhereInVariants(selectedCity);
        if (cityVariants.length == 1) {
          query = query.where('city', isEqualTo: cityVariants.first);
        } else if (cityVariants.isNotEmpty) {
          query = query.where('city', whereIn: cityVariants);
        }
      }
      query = query.orderBy('datePublished', descending: true).limit(100);
      final snapshot = await query.get();
      if (!mounted) return;
      List<AnimalPost> list = [];
      for (var doc in snapshot.docs) {
        try {
          list.add(AnimalPost.fromSnap(doc));
        } catch (_) {}
      }
      // Her kelime en az bir alanda geçmeli (büyük/küçük harf duyarsız)
      final filtered = list.where((animal) {
        for (final kw in _searchKeywords) {
          if (kw.isEmpty) continue;
          final k = kw.toLowerCase();
          final ok = animal.description.toLowerCase().contains(k) ||
              animal.animalSpecies.toLowerCase().contains(k) ||
              animal.animalBreed.toLowerCase().contains(k);
          if (!ok) return false;
        }
        return true;
      }).toList();
      if (!mounted) return;
      setState(() {
        _allAnimals = filtered;
        _filteredAnimals = filtered;
        filteredResultsCount = filtered.length;
        _hasMoreData = false;
        _lastDocument = null;
      });
    } catch (e) {
      print('Fallback arama hatası: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadMoreAnimals() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null || !mounted)
      return;

    // İşlem başladığı andaki ID'yi sakla
    final int startingOpId = _loadingOperationId;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _buildAnimalQuery(startAfter: _lastDocument);

      // İptal kontrolü (async sonrası)
      if (startingOpId != _loadingOperationId || !mounted) return;

      if (!_isAllCityFilterValue(selectedCity)) {
        print('🌆 [Ham veri] (loadMore) city=$selectedCity rawDocs=${snapshot.docs.length}');
      }

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
      } else {
        _lastDocument = snapshot.docs.last;

        List<AnimalPost> batchAnimals = [];
        for (var doc in snapshot.docs) {
          try {
            final animal = AnimalPost.fromSnap(doc);
            // Duplicate kontrolü
            if (!_allAnimals.any((a) => a.postId == animal.postId)) {
              batchAnimals.add(animal);
            }
          } catch (e) {
            // ignore error
          }
        }

        _allAnimals.addAll(batchAnimals);

        if (snapshot.docs.length < _limit) {
          _hasMoreData = false;
        }
      }

      if (startingOpId != _loadingOperationId || !mounted) return;

      setState(() {
        _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
        if (!_isAllCityFilterValue(selectedCity)) {
          print('🌆 [Ekranda görünen] (loadMore) city=$selectedCity filtered=${_filteredAnimals.length}');
        }

        if (!_hasMoreData) {
          filteredResultsCount = _filteredAnimals.length;
        } else if (filteredResultsCount < _filteredAnimals.length) {
          filteredResultsCount = _filteredAnimals.length;
        }

        _isLoadingMore = false;
      });
    } catch (e) {
      print("Error loading more animals: $e");
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.contains('https://console.firebase.google.com')) {
        print('⚠️ Firestore index gerekli olabilir. Oluşturma linki: ${e.message}');
      }
      if (mounted && startingOpId == _loadingOperationId) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // Performans için optimize edilmiş filtre (print yok)
  bool _filterAnimals(AnimalPost animal) {
    // isActive kontrolü
    if (animal.isActive == false) return false;

    // Kategori filtresi
    if (selectedCategory != 'Tüm Hayvanlar') {
      if (!_matchesCategory(animal, selectedCategory)) return false;
    }

    // Arama filtresi: Akıllı arama kelimeleri (büyük/küçük harf duyarsız)
    if (_searchKeywords.isNotEmpty) {
      for (final kw in _searchKeywords) {
        if (kw.length < 1) continue;
        final k = kw.toLowerCase();
        final descMatch = animal.description.toLowerCase().contains(k);
        final speciesMatch = animal.animalSpecies.toLowerCase().contains(k);
        final breedMatch = animal.animalBreed.toLowerCase().contains(k);
        if (!descMatch && !speciesMatch && !breedMatch) return false;
      }
    }
    // Eski tek metin araması (searchQuery dolu ama _searchKeywords boşsa)
    if (searchQuery.isNotEmpty && _searchKeywords.isEmpty) {
      final searchLower = searchQuery.toLowerCase();
      if (!animal.animalSpecies.toLowerCase().contains(searchLower) &&
          !animal.animalBreed.toLowerCase().contains(searchLower) &&
          !animal.description.toLowerCase().contains(searchLower)) {
        return false;
      }
    }

    // Tür (species) filtresi: Firestore ile aynı mantık
    if (selectedAnimalSpecies != 'Tümü' && selectedAnimalSpecies.isNotEmpty) {
      if (animal.animalSpecies.toLowerCase() != selectedAnimalSpecies.toLowerCase()) return false;
    }

    // Tür filtresi (Firestore'daki ASCII/diakritik varyantlarıyla uyumlu)
    if (selectedAnimalType != 'Tümü' && selectedAnimalType.isNotEmpty) {
      final variants = animalTypeWhereInVariants(selectedAnimalType);
      if (variants.isNotEmpty) {
        final animalTypeLower = animal.animalType.trim().toLowerCase();
        final matches =
            variants.any((v) => v.trim().toLowerCase() == animalTypeLower);
        if (!matches) return false;
      } else {
        if (animal.animalType.toLowerCase() !=
            selectedAnimalType.toLowerCase()) {
          return false;
        }
      }
    }

    // Şehir filtresi (güvenlik katmanı).
    // Firestore sorgusu city'yi `whereIn` ile çektiği için burası ana doğrulama değildir;
    // ama sorgu bir sebeple geniş dönmüşse (index fallback vs.) yanlış şehirleri
    // eklememek için toleranslı bir kontrol yapıyoruz.
    if (!_isAllCityFilterValue(selectedCity)) {
      final variants = cityWhereInVariants(selectedCity);
      if (variants.isNotEmpty) {
        final animalCity = animal.city.trim();
        final animalCityLower = animalCity.toLowerCase();
        final matches = variants.any((v) =>
            v.trim().toLowerCase() == animalCityLower);
        if (!matches) return false;
      }
    }

    // Fiyat filtresi
    if (animal.priceInTL < priceRange.start ||
        animal.priceInTL > priceRange.end) {
      return false;
    }

    // Yaş filtresi
    if (animal.ageInMonths < ageRange.start ||
        animal.ageInMonths > ageRange.end) {
      return false;
    }

    // Cinsiyet filtresi
    if (selectedGender != 'Tümü' && animal.gender != selectedGender) {
      return false;
    }

    // Sağlık durumu filtresi
    if (selectedHealthStatus != 'Tümü' &&
        animal.healthStatus != selectedHealthStatus) {
      return false;
    }

    // Cins filtresi
    if (selectedBreed != 'Tümü' && animal.animalBreed != selectedBreed) {
      return false;
    }

    // Acil satış filtresi
    if (showUrgentOnly && !animal.isUrgentSale) {
      return false;
    }

    // Kullanım Amacı filtresi
    if (selectedPurpose != 'Tümü') {
      final purposeLower = animal.purpose.toLowerCase();
      final selectedLower = selectedPurpose.toLowerCase();

      bool isMatch = false;

      // 1. Süt ve Sağım Mapping
      if ((selectedLower.contains('süt') ||
              selectedLower.contains('sağım') ||
              selectedLower == 'sütlük') &&
          (purposeLower.contains('süt') || purposeLower.contains('sağım'))) {
        isMatch = true;
      }
      // 2. Besi ve Et Mapping (Genişletilmiş)
      else if ((selectedLower.contains('besi') ||
              selectedLower.contains('et') ||
              selectedLower == 'besilik') &&
          (purposeLower.contains('besi') ||
              purposeLower.contains('et') ||
              purposeLower.contains('kasap') ||
              purposeLower.contains('semiz'))) {
        isMatch = true;
      }
      // 3. Genel contains kontrolü (karşılıklı)
      else if (purposeLower.contains(selectedLower) ||
          selectedLower.contains(purposeLower)) {
        isMatch = true;
      }

      if (!isMatch) return false;
    }

    return true;
  }

  // Unused legacy grid builder (kept for reference). Consider removal if not needed.
  Widget _buildGridView(List<AnimalPost> animals) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.all(8),
      itemCount: animals.length,
      itemBuilder: (context, index) {
        return AnimalCard(
          animal: animals[index],
          isGridView: true,
          onTap: () => _navigateToAnimalDetail(animals[index]),
          onFavorite: () => _toggleFavorite(animals[index]),
          onShare: () => _shareAnimal(animals[index]),
        );
      },
    );
  }

  // Unused legacy list builder (kept for reference). Consider removal if not needed.
  Widget _buildListView(List<AnimalPost> animals) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: animals.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: AnimalCard(
            animal: animals[index],
            isGridView: false,
            onTap: () => _navigateToAnimalDetail(animals[index]),
            onFavorite: () => _toggleFavorite(animals[index]),
            onShare: () => _shareAnimal(animals[index]),
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return FloatingActionButton(
      backgroundColor: primaryColor,
      elevation: 4,
      child: Icon(
        isGridView ? Icons.list : Icons.grid_view,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        setState(() {
          isGridView = !isGridView;
        });
      },
    );
  }

  Future<void> _navigateToAnimalDetail(AnimalPost animal) async {
    if (animal.photoUrls.isNotEmpty && mounted) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(animal.photoUrls.first),
          context,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalDetailScreen(animal: animal),
      ),
    );
  }

  void _toggleFavorite(AnimalPost animal) {
    // TODO: Implement favorite functionality
    print('Toggle favorite for ${animal.postId}');
  }

  void _shareAnimal(AnimalPost animal) {
    final shareText = 'https://canlipazar.net/ilan/${animal.postId}';
    Share.share(
      shareText,
      subject: '${animal.animalSpecies} İlanı',
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Tüm Hayvanlar';
      selectedAnimalType = 'Tümü';
      selectedPurpose = 'Tümü';
      searchQuery = '';
      selectedAnimalSpecies = 'Tümü';
      _searchKeywords = [];
      priceRange = RangeValues(0, 500000);
      ageRange = RangeValues(0, 120);
      selectedGender = 'Tümü';
      selectedHealthStatus = 'Tümü';
      selectedCity = 'Tüm Şehirler';
      selectedBreed = 'Tümü';
      showUrgentOnly = false;
      showFilters = false;
      _searchController.clear();
      _filtersModified = false;
    });
    // Pagination'ı sıfırla ve baştan yükle
    _loadInitialAnimals();
  }

  /// Yazılan metinden şehir, cinsiyet ve tür çıkarıp filtreleri uygular.
  /// Örn: "kahramanmaraş satılık inek" → şehir Maraş, tür Büyükbaş; "erkek dana" → cinsiyet Erkek, tür Büyükbaş.
  static String _normalizeForMatch(String s) {
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i');
  }

  /// Stop words: Aramada filtreye katkısı olmayan kelimeler (temizlenir). Normalize formda.
  static const Set<String> _searchStopWords = {
    'satilik', 'ilan', 'ariyorum', 'istiyorum', 'alici', 'var', 'mi', 'mu',
    'bir', 'bu', 'su', 'o', 'icin', 'ile', 've', 'veya', 'vb', 'acil', 'hayvan', 'hayvanlar',
    'fiyat', 'tane', 'adet', 'tlf', 'tel', 'telefon', 'numara', 'no', 'il', 'ilce',
  };

  /// Filtre tetikleyici: Şehir/tür/cinsiyet/kategori olarak kullanılan kelimeler
  /// _searchKeywords'a eklenmez; sadece Firestore (city, animalSpecies vb.) filtresine gider.
  static bool _isFilterTriggerWord(String normalizedWord) {
    const triggerSet = {
      'erkek', 'disi', 'buyukbas', 'kucukbas', 'kanatli',
      'inek', 'sigir', 'dana', 'duve', 'boga', 'tosun', 'manda',
      'koyun', 'keci', 'kuzu', 'oglak', 'koc', 'teke',
      'tavuk', 'hindi', 'kaz', 'ordek', 'bildircin', 'guvercin',
    };
    return _searchStopWords.contains(normalizedWord) || triggerSet.contains(normalizedWord);
  }

  void _applySmartSearchFromQuery(String text) {
    if (!mounted) return;
    final trimmed = text.trim();
    searchQuery = trimmed;
    final norm = _normalizeForMatch(trimmed);
    if (norm.isEmpty) {
      setState(() {
        selectedCity = 'Tüm Şehirler';
        selectedGender = 'Tümü';
        selectedAnimalType = 'Tümü';
        selectedAnimalSpecies = 'Tümü';
        selectedCategory = 'Tüm Hayvanlar';
        _searchKeywords = [];
      });
      _onFilterChanged(immediate: true);
      return;
    }

    // Kelimelere böl (büyük/küçük harf duyarsız eşleşme için kullanılacak)
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => _normalizeForMatch(w)).where((w) => w.length > 0).toList();

    // Şehir: metinde geçen en uzun eşleşen şehir (81 il)
    String newCity = 'Tüm Şehirler';
    int longestMatch = 0;
    for (int i = 1; i < turkishCities.length; i++) {
      final city = turkishCities[i];
      final cityNorm = _normalizeForMatch(city);
      if (cityNorm.length > longestMatch && norm.contains(cityNorm)) {
        longestMatch = cityNorm.length;
        newCity = city;
      }
    }

    // Anahtar kelimeler: Stop words ve filtre tetikleyicileri (şehir, tür, cinsiyet, kategori) çıkarılır.
    // Sadece açıklama/cins eşleşmesi için kullanılacak kelimeler kalır; böylece sorgu city + animalSpecies ile veritabanından gelir, lazy loading takılmaz.
    final cityNorm = newCity != 'Tüm Şehirler' ? _normalizeForMatch(newCity) : '';
    final keywordsOnly = words.where((w) {
      if (_isFilterTriggerWord(w)) return false;
      if (cityNorm.isNotEmpty && w == cityNorm) return false;
      return true;
    }).toList();
    _searchKeywords = keywordsOnly;

    // Cinsiyet
    String newGender = selectedGender;
    if (norm.contains('erkek')) {
      newGender = 'Erkek';
    } else if (norm.contains('disi') || norm.contains('dişi')) {
      newGender = 'Dişi';
    }

    // Hayvan türü (animalType): Büyükbaş / Küçükbaş / Kanatlı
    String newAnimalType = selectedAnimalType;
    if (norm.contains('buyukbas') ||
        norm.contains('büyükbaş') ||
        norm.contains('inek') ||
        norm.contains('sigir') ||
        norm.contains('sığır') ||
        norm.contains('dana') ||
        norm.contains('duve') ||
        norm.contains('düve') ||
        norm.contains('boga') ||
        norm.contains('boğa') ||
        norm.contains('tosun') ||
        norm.contains('manda')) {
      newAnimalType = 'Büyükbaş';
    } else if (norm.contains('kucukbas') ||
        norm.contains('küçükbaş') ||
        norm.contains('koyun') ||
        norm.contains('keci') ||
        norm.contains('keçi') ||
        norm.contains('kuzu') ||
        norm.contains('oglak') ||
        norm.contains('oğlak') ||
        norm.contains('koc') ||
        norm.contains('koç') ||
        norm.contains('teke')) {
      newAnimalType = 'Küçükbaş';
    } else if (norm.contains('kanatli') || norm.contains('kanatlı')) {
      newAnimalType = 'Kanatlı';
    }

    // Hayvan türü (animalSpecies): Firestore'da sorgu için - Sığır, Koyun, Keçi, Manda, Tavuk vb.
    // Veritabanındaki kayıtlarla eşleşmesi için AnimalCategories ile aynı yazım kullanılır.
    String newAnimalSpecies = 'Tümü';
    if (norm.contains('inek') ||
        norm.contains('sigir') ||
        norm.contains('sığır') ||
        norm.contains('dana') ||
        norm.contains('duve') ||
        norm.contains('düve') ||
        norm.contains('boga') ||
        norm.contains('boğa') ||
        norm.contains('tosun')) {
      newAnimalSpecies = 'Sığır';
    } else if (norm.contains('koyun') || norm.contains('kuzu') || norm.contains('koc') || norm.contains('koç')) {
      newAnimalSpecies = 'Koyun';
    } else if (norm.contains('keci') || norm.contains('keçi') || norm.contains('oglak') || norm.contains('oğlak') || norm.contains('teke')) {
      newAnimalSpecies = 'Keçi';
    } else if (norm.contains('manda')) {
      newAnimalSpecies = 'Manda';
    } else if (norm.contains('tavuk')) {
      newAnimalSpecies = 'Tavuk';
    } else if (norm.contains('hindi')) {
      newAnimalSpecies = 'Hindi';
    } else if (norm.contains('kaz')) {
      newAnimalSpecies = 'Kaz';
    } else if (norm.contains('ordek') || norm.contains('ördek')) {
      newAnimalSpecies = 'Ördek';
    } else if (norm.contains('bildircin') || norm.contains('bıldırcın')) {
      newAnimalSpecies = 'Bıldırcın';
    } else if (norm.contains('guvercin') || norm.contains('güvercin')) {
      newAnimalSpecies = 'Güvercin';
    }

    // Kategori (selectedCategory): Firestore'da ayrı alan yok; client-side _filterAnimals ile uygulanır.
    // Örn: "düve" → category Düve, "tosun" → Tosun, "kuzu" → Kuzu.
    String newCategory = selectedCategory;
    if (norm.contains('duve') || norm.contains('düve')) {
      newCategory = 'Düve';
    } else if (norm.contains('tosun')) {
      newCategory = 'Tosun';
    } else if (norm.contains('kuzu')) {
      newCategory = 'Kuzu';
    } else if (norm.contains('oglak') || norm.contains('oğlak')) {
      newCategory = 'Oğlak';
    } else if (norm.contains('koc') || norm.contains('koç')) {
      newCategory = 'Koç';
    } else if (norm.contains('teke')) {
      newCategory = 'Teke';
    } else if (norm.contains('manda')) {
      newCategory = 'Manda';
    } else if (norm.contains('koyun')) {
      newCategory = 'Koyun';
    } else if (norm.contains('keci') || norm.contains('keçi')) {
      newCategory = 'Keçi';
    }

    setState(() {
      selectedCity = newCity;
      selectedGender = newGender;
      selectedAnimalType = newAnimalType;
      selectedAnimalSpecies = newAnimalSpecies;
      selectedCategory = newCategory;
      if (newAnimalType != selectedAnimalType) selectedPurpose = 'Tümü';
    });
    _onFilterChanged(immediate: true);
  }

  bool _matchesCategory(AnimalPost animal, String category) {
    switch (category) {
      // Tür bazlı kategoriler
      case 'Süt Sığırı':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            (animal.purpose.toLowerCase().contains('süt') ||
                animal.animalBreed.toLowerCase().contains('holstein') ||
                animal.animalBreed.toLowerCase().contains('jersey'));

      case 'Et Sığırı':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            (animal.purpose.toLowerCase().contains('et') ||
                animal.animalBreed.toLowerCase().contains('angus') ||
                animal.animalBreed.toLowerCase().contains('charolais'));

      case 'Damızlık Boğa':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'erkek' &&
            animal.purpose.toLowerCase().contains('damızlık');

      case 'Düve':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'dişi' &&
            animal.ageInMonths < 24;

      case 'Manda':
        return animal.animalSpecies.toLowerCase() == 'manda';

      case 'Tosun':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'erkek' &&
            animal.ageInMonths < 24;

      case 'Koyun':
        return animal.animalSpecies.toLowerCase() == 'koyun';

      case 'Keçi':
        return animal.animalSpecies.toLowerCase() == 'keçi';

      case 'Kuzu':
        return animal.animalSpecies.toLowerCase() == 'koyun' &&
            animal.ageInMonths < 12;

      case 'Oğlak':
        return animal.animalSpecies.toLowerCase() == 'keçi' &&
            animal.ageInMonths < 12;

      case 'Koç':
        return animal.animalSpecies.toLowerCase() == 'koyun' &&
            animal.gender.toLowerCase() == 'erkek';

      case 'Teke':
        return animal.animalSpecies.toLowerCase() == 'keçi' &&
            animal.gender.toLowerCase() == 'erkek';

      // Durum bazlı kategoriler
      case 'Gebe Hayvanlar':
        return animal.isPregnant == true;

      case 'Genç Hayvanlar':
        return animal.ageInMonths < 18;

      case 'Damızlık Hayvanlar':
        return animal.purpose.toLowerCase().contains('damızlık');

      case 'Acil Satış':
        return animal.isUrgentSale == true;

      case 'Süt Veren':
        // Sadece süt için olanlar, adaklık veya kurbanlık değil
        return animal.purpose.toLowerCase().contains('süt') &&
            !animal.purpose.toLowerCase().contains('adak') &&
            !animal.purpose.toLowerCase().contains('kurban');

      case 'Et İçin':
        // Sadece et için olanlar, adaklık veya kurbanlık değil
        return animal.purpose.toLowerCase().contains('et') &&
            !animal.purpose.toLowerCase().contains('adak') &&
            !animal.purpose.toLowerCase().contains('kurban');

      case 'Organik Beslenmiş':
        return animal.additionalInfo != null &&
            animal.additionalInfo!.toString().toLowerCase().contains('organik');

      case 'Kanatlı':
        return animal.animalType.toLowerCase() == 'kanatlı' ||
            ['tavuk', 'hindi', 'kaz', 'ördek', 'bıldırcın', 'güvercin']
                .contains(animal.animalSpecies.toLowerCase());

      case 'Kurbanlık':
        // Sadece kurbanlık olanlar, adaklık değil
        final purposeLower = animal.purpose.toLowerCase();
        final additionalInfoLower = animal.additionalInfo != null
            ? animal.additionalInfo.toString().toLowerCase()
            : '';
        return (purposeLower.contains('kurban') ||
                additionalInfoLower.contains('kurban')) &&
            !purposeLower.contains('adak') &&
            !additionalInfoLower.contains('adak');

      case 'Adaklık Hayvanlar':
        // Sadece adaklık olanlar, kurbanlık değil
        final purposeLower = animal.purpose.toLowerCase();
        final additionalInfoLower = animal.additionalInfo != null
            ? animal.additionalInfo.toString().toLowerCase()
            : '';
        return (purposeLower.contains('adak') ||
                additionalInfoLower.contains('adak')) &&
            !purposeLower.contains('kurban') &&
            !additionalInfoLower.contains('kurban');

      default:
        return false; // Bilinmeyen kategoriler için false döndür (sadece eşleşenleri göster)
    }
  }

  void _onFilterChanged({bool immediate = false}) {
    if (!mounted) return;

    // UI Loading başlat
    if (!_isFiltering) {
      setState(() {
        _isFiltering = true;
      });
    }

    _filtersModified = _areFiltersModified();

    void performUpdates() {
      if (!mounted) return;

      // Hem sayıyı hem de verileri güncelle
      _fetchCategoryCount();

      // Verileri yenile (Pagination sıfırlanır)
      _loadInitialAnimals();
    }

    if (immediate) {
      performUpdates();
    } else {
      _filterDebounceTimer?.cancel();
      _filterDebounceTimer =
          Timer(const Duration(milliseconds: 500), performUpdates);
    }
  }

  // Çakışan filtreleri temizle
  void _clearConflictingFilters(String newFilterType, String newValue) {
    switch (newFilterType) {
      case 'animalType':
        // Hayvan türü değiştiğinde kategoriyi temizle
        if (newValue != 'Tümü') {
          selectedCategory = 'Tüm Hayvanlar';
          print('🧹 Hayvan türü değişti, kategori temizlendi');
        }
        // animalType değişince tür kapsamını daraltan alt filtreler temizlenmeli
        // (Küçükbaş altında sadece birkaç ilan kalmasını engellemek için).
        selectedAnimalSpecies = 'Tümü';
        selectedBreed = 'Tümü';
        break;
      case 'category':
        // Kategori değiştiğinde hayvan türünü temizle
        if (newValue != 'Tüm Hayvanlar') {
          selectedAnimalType = 'Tümü';
          print('🧹 Kategori değişti, hayvan türü temizlendi');
        }
        break;
    }
  }

  // Filtrelerin değiştirilip değiştirilmediğini kontrol et
  bool _areFiltersModified() {
    return selectedCategory != 'Tüm Hayvanlar' ||
        selectedAnimalType != 'Tümü' ||
        searchQuery.isNotEmpty ||
        selectedCity != 'Tüm Şehirler' ||
        selectedAnimalSpecies != 'Tümü' ||
        selectedGender != 'Tümü' ||
        selectedHealthStatus != 'Tümü' ||
        selectedBreed != 'Tümü' ||
        showUrgentOnly ||
        priceRange.start > 0 ||
        priceRange.end < 500000 ||
        ageRange.start > 0 ||
        ageRange.end < 120;
  }

  // Aktif filtreleri göster
  Widget _buildActiveFiltersSummary() {
    List<String> activeFilters = [];

    if (selectedCategory != 'Tüm Hayvanlar') {
      activeFilters.add(selectedCategory);
    }
    if (selectedAnimalType != 'Tümü') {
      activeFilters.add(selectedAnimalType);
    }
    if (selectedCity != 'Tüm Şehirler') {
      activeFilters.add(selectedCity);
    }
    if (selectedGender != 'Tümü') {
      activeFilters.add(selectedGender);
    }
    if (selectedHealthStatus != 'Tümü') {
      activeFilters.add(selectedHealthStatus);
    }
    if (selectedBreed != 'Tümü') {
      activeFilters.add(selectedBreed);
    }
    if (showUrgentOnly) {
      activeFilters.add('Acil Satış');
    }
    if (searchQuery.isNotEmpty) {
      activeFilters.add('Arama: "$searchQuery"');
    }
    if (priceRange.start > 0 || priceRange.end < 500000) {
      activeFilters.add(
          'Fiyat: ${PricingService.formatPrice(priceRange.start)} - ${PricingService.formatPrice(priceRange.end)}');
    }
    if (ageRange.start > 0 || ageRange.end < 120) {
      activeFilters
          .add('Yaş: ${ageRange.start.round()}-${ageRange.end.round()} ay');
    }

    if (activeFilters.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: primaryColor, size: 16),
              SizedBox(width: 6),
              Text(
                'Aktif Filtreler',
                style: SafeFonts.poppins(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                style: TextButton.styleFrom(
                  minimumSize: Size(0, 24),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Temizle',
                  style: SafeFonts.poppins(
                    color: warningColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: activeFilters
                .map((filter) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: SafeFonts.poppins(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Fiyat seçeneği widget'ı
  // Seçili kategoriye göre hayvan türünü belirle
  String _getAnimalTypeFromCategory() {
    if (selectedCategory == 'Tüm Hayvanlar') {
      return 'Tümü';
    }

    // Büyükbaş kategoriler
    final buyukbasCategories = [
      'Süt Sığırı',
      'Et Sığırı',
      'Damızlık Boğa',
      'Düve',
      'Manda',
      'Tosun'
    ];

    // Küçükbaş kategoriler
    final kucukbasCategories = [
      'Koyun',
      'Keçi',
      'Kuzu',
      'Oğlak',
      'Koç',
      'Teke',
      'Kurbanlık'
    ];

    // Kanatlı kategoriler
    final kanatliCategories = ['Kanatlı', 'Adaklık Hayvanlar'];

    if (buyukbasCategories.contains(selectedCategory)) {
      return 'büyükbaş';
    } else if (kucukbasCategories.contains(selectedCategory)) {
      return 'küçükbaş';
    } else if (kanatliCategories.contains(selectedCategory)) {
      return 'kanatlı';
    }

    return 'Tümü';
  }

  // Hayvan türüne göre dinamik fiyat seçenekleri
  List<Widget> _getDynamicPriceOptions() {
    final animalType = _getAnimalTypeFromCategory();

    // Büyükbaş için fiyat aralıkları (daha yüksek)
    if (animalType == 'büyükbaş') {
      return [
        _buildPriceOption('Tümü', 0, 500000),
        _buildPriceOption('0-20K₺', 0, 20000),
        _buildPriceOption('20K-40K₺', 20000, 40000),
        _buildPriceOption('40K-70K₺', 40000, 70000),
        _buildPriceOption('70K-100K₺', 70000, 100000),
        _buildPriceOption('100K-130K₺', 100000, 130000),
        _buildPriceOption('130K-150K₺', 130000, 150000),
        _buildPriceOption('150K+', 150000, 500000),
      ];
    }

    // Küçükbaş için fiyat aralıkları (orta)
    if (animalType == 'küçükbaş') {
      return [
        _buildPriceOption('Tümü', 0, 500000),
        _buildPriceOption('0-3K₺', 0, 3000),
        _buildPriceOption('3K-6K₺', 3000, 6000),
        _buildPriceOption('6K-10K₺', 6000, 10000),
        _buildPriceOption('10K-15K₺', 10000, 15000),
        _buildPriceOption('15K-25K₺', 15000, 25000),
        _buildPriceOption('25K+', 25000, 500000),
      ];
    }

    // Kanatlı için fiyat aralıkları (daha düşük)
    if (animalType == 'kanatlı') {
      return [
        _buildPriceOption('Tümü', 0, 500000),
        _buildPriceOption('0-100₺', 0, 100),
        _buildPriceOption('100-300₺', 100, 300),
        _buildPriceOption('300-500₺', 300, 500),
        _buildPriceOption('500-1K₺', 500, 1000),
        _buildPriceOption('1K-2K₺', 1000, 2000),
        _buildPriceOption('2K+', 2000, 500000),
      ];
    }

    // Tüm hayvanlar veya karışık seçim için genel aralıklar
    return [
      _buildPriceOption('Tümü', 0, 500000),
      _buildPriceOption('0-5K₺', 0, 5000),
      _buildPriceOption('5K-15K₺', 5000, 15000),
      _buildPriceOption('15K-30K₺', 15000, 30000),
      _buildPriceOption('30K-60K₺', 30000, 60000),
      _buildPriceOption('60K-100K₺', 60000, 100000),
      _buildPriceOption('100K-150K₺', 100000, 150000),
      _buildPriceOption('150K+', 150000, 500000),
    ];
  }

  Widget _buildPriceOption(String label, double min, double max) {
    final isSelected = priceRange.start == min && priceRange.end == max;
    return GestureDetector(
      onTap: () {
        setState(() {
          priceRange = RangeValues(min, max);
        });
        _onFilterChanged();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: SafeFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  // Hayvan türüne göre dinamik yaş seçenekleri
  List<Widget> _getDynamicAgeOptions() {
    final animalType = _getAnimalTypeFromCategory();

    // Kanatlı için yaş aralıkları (daha kısa ömür)
    if (animalType == 'kanatlı') {
      return [
        _buildAgeOption('Tümü', 0, 120),
        _buildAgeOption('0-3 ay', 0, 3),
        _buildAgeOption('3-6 ay', 3, 6),
        _buildAgeOption('6-12 ay', 6, 12),
        _buildAgeOption('1-2 yaş', 12, 24),
        _buildAgeOption('2+ yaş', 24, 120),
      ];
    }

    // Büyükbaş ve küçükbaş için yaş aralıkları (daha uzun ömür)
    if (animalType == 'büyükbaş' || animalType == 'küçükbaş') {
      return [
        _buildAgeOption('Tümü', 0, 120),
        _buildAgeOption('0-6 ay', 0, 6),
        _buildAgeOption('6-12 ay', 6, 12),
        _buildAgeOption('1-2 yaş', 12, 24),
        _buildAgeOption('2-5 yaş', 24, 60),
        _buildAgeOption('5+ yaş', 60, 120),
      ];
    }

    // Genel yaş aralıkları
    return [
      _buildAgeOption('Tümü', 0, 120),
      _buildAgeOption('0-6 ay', 0, 6),
      _buildAgeOption('6-12 ay', 6, 12),
      _buildAgeOption('1-2 yaş', 12, 24),
      _buildAgeOption('2-5 yaş', 24, 60),
      _buildAgeOption('5+ yaş', 60, 120),
    ];
  }

  // Yaş seçeneği widget'ı
  Widget _buildAgeOption(String label, double min, double max) {
    final isSelected = ageRange.start == min && ageRange.end == max;
    return GestureDetector(
      onTap: () {
        setState(() {
          ageRange = RangeValues(min, max);
        });
        _onFilterChanged();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: SafeFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }
}
