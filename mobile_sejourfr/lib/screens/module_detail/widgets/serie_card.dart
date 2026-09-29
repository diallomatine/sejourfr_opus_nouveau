import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/lot_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';

/// Carte d'une série d'entraînement (cf. `MSeries` maquette) : chip numéro
/// 46 px teinté par l'accent quand la série est faite, badge meilleur score
/// coloré par le ratio, icône refaire / play / cadenas. Partagée entre les
/// séries TCF par niveau et les séries d'un thème civique.
class SerieCard extends StatelessWidget {
  const SerieCard({
    super.key,
    required this.lot,
    required this.accent,
    required this.soft,
    required this.locked,
    required this.onTap,
  });

  final LotDto lot;
  final Color accent;
  final Color soft;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = lot.lastScore != null;
    final ratio = (done && lot.totalQuestions > 0)
        ? lot.lastScore! / lot.totalQuestions
        : null;
    final scoreTone = ratio == null
        ? TagTone.neutral
        : ratio >= 0.7
            ? TagTone.success
            : ratio >= 0.4
                ? TagTone.amber
                : TagTone.red;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: done ? soft : AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: Text(
                '${lot.numero}',
                style: AppFonts.display(
                  size: 18,
                  color: done ? accent : AppColors.inkFaint,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Série ${lot.numero}',
                    style: AppFonts.ui(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${lot.totalQuestions} questions',
                  style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                ),
                const SizedBox(height: 6),
                if (done)
                  AppTag(
                    // `lastScore` est le score du DERNIER attempt fini sur ce
                    // lot (cf. LotDto backend), pas le meilleur.
                    label: 'Dernier ${lot.lastScore}/${lot.totalQuestions}',
                    tone: scoreTone,
                    icon: scoreTone == TagTone.success
                        ? LucideIcons.check
                        : null,
                  )
                else
                  const AppTag(
                      label: 'Pas encore commencé', tone: TagTone.neutral),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            locked
                ? LucideIcons.lock
                : done
                    ? LucideIcons.refreshCw
                    : LucideIcons.play,
            size: 19,
            color: locked ? AppColors.inkFaint : AppColors.blue,
          ),
        ],
      ),
    );
  }
}
