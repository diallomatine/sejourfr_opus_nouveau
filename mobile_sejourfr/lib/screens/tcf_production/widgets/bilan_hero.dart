import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import 'cecrl_scale.dart';

/// Carte "Bilan global" sur fond bleu dégradé : eyebrow mono + moyenne /20
/// à gauche, niveau CECRL plancher à droite (règle TCF IRN), barre A1→C2
/// en bas. Alignée sur le pattern hero des autres écrans bilan (TCF complet,
/// EE/EO results).
class BilanHero extends StatelessWidget {
  const BilanHero({
    super.key,
    required this.moyenneSur20,
    required this.niveauGlobal,
    this.correspondanceTcf,
  });

  /// Moyenne des notes /20 (null tant qu'aucune submission n'a été évaluée).
  final double? moyenneSur20;

  /// Niveau CECRL plancher des évaluations disponibles (règle TCF IRN).
  final NiveauCecrl? niveauGlobal;

  /// Fourchette de note officielle du TCF pour ce niveau (backend). Null tant
  /// qu'aucun niveau n'est exploitable — le bloc n'est alors pas rendu.
  final CorrespondanceTcf? correspondanceTcf;

  @override
  Widget build(BuildContext context) {
    final hasResult = moyenneSur20 != null || niveauGlobal != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BILAN DE LA SESSION',
            style: AppFonts.mono(
              size: 10,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note moyenne',
                      style: AppFonts.ui(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: moyenneSur20 == null ? '—' : formatScore(moyenneSur20!),
                            style: AppFonts.display(
                              size: 44,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ).copyWith(height: 1, letterSpacing: -1.5),
                          ),
                          TextSpan(
                            text: ' / 20',
                            style: AppFonts.ui(
                              size: 18,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.65),
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
                      'Niveau plancher',
                      style: AppFonts.ui(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        niveauGlobal!.displayName,
                        style: AppFonts.ui(
                          size: 18,
                          weight: FontWeight.w800,
                          color: AppColors.blue,
                        ).copyWith(letterSpacing: -0.3),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (niveauGlobal != null) ...[
            const SizedBox(height: 18),
            CecrlScale(level: niveauGlobal!, dark: true),
          ],
          if (correspondanceTcf != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correspondanceTcf!.phrase,
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grille officielle du TCF IRN. Notre note ci-dessus utilise la '
                    'même échelle et porte, comme au TCF, sur l\'épreuve entière.',
                    style: AppFonts.ui(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!hasResult) ...[
            const SizedBox(height: 12),
            Text(
              'L\'évaluation IA est en cours sur tes productions.',
              style: AppFonts.ui(
                size: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
