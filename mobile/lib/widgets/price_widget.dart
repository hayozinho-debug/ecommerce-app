import 'package:flutter/material.dart';

class PriceWidget extends StatelessWidget {
  const PriceWidget({
    super.key,
    required this.priceAvista,
    required this.parcelas,
    required this.valorParcela,
  });

  final double priceAvista;
  final int parcelas;
  final double valorParcela;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAVista(),
        const Divider(),
        _buildParcelado(),
      ],
    );
  }

  Widget _buildAVista() => RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
          children: [
            const TextSpan(text: 'por  '),
            TextSpan(
              text: 'R\$ ${_fmt(priceAvista)}',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1054ff),
              ),
            ),
            const TextSpan(text: '  à vista'),
          ],
        ),
      );

  Widget _buildParcelado() => RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
          children: [
            TextSpan(text: 'ou ${parcelas}x  '),
            TextSpan(
              text: 'R\$ ${_fmt(valorParcela)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1054ff),
              ),
            ),
            const TextSpan(
              text: '  sem juros',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  String _fmt(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
}
