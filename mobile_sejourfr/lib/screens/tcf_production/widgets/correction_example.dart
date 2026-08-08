import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Bloc de correction d'un exemple : la phrase du candidat, sa reformulation,
/// l'explication, puis le `gain` — ce que la version corrigee demontre de plus.
class CorrectionExampleCard extends StatelessWidget {
  const CorrectionExampleCard({super.key, required this.example});

  final CorrectionExample example;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeforeAfterLines(avant: example.original, apres: example.corrige),
          if (example.explication.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Explication : ',
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  TextSpan(
                    text: example.explication,
                    style: AppFonts.ui(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (example.gain != null) ...[
            const SizedBox(height: 10),
            _GainLine(gain: example.gain!),
          ],
        ],
      ),
    );
  }
}

/// Ce que la reformulation demontre de plus — le progres vise, pas le detail
/// corrige. Absent des evaluations anterieures au contrat courant.
class _GainLine extends StatelessWidget {
  const _GainLine({required this.gain});

  final String gain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 8),
            child: Icon(LucideIcons.trendingUp, size: 15, color: AppColors.green),
          ),
          Expanded(
            child: Text(
              gain,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.green,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Couple « phrase du candidat » → « phrase reecrite », partage par les
/// corrections et par la demonstration d'une priorite de travail : c'est la
/// meme idee rendue au meme endroit, avec les mots de son contexte.
class BeforeAfterLines extends StatelessWidget {
  const BeforeAfterLines({
    super.key,
    required this.avant,
    required this.apres,
    this.avantLabel = 'Original :',
    this.apresLabel = 'Correction :',
  }) : compact = false;

  /// Sans etiquettes : l'ancienne phrase **barree**, la nouvelle en vert. Deux
  /// lignes au lieu de quatre, et le sens se lit sans mot d'introduction — la
  /// rature dit « avant » mieux que le mot « avant ».
  const BeforeAfterLines.compact({
    super.key,
    required this.avant,
    required this.apres,
  })  : avantLabel = '',
        apresLabel = '',
        compact = true;

  final String avant;
  final String apres;
  final String avantLabel;
  final String apresLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            avant,
            style: AppFonts.ui(size: 13, color: AppColors.red, height: 1.45)
                .copyWith(decoration: TextDecoration.lineThrough),
          ),
          const SizedBox(height: 6),
          Text(
            apres,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.green,
              height: 1.45,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          label: avantLabel,
          labelColor: AppColors.red,
          text: avant,
          textColor: AppColors.ink,
        ),
        const SizedBox(height: 4),
        _Line(
          label: apresLabel,
          labelColor: AppColors.green,
          text: apres,
          textColor: AppColors.green,
          textBold: true,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.labelColor,
    required this.text,
    required this.textColor,
    this.textBold = false,
  });

  final String label;
  final Color labelColor;
  final String text;
  final Color textColor;
  final bool textBold;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          TextSpan(
            text: text,
            style: AppFonts.ui(
              size: 13,
              weight: textBold ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
