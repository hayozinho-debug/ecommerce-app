import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/cart_provider.dart';
import '../services/analytics_service.dart';

// Conditional imports for web-specific functionality
import 'checkout_webview_stub.dart'
    if (dart.library.html) 'checkout_webview_web.dart';

// Para web: usa iframe embutido
// Para mobile: usa webview_flutter

class CheckoutWebView extends StatefulWidget {
  final String checkoutUrl;

  const CheckoutWebView({
    Key? key,
    required this.checkoutUrl,
  }) : super(key: key);

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  bool _isLoading = true;
  bool _webRedirectTriggered = false;
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _startWebCheckoutRedirect();
    } else {
      _setupMobileWebView();
    }

    // Tracking
    AnalyticsService.trackBeginCheckout(
      items: context.read<CartProvider>().items,
      value: context.read<CartProvider>().totalPrice,
    );
  }

  void _startWebCheckoutRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _webRedirectTriggered) {
        return;
      }

      setState(() {
        _webRedirectTriggered = true;
      });

      openCheckoutInSameTab(widget.checkoutUrl);
    });
  }

  Future<void> _openExternalScheme(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o app necessário para concluir o pagamento.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupMobileWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final scheme = uri?.scheme.toLowerCase();

            if (scheme == 'http' || scheme == 'https') {
              return NavigationDecision.navigate;
            }

            const allowedExternalSchemes = {
              'intent',
              'cielo',
              'upi',
              'mailto',
              'tel',
              'sms',
              'market',
            };

            if (uri != null && scheme != null && allowedExternalSchemes.contains(scheme)) {
              _openExternalScheme(uri);
              return NavigationDecision.prevent;
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link bloqueado por segurança do checkout.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao carregar checkout: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web: redirecionamento no mesmo contexto da aba para evitar bloqueios de iframe
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1054ff),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Confirma antes de sair
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Abandonar checkout?'),
                  content: const Text(
                    'Tem certeza que deseja sair? Seu carrinho será mantido.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Sair',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 18,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Checkout Seguro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF1054ff),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Redirecionando para o checkout seguro...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => openCheckoutInSameTab(widget.checkoutUrl),
                      child: const Text('Se não abrir automaticamente, clique aqui'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Para mobile (Android/iOS): checkout dentro do app com WebView
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout Seguro',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1054ff)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
