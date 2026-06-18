import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/products/presentation/providers/products_provider.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await _controller.stop();
      final product =
          await ref.read(productByReferenceProvider(rawValue).future);
      if (!mounted) return;
      if (product != null) {
        context.pushReplacement(AppRoutes.productDetailPath(product.id));
      } else {
        setState(() {
          _error = 'Produit introuvable pour le code "$rawValue".';
          _isProcessing = false;
        });
        await _controller.start();
      }
    } catch (_) {
      setState(() {
        _error = 'Erreur lors de la recherche du produit.';
        _isProcessing = false;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un article'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
            tooltip: 'Lampe torche',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay de visée
          _ScanOverlay(),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: AppSizes.md),
                    Text(
                      'Recherche du produit…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          if (_error != null)
            Positioned(
              bottom: 80,
              left: AppSizes.paddingPage,
              right: AppSizes.paddingPage,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: AppSizes.iconSm),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: AppSizes.fontSm),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: AppSizes.iconSm),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isProcessing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Placez le code-barres de l\'article dans le cadre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.55),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(color: Colors.transparent),
          Center(
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
