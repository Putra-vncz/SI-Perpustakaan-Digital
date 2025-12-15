import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/core.dart';

/// Reusable book cover image widget with placeholder fallback
class BookCoverImage extends StatelessWidget {
  final String? coverUrl;
  final double width;
  final double height;
  final double borderRadius;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    this.width = 60,
    this.height = 90,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: coverUrl != null && coverUrl!.isNotEmpty
          ? Image.network(
              coverUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder();
              },
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        LucideIcons.book,
        size: width * 0.4,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
