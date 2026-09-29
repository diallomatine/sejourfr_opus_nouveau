import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Badge numéroté d'un slot d'examen blanc (cf. maquette : carré 46 px,
/// numéro en Bricolage). 3 états :
/// - locked → fond `surface3` + icône cadenas
/// - next → fond `blue` plein + numéro blanc (prochain à faire)
/// - default → fond [baseBg] + numéro [baseFg] (tinté selon la difficulté
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
        ? AppColors.surface3
        : next
            ? AppColors.blue
            : baseBg;
    final fg = locked
        ? AppColors.muted2
        : next
            ? AppColors.white
            : baseFg;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: locked
          ? Icon(LucideIcons.lock, size: 18, color: fg)
          : Text(
              '$number',
              style: AppFonts.display(size: 19, color: fg),
            ),
    );
  }
}
