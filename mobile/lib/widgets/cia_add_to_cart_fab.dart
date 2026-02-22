import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class CiaColors {
  static const azul = Color(0xFF1054FF);
  static const azulDark = Color(0xFF0040DD);
  static const bege = Color(0xFFFCEED4);
  static const cinza = Color(0xFF656362);
}

abstract class CiaText {
  static TextStyle poppins({
    double size = 14,
    FontWeight weight = FontWeight.w700,
    Color color = const Color(0xFF1A1A1A),
    double spacing = 0,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );
}

class CiaAddToCartFab extends StatefulWidget {
  const CiaAddToCartFab({
    super.key,
    required this.productImageUrl,
    required this.price,
    required this.selectedSize,
    required this.selectedColor,
    required this.onAddToCart,
    this.isLoading = false,
  });

  final String productImageUrl;
  final String price;
  final String selectedSize;
  final String selectedColor;
  final VoidCallback onAddToCart;
  final bool isLoading;

  @override
  State<CiaAddToCartFab> createState() => _CiaAddToCartFabState();
}

class _CiaAddToCartFabState extends State<CiaAddToCartFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    ));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ));

    Future.delayed(
      const Duration(milliseconds: 180),
      _ctrl.forward,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _pressed = true);
    Future.delayed(
      const Duration(milliseconds: 140),
      () {
        if (!mounted) return;
        setState(() => _pressed = false);
        widget.onAddToCart();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() => LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 380;
          final cardHeight = isCompact ? 52.0 : 57.0;
          final borderRadius = isCompact ? 13.0 : 14.0;
          final imageWidth = isCompact ? 38.0 : 42.0;

          return Container(
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: CiaColors.azul.withOpacity(.28),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: CiaColors.azul.withOpacity(.14),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _ProductThumbnail(
                      imageUrl: widget.productImageUrl,
                      price: widget.price,
                      selectedSize: widget.selectedSize,
                      selectedColor: widget.selectedColor,
                      imageWidth: imageWidth,
                      compact: isCompact,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _CtaButton(
                      isLoading: widget.isLoading,
                      pressed: _pressed,
                      compact: isCompact,
                      onTap: widget.isLoading ? () {} : _handleTap,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.price,
    required this.selectedSize,
    required this.selectedColor,
    required this.imageWidth,
    required this.compact,
  });

  final String imageUrl;
  final String price;
  final String selectedSize;
  final String selectedColor;
  final double imageWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        color: CiaColors.bege,
        child: Row(
          children: [
            SizedBox(
              width: imageWidth,
              child: ClipRect(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFDDE5FF),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 16,
                      color: CiaColors.azul,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: compact ? 29 : 34,
              color: Colors.black.withOpacity(.07),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        price,
                        style: CiaText.poppins(
                          size: compact ? 10 : 11,
                          color: const Color(0xFF1A1A1A),
                          spacing: -0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 3),
                    Text(
                      'Tam. $selectedSize · $selectedColor',
                      style: CiaText.poppins(
                        size: compact ? 7 : 8,
                        weight: FontWeight.w600,
                        color: CiaColors.cinza,
                        spacing: 0.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.onTap,
    required this.isLoading,
    required this.pressed,
    required this.compact,
  });

  final VoidCallback onTap;
  final bool isLoading;
  final bool pressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          color: pressed ? CiaColors.azulDark : CiaColors.azul,
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation(CiaColors.bege),
                    ),
                  ),
                )
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+',
                          style: CiaText.poppins(
                            size: compact ? 14 : 15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Text(
                          'Adicionar ao Carrinho',
                          style: CiaText.poppins(
                            size: compact ? 12 : 13.5,
                            color: Colors.white,
                            spacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
}
