import 'package:flutter/material.dart';

const _kAzul = Color(0xFF1054FF);
const _kBege = Color(0xFFFCEED4);
const _kCinza = Color(0xFF656362);

const double _kPeek = 0.82;
const double _kGap = 10.0;
const double _kHeight = 440.0;

const double _kVelMed = 0.55;
const double _kVelHigh = 1.1;

class PdpImageSlider extends StatefulWidget {
  final List<String> imageUrls;

  const PdpImageSlider({super.key, required this.imageUrls});

  @override
  State<PdpImageSlider> createState() => _PdpImageSliderState();
}

class _PdpImageSliderState extends State<PdpImageSlider> {
  final _scroll = ScrollController();
  int _idx = 0;
  double _dragStartX = 0;
  double _dragEndX = 0;
  DateTime _dragStartTime = DateTime.now();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _itemWidth(double totalWidth) => totalWidth * _kPeek - _kGap * 0.5;

  void _animateTo(int target, double iw) {
    final idx = target.clamp(0, widget.imageUrls.length - 1);
    final dist = (idx - _idx).abs();
    final ms = (260 + dist * 55).clamp(260, 500);

    _scroll.animateTo(
      idx * (iw + _kGap),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );

    if (mounted) {
      setState(() => _idx = idx);
    }
  }

  void _onDragStart(DragStartDetails d) {
    _dragStartX = d.globalPosition.dx;
    _dragEndX = _dragStartX;
    _dragStartTime = DateTime.now();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragEndX = d.globalPosition.dx;
  }

  void _onDragEnd(DragEndDetails d, double iw) {
    final dx = _dragEndX - _dragStartX;
    final dt = DateTime.now()
        .difference(_dragStartTime)
        .inMilliseconds
        .toDouble()
        .clamp(1.0, 9999.0);
    final vel = dx.abs() / dt;
    final fwd = dx < 0;

    int jump;
    if (vel >= _kVelHigh) {
      jump = 3;
    } else if (vel >= _kVelMed) {
      jump = 2;
    } else if (dx.abs() > iw * 0.18) {
      jump = 1;
    } else {
      jump = 0;
    }

    if (jump == 0) {
      _animateTo(_idx, iw);
      return;
    }

    _animateTo(fwd ? _idx + jump : _idx - jump, iw);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final iw = _itemWidth(bc.maxWidth);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: (d) => _onDragEnd(d, iw),
              child: Container(
                height: _kHeight,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: widget.imageUrls.length,
                      itemBuilder: (_, i) {
                        final isLast = i == widget.imageUrls.length - 1;
                        return Container(
                          width: iw,
                          height: _kHeight,
                          margin: EdgeInsets.only(right: isLast ? 0 : _kGap),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImage(widget.imageUrls[i]),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _buildCounter(),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: _buildDots(iw),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                height: 66,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = i == _idx;
                    return GestureDetector(
                      onTap: () => _animateTo(i, iw),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 54,
                        height: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? _kAzul : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: active ? 1.0 : 0.38,
                            child: _buildImage(widget.imageUrls[i]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return Container(
          color: _kBege,
          child: const Center(
            child: CircularProgressIndicator(
              color: _kAzul,
              strokeWidth: 1.5,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: _kBege,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: _kCinza,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAzul.withOpacity(0.2)),
      ),
      child: Text(
        '${_idx + 1} / ${widget.imageUrls.length}',
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: _kAzul,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDots(double iw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.imageUrls.length, (i) {
        final active = i == _idx;
        return GestureDetector(
          onTap: () => _animateTo(i, iw),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: active ? _kAzul : _kCinza.withOpacity(0.45),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}