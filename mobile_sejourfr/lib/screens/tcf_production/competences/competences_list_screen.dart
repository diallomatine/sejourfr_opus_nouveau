import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/screen_header.dart';
import '../production_nav.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import 'widgets/competence_card.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_hero.dart';
import '../widgets/production_module_bar.dart';
import '../widgets/production_state_views.dart';
import '../widgets/production_task_pills.dart';

/// Niveau 4 du parcours : les 8 compétences d'une tâche EE/EO.
///
/// Reprend la structure de l'accueil du prototype : hero en dégradé portant la
/// progression globale, pastilles de tâche T1/T2/T3, intertitres, liste des
/// compétences, puis l'encart « Principe pédagogique ».
///
/// Espace **distinct** des sujets TCF complets (§13.9 de la spec) : on
/// travaille ici un critère à la fois sur de petits sujets, pas une production
/// d'examen entière.
class CompetencesListScreen extends ConsumerStatefulWidget {
  const CompetencesListScreen({
    super.key,
    required this.module,
    required this.tache,
  });

  final TcfProductionModule module;
  final int tache;

  @override
  ConsumerState<CompetencesListScreen> createState() =>
      _CompetencesListScreenState();
}

class _CompetencesListScreenState extends ConsumerState<CompetencesListScreen>
    with RouteAware {
  SkillsKey get _key => SkillsKey(
        section: widget.module.isEo ? SkillSection.eo : SkillSection.ee,
        tacheNumero: widget.tache,
      );

  Color get _accent => widget.module.accent;

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

  /// Retour depuis une compétence : la progression a pu bouger, on refetch
  /// sans démonter la liste (`skipLoadingOnReload` côté build).
  @override
  void didPopNext() {
    ref.invalidate(skillsListProvider(_key));
  }

  void _back() => leaveProductionParcours(context);

  void _open(SkillDto skill) =>
      context.push(competenceDetailPath(widget.module, skill.id));

  /// Change de tâche sans repasser par l'écran précédent (la navigation du
  /// prototype). `pushReplacement` : on remplace l'écran courant au lieu
  /// d'empiler une tâche par tap.
  void _openTask(int tache) {
    if (tache == widget.tache) return;
    context.pushReplacement(competencesListPath(widget.module, tache));
  }

  /// « Continuer » ouvre la première compétence dont tous les sujets n'ont pas
  /// encore été traités ; si tout a été vu, on rouvre la première.
  SkillDto? _resumeTarget(List<SkillDto> skills) {
    if (skills.isEmpty) return null;
    for (final skill in skills) {
      if (!skill.isComplete) return skill;
    }
    return skills.first;
  }

  /// Palier de la tâche : celui de ses compétences quand elles s'accordent,
  /// sinon `null` — on n'affiche pas un niveau qui ne vaudrait que pour une
  /// partie de la liste.
  String? _taskLevel(List<SkillDto> skills) {
    if (skills.isEmpty) return null;
    final first = skills.first.targetLevel.trim();
    if (first.isEmpty) return null;
    return skills.every((s) => s.targetLevel.trim() == first) ? first : null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(skillsListProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Compétences',
              sub: 'Tâche ${widget.tache} · ${widget.module.title}',
              onBack: _back,
            ),
            Expanded(
              child: Stack(
                children: [
                  async.when(
                    skipLoadingOnReload: true,
                    loading: () => Center(
                        child: CircularProgressIndicator(color: _accent)),
                    error: (e, _) => ProductionErrorView(
                      message: ApiClient.toApiException(e).message,
                      onRetry: () => ref.invalidate(skillsListProvider(_key)),
                    ),
                    data: _body,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ProductionModuleBar(
                      active: ProductionModuleTab.competences,
                      accent: _accent,
                      onChanged: (tab) => goProductionTab(
                        context,
                        widget.module,
                        widget.tache,
                        tab,
                        current: ProductionModuleTab.competences,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<SkillDto> skills) {
    if (skills.isEmpty) {
      return const ProductionEmptyView(
        description:
            'Les compétences de cette tâche ne sont pas encore prêtes.',
      );
    }
    final resume = _resumeTarget(skills);
    // Agrégat calculé côté client : `GET /api/skills?taskCode=` sert déjà les
    // compteurs par compétence, aucun endpoint à inventer pour la barre.
    final treated = skills.fold<int>(0, (sum, s) => sum + s.attemptedCount);
    final total = skills.fold<int>(0, (sum, s) => sum + s.promptCount);
    final percent = total == 0 ? 0.0 : treated / total * 100;

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        ref.invalidate(skillsListProvider(_key));
        await ref.read(skillsListProvider(_key).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            16, 12, 16, ProductionModuleBar.reservedHeight),
        children: [
          ProductionHero(
            accent: _accent,
            accentDark: widget.module.accentDark,
            eyebrow: 'Parcours TCF',
            title: 'Tâche ${widget.tache} · ${widget.module.title}',
            description: 'Travaille une compétence à la fois, puis '
                'utilise-la dans un sujet complet.',
            percent: percent,
            progressLabel: '$treated/$total sujets traités',
            level: _taskLevel(skills),
          ),
          const SizedBox(height: 21),
          const ProductionSectionHead(
            title: 'Choisis une tâche',
            description: 'Chaque tâche développe des compétences différentes.',
          ),
          const SizedBox(height: 11),
          ProductionTaskPills(
            active: widget.tache,
            accent: _accent,
            onChanged: _openTask,
          ),
          const SizedBox(height: 21),
          ProductionSectionHead(
            title: 'Compétences de la tâche ${widget.tache}',
            description: 'Chaque compétence contient plusieurs petits sujets '
                'de production.',
            accent: _accent,
            linkLabel: resume == null
                ? null
                : (resume.attemptedCount == 0 ? 'Commencer' : 'Continuer'),
            onLinkTap: resume == null ? null : () => _open(resume),
          ),
          const SizedBox(height: 11),
          for (final skill in skills) ...[
            CompetenceCard(
              skill: skill,
              accent: _accent,
              onTap: () => _open(skill),
            ),
            const SizedBox(height: 11),
          ],
          const SizedBox(height: 4),
          const ProductionNotice(
            title: 'Principe pédagogique',
            body: 'Le candidat produit directement. Chaque petit sujet '
                'travaille un seul critère attendu au TCF.',
          ),
        ],
      ),
    );
  }
}
