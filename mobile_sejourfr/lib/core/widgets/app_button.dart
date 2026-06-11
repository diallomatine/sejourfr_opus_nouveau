import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Variantes de la refonte 2026 (cf. `Button` maquette).
///
/// `secondary` est l'alias historique d'`outline` — ne plus l'utiliser dans
/// du code neuf.
enum AppButtonVariant { primary, accent, soft, outline, ghost, danger, secondary }

/// Bouton pill de la refonte 2026 : coins pleinement arrondis, Hanken w600,
/// icône optionnelle à gauche ([icon]) ou à droite ([iconRight]).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconRight,
    this.height = 52,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final IconData? iconRight;
  final double height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    final Color background;
    final Color foreground;
    final Color borderColor;
    var shadow = true;

    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.blue;
        foreground = AppColors.white;
        borderColor = Colors.transparent;
        break;
      case AppButtonVariant.accent:
      case AppButtonVariant.danger:
        background = AppColors.red;
        foreground = AppColors.white;
        borderColor = Colors.transparent;
        break;
      case AppButtonVariant.soft:
        background = AppColors.blueLight;
        foreground = AppColors.blueDark;
        borderColor = Colors.transparent;
        shadow = false;
        break;
      case AppButtonVariant.outline:
      case AppButtonVariant.secondary:
        background = AppColors.white;
        foreground = AppColors.ink;
        borderColor = AppColors.line;
        shadow = false;
        break;
      case AppButtonVariant.ghost:
        background = Colors.transparent;
        foreground = AppColors.inkSoft;
        borderColor = Colors.transparent;
        shadow = false;
        break;
    }

    final iconSize = height >= 50 ? 20.0 : 18.0;
    final fontSize = height >= 50 ? 16.0 : 14.5;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: isDisabled ? background.withValues(alpha: 0.5) : background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: borderColor),
              boxShadow: shadow && !isDisabled ? AppShadows.card : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: iconSize, color: foreground),
                        const SizedBox(width: 9),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: AppFonts.ui(
                            size: fontSize,
                            weight: FontWeight.w600,
                            color: foreground,
                            height: 1.0,
                          ),
                        ),
                      ),
                      if (iconRight != null) ...[
                        const SizedBox(width: 9),
                        Icon(iconRight, size: iconSize, color: foreground),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
