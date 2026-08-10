import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/widgets/premium_lock.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import 'widgets/competence_card.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';

/// Mode « Compétences » du parcours : les 8 compétences d'une tâche EE/EO.
///
/// Reprend la structure de l'accueil du prototype : hero en dégradé portant la
/// progression globale, pastilles de tâche T1/T2/T3, intertitres, liste des
/// compétences, puis l'encart « Principe pédagogique ».
///
/// Espace **distinct** des sujets TCF complets (§13.9 de la spec) : on
/// travaille ici un critère à la fois sur de petits sujets, pas une production
/// d'examen entière.
///
/// Corps seul — l'en-tête et la tête commune du parcours (héros, prochain
/// entraînement, barre des modes, sélecteur de tâche) sont portés par
/// [ProductionParcoursScreen] et rendus par [top]. Le sélecteur de tâche n'est
/// plus une navigation : les 24 compétences de l'épreuve arrivent en un appel,
/// le changement de tâche est un tri local.
class CompetencesTabView extends ConsumerStatefulWidget {
  const CompetencesTabView({
    super.key,
    required this.module,
    required this.tache,
    required this.top,
  });

  final TcfProductionModule module;
  final int tache;

  /// Tête commune du parcours, rendue en tête de cette liste.
  final List<Widget> Function({required bool withTaskPicker}) top;

  @override
  ConsumerState<CompetencesTabView> createState() => _CompetencesTabViewState();
}

class _CompetencesTabViewState extends ConsumerState<CompetencesTabView> {
  SkillsKey get _key => SkillsKey(
        section: widget.module.isEo ? SkillSection.eo : SkillSection.ee,
        tacheNumero: widget.tache,
      );

  Color get _accent => widget.module.accent;

  /// Le verrou freemium vient du serveur (`skill.locked`) : verrouillée, la
  /// compétence reste dans la liste et lisible, mais son tap ouvre l'offre au
  /// lieu de sujets sur lesquels rien ne pourrait être produit.
  void _open(SkillDto skill) {
    if (skill.locked) {
      unawaited(showTcfLockPaywall(context));
      return;
    }
    context.push(competenceDetailPath(widget.module, skill.id));
  }

  @override
  Widget build(BuildContext context) {
    // La tête du parcours porte la barre des trois modes : elle est rendue
    // **quel que soit l'état** de la liste. Sans elle, une erreur de chargement
    // enfermait le candidat dans un mode, sans autre issue que « retour ».
    final async = ref.watch(skillsListProvider(_key));
    return _body(
      async.when(
        skipLoadingOnReload: true,
        loading: () => [
          Center(child: CircularProgressIndicator(color: _accent)),
        ],
        error: (e, _) => [
          ProductionErrorView(
            message: ApiClient.toApiException(e).message,
            onRetry: () => invalidateSkillsSection(ref, _key.section),
          ),
        ],
        data: _skills,
      ),
    );
  }

  List<Widget> _skills(List<SkillDto> skills) {
    if (skills.isEmpty) {
      return const [
        ProductionEmptyView(
          description:
              'Les compétences de cette tâche ne sont pas encore prêtes.',
        ),
      ];
    }
    return [
      ProductionSectionHead(
        title: 'Compétences de la tâche ${widget.tache}',
        description:
            'Chaque compétence contient plusieurs petits sujets de production.',
        accent: _accent,
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
        body: 'Le candidat produit directement. Chaque petit sujet travaille '
            'un seul critère attendu au TCF.',
      ),
    ];
  }

  Widget _body(List<Widget> content) {
    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        invalidateSkillsSection(ref, _key.section);
        await ref.read(skillsSectionProvider(_key.section).future);
      },
      child: ListView(
        // Une clé par tâche : changer de tâche repart en haut de liste au lieu
        // de garder le défilement d'une autre tâche.
        key: PageStorageKey<int>(widget.tache),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          ...widget.top(withTaskPicker: true),
          ...content,
        ],
      ),
    );
  }
}
