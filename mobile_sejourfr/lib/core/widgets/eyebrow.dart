import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Eyebrow type "§ 01 — Mention" qu'on retrouve partout dans l'app.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.mono(
        size: 10,
        color: color,
        letterSpacing: 2.0,
      ).copyWith(height: 1.0, fontWeight: FontWeight.w500),
    );
  }
}
