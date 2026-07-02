import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Виджет отображения/выбора рейтинга (1-5) для уловов и приманок.
class RatingStars extends StatelessWidget {
  final int rating;
  final int max;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.max = 5,
    this.size = 22,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (index) {
        final filled = index < rating;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? AppColors.star : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          size: size,
        );
        if (onChanged == null) return icon;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged!(index + 1),
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        );
      }),
    );
  }
}
