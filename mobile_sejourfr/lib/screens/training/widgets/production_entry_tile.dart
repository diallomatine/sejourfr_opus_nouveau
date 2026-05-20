import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tile de navigation pour les epreuves d'expression (EO / EE) ajoutees sous la
/// liste des thematiques TCF. Visuel calque sur `_ThemeTile` (meme rayon, meme
/// border, meme padding) mais sans selection radio : tap = push immediat de
/// l'ecran de briefing.
class ProductionEntryTile extends StatelessWidget {
  const ProductionEntryTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.onLockedTap,
    this.locked = false,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;
  final bool locked;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked ? onLockedTap : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Opacity(
              opacity: locked ? 0.55 : 1.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: AppFonts.jakarta(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge!,
                                  style: AppFonts.mono(
                                    size: 9,
                                    color: AppColors.white,
                                    letterSpacing: 1.1,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    locked
                        ? Icons.lock_rounded
                        : Icons.chevron_right_rounded,
                    size: locked ? 16 : 20,
                    color: locked ? AppColors.muted2 : AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
