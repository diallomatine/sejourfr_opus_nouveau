import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Carte "Nombre de mots" avec code-couleur dynamique selon la plage :
///   current < min            → ROUGE (hors plage basse)
///   min ≤ current ≤ max      → VERT (dans la plage)
///   max < current ≤ max*1.2  → ORANGE (légèrement au-dessus)
///   current > max*1.2        → ROUGE (trop long)
class MotsCard extends StatelessWidget {
  const MotsCard({
    super.key,
    required this.current,
    required this.min,
    required this.max,
  });

  final int current;
  final int min;
  final int max;

  _MotsState get _state {
    if (max <= 0) return _MotsState.below;
    final tolerance = (max * 1.2).floor();
    if (current < min) return _MotsState.below;
    if (current <= max) return _MotsState.inRange;
    if (current <= tolerance) return _MotsState.overTolerance;
    return _MotsState.tooLong;
  }

  ({Color accent, Color bg, Color border}) get _colors {
    switch (_state) {
      case _MotsState.inRange:
        return (
          accent: AppColors.green,
          bg: AppColors.green.withValues(alpha: 0.10),
          border: AppColors.green.withValues(alpha: 0.30),
        );
      case _MotsState.overTolerance:
        return (
          accent: AppColors.amber,
          bg: AppColors.amber.withValues(alpha: 0.12),
          border: AppColors.amber.withValues(alpha: 0.30),
        );
      case _MotsState.below:
      case _MotsState.tooLong:
        return (
          accent: AppColors.red,
          bg: AppColors.red.withValues(alpha: 0.08),
          border: AppColors.red.withValues(alpha: 0.25),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final isBold = _state == _MotsState.below || _state == _MotsState.tooLong;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 18, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de mots',
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min $min / Max $max',
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: c.border),
            ),
            child: Text(
              '$current mots',
              style: AppFonts.ui(
                size: 13,
                weight: isBold ? FontWeight.w800 : FontWeight.w700,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MotsState { below, inRange, overTolerance, tooLong }
