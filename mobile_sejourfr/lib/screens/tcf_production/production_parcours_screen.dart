import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import 'competences/competences_nav.dart';
import 'competences/competences_providers.dart';
import 'competences/competences_tab_view.dart';
import 'expression_hub_data.dart';
import 'production_catalog.dart';
import 'production_exams_tab_view.dart';
import 'production_nav.dart';
import 'production_subjects_tab_view.dart';
import 'tcf_production_module.dart';
import 'widgets/production_common.dart';
import 'widgets/production_mode_tabs.dart';
import 'widgets/production_parcours_top.dart';

/// Écran unique du parcours TCF EE/EO : il **porte les trois modes**
/// (Compétences · Sujets · Examens) et la tâche courante (T1/T2/T3).
///
/// Structure reprise de la maquette client (2026-08-09) : un en-tête constant
/// (retour, épreuve, palier visé), puis une **tête commune aux trois modes** —
/// carte héros chiffrée, « Prochain entraînement », barre segmentée des modes,
/// sélecteur de tâche — et enfin le corps du mode actif.
///
/// Les trois modes vivent dans un [IndexedStack] : celui qu'on quitte reste
/// monté (état local, filtres, position de défilement), celui qu'on rejoint
/// réapparaît tel qu'il était. La donnée, elle, est mise en cache dans
/// [productionCatalogProvider] / [skillsSectionProvider], tous deux portés par
/// **l'épreuve** et non par la tâche.
///
/// ⚠️ Depuis que la tête est commune, ces deux sources d'épreuve sont chargées
/// **dès l'entrée** (le héros compte les sujets et les examens, la carte
/// « Prochain entraînement » lit les compétences) : c'est le prix assumé d'une
/// vue d'ensemble présente sur les trois modes. Ce qui est préservé, et
/// verrouillé par `test/production_parcours_caching_test.dart`, c'est
/// qu'**aucune bascule de mode ou de tâche ne coûte un appel de plus**.
///
/// Les chemins des trois modes restent servis à l'identique (lien profond,
/// retour arrière) : ils construisent simplement cet écran avec le bon mode de
/// départ. En revanche, une bascule **ne change plus l'URL** — ce qui rend le
/// retour arrière exact : quitter un mode, c'est quitter le parcours
/// ([leaveProductionParcours]), jamais un déplacement latéral.
class ProductionParcoursScreen extends ConsumerStatefulWidget {
  const ProductionParcoursScreen({
    super.key,
    required this.module,
    required this.tab,
    this.tache = 1,
  });

  final TcfProductionModule module;

  /// Mode d'ouverture, déduit du chemin emprunté.
  final ProductionModuleTab tab;

  /// Tâche d'ouverture. La page des examens est portée par l'épreuve : elle la
  /// reçoit uniquement pour savoir sur quelle tâche revenir.
  final int tache;

  @override
  ConsumerState<ProductionParcoursScreen> createState() =>
      _ProductionParcoursScreenState();
}

