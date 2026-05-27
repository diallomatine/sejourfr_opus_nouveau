import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'tcf_production_module.dart';

/// Écran consolidé d'entraînement à l'Expression (EO ou EE), routé sur
/// `/tcf/eo` et `/tcf/ee`. Trois onglets globaux — **Entraînement / Examens /
/// Corrections** — et, dans Entraînement, trois sous-onglets **Tâche 1/2/3**.
///
/// Remplace l'ancien couple `TcfProductionDetailScreen` +
/// `TcfProductionTaskSubjectsScreen` : la sélection d'un sujet se fait
/// désormais via le carrousel de **situations** chargé depuis
/// `/api/production-tasks/{id}/situations`. Les flux production (briefing →
/// enregistrement/écriture → résultats), examen 3-tâches et historique sont
/// réutilisés tels quels.
class TcfExpressionScreen extends ConsumerStatefulWidget {
  const TcfExpressionScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<TcfExpressionScreen> createState() => _TcfExpressionScreenState();
}

enum _GlobalTab { entrainement, examens, corrections }

class _TcfExpressionScreenState extends ConsumerState<TcfExpressionScreen> {
  _GlobalTab _tab = _GlobalTab.entrainement;
  int _tache = 1;

  String _niveau() {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return 'B1';
    return auth.user.targetProcedure?.tcfLevel ?? 'B1';
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ExpressionHeader(module: mod, onBack: () => _back(context)),
            _GlobalTabsBar(
              active: _tab,
              historyLabel: mod.historyTabLabel,
              onChanged: (t) => setState(() => _tab = t),
            ),
            if (_tab == _GlobalTab.entrainement)
              _StepTabsBar(
                active: _tache,
                onChanged: (n) => setState(() => _tache = n),
              ),
            const SizedBox(height: 4),
            Expanded(child: _body(mod)),
          ],
        ),
      ),
    );
  }

  Widget _body(TcfProductionModule mod) {
    switch (_tab) {
      case _GlobalTab.entrainement:
        return _EntrainementTab(
          key: ValueKey('entrainement-${mod.routeKey}-$_tache'),
          module: mod,
          tache: _tache,
          niveau: _niveau(),
        );
      case _GlobalTab.examens:
        return _ExamensTab(module: mod);
      case _GlobalTab.corrections:
        return _CorrectionsTab(module: mod);
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

// ============================================================================
// Header + barres d'onglets
// ============================================================================

class _ExpressionHeader extends StatelessWidget {
  const _ExpressionHeader({required this.module, required this.onBack});

  final TcfProductionModule module;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Row(
        children: [
          _SquareIconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
          Expanded(
            child: Column(
              children: [
                Text(
                  'TCF IRN',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.muted,
                    letterSpacing: 1.8,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.title,
                  style: AppFonts.jakarta(
                    size: 17,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'IA',
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w900,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.ink, size: 24),
        ),
      ),
    );
  }
}

class _GlobalTabsBar extends StatelessWidget {
  const _GlobalTabsBar({
    required this.active,
    required this.historyLabel,
    required this.onChanged,
  });

  final _GlobalTab active;
  final String historyLabel;
  final ValueChanged<_GlobalTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      _GlobalTab.entrainement: 'Entraînement',
      _GlobalTab.examens: 'Examens',
      _GlobalTab.corrections: historyLabel,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          for (final t in _GlobalTab.values)
            Expanded(
              child: _SegButton(
                label: labels[t]!,
                active: active == t,
                activeColor: AppColors.blue,
                activeText: AppColors.white,
                onTap: () => onChanged(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepTabsBar extends StatelessWidget {
  const _StepTabsBar({required this.active, required this.onChanged});

  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int n = 1; n <= 3; n++)
            Expanded(
              child: _SegButton(
                label: 'Tâche $n',
                active: active == n,
                activeColor: AppColors.ink,
                activeText: AppColors.white,
                onTap: () => onChanged(n),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeText,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color activeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.jakarta(
            size: 13,
            weight: FontWeight.w800,
            color: active ? activeText : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Onglet ENTRAÎNEMENT — situations + exemples + zone de production
// ============================================================================

class _EntrainementKey {
  const _EntrainementKey({
    required this.epreuve,
    required this.tacheNumero,
    required this.niveau,
  });

  final EpreuveType epreuve;
  final int tacheNumero;
  final String niveau;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EntrainementKey &&
          other.epreuve == epreuve &&
          other.tacheNumero == tacheNumero &&
          other.niveau == niveau;

  @override
  int get hashCode => Object.hash(epreuve, tacheNumero, niveau);
}

class _EntrainementData {
  const _EntrainementData({
    required this.displayTask,
    required this.tasksById,
    required this.situations,
    required this.examples,
  });

  /// Tâche servant à afficher la durée / les bornes de mots (cohérentes entre
  /// niveaux pour une même tâche). Null = catalogue vide.
  final ProductionTaskDto? displayTask;

  /// Toutes les tâches (A2/B1/B2) de ce (épreuve, tâche), indexées par id —
  /// pour retrouver la tâche propre à la situation jouée au moment du submit.
  final Map<String, ProductionTaskDto> tasksById;

  /// Les SUJETS proposés au candidat (carrousel).
  final List<ProductionSituationDto> situations;

  /// Les MODÈLES de la tâche (carte Exemples), indépendants du sujet choisi.
  final List<ProductionExampleDto> examples;
}

/// Agrège les situations de **toutes** les tâches (A2/B1/B2) d'un (épreuve,
/// tâche). Le niveau n'est PAS un filtre bloquant côté apprenant (l'examen TCF
/// réel n'étiquette pas les sujets par niveau) : on montre tous les sujets et
/// on garde le niveau du user uniquement pour choisir la tâche d'affichage.
final _entrainementProvider =
    FutureProvider.autoDispose.family<_EntrainementData, _EntrainementKey>((ref, key) async {
  final repo = ref.watch(productionRepositoryProvider);
  // Pas de filtre niveau : le backend ignore `tacheNumero` sans niveau, donc on
  // récupère tout le catalogue de l'épreuve et on filtre la tâche côté client.
  final all = await repo.listTasks(epreuve: key.epreuve);
  final tasks = all.where((t) => t.tacheNumero == key.tacheNumero).toList();
  if (tasks.isEmpty) {
    return const _EntrainementData(displayTask: null, tasksById: {}, situations: [], examples: []);
  }
  final displayTask = tasks.firstWhere(
    (t) => t.niveauCible == key.niveau,
    orElse: () => tasks.first,
  );
  // Sujets + modèles agrégés sur toutes les tâches (niveaux) du couple.
  final sitLists = await Future.wait(tasks.map((t) => repo.listSituations(t.id)));
  final exLists = await Future.wait(tasks.map((t) => repo.listExamples(t.id)));
  return _EntrainementData(
    displayTask: displayTask,
    tasksById: {for (final t in tasks) t.id: t},
    situations: [for (final l in sitLists) ...l],
    examples: [for (final l in exLists) ...l],
  );
});

class _EntrainementTab extends ConsumerStatefulWidget {
  const _EntrainementTab({
    super.key,
    required this.module,
    required this.tache,
    required this.niveau,
  });

  final TcfProductionModule module;
  final int tache;
  final String niveau;

  @override
  ConsumerState<_EntrainementTab> createState() => _EntrainementTabState();
}

class _EntrainementTabState extends ConsumerState<_EntrainementTab> {
  String? _situationId;
  String? _exampleId;
  bool _starting = false;

  final AudioPlayer _audio = AudioPlayer();
  String? _playingExampleId;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  ProductionSituationDto _selectedSituation(List<ProductionSituationDto> situations) {
    return situations.firstWhere(
      (s) => s.id == _situationId,
      orElse: () => situations.first,
    );
  }

  ProductionExampleDto? _selectedExample(List<ProductionExampleDto> examples) {
    if (examples.isEmpty) return null;
    return examples.firstWhere(
      (e) => e.id == _exampleId,
      orElse: () => examples.first,
    );
  }

  Future<void> _toggleAudio(ProductionExampleDto example) async {
    if (!example.hasAudio) return;
    if (_playingExampleId == example.id) {
      await _audio.stop();
      setState(() => _playingExampleId = null);
      return;
    }
    try {
      await _audio.stop();
      await _audio.setUrl(example.audioUrl!);
      setState(() => _playingExampleId = example.id);
      await _audio.play();
      if (mounted) setState(() => _playingExampleId = null);
    } catch (_) {
      if (mounted) setState(() => _playingExampleId = null);
    }
  }

  Future<void> _practice(ProductionTaskDto task, ProductionSituationDto situation) async {
    if (_starting) return;
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).startSingle(task: task, situationId: situation.id);
      } else {
        await ref.read(eeSessionProvider.notifier).startSingle(task: task, situationId: situation.id);
      }
      if (!mounted) return;
      context.push(widget.module.isEo
          ? '/tcf/expression-orale/t/0'
          : '/tcf/expression-ecrite/t/0');
    } catch (e) {
      if (!mounted) return;
      final err = ApiClient.toApiException(e);
      if (err.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final async = ref.watch(_entrainementProvider(_EntrainementKey(
      epreuve: mod.epreuve,
      tacheNumero: widget.tache,
      niveau: widget.niveau,
    )));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
      error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
      data: (data) {
        final displayTask = data.displayTask;
        final situations = data.situations;
        if (displayTask == null || situations.isEmpty) {
          return _Placeholder(
            icon: Icons.hourglass_empty_rounded,
            title: 'Bientôt disponible',
            description:
                'Les situations d\'entraînement de cette tâche ne sont pas encore prêtes. Reviens vite !',
          );
        }
        final situation = _selectedSituation(situations);
        final example = _selectedExample(data.examples);
        // La production se lance sur la tâche propre à la situation choisie
        // (son niveau), pas forcément celle d'affichage.
        final practiceTask = data.tasksById[situation.taskId] ?? displayTask;
        final hero = _heroCopy(mod, widget.tache);

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
              children: [
                _Hero(label: hero.$1, title: hero.$2, pitch: hero.$3, gradient: hero.$4),
                const SizedBox(height: 16),
                _StatsRow(
                  values: [
                    '${situations.length}',
                    '${data.examples.length}',
                    _durationLabel(mod, displayTask),
                  ],
                  labels: const ['Situations', 'Exemples', 'Cible'],
                ),
                const SizedBox(height: 18),
                _SectionHead(title: 'Situations'),
                const SizedBox(height: 10),
                _SituationsCarousel(
                  situations: situations,
                  selectedId: situation.id,
                  onSelect: (s) => setState(() {
                    _situationId = s.id;
                    _exampleId = null;
                  }),
                ),
                const SizedBox(height: 14),
                _ConsigneCard(module: mod, task: displayTask, situation: situation),
                const SizedBox(height: 14),
                _ExamplesCard(
                  module: mod,
                  examples: data.examples,
                  selected: example,
                  playingId: _playingExampleId,
                  onSelectExample: (e) => setState(() => _exampleId = e.id),
                  onToggleAudio: _toggleAudio,
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProductionPanel(
                module: mod,
                busy: _starting,
                onStart: () => _practice(practiceTask, situation),
              ),
            ),
          ],
        );
      },
    );
  }

  /// (label, titre, pitch, gradient) du hero selon module + tâche.
  (String, String, String, List<Color>) _heroCopy(TcfProductionModule mod, int tache) {
    if (mod.isEo) {
      return switch (tache) {
        1 => (
            '🎙️ Entraînement guidé',
            'Apprenez à vous présenter naturellement',
            'Plusieurs exemples pour une même situation, puis vous enregistrez votre propre réponse.',
            const [AppColors.blue, AppColors.blueDark],
          ),
        2 => (
            '🎭 Jeu de rôle guidé',
            'Apprenez à poser les bonnes questions',
            'Vous jouez une situation pratique : demander des informations, réserver, expliquer un besoin.',
            const [AppColors.blue, AppColors.blueDark],
          ),
        _ => (
            '💬 Donner son avis',
            'Exprimez votre opinion avec assurance',
            'Structurez un point de vue, illustrez-le d\'exemples, puis enregistrez votre réponse.',
            const [AppColors.blue, AppColors.blueDark],
          ),
      };
    }
    return switch (tache) {
      1 => (
          '✍️ Entraînement guidé',
          'Rédigez un message simple et clair',
          'Répondez à un message reçu : des exemples vous montrent le ton juste avant de rédiger.',
          const [AppColors.red, AppColors.redDark],
        ),
      2 => (
          '📖 Récit guidé',
          'Racontez une expérience',
          'Décrivez un événement vécu en suivant un plan d\'aide, puis rédigez votre propre récit.',
          const [AppColors.red, AppColors.redDark],
        ),
      _ => (
          '💬 Avis argumenté',
          'Défendez votre point de vue',
          'Donnez votre opinion avec des arguments illustrés, puis rédigez votre réponse.',
          const [AppColors.red, AppColors.redDark],
        ),
    };
  }

  String _durationLabel(TcfProductionModule mod, ProductionTaskDto task) {
    if (mod.isEo) {
      final sec = task.dureeMaxSec ?? 0;
      if (sec <= 0) return '—';
      final m = sec ~/ 60;
      final s = sec % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (task.motsMin != null && task.motsMax != null) {
      return '${task.motsMin}-${task.motsMax}';
    }
    return '—';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.label,
    required this.title,
    required this.pitch,
    required this.gradient,
  });

  final String label;
  final String title;
  final String pitch;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppFonts.jakarta(size: 12, weight: FontWeight.w800, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppFonts.jakarta(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text(
            pitch,
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.values,
    required this.labels,
  });

  final List<String> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < values.length; i++) ...[
          if (i != 0) const SizedBox(width: 10),
          _StatCell(value: values[i], label: labels[i]),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppFonts.jakarta(size: 18, weight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.mono(
                size: 9.5,
                color: AppColors.muted,
                letterSpacing: 1.2,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppFonts.jakarta(size: 17, weight: FontWeight.w800, color: AppColors.ink)
          .copyWith(letterSpacing: -0.2),
    );
  }
}

class _SituationsCarousel extends StatelessWidget {
  const _SituationsCarousel({
    required this.situations,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ProductionSituationDto> situations;
  final String selectedId;
  final ValueChanged<ProductionSituationDto> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: situations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = situations[i];
          final active = s.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: Container(
              width: 244,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: active ? AppColors.blueSoft : AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? AppColors.blue : AppColors.line,
                  width: active ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          s.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jakarta(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (s.niveauIndicatif != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.blueLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.niveauIndicatif!,
                            style: AppFonts.jakarta(
                              size: 11,
                              weight: FontWeight.w800,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      s.contexte,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jakarta(size: 13, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Carte « Consigne & préparation » : consigne + badge durée/mots, rôle (jeu de
/// rôle EO), supports visuels, déclencheur (EE) puis le plan d'aide.
class _ConsigneCard extends StatelessWidget {
  const _ConsigneCard({required this.module, required this.task, required this.situation});

  final TcfProductionModule module;
  final ProductionTaskDto task;
  final ProductionSituationDto situation;

  @override
  Widget build(BuildContext context) {
    final badge = module.isEo
        ? (task.dureeMaxSec != null ? '${(task.dureeMaxSec! / 60).ceil()} min' : null)
        : (task.motsMin != null && task.motsMax != null ? '${task.motsMin}-${task.motsMax} mots' : null);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  situation.isRolePlay ? 'Consigne & rôle' : 'Consigne & préparation',
                  style: AppFonts.jakarta(size: 18, weight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badge,
                    style: AppFonts.jakarta(size: 12, weight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (situation.declencheur != null) ...[
            _DeclencheurBox(declencheur: situation.declencheur!),
            const SizedBox(height: 14),
          ],
          Text(
            situation.consigne?.isNotEmpty == true ? situation.consigne! : situation.contexte,
            style: AppFonts.jakarta(size: 14, color: AppColors.ink2, height: 1.55),
          ),
          if (situation.isRolePlay) ...[
            const SizedBox(height: 14),
            if (situation.roleCandidat != null)
              _RoleRow(label: 'Votre rôle', value: situation.roleCandidat!),
            if (situation.objectif != null) ...[
              const SizedBox(height: 8),
              _RoleRow(label: 'Objectif', value: situation.objectif!),
            ],
          ],
          if (situation.medias.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SupportsRow(medias: situation.medias),
          ],
          if (situation.etapes.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (int i = 0; i < situation.etapes.length; i++) ...[
              _HelpItem(index: i + 1, etape: situation.etapes[i]),
              if (i != situation.etapes.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _DeclencheurBox extends StatelessWidget {
  const _DeclencheurBox({required this.declencheur});

  final ProductionDeclencheur declencheur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _avatarLetter(declencheur),
              style: AppFonts.jakarta(size: 15, weight: FontWeight.w800, color: AppColors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  declencheur.expediteur ?? 'Message reçu',
                  style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  declencheur.texte ?? '',
                  style: AppFonts.jakarta(size: 13, color: AppColors.ink2, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _avatarLetter(ProductionDeclencheur d) {
  if (d.avatar != null && d.avatar!.isNotEmpty) return d.avatar!.substring(0, 1).toUpperCase();
  if (d.expediteur != null && d.expediteur!.isNotEmpty) return d.expediteur!.substring(0, 1).toUpperCase();
  return '?';
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppFonts.jakarta(size: 12.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SupportsRow extends StatelessWidget {
  const _SupportsRow({required this.medias});

  final List<ProductionSituationMediaDto> medias;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: medias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = medias[i];
          return Container(
            width: 170,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: m.isSvg && m.inlineSvg != null
                      ? SvgPicture.string(m.inlineSvg!, fit: BoxFit.cover)
                      : (m.imageUrl != null
                          ? Image.network(m.imageUrl!, fit: BoxFit.cover)
                          : const ColoredBox(color: AppColors.line2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Text(
                    m.legende ?? m.altText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jakarta(size: 11.5, color: AppColors.ink2, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.index, required this.etape});

  final int index;
  final ProductionEtape etape;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(etape.icon), size: 17, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${etape.titre}',
                  style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: AppColors.ink),
                ),
                if (etape.aide != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    etape.aide!,
                    style: AppFonts.jakarta(size: 12, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String? key) {
    switch (key) {
      case 'person':
        return Icons.person_outline_rounded;
      case 'work':
        return Icons.work_outline_rounded;
      case 'target':
        return Icons.flag_outlined;
      case 'wave':
        return Icons.waving_hand_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'handshake':
        return Icons.handshake_outlined;
      case 'id':
        return Icons.badge_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'doc':
        return Icons.description_outlined;
      case 'question':
        return Icons.help_outline_rounded;
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'reply':
        return Icons.reply_rounded;
      case 'check':
        return Icons.check_circle_outline_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'euro':
        return Icons.euro_rounded;
      default:
        return Icons.bolt_outlined;
    }
  }
}

/// Carte « Exemples de réponses » : previews horizontales (titre + résumé +
/// Ouvrir / Écouter) puis le contenu de l'exemple ouvert et son plan rapide.
class _ExamplesCard extends StatelessWidget {
  const _ExamplesCard({
    required this.module,
    required this.examples,
    required this.selected,
    required this.playingId,
    required this.onSelectExample,
    required this.onToggleAudio,
  });

  final TcfProductionModule module;
  final List<ProductionExampleDto> examples;
  final ProductionExampleDto? selected;
  final String? playingId;
  final ValueChanged<ProductionExampleDto> onSelectExample;
  final ValueChanged<ProductionExampleDto> onToggleAudio;

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.isEo ? 'Exemples de réponses' : 'Exemples rédigés',
            style: AppFonts.jakarta(size: 17, weight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: examples.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final ex = examples[i];
                final active = ex.id == selected?.id;
                return _ExamplePreview(
                  index: i + 1,
                  example: ex,
                  active: active,
                  showAudio: module.isEo && ex.hasAudio,
                  playing: playingId == ex.id,
                  onOpen: () => onSelectExample(ex),
                  onAudio: () => onToggleAudio(ex),
                );
              },
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: const Border(left: BorderSide(color: AppColors.blue, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected!.titre,
                          style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ),
                      Text(
                        'Exemple ${examples.indexOf(selected!) + 1}/${examples.length}',
                        style: AppFonts.mono(
                          size: 9.5,
                          color: AppColors.muted,
                          letterSpacing: 1.2,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selected!.contenu,
                    style: AppFonts.jakarta(size: 14, color: AppColors.ink2, height: 1.6),
                  ),
                ],
              ),
            ),
            if (selected!.planPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Plan rapide',
                style: AppFonts.jakarta(size: 15, weight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              for (final p in selected!.planPoints) _PlanRow(text: p),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExamplePreview extends StatelessWidget {
  const _ExamplePreview({
    required this.index,
    required this.example,
    required this.active,
    required this.showAudio,
    required this.playing,
    required this.onOpen,
    required this.onAudio,
  });

  final int index;
  final ProductionExampleDto example;
  final bool active;
  final bool showAudio;
  final bool playing;
  final VoidCallback onOpen;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.blueSoft : AppColors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? AppColors.blue : AppColors.line,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  example.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jakarta(size: 14, weight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$index',
                  style: AppFonts.jakarta(size: 11, weight: FontWeight.w800, color: AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              example.resume ?? example.contenu,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jakarta(size: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniBtn(label: 'Ouvrir', filled: true, onTap: onOpen),
              if (showAudio) ...[
                const SizedBox(width: 8),
                _MiniBtn(
                  label: playing ? 'Stop' : 'Écouter',
                  icon: playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  filled: false,
                  onTap: onAudio,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.label, required this.filled, required this.onTap, this.icon});

  final String label;
  final bool filled;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? AppColors.blue : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: AppColors.blueLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: filled ? AppColors.white : AppColors.blue),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppFonts.jakarta(
                size: 11.5,
                weight: FontWeight.w800,
                color: filled ? AppColors.white : AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.check_rounded, size: 13, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.jakarta(size: 13, color: AppColors.ink2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panneau fixe en bas de l'onglet Entraînement : invite à produire (micro pour
/// l'EO, rédaction pour l'EE). Le tap démarre une session single-task sur la
/// situation choisie et pousse le flux briefing → enregistrement/écriture.
class _ProductionPanel extends StatelessWidget {
  const _ProductionPanel({
    required this.module,
    required this.busy,
    required this.onStart,
  });

  final TcfProductionModule module;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isEo = module.isEo;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEo ? AppColors.redLight : AppColors.blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEo ? Icons.mic_rounded : Icons.edit_note_rounded,
              color: isEo ? AppColors.red : AppColors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEo ? 'À vous de parler' : 'À vous d\'écrire',
                  style: AppFonts.jakarta(size: 14, weight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  isEo
                      ? 'Enregistrez votre réponse pour cette situation.'
                      : 'Rédigez votre réponse pour cette situation.',
                  style: AppFonts.jakarta(size: 11.5, color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: busy ? null : onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.white),
                    )
                  : Text(
                      isEo ? 'Enregistrer' : 'Rédiger',
                      style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: AppColors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Onglet EXAMENS — 10 slots de sessions 3-tâches
// ============================================================================

const int _examSlotsCount = 10;

class _ProductionExamSession {
  _ProductionExamSession({required this.attemptId, required this.submissions});

  final String attemptId;
  final List<ProductionSubmissionDto> submissions;

  DateTime get firstSubmittedAt =>
      submissions.map((s) => s.submittedAt).reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get lastSubmittedAt =>
      submissions.map((s) => s.submittedAt).reduce((a, b) => a.isAfter(b) ? a : b);

  int get evaluatedCount => submissions.where((s) => s.evaluation != null).length;

  NiveauCecrl? get niveauPlancher {
    NiveauCecrl? floor;
    for (final s in submissions) {
      final n = s.evaluation?.niveauCecrl;
      if (n == null) continue;
      if (floor == null || n.scaleIndex < floor.scaleIndex) floor = n;
    }
    return floor;
  }

  double? get noteMoyenne {
    final notes = submissions.map((s) => s.evaluation?.noteSurVingt).whereType<double>().toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }
}

final _examsHistoryProvider =
    FutureProvider.autoDispose.family<List<_ProductionExamSession>, EpreuveType>((ref, epreuve) async {
  final all = await ref.watch(productionRepositoryProvider).listMine(epreuve: epreuve, limit: 200);
  final byAttempt = <String, List<ProductionSubmissionDto>>{};
  for (final s in all) {
    final id = s.attemptId;
    if (id == null) continue;
    byAttempt.putIfAbsent(id, () => []).add(s);
  }
  final exams = <_ProductionExamSession>[];
  for (final entry in byAttempt.entries) {
    if (entry.value.length < 3) continue;
    exams.add(_ProductionExamSession(attemptId: entry.key, submissions: entry.value));
  }
  exams.sort((a, b) => a.firstSubmittedAt.compareTo(b.firstSubmittedAt));
  return exams;
});

class _ExamensTab extends ConsumerStatefulWidget {
  const _ExamensTab({required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<_ExamensTab> createState() => _ExamensTabState();
}

class _ExamensTabState extends ConsumerState<_ExamensTab> {
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
  }

  Future<void> _startFullExam() async {
    if (_starting) return;
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    final auth = ref.read(authControllerProvider);
    final niveau = auth is AuthAuthenticated ? (auth.user.targetProcedure?.tcfLevel ?? 'B1') : 'B1';
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).start(niveau: niveau);
        if (!mounted) return;
        context.push('/tcf/expression-orale/t/0');
      } else {
        await ref.read(eeSessionProvider.notifier).start(niveau: niveau);
        if (!mounted) return;
        context.push('/tcf/expression-ecrite/t/0');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.toApiException(e).message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final isPremium = _isPremium();
    final asyncExams = ref.watch(_examsHistoryProvider(mod.epreuve));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Hero(
          label: '📝 Simulation officielle',
          title: mod.isEo ? 'Simulez l\'oral comme au vrai examen' : 'Simulez l\'écrit comme au vrai examen',
          pitch: 'Pas d\'exemples, pas d\'aide détaillée : vous répondez directement, puis l\'IA corrige.',
          gradient: const [AppColors.ink, AppColors.blueDark],
        ),
        const SizedBox(height: 16),
        _StatsRow(
          values: ['3', mod.durationLabel, 'IA'],
          labels: const ['Tâches', 'Minutes', 'Correction'],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SectionHead(title: 'Tes examens'),
            const Spacer(),
            Text(
              '$_examSlotsCount disponibles',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 1.2,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        asyncExams.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.red)),
          ),
          error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
          data: (exams) => Column(
            children: [
              for (int i = 0; i < _examSlotsCount; i++)
                _ExamSlotCard(
                  slot: i + 1,
                  session: i < exams.length ? exams[i] : null,
                  locked: !isPremium,
                  onTapEmpty: _starting
                      ? null
                      : !isPremium
                          ? () => showPaywallSheet(context)
                          : () => showProductionExamBriefingSheet(
                                context,
                                module: mod,
                                starting: _starting,
                                onStart: _startFullExam,
                              ),
                  onTapDone: (s) => _showSessionSheet(context, s),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSessionSheet(BuildContext context, _ProductionExamSession session) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ExamActionSheet(
        session: session,
        onViewDetails: () {
          Navigator.of(sheetCtx).pop();
          final base = widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
          context.push('$base/sessions/${session.attemptId}');
        },
        onRetake: () {
          Navigator.of(sheetCtx).pop();
          showProductionExamBriefingSheet(
            context,
            module: widget.module,
            starting: _starting,
            onStart: _startFullExam,
          );
        },
      ),
    );
  }
}

class _ExamActionSheet extends StatelessWidget {
  const _ExamActionSheet({
    required this.session,
    required this.onViewDetails,
    required this.onRetake,
  });

  final _ProductionExamSession session;
  final VoidCallback onViewDetails;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final niveau = session.niveauPlancher;
    final note = session.noteMoyenne;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Examen passé',
                style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _summary(niveau, note),
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              AppButton(label: 'Voir les détails', icon: Icons.visibility_outlined, onPressed: onViewDetails),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reprendre (nouvelle session)',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: onRetake,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summary(NiveauCecrl? niveau, double? note) {
    final parts = <String>[];
    if (niveau != null) parts.add('Niveau ${niveau.displayName}');
    if (note != null) parts.add('moyenne ${_formatNote(note)}/20');
    if (session.evaluatedCount < session.submissions.length) {
      parts.add('${session.evaluatedCount}/${session.submissions.length} évaluations remontées');
    }
    if (parts.isEmpty) return 'Évaluation IA en cours.';
    return parts.join(' · ');
  }
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.session,
    required this.onTapEmpty,
    required this.onTapDone,
    this.locked = false,
  });

  final int slot;
  final _ProductionExamSession? session;
  final VoidCallback? onTapEmpty;
  final ValueChanged<_ProductionExamSession> onTapDone;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final done = session != null;
    final color = _slotColor(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? color.withValues(alpha: 0.3) : AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: done ? () => onTapDone(session!) : onTapEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? color : AppColors.line2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$slot',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: done ? AppColors.white : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen $slot',
                          style: AppFonts.jakarta(size: 14.5, weight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done ? _formatDoneSubtitle(session!) : 'Disponible · 3 tâches enchaînées',
                          style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (locked)
                    _SlotTrailingIcon(icon: Icons.lock_outline_rounded)
                  else if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        session!.niveauPlancher?.displayName ?? '…',
                        style: AppFonts.jakarta(size: 12, weight: FontWeight.w800, color: AppColors.white),
                      ),
                    )
                  else
                    const Icon(Icons.play_arrow_rounded, color: AppColors.muted2, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _slotColor(_ProductionExamSession? s) {
    final niveau = s?.niveauPlancher;
    if (niveau == null) return AppColors.muted;
    return _colorForLevel(niveau);
  }

  String _formatDoneSubtitle(_ProductionExamSession s) {
    final date = _formatDate(s.lastSubmittedAt);
    final note = s.noteMoyenne;
    if (note == null) return '$date · évaluation en cours';
    return '$date · ${_formatNote(note)}/20 moyenne';
  }
}

class _SlotTrailingIcon extends StatelessWidget {
  const _SlotTrailingIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.line2, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 15, color: AppColors.muted),
    );
  }
}

// ============================================================================
// Onglet CORRECTIONS — historique filtrable par tâche
// ============================================================================

final _correctionsProvider =
    FutureProvider.autoDispose.family<List<ProductionSubmissionDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listMine(epreuve: epreuve, limit: 50);
});

class _CorrectionsTab extends ConsumerStatefulWidget {
  const _CorrectionsTab({required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<_CorrectionsTab> createState() => _CorrectionsTabState();
}

class _CorrectionsTabState extends ConsumerState<_CorrectionsTab> {
  int _filter = 0; // 0 = toutes, 1/2/3 = tâche

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final async = ref.watch(_correctionsProvider(mod.epreuve));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Hero(
          label: '🤖 Historique IA',
          title: 'Retrouvez toutes vos corrections',
          pitch: 'Scores, transcription, points forts, erreurs et conseils restent disponibles à tout moment.',
          gradient: const [AppColors.blueDark, AppColors.blue],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i <= 3; i++) ...[
              _FilterChip(
                label: i == 0 ? 'Toutes' : 'Tâche $i',
                active: _filter == i,
                onTap: () => setState(() => _filter = i),
              ),
              if (i != 3) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue)),
          ),
          error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
          data: (subs) {
            var finished = subs.where((s) => s.statut.isFinal).toList();
            if (_filter != 0) {
              finished = finished.where((s) => (s.tacheNumero ?? 1) == _filter).toList();
            }
            if (finished.isEmpty) {
              return _Placeholder(
                icon: Icons.history_rounded,
                title: 'Pas encore de ${mod.historyTabLabel.toLowerCase()}',
                description:
                    'Tes ${mod.historyTabLabel.toLowerCase()} apparaîtront ici une fois la première tâche évaluée par l\'IA.',
              );
            }
            return Column(
              children: [for (final s in finished) _SubmissionRow(module: mod, submission: s)],
            );
          },
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.blue : AppColors.line2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppFonts.jakarta(
            size: 12,
            weight: FontWeight.w800,
            color: active ? AppColors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.module, required this.submission});

  final TcfProductionModule module;
  final ProductionSubmissionDto submission;

  @override
  Widget build(BuildContext context) {
    final isEval = submission.statut == SubmissionStatut.evaluated;
    final isFailed = submission.statut == SubmissionStatut.failed;
    final niveau = submission.evaluation?.niveauCecrl;
    final note = submission.evaluation?.noteSurVingt;
    final tache = submission.tacheNumero ?? 1;
    final color = isFailed ? AppColors.red : (niveau == null ? AppColors.muted : _colorForLevel(niveau));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final base = module.isEo
                  ? '/tcf/expression-orale/resultats'
                  : '/tcf/expression-ecrite/resultats';
              context.push('$base/${submission.id}?taskIndex=${tache - 1}&history=1');
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'T$tache',
                      style: AppFonts.jakarta(size: 12, weight: FontWeight.w800, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(submission.submittedAt),
                          style: AppFonts.jakarta(size: 13.5, weight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFailed
                              ? 'Évaluation échouée'
                              : isEval && niveau != null
                                  ? '${niveau.displayName}${note != null ? " · ${_formatNote(note)}/20" : ""}'
                                  : 'Évaluation en cours…',
                          style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isEval && niveau != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        niveau.displayName,
                        style: AppFonts.jakarta(size: 12, weight: FontWeight.w800, color: AppColors.white),
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Helpers partagés
// ============================================================================

Color _colorForLevel(NiveauCecrl level) {
  switch (level) {
    case NiveauCecrl.a1NonAtteint:
    case NiveauCecrl.a1:
    case NiveauCecrl.a2:
      return AppColors.red;
    case NiveauCecrl.b1:
      return AppColors.amber;
    case NiveauCecrl.b2:
    case NiveauCecrl.c1:
    case NiveauCecrl.c2:
      return AppColors.green;
  }
}

String _formatNote(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

String _formatDate(DateTime d) {
  const months = [
    'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: AppColors.blue, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 16, weight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: AppFonts.jakarta(size: 12.5, color: AppColors.redDark)),
      ),
    );
  }
}
