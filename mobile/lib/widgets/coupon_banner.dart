import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CouponBanner — Outlined + Codigo Preenchido
/// Cores da marca: Azul #1054FF | Bege #fceed4 | Cinza #656362
///
/// Como usar:
///   CouponBanner(
///     discount: '10% OFF',
///     label: 'Cupom',
///     subtitle: 'Primeira compra',
///     code: 'BEMVINDO',
///   )
class CouponBanner extends StatefulWidget {
  final String discount;
  final String label;
  final String subtitle;
  final String code;

  const CouponBanner({
    super.key,
    this.discount = '10% OFF',
    this.label = 'Cupom',
    this.subtitle = 'Primeira compra',
    this.code = 'BEMVINDO',
  });

  @override
  State<CouponBanner> createState() => _CouponBannerState();
}

class _CouponBannerState extends State<CouponBanner>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1054FF);
  static const _offWhite = Color(0xFFF7F9FF);

  bool _copied = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        decoration: BoxDecoration(
          color: _offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _blue, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
            children: [
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${widget.label} ',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                          TextSpan(
                            text: widget.discount,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF656362),
                      ),
                    ),
                  ],
                ),
              ),

            // Code area
            Container(
              color: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              alignment: Alignment.center,
              child: Text(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),

            // Vertical divider
            Container(
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),

            // Copy button
            GestureDetector(
              onTap: _handleCopy,
              child: ScaleTransition(
                scale: _scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  color: _copied ? const Color(0xFF16A34A) : _blue,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Row(
                            key: ValueKey('ok'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'OK',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            key: ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_outlined, color: Colors.white, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'COPIAR',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
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
