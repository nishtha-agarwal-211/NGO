import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/theme.dart';

/// Reusable shimmer loading widgets used across multiple screens.
/// Eliminates duplicated shimmer-loading-card code.

/// Shimmer placeholder for a list tile / card row.
class ShimmerListTile extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerListTile({
    super.key,
    this.height = 60,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        margin: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: 4,
            ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a horizontal scrolling card.
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    super.key,
    this.width = 200,
    this.height = 140,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a grid tile (e.g. photo gallery).
class ShimmerGridTile extends StatelessWidget {
  const ShimmerGridTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a stat value (number).
class ShimmerStatValue extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerStatValue({
    super.key,
    this.width = 40,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the donation stat (on gradient bg).
class ShimmerDonationValue extends StatelessWidget {
  const ShimmerDonationValue({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white24,
      highlightColor: Colors.white54,
      child: Container(
        width: 100,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Builds a column of shimmer list tiles (for loading states).
class ShimmerListColumn extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListColumn({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => ShimmerListTile(height: itemHeight),
      ),
    );
  }
}

/// Shimmer for a full list loading state (e.g. member/donor list).
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 88,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
      ),
    );
  }
}
