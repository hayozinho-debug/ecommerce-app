import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, ValueListenable;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import 'clips_video_platform.dart';

class CP {
  static const blue = Color(0xFF1054FF);
  static const beige = Color(0xFFFCEED4);
  static const gray = Color(0xFF656362);
  static const black = Color(0xFF0D0D0D);
  static const white = Color(0xFFFFFFFF);
}

TextStyle poppins({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = CP.white,
  double? height,
  double letterSpacing = 0,
}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

class ClipProduct {
  final String id;
  final String videoUrl;
  final String storeName;
  final String productName;
  final String productSku;
  final String? subtitle;
  final String? thumbUrl;
  final double price;
  final double? originalPrice;
  final int likes;
  final int? productId;
  final String? productGid;
  final String? variantLabel;
  final String? color;
  final String ctaLabel;
  final String ctaType;
  final String? ctaTarget;
  bool isLiked;

  ClipProduct({
    required this.id,
    required this.videoUrl,
    required this.storeName,
    required this.productName,
    required this.productSku,
    this.subtitle,
    this.thumbUrl,
    required this.price,
    this.originalPrice,
    required this.likes,
    this.productId,
    this.productGid,
    this.variantLabel,
    this.color,
    required this.ctaLabel,
    required this.ctaType,
    this.ctaTarget,
    this.isLiked = false,
  });

  factory ClipProduct.fromJson(Map<String, dynamic> json) {
    double readPrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
    }

    return ClipProduct(
      id: (json['id'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      storeName: 'Cia Pijamas',
      productName: (json['title'] ?? '').toString().isEmpty
          ? 'Produto em destaque'
          : (json['title'] as String),
      productSku: (json['handle'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      thumbUrl: json['thumbUrl']?.toString(),
      price: readPrice(json['price']),
      originalPrice: readPrice(json['originalPrice']) > 0 ? readPrice(json['originalPrice']) : null,
      likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : 0,
      productId: (json['productId'] is num) ? (json['productId'] as num).toInt() : int.tryParse('${json['productId'] ?? ''}'),
      productGid: json['productGid']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      color: json['color']?.toString(),
      ctaLabel: (json['ctaLabel'] ?? 'Confira agora').toString(),
      ctaType: (json['ctaType'] ?? 'none').toString(),
      ctaTarget: json['ctaTarget']?.toString(),
    );
  }

  static List<ClipProduct> mockList = [
    ClipProduct(
      id: '1',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      storeName: 'Cia Pijamas',
      productName: 'Pijama Longo Listrado',
      productSku: 'CP-2025-041 · P ao GGG',
      price: 129.90,
      originalPrice: 179.90,
      likes: 2400,
      variantLabel: 'Rosa',
      color: 'Rosa',
      ctaLabel: 'Confira agora',
      ctaType: 'none',
    ),
    ClipProduct(
      id: '2',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      storeName: 'Cia Pijamas',
      productName: 'Camisola Manga Curta',
      productSku: 'CP-2025-082 · PP ao GG',
      price: 89.90,
      originalPrice: 119.90,
      likes: 3800,
      variantLabel: 'Azul-marinho',
      color: 'Azul-marinho',
      ctaLabel: 'Confira agora',
      ctaType: 'none',
    ),
    ClipProduct(
      id: '3',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      storeName: 'Cia Pijamas',
      productName: 'Short Doll Estampado',
      productSku: 'CP-2025-103 · P ao GG',
      price: 74.90,
      originalPrice: 99.90,
      likes: 5100,
      variantLabel: 'Estampado Floral',
      color: 'Estampado Floral',
      ctaLabel: 'Confira agora',
      ctaType: 'none',
    ),
  ];
}

class ClipsStoriesWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onNavigateBack;

  const ClipsStoriesWidget({super.key, this.isActive = true, this.onNavigateBack});

  @override
  State<ClipsStoriesWidget> createState() => _ClipsStoriesWidgetState();
}

class _ClipsStoriesWidgetState extends State<ClipsStoriesWidget> {
  final _pageCtrl = PageController();
  late final ValueNotifier<bool> _screenActive = ValueNotifier<bool>(widget.isActive);
  List<ClipProduct> _clips = [];
  bool _isLoading = true;
  String? _error;
  int _current = 0;
  String _resolvedApiBaseUrl = ApiConstants.apiUrl;

  @override
  void initState() {
    super.initState();
    _loadClips();
  }

  Future<void> _loadClips() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final candidates = _buildApiBaseCandidates();
      final attemptErrors = <String>[];
      List<ClipProduct> loaded = [];

      for (final base in candidates) {
        final uri = Uri.parse('$base/shopify/clips').replace(queryParameters: {
          'referenceListId': '186305708310',
          'metaobjectType': 'lista_de_referencias',
        });

        try {
          final response = await http.get(uri).timeout(const Duration(seconds: 8));
          if (response.statusCode != 200) {
            attemptErrors.add('$base -> HTTP ${response.statusCode}');
            continue;
          }

          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final clipsJson = (data['clips'] as List<dynamic>? ?? []);
          loaded = clipsJson
              .whereType<Map<String, dynamic>>()
              .map(ClipProduct.fromJson)
              .where((clip) => clip.videoUrl.trim().isNotEmpty)
              .toList();

          _resolvedApiBaseUrl = base;
          break;
        } catch (e) {
          attemptErrors.add('$base -> $e');
        }
      }

      if (!mounted) return;

      if (loaded.isEmpty && attemptErrors.isNotEmpty) {
        setState(() {
          _clips = [];
          _error = 'Não foi possível carregar os clips.\n${attemptErrors.join('\n')}';
        });
        return;
      }

      setState(() {
        _clips = loaded;
        _current = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clips = [];
        _error = 'Não foi possível carregar os clips.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleClipCta(ClipProduct clip) async {
    if (clip.ctaType == 'product' && clip.productId != null) {
      try {
        final uri = Uri.parse('$_resolvedApiBaseUrl/shopify/products/${clip.productId}');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final product = Product.fromJson(data);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: product,
                initialColor: clip.color,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // fallback to snackbar below
      }
    }

    if (clip.ctaType == 'url' && clip.ctaTarget != null && clip.ctaTarget!.isNotEmpty) {
      final target = Uri.tryParse(clip.ctaTarget!);
      if (target != null) {
        await launchUrl(target, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Abrindo ${clip.productName}…',
          style: poppins(size: 13, weight: FontWeight.w600, color: CP.black),
        ),
        backgroundColor: CP.beige,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> _buildApiBaseCandidates() {
    final bases = <String>{ApiConstants.apiUrl};

    final apiUri = Uri.tryParse(ApiConstants.apiUrl);
    final port = apiUri?.port == 0 ? 3000 : (apiUri?.port ?? 3000);
    final pathPrefix = (apiUri?.path ?? '/api').replaceAll(RegExp(r'/$'), '');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      bases.add('http://10.0.2.2:$port$pathPrefix');
      bases.add('http://127.0.0.1:$port$pathPrefix');
    }

    bases.add('http://localhost:$port$pathPrefix');

    return bases.toList(growable: false);
  }

  void _goNext() {
    if (_clips.length <= 1) return;
    final next = (_current + 1) % _clips.length;
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _screenActive.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClipsStoriesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _screenActive.value = widget.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: CP.black,
        body: Center(
          child: CircularProgressIndicator(color: CP.blue),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: CP.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 40),
                const SizedBox(height: 10),
                Text(_error!, style: poppins(size: 14, color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _loadClips,
                  style: ElevatedButton.styleFrom(backgroundColor: CP.blue),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_clips.isEmpty) {
      return Scaffold(
        backgroundColor: CP.black,
        body: Center(
          child: Text(
            'Nenhum clip ativo no momento',
            style: poppins(size: 14, color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CP.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: _clips.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _ClipPlayer(
              clip: _clips[i],
              isActive: i == _current,
              onVideoEnd: _goNext,
              onLike: () => setState(() {
                _clips[i].isLiked = !_clips[i].isLiked;
              }),
              onCheckout: () => _handleClipCta(_clips[i]),
              screenActive: _screenActive,
            ),
          ),
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: _ProgressSegments(total: _clips.length, current: _current),
          ),
          Positioned(
            top: top + 20,
            left: 0,
            right: 0,
            child: _TopBar(
              onBack: widget.onNavigateBack ?? () {},
            ),
          ),
          Positioned(
            top: top + 70,
            left: 16,
            child: const _AutoBadge(),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegments extends StatefulWidget {
  final int total;
  final int current;

  const _ProgressSegments({required this.total, required this.current});

  @override
  State<_ProgressSegments> createState() => _ProgressSegmentsState();
}

class _ProgressSegmentsState extends State<_ProgressSegments>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressSegments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.total, (i) {
        return Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(2),
            ),
            child: i < widget.current
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : i == widget.current
                    ? AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _ctrl.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        );
      }),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: CP.white, size: 15),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'CIA ',
                        style: poppins(size: 15, weight: FontWeight.w700, letterSpacing: 3),
                      ),
                      TextSpan(
                        text: 'PIJAMAS',
                        style: poppins(size: 15, weight: FontWeight.w700, color: CP.blue, letterSpacing: 3),
                      ),
                    ]),
                  ),
                  Text(
                    'CLIPS',
                    style: poppins(
                      size: 9,
                      weight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _AutoBadge extends StatefulWidget {
  const _AutoBadge();

  @override
  State<_AutoBadge> createState() => _AutoBadgeState();
}

class _AutoBadgeState extends State<_AutoBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CP.blue.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CP.blue.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: 0.38 + 0.62 * _ctrl.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: CP.blue, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'AUTO',
            style: poppins(size: 10, weight: FontWeight.w700, color: CP.blue, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ClipPlayer extends StatefulWidget {
  final ClipProduct clip;
  final bool isActive;
  final VoidCallback onVideoEnd;
  final VoidCallback onLike;
  final VoidCallback onCheckout;
  final ValueListenable<bool> screenActive;

  const _ClipPlayer({
    required this.clip,
    required this.isActive,
    required this.onVideoEnd,
    required this.onLike,
    required this.onCheckout,
    required this.screenActive,
  });

  @override
  State<_ClipPlayer> createState() => kIsWeb ? _ClipPlayerWebState() : _ClipPlayerState();
}

class _ClipPlayerState extends State<_ClipPlayer> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  String? _initError;
  Timer? _endTimer;
  bool _paused = false;
  bool _pausedByVisibility = false;
  late final VoidCallback _screenListener;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _screenListener = _handleScreenActiveChange;
    widget.screenActive.addListener(_screenListener);
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.of(context)) {
      _ctrl?.pause();
      if (!_paused) {
        setState(() => _paused = true);
      }
    }
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.clip.videoUrl));
      await controller.initialize().timeout(const Duration(seconds: 12));
      controller.addListener(_listen);
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _ctrl = controller;
        _ready = true;
        _initError = null;
      });
      final videoInfo = controller.value;
      print('✅ CLIPS: Vídeo carregado com sucesso');
      print('  URL: ${widget.clip.videoUrl}');
      print('  Resolução: ${videoInfo.size.width.toInt()}x${videoInfo.size.height.toInt()}');
      print('  Duração: ${videoInfo.duration.inSeconds}s');
      print('  Aspect Ratio: ${videoInfo.aspectRatio.toStringAsFixed(2)}');

      if (widget.isActive && widget.screenActive.value) {
        await controller.play();
        if (_paused) {
          setState(() => _paused = false);
        }
      } else {
        await controller.pause();
        if (!_paused) {
          setState(() => _paused = true);
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      print('❌ CLIPS: Timeout ao carregar vídeo: ${widget.clip.videoUrl}');
      setState(() {
        _ready = false;
        _initError = 'Tempo esgotado ao carregar o vídeo.\n\n⚠️ Possível causa: Conexão lenta ou arquivo muito grande.';
      });
    } catch (e, stack) {
      if (!mounted) return;
      print('❌ CLIPS: Erro ao inicializar player');
      print('  URL: ${widget.clip.videoUrl}');
      print('  Erro: $e');
      print('  Stack: ${stack.toString().split('\n').take(3).join('\n')}');

      String detailedError = 'Falha ao reproduzir vídeo neste dispositivo.';
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('codec') || errorMsg.contains('format') || errorMsg.contains('unsupported')) {
        detailedError = 'Formato de vídeo não suportado neste dispositivo.\n\n⚠️ Possível causa: Codec incompatível (HEVC/H.265).';
      } else if (errorMsg.contains('network') || errorMsg.contains('connection') || errorMsg.contains('ssl') || errorMsg.contains('certificate')) {
        detailedError = 'Erro de conexão ao carregar vídeo.\n\n⚠️ Verifique sua conexão com a internet.';
      } else if (errorMsg.contains('memory') || errorMsg.contains('resource')) {
        detailedError = 'Vídeo muito pesado para este dispositivo.\n\n⚠️ Memória ou recursos insuficientes.';
      } else if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
        detailedError = 'Sem permissão para acessar o vídeo.\n\n⚠️ Verifique as permissões do app.';
      }

      setState(() {
        _ready = false;
        _initError = detailedError;
      });
    }
  }

  void _listen() {
    final controller = _ctrl;
    if (controller == null || !controller.value.isInitialized) return;
    final pos = controller.value.position;
    final dur = controller.value.duration;
    if (dur.inMilliseconds > 0 && pos.inMilliseconds >= dur.inMilliseconds - 200) {
      _endTimer?.cancel();
      _endTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) widget.onVideoEnd();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ClipPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenActive != widget.screenActive) {
      oldWidget.screenActive.removeListener(_screenListener);
      widget.screenActive.addListener(_screenListener);
      _handleScreenActiveChange();
    }
    if (widget.clip.id != oldWidget.clip.id || widget.clip.videoUrl != oldWidget.clip.videoUrl) {
      _retryInit();
      return;
    }
    if (!_ready) return;
    final controller = _ctrl;
    if (controller == null) return;
    if (widget.isActive && !oldWidget.isActive) {
      controller.seekTo(Duration.zero);
      if (!widget.screenActive.value) {
        controller.pause();
        if (!_paused) {
          setState(() => _paused = true);
        }
      } else {
        controller.play();
        if (_paused) {
          setState(() => _paused = false);
        }
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      controller.pause();
    }
  }

  void _handleScreenActiveChange() {
    final isScreenActive = widget.screenActive.value;
    if (!isScreenActive) {
      _pausedByVisibility = true;
      _ctrl?.pause();
      if (!_paused) {
        setState(() => _paused = true);
      }
      return;
    }

    if (_pausedByVisibility && widget.isActive) {
      _pausedByVisibility = false;
      _ctrl?.play();
      if (_paused) {
        setState(() => _paused = false);
      }
    }
  }

  void _togglePause() {
    if (!_ready) return;
    setState(() {
      _paused = !_paused;
      _paused ? _ctrl?.pause() : _ctrl?.play();
    });
  }

  Future<void> _retryInit() async {
    final controller = _ctrl;
    if (controller != null) {
      controller.removeListener(_listen);
      await controller.dispose();
    }
    if (!mounted) return;
    setState(() {
      _ctrl = null;
      _ready = false;
      _initError = null;
    });
    await _init();
  }

  Future<void> _openExternalVideo() async {
    final uri = Uri.tryParse(widget.clip.videoUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    widget.screenActive.removeListener(_screenListener);
    _endTimer?.cancel();
    final controller = _ctrl;
    if (controller != null) {
      controller.removeListener(_listen);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final videoLayer = _ready
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _ctrl!.value.size.width,
              height: _ctrl!.value.size.height,
              child: VideoPlayer(_ctrl!),
            ),
          )
        : widget.clip.thumbUrl != null && widget.clip.thumbUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.clip.thumbUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: CP.black),
                  ),
                  const Center(
                    child: CircularProgressIndicator(color: CP.blue, strokeWidth: 2.5),
                  ),
                ],
              )
            : Container(
                color: CP.black,
                child: const Center(
                  child: CircularProgressIndicator(color: CP.blue, strokeWidth: 2.5),
                ),
              );

    return GestureDetector(
      onTap: _togglePause,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            videoLayer,
            if (!_ready && _initError != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _initError!,
                        textAlign: TextAlign.center,
                        style: poppins(size: 13, color: Colors.white, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _retryInit,
                      style: ElevatedButton.styleFrom(backgroundColor: CP.blue),
                      child: const Text('Recarregar vídeo'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openExternalVideo,
                      child: const Text('Abrir vídeo externamente', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF05050C).withOpacity(0.97),
                      const Color(0xFF05050C).withOpacity(0.5),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
            if (_paused)
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.46),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_rounded, color: Colors.white, size: 36),
                ),
              ),
            Positioned(
              right: 14,
              bottom: 200,
              child: _SideActions(
                clip: widget.clip,
                onLike: widget.onLike,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomContent(
                clip: widget.clip,
                onCheckout: widget.onCheckout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Implementação Web usando HTML5 video
class _ClipPlayerWebState extends State<_ClipPlayer> with AutomaticKeepAliveClientMixin {
  bool _ready = false;
  String? _initError;
  String _videoId = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _videoId = 'video-${widget.clip.id}-${DateTime.now().millisecondsSinceEpoch}';
    _initWebVideo();
  }

  void _initWebVideo() {
    if (!kIsWeb) return;
    
    try {
      registerWebVideoFactory(
        _videoId,
        widget.clip.videoUrl,
        widget.isActive,
        (bool ready, String? error) {
          if (mounted) {
            setState(() {
              _ready = ready;
              _initError = error;
            });
          }
        },
      );
    } catch (e) {
      print('❌ CLIPS WEB: Erro ao registrar video element: $e');
      if (mounted) {
        setState(() {
          _ready = false;
          _initError = 'Erro ao inicializar player web.\n\n⚠️ $e';
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ClipPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.id != oldWidget.clip.id || widget.clip.videoUrl != oldWidget.clip.videoUrl) {
      setState(() {
        _videoId = 'video-${widget.clip.id}-${DateTime.now().millisecondsSinceEpoch}';
        _ready = false;
        _initError = null;
      });
      _initWebVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final videoLayer = (kIsWeb && _ready)
        ? HtmlElementView(viewType: _videoId)
        : widget.clip.thumbUrl != null && widget.clip.thumbUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.clip.thumbUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: CP.black),
                  ),
                  if (!_ready && _initError == null)
                    const Center(
                      child: CircularProgressIndicator(color: CP.blue, strokeWidth: 2.5),
                    ),
                ],
              )
            : Container(
                color: CP.black,
                child: _initError == null
                    ? const Center(
                        child: CircularProgressIndicator(color: CP.blue, strokeWidth: 2.5),
                      )
                    : null,
              );

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          videoLayer,
          if (_initError != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _initError!,
                      textAlign: TextAlign.center,
                      style: poppins(size: 13, color: Colors.white, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _videoId = 'video-${widget.clip.id}-${DateTime.now().millisecondsSinceEpoch}';
                        _ready = false;
                        _initError = null;
                      });
                      _initWebVideo();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: CP.blue),
                    child: const Text('Recarregar vídeo'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.clip.videoUrl);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Abrir vídeo externamente', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF05050C).withOpacity(0.97),
                    const Color(0xFF05050C).withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 200,
            child: _SideActions(
              clip: widget.clip,
              onLike: widget.onLike,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomContent(
              clip: widget.clip,
              onCheckout: widget.onCheckout,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _SideActions extends StatelessWidget {
  final ClipProduct clip;
  final VoidCallback onLike;

  const _SideActions({required this.clip, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideBtn(
          icon: clip.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: _fmt(clip.likes + (clip.isLiked ? 1 : 0)),
          color: clip.isLiked ? const Color(0xFFFF5050) : Colors.white,
          active: clip.isLiked,
          onTap: onLike,
        ),
        const SizedBox(height: 20),
        _ShareBtn(),
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _ShareBtn extends StatefulWidget {
  @override
  State<_ShareBtn> createState() => _ShareBtnState();
}

class _ShareBtnState extends State<_ShareBtn> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
  late final _scale = Tween(begin: 1.0, end: 0.84).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(18, 18),
                  painter: _ShareIconPainter(),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Compartilhar',
              style: poppins(size: 9.5, weight: FontWeight.w600, color: Colors.white.withOpacity(0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 2.5;
    final topRight = Offset(size.width * 0.82, size.height * 0.15);
    final bottomRight = Offset(size.width * 0.82, size.height * 0.85);
    final left = Offset(size.width * 0.18, size.height * 0.50);

    canvas.drawCircle(topRight, r, paint);
    canvas.drawCircle(bottomRight, r, paint);
    canvas.drawCircle(left, r, paint);

    canvas.drawLine(
      Offset(left.dx + r + 1, left.dy - r),
      Offset(topRight.dx - r - 1, topRight.dy + r),
      paint,
    );
    canvas.drawLine(
      Offset(left.dx + r + 1, left.dy + r),
      Offset(bottomRight.dx - r - 1, bottomRight.dy - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _SideBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  @override
  State<_SideBtn> createState() => _SideBtnState();
}

class _SideBtnState extends State<_SideBtn> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
  late final _scale = Tween(begin: 1.0, end: 0.84)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.active ? widget.color.withOpacity(0.2) : Colors.white.withOpacity(0.10),
                border: Border.all(
                  color: widget.active ? widget.color.withOpacity(0.4) : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: poppins(size: 9.5, weight: FontWeight.w600, color: Colors.white.withOpacity(0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomContent extends StatelessWidget {
  final ClipProduct clip;
  final VoidCallback onCheckout;

  const _BottomContent({required this.clip, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 22 + bottom),
      child: _ProductCard(clip: clip, onCheckout: onCheckout),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ClipProduct clip;
  final VoidCallback onCheckout;

  const _ProductCard({required this.clip, required this.onCheckout});

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = clip.thumbUrl != null && clip.thumbUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: CP.beige,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CP.blue.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 40, offset: const Offset(0, 8)),
            BoxShadow(color: CP.blue.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  // Product Image/Thumbnail
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: CP.blue.withOpacity(0.12),
                      border: Border.all(color: CP.blue.withOpacity(0.22)),
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(clip.thumbUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? const Icon(Icons.bed_rounded, color: CP.blue, size: 26)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clip.productName,
                          style: poppins(size: 13, weight: FontWeight.w700, color: const Color(0xFF1a1a2e)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clip.subtitle?.isNotEmpty == true ? clip.subtitle! : clip.productSku,
                          style: poppins(size: 10.5, color: CP.gray, weight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clip.variantLabel != null && clip.variantLabel!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              clip.variantLabel!,
                              style: poppins(size: 10.5, color: CP.blue, weight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 5),
                        // Price Display
                        Row(
                          children: [
                            Text(
                              _formatPrice(clip.price),
                              style: poppins(size: 15, weight: FontWeight.w700, color: CP.blue),
                            ),
                            if (clip.originalPrice != null && clip.originalPrice! > clip.price) ...[
                              const SizedBox(width: 7),
                              Text(
                                _formatPrice(clip.originalPrice!),
                                style: poppins(size: 11, color: CP.gray, weight: FontWeight.w400).copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: CP.gray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: CP.blue.withOpacity(0.10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onCheckout,
                    child: Row(
                      children: [
                        Text(
                          clip.ctaLabel,
                          style: poppins(size: 13, weight: FontWeight.w700, color: CP.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CP.blue.withOpacity(0.12),
                            border: Border.all(color: CP.blue.withOpacity(0.35), width: 1.5),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: CP.blue, size: 13),
                        ),
                      ],
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
