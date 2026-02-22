import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/collection.dart';
import '../constants/app_constants.dart';

// --------------- CONSTANTES DE BRANDING ----------------------
const kBlue  = Color(0xFF1054FF);
const kBeige = Color(0xFFFCEED4);
const kGray  = Color(0xFF656362);

// --------------- TELA PRINCIPAL -----------------------------
class CategoriesScreen extends StatefulWidget {
  final Function(String?, String?)? onNavigateToCatalog;
  
  const CategoriesScreen({super.key, this.onNavigateToCatalog});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Collection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoriesCollections();
  }

  Future<void> _fetchStoriesCollections() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiUrl}/shopify/stories-collections'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final collections = (data['collections'] as List)
            .map((json) => Collection.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _collections = collections;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching stories collections: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma categoria disponível',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: kGray,
                      ),
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── Section Title ────────────────────────
                      SliverToBoxAdapter(child: _buildSectionTitle()),

                      // ── Category Cards (1 por linha) ─────────
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _CategoryCard(
                                  collection: _collections[index],
                                  onTap: () {
                                    widget.onNavigateToCatalog?.call(
                                      _collections[index].gid,
                                      _collections[index].name,
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: _collections.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          Text(
            'Categorias',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Escolha a sua 💙',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kGray,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------- CATEGORY CARD WIDGET ----------------------
class _CategoryCard extends StatefulWidget {
  final Collection collection;
  final VoidCallback onTap;
  
  const _CategoryCard({
    required this.collection,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  // Gradientes baseados no nome da categoria
  List<Color> _getGradientForCategory(String name) {
    final nameUpper = name.toUpperCase();
    
    if (nameUpper.contains('MASCULINO') || nameUpper.contains('HOMEM')) {
      return [Color(0xFF1054FF), Color(0xFF4A7FFF)];
    } else if (nameUpper.contains('FEMININO') || nameUpper.contains('MULHER')) {
      return [Color(0xFFF9C5D1), Color(0xFFE882A0)];
    } else if (nameUpper.contains('INFANTIL') || nameUpper.contains('CRIANÇA')) {
      return [Color(0xFFFFE066), Color(0xFFFF9F1C)];
    } else if (nameUpper.contains('CASAL')) {
      return [Color(0xFFB5E8C4), Color(0xFF2E8B57)];
    } else if (nameUpper.contains('FAMÍLIA') || nameUpper.contains('FAMILIA')) {
      return [Color(0xFFD0B4FF), Color(0xFF7C4FFF)];
    } else if (nameUpper.contains('BEBÊ') || nameUpper.contains('BEBE')) {
      return [Color(0xFFA8E6F0), Color(0xFF3DB8C8)];
    } else if (nameUpper.contains('MENINO')) {
      return [Color(0xFF4A9FFF), Color(0xFF1054FF)];
    } else if (nameUpper.contains('MENINA')) {
      return [Color(0xFFFFB6D9), Color(0xFFFF85C0)];
    } else {
      return [kBlue, Color(0xFF4A7FFF)];
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final gradient = _getGradientForCategory(collection.name);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Image background
              if (collection.image != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: collection.image!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),
                  ),
                ),

              // Gradient overlay (left dark for readability)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.60),
                      Colors.black.withOpacity(0.40),
                      Colors.black.withOpacity(0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.60, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // Content left
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      collection.name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ver coleção',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow button (right)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
