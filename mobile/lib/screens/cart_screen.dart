import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../services/analytics_service.dart';
import 'checkout_webview.dart';
import '../utils/price_formatter.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({Key? key, this.onContinueShopping}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  Future<void> _handleBack() async {
    final popped = await Navigator.maybePop(context);
    if (!popped && widget.onContinueShopping != null) {
      widget.onContinueShopping!.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final subtotal = cartProvider.totalPrice;
        const targetAmount = 200.0;
        final shippingCost = subtotal >= targetAmount ? 0.0 : 15.90;
        final total = subtotal + shippingCost;
        final progress = (subtotal / targetAmount).clamp(0.0, 1.0);
        final remaining = (targetAmount - subtotal).clamp(0.0, double.infinity);
        final isCompleted = subtotal >= targetAmount;

        // Carrinho vazio
        if (cartProvider.items.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'CARRINHO',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1054ff),
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _handleBack,
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1054ff),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => widget.onContinueShopping != null ? widget.onContinueShopping!.call() : Navigator.pop(context),
                    child: Text(
                      'Continuar Comprando',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Carrinho com itens
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'CARRINHO',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1054ff),
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _handleBack,
            ),
          ),
          backgroundColor: const Color(0xFFF9F9F9),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildGamificationCard(isCompleted, progress, remaining),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: cartProvider.items.map((item) {
                      return _buildCartItem(context, cartProvider, item);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: _buildCheckoutBottomSheet(
              context,
              cartProvider,
              subtotal,
              shippingCost,
              total,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamificationCard(bool isCompleted, double progress, double remaining) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFE0F2FE),
          border: Border.all(
            color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFF7DD3FC),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensagem
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parabéns! Você ganhou Frete Grátis!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Quase lá, adicione mais ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      TextSpan(
                        text: PriceFormatter.formatWithCurrency(remaining),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1054ff),
                        ),
                      ),
                      TextSpan(
                        text: ' para ganhar ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      TextSpan(
                        text: 'FRETE GRÁTIS!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1054ff),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Progress Fill
                  Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * progress - 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                            : [const Color(0xFF22D3EE), const Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Shimmer effect
                  if (!isCompleted)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0),
                                ],
                                stops: [
                                  _shimmerController.value - 0.1,
                                  _shimmerController.value,
                                  _shimmerController.value + 0.1,
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildCartItem(BuildContext context, CartProvider cartProvider, dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      height: 128,
      child: Row(
        children: [
          // Imagem
          Container(
            width: 100,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: item.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item.images.first,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 256,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return const Icon(Icons.image, color: Colors.grey, size: 30);
                      },
                    ),
                  )
                : const Icon(Icons.image, color: Colors.grey, size: 30),
          ),

          // Informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    item.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    [
                      if (item.selectedColor != null) item.selectedColor!,
                      if (item.selectedSize != null) item.selectedSize!,
                    ].join(' • ').isEmpty
                        ? 'Sem variação'
                        : [
                            if (item.selectedColor != null) item.selectedColor!,
                            if (item.selectedSize != null) item.selectedSize!,
                          ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    PriceFormatter.formatWithCurrency(item.subtotal),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles (Lixeira + Quantidade)
          SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lixeira
                GestureDetector(
                  onTap: () => cartProvider.removeItem(item.id),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),

                // Quantidade
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: item.quantity > 1
                            ? () => cartProvider.updateQuantity(
                                  item.id,
                                  item.quantity - 1,
                                )
                            : null,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: Icon(Icons.remove, size: 12, color: Color(0xFF1054ff)),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cartProvider.updateQuantity(
                          item.id,
                          item.quantity + 1,
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: Icon(Icons.add, size: 12, color: Color(0xFF1054ff)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomSheet(
    BuildContext context,
    CartProvider cartProvider,
    double subtotal,
    double shippingCost,
    double total,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                PriceFormatter.formatWithCurrency(subtotal),
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frete:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                shippingCost == 0 ? 'GRÁTIS ✓' : PriceFormatter.formatWithCurrency(shippingCost),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: shippingCost == 0 ? FontWeight.bold : FontWeight.normal,
                  color: shippingCost == 0 ? const Color(0xFF14B8A6) : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                PriceFormatter.formatWithCurrency(total),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1054ff),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botão Finalizar Compra
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1054ff),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _handleCheckout(context, cartProvider),
              child: Text(
                'Finalizar a Compra',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Botão Continuar Comprando
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1054ff), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => widget.onContinueShopping != null ? widget.onContinueShopping!.call() : Navigator.pop(context),
              child: Text(
                'Continuar Comprando',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1054ff),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Security Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                color: Color(0xFF16A34A),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Compra Segura',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF1054ff),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparando checkout...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await AnalyticsService.trackBeginCheckout(
        items: cart.items,
        value: cart.totalPrice,
      );

      final checkoutUrl = await cart.createShopifyCheckout();

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutWebView(
              checkoutUrl: checkoutUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao iniciar checkout: $e',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
