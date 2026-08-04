import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Liste encartée de la refonte 2026 (cf. `MGroup` maquette) : carte blanche
/// bordée dont les enfants sont séparés par un divider indenté à 67 px
/// (aligné sur le texte des [ListRow]).
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 67),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de liste (cf. `MRow` maquette) : icône en pastille 40, titre 15,
/// sous-titre 12.5, slot droit (chevron par défaut si tappable).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.sub,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.badge,
    this.right,
    this.onTap,
  });

  final String title;
  final String? sub;
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final Widget? badge;
  final Widget? right;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.blueLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                icon,
                size: 21,
                color: iconColor ?? AppColors.blueDark,
              ),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        // Les libellés de thème civique dépassent la largeur
                        // d'une ligne : on enroule plutôt que de tronquer.
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                  ),
                ],
              ],
            ),
          ),
          if (right != null)
            right!
          else if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 17,
              color: AppColors.inkFaint,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Titre de section entre deux blocs (cf. `MSectionTitle` maquette).
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppFonts.display(size: 17))),
          if (action != null) action!,
        ],
      ),
    );
  }
}
