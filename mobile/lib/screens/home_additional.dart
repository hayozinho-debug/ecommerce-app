import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../providers/collection_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/collection.dart';
import '../models/product.dart';
import '../constants/app_constants.dart';
import '../utils/price_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/reviews_widget.dart';
import '../widgets/frete_carousel_widget.dart';
import '../widgets/clips_stories_widget.dart';
import 'profile_menu_screen.dart';
import 'categories_screen.dart';
import 'categories_screen.dart';

const _kBlue = Color(0xFF1054FF);
const _kGray = Color(0xFF656362);
const _kGrayL = Color(0xFFA09E9D);

class HomeAdditionalShell extends StatefulWidget {
  const HomeAdditionalShell({Key? key}) : super(key: key);

  @override
  State<HomeAdditionalShell> createState() => _HomeAdditionalShellState();
}

class _HomeAdditionalShellState extends State<HomeAdditionalShell> {
  int _selectedIndex = 0;
  late CartProvider _cartProvider;
  String? _catalogCollectionGid;
  String? _catalogCollectionName;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Listener para quando um item é adicionado ao carrinho
    Future.microtask(() {
      _cartProvider = context.read<CartProvider>();
      _cartProvider.addListener(_onCartChanged);
    });
  }

  @override
  void dispose() {
    _cartProvider.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    // Muda para a aba Carrinho automaticamente
    if (mounted) {
      setState(() {
        _selectedIndex = 5;
      });
    }
  }

  void _navigateToCatalogWithCollection(String? collectionGid, String? collectionName) {
    setState(() {
      _catalogCollectionGid = collectionGid;
      _catalogCollectionName = collectionName;
      _selectedIndex = 1; // Navigate to CatalogScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeAdditionalContent(
                  onNavigateToCatalog: _navigateToCatalogWithCollection,
                  onNavigateToCart: () => setState(() => _selectedIndex = 4),
                ),
                CatalogScreen(
                  onBackToHome: () => setState(() {
                    _selectedIndex = 0;
                    _catalogCollectionGid = null;
                    _catalogCollectionName = null;
                  }),
                  onNavigateToCart: () => setState(() => _selectedIndex = 5),
                  collectionGid: _catalogCollectionGid,
                  collectionName: _catalogCollectionName,
                ),
                CategoriesScreen(
                  onNavigateToCatalog: _navigateToCatalogWithCollection,
                ),
                ClipsStoriesWidget(
                  isActive: _selectedIndex == 3,
                  onNavigateBack: () => setState(() => _selectedIndex = 0),
                ),
                CartScreen(
                  onContinueShopping: () => setState(() => _selectedIndex = 0),
                ),
                const ProfileMenuScreen(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return _FooterNav(
                  selectedIndex: _selectedIndex,
                  itemCount: cartProvider.itemCount,
                  onTabSelected: _onTabSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNav extends StatelessWidget {
  final int selectedIndex;
  final int itemCount;
  final ValueChanged<int> onTabSelected;

  const _FooterNav({
    required this.selectedIndex,
    required this.itemCount,
    required this.onTabSelected,
  });

  // Cores
  static const Color _primary = Color(0xFF1A3A8C);
  static const Color _active = Color(0xFF1A3A8C);
  static const Color _inactive = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0, left: 14, right: 14),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => onTabSelected(0),
              behavior: HitTestBehavior.opaque,
              child: _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: selectedIndex == 0,
              ),
            ),
            GestureDetector(
              onTap: () => onTabSelected(2),
              behavior: HitTestBehavior.opaque,
              child: _buildNavItem(
                icon: Icons.category_rounded,
                label: 'Categorias',
                isActive: selectedIndex == 2,
              ),
            ),
            GestureDetector(
              onTap: () => onTabSelected(3),
              behavior: HitTestBehavior.opaque,
              child: _buildNavItem(
                icon: Icons.play_circle_outline_rounded,
                label: 'Clips',
                isActive: selectedIndex == 3,
              ),
            ),
            GestureDetector(
              onTap: () => onTabSelected(4),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildNavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Carrinho',
                    isActive: selectedIndex == 4,
                  ),
                  if (itemCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onTabSelected(5),
              behavior: HitTestBehavior.opaque,
              child: _buildNavItem(
                icon: Icons.menu_rounded,
                label: 'Menu',
                isActive: selectedIndex == 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? _active : _inactive;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(isActive),
            size: 24,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
          child: Text(label),
        ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 5 : 0,
          height: isActive ? 5 : 0,
          decoration: BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class HomeAdditionalContent extends StatefulWidget {
  final Function(String?, String?)? onNavigateToCatalog;
  final VoidCallback? onNavigateToCart;

  const HomeAdditionalContent({
    Key? key,
    this.onNavigateToCatalog,
    this.onNavigateToCart,
  }) : super(key: key);

  @override
  State<HomeAdditionalContent> createState() => _HomeAdditionalContentState();
}

class _HomeAdditionalContentState extends State<HomeAdditionalContent> {
    // Verifica se o altText da imagem corresponde à cor (case-insensitive, ignora acentos)
    bool _matchesColorAltText(String? altText, String color) {
      if (altText == null) return false;
      String normalize(String s) => s
          .toLowerCase()
          .replaceAll(RegExp(r'[áàãâä]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòõôö]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return normalize(altText).contains(normalize(color));
    }

    // Normaliza a URL da imagem para comparação (remove query params, ignora http/https)
    String _normalizeImageUrl(String? url) {
      if (url == null) return '';
      final uri = Uri.tryParse(url);
      if (uri == null) return url;
      // Remove query params e força https
      return uri.replace(queryParameters: {}, scheme: 'https').toString();
    }
  List<Product> _pijamasFemininosProducts = [];
  bool _isLoadingPijamasFemininos = false;
  List<Product> _secondCollectionProducts = [];
  bool _isLoadingSecondCollection = false;
  List<Product> _boysCollectionProducts = [];
  bool _isLoadingBoysCollection = false;
  List<Product> _girlsCollectionProducts = [];
  bool _isLoadingGirlsCollection = false;
  String? _bannerHomeMobileUrl;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  String _optimizedShopifyImageUrl(
    String imageUrl, {
    required int width,
    int? height,
  }) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return imageUrl;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('cdn.shopify.com')) {
      return imageUrl;
    }

    final query = Map<String, String>.from(uri.queryParameters);
    query['width'] = width.toString();
    if (height != null) {
      query['height'] = height.toString();
      query['crop'] = 'center';
    }

    return uri.replace(queryParameters: query).toString();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<CollectionProvider>().fetchStoriesCollections();
      // Buscar produtos da coleção Pijamas Femininos
      _fetchPijamasFemininosProducts();
      // Buscar produtos da segunda coleção (453168070934)
      _fetchSecondCollectionProducts();
      // Buscar produtos da colecao Pijamas Meninos (453166235926)
      _fetchBoysCollectionProducts();
      // Buscar produtos da colecao Pijamas Meninas (435358957846)
      _fetchGirlsCollectionProducts();
      // Buscar metafields da loja (banner)
      _fetchShopMetafields();
      // Buscar avaliações reais
      _fetchReviews();
    });
  }

  Future<void> _fetchReviews() async {
    try {
      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/reviews');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['reviews'] ?? [];
        if (mounted) {
          setState(() {
            _reviews = list.map((r) {
              return ReviewModel(
                name: r['author'] ?? r['handle'] ?? 'Cliente',
                rating: (r['stars'] ?? 5) as int,
                text: r['comment'] ?? r['title'] ?? '',
                imageUrl: r['photoUrl'] ?? '',
                date: DateFormatter.formatBrazilian(r['date']),
              );
            }).where((r) => r.imageUrl.isNotEmpty).toList();
            _isLoadingReviews = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingReviews = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _fetchPijamasFemininosProducts() async {
    setState(() {
      _isLoadingPijamasFemininos = true;
    });

    try {
      final queryParams = {
        'collectionGid': 'gid://shopify/Collection/435290702102',
        'first': '10',
      };

      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/collection-products')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        
        setState(() {
          _pijamasFemininosProducts = products;
          _isLoadingPijamasFemininos = false;
        });
      } else {
        setState(() {
          _isLoadingPijamasFemininos = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPijamasFemininos = false;
      });
    }
  }

  Future<void> _fetchSecondCollectionProducts() async {
    setState(() {
      _isLoadingSecondCollection = true;
    });

    try {
      final queryParams = {
        'collectionGid': 'gid://shopify/Collection/453168070934',
        'first': '4',
      };

      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/collection-products')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        
        setState(() {
          _secondCollectionProducts = products;
          _isLoadingSecondCollection = false;
        });
      } else {
        setState(() {
          _isLoadingSecondCollection = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSecondCollection = false;
      });
    }
  }

  Future<void> _fetchBoysCollectionProducts() async {
    setState(() {
      _isLoadingBoysCollection = true;
    });

    try {
      final queryParams = {
        'collectionGid': 'gid://shopify/Collection/453166235926',
        'first': '4',
      };

      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/collection-products')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();

        setState(() {
          _boysCollectionProducts = products;
          _isLoadingBoysCollection = false;
        });
      } else {
        setState(() {
          _isLoadingBoysCollection = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBoysCollection = false;
      });
    }
  }

  Future<void> _fetchGirlsCollectionProducts() async {
    setState(() {
      _isLoadingGirlsCollection = true;
    });

    try {
      final queryParams = {
        'collectionGid': 'gid://shopify/Collection/435358957846',
        'first': '4',
      };

      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/collection-products')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();

        setState(() {
          _girlsCollectionProducts = products;
          _isLoadingGirlsCollection = false;
        });
      } else {
        setState(() {
          _isLoadingGirlsCollection = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingGirlsCollection = false;
      });
    }
  }

  Future<void> _fetchShopMetafields() async {
    try {
      final uri = Uri.parse('${ApiConstants.apiUrl}/shopify/shop-metafields');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bannerHomeMobileUrl = data['bannerHomeMobile'];
        });
      }
    } catch (e) {
      print('Error fetching shop metafields: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildTopBar(),
        _buildHeader(),
        _buildCircularCategories(),
        _buildHeroBanner(),
        _buildBenefits(),
        _buildLaunchesSection(),
        _buildBoysCollectionSection(),
        _buildGirlsCollectionSection(),
        _buildSecondCollectionSection(),
        _buildReviewsSection(),
        _buildFooterPlaceholder(),
      ],
    );
  }

  // Top Bar
  Widget _buildTopBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: const Text(
          'Troca gratis por qualquer motivo em ate 7 dias',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://www.ciadamalha.com.br/cdn/shop/files/logo-horizontal-cia-da-malha-pijamas-completa.png?v=1692659015&width=180',
              height: 32,
              memCacheWidth: 360,
              errorWidget: (context, url, error) {
                return const Text(
                  'cia da malha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                );
              },
            ),
            Row(
              children: [
                _buildCartButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final itemCount = cartProvider.itemCount;

        return GestureDetector(
          onTap: widget.onNavigateToCart,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.black54),
                ),
                if (itemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1054ff),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Circular Categories - Stories Collections
  Widget _buildCircularCategories() {
    return Consumer<CollectionProvider>(
      builder: (context, collectionProvider, _) {
        final collections = collectionProvider.storiesCollections;
        
        if (collectionProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (collections.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110, // Altura reduzida para círculos menores
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      return _StoryItem(
                        collection: collection,
                        onTap: () {
                          widget.onNavigateToCatalog?.call(
                            collection.gid,
                            collection.name,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hero Banner
  Widget _buildHeroBanner() {
    // Se houver banner personalizado da Shopify, exibi-lo
    if (_bannerHomeMobileUrl != null && _bannerHomeMobileUrl!.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: _bannerHomeMobileUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultBanner(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Banner padrão
    return _buildDefaultBanner();
  }

  Widget _buildDefaultBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/bannerMobile1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback para banner gradiente caso a imagem não carregue
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Banner não disponível',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Benefits
  Widget _buildBenefits() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: FreteCarousel(),
      ),
    );
  }

  // Launches Section
  Widget _buildLaunchesSection() {
    if (_isLoadingPijamasFemininos) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 480,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Expandir produtos por variação de cor e pegar os primeiros 8
    final expandedProducts = _expandProductsByColorVariants(_pijamasFemininosProducts);
    final products = expandedProducts.take(8).toList();

        if (products.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pijamas Femininos',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onNavigateToCatalog?.call(
                          'gid://shopify/Collection/435290702102',
                          'Pijamas Femininos',
                        );
                      },
                      child: const Text(
                        'Ver Tudo',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 385,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      key: ValueKey('home-launch-${product.id}-$index'),
                      padding: EdgeInsets.only(
                        right: index < products.length - 1 ? 16 : 0,
                      ),
                      child: GestureDetector(
                          onTap: () {
                            final colorMap = _getProductColorMap(product);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: product,
                                  initialColor: colorMap.isNotEmpty ? colorMap.keys.first : null,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 214,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do produto (3:4 aspect ratio)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: product.images.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _optimizedShopifyImageUrl(
                                            product.images.first.url,
                                            width: 428,
                                            height: 570,
                                          ),
                                          height: 285,
                                          width: 214,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 428,
                                          memCacheHeight: 570,
                                          maxWidthDiskCache: 428,
                                          maxHeightDiskCache: 570,
                                          fadeInDuration: Duration.zero,
                                          fadeOutDuration: Duration.zero,
                                          placeholderFadeInDuration: Duration.zero,
                                          placeholder: (context, url) => Container(
                                            height: 285,
                                            width: 214,
                                            color: Colors.grey[100],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            return Container(
                                              height: 285,
                                              width: 214,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 50),
                                            );
                                          },
                                        )
                                      : Container(
                                          height: 285,
                                          width: 214,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 50),
                                        ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              PriceFormatter.formatWithCurrency(product.price),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            if (product.compareAtPrice != null &&
                                                product.compareAtPrice! > product.price) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF999999),
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          '6x sem juros',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 18,
                                          child: Row(
                                            children: [
                                              ..._getProductColorMap(product).entries.take(3).map((entry) {
                                                final colorName = entry.key;
                                                final color = entry.value;
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => ProductDetailScreen(
                                                          product: product,
                                                          initialColor: colorName,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    margin: const EdgeInsets.only(right: 4),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 1.5),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.1),
                                                          blurRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                              if (_getProductColorMap(product).length > 3)
                                                const Text(
                                                  '+',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
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

  // Segunda seção de produtos (Collection 453168070934)
  Widget _buildSecondCollectionSection() {
    if (_isLoadingSecondCollection) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 480,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Expandir produtos por variação de cor e pegar os primeiros 8
    final expandedProducts = _expandProductsByColorVariants(_secondCollectionProducts);
    final products = expandedProducts.take(8).toList();

    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pijamas Masculinos',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onNavigateToCatalog?.call(
                      'gid://shopify/Collection/453168070934',
                      'Pijamas Masculinos',
                    );
                  },
                  child: const Text(
                    'Ver Tudo',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 385,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              padding: const EdgeInsets.only(left: 16, right: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  key: ValueKey('home-news-${product.id}-$index'),
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 16 : 0,
                  ),
                  child: GestureDetector(
                      onTap: () {
                        final colorMap = _getProductColorMap(product);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: product,
                              initialColor: colorMap.isNotEmpty ? colorMap.keys.first : null,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 214,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagem do produto (3:4 aspect ratio)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: product.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _optimizedShopifyImageUrl(
                                        product.images.first.url,
                                        width: 428,
                                        height: 570,
                                      ),
                                      height: 285,
                                      width: 214,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 428,
                                      memCacheHeight: 570,
                                      maxWidthDiskCache: 428,
                                      maxHeightDiskCache: 570,
                                      fadeInDuration: Duration.zero,
                                      fadeOutDuration: Duration.zero,
                                      placeholderFadeInDuration: Duration.zero,
                                      placeholder: (context, url) => Container(
                                        height: 285,
                                        width: 214,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          height: 285,
                                          width: 214,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 50),
                                        );
                                      },
                                    )
                                  : Container(
                                      height: 285,
                                      width: 214,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, size: 50),
                                    ),
                            ),
                            Padding(
                                padding: const EdgeInsets.all(7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          PriceFormatter.formatWithCurrency(product.price),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        if (product.compareAtPrice != null &&
                                            product.compareAtPrice! > product.price) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF999999),
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '6x sem juros',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 18,
                                      child: Row(
                                        children: [
                                          ..._getProductColorMap(product).entries.take(3).map((entry) {
                                            final colorName = entry.key;
                                            final color = entry.value;
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => ProductDetailScreen(
                                                      product: product,
                                                      initialColor: colorName,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(right: 4),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                          if (_getProductColorMap(product).length > 3)
                                            const Text(
                                              '+',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  // Pijamas Meninos (Collection 453166235926)
  Widget _buildBoysCollectionSection() {
    if (_isLoadingBoysCollection) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 480,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Expandir produtos por variação de cor e pegar os primeiros 8
    final expandedProducts = _expandProductsByColorVariants(_boysCollectionProducts);
    final products = expandedProducts.take(8).toList();

    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pijamas Meninos',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onNavigateToCatalog?.call(
                      'gid://shopify/Collection/453166235926',
                      'Pijamas Meninos',
                    );
                  },
                  child: const Text(
                    'Ver Tudo',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 385,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              padding: const EdgeInsets.only(left: 16, right: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  key: ValueKey('home-boys-${product.id}-$index'),
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 16 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      final colorMap = _getProductColorMap(product);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                            initialColor: colorMap.isNotEmpty ? colorMap.keys.first : null,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 214,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagem do produto (3:4 aspect ratio)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: product.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _optimizedShopifyImageUrl(
                                      product.images.first.url,
                                      width: 428,
                                      height: 570,
                                    ),
                                    height: 285,
                                    width: 214,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 428,
                                    memCacheHeight: 570,
                                    maxWidthDiskCache: 428,
                                    maxHeightDiskCache: 570,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholderFadeInDuration: Duration.zero,
                                    placeholder: (context, url) => Container(
                                      height: 285,
                                      width: 214,
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Container(
                                        height: 285,
                                        width: 214,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 50),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 285,
                                    width: 214,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 50),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      PriceFormatter.formatWithCurrency(product.price),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    if (product.compareAtPrice != null &&
                                        product.compareAtPrice! > product.price) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF999999),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    ..._getProductColors(product)
                                        .take(3)
                                        .map((color) {
                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    if (_getProductColorMap(product).length > 3)
                                      const Text(
                                        '+',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF666666),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Pijamas Meninas (Collection 435358957846)
  Widget _buildGirlsCollectionSection() {
    if (_isLoadingGirlsCollection) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 480,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Expandir produtos por variação de cor e pegar os primeiros 8
    final expandedProducts = _expandProductsByColorVariants(_girlsCollectionProducts);
    final products = expandedProducts.take(8).toList();

    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pijamas Meninas',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onNavigateToCatalog?.call(
                      'gid://shopify/Collection/435358957846',
                      'Pijamas Meninas',
                    );
                  },
                  child: const Text(
                    'Ver Tudo',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 385,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              padding: const EdgeInsets.only(left: 16, right: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  key: ValueKey('home-girls-${product.id}-$index'),
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 16 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      final colorMap = _getProductColorMap(product);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                            initialColor: colorMap.isNotEmpty ? colorMap.keys.first : null,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 214,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagem do produto (3:4 aspect ratio)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: product.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _optimizedShopifyImageUrl(
                                      product.images.first.url,
                                      width: 428,
                                      height: 570,
                                    ),
                                    height: 285,
                                    width: 214,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 428,
                                    memCacheHeight: 570,
                                    maxWidthDiskCache: 428,
                                    maxHeightDiskCache: 570,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholderFadeInDuration: Duration.zero,
                                    placeholder: (context, url) => Container(
                                      height: 285,
                                      width: 214,
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Container(
                                        height: 285,
                                        width: 214,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 50),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 285,
                                    width: 214,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 50),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      PriceFormatter.formatWithCurrency(product.price),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    if (product.compareAtPrice != null &&
                                        product.compareAtPrice! > product.price) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF999999),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    ..._getProductColors(product)
                                        .take(3)
                                        .map((color) {
                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    if (_getProductColorMap(product).length > 3)
                                      const Text(
                                        '+',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF666666),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Expande produtos por variações de cor
  /// Cada cor única vira um "produto" separado para melhor navegação
  List<Product> _expandProductsByColorVariants(List<Product> products) {
    final expandedProducts = <Product>[];
    for (final product in products) {
      final variants = product.variants ?? [];
      // Agrupar variantes por cor
      final colorVariants = <String, List<ProductVariant>>{};
      for (final variant in variants) {
        final color = variant.color?.trim().toUpperCase();
        if (color != null && color.isNotEmpty) {
          colorVariants.putIfAbsent(color, () => <ProductVariant>[]).add(variant);
        }
      }

      // Se tem múltiplas cores, criar um produto para cada
      if (colorVariants.length > 1) {
        for (final entry in colorVariants.entries) {
          final color = entry.key;
          final variantsForColor = entry.value;
          final variantWithImage = variantsForColor.firstWhere(
            (variant) => variant.image != null && variant.image!.trim().isNotEmpty,
            orElse: () => variantsForColor.first,
          );
          final variantImage = variantWithImage.image;

          List<ProductImage> newImages = [...product.images];
          String? coverImageUrl = variantImage;

          // Fallback: busca imagem pelo altText da cor quando a variante não traz imagem
          if (coverImageUrl == null || coverImageUrl.trim().isEmpty) {
            final imageByAlt = product.images.cast<ProductImage?>().firstWhere(
              (img) => img != null && _matchesColorAltText(img.altText, color),
              orElse: () => null,
            );
            coverImageUrl = imageByAlt?.url;
          }

          if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty) {
            final normalizedCover = _normalizeImageUrl(coverImageUrl);
            final imgIndex = newImages.indexWhere((img) => _normalizeImageUrl(img.url) == normalizedCover);
            if (imgIndex != -1) {
              final img = newImages.removeAt(imgIndex);
              newImages.insert(0, img);
            } else {
              newImages.insert(0, ProductImage(url: coverImageUrl, altText: 'Cor_$color'));
            }
          }

          expandedProducts.add(product.copyWith(images: newImages));
        }
      } else {
        expandedProducts.add(product);
      }
    }
    return expandedProducts;
  }

  List<Color> _getProductColors(Product product) {
    final variants = product.variants ?? [];
    final uniqueColors = <String>{};
    for (final variant in variants) {
      final color = variant.color;
      if (color != null && color.trim().isNotEmpty) {
        uniqueColors.add(color.trim().toUpperCase());
      }
    }

    if (uniqueColors.isEmpty) {
      return [const Color(0xFFE0E0E0)];
    }

    return uniqueColors.map(_colorFromName).toList();
  }

  /// Retorna um mapa de nome da cor (original) para Color (Flutter)
  Map<String, Color> _getProductColorMap(Product product) {
    final variants = product.variants ?? [];
    final colorMap = <String, Color>{};
    
    for (final variant in variants) {
      final color = variant.color;
      if (color != null && color.trim().isNotEmpty) {
        final colorKey = color.trim().toUpperCase();
        if (!colorMap.containsKey(colorKey)) {
          colorMap[colorKey] = _colorFromName(colorKey);
        }
      }
    }

    if (colorMap.isEmpty) {
      return {'DEFAULT': const Color(0xFFE0E0E0)};
    }

    return colorMap;
  }

  Color _colorFromName(String name) {
    if (name.contains('PRETO')) return const Color(0xFF1F2937);
    if (name.contains('BRANCO')) return const Color(0xFFFFFFFF);
    if (name.contains('AZUL')) return const Color(0xFF2563EB);
    if (name.contains('VERDE')) return const Color(0xFF10B981);
    if (name.contains('VERMELHO')) return const Color(0xFFEF4444);
    if (name.contains('ROSA') || name.contains('PINK')) return const Color(0xFFF472B6);
    if (name.contains('LILAS') || name.contains('ROXO')) return const Color(0xFF8B5CF6);
    if (name.contains('AMARELO')) return const Color(0xFFF59E0B);
    if (name.contains('BEGE') || name.contains('CREME')) return const Color(0xFFF5DEB3);
    if (name.contains('CINZA') || name.contains('MESCLA')) return const Color(0xFF9CA3AF);
    if (name.contains('MARINHO')) return const Color(0xFF0F172A);
    return const Color(0xFFE0E0E0);
  }

  // Reviews Section
  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
      );
    }

    if (_reviews.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: ReviewsWidget(reviews: _reviews),
    );
  }

  // Footer Placeholder
  Widget _buildFooterPlaceholder() {
    return const SliverToBoxAdapter(
      child: SizedBox(height: 40),
    );
  }
}

// Widget de um item individual de Story (Foto + Nome da Categoria)
class _StoryItem extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const _StoryItem({
    Key? key,
    required this.collection,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tamanhos reduzidos para mostrar 4 stories por slide
    const double outerCircleSize = 75.0;
    const double whiteBorderCircleSize = 71.0;
    const double imageCircleSize = 68.0;
    const double textContainerWidth = 80.0;
    const double errorIconSize = 35.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          // Área da foto circular com feedback ao clique e borda gradiente
          SizedBox(
            width: outerCircleSize, // Tamanho total do círculo (imagem + bordas)
            height: outerCircleSize,
            child: Material(
              color: Colors.transparent, // Permite que o ripple do InkWell seja visível sobre o gradiente
              shape: const CircleBorder(), // Define o formato do Material como circular para o splash
              clipBehavior: Clip.antiAlias, // Garante que o splash seja cortado para o círculo
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Camada externa: o gradiente colorido
                    Container(
                      width: outerCircleSize,
                      height: outerCircleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF833AB4), // Instagram-like purple
                            Color(0xFFFD1D1D), // Instagram-like red
                            Color(0xFFFCB045), // Instagram-like orange
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                    // Camada do meio: um círculo branco para criar a "borda" interna
                    Container(
                      width: whiteBorderCircleSize,
                      height: whiteBorderCircleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white, // Cor da borda interna
                      ),
                    ),
                    // Camada interna: a imagem do story
                    Container(
                      width: imageCircleSize,
                      height: imageCircleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        // ClipOval para garantir que a imagem seja circular
                        child: collection.image != null
                            ? CachedNetworkImage(
                                imageUrl: collection.image!,
                                fit: BoxFit.cover,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Icon(
                                    Icons.broken_image,
                                    size: errorIconSize,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : Icon(
                                Icons.image,
                                size: errorIconSize,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4), // Espaçamento entre a imagem e o texto
          // Nome da categoria
          SizedBox(
            width: textContainerWidth, // Largura para o texto (um pouco maior que a imagem)
            child: Text(
              collection.name,
              textAlign: TextAlign.center,
              maxLines: 1, // Limita o texto a uma linha
              overflow: TextOverflow.ellipsis, // Adiciona "..." se o texto for muito longo
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
