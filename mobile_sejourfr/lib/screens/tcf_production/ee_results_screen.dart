import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'ee_session_controller.dart';
import 'widgets/correction_example.dart';
import 'widgets/criterion_row.dart';
import 'widgets/donut_chart_score.dart';
import 'widgets/evaluation_loading_view.dart';
import 'widgets/feedback_block.dart';
import 'widgets/production_app_header.dart';
import 'widgets/results_eval_banner.dart';

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

  /// True quand on consulte les resultats depuis l'historique : on cache les
  /// CTAs "Passer a la tache N+1" / "Voir mon bilan" au profit d'un simple "Retour".
  final bool isHistory;

  @override
  ConsumerState<EeResultsScreen> createState() => _EeResultsScreenState();
}

class _EeResultsScreenState extends ConsumerState<EeResultsScreen> {
  Timer? _poll;

  /// Stop polling après cette durée — protège contre une éval IA bloquée.
  static const Duration _pollMaxDuration = Duration(seconds: 90);
  late final DateTime _pollStartedAt;

  @override
  void initState() {
    super.initState();
    _pollStartedAt = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Stop si statut final atteint ou timeout.
      final value = ref.read(_submissionFetcher(widget.submissionId)).valueOrNull;
      if (value != null && value.statut.isFinal) {
        timer.cancel();
        return;
      }
      if (DateTime.now().difference(_pollStartedAt) > _pollMaxDuration) {
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
    final session = widget.isHistory ? null : ref.watch(eeSessionProvider).value;
    final async = ref.watch(_submissionFetcher(widget.submissionId));

    // Lecture des query params depuis le State du screen — `GoRouterState.of`
    // est garanti accessible ici car ce widget est directement le builder
    // d'une GoRoute. On les passe en paramètres aux sous-widgets pour ne pas
    // ré-appeler `GoRouterState.of` dans des sous-arbres qui peuvent être
    // rebuilds hors du contexte route (cf. crash "no GoRouterState above").
    final qp = GoRouterState.of(context).uri.queryParameters;
    final fullExamId = qp['fullExamId'];

    return _Wrapper(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              ApiClient.toApiException(e).message,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted),
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
          );
        },
      ),
    );
  }
}