class _ProductionParcoursScreenState
    extends ConsumerState<ProductionParcoursScreen> with RouteAware {
  late ProductionModuleTab _tab = widget.tab;
  late int _tache = widget.tache;

  /// Modes déjà ouverts. Un mode jamais visité n'est pas construit : on ne
  /// paie pas le rendu d'un mode que le candidat n'a pas demandé.
  late final Set<ProductionModuleTab> _mounted = {widget.tab};

  /// Voile d'attente au démarrage d'une session, remonté par les modes qui
  /// peuvent en démarrer une. Porté ici pour couvrir **aussi** la tête du
  /// parcours : sinon on pourrait changer de mode pendant le démarrage.
  bool _busy = false;

  SkillSection get _section =>
      widget.module.isEo ? SkillSection.eo : SkillSection.ee;

  @override
  void didUpdateWidget(ProductionParcoursScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le routeur peut reconstruire la même route avec d'autres paramètres
    // (lien profond entrant sur un parcours déjà ouvert).
    if (widget.tab != oldWidget.tab) _selectTab(widget.tab);
    if (widget.tache != oldWidget.tache) _selectTache(widget.tache);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour d'un flux poussé au-dessus du parcours (production d'un sujet,
  /// petit sujet de compétence, session d'examen). Le candidat vient
  /// potentiellement de produire : sa progression a changé, et un cache muet
  /// afficherait un « 6/20 sujets traités » périmé.
  ///
  /// La tête commune lit les deux sources : on recharge donc **les deux**,
  /// quel que soit le mode d'où l'on revient. Les bilans d'examen, eux, ne se
  /// redemandent que depuis le mode qui les affiche.
  @override
  void didPopNext() {
    invalidateSkillsSection(ref, _section);
    invalidateProductionCatalog(ref, widget.module.epreuve);
    if (_tab == ProductionModuleTab.examens) {
      // Une évaluation a pu se terminer pendant la consultation du bilan : les
      // bilans ne se redemandent pas tout seuls tant que la liste des sessions
      // est la même.
      ref.invalidate(examBilansProvider(widget.module.epreuve));
    }
  }

  void _selectTab(ProductionModuleTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _mounted.add(tab);
    });
  }

  void _selectTache(int tache) {
    if (tache == _tache) return;
    setState(() => _tache = tache);
  }

  void _setBusy(bool value) {
    if (value == _busy) return;
    setState(() => _busy = value);
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(userTargetLevelProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  title: widget.module.title,
                  sub: widget.module.epreuveMeta,
                  onBack: _back,
                  right: level == null
                      ? null
                      : ProductionLevelBadge(level: level.wire),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab.index,
                    // `sizing: expand` : un mode caché garde la taille du
                    // conteneur, donc sa position de défilement reste valable.
                    sizing: StackFit.expand,
                    children: [
                      for (final tab in ProductionModuleTab.values)
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

  Widget _tabView(ProductionModuleTab tab) {
    switch (tab) {
      case ProductionModuleTab.competences:
        return CompetencesTabView(
          module: widget.module,
          tache: _tache,
          top: _top,
        );
      case ProductionModuleTab.sujets:
        return ProductionSubjectsTabView(
          module: widget.module,
          tache: _tache,
          onBusy: _setBusy,
          top: _top,
        );
      case ProductionModuleTab.examens:
        return ProductionExamsTabView(
          module: widget.module,
          onBusy: _setBusy,
          top: _top,
        );
    }
  }

  /// Tête commune, rendue **en tête de la liste de chaque mode**.
  ///
  /// [withTaskPicker] : le sélecteur de tâche n'a de sens que là où la tâche
  /// pilote le contenu (Compétences, Sujets). La grille des examens blancs est
  /// portée par l'épreuve entière.
  List<Widget> _top({required bool withTaskPicker}) {
    final catalog =
        ref.watch(productionCatalogProvider(widget.module.epreuve)).valueOrNull;
    final hub = catalog == null ? null : buildHubData(catalog);
    final skills =
        ref.watch(skillsSectionProvider(_section)).valueOrNull ?? const [];
    final next = _nextSkill(skills);

    return [
      ProductionParcoursHero(
        module: widget.module,
        stats: ProductionParcoursStats(
          avgScore: _avgExamScore(hub),
          examsDone: hub?.exams.length ?? 0,
          examsTotal: kProductionExamSlots,
          subjectsDone: hub?.doneSubjects ?? 0,
          subjectsTotal: hub?.totalSubjects ?? 0,
        ),
      ),
      const SizedBox(height: 12),
      if (next != null) ...[
        ProductionNextCard(
          module: widget.module,
          title: 'Prochain entraînement',
          subtitle: '${_tacheLabel(next.taskCode)} · ${next.title}',
          actionLabel: 'Continuer',
          onTap: () =>
              context.push(competenceDetailPath(widget.module, next.id)),
        ),
        const SizedBox(height: 12),
      ],
      ProductionModeTabs(
        active: _tab,
        accent: widget.module.accent,
        onChanged: _selectTab,
      ),
      const SizedBox(height: 12),
      if (withTaskPicker) ...[
        ProductionTaskCards(
          module: widget.module,
          active: _tache,
          accent: widget.module.accent,
          onChanged: _selectTache,
          constraintOf: (tache) => _constraintOf(catalog, tache),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  /// La prochaine compétence à travailler : la première dont tous les petits
  /// sujets n'ont pas été traités, dans l'ordre du référentiel. Tout terminé
  /// (ou rien de chargé) ⇒ **aucune carte**, jamais une invitation vide.
  SkillDto? _nextSkill(List<SkillDto> skills) {
    if (skills.isEmpty) return null;
    final sorted = [...skills]..sort((a, b) {
        final byTask = (a.taskCode ?? '').compareTo(b.taskCode ?? '');
        return byTask != 0 ? byTask : a.displayOrder.compareTo(b.displayOrder);
      });
    for (final skill in sorted) {
      if (!skill.isComplete) return skill;
    }
    return null;
  }

  /// « Tâche 2 » depuis un `taskCode` (`EE2` / `EO2`). Le référentiel garantit
  /// le format ; un code inattendu retombe sur le code brut plutôt que sur un
  /// numéro inventé.
  String _tacheLabel(String? taskCode) {
    if (taskCode == null || taskCode.isEmpty) return 'Tâche';
    final numero = int.tryParse(taskCode.substring(taskCode.length - 1));
    return numero == null ? taskCode : 'Tâche $numero';
  }

  /// Moyenne des examens blancs **entièrement évalués** de l'épreuve. On
  /// n'agrège que des sessions complètes : une session dont l'IA n'a rendu
  /// qu'une note sur trois tirerait la moyenne vers le bas sans raison.
  double? _avgExamScore(HubData? hub) {
    final done = (hub?.exams ?? const <ExamSession>[])
        .where((e) => e.isFullyEvaluated)
        .map((e) => e.avgScore)
        .whereType<double>()
        .toList();
    if (done.isEmpty) return null;
    return done.reduce((a, b) => a + b) / done.length;
  }

  /// Contrainte réelle d'une tâche (longueur à l'écrit, durée à l'oral), lue
  /// sur son premier sujet publié. `null` quand l'API ne la porte pas : on
  /// n'invente jamais une consigne de longueur.
  String? _constraintOf(ProductionCatalog? catalog, int tache) {
    final subjects = catalog?.tasksForTache(tache) ?? const [];
    if (subjects.isEmpty) return null;
    return productionTaskConstraint(subjects.first, isOral: widget.module.isEo);
  }

  void _back() => leaveProductionParcours(context);
}
