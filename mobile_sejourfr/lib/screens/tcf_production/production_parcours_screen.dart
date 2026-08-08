import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/skill_models.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import 'competences/competences_providers.dart';
import 'competences/competences_tab_view.dart';
import 'production_catalog.dart';
import 'production_exams_tab_view.dart';
import 'production_nav.dart';
import 'production_subjects_tab_view.dart';
import 'tcf_production_module.dart';
import 'widgets/flag_badge.dart';
import 'widgets/module_screen_header.dart';
import 'widgets/production_common.dart';
import 'widgets/production_module_bar.dart';

/// Écran unique du parcours TCF EE/EO : il **porte les trois modes**
/// (Compétences · Sujets · Examens) et la tâche courante (T1/T2/T3).
///
/// Avant, chaque mode était une route et chaque bascule un `pushReplacement` :
/// l'arbre entier était démonté puis reconstruit, et les providers `autoDispose`
/// de l'écran quitté jetaient leurs données — donc rechargeaient au retour.
/// Trois modes × trois tâches, c'était neuf écrans et autant d'allers-retours
/// réseau pour une navigation qui, du point de vue du candidat, ne quitte
/// jamais son épreuve.
///
/// Ici, les trois modes vivent dans un [IndexedStack] : celui qu'on quitte
/// reste monté (état local, filtres, position de défilement), celui qu'on
/// rejoint réapparaît tel qu'il était. La donnée, elle, est mise en cache dans
/// [productionCatalogProvider] / [skillsSectionProvider], tous deux portés par
/// **l'épreuve** et non par la tâche.
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
  /// paie pas les appels d'un mode que le candidat n'a pas demandé.
  late final Set<ProductionModuleTab> _mounted = {widget.tab};

  /// Voile d'attente au démarrage d'une session, remonté par les modes qui
  /// peuvent en démarrer une. Porté ici pour couvrir **aussi** la barre du
  /// module : sinon on pourrait changer de mode pendant le démarrage.
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
  /// On ne recharge que la donnée du mode d'où l'on est parti : un micro-sujet
  /// de compétence ne touche pas au catalogue des sujets TCF, et inversement.
  @override
  void didPopNext() {
    switch (_tab) {
      case ProductionModuleTab.competences:
        invalidateSkillsSection(ref, _section);
      case ProductionModuleTab.sujets:
        invalidateProductionCatalog(ref, widget.module.epreuve);
      case ProductionModuleTab.examens:
        invalidateProductionCatalog(ref, widget.module.epreuve);
        // Une évaluation a pu se terminer pendant la consultation du bilan :
        // les bilans ne se redemandent pas tout seuls tant que la liste des
        // sessions est la même.
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _header(),
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ProductionModuleBar(
                active: _tab,
                accent: widget.module.accent,
                onChanged: _selectTab,
              ),
            ),
            if (_busy) const Positioned.fill(child: BusyOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final module = widget.module;
    switch (_tab) {
      case ProductionModuleTab.competences:
        return ScreenHeader(
          title: 'Compétences',
          sub: 'Tâche $_tache · ${module.title}',
          onBack: _back,
        );
      case ProductionModuleTab.sujets:
        final meta = productionTaskMeta(module, _tache);
        return ScreenHeader(
          title: meta.title,
          sub: 'Tâche $_tache · ${meta.subtitle}',
          onBack: _back,
        );
      case ProductionModuleTab.examens:
        return ModuleScreenHeader(
          title: 'Examens blancs',
          subtitle: '${module.title} · TCF IRN',
          onBack: _back,
          trailing: const FlagBadge(),
        );
    }
  }

  Widget _tabView(ProductionModuleTab tab) {
    switch (tab) {
      case ProductionModuleTab.competences:
        return CompetencesTabView(
          module: widget.module,
          tache: _tache,
          onTacheChanged: _selectTache,
        );
      case ProductionModuleTab.sujets:
        return ProductionSubjectsTabView(
          module: widget.module,
          tache: _tache,
          onTacheChanged: _selectTache,
          onBusy: _setBusy,
        );
      case ProductionModuleTab.examens:
        return ProductionExamsTabView(
          module: widget.module,
          onBusy: _setBusy,
        );
    }
  }

  void _back() => leaveProductionParcours(context);
}
