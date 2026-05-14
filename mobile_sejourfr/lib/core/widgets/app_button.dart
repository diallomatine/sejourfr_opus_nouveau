import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    final Color background;
    final Color foreground;
    final Color borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.blue;
        foreground = AppColors.white;
        borderColor = AppColors.blue;
        break;
      case AppButtonVariant.secondary:
        background = AppColors.white;
        foreground = AppColors.blue;
        borderColor = AppColors.blue;
        break;
      case AppButtonVariant.ghost:
        background = Colors.transparent;
        foreground = AppColors.muted;
        borderColor = AppColors.line;
        break;
      case AppButtonVariant.danger:
        background = AppColors.red;
        foreground = AppColors.white;
        borderColor = AppColors.red;
        break;
    }

    final button = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: isDisabled ? background.withValues(alpha: 0.45) : background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        Icon(icon, size: 18, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: AppFonts.jakarta(
                            size: 15,
                            weight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return button;
  }
}
