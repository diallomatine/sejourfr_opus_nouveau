import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Vue d'erreur réseau pour les pages « Examens blancs ». Icône rouge +
/// libellé + bouton retry. Accent paramétrable (bleu pour QCM, rouge pour
/// EE/EO) pour rester aligné avec le ton de la page.
class ExamsErrorView extends StatelessWidget {
  const ExamsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.accent,
  });

  final String message;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les examens',
            style: AppFonts.jakarta(
                size: 14, weight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, color: accent),
            label: Text(
              'Réessayer',
              style: AppFonts.jakarta(
                  size: 13, weight: FontWeight.w700, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
