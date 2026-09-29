import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Carte d'un slot d'examen blanc complet (cf. `MExamens` maquette) : chip
/// numéro 50 px — **plein accent** quand le slot est passé, gris bordé sinon,
/// cadenas si verrouillé. Présentationnelle : TCF (rouge) et Civique (bleu)
/// la composent avec leur sous-titre et leur trailing d'état.
class FullExamSlotCard extends StatelessWidget {
  const FullExamSlotCard({
    super.key,
    required this.slot,
    required this.filled,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.trailing,
    this.lockedEmpty = false,
    required this.onTap,
  });

  final int slot;

  /// Chip plein accent (slot passé) vs gris bordé (slot vide).
  final bool filled;
  final Color accent;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Widget trailing;
  final bool lockedEmpty;
  final VoidCallback onTap;

  /// Pill « ✓ Fait » teinté accent — trailing standard d'un slot passé.
  static Widget faitPill(Color accent, {Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ??
            Color.alphaBlend(
              accent.withValues(alpha: 0.12),
              AppColors.white,
            ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.check, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            'Fait',
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: lockedEmpty ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: filled ? accent : AppColors.surface2,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border:
                          filled ? null : Border.all(color: AppColors.line),
                      boxShadow: filled ? AppShadows.card : null,
                    ),
                    child: lockedEmpty
                        ? const Icon(LucideIcons.lock,
                            size: 18, color: AppColors.inkFaint)
                        : Text(
                            '$slot',
                            style: AppFonts.display(
                              size: 21,
                              color: filled
                                  ? AppColors.white
                                  : AppColors.inkFaint,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style:
                              AppFonts.ui(size: 15, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
