import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Carte cliquable du prototype : ombre douce au repos, **retour au toucher**
/// (le survol `translateY(-2px)` + ombre n'a pas d'équivalent tactile — on le
/// transpose en enfoncement). Le bord se teinte quand la carte est « traitée ».
///
/// Promue de `screens/tcf_production/widgets/production_blocks.dart` vers
/// `core/widgets/` quand le Plan a repris l'anatomie de la carte de compétence
/// (`PressableCard` + `ProgressRing` + titre + état + chevron) : un import
/// `screens/plan/` → `screens/tcf_production/` aurait couplé deux features.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 23,
    this.borderColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final Color? borderColor;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: widget.borderColor ?? AppColors.line),
            boxShadow: _down ? AppShadows.md : AppShadows.card,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Chevron encerclé du prototype (`.chev`, 30×30) : même forme sur la carte de
/// compétence, celle d'un petit sujet et celle du Plan.
class CardChevron extends StatelessWidget {
  const CardChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: AppColors.inkFaint,
      ),
    );
  }
}
