import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Badge numéroté d'un slot d'examen blanc. 3 états :
/// - locked → fond `line2` + icône cadenas
/// - next → fond `blue` plein + texte blanc (mis en avant comme prochain à
///   faire)
/// - default → fond [baseBg] + texte [baseFg] (tinté selon la difficulté
///   pour EE/EO, neutre `blueLight/blue` pour QCM)
class ExamNumberBadge extends StatelessWidget {
  const ExamNumberBadge({
    super.key,
    required this.number,
    required this.locked,
    required this.next,
    required this.baseBg,
    required this.baseFg,
  });

  final int number;
  final bool locked;
  final bool next;
  final Color baseBg;
  final Color baseFg;

  @override
  Widget build(BuildContext context) {
    final bg = locked
        ? AppColors.line2
        : next
            ? AppColors.blue
            : baseBg;
    final fg = locked
        ? AppColors.muted2
        : next
            ? AppColors.white
            : baseFg;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: locked
          ? Icon(Icons.lock_outline_rounded, size: 18, color: fg)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'N°',
                  style: AppFonts.jakarta(
                    size: 9,
                    color: fg.withValues(alpha: 0.75),
                    height: 1,
                  ),
                ),
                Text(
                  number.toString().padLeft(2, '0'),
                  style: AppFonts.jakarta(
                    size: 18,
                    weight: FontWeight.w800,
                    color: fg,
                    height: 1.1,
                  ),
                ),
              ],
            ),
    );
  }
}
