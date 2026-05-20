import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_hub_controller.dart';
import 'widgets/level_pill.dart';
import 'widgets/production_app_header.dart';

/// Hub d'entrainement EO/EE : ecran d'accueil qui propose les 3 taches
/// individuellement. L'utilisateur en choisit une, fait son entrainement,
/// puis revient au hub. Pas de chainage T1 -> T2 -> T3 (reserve a l'examen
/// blanc, a venir).
class ProductionHubScreen extends ConsumerStatefulWidget {
  const ProductionHubScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  @override
  ConsumerState<ProductionHubScreen> createState() =>
      _ProductionHubScreenState();
}

class _ProductionHubScreenState extends ConsumerState<ProductionHubScreen> {
  String _niveauForUser() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      final tp = auth.user.targetProcedure;
      if (tp != null) return tp.tcfLevel;
    }
    return 'B1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Au mount on charge (ou recharge si niveau a change). Au retour d'une
      // tache, on rafraichit juste les notes via refreshLast().
      final current = ref.read(productionHubProvider(widget.epreuve)).value;
      final niveau = _niveauForUser();
      if (current == null || current.niveau != niveau || current.picked.isEmpty) {
        ref.read(productionHubProvider(widget.epreuve).notifier).load(niveau: niveau);
      } else {
        ref.read(productionHubProvider(widget.epreuve).notifier).refreshLast();
      }
    });
  }

  String get _epreuveLabel =>
      widget.epreuve == EpreuveType.tcfEo ? 'Expression orale' : 'Expression écrite';

  String get _epreuveRoot =>
      widget.epreuve == EpreuveType.tcfEo
          ? '/tcf/expression-orale'
          : '/tcf/expression-ecrite';

  Future<void> _startTask(ProductionTaskDto task) async {
    if (widget.epreuve == EpreuveType.tcfEo) {
      await ref.read(eoSessionProvider.notifier).startSingle(task: task);
    } else {
      await ref.read(eeSessionProvider.notifier).startSingle(task: task);
    }
    if (!mounted) return;
    context.push('$_epreuveRoot/t/0');
  }

  @override
  Widget build(BuildContext context) {
    final hubState = ref.watch(productionHubProvider(widget.epreuve));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: ProductionAppHeader(title: _epreuveLabel),
      body: hubState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref
              .read(productionHubProvider(widget.epreuve).notifier)
              .load(niveau: _niveauForUser()),
        ),
        data: (state) {
          if (!state.isReady) {
            return _EmptyState(epreuveLabel: _epreuveLabel, niveau: state.niveau);
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(productionHubProvider(widget.epreuve).notifier)
                .load(niveau: _niveauForUser()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                _Intro(niveau: state.niveau),
                const SizedBox(height: 16),
                for (final entry in [1, 2, 3])
                  if (state.picked[entry] != null) ...[
                    _TaskCard(
                      task: state.picked[entry]!,
                      lastSubmission: state.lastByNumero[entry],
                      canChange: (state.tasksByNumero[entry]?.length ?? 0) > 1
                          && entry != 1, // T1 = consigne fixe (presentation)
                      onStart: () => _startTask(state.picked[entry]!),
                      onReroll: () => ref
                          .read(productionHubProvider(widget.epreuve).notifier)
                          .rerollTask(entry),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
                _HistoryLink(epreuveRoot: _epreuveRoot),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.niveau});
  final String niveau;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Eyebrow('ENTRAÎNEMENT LIBRE'),
            const SizedBox(width: 8),
            LevelPill(level: _niveau(niveau)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez la tâche à travailler',
          style: AppFonts.fraunces(
            size: 24,
            weight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pas de chrono — concentrez-vous sur une tâche à la fois. '
          'Vous recevrez votre évaluation détaillée juste après.',
          style: AppFonts.jakarta(
            size: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  NiveauCecrl _niveau(String niveau) {
    return switch (niveau.toUpperCase()) {
      'A2' => NiveauCecrl.a2,
      'B1' => NiveauCecrl.b1,
      'B2' => NiveauCecrl.b2,
      _ => NiveauCecrl.b1,
    };
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.canChange,
    required this.onStart,
    required this.onReroll,
    this.lastSubmission,
  });

  final ProductionTaskDto task;
  final ProductionSubmissionDto? lastSubmission;
  final bool canChange;
  final VoidCallback onStart;
  final VoidCallback onReroll;

  @override
  Widget build(BuildContext context) {
    final note = lastSubmission?.evaluation?.noteSurVingt;
    final niveauEval = lastSubmission?.evaluation?.niveauCecrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow('TÂCHE ${task.tacheNumero}'),
              if (note != null && niveauEval != null) _NoteBadge(note: note, niveau: niveauEval),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.displayTitle,
            style: AppFonts.fraunces(
              size: 19,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.consigne,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (canChange)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Commencer',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onStart,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReroll,
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('Changer'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppFonts.jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            AppButton(
              label: 'Commencer',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
        ],
      ),
    );
  }
}

class _NoteBadge extends StatelessWidget {
  const _NoteBadge({required this.note, required this.niveau});
  final double note;
  final NiveauCecrl niveau;

  @override
  Widget build(BuildContext context) {
    final color = note >= 14
        ? AppColors.green
        : note >= 10
            ? AppColors.amber
            : AppColors.red;
    final formatted = note == note.roundToDouble()
        ? note.toInt().toString()
        : note.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$formatted/20 · ${niveau.displayName}',
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLink extends StatelessWidget {
  const _HistoryLink({required this.epreuveRoot});
  final String epreuveRoot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('$epreuveRoot/historique'),
        icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.blue),
        label: Text(
          'Voir mon historique',
          style: AppFonts.jakarta(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.epreuveLabel, required this.niveau});
  final String epreuveLabel;
  final String niveau;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: AppColors.muted2),
            const SizedBox(height: 12),
            Text(
              'Aucune tâche disponible',
              style: AppFonts.jakarta(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Le catalogue de tâches $epreuveLabel n\'est pas encore peuplé pour le niveau $niveau.',
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
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les tâches.',
            style: AppFonts.jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Réessayer',
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }
}
