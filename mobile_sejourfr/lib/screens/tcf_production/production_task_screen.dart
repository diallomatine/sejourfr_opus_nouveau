import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_tabs.dart';
import 'competences/competences_providers.dart';
import 'competences/competences_tab_view.dart';
import 'production_catalog.dart';
import 'production_subjects_tab_view.dart';
import 'tcf_production_module.dart';
import 'widgets/production_blocks.dart';
import 'widgets/production_common.dart';
import 'widgets/task_palette.dart';

/// Les deux façons de travailler **une** tâche d'expression.
///
/// ⚠️ Libellés gelés, à mirrorer sur le web dans la même passe. Le compteur
/// est collé au libellé (« Compétences · 8 ») comme dans la maquette ; il
/// **disparaît** tant que la source n'est pas chargée, plutôt que d'annoncer
/// un « · 0 » qui se lirait comme un onglet vide.
enum ProductionTaskTab { competences, sujets }

String productionTaskTabLabel(ProductionTaskTab tab, int? count) {
  final base = switch (tab) {
    ProductionTaskTab.competences => 'Compétences',
    ProductionTaskTab.sujets => "Sujets d'examen",
  };
  return count == null ? base : '$base · $count';
}

/// **Niveau 2 du parcours EE/EO** : une tâche, sa consigne, et ses deux
/// onglets (`MTask` de la maquette 2026-08-21).
///
/// Il remplace l'écran unique à trois modes : la tâche ne se choisit plus par
/// un sélecteur — on y entre depuis la liste des tâches ([ProductionTasksScreen])
/// ou depuis le Plan — et les examens blancs ne sont plus un troisième onglet,
/// ils ont leur écran ([ProductionExamsScreen]).
///
/// Les deux onglets vivent dans un [IndexedStack] : celui qu'on quitte reste
/// monté (filtres, position de défilement). La donnée est mise en cache par
/// [skillsSectionProvider] / [productionCatalogProvider], tous deux portés par
/// **l'épreuve** — passer d'un onglet à l'autre, ou d'une tâche à l'autre, ne
/// coûte aucun appel.
class ProductionTaskScreen extends ConsumerStatefulWidget {
  const ProductionTaskScreen({
    super.key,
    required this.module,
    required this.tache,
    this.tab = ProductionTaskTab.competences,
  });

  final TcfProductionModule module;
  final int tache;

  /// Onglet d'ouverture, déduit du chemin emprunté.
  final ProductionTaskTab tab;

  @override
  ConsumerState<ProductionTaskScreen> createState() =>
      _ProductionTaskScreenState();
}

