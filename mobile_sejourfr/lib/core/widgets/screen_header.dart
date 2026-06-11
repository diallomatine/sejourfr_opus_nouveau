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
  });

  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final Widget? right;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.86),
            border: const Border(
              bottom: BorderSide(color: AppColors.lineSoft),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: large ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(size: large ? 26 : 19),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.inkFaint,
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
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(LucideIcons.arrowLeft, size: 19, color: AppColors.ink),
        ),
      ),
    );
  }
}
