import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'level_pill.dart';

/// Carte de session dans l'historique : date + moyenne + niveau global + mini-pills par tache.
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

  NiveauCecrl? _modeNiveau() {
    final counts = <NiveauCecrl, int>{};
    for (final s in submissions) {
      final n = s.evaluation?.niveauCecrl;
      if (n != null) counts[n] = (counts[n] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final max = counts.values.reduce((a, b) => a > b ? a : b);
    final tops = counts.entries.where((e) => e.value == max).toList()
      ..sort((a, b) => a.key.scaleIndex.compareTo(b.key.scaleIndex));
    return tops.last.key;
  }

  DateTime _lastSubmittedAt() {
    return submissions
        .map((s) => s.submittedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'janv.', 'fevr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'aout', 'sept.', 'oct.', 'nov.', 'dec.'
    ];
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year} · $h:$m';
  }

  String _formatScore(double s) {
    if (s == s.truncateToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avgScore();
    final niveau = _modeNiveau();
    final date = _lastSubmittedAt();
    final completed = submissions.where((s) => s.evaluation != null).length;
    final total = submissions.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(date),
                        style: AppFonts.jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    if (completed < total)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Incomplete',
                          style: AppFonts.jakarta(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFFB5780E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: avg == null ? '—' : _formatScore(avg),
                                  style: AppFonts.fraunces(
                                    size: 28,
                                    weight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(
                                  text: '/20',
                                  style: AppFonts.jakarta(
                                    size: 14,
                                    weight: FontWeight.w500,
                                    color: AppColors.muted2,
                                  ),
                                ),
                                TextSpan(
                                  text: '   moyenne',
                                  style: AppFonts.jakarta(
                                    size: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$completed / $total taches evaluees',
                            style: AppFonts.jakarta(
                              size: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (niveau != null) LevelPill(level: niveau),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
