import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Les trois modes du parcours de production.
///
/// L'enum vivait dans `production_module_bar.dart`, supprimé avec la barre
/// flottante du bas : la maquette client place la navigation des modes **dans
/// le flux**, juste sous la carte « Prochain entraînement ».
enum ProductionModuleTab { competences, sujets, examens }

/// Barre segmentée des trois modes (Compétences · Sujets · Examens).
///
/// Reprise de la maquette : rail blanc arrondi, mode actif en **pilule pleine**
/// portant l'accent du module, icône à gauche du libellé. Elle **défile avec le
/// contenu** — l'ancienne barre flottante en bas d'écran est supprimée, elle
/// masquait le dernier élément de chaque liste et faisait doublon avec la
/// navigation globale.
class ProductionModeTabs extends StatelessWidget {
  const ProductionModeTabs({
    super.key,
    required this.active,
    required this.accent,
    required this.onChanged,
  });

  final ProductionModuleTab active;
  final Color accent;
  final ValueChanged<ProductionModuleTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          for (final tab in ProductionModuleTab.values)
            Expanded(
              child: _TabButton(
                tab: tab,
                on: tab == active,
                accent: accent,
                onTap: () => onChanged(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
    final foreground = on ? AppColors.white : AppColors.inkSoft;
    return Material(
      color: on ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get label => productionModeTabLabel(tab);

  IconData get _icon => switch (tab) {
        ProductionModuleTab.competences => LucideIcons.clock,
        ProductionModuleTab.sujets => LucideIcons.fileText,
        ProductionModuleTab.examens => LucideIcons.clipboardCheck,
      };
}

/// Libellé d'un mode. **Contrat gelé**, miroir mot pour mot du web
/// (`SKILL_MODE_LABELS`, `app/_components/skill-ui/SkillLayout.tsx`).
String productionModeTabLabel(ProductionModuleTab tab) => switch (tab) {
      ProductionModuleTab.competences => 'Compétences',
      ProductionModuleTab.sujets => 'Sujets',
      ProductionModuleTab.examens => 'Examens',
    };
