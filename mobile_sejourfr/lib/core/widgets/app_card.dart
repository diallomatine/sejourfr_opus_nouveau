import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte standard SejourFR (fond blanc, bord line, ombre douce).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.white,
    this.onTap,
    this.border,
    this.boxShadow,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.line, width: 1),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
    );
  }
}
