import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// MODEL
// ──────────────────────────────────────────────
class ReviewModel {
  final String name, text, imageUrl, date;
  final int rating;
  
  const ReviewModel({
    required this.name,
    required this.text,
    required this.imageUrl,
    required this.date,
    required this.rating,
  });
}

// ──────────────────────────────────────────────
// WIDGET PRINCIPAL
// ──────────────────────────────────────────────
class ReviewsWidget extends StatefulWidget {
  final List<ReviewModel> reviews;
  const ReviewsWidget({super.key, required this.reviews});

  @override
  State<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends State<ReviewsWidget> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.reviews.length > 1 ? 1 : 0;
    _current = initialPage;
    _controller = PageController(
      viewportFraction: 0.82,
      initialPage: initialPage,
    );
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _current) setState(() => _current = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _currentHasPhoto =>
      _current < widget.reviews.length &&
      widget.reviews[_current].imageUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deixe os clientes falarem por nós',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1054ff),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ..._buildStars(5, 14),
                  const SizedBox(width: 6),
                  Text(
                    'de ${widget.reviews.length} avaliações',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF656362)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Cards Carrossel com altura animada ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _currentHasPhoto ? 560 : 420,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.reviews.length,
            itemBuilder: (context, index) {
              return _ReviewCard(
                review: widget.reviews[index],
                isActive: index == _current,
              );
            },
          ),
        ),

        // ── Dots ──
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.reviews.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i
                    ? const Color(0xFF1054ff)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildStars(int total, double size) {
    return List.generate(total, (i) => Icon(
      Icons.star_rounded,
      size: size,
      color: const Color(0xFFFDB022),
    ));
  }
}

// ──────────────────────────────────────────────
// CARD
// ──────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isActive;

  const _ReviewCard({required this.review, required this.isActive});

  void _showPhotoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(review.imageUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(review.name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1054ff).withOpacity(0.25)
                : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1054ff).withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estrelas + data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StarRating(rating: review.rating, size: 14),
                  Text(review.date,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF656362))),
                ],
              ),

              const SizedBox(height: 8),

              // Autor
              Text(
                review.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1054ff),
                ),
              ),

              const SizedBox(height: 8),

              // ── Foto do cliente ──────────────────────────────────────────
              if (review.imageUrl.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showPhotoDialog(context),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Image.network(
                            review.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 32, color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1054ff),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 12),
                              SizedBox(width: 3),
                              Text('ampliar',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Texto
              Expanded(
                child: Text(
                  '"${review.text}"',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF656362),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Compra verificada
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1054ff).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Icon(Icons.check, size: 8,
                          color: Color(0xFF1054ff)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Compra verificada',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1054ff),
                    )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// STAR RATING
// ──────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final int rating;
  final double size;

  const _StarRating({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: const Color(0xFFFDB022),
        );
      }),
    );
  }
}
