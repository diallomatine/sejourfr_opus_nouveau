import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Case à cocher maison (pas d'UI kit). La case se coche toujours au tap.
///
/// [labelTappable] : si `true` (défaut), taper le label coche aussi — pratique
/// pour un libellé en texte simple. Le mettre à `false` quand le label contient
/// ses propres zones tappables (ex. liens) pour éviter le conflit de gestes :
/// seule la case réagit alors, les liens gardent leur propre tap.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.labelTappable = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  final bool labelTappable;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: _box(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: label,
          ),
        ),
      ],
    );
    if (!labelTappable) return content;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _box() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? AppColors.blue : AppColors.white,
        border: Border.all(
          color: value ? AppColors.blue : AppColors.line,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: value
          ? const Icon(LucideIcons.check, size: 15, color: AppColors.white)
          : null,
    );
  }
}
