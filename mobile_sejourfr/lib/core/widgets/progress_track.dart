import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barre de progression fine de la refonte 2026 (cf. `Bar` maquette) :
/// piste `surface3` arrondie, remplissage animé à l'apparition.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.color = AppColors.blue,
    this.trackColor = AppColors.surface3,
    this.height = 8,
    this.animate = true,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final fraction = (value.clamp(0, 100)) / 100;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : fraction, end: fraction.toDouble()),
        duration: Duration(milliseconds: animate ? 800 : 0),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => FractionallySizedBox(
          widthFactor: animated,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
      ),
    );
  }
}
