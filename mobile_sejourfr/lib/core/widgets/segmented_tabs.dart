import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Option d'un [SegmentedTabs]. Si [color] est fournie, le segment actif est
/// plein de cette couleur avec texte blanc (segment du module civique, toggle
/// de parcours) ; sinon fond blanc, texte ink.
class SegmentTab<T> {
  const SegmentTab({required this.value, required this.label, this.color});

  final T value;
  final String label;
  final Color? color;
}

/// La forme d'un [SegmentedTabs].
///
/// [pill] : le contrôle historique de la refonte 2026 (piste en pilule).
/// [module] : le segment « Plan | Entraînement | Examens » de Navigation v2
/// (`.segment.segment-3` de la maquette) — piste à coins arrondis, volets
/// rectangles. Les rayons de la maquette (18 / 13 px) sont arrondis aux
/// tokens [AppRadii.lg] / [AppRadii.md]. Miroir web : `ModuleSegment`.
enum SegmentedTabsShape { pill, module }

/// Contrôle segmenté de la refonte 2026 (cf. `Segmented` maquette) :
/// piste `surface3`, segment actif surélevé d'une ombre douce.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.shape = SegmentedTabsShape.pill,
  });

  final List<SegmentTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;
  final SegmentedTabsShape shape;

  @override
  Widget build(BuildContext context) {
    final module = shape == SegmentedTabsShape.module;
    final trackRadius = module ? AppRadii.lg : AppRadii.pill;
    final thumbRadius = module ? AppRadii.md : AppRadii.pill;
    return Container(
      padding: EdgeInsets.all(module ? 5 : 3),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (module && i > 0) const SizedBox(width: 6),
            Expanded(child: _segment(tabs[i], module, thumbRadius)),
          ],
        ],
      ),
    );
  }

  Widget _segment(SegmentTab<T> tab, bool module, double radius) {
    final active = tab.value == value;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(tab.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: module
              ? const EdgeInsets.symmetric(vertical: 11, horizontal: 8)
              : const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? (tab.color ?? AppColors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: active ? AppShadows.card : null,
          ),
          child: Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: module ? 13 : 13.5,
              weight: active
                  ? (module ? FontWeight.w800 : FontWeight.w700)
                  : (module ? FontWeight.w700 : FontWeight.w600),
              color: active
                  ? (tab.color != null ? AppColors.white : AppColors.ink)
                  : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle parcours canonique : chaque module dans SA couleur — TCF bleu,
/// Civique rouge (tokens de module, Navigation v2 X1).
List<SegmentTab<T>> parcoursSegments<T>({
  required T tcf,
  required T civique,
}) =>
    [
      SegmentTab(value: tcf, label: 'TCF IRN', color: AppColors.moduleTcf),
      SegmentTab(
        value: civique,
        label: 'Examen civique',
        color: AppColors.moduleCivique,
      ),
    ];
