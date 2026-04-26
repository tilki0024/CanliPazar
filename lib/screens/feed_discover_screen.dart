import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post.dart';
import '../widgets/feed_card.dart';
import '../utils/feed_categories.dart';
import '../services/pricing_service.dart';
import 'feed_detail_screen.dart';
import 'add_feed_screen.dart';
import '../utils/safe_fonts.dart';
import 'package:shimmer/shimmer.dart';

class FeedDiscoverScreen extends StatefulWidget {
  const FeedDiscoverScreen({Key? key}) : super(key: key);

  @override
  State<FeedDiscoverScreen> createState() => _FeedDiscoverScreenState();
}

class _FeedDiscoverScreenState extends State<FeedDiscoverScreen> {
  bool isGridView = true;
  String selectedCategory = 'Tüm Yemler';
  String selectedAnimalType = 'Tümü';
  String searchQuery = '';
  RangeValues priceRange = RangeValues(0, 100000);
  RangeValues quantityRange = RangeValues(0, 10000);
  String selectedCity = 'Tüm Şehirler';
  bool showFilters = false;
  bool showUrgentOnly = false;
  bool showOrganicOnly = false;
  bool showBulkSaleOnly = false;
  int filteredResultsCount = 0;

  List<FeedPost> _allFeeds = [];

