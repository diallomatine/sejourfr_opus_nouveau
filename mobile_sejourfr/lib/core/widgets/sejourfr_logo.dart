import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cocarde tricolore (3 cercles concentriques bleu / blanc / rouge).
class Cocarde extends StatelessWidget {
  const Cocarde({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CocardePainter()),
    );
  }
}

class _CocardePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * (30 / 48);
    final coreRadius = outerRadius * (14 / 48);

    canvas.drawCircle(center, outerRadius, Paint()..color = AppColors.blue);
    canvas.drawCircle(center, innerRadius, Paint()..color = AppColors.white);
    canvas.drawCircle(center, coreRadius, Paint()..color = AppColors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wordmark "Sejour FR" avec FR en rouge — taille configurable.
class SejourFrWordmark extends StatelessWidget {
  const SejourFrWordmark({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppFonts.jakarta(
          size: fontSize,
          weight: FontWeight.w800,
          color: AppColors.blue,
          letterSpacing: -0.6,
        ).copyWith(height: 1.0),
        children: const [
          TextSpan(text: 'Sejour'),
          TextSpan(
            text: 'FR',
            style: TextStyle(color: AppColors.red),
          ),
        ],
      ),
    );
  }
}

/// Sous-titre type "Examen civique · TCF" en mono majuscule.
class SejourFrTagline extends StatelessWidget {
  const SejourFrTagline({super.key, this.fontSize = 11});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppFonts.mono(
          size: fontSize,
          color: AppColors.muted,
          letterSpacing: 2.5,
        ),
        children: const [
          TextSpan(text: 'EXAMEN CIVIQUE'),
          TextSpan(text: '   ·   ', style: TextStyle(color: AppColors.red)),
          TextSpan(text: 'TCF'),
        ],
      ),
    );
  }
}

/// Bloc complet "logo + wordmark + tagline" pour splash/login/header.
class SejourFrLogoLockup extends StatelessWidget {
  const SejourFrLogoLockup({
    super.key,
    this.cocardeSize = 96,
    this.wordmarkSize = 40,
    this.taglineSize = 11,
    this.spacingBetween = 24,
    this.spacingTagline = 14,
  });

  final double cocardeSize;
  final double wordmarkSize;
  final double taglineSize;
  final double spacingBetween;
  final double spacingTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Cocarde(size: cocardeSize),
        SizedBox(height: spacingBetween),
        SejourFrWordmark(fontSize: wordmarkSize),
        SizedBox(height: spacingTagline),
        SejourFrTagline(fontSize: taglineSize),
      ],
    );
  }
}
