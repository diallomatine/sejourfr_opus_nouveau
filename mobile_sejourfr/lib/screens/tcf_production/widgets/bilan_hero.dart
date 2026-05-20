import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'cecrl_scale.dart';

/// Carte "Bilan global" sur fond bleu degrade : moyenne des scores a gauche,
/// niveau global a droite, barre CECRL A1->C2 en bas.
/// Equivalent de `.bilan-hero` du mockup HTML.
class BilanHero extends StatelessWidget {
  const BilanHero({
    super.key,
    required this.moyenneSur20,
    required this.niveauGlobal,
  });

  /// Moyenne des notes sur 20 (peut etre nulle si aucune submission n'a abouti).
  final double? moyenneSur20;
  final NiveauCecrl? niveauGlobal;

  String _formatScore(double s) {
    if (s == s.truncateToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score global (moyenne)',
                      style: AppFonts.jakarta(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: moyenneSur20 == null ? '—' : _formatScore(moyenneSur20!),
                            style: AppFonts.fraunces(
                              size: 40,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '/20',
                            style: AppFonts.jakarta(
                              size: 20,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (niveauGlobal != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Niveau global',
                      style: AppFonts.jakarta(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        niveauGlobal!.displayName,
                        style: AppFonts.jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (niveauGlobal != null) CecrlScale(level: niveauGlobal!, dark: true),
        ],
      ),
    );
  }
}
