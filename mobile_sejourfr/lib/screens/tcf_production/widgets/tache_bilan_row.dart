import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Ligne récap d'une tâche dans le bilan d'une session EE/EO.
///
/// Layout : titre de la tâche en haut, sous-titre récap en bas ("Note 14/20",
/// "Évaluation en cours…" ou "Non évaluée"). À droite : un chevron qui signale
/// qu'on peut tapoter pour ouvrir l'évaluation détaillée. Le chevron disparaît
/// quand la ligne n'est pas tappable (pending ou absence d'éval). Aucun niveau
/// CECRL par tâche : il n'apparaît qu'au bilan d'épreuve (examen blanc).
class TacheBilanRow extends StatelessWidget {
  const TacheBilanRow({
    super.key,
    required this.name,
    this.score,
    this.pending = false,
  });

  final String name;
  final double? score;

  /// Quand `true`, l'évaluation IA tourne encore : on affiche un mini-spinner
  /// et le texte "Évaluation en cours" au lieu du score.
  final bool pending;

  String _formatScore(double s) {
    if (s == s.truncateToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final isEvaluated = hasScore;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _Subtitle(
                  pending: pending,
                  score: hasScore ? _formatScore(score!) : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (pending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (isEvaluated)
            const Icon(
              LucideIcons.chevronRight,
              size: 22,
              color: AppColors.muted2,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                LucideIcons.circleMinus,
                size: 18,
                color: AppColors.muted2,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sous-titre récap sous le nom de la tâche, selon l'état :
/// - Score connu → "Note 14/20"
/// - Évaluation en cours → "Évaluation IA en cours…"
/// - Aucune éval → "Non évaluée"
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.pending, required this.score});

  final bool pending;
  final String? score;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch ((pending, score)) {
      (true, _) => ('Évaluation IA en cours…', AppColors.blue),
      (false, final String s) when s.isNotEmpty => ('Note $s / 20', AppColors.ink2),
      _ => ('Non évaluée', AppColors.muted),
    };
    return Text(
      text,
      style: AppFonts.ui(
        size: 12,
        weight: pending ? FontWeight.w600 : FontWeight.w500,
        color: color,
      ),
    );
  }
}
