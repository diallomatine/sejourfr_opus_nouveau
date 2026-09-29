import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_button.dart';
import 'fixed_action_bar.dart';

/// « Examens blancs », collé en bas du détail d'une épreuve TCF ou d'un thème
/// civique : bouton pill bleu plein (`AppColors.blue`), cible à gauche.
/// Miroir web : `ExamsActionBar` (`app/_components/hub/ExamsActionBar.tsx`).
class ExamsActionBar extends StatelessWidget {
  const ExamsActionBar({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FixedActionBar(
      child: AppButton(
        label: 'Examens blancs',
        icon: LucideIcons.target,
        onPressed: onPressed,
      ),
    );
  }
}
