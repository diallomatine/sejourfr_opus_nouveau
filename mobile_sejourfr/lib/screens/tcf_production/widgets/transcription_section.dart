import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bandeau d'avertissement IA + carte de la transcription brute.
/// Affichee uniquement pour les submissions EO (avec un audio derriere).
/// Equivalent de `.transcription-info-banner` + `.transcription-text-card`.
class TranscriptionSection extends StatelessWidget {
  const TranscriptionSection({super.key, required this.transcription});

  final String transcription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Transcription generee par IA\n',
                        style: AppFonts.jakarta(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                      TextSpan(
                        text: 'Des erreurs peuvent subsister.',
                        style: AppFonts.jakarta(
                          size: 12.5,
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            transcription,
            style: AppFonts.jakarta(
              size: 14,
              color: AppColors.ink,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}
