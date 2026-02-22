import 'package:flutter/material.dart';

class SizeChartButton extends StatelessWidget {
  const SizeChartButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1054FF),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8.0 : 20.0,
          vertical: compact ? 8.0 : 14.0,
        ),
        textStyle: TextStyle(
          fontSize: compact ? 14.0 : 18.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          decoration: TextDecoration.underline,
        ),
      ),
      icon: Icon(
        Icons.straighten_rounded,
        size: compact ? 18.0 : 24.0,
        color: const Color(0xFF1054FF),
      ),
      label: const Text('Tabela de Medidas'),
    );
  }
}