class _Wrapper extends StatelessWidget {
  const _Wrapper({required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: 'Resultats',
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

  bool get _hasNext =>
      !isHistory && session != null && taskIndex + 1 < session!.totalTasks;

  /// Mode entrainement libre (single-task depuis le hub). Voir EoResultsScreen.
  bool get _isSingleTask =>
      !isHistory && session != null && session!.totalTasks == 1;

  /// Route de la prochaine tâche en propageant les query params (notamment
  /// `fullExamId` + `subAttemptId` quand on est dans un examen blanc complet).
  /// Construit ici à partir du snapshot reçu, sans appeler `GoRouterState.of`
  /// (qui peut planter sous un sous-arbre re-buildé hors contexte route).
  String _nextTaskRoute(int nextIndex) {
    final base = '/tcf/expression-ecrite/t/$nextIndex';
    if (queryParameters.isEmpty) return base;
    final qs = queryParameters.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$base?$qs';
  }

  String get _bilanCtaLabel =>
      fullExamId != null ? 'Continuer l\'examen blanc' : 'Voir mon bilan';

  void _navigateToBilan(BuildContext context, WidgetRef ref) {
    if (fullExamId != null) {
      ref.read(eeSessionProvider.notifier).reset();
      ref.invalidate(fullTcfExamProvider(fullExamId!));
      context.go('/tcf/examen-blanc/$fullExamId');
      return;
    }
    context.pushReplacement('/tcf/expression-ecrite/bilan');
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
              const ResultsEvalBanner(
                title: 'Evaluation terminee !',
                subtitle: 'Voici votre correction detaillee.',
              ),
              DonutChartScore(
                noteSur20: eval.noteSurVingt?.toDouble(),
                niveau: eval.niveauCecrl,
              ),
              if (eval.feedback.scoresCriteres.isNotEmpty)
                _CriteresCard(criteres: eval.feedback.scoresCriteres),
              if (eval.feedback.pointsForts.isNotEmpty)
                FeedbackBlock(
                  kind: FeedbackKind.positive,
                  title: 'Points forts',
                  items: eval.feedback.pointsForts,
                ),
              if (eval.feedback.pointsAAmeliorer.isNotEmpty)
                FeedbackBlock(
                  kind: FeedbackKind.improve,
                  title: 'A ameliorer',
                  items: eval.feedback.pointsAAmeliorer,
                ),
              if (eval.feedback.exemplesCorriges.isNotEmpty)
                _CorrectionsCard(examples: eval.feedback.exemplesCorriges),
              if (eval.feedback.suggestions.isNotEmpty)
                FeedbackBlock(
                  kind: FeedbackKind.suggest,
                  title: 'Suggestion globale',
                  items: eval.feedback.suggestions,
                ),
              if (submission.texteSoumis != null) ...[
                const SizedBox(height: 4),
                _SectionTitle('Votre redaction'),
                const SizedBox(height: 8),
                _SubmittedTextCard(text: submission.texteSoumis!),
              ],
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
                    icon: Icons.arrow_back_rounded,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : _hasNext
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.pushReplacement(
                                '/tcf/expression-ecrite/progression',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                side: const BorderSide(color: AppColors.line),
                                foregroundColor: AppColors.ink,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Voir les taches',
                                style: AppFonts.jakarta(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Passer a la tache ${taskIndex + 2}',
                              onPressed: () => context.pushReplacement(
                                _nextTaskRoute(taskIndex + 1),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _isSingleTask
                        ? AppButton(
                            label: 'Retour aux sujets',
                            icon: Icons.grid_view_rounded,
                            onPressed: () {
                              // Retour à la liste des sujets de la tâche
                              // qu'on vient de faire (TcfProductionTaskSubjectsScreen),
                              // pas l'ancien ProductionHubScreen à
                              // `/tcf/expression-ecrite` ni le détail global.
                              final tacheNumero = submission.tacheNumero ??
                                  session?.taskAt(taskIndex)?.tacheNumero ??
                                  1;
                              ref.read(eeSessionProvider.notifier).reset();
                              context.go(
                                AppRoutes.tcfEeTaskSubjects
                                    .replaceFirst(':tacheNumero', '$tacheNumero'),
                              );
                            },
                          )
                        : AppButton(
                            label: _bilanCtaLabel,
                            icon: Icons.bar_chart_rounded,
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

/// Carte "Detail par criteres" (results-summary-card avec wrapping).
class _CriteresCard extends StatelessWidget {
  const _CriteresCard({required this.criteres});
  final List<CriterionScore> criteres;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail par criteres',
            style: AppFonts.jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...criteres.map((c) => CriterionRow(criterion: c)),
        ],
      ),
    );
  }
}

class _CorrectionsCard extends StatelessWidget {
  const _CorrectionsCard({required this.examples});
  final List<CorrectionExample> examples;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(
                'Exemples et corrections',
                style: AppFonts.jakarta(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...examples.map((e) => CorrectionExampleCard(example: e)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.jakarta(
        size: 15,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _SubmittedTextCard extends StatelessWidget {
  const _SubmittedTextCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: AppFonts.jakarta(
          size: 13.5,
          color: AppColors.ink,
          height: 1.55,
        ),
      ),
    );
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
          const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.red),
          const SizedBox(height: 12),
          Text(
            "L'evaluation n'a pas abouti",
            style: AppFonts.fraunces(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            submission.erreurMessage ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: submission.retryCount >= 3
                ? 'Plafond de retries atteint'
                : "Reessayer l'evaluation",
            icon: Icons.refresh_rounded,
            onPressed: submission.retryCount >= 3 ? null : onRetry,
          ),
        ],
      ),
    );
  }
}
