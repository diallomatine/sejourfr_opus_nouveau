import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Option d'un [SegmentedTabs]. Si [color] est fournie, le segment actif est
/// plein de cette couleur avec texte blanc (cf. toggle TCF rouge / Civique
/// bleu de la maquette) ; sinon fond blanc, texte ink.
class SegmentTab<T> {
  const SegmentTab({required this.value, required this.label, this.color});

  final T value;
  final String label;
  final Color? color;
}

/// Contrôle segmenté de la refonte 2026 (cf. `Segmented` maquette) :
/// piste `surface3` en pill, segment actif surélevé d'une ombre douce.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: tab.value == value
                        ? (tab.color ?? AppColors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: tab.value == value ? AppShadows.card : null,
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: tab.value == value
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: tab.value == value
                          ? (tab.color != null
                              ? AppColors.white
                              : AppColors.ink)
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Toggle parcours canonique : TCF rouge / Civique bleu (cf. maquette).
List<SegmentTab<T>> parcoursSegments<T>({
  required T tcf,
  required T civique,
}) =>
    [
      SegmentTab(value: tcf, label: 'TCF IRN', color: AppColors.red),
      SegmentTab(value: civique, label: 'Examen civique', color: AppColors.blue),
    ];
