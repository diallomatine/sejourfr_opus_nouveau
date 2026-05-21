import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../tcf_production/ee_session_controller.dart';
import '../tcf_production/eo_session_controller.dart';
import 'widgets/module_detail_widgets.dart';

/// Seuil au-delà duquel on regroupe les sujets par lots de 5 (cf. user spec).
/// En-dessous : liste plate dans une seule catégorie.
const _lotChunkSize = 5;
const _lotThreshold = 15;

/// Famille (epreuve, tacheNumero, niveau) → liste des `ProductionTaskDto`.
final _tasksProvider = FutureProvider.autoDispose
    .family<List<ProductionTaskDto>, _TasksKey>((ref, key) {
  return ref.watch(productionRepositoryProvider).listTasks(
        epreuve: key.epreuve,
        niveau: key.niveau,
        tacheNumero: key.tacheNumero,
      );
});

class _TasksKey {
  const _TasksKey({
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
      other is _TasksKey &&
          other.epreuve == epreuve &&
          other.tacheNumero == tacheNumero &&
          other.niveau == niveau;

  @override
  int get hashCode => Object.hash(epreuve, tacheNumero, niveau);
}

/// Liste des sujets d'une tâche EE ou EO. Si plus de 15 sujets disponibles
/// pour ce (épreuve, tâche, niveau), on les regroupe par lots de 5. Sinon
/// liste plate. Tap → `startSingle(task)` du session controller approprié
/// puis push briefing.
///
/// **Cas particulier EO Tâche 1** : la consigne est fixe (présentation),
/// on bypass l'écran lots et on push directement le briefing avec la
/// première (ou seule) consigne. Cf. choix produit confirmé par le user.
class TcfProductionTaskSubjectsScreen extends ConsumerStatefulWidget {
  const TcfProductionTaskSubjectsScreen({
    super.key,
    required this.epreuve,
    required this.tacheNumero,
  });

  final EpreuveType epreuve;
  final int tacheNumero;

  @override
  ConsumerState<TcfProductionTaskSubjectsScreen> createState() =>
      _TcfProductionTaskSubjectsScreenState();
}

class _TcfProductionTaskSubjectsScreenState
    extends ConsumerState<TcfProductionTaskSubjectsScreen> {
  bool _starting = false;
  bool _autoStartTriggered = false;

  bool get _isEo => widget.epreuve == EpreuveType.tcfEo;

  String get _briefingRoute => _isEo
      ? '/tcf/expression-orale/t/0'
      : '/tcf/expression-ecrite/t/0';

  String _niveauFromUser() {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return 'B1';
    return auth.user.targetProcedure?.tcfLevel ?? 'B1';
  }

  Future<void> _startTask(ProductionTaskDto task) async {
    if (_starting) return;
    final auth = ref.read(authControllerProvider);
    final isPremium =
        auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
    if (!isPremium) {
      showPaywallSheet(context);
      return;
    }
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (_isEo) {
        await ref.read(eoSessionProvider.notifier).startSingle(task: task);
      } else {
        await ref.read(eeSessionProvider.notifier).startSingle(task: task);
      }
      if (!mounted) return;
      context.push(_briefingRoute);
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErr.message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Cas spécial : EO Tâche 1 (consigne fixe). On démarre directement avec
  /// la première tâche renvoyée par l'API, sans afficher l'écran lots —
  /// l'utilisateur n'a pas à choisir.
  void _maybeAutoStartEoT1(List<ProductionTaskDto> tasks) {
    if (_autoStartTriggered) return;
    if (!_isEo || widget.tacheNumero != 1) return;
    if (tasks.isEmpty) return;
    _autoStartTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startTask(tasks.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final niveau = _niveauFromUser();
    final asyncTasks = ref.watch(_tasksProvider(_TasksKey(
      epreuve: widget.epreuve,
      tacheNumero: widget.tacheNumero,
      niveau: niveau,
    )));

    final isEo = _isEo;
    final mod = isEo ? 'Expression orale' : 'Expression écrite';
    final taskLabels = isEo
        ? const {
            1: 'Présentation',
            2: 'Jeu de rôle',
            3: 'Opinion',
          }
        : const {
            1: 'Message simple',
            2: 'Récit',
            3: 'Opinion',
          };
    final taskLabel = taskLabels[widget.tacheNumero] ?? 'Tâche';
    final icon = isEo ? Icons.mic_rounded : Icons.edit_note_rounded;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            asyncTasks.when(
              loading: _loading,
              error: (e, _) => _ErrorView(
                message: ApiClient.toApiException(e).message,
                onBack: () => _back(context),
              ),
              data: (tasks) {
                _maybeAutoStartEoT1(tasks);
                // En EO T1 on a déclenché un push direct vers le briefing —
                // on affiche un état de transition pendant que le push se fait.
                if (isEo && widget.tacheNumero == 1) {
                  return _loading();
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    ModuleDetailTopBar(
                      onBack: () => _back(context),
                      icon: icon,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blueLight,
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailTitle(
                      eyebrow: '$mod · Niveau $niveau',
                      title: 'Tâche ${widget.tacheNumero} · $taskLabel',
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailHero(
                      icon: icon,
                      headline: tasks.isEmpty
                          ? 'Aucun sujet disponible'
                          : '${tasks.length} sujet${tasks.length > 1 ? "s" : ""} disponible${tasks.length > 1 ? "s" : ""}',
                      description:
                          'Choisis un sujet pour démarrer ton ${isEo ? "enregistrement" : "écrit"}. Tu recevras une évaluation CECRL à la fin.',
                      gradient: const [AppColors.red, AppColors.redDark],
                    ),
                    const SizedBox(height: 18),
                    _SubjectsList(
                      tasks: tasks,
                      tacheNumero: widget.tacheNumero,
                      onTap: _startTask,
                    ),
                  ],
                );
              },
            ),
            if (_starting)
              const Positioned.fill(
                child: ModuleDetailStartingOverlay(accent: AppColors.blue),
              ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_isEo ? '/tcf/eo' : '/tcf/ee');
    }
  }
}

/// Présentation des sujets : groupés par lots de 5 si > 15 sujets, sinon
/// liste plate sous un seul header de catégorie.
class _SubjectsList extends StatelessWidget {
  const _SubjectsList({
    required this.tasks,
    required this.tacheNumero,
    required this.onTap,
  });

  final List<ProductionTaskDto> tasks;
  final int tacheNumero;
  final ValueChanged<ProductionTaskDto> onTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const ModuleDetailTabPlaceholder(
        icon: Icons.hourglass_empty_rounded,
        title: 'Pas encore de sujet',
        description:
            'Le catalogue pour cette tâche n\'est pas encore prêt à ton niveau. Reviens plus tard.',
      );
    }

    if (tasks.length <= _lotThreshold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: '${tasks.length} sujet${tasks.length > 1 ? "s" : ""}'),
          const SizedBox(height: 10),
          for (int i = 0; i < tasks.length; i++)
            _SubjectCard(
              index: i + 1,
              task: tasks[i],
              onTap: () => onTap(tasks[i]),
            ),
        ],
      );
    }

