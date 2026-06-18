import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/providers/logistics_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
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
      final missionId = await ref.read(scanQrProvider(rawValue).future);
      if (mounted) {
        context.pushReplacement(AppRoutes.missionDetailPath(missionId));
      }
    } catch (_) {
      setState(() {
        _error = 'QR invalide ou mission introuvable.';
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
        title: const Text('Scanner QR Mission'),
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
          // Caméra
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay de visée
          _ScanOverlay(),

          // Indicateur de chargement
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
                      'Recherche de la mission…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Message d'erreur
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

          // Hint en bas
          if (!_isProcessing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Placez le QR code de la mission dans le cadre',
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
    final boxSize = size.width * 0.65;
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
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
