import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'production_result_polling.dart';
import 'ee_session_controller.dart';
import 'widgets/evaluation_loading_view.dart';
import 'widgets/evaluation_report.dart';
import 'widgets/production_app_header.dart';

final _submissionFetcher = FutureProvider.autoDispose
    .family<ProductionSubmissionDto, String>((ref, id) {
  return ref.watch(productionRepositoryProvider).getSubmission(id);
});

/// Écran résultats EE : tant que la submission est dans un statut
/// intermédiaire (SUBMITTED / TRANSCRIBING / EVALUATING), on poll toutes
/// les 3 s et on affiche le loader IA. Le pipeline backend tourne en async
/// (cf. ProductionPipelineAsyncRunner) → ~10-15 s en moyenne pour Claude.
class EeResultsScreen extends ConsumerStatefulWidget {
  const EeResultsScreen({
    super.key,
    required this.submissionId,
    required this.taskIndex,
    this.isHistory = false,
  });

  final String submissionId;
  final int taskIndex;

  /// True quand on consulte les résultats depuis l'historique : on cache les
  /// CTAs "Passer a la tache N+1" / "Voir mon bilan" au profit d'un simple "Retour".
  final bool isHistory;

  @override
  ConsumerState<EeResultsScreen> createState() => _EeResultsScreenState();
}

class _EeResultsScreenState extends ConsumerState<EeResultsScreen> {
  Timer? _poll;

  /// Arrêt du polling : statut final, budget épuisé, ou fin du sursis accordé
  /// au plan d'action. Une seule boucle, une seule règle — cf.
  /// [ProductionResultPollGuard].
  final ProductionResultPollGuard _guard = ProductionResultPollGuard();

  /// Le second appel peut encore aboutir : la place du plan d'action porte son
  /// indicateur, qui s'efface en silence à la fin du sursis.
  bool _actionPlanPending = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(kProductionPollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final value =
          ref.read(_submissionFetcher(widget.submissionId)).valueOrNull;
      final again = _guard.shouldPoll(value);
      if (_actionPlanPending != _guard.awaitsActionPlan) {
        setState(() => _actionPlanPending = _guard.awaitsActionPlan);
      }
      if (!again) {
        timer.cancel();
        return;
      }
      ref.invalidate(_submissionFetcher(widget.submissionId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session =
        widget.isHistory ? null : ref.watch(eeSessionProvider).value;
    final async = ref.watch(_submissionFetcher(widget.submissionId));

    // Lecture des query params depuis le State du screen — `GoRouterState.of`
    // est garanti accessible ici car ce widget est directement le builder
    // d'une GoRoute. On les passe en paramètres aux sous-widgets pour ne pas
    // ré-appeler `GoRouterState.of` dans des sous-arbres qui peuvent être
    // rebuilds hors du contexte route (cf. crash "no GoRouterState above").
    final qp = GoRouterState.of(context).uri.queryParameters;
    final fullExamId = qp['fullExamId'];

    final fallbackRoute =
        fullExamId != null ? '/tcf/examen-blanc/$fullExamId' : '/tcf/ee';
    return _Wrapper(
      fallbackRoute: fallbackRoute,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              ApiClient.toApiException(e).message,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (sub) {
          if (sub.statut.isInProgress) {
            return const Center(child: EvaluationLoadingView());
          }
          return _ResultsBody(
            submission: sub,
            taskIndex: widget.taskIndex,
            session: session,
            isHistory: widget.isHistory,
            fullExamId: fullExamId,
            queryParameters: qp,
            actionPlanPending: _actionPlanPending,
          );
        },
      ),
    );
  }
}

class _Wrapper extends StatelessWidget {
  const _Wrapper({required this.body, this.fallbackRoute = '/tcf'});

  final Widget body;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond legerement teinte, comme la maquette : les cartes blanches du
      // rapport ne se detachaient pas sur du blanc pur.
      backgroundColor: AppColors.bg,
      appBar: ProductionAppHeader(
        title: 'Résultats',
        fallbackRoute: fallbackRoute,
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: body,
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.submission,
    required this.taskIndex,
    required this.session,
    required this.isHistory,
    required this.fullExamId,
    required this.queryParameters,
    required this.actionPlanPending,
  });

