import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/recently_viewed_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/price_formatter.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

// Color constants
const kBlue = Color(0xFF1054FF);
const kBeige = Color(0xFFFCEED4);
const kGray = Color(0xFF656362);
const kLightGray = Color(0xFFF5F5F5);
const kWhite = Colors.white;

class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCard1(),
              const SizedBox(height: 12),
              _buildFavoritesButton(context),
              const SizedBox(height: 12),
              _buildWhatsAppButton(),
              const SizedBox(height: 12),
              _buildRecentlyViewed(context),
              const SizedBox(height: 12),
              _buildFavorites(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kBeige,
              shape: BoxShape.circle,
              border: Border.all(color: kBlue, width: 2),
            ),
            child: const Icon(Icons.person, color: kBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Entrar / Cadastrar',
              style: _boldStyle(16, kBlue),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kGray),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ─── CARD ÚNICO: MEUS PEDIDOS · POLÍTICA · CUPONS · DEVOLUÇÃO ─────────────
  Widget _buildCard1() {
    return _card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconAction(Icons.local_shipping_outlined, 'Meus Pedidos'),
          _iconAction(Icons.policy_outlined, 'Política'),
          _iconAction(Icons.confirmation_number_outlined, 'Cupons'),
          _iconAction(Icons.assignment_return_outlined, 'Devolução'),
        ],
      ),
    );
  }

  // ─── FAVORITES BUTTON ──────────────────────────────────────────────────────
  Widget _buildFavoritesButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _FavoritesScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: kBlue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kBlue.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: kWhite, size: 24),
              const SizedBox(width: 10),
              Text('Meus Favoritos', style: _boldStyle(15, kWhite)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WHATSAPP BUTTON ───────────────────────────────────────────────────────
  Widget _buildWhatsAppButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse('https://wa.me/554734600332');
          // Use url_launcher package: launchUrl(uri);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WhatsApp icon (use font_awesome_flutter or an asset)
              const Icon(Icons.chat, color: kWhite, size: 24),
              const SizedBox(width: 10),
              Text('Falar no WhatsApp', style: _boldStyle(15, kWhite)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RECENTLY VIEWED ───────────────────────────────────────────────────────
  Widget _buildRecentlyViewed(BuildContext context) {
    return Consumer<RecentlyViewedProvider>(
      builder: (context, recentlyViewedProvider, _) {
        final products = recentlyViewedProvider.products;
        
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Vistos Recentemente', style: _boldStyle(15, Colors.black87)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 385,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length > 10 ? 10 : products.length,
                itemBuilder: (_, i) => _productCard(context, products[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        final colorMap = _getProductColorMap(product);
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
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(right: 12),
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
                            valueColor: AlwaysStoppedAnimation<Color>(kBlue),
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
                          color: kBlue,
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
    );
  }

  // ─── FAVORITES ─────────────────────────────────────────────────────────────
  Widget _buildFavorites(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final favorites = favoritesProvider.items;
        
        if (favorites.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Meus Favoritos', style: _boldStyle(15, Colors.black87)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 385,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favorites.length,
                itemBuilder: (_, i) => _productCard(context, favorites[i].product),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconAction(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kBlue, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: _regularStyle(11, kGray),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  TextStyle _boldStyle(double size, Color color) =>
      GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: size, color: color);

  TextStyle _semiBoldStyle(double size, Color color) =>
      GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: size, color: color);

  TextStyle _regularStyle(double size, Color color) =>
      GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: size, color: color);

  // Helper functions for product cards
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
}
// ─── FAVORITES SCREEN ──────────────────────────────────────────────────────
class _FavoritesScreen extends StatelessWidget {
  const _FavoritesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Meus Favoritos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kBlue,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          final items = favoritesProvider.items;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 68,
                      color: kBlue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum favorito ainda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Marque seus produtos favoritos para acompanhá-los.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: kGray,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final favorite = items[index];
              final product = favorite.product;
              final imageUrl = (favorite.coverImageUrl != null && favorite.coverImageUrl!.isNotEmpty)
                  ? favorite.coverImageUrl!
                  : (product.images.isNotEmpty ? product.images.first.url : '');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: product,
                          initialColor: favorite.selectedColor,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey[100],
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.image, color: Colors.black26),
                                  ),
                                )
                              : Container(
                                  width: 84,
                                  height: 84,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.image, color: Colors.black26),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                PriceFormatter.formatWithCurrency(product.price),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: kBlue,
                                ),
                              ),
                              if (favorite.selectedColor != null && favorite.selectedColor!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Cor: ${favorite.selectedColor!}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kGray,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: kBlue),
                          onPressed: () {
                            favoritesProvider.toggleFavorite(
                              product: product,
                              selectedColor: favorite.selectedColor,
                              coverImageUrl: favorite.coverImageUrl,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}