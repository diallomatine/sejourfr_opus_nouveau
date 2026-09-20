import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill_models.dart';
import '../../../core/router/route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../tcf_production_module.dart';
import '../widgets/task_banner.dart';
import 'competences_list_view.dart';
import 'competences_providers.dart';

/// **Les 8 compétences d'une tâche**, atteintes **depuis le Plan** et nulle part
/// ailleurs.
///
/// ⚠️ L'écran d'une tâche ([ProductionTaskScreen]) n'a plus d'onglet
/// « Compétences » depuis le 2026-09-20 : les compétences ne se travaillent que
/// via le Plan, qui route ses tâches d'expression ici puis d'ici vers la fiche
/// d'une compétence. Cette route existait déjà — elle rendait l'écran de tâche
/// ouvert sur son premier onglet ; elle a désormais son écran propre.
///
/// Miroir web : `app/_components/competences/CompetencesList.tsx`.
class CompetencesScreen extends ConsumerStatefulWidget {
  const CompetencesScreen({
    super.key,
    required this.module,
    required this.tache,
  });

  final TcfProductionModule module;
  final int tache;

  @override
  ConsumerState<CompetencesScreen> createState() => _CompetencesScreenState();
}

class _CompetencesScreenState extends ConsumerState<CompetencesScreen>
    with RouteAware {
  SkillSection get _section =>
      widget.module.isEo ? SkillSection.eo : SkillSection.ee;

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

  /// Retour d'une fiche de compétence : le candidat vient potentiellement de
  /// produire, et un cache muet afficherait un « 2/5 » périmé.
  @override
  void didPopNext() {
    invalidateSkillsSection(ref, _section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: CompetencesListView(
          module: widget.module,
          tache: widget.tache,
          top: taskBannerTop(
            context,
            module: widget.module,
            tache: widget.tache,
          ),
        ),
      ),
    );
  }
}
