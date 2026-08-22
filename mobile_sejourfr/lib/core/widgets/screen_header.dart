import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// En-tête d'écran de la refonte 2026 (cf. `MHeader` maquette).
///
/// À poser **au-dessus** de la zone scrollable (Column → header + Expanded),
/// pas dans le scroll : il est fixe avec un fond translucide flouté. `large`
/// donne le titre 26 des écrans racine ; sinon 19 avec ellipse.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.sub,
    this.onBack,
    this.right,
    this.large = false,
    this.solid = false,
  });

  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final Widget? right;
  final bool large;

  /// Variante **pleine** : fond bleu de marque, texte blanc. Ajoutee le
  /// 2026-08-21 pour l'ecran d'une tache EE/EO, ou le numero de tache doit
  /// s'imposer. Les 19 autres appelants ne passent pas ce drapeau et gardent
  /// le bandeau clair translucide : **ne pas en faire le defaut**.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: solid
                ? AppColors.blue
                : AppColors.bg.withValues(alpha: 0.86),
            border: Border(
              bottom: BorderSide(
                color: solid ? AppColors.blue : AppColors.lineSoft,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack!, solid: solid),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // 2 lignes même hors `large` : les titres de thème
                      // civique (« Principes et valeurs de la République »)
                      // ne tiennent pas sur une ligne à 19.
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        size: large ? 26 : 19,
                        color: solid ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          color: solid
                              ? AppColors.white.withValues(alpha: 0.82)
                              : AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (right != null) ...[
                const SizedBox(width: 10),
                right!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, this.solid = false});

  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: solid
          ? AppColors.white.withValues(alpha: 0.18)
          : AppColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            LucideIcons.arrowLeft,
            size: 19,
            color: solid ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
