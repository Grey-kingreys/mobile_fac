import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

// ── Loader plein écran ────────────────────────────────────────────────────────

class AppFullLoader extends StatelessWidget {
  const AppFullLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Loader inline (petit) ─────────────────────────────────────────────────────

class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key, this.size = 20.0});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    );
  }
}

// ── Overlay loader (bloque l'UI pendant une opération) ────────────────────────

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: AppFullLoader(message: message),
          ),
      ],
    );
  }
}

// ── Shimmer carte ─────────────────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 80,
    this.borderRadius = AppSizes.radiusMd,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Liste shimmer (pour les listes en cours de chargement) ────────────────────

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
    );
  }
}
