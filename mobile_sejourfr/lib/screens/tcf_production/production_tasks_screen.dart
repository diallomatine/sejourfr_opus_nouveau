import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fixed_action_bar.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_header.dart';
import 'competences/competences_providers.dart';
import 'production_catalog.dart';
import 'production_nav.dart';
import 'tcf_production_module.dart';
import 'widgets/production_blocks.dart';
import 'widgets/production_common.dart';
import 'widgets/task_palette.dart';

/// **Niveau 1 du parcours EE/EO** : l'épreuve et ses trois tâches.
///
/// Reprise de `MTasks` (maquette 2026-08-21) : un en-tête chiffré, une carte de
/// synthèse de l'épreuve, **une carte par tâche** avec ses trois compteurs, une
/// note, et une barre fixe qui mène aux examens blancs.
///
/// Ce qu'il remplace : l'écran unique à trois modes (Compétences · Sujets ·
/// Examens) dans lequel la tâche se choisissait par un sélecteur, et où les
/// examens blancs étaient un troisième onglet. Les examens n'ont pas disparu —
/// ils **quittent l'écran** par le bouton du bas ([ProductionExamsScreen]), la
/// grille et le démarrage d'une session étant inchangés.
///
/// Aucun agrégat n'est inventé : les trois compteurs de chaque tâche se lisent
/// sur les deux sources déjà en cache — les 24 compétences de l'épreuve
/// ([skillsSectionProvider], `promptCount` compris) et son catalogue de sujets
/// ([productionCatalogProvider]). Une carte de tâche ne porte donc **pas** de
/// pastille d'état : le serveur n'expose pas d'état « de tâche », et le déduire
/// des 8 compétences serait une invention.
class ProductionTasksScreen extends ConsumerWidget {
  const ProductionTasksScreen({super.key, required this.module});

  final TcfProductionModule module;

  static const int _taches = 3;

  SkillSection get _section =>
      module.isEo ? SkillSection.eo : SkillSection.ee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(userTargetLevelProvider);
    final skills = ref.watch(skillsSectionProvider(_section)).valueOrNull;
    final catalog =
        ref.watch(productionCatalogProvider(module.epreuve)).valueOrNull;

    final counts = [
      for (var n = 1; n <= _taches; n++) _countsOf(n, skills, catalog),
    ];
    final totalSkills = skills?.length;
    final totalPrompts =
        skills?.fold<int>(0, (a, s) => a + s.promptCount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: module.title,
              // Tant que le référentiel n'est pas là, on annonce l'épreuve
              // plutôt que des compteurs à zéro.
              sub: totalSkills == null || totalPrompts == null
                  ? module.epreuveMeta
                  : '$_taches tâches · $totalSkills compétences · '
                      '$totalPrompts petits sujets',
              onBack: () => leaveProductionEpreuve(context),
              right: level == null
                  ? null
                  : ProductionLevelBadge(level: level.wire),
            ),
            Expanded(
              child: RefreshIndicator(
                color: module.accent,
                onRefresh: () async {
                  invalidateSkillsSection(ref, _section);
                  invalidateProductionCatalog(ref, module.epreuve);
                  await ref.read(skillsSectionProvider(_section).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    _EpreuveSummaryCard(
                      module: module,
                      taches: _taches,
                      skills: totalSkills,
                      prompts: totalPrompts,
                    ),
                    const SizedBox(height: 12),
                    for (var n = 1; n <= _taches; n++) ...[
                      _TaskCard(
                        module: module,
                        numero: n,
                        counts: counts[n - 1],
                        onTap: () =>
                            context.push(productionTaskPath(module, n)),
                      ),
                      const SizedBox(height: 11),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      'Chaque tâche se travaille de deux façons : compétence '
                      'par compétence avec des petits sujets, ou en production '
                      "complète comme à l'examen.",
                      style: AppFonts.ui(
                        size: 12,
                        height: 1.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FixedActionBar(
              child: AppButton(
                label: 'Examens blancs',
                icon: LucideIcons.target,
                height: 52,
                onPressed: () => context.push(productionExamsPath(module)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TaskCounts _countsOf(
    int tache,
    List<SkillDto>? skills,
    ProductionCatalog? catalog,
  ) {
    final code = _section.taskCode(tache);
    final ofTask = skills?.where((s) => s.taskCode == code);
    return _TaskCounts(
      skills: ofTask?.length,
      prompts: ofTask?.fold<int>(0, (a, s) => a + s.promptCount),
      subjects: catalog?.tasksForTache(tache).length,
    );
  }
}

/// Les trois nombres du pied d'une carte de tâche. Tous **lus**, jamais
/// dérivés : compétences et petits sujets viennent du référentiel, les sujets
/// d'examen du catalogue de l'épreuve. `null` = source pas encore chargée.
class _TaskCounts {
  const _TaskCounts({
    required this.skills,
    required this.prompts,
    required this.subjects,
  });

  final int? skills;
  final int? prompts;
  final int? subjects;
}

/// Carte de synthèse de l'épreuve : bandeau d'accent, pictogramme, puis les
/// trois compteurs de l'épreuve entière.
class _EpreuveSummaryCard extends StatelessWidget {
  const _EpreuveSummaryCard({
    required this.module,
    required this.taches,
    required this.skills,
    required this.prompts,
  });

  final TcfProductionModule module;
  final int taches;
  final int? skills;
  final int? prompts;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 17, 15),
            decoration: BoxDecoration(
              gradient: AppGradients.hero(module.accentDark, module.accent),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(module.icon, size: 22, color: module.accent),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppFonts.display(size: 19, color: AppColors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        module.isEo
                            ? 'Trois tâches orales, analysées par l’IA'
                            : 'Trois tâches écrites, analysées par l’IA',
                        maxLines: 2,
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ProductionCountersRow(
            counters: [
              (value: taches, label: 'tâches', singular: 'tâche'),
              (
                value: skills,
                label: 'compétences',
                singular: 'compétence',
              ),
              (
                value: prompts,
                label: 'petits sujets',
                singular: 'petit sujet',
              ),
            ],
            valueSize: 18,
          ),
        ],
      ),
    );
  }
}

/// Carte d'une tâche : filet de teinte, rond numéroté, intitulé, intention,
/// puis les trois compteurs.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.module,
    required this.numero,
    required this.counts,
    required this.onTap,
  });

  final TcfProductionModule module;
  final int numero;
  final _TaskCounts counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (toneBg, toneFg) = taskPalette(numero);
    final meta = productionTaskMeta(module, numero);

    return PressableCard(
      onTap: onTap,
      radius: AppRadii.xl,
      child: Column(
        children: [
          Container(height: 3, color: toneFg),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: toneBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    '$numero',
                    style: AppFonts.display(size: 21, color: toneFg),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productionTaskLabeledTitle(module, numero),
                        style: AppFonts.ui(size: 15.5, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta.intro,
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
          ProductionCountersRow(
            background: AppColors.surface2,
            counters: [
              (
                value: counts.skills,
                label: 'compétences',
                singular: 'compétence',
              ),
              (
                value: counts.prompts,
                label: 'petits sujets',
                singular: 'petit sujet',
              ),
              (
                value: counts.subjects,
                label: "sujets d'examen",
                singular: "sujet d'examen",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
