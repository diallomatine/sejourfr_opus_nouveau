import 'package:flutter/material.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Bloc de correction d'un exemple : label rouge "Original :" + texte, label
/// vert "Correction :" + texte vert gras, label gris "Explication :" + texte.
/// Equivalent de `.correction-block` du mockup HTML.
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
          _Line(
            label: 'Original :',
            labelColor: AppColors.red,
            text: example.original,
            textColor: AppColors.ink,
          ),
          const SizedBox(height: 4),
          _Line(
            label: 'Correction :',
            labelColor: AppColors.green,
            text: example.corrige,
            textColor: AppColors.green,
            textBold: true,
          ),
          if (example.explication.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Explication : ',
                    style: AppFonts.jakarta(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  TextSpan(
                    text: example.explication,
                    style: AppFonts.jakarta(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
            style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          TextSpan(
            text: text,
            style: AppFonts.jakarta(
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
