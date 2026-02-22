// pubspec.yaml → google_fonts: ^6.1.0
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CiaPijamasPopup extends StatelessWidget {
  final VoidCallback? onContinuarComprando;
  final VoidCallback? onIrParaCarrinho;

  const CiaPijamasPopup({
    Key? key,
    this.onContinuarComprando,
    this.onIrParaCarrinho,
  }) : super(key: key);

  /// Exibe o popup com showDialog
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onContinuarComprando,
    VoidCallback? onIrParaCarrinho,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => CiaPijamasPopup(
        onContinuarComprando: onContinuarComprando,
        onIrParaCarrinho: onIrParaCarrinho,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul  = Color(0xFF1054FF);
    const bege  = Color(0xFFFCEED4);
    const cinza = Color(0xFF656362);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: bege,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: azul.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header Azul (ícone 1/4 | título 3/4) ─
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 20, horizontal: 18,
              ),
              decoration: const BoxDecoration(
                color: azul,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Ícone — ocupa 1/4
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        width: 52, height: 52,
                        decoration: const BoxDecoration(
                          color: bege, shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: azul, size: 26,
                        ),
                      ),
                    ),
                  ),
                  // Título — ocupa 3/4
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Produto adicionado!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: bege,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Botões ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [

                  // Continuar Comprando
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onContinuarComprando?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: azul, width: 2,
                        ),
                        foregroundColor: azul,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continuar\nComprando',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: azul,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Ir para o Carrinho
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onIrParaCarrinho?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azul,
                        foregroundColor: bege,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ir para o\nCarrinho',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: bege,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
}

// ── Como usar ─────────────────────────────────────
// CiaPijamasPopup.show(
//   context,
//   onContinuarComprando: () { /* volta para loja */ },
//   onIrParaCarrinho:     () { /* navega carrinho */ },
// );
