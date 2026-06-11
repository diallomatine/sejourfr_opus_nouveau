import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barre d'action fixée en bas d'écran (cf. `MFixedBar` maquette) : fondu
/// vers le fond pour laisser le contenu défiler dessous. À poser sous la
/// zone scrollable dans une Column (ou en `bottomNavigationBar`).
class FixedActionBar extends StatelessWidget {
  const FixedActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0.62, 1],
          colors: [AppColors.bg, AppColors.bg.withValues(alpha: 0)],
        ),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
