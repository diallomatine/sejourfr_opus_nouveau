import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte standard de la refonte 2026 (cf. `MCard` maquette) : fond blanc,
/// bord `line`, coins 18, ombre très douce.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.onTap,
    this.border,
    this.boxShadow,
    this.borderRadius = AppRadii.lg,
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
        boxShadow: boxShadow ?? AppShadows.card,
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
