import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'level_pill.dart';

/// Strip "Tache X sur 3 [· sous-titre]" + barre 4px + level pill **sous la barre**.
/// Calque sur la classe `.progress-wrapper` du mockup HTML (cf. EE 01).
class ProductionProgressStrip extends StatelessWidget {
  const ProductionProgressStrip({
    super.key,
    required this.current,
    required this.total,
    required this.niveau,
    this.subtitle,
    this.trailing,
  });

  final int current;
  final int total;

  /// Niveau CECRL affiche en pill sous la barre. On accepte un niveau brut
  /// (`A2`, `B1`, `B2`) car les taches stockent une string.
  final String niveau;

  /// Optionnel : "Recit d'experience" pour completer "Tache 2 sur 3".
  final String? subtitle;

  /// Optionnel : timer pill ou autre widget aligne a droite du label.
  final Widget? trailing;

  NiveauCecrl? get _parsedNiveau {
    switch (niveau.toUpperCase()) {
      case 'A1':
        return NiveauCecrl.a1;
      case 'A2':
        return NiveauCecrl.a2;
      case 'B1':
        return NiveauCecrl.b1;
      case 'B2':
        return NiveauCecrl.b2;
      case 'C1':
        return NiveauCecrl.c1;
      case 'C2':
        return NiveauCecrl.c2;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : current / total;
    final pillNiveau = _parsedNiveau;
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
          if (pillNiveau != null) ...[
            SizedBox(height: singleTask ? 8 : 10),
            Align(
              alignment: Alignment.centerLeft,
              child: LevelPill(level: pillNiveau, small: true),
            ),
          ],
        ],
      ),
    );
  }
}
