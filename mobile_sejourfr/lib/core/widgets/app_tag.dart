import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TagTone { blue, red, neutral, success, amber, ghost }

/// Badge pill de la refonte 2026 (cf. `Badge` maquette) : fond teinté doux,
/// Hanken 12 w600, icône optionnelle. Le libellé est rendu tel quel.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.tone = TagTone.blue,
    this.icon,
  });

  final String label;
  final TagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (tone) {
      case TagTone.blue:
        bg = AppColors.blueLight;
        fg = AppColors.blueDark;
        break;
      case TagTone.red:
        bg = AppColors.redLight;
        fg = AppColors.red;
        break;
      case TagTone.success:
        bg = AppColors.greenLight;
        fg = AppColors.green;
        break;
      case TagTone.amber:
        bg = AppColors.amberLight;
        fg = const Color(0xFF9A6A0B);
        break;
      case TagTone.neutral:
        bg = AppColors.surface3;
        fg = AppColors.inkSoft;
        break;
      case TagTone.ghost:
        bg = Colors.transparent;
        fg = AppColors.inkSoft;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: tone == TagTone.ghost
            ? Border.all(color: AppColors.line)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w600,
              color: fg,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
