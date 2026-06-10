import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Header personnalise pour les ecrans EO/EE, calque sur la classe `.app-header`
/// du mockup HTML : bouton retour bleu a gauche, titre encre au centre, action
/// optionnelle a droite (texte "Quitter" ou icone info).
///
/// **Back robuste** : `context.canPop()` peut renvoyer false dans go_router
/// quand l'écran est arrivé via `context.go`, après `pushReplacement` en
/// chaîne, ou quand l'utilisateur a deep-link / hot-reload. Dans ce cas, le
/// fallback est `context.go(fallbackRoute)` (par défaut le hub TCF) — pas
/// un no-op silencieux. Les écrans qui ont une cible précise (hub d'examen
/// blanc complet, etc.) la passent via `fallbackRoute`.
class ProductionAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const ProductionAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.fallbackRoute = '/tcf',
    this.rightAction,
  });

  final String title;
  final VoidCallback? onBack;

  /// Route empruntée quand `context.canPop()` renvoie false. Garantit que la
  /// flèche arrière fait toujours quelque chose.
  final String fallbackRoute;

  /// Bouton droit optionnel (ex: ProductionAppHeaderQuit, ProductionAppHeaderInfo).
  final Widget? rightAction;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

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
                  icon: const Icon(LucideIcons.chevronLeft, size: 26),
                  color: AppColors.blue,
                  onPressed: onBack ?? () => _defaultBack(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: AppFonts.ui(
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
        style: AppFonts.ui(
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
      icon: const Icon(LucideIcons.info, size: 22),
      color: AppColors.blue,
      onPressed: onPressed,
    );
  }
}