    // > 15 sujets → groupés par lots de 5 (Lot 1, Lot 2, …). Le dernier lot
    // peut être plus court ; on l'expose quand même pour ne pas masquer de
    // sujets disponibles.
    final lots = <List<ProductionTaskDto>>[];
    for (int i = 0; i < tasks.length; i += _lotChunkSize) {
      lots.add(tasks.sublist(
        i,
        (i + _lotChunkSize).clamp(0, tasks.length),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int li = 0; li < lots.length; li++) ...[
          _SectionHeader(
            label: 'Lot ${li + 1} · ${lots[li].length} sujet${lots[li].length > 1 ? "s" : ""}',
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < lots[li].length; i++)
            _SubjectCard(
              index: li * _lotChunkSize + i + 1,
              task: lots[li][i],
              onTap: () => onTap(lots[li][i]),
            ),
          if (li != lots.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppFonts.mono(
        size: 10,
        color: AppColors.muted,
        letterSpacing: 1.8,
        weight: FontWeight.w600,
      ),
    );
  }
}

/// Carte d'un sujet : numéro + consigne tronquée + chip durée/mots + chevron.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.index,
    required this.task,
    required this.onTap,
  });

  final int index;
  final ProductionTaskDto task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _formatMeta();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$index',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.white,
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
                          task.consigne,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.35,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: AppFonts.mono(
                              size: 10,
                              color: AppColors.muted,
                              letterSpacing: 1.2,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted2,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMeta() {
    final parts = <String>[];
    if (task.dureeMaxSec != null) {
      final mins = (task.dureeMaxSec! / 60).ceil();
      parts.add('$mins MIN MAX');
    }
    if (task.motsMin != null && task.motsMax != null) {
      parts.add('${task.motsMin}-${task.motsMax} MOTS');
    } else if (task.motsMax != null) {
      parts.add('≤ ${task.motsMax} MOTS');
    }
    return parts.join(' · ');
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.ink,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: AppFonts.jakarta(size: 14, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
