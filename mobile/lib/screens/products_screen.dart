import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'product_detail_screen.dart';
import '../utils/price_formatter.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback? onNavigateToCart;
  final String? collectionGid;
  final String? collectionName;
  
  const CatalogScreen({
    Key? key,
    this.onBackToHome,
    this.onNavigateToCart,
    this.collectionGid,
    this.collectionName,
  }) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final ScrollController _scrollController;
  String selectedCategory = 'todos';
  bool showFilters = false;
  String viewType = 'grid';
  String sortBy = 'relevancia';
  RangeValues priceRange = const RangeValues(0, 300);
  Set<String> selectedSizes = {};
  bool showSortMenu = false;
  String searchQuery = '';

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

  final List<String> categories = [
    'todos',
    'pijamas',
    'vestidos',
    'blusas',
    'kigurumi',
    'infantil',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, () {
      if (widget.collectionGid != null) {
        // Quando há collection, não passa sortKey para manter ordem da Shopify
        context.read<ProductProvider>().fetchProducts(
          collectionGid: widget.collectionGid,
          first: 20,
        );
      } else {
        context.read<ProductProvider>().fetchProducts(first: 20, sortKey: 'BEST_SELLING');
      }
    });
  }

  @override
  void didUpdateWidget(CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega produtos quando collectionGid muda
    if (oldWidget.collectionGid != widget.collectionGid) {
      if (widget.collectionGid != null) {
        // Quando há collection, não passa sortKey para manter ordem da Shopify
        context.read<ProductProvider>().fetchProducts(
          collectionGid: widget.collectionGid,
          first: 20,
        );
      } else {
        context.read<ProductProvider>().fetchProducts(first: 20, sortKey: 'BEST_SELLING');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // Quando há collection, não passa sortKey para manter ordem da Shopify
      if (widget.collectionGid != null) {
        context.read<ProductProvider>().fetchMoreProducts(first: 20);
      } else {
        context.read<ProductProvider>().fetchMoreProducts(first: 20, sortKey: 'BEST_SELLING');
      }
    }
  }

  List<Product> getFilteredAndSortedProducts(List<Product> products) {
    // Primeiro expandir produtos por variações de cor
    final expandedProducts = _expandProductsByColorVariants(products);
    
    final filtered = expandedProducts.where((p) {
      final categoryMatch = selectedCategory == 'todos' ||
          p.title.toLowerCase().contains(selectedCategory.toLowerCase());
      final priceMatch = p.price >= priceRange.start && p.price <= priceRange.end;
      final searchMatch = searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase());
      final sizeMatch = selectedSizes.isEmpty ||
          (p.variants ?? []).any((v) =>
              v.size != null && selectedSizes.contains(v.size!.toUpperCase()));
      return categoryMatch && priceMatch && searchMatch && sizeMatch;
    }).toList();

    filtered.sort((a, b) {
      switch (sortBy) {
        case 'preco-crescente':
          return a.price.compareTo(b.price);
        case 'preco-decrescente':
          return b.price.compareTo(a.price);
        case 'novos':
          return b.id.compareTo(a.id);
        case 'promocoes':
          return (_hasPromotion(b) ? 1 : 0)
              .compareTo(_hasPromotion(a) ? 1 : 0);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1054ff)),
            ),
          );
        }

        if (productProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  productProvider.errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF656362),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProductProvider>().fetchProducts(
                          first: 20,
                          sortKey: 'BEST_SELLING',
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1054ff),
                  ),
                  child: const Text(
                    'Tentar Novamente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfceed4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final products = productProvider.products;
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum produto disponivel',
              style: TextStyle(fontSize: 14, color: Color(0xFF656362)),
            ),
          );
        }

        final filteredProducts = getFilteredAndSortedProducts(products);

        final maxPrice = products.fold<double>(
          0,
          (acc, p) => p.price > acc ? p.price : acc,
        );
        final double sliderMax = maxPrice > 0 ? maxPrice : 300.0;
        final clampedRange = RangeValues(
          priceRange.start.clamp(0.0, sliderMax).toDouble(),
          priceRange.end.clamp(0.0, sliderMax).toDouble(),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 24),
                      color: const Color(0xFF2563EB),
                      onPressed: () {
                        if (widget.onBackToHome != null) {
                          widget.onBackToHome!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 12, right: 8),
                              child: Icon(Icons.search, size: 18, color: Color(0xFF999999)),
                            ),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Buscar...',
                                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  filled: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    _buildCartButton(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.replaceFirst(cat[0], cat[0].toUpperCase()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => showFilters = !showFilters),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 14),
                              SizedBox(width: 4),
                              Text('Filtros', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => showSortMenu = !showSortMenu),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.unfold_more, size: 14),
                              SizedBox(width: 4),
                              Text('Ordenar', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => viewType = 'grid'),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: viewType == 'grid'
                                ? Colors.white
                                : Colors.grey[100],
                            border: viewType == 'grid'
                                ? Border.all(color: const Color(0xFF2563EB))
                                : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.grid_3x3,
                            size: 16,
                            color: viewType == 'grid'
                                ? const Color(0xFF2563EB)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => viewType = 'list'),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: viewType == 'list'
                                ? Colors.white
                                : Colors.grey[100],
                            border: viewType == 'list'
                                ? Border.all(color: const Color(0xFF2563EB))
                                : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.list,
                            size: 16,
                            color: viewType == 'list'
                                ? const Color(0xFF2563EB)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showFilters)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preco',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: clampedRange,
                      min: 0,
                      max: sliderMax,
                      onChanged: (values) {
                        setState(() => priceRange = values);
                      },
                    ),
                    Text(
                      '${PriceFormatter.formatWithCurrency(clampedRange.start)} - ${PriceFormatter.formatWithCurrency(clampedRange.end)}',
                      style:
                          const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tamanho',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['P', 'M', 'G', 'GG', 'XG'].map((size) {
                        final isSelected = selectedSizes.contains(size);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedSizes.remove(size);
                              } else {
                                selectedSizes.add(size);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          if (showSortMenu)
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Column(
                  children: [
                    _buildSortOption('Relevancia', 'relevancia'),
                    _buildSortOption('Mais Novos', 'novos'),
                    _buildSortOption('Menor Preco', 'preco-crescente'),
                    _buildSortOption('Maior Preco', 'preco-decrescente'),
                    _buildSortOption('Em Promocao', 'promocoes'),
                  ],
                ),
              ),
            ),
          if (viewType == 'grid')
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filteredProducts.length) {
                      return const SizedBox();
                    }
                    final product = filteredProducts[index];
                    return KeyedSubtree(
                      key: ValueKey('catalog-grid-${product.id}-$index'),
                      child: _buildProductCard(product),
                    );
                  },
                  childCount: filteredProducts.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filteredProducts.length) {
                      return const SizedBox();
                    }
                    final product = filteredProducts[index];
                    return Padding(
                      key: ValueKey('catalog-list-${product.id}-$index'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductListItem(product),
                    );
                  },
                  childCount: filteredProducts.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          if (productProvider.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1054ff)),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
      },
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

  Widget _buildSortOption(String label, String value) {
    final isSelected = sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          sortBy = value;
          showSortMenu = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final colorMap = _getProductColorMap(product);
    final initialColor = _getInitialColorFromCoverImage(product);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
              initialColor: initialColor ?? (colorMap.isNotEmpty ? colorMap.keys.first : null),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                color: Colors.grey[100],
                child: Stack(
                  children: [
                    if (product.images.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: _optimizedShopifyImageUrl(
                          product.images.first.url,
                          width: 420,
                          height: 600,
                        ),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 420,
                        memCacheHeight: 600,
                        maxWidthDiskCache: 420,
                        maxHeightDiskCache: 600,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        placeholder: (context, url) => SizedBox.expand(
                          child: ColoredBox(
                            color: Color(0xFFFAFAFA),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return const Center(
                            child: Icon(Icons.image, size: 50, color: Colors.black26),
                          );
                        },
                      )
                    else
                      const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.black26),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, _) {
                          final coverImageUrl = product.images.isNotEmpty ? product.images.first.url : null;
                          final isLiked = favoritesProvider.isFavorite(
                            product: product,
                            selectedColor: initialColor,
                            coverImageUrl: coverImageUrl,
                          );
                          return GestureDetector(
                            onTap: () => favoritesProvider.toggleFavorite(
                              product: product,
                              selectedColor: initialColor,
                              coverImageUrl: coverImageUrl,
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            PriceFormatter.formatWithCurrency(product.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_hasPromotion(product)) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF999999),
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '6x sem juros',
                      style: TextStyle(fontSize: 8, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          ...colorMap.entries.take(3).map((entry) {
                            final colorName = entry.key;
                            final color = entry.value;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: product,
                                      initialColor: colorName,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 14,
                                height: 14,
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
                          if (colorMap.length > 3)
                            const Text(
                              '+',
                              style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildProductListItem(Product product) {
    final initialColor = _getInitialColorFromCoverImage(product);
    final colorMap = _getProductColorMap(product);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (product.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _optimizedShopifyImageUrl(
                        product.images.first.url,
                        width: 200,
                        height: 200,
                      ),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      maxWidthDiskCache: 200,
                      maxHeightDiskCache: 200,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholderFadeInDuration: Duration.zero,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[50],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return const Center(
                          child: Icon(Icons.image, size: 40, color: Colors.black26),
                        );
                      },
                    ),
                  )
                else
                  const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.black26),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_hasPromotion(product))
                  Text(
                    PriceFormatter.formatWithCurrency(product.compareAtPrice!),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  PriceFormatter.formatWithCurrency(product.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 4,
                        children: colorMap.values.take(2).map((color) {
                          return Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          );
                        }).toList(),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, _) {
                          final coverImageUrl = product.images.isNotEmpty ? product.images.first.url : null;
                          final isLiked = favoritesProvider.isFavorite(
                            product: product,
                            selectedColor: initialColor,
                            coverImageUrl: coverImageUrl,
                          );
                          return GestureDetector(
                            onTap: () => favoritesProvider.toggleFavorite(
                              product: product,
                              selectedColor: initialColor,
                              coverImageUrl: coverImageUrl,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
          
          // Criar produto com a imagem da variante como primeira
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
            // Procurar a imagem correspondente na lista (normalizando URL para evitar falhas por query string)
            final normalizedCover = _normalizeImageUrl(coverImageUrl);
            final imgIndex = newImages.indexWhere((img) => _normalizeImageUrl(img.url) == normalizedCover);
            if (imgIndex != -1) {
              // Remover e colocar como primeira
              final img = newImages.removeAt(imgIndex);
              newImages.insert(0, img);
            } else {
              // Se não existir no array original, injeta como capa para garantir correspondência da cor
              newImages.insert(0, ProductImage(url: coverImageUrl, altText: 'Cor_$color'));
            }
          }
          
          expandedProducts.add(product.copyWith(images: newImages));
        }
      } else {
        // Se tem só uma cor ou nenhuma, adicionar o produto original
        expandedProducts.add(product);
      }
    }
    
    return expandedProducts;
  }

  String _normalizeImageUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url.trim().toLowerCase();

    final normalized = parsed.replace(query: null, fragment: null).toString();
    return normalized.trim().toLowerCase();
  }

  bool _matchesColorAltText(String? altText, String color) {
    if (altText == null || altText.trim().isEmpty) return false;

    final alt = altText.trim().toUpperCase();
    final colorNormalized = color.trim().toUpperCase();

    if (alt.contains('COR_')) {
      final colorPart = alt.split('COR_').last.replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final compactAlt = colorPart.replaceAll(' ', '');
      final compactColor = colorNormalized.replaceAll(' ', '');
      return compactAlt == compactColor || colorPart == colorNormalized;
    }

    return alt.contains(colorNormalized);
  }

  String? _getInitialColorFromCoverImage(Product product) {
    if (product.images.isEmpty) return null;

    final coverUrl = _normalizeImageUrl(product.images.first.url);
    final variants = product.variants ?? [];

    for (final variant in variants) {
      final color = variant.color?.trim().toUpperCase();
      final image = variant.image;
      if (color == null || color.isEmpty || image == null || image.trim().isEmpty) {
        continue;
      }

      if (_normalizeImageUrl(image) == coverUrl) {
        return color;
      }
    }

    final altText = product.images.first.altText;
    if (altText != null && altText.trim().isNotEmpty) {
      final byAlt = variants.firstWhere(
        (variant) => variant.color != null && _matchesColorAltText(altText, variant.color!.trim().toUpperCase()),
        orElse: () => ProductVariant(id: 0, sku: '', stock: 0),
      );
      if (byAlt.color != null && byAlt.color!.trim().isNotEmpty) {
        return byAlt.color!.trim().toUpperCase();
      }
    }

    return null;
  }

  bool _hasPromotion(Product product) {
    final compareAtPrice = product.compareAtPrice;
    return compareAtPrice != null && compareAtPrice > product.price;
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
    return const Color(0xFFCBD5F5);
  }
}
