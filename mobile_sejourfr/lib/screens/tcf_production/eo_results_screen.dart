import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'eo_session_controller.dart';
import 'widgets/avertissements_card.dart';
import 'widgets/correction_example.dart';
import 'widgets/criterion_row.dart';
import 'widgets/donut_chart_score.dart';
import 'widgets/evaluation_loading_view.dart';
import 'widgets/feedback_block.dart';
import 'widgets/production_app_header.dart';
import 'widgets/results_eval_banner.dart';
import 'widgets/transcription_section.dart';

final _eoSubmissionFetcher = FutureProvider.autoDispose
    .family<ProductionSubmissionDto, String>((ref, id) {
  return ref.watch(productionRepositoryProvider).getSubmission(id);
});

/// Écran résultats EO : poll la submission tant que le pipeline async backend
/// (Whisper + Claude) n'a pas produit EVALUATED ou FAILED. Affiche
/// `EvaluationLoadingView(includeTranscription: true)` pendant l'attente.
class EoResultsScreen extends ConsumerStatefulWidget {
  const EoResultsScreen({
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
  ConsumerState<EoResultsScreen> createState() => _EoResultsScreenState();
}

class _EoResultsScreenState extends ConsumerState<EoResultsScreen> {
  Timer? _poll;
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
      final value =
          ref.read(_eoSubmissionFetcher(widget.submissionId)).valueOrNull;
      if (value != null && value.statut.isFinal) {
        timer.cancel();
        return;
      }
      if (DateTime.now().difference(_pollStartedAt) > _pollMaxDuration) {
        timer.cancel();
        return;
      }
      ref.invalidate(_eoSubmissionFetcher(widget.submissionId));
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
        widget.isHistory ? null : ref.watch(eoSessionProvider).value;
    final async = ref.watch(_eoSubmissionFetcher(widget.submissionId));

    // Lecture des query params au niveau du screen (accès garanti au
    // GoRouterState) puis propagation aux sous-widgets — voir
    // ee_results_screen.dart pour le motif (crash "no GoRouterState above").
    final qp = GoRouterState.of(context).uri.queryParameters;
    final fullExamId = qp['fullExamId'];

    final fallbackRoute =
        fullExamId != null ? '/tcf/examen-blanc/$fullExamId' : '/tcf/eo';
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
            return const Center(
              child: EvaluationLoadingView(includeTranscription: true),
            );
          }
          return _Body(
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
  const _Wrapper({required this.body, this.fallbackRoute = '/tcf'});

  final Widget body;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: 'Resultats',
        fallbackRoute: fallbackRoute,
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: body,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.submission,
    required this.taskIndex,
    required this.session,
    required this.isHistory,
    required this.fullExamId,
    required this.queryParameters,
  });

  final ProductionSubmissionDto submission;
  final int taskIndex;
  final EoSessionState? session;
  final bool isHistory;

  /// Reçu du screen parent (qui a accès garanti à GoRouterState).
  final String? fullExamId;
  final Map<String, String> queryParameters;

  /// Mode entrainement libre (single-task depuis le hub). Le bilan de session
  /// n'a pas de sens : on propose juste un retour au hub des taches.
  bool get _isSingleTask =>
      !isHistory && session != null && session!.totalTasks == 1;

  String get _bilanCtaLabel =>
      fullExamId != null ? 'Continuer l\'examen blanc' : 'Voir mon bilan';

  void _navigateToBilan(BuildContext context, WidgetRef ref) {
    if (fullExamId != null) {
      ref.read(eoSessionProvider.notifier).reset();
      ref.invalidate(fullTcfExamProvider(fullExamId!));
      context.go('/tcf/examen-blanc/$fullExamId');

      return;
    }
    // Hors examen blanc complet : ce CTA n'est plus atteignable en mode
    // session 3-tâches (cf. `eo_finished_screen` qui push directement le
    // bilan détaillé après T3). Reste joignable uniquement comme CTA
    // "Continuer l'examen blanc" en mode fullExam ci-dessus.
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
                subtitle: 'Voici votre evaluation detaillee.',
              ),
              DonutChartScore(
                noteSur20: eval.noteSurVingt?.toDouble(),
              ),
              AvertissementsCard(
                avertissements: eval.feedback.avertissements,
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
              if (submission.transcription != null &&
                  submission.transcription!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Transcription de votre enregistrement',
                  style: AppFonts.ui(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TranscriptionSection(transcription: submission.transcription!),
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
                          // Retour à l'écran d'entraînement Expression orale
                          // (onglet Entraînement, carrousel de situations).
                          ref.read(eoSessionProvider.notifier).reset();
                          context.go(AppRoutes.tcfEoDetail);
                        },
                      )
                    : AppButton(
                        // Atteint uniquement en mode examen blanc complet
                        // après la 3ème tâche (cf. `_navigateToBilan` qui
                        // détecte `fullExamId` et retourne au progress).
                        // En session 3-tâches autonome, on n'arrive plus
                        // jamais sur ce screen — le bilan détaillé est
                        // poussé directement par `eo_finished_screen`.
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
      ref.invalidate(_eoSubmissionFetcher(submission.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.toApiException(e).message)),
      );
    }
  }
}

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
            style: AppFonts.ui(
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
              const Icon(LucideIcons.lightbulb,
                  size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(
                'Exemples et corrections',
                style: AppFonts.ui(
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
            "L'evaluation n'a pas abouti",
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
                : "Reessayer l'evaluation",
            icon: LucideIcons.refreshCw,
            onPressed: submission.retryCount >= 3 ? null : onRetry,
          ),
        ],
      ),
    );
  }
}
