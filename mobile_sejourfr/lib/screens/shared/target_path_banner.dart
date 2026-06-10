import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Petit bandeau qui rappelle le parcours visé par l'utilisateur sur les écrans
/// de setup (entraînement / examen blanc). Permet de modifier en un tap.
class TargetPathBanner extends StatelessWidget {
  const TargetPathBanner({super.key, required this.procedure});

  final TargetProcedure procedure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.flag, size: 16, color: AppColors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Vous préparez : '),
                  TextSpan(
                    text:
                        '${procedure.shortLabel} (${procedure.wire})',
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ],
                style: AppFonts.ui(size: 13, color: AppColors.ink),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final loc = GoRouterState.of(context).matchedLocation;
              context.push(
                '${AppRoutes.targetPath}?from=${Uri.encodeComponent(loc)}',
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Modifier',
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
