import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../production_result_labels.dart';
import 'task_palette.dart';

/// Pastille circulaire en tête de carte d'historique : numéro de tâche (T1
/// vert / T2 ambre / T3 rouge) pour une session mono-tâche, icône d'examen
/// (cercle bleu) pour une session multi-tâches (examen blanc complet).
class _Pastille extends StatelessWidget {
  const _Pastille({required this.submissions});

  final List<ProductionSubmissionDto> submissions;

  @override
  Widget build(BuildContext context) {
    final isExam = submissions.length >= 2;
    if (isExam) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.blueLight, shape: BoxShape.circle),
        child: const Icon(LucideIcons.clipboardCheck,
            size: 20, color: AppColors.blue),
      );
    }
    final tache = submissions.first.tacheNumero ?? 1;
    final (bg, fg) = taskPalette(tache);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text('$tache',
          style: AppFonts.ui(
              size: 14, weight: FontWeight.w800, color: fg)),
    );
  }
}

/// Carte de session dans l'historique.
///
/// Une session **d'examen blanc** (≥ 2 tâches) porte sa moyenne /20 : c'est le
/// seul périmètre auquel le TCF attache une note. Un **entraînement libre**
/// (1 tâche) porte son **niveau** — une « moyenne » sur une seule tâche, c'était
/// sa note, et une tâche isolée n'en reçoit pas (décision produit du
/// 2026-08-08).
///
/// Tap -> bilan complet de la session.
class HistorySessionCard extends StatelessWidget {
  const HistorySessionCard({
    super.key,
    required this.submissions,
    required this.onTap,
  });

  /// Toutes les submissions d'un meme attempt (>= 1). Triees par tacheNumero
  /// est preferable mais pas obligatoire (on n'utilise pas l'ordre ici).
  final List<ProductionSubmissionDto> submissions;
  final VoidCallback onTap;

  double? _avgScore() {
    final notes = submissions
        .map((s) => s.evaluation?.noteSurVingt)
        .whereType<double>()
        .toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  DateTime _lastSubmittedAt() {
    return submissions
        .map((s) => s.submittedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _title() => submissions.length >= 2
      ? 'Examen blanc complet'
      : 'Tâche ${submissions.first.tacheNumero ?? 1} · entraînement libre';

  @override
  Widget build(BuildContext context) {
    final isMulti = submissions.length >= 2;
    final avg = isMulti ? _avgScore() : null;
    final niveau = isMulti ? null : tacheNiveau(submissions.first.evaluation);
    final date = _lastSubmittedAt();
    final completed = submissions.where((s) => s.evaluation != null).length;
    final total = submissions.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pastille(submissions: submissions),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _title(),
                              style: AppFonts.ui(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (isMulti && completed < total) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Incomplet',
                                style: AppFonts.ui(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatLongDateTime(date),
                        style: AppFonts.ui(
                          size: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: isMulti
                                  ? (avg == null ? '—' : formatScore(avg))
                                  : (niveau == null
                                      ? '—'
                                      : tacheNiveauLabel(niveau)),
                              style: AppFonts.display(
                                size: isMulti ? 24 : 18,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (isMulti)
                              TextSpan(
                                text: '/20',
                                style: AppFonts.ui(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted2,
                                ),
                              ),
                            TextSpan(
                              text: isMulti
                                  ? '  moyenne · $completed/$total évaluées'
                                  : '  $completed/$total évaluée',
                              style: AppFonts.ui(
                                size: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronRight,
                    size: 20, color: AppColors.muted2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
