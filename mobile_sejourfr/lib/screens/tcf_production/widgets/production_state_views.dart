import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

/// Vue d'erreur partagée par les quatre écrans du module Compétences.
class ProductionErrorView extends StatelessWidget {
  const ProductionErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Réessayer',
                icon: LucideIcons.refreshCw,
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 44,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue « contenu pas encore prêt » (aucune compétence / aucun sujet actif).
class ProductionEmptyView extends StatelessWidget {
  const ProductionEmptyView({
    super.key,
    this.title = 'Bientôt disponible',
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.hourglass, size: 34, color: AppColors.muted2),
            const SizedBox(height: 12),
            Text(title, style: AppFonts.display(size: 18)),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
