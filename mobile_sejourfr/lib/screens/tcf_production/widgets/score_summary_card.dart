import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'cecrl_scale.dart';
import 'level_pill.dart';

/// Carte hero du score : grand chiffre /20 a gauche, niveau CECRL a droite,
/// barre de niveaux en bas.
class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({
    super.key,
    required this.note,
    required this.niveau,
  });

  /// Note 0..20. `null` si l'IA n'a pas pu noter (ex: production trop courte).
  final double? note;
  final NiveauCecrl? niveau;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre evaluation',
            style: AppFonts.mono(
              size: 10,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
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
                            text: note == null ? '—' : _formatNote(note!),
                            style: AppFonts.display(
                              size: 40,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' / 20',
                            style: AppFonts.ui(
                              size: 16,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (niveau != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Niveau estime : ${niveau!.displayName}',
                        style: AppFonts.ui(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (niveau != null) LevelPill(level: niveau!),
            ],
          ),
          const SizedBox(height: 18),
          if (niveau != null) CecrlScale(level: niveau!, dark: true),
        ],
      ),
    );
  }

  static String _formatNote(double note) {
    if (note == note.truncateToDouble()) return note.toInt().toString();
    return note.toStringAsFixed(1).replaceAll('.', ',');
  }
}