  final bool isHistory;
  final ProductionSubmissionDto submission;
  final int taskIndex;
  final EeSessionState? session;

  /// Reçu par le parent (qui a accès garanti à GoRouterState). Non-null
  /// quand on est dans un examen blanc TCF complet — pilote le label du
  /// CTA et la cible de navigation.
  final String? fullExamId;

  /// Snapshot des query params de la route au moment du build du parent.
  /// Utilisé pour propager fullExamId / subAttemptId aux tâches suivantes.
  final Map<String, String> queryParameters;

  /// Le sursis accordé au second appel court encore : le rapport rend son
  /// indicateur à la place du plan d'action.
  final bool actionPlanPending;

  /// Mode entrainement libre (single-task depuis le hub). Voir EoResultsScreen.
  bool get _isSingleTask =>
      !isHistory && session != null && session!.totalTasks == 1;

  String get _bilanCtaLabel =>
      fullExamId != null ? 'Continuer l\'examen blanc' : 'Voir mon bilan';

  void _navigateToBilan(BuildContext context, WidgetRef ref) {
    if (fullExamId != null) {
      ref.read(eeSessionProvider.notifier).reset();
      ref.invalidate(fullTcfExamProvider(fullExamId!));
      context.go('/tcf/examen-blanc/$fullExamId');
      return;
    }
    // Hors examen blanc complet : CTA atteint uniquement quand la session
    // 3-tâches est en mode legacy. Pour le nouveau flux, `ee_briefing_writing_screen`
    // push directement le bilan détaillé après T3.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eval = submission.evaluation;
    if (eval == null) {
      return _FailedBlock(
        submission: submission,
        onRetry: () => _retry(context, ref),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            children: [
              EvaluationReport(
                evaluation: eval,
                isOral: false,
                eyebrow: 'Expression écrite · Tâche ${taskIndex + 1}',
                productionText: submission.texteSoumis,
                targetLevel: ref.watch(userTargetLevelProvider),
                planChange: submission.planChange,
                actionPlanPending: actionPlanPending,
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: SafeArea(
            top: false,
            child: isHistory
                ? AppButton(
                    label: 'Retour',
                    icon: LucideIcons.arrowLeft,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : _isSingleTask
                    ? AppButton(
                        label: 'Retour à l\'entraînement',
                        icon: LucideIcons.layoutGrid,
                        onPressed: () {
                          // Retour à l'écran d'entraînement Expression écrite
                          // (onglet Entraînement, carrousel de situations).
                          ref.read(eeSessionProvider.notifier).reset();
                          context.go(AppRoutes.tcfEeDetail);
                        },
                      )
                    : AppButton(
                        // Atteint uniquement en mode examen blanc complet
                        // (fullExamId != null) ; en session 3-tâches autonome,
                        // `ee_briefing_writing_screen` push directement le
                        // bilan détaillé après T3.
                        label: _bilanCtaLabel,
                        icon: LucideIcons.chartColumn,
                        onPressed: () => _navigateToBilan(context, ref),
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(productionRepositoryProvider)
          .retrySubmission(submission.id);
      ref.invalidate(_submissionFetcher(submission.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.toApiException(e).message)),
      );
    }
  }
}

class _FailedBlock extends StatelessWidget {
  const _FailedBlock({required this.submission, required this.onRetry});

  final ProductionSubmissionDto submission;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert,
              size: 40, color: AppColors.red),
          const SizedBox(height: 12),
          Text(
            "L'évaluation n'a pas abouti",
            style: AppFonts.display(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            submission.erreurMessage ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: submission.retryCount >= 3
                ? 'Plafond de retries atteint'
                : "Réessayer l'évaluation",
            icon: LucideIcons.refreshCw,
            onPressed: submission.retryCount >= 3 ? null : onRetry,
          ),
        ],
      ),
    );
  }
}
