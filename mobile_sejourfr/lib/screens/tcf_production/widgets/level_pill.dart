import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Pastille A1 / A2 / B1 / B2 / C1 / C2 colorée par strate :
///   A1/A2 -> vert clair, B1 -> bleu, B2/C1/C2 -> violet.
/// Distincte du `AppTag` existant (CSP/CR/NAT) qui sert pour les parcours.
class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.level, this.small = false});

  final NiveauCecrl level;
  final bool small;

  Color get _bgColor {
    switch (level) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
      case NiveauCecrl.a2:
        return AppColors.green.withValues(alpha: 0.12);
      case NiveauCecrl.b1:
        return AppColors.blueLight;
      case NiveauCecrl.b2:
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        // Pas de violet officiel dans AppColors -> on bricole un fond doux.
        return const Color(0xFFF3EEFE);
    }
  }

  Color get _textColor {
    switch (level) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
      case NiveauCecrl.a2:
        return AppColors.green;
      case NiveauCecrl.b1:
        return AppColors.blue;
      case NiveauCecrl.b2:
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        // Aligne sur --violet du mockup HTML (etait #6D28D9 -- legerement plus fonce).
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        level.displayName,
        style: AppFonts.jakarta(
          size: small ? 11 : 12,
          weight: FontWeight.w700,
          color: _textColor,
        ),
      ),
    );
  }
}
