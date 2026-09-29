import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tuile statistique sur les pages d'examens blancs (Terminés / Score moyen /
/// Meilleur score / Niveau estimé...). Icône colorée + valeur en gras + suffixe
/// optionnel (ex: "/50") en gris + label en bas. Layout identique entre QCM et
/// EE/EO depuis le lot de refacto.
class ExamStatCard extends StatelessWidget {
  const ExamStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.suffix,
    required this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String suffix;
  final Color valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                  text: value,
                  style: AppFonts.ui(
                    size: 18,
                    weight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.muted2,
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.ui(size: 10.5, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
