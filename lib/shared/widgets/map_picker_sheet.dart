import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

/// Bottom sheet carte OpenStreetMap — style épingle fixe (Uber-style).
///
/// Retourne [LatLng] confirmé ou null si annulé.
///
/// Usage :
///   final position = await MapPickerSheet.show(context, initial: LatLng(9.54, -13.68));
class MapPickerSheet extends StatefulWidget {
  const MapPickerSheet({super.key, this.initial});

  final LatLng? initial;

  static Future<LatLng?> show(BuildContext context, {LatLng? initial}) {
    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => MapPickerSheet(initial: initial),
    );
  }

  @override
  State<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<MapPickerSheet>
    with SingleTickerProviderStateMixin {
  // Centre par défaut : Conakry, Guinée
  static const _defaultCenter = LatLng(9.5370, -13.6773);
  static const _defaultZoom = 12.0;

  late final MapController _mapCtrl;
  late LatLng _center;
  bool _moving = false;
  late AnimationController _pinAnim;
  late Animation<double> _pinLift;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _center = widget.initial ?? _defaultCenter;

    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinLift = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _pinAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _pinAnim.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      _pinAnim.forward();
      setState(() => _moving = true);
    } else if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _pinAnim.reverse();
      setState(() {
        _moving = false;
        _center = event.camera.center;
      });
    } else if (event is MapEventMove) {
      setState(() => _center = event.camera.center);
    }
  }

  String _fmt(double v, {bool isLat = true}) {
    final dir = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'O');
    return '${v.abs().toStringAsFixed(5)}° $dir';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Carte ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _defaultZoom,
              onMapEvent: _onMapEvent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.djoulagest.mobile',
                maxZoom: 19,
              ),
            ],
          ),

          // ── Épingle fixe au centre ──────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pinLift,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, -(_pinLift.value + 44)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tête de l'épingle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: _moving ? 20 : 10,
                            spreadRadius: _moving ? 4 : 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Pointe de l'épingle
                    CustomPaint(
                      size: const Size(16, 10),
                      painter: _PinTailPainter(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ombre portée de l'épingle au sol
          Center(
            child: AnimatedBuilder(
              animation: _pinLift,
              builder: (_, __) => Container(
                width: 12 + _pinLift.value * 0.8,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15 - _pinLift.value * 0.005),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // ── Header (handle + titre) ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(moving: _moving),
          ),

          // ── Boutons zoom ──────────────────────────────────────────────────
          Positioned(
            right: AppSizes.md,
            bottom: 200,
            child: _ZoomControls(mapCtrl: _mapCtrl),
          ),

          // ── Panneau bas : coordonnées + bouton confirmer ─────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(
              center: _center,
              moving: _moving,
              fmt: _fmt,
              onConfirm: () => Navigator.of(context).pop(_center),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.moving});
  final bool moving;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.97),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightBg,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choisir la position',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppSizes.fontMd,
                          color: AppColors.gray900,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          moving ? 'Déplacez la carte…' : 'Centrez l\'épingle sur le lieu',
                          key: ValueKey(moving),
                          style: const TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Boutons zoom ─────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.mapCtrl});
  final MapController mapCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomBtn(
          icon: Icons.add_rounded,
          onTap: () {
            final z = mapCtrl.camera.zoom;
            mapCtrl.move(mapCtrl.camera.center, (z + 1).clamp(1, 19));
          },
        ),
        const SizedBox(height: 2),
        _ZoomBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            final z = mapCtrl.camera.zoom;
            mapCtrl.move(mapCtrl.camera.center, (z - 1).clamp(1, 19));
          },
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: AppColors.gray700),
        ),
      ),
    );
  }
}

// ─── Panneau bas ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.center,
    required this.moving,
    required this.fmt,
    required this.onConfirm,
    required this.onCancel,
  });

  final LatLng center;
  final bool moving;
  final String Function(double, {bool isLat}) fmt;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.lg + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coordonnées
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: moving ? AppColors.primaryLightBg : AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: moving ? AppColors.primary.withValues(alpha: 0.3) : AppColors.gray100,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  size: 18,
                  color: moving ? AppColors.primary : AppColors.gray400,
                ),
                const SizedBox(width: AppSizes.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt(center.latitude, isLat: true),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: moving ? AppColors.primary : AppColors.gray800,
                      ),
                    ),
                    Text(
                      fmt(center.longitude, isLat: false),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: moving ? AppColors.primary : AppColors.gray800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (moving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: InkWell(
                      onTap: moving ? null : onConfirm,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Confirmer la position',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Peintre pointe épingle ───────────────────────────────────────────────────

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
