import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Header personnalise pour les ecrans EO/EE, calque sur la classe `.app-header`
/// du mockup HTML : bouton retour bleu a gauche, titre encre au centre, action
/// optionnelle a droite (texte "Quitter" ou icone info).
class ProductionAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const ProductionAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightAction,
  });

  final String title;
  final VoidCallback? onBack;

  /// Bouton droit optionnel (ex: ProductionAppHeaderQuit, ProductionAppHeaderInfo).
  final Widget? rightAction;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded, size: 26),
                  color: AppColors.blue,
                  onPressed: onBack ??
                      () {
                        if (context.canPop()) context.pop();
                      },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: AppFonts.jakarta(
                        size: 17,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Align(alignment: Alignment.centerRight, child: rightAction ?? const SizedBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Action droite "Quitter" en texte bleu (cf. screen EO 01 du HTML).
class ProductionAppHeaderQuit extends StatelessWidget {
  const ProductionAppHeaderQuit({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        'Quitter',
        style: AppFonts.jakarta(
          size: 15,
          weight: FontWeight.w600,
          color: AppColors.blue,
        ),
      ),
    );
  }
}

/// Action droite "info" (cf. screen EE 01 du HTML).
class ProductionAppHeaderInfo extends StatelessWidget {
  const ProductionAppHeaderInfo({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline_rounded, size: 22),
      color: AppColors.blue,
      onPressed: onPressed,
    );
  }
}
