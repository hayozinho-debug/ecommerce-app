import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../constants/app_constants.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/product_provider.dart';
import '../providers/recently_viewed_provider.dart';
import 'cart_screen.dart';
import '../widgets/size_chart_button.dart';
import '../widgets/coupon_banner.dart';
import '../widgets/add_to_cart_popup.dart';
import '../widgets/price_widget.dart';
import '../widgets/cia_add_to_cart_fab.dart';
import '../widgets/pdp_image_slider.dart';
import '../utils/price_formatter.dart';
import '../utils/date_formatter.dart';

// Badge de desconto para seletor de cor
class DiscountBadge extends StatelessWidget {
  final int percent;
  const DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF00B96B),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B96B).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? initialColor;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    this.initialColor,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // ...existing code...
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  String? _selectedColor;
  String? _selectedSize;
  bool _showAllReviews = false;
  List<Map<String, dynamic>>? _productReviews;
  bool _loadingReviews = true;
  final PageController _contentPageController = PageController();
  int _currentContentPage = 0;

  void _goToCartScreen() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  final List<Map<String, dynamic>> _mockReviews = [
    {
      'author': 'Maria Silva',
      'rating': 5,
      'date': '15/01/2024',
      'comment': 'Produto excelente! Qualidade impecável e caiu perfeitamente.',
    },
    {
      'author': 'João Santos',
      'rating': 5,
      'date': '10/01/2024',
      'comment': 'Muito satisfeito com a compra. Entrega rápida.',
    },
    {
      'author': 'Ana Costa',
      'rating': 4,
      'date': '05/01/2024',
      'comment': 'Bonito e confortável. Recomendo!',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Track product view
    Future.microtask(() {
      context.read<RecentlyViewedProvider>().addProduct(widget.product);
    });
    
    // Fetch product reviews from AvaliacoesProduto metafield
    _fetchProductReviews();
    
    // Pré-seleciona a cor inicial se foi passada
    if (widget.initialColor != null) {
      // Normaliza a cor para uppercase para consistência
      _selectedColor = widget.initialColor!.trim().toUpperCase();
      // Auto-seleciona o primeiro tamanho disponível para esta cor
      final firstSize = _getFirstAvailableSizeForColor(_selectedColor!);
      if (firstSize != null) {
        _selectedSize = firstSize;
        _updateSelectedVariant();
      }
    }
  }

  Future<void> _fetchProductReviews() async {
    if (!mounted) return;
    
    setState(() {
      _loadingReviews = true;
    });

    try {
      final productGid = 'gid://shopify/Product/${widget.product.id}';
      final url = Uri.parse('${ApiConstants.apiUrl}/shopify/reviews?productGid=$productGid');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reviews = (data['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        // Filter only reviews with photos
        final reviewsWithPhotos = reviews.where((review) => 
          review['photoUrl'] != null && review['photoUrl'].toString().isNotEmpty
        ).toList();
        
        if (mounted) {
          setState(() {
            _productReviews = reviewsWithPhotos.isNotEmpty ? reviewsWithPhotos : null;
            _loadingReviews = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _productReviews = null;
            _loadingReviews = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching product reviews: $e');
      if (mounted) {
        setState(() {
          _productReviews = null;
          _loadingReviews = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentPageController.dispose();
    super.dispose();
  }

  void _updateSelectedVariant() {
    if (widget.product.variants == null || widget.product.variants!.isEmpty) return;
    
    ProductVariant? variant = widget.product.variants!.firstWhere(
      (v) {
        final colorMatch = _selectedColor == null || (v.color != null && v.color!.trim().toUpperCase() == _selectedColor);
        final sizeMatch = _selectedSize == null || v.size == _selectedSize;
        return colorMatch && sizeMatch;
      },
      orElse: () => widget.product.variants!.first,
    );
    
    setState(() {
      _selectedVariant = variant;
    });
  }

  // Normaliza texto para matching: remove acentos, pontuação, converte para lowercase
  String _normalizeForMatching(String text) {
    String normalized = text.toLowerCase().trim();
    
    // Remove acentos
    const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < withAccents.length; i++) {
      normalized = normalized.replaceAll(withAccents[i], withoutAccents[i]);
    }
    
    // Remove pontuação e caracteres especiais, mantém apenas letras e números
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), ' ');
    
    // Remove espaços múltiplos
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }
  
  // Extrai tokens de texto relevantes para matching
  List<String> _extractTokens(String text) {
    final normalized = _normalizeForMatching(text);
    final tokens = normalized.split(' ').where((t) => t.isNotEmpty).toList();
    
    // Remove tokens muito curtos (menos de 2 caracteres) que podem gerar false positives
    return tokens.where((t) => t.length >= 2).toList();
  }
  
  // Verifica se há match entre cor e altText usando tokens
  bool _matchesColor(String altText, String color) {
    final altNormalized = _normalizeForMatching(altText);
    final colorNormalized = _normalizeForMatching(color);
    
    // 1. Match exato completo (mais prioritário)
    if (altNormalized == colorNormalized) return true;
    
    // 2. Match exato sem espaços
    final colorNoSpaces = colorNormalized.replaceAll(' ', '');
    final altNoSpaces = altNormalized.replaceAll(' ', '');
    if (altNoSpaces == colorNoSpaces) return true;
    
    // 3. Verifica se tem o padrão "cor_" ou "cor " ou "color_" ou "color "
    final hasColorPrefix = altNormalized.contains('cor ') || 
                          altNormalized.contains('cor_') ||
                          altNormalized.contains('color ') ||
                          altNormalized.contains('color_');
    
    if (hasColorPrefix) {
      // Extrai a parte depois de "cor" ou "color"
      String colorPart = '';
      if (altNormalized.contains('cor_')) {
        colorPart = altNormalized.split('cor_').last.split('_').first.trim();
      } else if (altNormalized.contains('cor ')) {
        final parts = altNormalized.split('cor ').last.split(' ');
        colorPart = parts.isNotEmpty ? parts.first.trim() : '';
      } else if (altNormalized.contains('color_')) {
        colorPart = altNormalized.split('color_').last.split('_').first.trim();
      } else if (altNormalized.contains('color ')) {
        final parts = altNormalized.split('color ').last.split(' ');
        colorPart = parts.isNotEmpty ? parts.first.trim() : '';
      }
      
      // Para formato "Cor_Nome_Sobrenome", pega tudo entre "Cor_" e o fim ou próximo separador
      if (altNormalized.contains('cor_') || altNormalized.contains('color_')) {
        String fullColorPart = '';
        if (altNormalized.contains('cor_')) {
          fullColorPart = altNormalized.split('cor_').last.trim();
        } else {
          fullColorPart = altNormalized.split('color_').last.trim();
        }
        
        // Remove underscores e hífens para comparação
        fullColorPart = fullColorPart.replaceAll('_', ' ').replaceAll('-', ' ').trim();
        final fullColorPartClean = fullColorPart.replaceAll(' ', '');
        final colorClean = colorNormalized.replaceAll(' ', '');
        
        // Match exato da parte completa após "Cor_" (sem espaços)
        if (fullColorPartClean == colorClean) return true;
        
        // Match exato com espaços
        if (fullColorPart == colorNormalized) return true;
        
        // Verifica match exato de tokens (MESMA QUANTIDADE e TODOS iguais)
        final colorTokens = _extractTokens(color);
        final fullColorPartTokens = _extractTokens(fullColorPart);
        
        // SÓ faz match se tiver EXATAMENTE a mesma quantidade de tokens
        if (colorTokens.length == fullColorPartTokens.length && colorTokens.isNotEmpty) {
          bool allTokensMatch = true;
          for (int i = 0; i < colorTokens.length; i++) {
            if (colorTokens[i] != fullColorPartTokens[i]) {
              allTokensMatch = false;
              break;
            }
          }
          if (allTokensMatch) return true;
        }
      }
    }
    
    return false;
  }

  List<ProductImage> _getAvailableImages() {
    if (widget.product.images.isEmpty) {
      return [];
    }

    // Se não houver cor selecionada, retorna todas as imagens
    if (_selectedColor == null) {
      return widget.product.images;
    }

    // Coletar todas as imagens da cor selecionada
    final colorImages = <ProductImage>[];
    final seenUrls = <String>{}; // Para evitar duplicatas
    
    // 1. Buscar imagens das variantes da mesma cor
    if (widget.product.variants != null) {
      // Pega todas as variantes que têm a cor selecionada
      final variantsOfColor = widget.product.variants!.where((v) => 
        v.color != null && v.color!.trim().toUpperCase() == _selectedColor
      ).toList();
      
      // Coleta as imagens dessas variantes
      for (var variant in variantsOfColor) {
        if (variant.image != null && variant.image!.isNotEmpty) {
          if (!seenUrls.contains(variant.image)) {
            seenUrls.add(variant.image!);
            colorImages.add(ProductImage(
              url: variant.image!,
              altText: 'Cor_${_selectedColor}',
            ));
          }
        }
      }
    }
    
    // 2. Buscar imagens do produto principal que correspondem à cor pelo altText
    final filteredImages = widget.product.images.where((img) {
      if (img.altText == null || img.altText!.isEmpty) return false;
      if (seenUrls.contains(img.url)) return false; // Evita duplicatas
      return _matchesColor(img.altText!, _selectedColor!);
    }).toList();
    
    // Adiciona as imagens filtradas sem duplicatas
    for (var img in filteredImages) {
      if (!seenUrls.contains(img.url)) {
        seenUrls.add(img.url);
        colorImages.add(img);
      }
    }

    // Se encontrou imagens da cor, retorna o grupo completo
    // Caso contrário, retorna todas as imagens
    return colorImages.isNotEmpty ? colorImages : widget.product.images;
  }

  List<String> _getAvailableSizes() {
    if (widget.product.variants == null) return [];
    return widget.product.variants!
        .where((v) => v.size != null)
        .map((v) => v.size!)
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> _getAvailableColors() {
    if (widget.product.variants == null) return [];
    final colors = <String>{};
    final colorData = <Map<String, dynamic>>[];

    for (var variant in widget.product.variants!) {
      if (variant.color != null && variant.color!.trim().isNotEmpty) {
        // Normaliza a cor para uppercase para consistência
        final normalizedColor = variant.color!.trim().toUpperCase();
        
        if (!colors.contains(normalizedColor)) {
          colors.add(normalizedColor);

          // Busca a primeira imagem disponível para essa cor
          String? colorImage = variant.image;
          if (colorImage == null || colorImage.isEmpty) {
            final variantsOfSameColor = widget.product.variants!.where((v) =>
                v.color != null && v.color!.trim().toUpperCase() == normalizedColor && v.image != null && v.image!.isNotEmpty);
            if (variantsOfSameColor.isNotEmpty) {
              colorImage = variantsOfSameColor.first.image;
            }
          }
          if (colorImage == null || colorImage.isEmpty) {
            final matchingImage = widget.product.images.firstWhere(
              (img) => img.altText != null && _matchesColor(img.altText!, normalizedColor),
              orElse: () => widget.product.images.isNotEmpty ? widget.product.images.first : ProductImage(url: '', altText: null),
            );
            colorImage = matchingImage.url;
          }

          // Calcula o maior desconto entre as variantes dessa cor
          final variantsOfColor = widget.product.variants!.where((v) => 
              v.color != null && v.color!.trim().toUpperCase() == normalizedColor).toList();
          int maxDiscount = 0;
          for (var v in variantsOfColor) {
            if (v.compareAtPrice != null && v.price != null && v.compareAtPrice! > v.price!) {
              final percent = ((v.compareAtPrice! - v.price!) / v.compareAtPrice! * 100).round();
              if (percent > maxDiscount) maxDiscount = percent;
            }
          }

          colorData.add({
            'color': normalizedColor,
            'image': colorImage,
            'discount': maxDiscount,
          });
        }
      }
    }
    return colorData;
  }

  // Verifica se um tamanho tem estoque disponível
  bool _hasSizeStock(String size) {
    if (widget.product.variants == null) return false;
    
    // Se uma cor está selecionada, verifica estoque para aquela cor + tamanho
    if (_selectedColor != null) {
      return widget.product.variants!.any((v) => 
        v.size == size && v.color != null && v.color!.trim().toUpperCase() == _selectedColor && v.stock > 0
      );
    }
    
    // Se nenhuma cor está selecionada, verifica se o tamanho tem estoque em QUALQUER cor
    return widget.product.variants!.any((v) => 
      v.size == size && v.stock > 0
    );
  }

  // Verifica se uma cor tem estoque disponível
  bool _hasColorStock(String color) {
    if (widget.product.variants == null) return false;
    
    // Normaliza a cor para comparação
    final normalizedColor = color.trim().toUpperCase();
    // Verifica se existe QUALQUER tamanho disponível nessa cor
    return widget.product.variants!.any((v) => 
      v.color != null && v.color!.trim().toUpperCase() == normalizedColor && v.stock > 0
    );
  }
  
  // Retorna o primeiro tamanho disponível para uma cor específica
  // Retorna o primeiro tamanho disponível para uma cor específica
  String? _getFirstAvailableSizeForColor(String color) {
    if (widget.product.variants == null) return null;
    
    // Normaliza a cor para comparação
    final normalizedColor = color.trim().toUpperCase();
    final variantWithStock = widget.product.variants!.firstWhere(
      (v) => v.color != null && v.color!.trim().toUpperCase() == normalizedColor && v.stock > 0,
      orElse: () => widget.product.variants!.first,
    );
    
    return variantWithStock.stock > 0 ? variantWithStock.size : null;
  }
  
  // Retorna a quantidade em estoque de um tamanho específico
  int _getSizeStockQuantity(String size) {
    if (widget.product.variants == null) return 0;
    
    // Se uma cor está selecionada, retorna o estoque para aquela cor + tamanho
    if (_selectedColor != null) {
      final variant = widget.product.variants!.firstWhere(
        (v) => v.size == size && v.color != null && v.color!.trim().toUpperCase() == _selectedColor,
        orElse: () => widget.product.variants!.first,
      );
      return variant.stock;
    }
    
    // Se nenhuma cor está selecionada, retorna o maior estoque disponível desse tamanho
    final variantsWithSize = widget.product.variants!.where((v) => v.size == size).toList();
    if (variantsWithSize.isEmpty) return 0;
    
    return variantsWithSize.map((v) => v.stock).reduce((a, b) => a > b ? a : b);
  }

  // Verifica se a variante selecionada tem estoque
  bool _hasCurrentVariantStock() {
    // Se não tem variantes, produto tem estoque
    if (widget.product.variants == null || widget.product.variants!.isEmpty) {
      return true;
    }
    
    // Se tem variante selecionada, verifica o estoque dela
    if (_selectedVariant != null) {
      return _selectedVariant!.stock > 0;
    }
    
    // Se não selecionou ainda, verifica se há ALGUMA variante com estoque disponível
    return widget.product.variants!.any((v) => v.stock > 0);
  }

  // Retorna o preço atual baseado na variante selecionada
  double _getCurrentPrice() {
    if (_selectedVariant != null && _selectedVariant!.price != null) {
      return _selectedVariant!.price!;
    }
    return widget.product.price;
  }

  // Retorna o compareAtPrice atual baseado na variante selecionada
  double? _getCurrentCompareAtPrice() {
    if (_selectedVariant != null && _selectedVariant!.compareAtPrice != null) {
      return _selectedVariant!.compareAtPrice;
    }
    return widget.product.compareAtPrice;
  }

  void _showSizeGuide() {
    final hasTabelaMedida = widget.product.tabelaMedida != null && 
                            widget.product.tabelaMedida!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tabela de Medidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: hasTabelaMedida
                    ? CachedNetworkImage(
                        imageUrl: widget.product.tabelaMedida!,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Erro ao carregar tabela de medidas'),
                          ],
                        ),
                        fit: BoxFit.cover,
                      )
                    : Table(
                        border: TableBorder.all(color: Colors.grey[300]!),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[100]),
                            children: const [
                              _TableCell(text: 'Tamanho', isHeader: true),
                              _TableCell(text: 'Busto (cm)', isHeader: true),
                              _TableCell(text: 'Cintura (cm)', isHeader: true),
                              _TableCell(text: 'Quadril (cm)', isHeader: true),
                            ],
                          ),
                          const TableRow(
                            children: [
                              _TableCell(text: 'PP'),
                              _TableCell(text: '80-84'),
                              _TableCell(text: '60-64'),
                              _TableCell(text: '86-90'),
                            ],
                          ),
                          const TableRow(
                            children: [
                              _TableCell(text: 'P'),
                              _TableCell(text: '84-88'),
                              _TableCell(text: '64-68'),
                              _TableCell(text: '90-94'),
                            ],
                          ),
                          const TableRow(
                            children: [
                              _TableCell(text: 'M'),
                              _TableCell(text: '88-92'),
                              _TableCell(text: '68-72'),
                              _TableCell(text: '94-98'),
                            ],
                          ),
                          const TableRow(
                            children: [
                              _TableCell(text: 'G'),
                              _TableCell(text: '92-96'),
                              _TableCell(text: '72-76'),
                              _TableCell(text: '98-102'),
                            ],
                          ),
                          const TableRow(
                            children: [
                              _TableCell(text: 'GG'),
                              _TableCell(text: '96-100'),
                              _TableCell(text: '76-80'),
                              _TableCell(text: '102-106'),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _getAvailableImages();
    final sizes = _getAvailableSizes();
    final colors = _getAvailableColors();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildTopCartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coupon Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Center(
                      child: CouponBanner(
                        discount: '10% OFF',
                        label: 'Cupom',
                        subtitle: 'Primeira compra',
                        code: 'BEMVINDO',
                      ),
                    ),
                  ),
                  
                  // Title, Price and Reviews
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Text(
                          widget.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color(0xFF1054ff),
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_mockReviews.length} avaliações)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Image Carousel
                  if (images.isNotEmpty)
                    Stack(
                      children: [
                        PdpImageSlider(
                          key: ValueKey<String>(_selectedColor ?? 'all-colors'),
                          imageUrls: images.map((image) => image.url).toList(),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 84,
                          child: Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, _) {
                              final coverImageUrl = images.first.url;
                              final isFavorite = favoritesProvider.isFavorite(
                                product: widget.product,
                                selectedColor: _selectedColor,
                                coverImageUrl: coverImageUrl,
                              );

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => favoritesProvider.toggleFavorite(
                                    product: widget.product,
                                    selectedColor: _selectedColor,
                                    coverImageUrl: coverImageUrl,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : const Color(0xFF1054ff),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color Selection
                        if (colors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Selecione a Cor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 77,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(right: 50),
                              itemCount: colors.length,
                              itemBuilder: (context, index) {
                                final colorData = colors[index];
                                final color = colorData['color'] as String;
                                final image = colorData['image'] as String?;
                                final discount = colorData['discount'] as int;
                                final isSelected = _selectedColor == color;
                                final hasStock = _hasColorStock(color);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = color;
                                        
                                        // Se a cor não tem estoque no tamanho atual,
                                        // seleciona automaticamente um tamanho disponível
                                        if (_selectedSize != null && !_hasSizeStock(_selectedSize!)) {
                                          final availableSize = _getFirstAvailableSizeForColor(color);
                                          if (availableSize != null) {
                                            _selectedSize = availableSize;
                                          }
                                        }
                                        
                                        _updateSelectedVariant();
                                      });
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Opacity(
                                          opacity: hasStock ? 1.0 : 0.5,
                                          child: Container(
                                            width: 63,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: !hasStock
                                                    ? const Color(0xFFE0E0E8)
                                                    : isSelected
                                                        ? const Color(0xFF1054ff)
                                                        : const Color(0xFFCCCCDD),
                                                width: isSelected ? 3 : 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              color: !hasStock ? const Color(0xFFF4F4F6) : Colors.grey[100],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: image != null && image.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: image,
                                                      fit: BoxFit.cover,
                                                      memCacheWidth: 126,
                                                      memCacheHeight: 168,
                                                      placeholder: (context, url) => Container(
                                                        color: Colors.grey[100],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context, url, error) {
                                                        return Container(
                                                          color: Colors.grey[200],
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.image, size: 21),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                color,
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: Colors.grey[200],
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.image, size: 21, color: Colors.grey),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            color,
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.grey,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        if (!hasStock)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                              child: Center(
                                                child: Transform.rotate(
                                                  angle: -0.785398, // -45 degrees
                                                  child: Container(
                                                    width: 38,
                                                    height: 2,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFCCCCDD),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (discount > 0 && hasStock)
                                          Positioned(
                                            top: -14,
                                            right: -14,
                                            child: DiscountBadge(percent: discount),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        
                        // Size Selection
                        if (sizes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Selecione o Tamanho',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 58,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(right: 50),
                              itemCount: sizes.length,
                              itemBuilder: (context, index) {
                                final size = sizes[index];
                                final isSelected = _selectedSize == size;
                                final hasStock = _hasSizeStock(size);
                                final stockQuantity = _getSizeStockQuantity(size);
                                final isLowStock = hasStock && stockQuantity <= 10 && stockQuantity > 0;
                                final isWideSize = size.length > 2; // GG, XXG, XXXG, etc.
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: hasStock ? () {
                                      setState(() {
                                        _selectedSize = size;
                                        _updateSelectedVariant();
                                      });
                                    } : null,
                                    child: SizedBox(
                                      width: isWideSize ? 56 : 48,
                                      height: 58,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.topCenter,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            curve: Curves.easeInOut,
                                            width: isWideSize ? 56 : 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: !hasStock
                                                  ? const Color(0xFFF4F4F6)
                                                  : isSelected
                                                      ? const Color(0xFF1054ff)
                                                      : Colors.white,
                                              border: Border.all(
                                                color: !hasStock
                                                    ? const Color(0xFFE0E0E8)
                                                    : isSelected
                                                        ? const Color(0xFF1054ff)
                                                        : const Color(0xFFCCCCDD),
                                                width: isSelected ? 2 : 1.5,
                                              ),
                                              boxShadow: isSelected && hasStock
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF1054ff).withOpacity(0.35),
                                                        blurRadius: 14,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  size,
                                                  style: TextStyle(
                                                    fontSize: isWideSize ? 11 : 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: !hasStock
                                                        ? const Color(0xFFBBBBCC)
                                                        : isSelected
                                                            ? Colors.white
                                                            : const Color(0xFF1A1A2E),
                                                    letterSpacing: 0.1,
                                                  ),
                                                ),
                                                if (!hasStock)
                                                  Transform.rotate(
                                                    angle: -0.785398, // -45 degrees in radians
                                                    child: Container(
                                                      width: (isWideSize ? 56 : 48) * 0.6,
                                                      height: 1.5,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFCCCCDD),
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isLowStock)
                                            Positioned(
                                              bottom: 3,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF5EDD8),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'resta $stockQuantity',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1054ff),
                                                    letterSpacing: 0.2,
                                                    height: 1.4,
                                                  ),
                                                ),
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
                        
                        // Size Chart Button
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizeChartButton(
                            onPressed: _showSizeGuide,
                          ),
                        ),
                        
                        // Price Section
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_getCurrentCompareAtPrice() != null && _getCurrentCompareAtPrice()! > _getCurrentPrice())
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  PriceFormatter.formatWithCurrency(_getCurrentCompareAtPrice()!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            PriceWidget(
                              priceAvista: _getCurrentPrice(),
                              parcelas: 6,
                              valorParcela: _getCurrentPrice() / 6,
                            ),
                          ],
                        ),
                        
                        // Add to Cart Button
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_hasCurrentVariantStock()
                                  ? Colors.grey[400]
                                  : const Color(0xFF1054ff),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: !_hasCurrentVariantStock() ? 0 : 2,
                            ),
                            onPressed: !_hasCurrentVariantStock() ? null : () {
                              // Se não selecionou tamanho, força seleção
                              if (_selectedSize == null && sizes.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, selecione um tamanho'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (_selectedColor == null && colors.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, selecione uma cor'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Verifica se a variante selecionada especificamente tem estoque
                              if (_selectedVariant != null && _selectedVariant!.stock <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Esta variação não tem estoque disponível'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              for (int i = 0; i < _quantity; i++) {
                                context.read<CartProvider>().addItem(
                                      widget.product.id,
                                      widget.product.title,
                                      widget.product.price,
                                      variantId: _selectedVariant?.id,
                                      images: widget.product.images.map((img) => img.url).toList(),
                                      selectedColor: _selectedColor,
                                      selectedSize: _selectedSize,
                                    );
                              }
                              
                              // Mostra popup de confirmação
                              CiaPijamasPopup.show(
                                context,
                                onContinuarComprando: () {
                                  // Apenas fecha o popup, continua na página
                                },
                                onIrParaCarrinho: () {
                                  _goToCartScreen();
                                },
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  !_hasCurrentVariantStock()
                                      ? Icons.block
                                      : Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  !_hasCurrentVariantStock() 
                                      ? 'Sem Estoque Disponível'
                                      : 'Adicionar ao Carrinho',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Trust Badges
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TrustBadge(
                                icon: Icons.local_shipping,
                                title: 'Frete Grátis',
                                subtitle: 'acima de R\$150',
                              ),
                              _TrustBadge(
                                icon: Icons.lock,
                                title: 'Compra\nSegura',
                                subtitle: '100% protegida',
                              ),
                              _TrustBadge(
                                icon: Icons.sync,
                                title: 'Troca\nFácil',
                                subtitle: 'até 30 dias',
                              ),
                            ],
                          ),
                        ),
                        
                        // Product Benefits
                        const SizedBox(height: 24),
                        const Text(
                          'Por que você vai amar:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...[
                          'Tecido premium de alta qualidade',
                          'Ajuste perfeito ao corpo',
                          'Durabilidade garantida',
                          'Fácil de lavar e secar',
                        ].map((benefit) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        
                        // Features Carousel
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FeatureIcon(icon: Icons.eco, label: 'Sustentável'),
                              _FeatureIcon(icon: Icons.water_drop, label: 'Respirável'),
                              _FeatureIcon(icon: Icons.straighten, label: 'Flexível'),
                              _FeatureIcon(icon: Icons.wb_sunny, label: 'UV Protect'),
                              _FeatureIcon(icon: Icons.favorite, label: 'Conforto'),
                              _FeatureIcon(icon: Icons.stars, label: 'Premium'),
                            ],
                          ),
                        ),
                        
                        // Content Slider with Metafield Images (1:1 aspect ratio)
                        if (widget.product.metafield01Foto != null ||
                            widget.product.metafield02Foto != null ||
                            widget.product.metafield03Foto != null) ...[
                          const SizedBox(height: 32),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              return SizedBox(
                                width: width,
                                height: width, // 1:1 aspect ratio
                                child: Stack(
                                  children: [
                                    PageView(
                                      controller: _contentPageController,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentContentPage = index;
                                        });
                                      },
                                      children: [
                                        if (widget.product.metafield01Foto != null)
                                          _ImageSlide(imageUrl: widget.product.metafield01Foto!),
                                        if (widget.product.metafield02Foto != null)
                                          _ImageSlide(imageUrl: widget.product.metafield02Foto!),
                                        if (widget.product.metafield03Foto != null)
                                          _ImageSlide(imageUrl: widget.product.metafield03Foto!),
                                      ],
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          [
                                            widget.product.metafield01Foto,
                                            widget.product.metafield02Foto,
                                            widget.product.metafield03Foto,
                                          ].where((m) => m != null).length,
                                          (index) => Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _currentContentPage == index
                                                  ? const Color(0xFF1054ff)
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        
                        // Description
                        if (widget.product.description != null) ...[
                          const SizedBox(height: 32),
                          const Text(
                            'Descrição do Produto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.description!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                        
                        // Reviews
                        if (_loadingReviews) ...[
                          const SizedBox(height: 32),
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ] else if (_productReviews != null && _productReviews!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Avaliações',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    _calculateAverageRating(_productReviews!).toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...(_showAllReviews
                                  ? _productReviews!
                                  : _productReviews!.take(3))
                              .map((review) => _RealReviewCard(review: review)),
                          if (_productReviews!.length > 3)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllReviews = !_showAllReviews;
                                  });
                                },
                                child: Text(
                                  _showAllReviews
                                      ? 'Mostrar menos'
                                      : 'Ver todas as avaliações',
                                ),
                              ),
                            ),
                        ],
                        
                        // Related Products
                        const SizedBox(height: 32),
                        Text(
                          'Produtos Relacionados',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1054FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<ProductProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            
                            final relatedProducts = provider.products
                                .where((p) => p.id != widget.product.id)
                                .take(8)
                                .toList();
                            
                            return SizedBox(
                              height: 385,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: relatedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = relatedProducts[index];
                                  final colorMap = _getProductColorMap(product);
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < relatedProducts.length - 1 ? 16 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
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
                                                        if (colorMap.length > 3)
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
                            );
                          },
                        ),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Button
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CiaAddToCartFab(
                productImageUrl: images.isNotEmpty ? images.first.url : '',
                price: PriceFormatter.formatWithCurrency(_getCurrentPrice()),
                selectedSize: _selectedSize ?? '-',
                selectedColor: _selectedColor ?? '-',
                onAddToCart: () {
                  if (!_hasCurrentVariantStock()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sem estoque disponível'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_selectedSize == null && sizes.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecione um tamanho'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_selectedColor == null && colors.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecione uma cor'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_selectedVariant != null && _selectedVariant!.stock <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Esta variação não tem estoque disponível'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  for (int i = 0; i < _quantity; i++) {
                    context.read<CartProvider>().addItem(
                          widget.product.id,
                          widget.product.title,
                          widget.product.price,
                          variantId: _selectedVariant?.id,
                          images: widget.product.images.map((img) => img.url).toList(),
                          selectedColor: _selectedColor,
                          selectedSize: _selectedSize,
                        );
                  }

                  CiaPijamasPopup.show(
                    context,
                    onContinuarComprando: () {},
                    onIrParaCarrinho: () {
                      _goToCartScreen();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final itemCount = cartProvider.itemCount;

        return GestureDetector(
          onTap: _goToCartScreen,
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

  double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    
    int totalStars = 0;
    int count = 0;
    
    for (var review in reviews) {
      final stars = review['stars'];
      if (stars != null) {
        totalStars += (stars as int);
        count++;
      }
    }
    
    return count > 0 ? totalStars / count : 0.0;
  }
}

// Helper Widgets

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TableCell({
    required this.text,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1054ff), size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1054ff), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ContentSlide extends StatelessWidget {
  final String title;
  final String description;
  final Gradient gradient;

  const _ContentSlide({
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ImageSlide extends StatelessWidget {
  final String imageUrl;

  const _ImageSlide({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1054ff),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Imagem não disponível',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['author'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review['rating'] ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review['date'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _RealReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _RealReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final author = review['author'] ?? 'Anônimo';
    final stars = review['stars'] ?? 0;
    final comment = review['comment'] ?? '';
    final date = review['date'] ?? '';
    final photoUrl = review['photoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author and Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Two Column Layout: Photo (1/4) + Text (3/4)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Photo (1/4 width, 1:1 aspect ratio)
              if (photoUrl.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate 1/4 of available width
                    final photoSize = (MediaQuery.of(context).size.width - 64) / 4;
                    return GestureDetector(
                      onTap: () => _showReviewPhotoDialog(context, photoUrl, author),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              height: photoSize,
                              width: photoSize,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: photoSize,
                                width: photoSize,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: photoSize,
                                width: photoSize,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.error, size: 20),
                                ),
                              ),
                            ),
                          ),
                          // Ampliar button overlay
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1054FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'ampliar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              
              if (photoUrl.isNotEmpty) const SizedBox(width: 12),
              
              // Right Column: Text content (3/4 width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment
                    if (comment.isNotEmpty)
                      Text(
                        comment,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    
                    if (comment.isNotEmpty && date.isNotEmpty) const SizedBox(height: 8),
                    
                    // Date
                    if (date.isNotEmpty)
                      Text(
                        DateFormatter.formatBrazilian(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showReviewPhotoDialog(BuildContext context, String photoUrl, String author) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  padding: const EdgeInsets.all(40),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  padding: const EdgeInsets.all(40),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              author,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
