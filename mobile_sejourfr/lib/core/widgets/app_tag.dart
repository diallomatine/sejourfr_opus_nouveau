import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TagTone { blue, red, neutral, success, amber, ghost }

class AppTag extends StatelessWidget {
  const AppTag({super.key, required this.label, this.tone = TagTone.blue});

  final String label;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;

    switch (tone) {
      case TagTone.blue:
        bg = AppColors.blueLight;
        border = AppColors.blue.withValues(alpha: 0.3);
        fg = AppColors.blue;
        break;
      case TagTone.red:
        bg = AppColors.redLight;
        border = AppColors.red.withValues(alpha: 0.3);
        fg = AppColors.red;
        break;
      case TagTone.success:
        bg = AppColors.green.withValues(alpha: 0.08);
        border = AppColors.green.withValues(alpha: 0.35);
        fg = AppColors.green;
        break;
      case TagTone.amber:
        bg = AppColors.amber.withValues(alpha: 0.1);
        border = AppColors.amber.withValues(alpha: 0.4);
        fg = AppColors.amber;
        break;
      case TagTone.neutral:
        bg = AppColors.line2;
        border = AppColors.line;
        fg = AppColors.muted;
        break;
      case TagTone.ghost:
        bg = Colors.transparent;
        border = AppColors.line;
        fg = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.mono(
          size: 10,
          color: fg,
          letterSpacing: 1.0,
        ).copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
