import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Ce que cette production a changé dans le Plan — **une ligne**, en fin de
/// rapport, et rien d'autre. Pas la liste des compétences observées : le
/// candidat vient lire sa correction, pas un tableau de bord.
///
/// ⚠️ **Bloc absent = cas NORMAL** (rien n'a bougé, ou les observations,
/// écrites après la correction, ne sont pas encore là) : on n'affiche alors ni
/// message, ni attente, ni « indisponible ». Les deux moitiés sont
/// indépendamment nullables — on ne rend que celle qui existe.
///
/// Miroir de `PlanChangeLine` côté web.
class PlanChangeLine extends StatelessWidget {
  const PlanChangeLine({super.key, required this.change});

  final PlanChange? change;

  @override
  Widget build(BuildContext context) {
    final value = change;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final confirmed = value.confirmedSkill;
    final next = value.newPriority;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (confirmed != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.check,
                            size: 15,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${confirmed.title} confirmée',
                            style: AppFonts.ui(
                              size: 13.5,
                              weight: FontWeight.w800,
                              height: 1.3,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (next != null) ...[
                    if (confirmed != null) const SizedBox(height: 3),
                    Text(
                      'Nouvelle priorité : ${next.title}.',
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => context.push(AppRoutes.plan),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue,
                backgroundColor: AppColors.blueLight,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir',
                    style: AppFonts.ui(size: 12.5, weight: FontWeight.w800),
                  ),
                  const SizedBox(width: 5),
                  const Icon(LucideIcons.arrowRight, size: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
