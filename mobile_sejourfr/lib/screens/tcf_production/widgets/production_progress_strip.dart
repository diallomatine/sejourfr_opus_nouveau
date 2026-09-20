import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Strip « Tâche X sur 3 [· sous-titre] » + barre 4 px.
///
/// ⚠️ **La pastille de niveau a été retirée** (demande du propriétaire,
/// 2026-09-20) : elle affichait `production_tasks.niveau_cible`, un palier que
/// le vrai TCF ne rattache à aucune tâche, et qu'aucun moteur n'utilise.
/// C'est **l'affichage** qui part ; la colonne reste servie.
class ProductionProgressStrip extends StatelessWidget {
  const ProductionProgressStrip({
    super.key,
    required this.current,
    required this.total,
    this.subtitle,
    this.trailing,
  });

  final int current;
  final int total;

  /// Optionnel : "Recit d'experience" pour completer "Tache 2 sur 3".
  final String? subtitle;

  /// Optionnel : timer pill ou autre widget aligne a droite du label.
  final Widget? trailing;



  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : current / total;
    final singleTask = total <= 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppFonts.ui(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    children: singleTask
                        ? [
                            // En single-task on supprime la mention "X sur N" qui
                            // n'apporte rien -> on affiche juste le displayTitle.
                            TextSpan(text: subtitle ?? 'Entraînement libre'),
                          ]
                        : [
                            TextSpan(text: 'Tâche $current sur $total'),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              TextSpan(
                                text: ' · $subtitle',
                                style: AppFonts.ui(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted2,
                                ),
                              ),
                          ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (!singleTask) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 4,
                backgroundColor: AppColors.line2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
