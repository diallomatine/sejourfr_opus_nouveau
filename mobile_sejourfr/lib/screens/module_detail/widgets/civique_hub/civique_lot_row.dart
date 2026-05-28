import 'package:flutter/material.dart';

import '../../../../core/models/lot_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Ligne d'un lot Civique dans le hub d'un thème. Pendant de `QcmLevelRow` —
/// pastille numérotée à gauche, titre + sous-titre, badge score ou cadenas
/// ou chevron à droite. Le tint léger signale les lots déjà faits.
class CiviqueLotRow extends StatelessWidget {
  const CiviqueLotRow({
    super.key,
    required this.lot,
    required this.onTap,
    this.locked = false,
  });

  final LotDto lot;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final done = lot.lastScore != null;
    final color = done ? _scoreColor(lot) : AppColors.blue;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? color.withValues(alpha: 0.3) : AppColors.line,
        ),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? color : AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${lot.numero}',
                    style: AppFonts.jakarta(
                      size: 13,
                      weight: FontWeight.w800,
                      color: done ? AppColors.white : AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lot ${lot.numero}',
                        style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        done
                            ? '${lot.totalQuestions} questions · déjà fait'
                            : '${lot.totalQuestions} questions',
                        style: AppFonts.jakarta(
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (locked)
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  )
                else if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${lot.lastScore}/${lot.totalQuestions}',
                      style: AppFonts.jakarta(
                        size: 12,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted2,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(LotDto lot) {
    if (lot.lastScore == null || lot.totalQuestions == 0) {
      return AppColors.muted;
    }
    final ratio = lot.lastScore! / lot.totalQuestions;
    if (ratio >= 0.7) return AppColors.green;
    if (ratio >= 0.4) return AppColors.amber;
    return AppColors.red;
  }
}
