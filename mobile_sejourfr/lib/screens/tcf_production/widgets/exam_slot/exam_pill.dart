import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Pastille arrondie (radius 999) utilisée pour les chips d'info dans une
/// carte de slot d'examen (durée, niveau de difficulté...). Texte Jakarta
/// 10/700.
class ExamPill extends StatelessWidget {
  const ExamPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppFonts.jakarta(size: 10, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}
