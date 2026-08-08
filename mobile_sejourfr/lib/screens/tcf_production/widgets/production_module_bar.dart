import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Les trois modes du parcours de production, tels que déclarés par la
/// maquette (`data-mode` : `learn` / `topics` / `simulate`).
enum ProductionModuleTab { competences, sujets, examens }

/// Barre de navigation **du module** (`nav.bottom` de la maquette) : carte
/// blanche flottante à trois entrées, icône au-dessus du libellé, posée en bas
/// de l'écran sur un fondu vers le fond de page.
///
/// C'est elle qui pilote Compétences / Sujets / Examens — la barre d'onglets
/// du haut de la maquette (`.mode-tabs`) n'est **pas** reproduite : elle dit la
/// même chose deux fois.
///
/// ⚠ Elle ne coexiste avec aucune autre barre : les écrans du parcours TCF
/// EE/EO sont déclarés **hors du `ShellRoute`** (cf. `app_router.dart`), donc
/// la navigation globale de l'application n'y est pas rendue.
class ProductionModuleBar extends StatelessWidget {
  const ProductionModuleBar({
    super.key,
    required this.active,
    required this.accent,
    required this.onChanged,
  });

  final ProductionModuleTab active;
  final Color accent;
  final ValueChanged<ProductionModuleTab> onChanged;

  /// Hauteur à réserver en bas d'une liste pour que le dernier élément ne
  /// passe pas sous la barre.
  static const double reservedHeight = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        // Fondu du prototype : transparent → fond à 30 % → fond plein.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0),
            AppColors.bg.withValues(alpha: 0.85),
            AppColors.bg,
          ],
          stops: const [0, 0.3, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.md,
          ),
          child: Row(
            children: [
              for (final tab in ProductionModuleTab.values) ...[
                if (tab != ProductionModuleTab.values.first)
                  const SizedBox(width: 5),
                Expanded(
                  child: _BarButton(
                    tab: tab,
                    on: tab == active,
                    accent: accent,
                    onTap: () => onChanged(tab),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tab,
    required this.on,
    required this.accent,
    required this.onTap,
  });

  final ProductionModuleTab tab;
  final bool on;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = on ? accent : AppColors.inkSoft;
    return Material(
      color: on ? accent.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 19, color: foreground),
              const SizedBox(height: 4),
              Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.ui(
                  size: 10,
                  weight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label => switch (tab) {
        ProductionModuleTab.competences => 'Compétences',
        ProductionModuleTab.sujets => 'Sujets',
        ProductionModuleTab.examens => 'Examens',
      };

  IconData get _icon => switch (tab) {
        ProductionModuleTab.competences => LucideIcons.target,
        ProductionModuleTab.sujets => LucideIcons.layoutList,
        ProductionModuleTab.examens => LucideIcons.clipboardCheck,
      };
}
