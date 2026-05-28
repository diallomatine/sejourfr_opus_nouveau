import 'package:flutter/material.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Ligne d'un critere : icone bubble coloree + nom + score colore + barre 4px.
/// Equivalent de `.criterion-row` du mockup HTML.
/// Pas de card autour : a inserer dans une carte parent (`results-summary-card`).
class CriterionRow extends StatelessWidget {
  const CriterionRow({super.key, required this.criterion});

  final CriterionScore criterion;

  Color get _color {
    final n = criterion.noteSurVingt;
    if (n >= 15) return AppColors.green;
    if (n >= 10) return AppColors.amber;
    return AppColors.red;
  }

  Color get _bubbleBg {
    final n = criterion.noteSurVingt;
    if (n >= 15) return AppColors.green.withValues(alpha: 0.12);
    if (n >= 10) return AppColors.amber.withValues(alpha: 0.12);
    return AppColors.red.withValues(alpha: 0.12);
  }

  IconData _iconForCode(String code) {
    switch (code) {
      case 'pertinence':
        return Icons.adjust_rounded;
      case 'organisation':
      case 'coherence':
        return Icons.format_list_bulleted_rounded;
      case 'vocabulaire':
        return Icons.book_outlined;
      case 'grammaire':
        return Icons.spellcheck_rounded;
      case 'orthographe':
        return Icons.text_fields_rounded;
      case 'prononciation':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.fact_check_outlined;
    }
  }

  /// Le backend joint desormais `label` depuis la grille de la tache. On le
  /// privilegie ; cette table sert de fallback pour les anciennes evaluations.
  String _labelForCode(String code) {
    switch (code) {
      case 'pertinence':
        return 'Pertinence du contenu';
      case 'grammaire':
        return 'Correction grammaticale';
      case 'vocabulaire':
      case 'lexique':
        return 'Richesse lexicale';
      case 'coherence':
      case 'organisation':
        return 'Cohérence du discours';
      case 'orthographe':
        return 'Orthographe et ponctuation';
      case 'prononciation':
        return 'Prononciation';
      case 'clarte_orale':
      case 'fluidite':
        return 'Clarté et fluidité';
      default:
        return code;
    }
  }

  String _formatNote(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _bubbleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconForCode(criterion.code), size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  criterion.label ?? _labelForCode(criterion.code),
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _formatNote(criterion.noteSurVingt),
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: color,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barre alignee avec le label (42px = bubble 32 + gap 10).
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (criterion.noteSurVingt / 20).clamp(0, 1),
                minHeight: 4,
                backgroundColor: AppColors.line2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (criterion.commentaire.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                criterion.commentaire,
                style: AppFonts.jakarta(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
