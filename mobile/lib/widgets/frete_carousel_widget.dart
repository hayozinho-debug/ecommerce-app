import 'package:flutter/material.dart';

// === WIDGET PRINCIPAL: Carrossel com indicadores ===
class FreteCarousel extends StatefulWidget {
  const FreteCarousel({super.key});

  @override
  State<FreteCarousel> createState() => _FreteCarouselState();
}

class _FreteCarouselState extends State<FreteCarousel> {
  int _currentPage = 0;
  final PageController _controller = PageController();

  final List<Map<String, String>> _items = [
    {
      'title': 'Frete grátis',
      'subtitle': 'Acima de R\$ 199,90',
    },
    {
      'title': 'Não deu certo?',
      'subtitle': 'Troca Grátis',
    },
    {
      'title': 'Fabricantes',
      'subtitle': 'Desde 1987',
    },
    {
      'title': '12% Cashback',
      'subtitle': 'Aproveite',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 88,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return FreteCard(
                title: _items[index]['title']!,
                subtitle: _items[index]['subtitle']!,
                iconIndex: index,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 10 : 8,
              height: _currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFBFD3F6),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// === CARD INDIVIDUAL ===
class FreteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int iconIndex;

  const FreteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconIndex,
  });

  CustomPainter _painterFor(int index) {
    switch (index) {
      case 1: return _ReturnIconPainter();
      case 2: return _SewingIconPainter();
      case 3: return _GiftIconPainter();
      default: return _TruckIconPainter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A56DB),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // Ícone
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _painterFor(iconIndex),
              ),
            ),
            const SizedBox(width: 16),
            // Textos
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// === PINTOR DO ÍCONE DE CAMINHÃO ===
class _TruckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double s = size.width / 40; // escala

    // Corpo do caminhão (carga)
    final body = Path()
      ..moveTo(2 * s, 28 * s)
      ..lineTo(2 * s, 14 * s)
      ..lineTo(24 * s, 14 * s)
      ..lineTo(24 * s, 28 * s)
      ..close();
    canvas.drawPath(body, paint);

    // Cabine
    final cab = Path()
      ..moveTo(24 * s, 18 * s)
      ..lineTo(32 * s, 18 * s)
      ..lineTo(38 * s, 23 * s)
      ..lineTo(38 * s, 28 * s)
      ..lineTo(24 * s, 28 * s)
      ..close();
    canvas.drawPath(cab, paint);

    // Rodas
    canvas.drawCircle(Offset(9 * s, 29 * s), 3 * s, paint);
    canvas.drawCircle(Offset(31 * s, 29 * s), 3 * s, paint);

    // Check mark dentro do corpo
    final check = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(8 * s, 21 * s)
      ..lineTo(12 * s, 25 * s)
      ..lineTo(18 * s, 17 * s);
    canvas.drawPath(checkPath, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// === PINTOR DO ÍCONE DE TROCA ===
class _ReturnIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double s = size.width / 40;

    // Seta circular esquerda
    final arc1 = Path()
      ..moveTo(20 * s, 6 * s)
      ..cubicTo(12 * s, 6 * s, 6 * s, 12 * s, 6 * s, 20 * s)
      ..cubicTo(6 * s, 28 * s, 12 * s, 34 * s, 20 * s, 34 * s);
    canvas.drawPath(arc1, paint);

    // Ponta da seta (cima)
    final arrowUp = Path()
      ..moveTo(20 * s, 6 * s)
      ..lineTo(24 * s, 10 * s)
      ..moveTo(20 * s, 6 * s)
      ..lineTo(16 * s, 10 * s);
    canvas.drawPath(arrowUp, paint);

    // Seta circular direita (tracejada)
    final dashPaint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final arc2 = Path()
      ..moveTo(20 * s, 34 * s)
      ..cubicTo(28 * s, 34 * s, 34 * s, 28 * s, 34 * s, 20 * s)
      ..cubicTo(34 * s, 12 * s, 28 * s, 6 * s, 20 * s, 6 * s);
    
    final metrics = arc2.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final seg = metric.extractPath(dist, dist + 3 * s);
        canvas.drawPath(seg, dashPaint);
        dist += 5 * s;
      }
    }

    // Check
    final check = Path()
      ..moveTo(14 * s, 20 * s)
      ..lineTo(18 * s, 24 * s)
      ..lineTo(26 * s, 16 * s);
    canvas.drawPath(check, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// === PINTOR DO ÍCONE DE INDÚSTRIA ===
class _SewingIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double s = size.width / 40;

    // Chão
    canvas.drawLine(Offset(3 * s, 34 * s), Offset(37 * s, 34 * s), paint);

    // Corpo da fábrica com telhado serrilhado (shed roof)
    final body = Path()
      ..moveTo(4 * s, 34 * s)
      ..lineTo(4 * s, 20 * s)
      ..lineTo(14 * s, 26 * s)
      ..lineTo(14 * s, 20 * s)
      ..lineTo(24 * s, 26 * s)
      ..lineTo(24 * s, 20 * s)
      ..lineTo(34 * s, 20 * s)
      ..lineTo(34 * s, 34 * s)
      ..close();
    canvas.drawPath(body, paint);

    // Telhado do bloco direito
    final roof = Path()
      ..moveTo(24 * s, 20 * s)
      ..lineTo(24 * s, 14 * s)
      ..lineTo(34 * s, 14 * s)
      ..lineTo(34 * s, 20 * s);
    canvas.drawPath(roof, paint);

    // Chaminé esquerda
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(27 * s, 7 * s, 3.5 * s, 8 * s), Radius.circular(s)),
      paint..strokeWidth = 1.5,
    );

    // Chaminé direita
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(32 * s, 9 * s, 3.5 * s, 6 * s), Radius.circular(s)),
      paint,
    );

    // Fumaça
    final smoke = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final smokePath = Path()
      ..moveTo(28.7 * s, 7 * s)
      ..quadraticBezierTo(27.5 * s, 4.5 * s, 28.7 * s, 3 * s);
    canvas.drawPath(smokePath, smoke);

    // Janela
    paint.strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(27 * s, 22 * s, 5 * s, 5 * s), Radius.circular(0.8 * s)),
      paint,
    );

    // Porta
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(9 * s, 27 * s, 5 * s, 7 * s), Radius.circular(0.8 * s)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// === PINTOR DO ÍCONE DE PRESENTE ===
class _GiftIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double s = size.width / 40;

    // Caixa
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(6 * s, 18 * s, 28 * s, 18 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(box, paint);

    // Tampa
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(4 * s, 13 * s, 32 * s, 7 * s),
      Radius.circular(1.5 * s),
    );
    canvas.drawRRect(lid, paint);

    // Fita vertical
    canvas.drawLine(Offset(20 * s, 13 * s), Offset(20 * s, 36 * s), paint);

    // Fita horizontal
    canvas.drawLine(Offset(6 * s, 16.5 * s), Offset(34 * s, 16.5 * s), paint);

    // Laço esquerdo
    final bowLeft = Path()
      ..moveTo(20 * s, 13 * s)
      ..cubicTo(17 * s, 8 * s, 11 * s, 7 * s, 12 * s, 10 * s)
      ..cubicTo(13 * s, 13 * s, 18 * s, 13 * s, 20 * s, 13 * s);
    canvas.drawPath(bowLeft, paint);

    // Laço direito
    final bowRight = Path()
      ..moveTo(20 * s, 13 * s)
      ..cubicTo(23 * s, 8 * s, 29 * s, 7 * s, 28 * s, 10 * s)
      ..cubicTo(27 * s, 13 * s, 22 * s, 13 * s, 20 * s, 13 * s);
    canvas.drawPath(bowRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
