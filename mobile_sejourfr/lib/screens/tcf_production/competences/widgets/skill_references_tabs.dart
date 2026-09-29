import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Teinte d'un niveau de référence (`.ref-tab.active[data-ref=…]` du
/// prototype) : **Insuffisant rouge, Attendu vert, Très réussi bleu**.
///
/// Ce n'est pas un niveau CECRL — la règle « jamais de rouge sur un niveau »
/// ne s'applique donc pas : ici le rouge dit « contre-exemple ».
Color skillReferenceColor(SkillReferenceLevel level) => switch (level) {
      SkillReferenceLevel.insufficient => AppColors.red,
      SkillReferenceLevel.expected => AppColors.green,
      SkillReferenceLevel.excellent => AppColors.blue,
    };

Color _softColor(SkillReferenceLevel level) => switch (level) {
      SkillReferenceLevel.insufficient => AppColors.redLight,
      SkillReferenceLevel.expected => AppColors.greenLight,
      SkillReferenceLevel.excellent => AppColors.blueLight,
    };

/// Les trois références comparatives, en onglets `Insuffisant | Attendu |
/// Très réussi` — grille `repeat(3,1fr)`, `radius 13`, onglet actif teinté de
/// la couleur de son niveau.
///
/// Écrites en base, indépendantes de l'IA : elles s'affichent même quand
/// aucune analyse n'a été demandée, et **jamais avant** que le candidat ait
/// produit (§13.2 de la spec).
class SkillReferencesTabs extends StatefulWidget {
  const SkillReferencesTabs({super.key, required this.references});

  final List<SkillReferenceDto> references;

  @override
  State<SkillReferencesTabs> createState() => _SkillReferencesTabsState();
}

class _SkillReferencesTabsState extends State<SkillReferencesTabs> {
  late SkillReferenceLevel _level;

  @override
  void initState() {
    super.initState();
    // On ouvre sur « Attendu » : c'est la cible, pas le contre-exemple.
    // Liste vide = le widget ne rend rien (l'appelant retire déjà la section
    // avec son titre) : pas de `.first` sur du vide.
    _level = widget.references.isEmpty ||
            widget.references.any((r) => r.level == SkillReferenceLevel.expected)
        ? SkillReferenceLevel.expected
        : widget.references.first.level;
  }

  @override
  Widget build(BuildContext context) {
    final ordered = [
      for (final level in SkillReferenceLevel.values)
        ...widget.references.where((r) => r.level == level),
    ];
    if (ordered.isEmpty) return const SizedBox.shrink();

    final current = ordered.firstWhere(
      (r) => r.level == _level,
      orElse: () => ordered.first,
    );
    final accent = skillReferenceColor(current.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < ordered.length; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(
                child: _RefTab(
                  level: ordered[i].level,
                  active: ordered[i].level == current.level,
                  onTap: () => setState(() => _level = ordered[i].level),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current.level.label.toUpperCase(),
                style: AppFonts.label(size: 10, color: accent),
              ),
              const SizedBox(height: 7),
              Text(
                current.text,
                style: AppFonts.ui(size: 13.5, height: 1.48),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 14, color: accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      current.pedagogicalNote,
                      style: AppFonts.ui(
                        size: 11,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RefTab extends StatelessWidget {
  const _RefTab({
    required this.level,
    required this.active,
    required this.onTap,
  });

  final SkillReferenceLevel level;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = skillReferenceColor(level);
    return Material(
      color: active ? _softColor(level) : AppColors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? accent.withValues(alpha: 0.45) : AppColors.line,
            ),
          ),
          child: Text(
            level.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w900,
              color: active ? accent : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