class _ProductionTaskScreenState extends ConsumerState<ProductionTaskScreen>
    with RouteAware {
  late ProductionTaskTab _tab = widget.tab;

  /// Onglets déjà ouverts : celui qu'on n'a pas demandé n'est pas construit.
  late final Set<ProductionTaskTab> _mounted = {widget.tab};

  /// Voile d'attente au démarrage d'une session, remonté par l'onglet des
  /// sujets. Porté ici pour couvrir **aussi** l'en-tête et la barre d'onglets.
  bool _busy = false;

  SkillSection get _section =>
      widget.module.isEo ? SkillSection.eo : SkillSection.ee;

  @override
  void didUpdateWidget(ProductionTaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab) _selectTab(widget.tab);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour d'un flux poussé au-dessus de la tâche (production d'un sujet,
  /// petit sujet de compétence). Le candidat vient potentiellement de
  /// produire : sa progression a changé, et un cache muet afficherait un
  /// « 6/20 sujets traités » périmé.
  @override
  void didPopNext() {
    invalidateSkillsSection(ref, _section);
    invalidateProductionCatalog(ref, widget.module.epreuve);
  }

  void _selectTab(ProductionTaskTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _mounted.add(tab);
    });
  }

  void _setBusy(bool value) {
    if (value == _busy) return;
    setState(() => _busy = value);
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(userTargetLevelProvider);
    final meta = productionTaskMeta(widget.module, widget.tache);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  title: meta.title,
                  sub: '${widget.module.title} · Tâche ${widget.tache}',
                  onBack: () => Navigator.of(context).maybePop(),
                  right: level == null
                      ? null
                      : ProductionLevelBadge(level: level.wire),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab.index,
                    sizing: StackFit.expand,
                    children: [
                      for (final tab in ProductionTaskTab.values)
                        _mounted.contains(tab)
                            ? _tabView(tab)
                            : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
            if (_busy) const Positioned.fill(child: BusyOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _tabView(ProductionTaskTab tab) {
    switch (tab) {
      case ProductionTaskTab.competences:
        return CompetencesTabView(
          module: widget.module,
          tache: widget.tache,
          top: _top(),
        );
      case ProductionTaskTab.sujets:
        return ProductionSubjectsTabView(
          module: widget.module,
          tache: widget.tache,
          onBusy: _setBusy,
          top: _top(),
        );
    }
  }

  /// Tête commune aux deux onglets, rendue **en tête de leur liste** : la carte
  /// de consigne puis la barre segmentée.
  ///
  /// Elle est rendue quel que soit l'état de la liste — sans elle, une erreur
  /// de chargement enfermerait le candidat dans un onglet.
  List<Widget> _top() {
    final skills = ref.watch(skillsListProvider(
      SkillsKey(section: _section, tacheNumero: widget.tache),
    )).valueOrNull;
    final catalog =
        ref.watch(productionCatalogProvider(widget.module.epreuve)).valueOrNull;

    return [
      _ConsigneCard(
        module: widget.module,
        tache: widget.tache,
        constraint: _constraintOf(catalog),
      ),
      const SizedBox(height: 12),
      SegmentedTabs<ProductionTaskTab>(
        value: _tab,
        onChanged: _selectTab,
        tabs: [
          SegmentTab(
            value: ProductionTaskTab.competences,
            label: productionTaskTabLabel(
              ProductionTaskTab.competences,
              skills?.length,
            ),
          ),
          SegmentTab(
            value: ProductionTaskTab.sujets,
            label: productionTaskTabLabel(
              ProductionTaskTab.sujets,
              catalog?.tasksForTache(widget.tache).length,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  /// Contrainte réelle de la tâche (longueur à l'écrit, durée à l'oral), lue
  /// sur son premier sujet publié. `null` quand l'API ne la porte pas : on
  /// n'invente jamais une consigne de longueur — les bornes vivent dans
  /// `production_tasks.mots_min/mots_max` côté serveur.
  String? _constraintOf(ProductionCatalog? catalog) {
    final subjects = catalog?.tasksForTache(widget.tache) ?? const [];
    if (subjects.isEmpty) return null;
    return productionTaskConstraint(
      subjects.first,
      isOral: widget.module.isEo,
    );
  }
}

/// Carte de consigne de la tâche : filet de teinte, rond numéroté, intention
/// et contrainte. C'est la **présentation éditoriale de la tâche**, pas la
/// consigne d'un sujet — celle-ci vit sur l'écran de production.
class _ConsigneCard extends StatelessWidget {
  const _ConsigneCard({
    required this.module,
    required this.tache,
    required this.constraint,
  });

  final TcfProductionModule module;
  final int tache;

  /// « 30-60 mots », « 3 min » — servi par l'API. Absent, l'eyebrow se contente
  /// du rang de la tâche : aucune borne n'est inventée.
  final String? constraint;

  @override
  Widget build(BuildContext context) {
    final (toneBg, toneFg) = taskPalette(tache);
    final meta = productionTaskMeta(module, tache);

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
          Container(height: 3, color: toneFg),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [toneBg, AppColors.white],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    '$tache',
                    style: AppFonts.display(size: 19, color: toneFg),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        constraint == null
                            ? 'CONSIGNE · TÂCHE $tache'
                            : 'CONSIGNE · ${constraint!.toUpperCase()}',
                        style: AppFonts.ui(
                          size: 10.5,
                          weight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.inkFaint,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        meta.intro,
                        style: AppFonts.ui(
                          size: 14,
                          height: 1.5,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
