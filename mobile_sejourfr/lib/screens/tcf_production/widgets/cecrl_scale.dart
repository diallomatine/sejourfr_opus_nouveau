import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Barre du profil TCF IRN A1 -> B2 avec curseur sur le niveau atteint.
/// Les anciens niveaux C1/C2, encore lisibles dans l'historique, sont affichés
/// au plafond B2 de ce profil.
/// `dark = true` -> rendu pour fond bleu fonce (curseur blanc).
class CecrlScale extends StatelessWidget {
  const CecrlScale({super.key, required this.level, this.dark = false});

  final NiveauCecrl level;
  final bool dark;

  static const _labels = ['A1', 'A2', 'B1', 'B2'];
  static const _gradient = LinearGradient(colors: [
    Color(0xFFF87171), // rose A1
    Color(0xFFFB923C), // orange A2
    Color(0xFFFBBF24), // ambre B1
    Color(0xFF34D399), // vert B2
  ]);

  @override
  Widget build(BuildContext context) {
    final activeColor = dark ? Colors.white : AppColors.blue;
    final mutedColor =
        dark ? Colors.white.withValues(alpha: 0.6) : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_labels.length, (i) {
            final isActive = i == level.scaleIndex;
            return Text(
              _labels[i],
              style: AppFonts.mono(
                size: 10,
                color: isActive ? activeColor : mutedColor,
                letterSpacing: 1.2,
              ).copyWith(
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cursorLeft =
              (level.scaleIndex / (_labels.length - 1)) * (w - 14);
          return SizedBox(
            height: 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: cursorLeft,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dark ? AppColors.blue : Colors.white,
                      border: Border.all(
                        color: dark ? Colors.white : AppColors.blue,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