  final int _limit = 15;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  static const List<String> turkishCities = [
    'Tüm Şehirler',
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara',
    'Antalya', 'Artvin', 'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl',
    'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı',
    'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
    'Hakkari', 'Hatay', 'Isparta', 'Mersin', 'İstanbul', 'İzmir',
    'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli',
    'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin',
    'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya',
    'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon',
    'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak',
    'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman', 'Şırnak',
    'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis',
    'Osmaniye', 'Düzce',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialFeeds());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isInitialLoading) {
      _loadMoreFeeds();
    }
  }

  Future<QuerySnapshot> _fetchFeeds({DocumentSnapshot? startAfter}) async {
    Query query = FirebaseFirestore.instance
        .collection('feeds')
        .orderBy('datePublished', descending: true)
        .limit(_limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  Future<void> _loadInitialFeeds() async {
    if (_isLoadingMore || !mounted) return;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = true;
      _allFeeds = [];
      _lastDocument = null;
      _hasMoreData = true;
    });
    try {
      final snapshot = await _fetchFeeds();
      if (!mounted) return;
      final list = <FeedPost>[];
      for (var doc in snapshot.docs) {
        try {
          list.add(FeedPost.fromSnap(doc));
        } catch (e) {
          print('Feed parse hatası: $e');
        }
      }
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreData = snapshot.docs.length >= _limit;
      setState(() {
        _allFeeds = list;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
          _hasMoreData = false;
        });
      }
    }
  }

  Future<void> _loadMoreFeeds() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null || !mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final snapshot = await _fetchFeeds(startAfter: _lastDocument);
      if (!mounted) return;
      final list = <FeedPost>[];
      for (var doc in snapshot.docs) {
        try {
          list.add(FeedPost.fromSnap(doc));
        } catch (e) {
          print('Feed parse hatası: $e');
        }
      }
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreData = snapshot.docs.length >= _limit;
      setState(() {
        _allFeeds.addAll(list);
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async => _loadInitialFeeds(),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            // Arama çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Yem ara (örn: saman, arpa, yonca...)',
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: textSecondary, size: 20),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.tune, color: primaryColor, size: 20),
                          onPressed: () => setState(() => showFilters = !showFilters),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            if (showFilters) _buildSearchAndFilters(),
            // Kategoriler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickFilterChip('Acil Satış', showUrgentOnly,
                        () => setState(() => showUrgentOnly = !showUrgentOnly)),
                    SizedBox(width: 8),
                    _buildQuickFilterChip('Organik', showOrganicOnly,
                        () => setState(() => showOrganicOnly = !showOrganicOnly)),
                    SizedBox(width: 8),
                    _buildQuickFilterChip('Toplu Satış', showBulkSaleOnly,
                        () => setState(() => showBulkSaleOnly = !showBulkSaleOnly)),
                    SizedBox(width: 16),
                    ...FeedCategories.categories
                        .take(10)
                        .map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedCategory = category),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == category
                                        ? primaryColor.withOpacity(0.1)
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selectedCategory == category
                                          ? primaryColor.withOpacity(0.3)
                                          : dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        FeedCategories.getCategoryIcon(category),
                                        size: 16,
                                        color: selectedCategory == category
                                            ? primaryColor
                                            : textSecondary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        category,
                                        style: SafeFonts.poppins(
                                          color: selectedCategory == category
                                              ? primaryColor
                                              : textPrimary,
                                          fontWeight:
                                              selectedCategory == category
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ),
            // Yem listesi
            _buildFeedList(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: primaryColor,
            elevation: 4,
            heroTag: "add_feed",
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFeedScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: surfaceColor,
            elevation: 4,
            heroTag: "view_toggle",
            child: Icon(
              isGridView ? Icons.list : Icons.grid_view,
              color: primaryColor,
              size: 24,
            ),
            onPressed: () => setState(() => isGridView = !isGridView),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        'Yemler',
        style: SafeFonts.poppins(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFFF5F7F4),
      margin: EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: primaryColor, size: 16),
                    SizedBox(width: 4),
                    Text('Filtreler',
                        style: SafeFonts.poppins(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text('Temizle',
                      style: SafeFonts.poppins(
                          color: warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Yem ara (örn: saman, arpa, yonca...)',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondary),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 12),
            Text('Fiyat (₺)',
                style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            RangeSlider(
              values: priceRange,
              min: 0,
              max: 100000,
              divisions: 100,
              labels: RangeLabels(
                PricingService.formatPrice(priceRange.start),
                PricingService.formatPrice(priceRange.end),
              ),
              onChanged: (values) => setState(() => priceRange = values),
            ),
            SizedBox(height: 12),
            Text('Miktar (kg)',
                style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            RangeSlider(
              values: quantityRange,
              min: 0,
              max: 10000,
              divisions: 50,
              labels: RangeLabels(
                '${quantityRange.start.round()} kg',
                '${quantityRange.end.round()} kg',
              ),
              onChanged: (values) => setState(() => quantityRange = values),
            ),
            SizedBox(height: 12),
            Text('Şehir',
                style: SafeFonts.poppins(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              value: selectedCity,
              isExpanded: true,
              items: turkishCities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city, style: SafeFonts.poppins(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => selectedCity = value ?? 'Tüm Şehirler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor.withOpacity(0.3) : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, color: primaryColor, size: 16),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: SafeFonts.poppins(
                color: isSelected ? primaryColor : textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    final filteredFeeds = _allFeeds.where(_filterFeeds).toList();
    if (_isInitialLoading) {
      return _buildShimmerLoading();
    }
    if (filteredFeeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Yem bulunamadı',
                  style: SafeFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Filtreleri değiştirmeyi deneyin',
                  style: SafeFonts.poppins(color: textSecondary)),
            ],
          ),
        ),
      );
    }
    if (isGridView) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredFeeds
                  .map((feed) => SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 20,
                        child: FeedCard(
                          feed: feed,
                          isGridView: true,
                          onTap: () => _navigateToFeedDetail(feed),
                        ),
                      ))
                  .toList(),
            ),
            _buildFeedListFooter(),
          ],
        ),
      );
    }
    return Column(
      children: [
        ...filteredFeeds
            .map((feed) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: FeedCard(
                    feed: feed,
                    isGridView: false,
                    onTap: () => _navigateToFeedDetail(feed),
                  ),
                )),
        _buildFeedListFooter(),
      ],
    );
  }

  Widget _buildFeedListFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (!_hasMoreData) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Tüm yemler gösterildi',
            style: SafeFonts.poppins(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
              6,
              (index) => SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 20,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
        ),
      ),
    );
  }

  bool _filterFeeds(FeedPost feed) {
    if (feed.isActive == false) return false;

    if (selectedCategory != 'Tüm Yemler') {
      if (!FeedCategories.matchesCategory(feed, selectedCategory)) {
        return false;
      }
    }

    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase().trim();
      // Genişletilmiş arama: kategori, marka, açıklama, yem türü, hayvan türü, paketleme
      final matchesCategory = feed.feedCategory.toLowerCase().contains(searchLower);
      final matchesBrand = feed.brand.toLowerCase().contains(searchLower);
      final matchesDescription = feed.description.toLowerCase().contains(searchLower);
      final matchesFeedType = feed.feedType.toLowerCase().contains(searchLower);
      final matchesAnimalType = feed.animalType.toLowerCase().contains(searchLower);
      final matchesPackaging = feed.packagingType.toLowerCase().contains(searchLower);
      final matchesSellerType = feed.sellerType.toLowerCase().contains(searchLower);
      
      // Eğer hiçbir alanda eşleşme yoksa filtrele
      if (!matchesCategory && 
          !matchesBrand && 
          !matchesDescription && 
          !matchesFeedType && 
          !matchesAnimalType && 
          !matchesPackaging && 
          !matchesSellerType) {
        return false;
      }
    }

    if (selectedCity != 'Tüm Şehirler' && feed.city != selectedCity) {
      return false;
    }

    if (feed.priceInTL < priceRange.start || feed.priceInTL > priceRange.end) {
      return false;
    }

    if (feed.quantityInKg < quantityRange.start ||
        feed.quantityInKg > quantityRange.end) {
      return false;
    }

    if (showUrgentOnly && !feed.isUrgentSale) return false;
    if (showOrganicOnly && !feed.isOrganic) return false;
    if (showBulkSaleOnly && !feed.isBulkSale) return false;

    return true;
  }

  void _navigateToFeedDetail(FeedPost feed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailScreen(feed: feed),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Tüm Yemler';
      searchQuery = '';
      priceRange = RangeValues(0, 100000);
      quantityRange = RangeValues(0, 10000);
      selectedCity = 'Tüm Şehirler';
      showUrgentOnly = false;
      showOrganicOnly = false;
      showBulkSaleOnly = false;
      showFilters = false;
      _searchController.clear();
    });
    _loadInitialFeeds();
  }
}
