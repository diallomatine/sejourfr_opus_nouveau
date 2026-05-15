import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/core/router/app_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/question_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/rich_paragraph_text.dart';
import 'runner_controller.dart';
import 'widgets/choice_tile.dart';
import 'widgets/exam_timer.dart';
import 'widgets/explanation_box.dart';
import 'widgets/question_media_view.dart';

const _kCheckoutUrl = 'https://sejourfr.fr/paiement';

class RunnerScreen extends ConsumerWidget {
  const RunnerScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runnerControllerProvider(attemptId));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    color: AppColors.red, size: 40),
                const SizedBox(height: 12),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: AppFonts.jakarta(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Réessayer',
                  variant: AppButtonVariant.secondary,
                  fullWidth: false,
                  onPressed: () => ref
                      .read(runnerControllerProvider(attemptId).notifier)
                      .retry(),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (s) => _RunnerView(state: s, attemptId: attemptId),
    );
  }
}

class _RunnerView extends ConsumerWidget {
  const _RunnerView({required this.state, required this.attemptId});

  final RunnerState state;
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.current.question;
    final isExam = state.activeAttempt.isMockExam;
    final isTraining = state.activeAttempt.type == AttemptType.training;
    final selected = state.answersByQuestion[state.current.id] ?? const [];

    final isFavorite =
        state.favoriteQuestionIds.contains(state.current.question.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => _confirmQuit(context, ref),
        ),
        title: _ProgressHeader(state: state),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: Icon(
              isFavorite ? Icons.bookmark_rounded : Icons.bookmark_outline,
              size: 22,
              color: isFavorite ? AppColors.red : AppColors.ink,
            ),
            onPressed: () => ref
                .read(runnerControllerProvider(attemptId).notifier)
                .toggleFavoriteCurrent(),
          ),
          if (isExam && state.activeAttempt.timeLimitSeconds != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: ExamTimer(
                  durationSeconds: state.activeAttempt.timeLimitSeconds!,
                  startedAt: state.activeAttempt.startedAt,
                  onElapsed: () => _autoFinish(context, ref),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(state: state),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _QuestionHeader(question: question),
                  const SizedBox(height: 14),
                  if (question.hasMedia)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: QuestionMediaView(media: question.media!),
                    ),
                  if (question.passageText != null) ...[
                    _PassageBlock(text: question.passageText!),
                    const SizedBox(height: 16),
                  ],
                  _StatementBlock(text: question.statement),
                  const SizedBox(height: 20),
                  ...List.generate(question.choices.length, (i) {
                    final c = question.choices[i];
                    final isSelected = selected.contains(c.id);
                    final showCorr = state.hasResult && isTraining;
                    final isCorrect =
                        state.lastResult?.correctChoiceIds.contains(c.id);
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i == question.choices.length - 1 ? 0 : 10),
                      child: ChoiceTile(
                        choice: c,
                        index: i,
                        selected: isSelected,
                        showCorrection: showCorr,
                        isCorrect: isCorrect,
                        onTap: () => ref
                            .read(runnerControllerProvider(attemptId).notifier)
                            .toggleChoice(c.id),
                      ),
                    );
                  }),
                  if (state.hasResult && isTraining) ...[
                    const SizedBox(height: 20),
                    ExplanationBox(
                      correct: state.lastResult!.correct,
                      explanation:
                          state.lastResult!.explanation ?? question.explanation,
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redLight,
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: AppFonts.jakarta(color: AppColors.red, size: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _BottomBar(state: state, attemptId: attemptId),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context, WidgetRef ref) async {
    final isTraining = state.activeAttempt.type == AttemptType.training;
    final isInfinite = state.isInfiniteTraining;
    final title = isInfinite ? 'Terminer la session ?' : 'Quitter cette session ?';
    final message = isInfinite
        ? 'Vos réponses ont été enregistrées. Vous pourrez consulter cette session dans votre historique.'
        : 'Votre progression dans cette session sera conservée. Vous pourrez la reprendre plus tard.';
    final confirmLabel = isInfinite ? 'Terminer' : 'Quitter';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: AppFonts.fraunces(size: 20, weight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: AppFonts.jakarta(size: 13.5, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: AppFonts.jakarta(
                color: AppColors.red,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != true) return;
    if (!context.mounted) return;

    // En entraînement infini, on finalise le batch courant pour que les
    // réponses comptent dans les stats. En examen ou training non-infini,
    // on quitte sans finaliser (resume possible).
    if (isTraining && isInfinite) {
      await ref.read(runnerControllerProvider(attemptId).notifier).finish();
    }
    if (!context.mounted) return;
    GoRouter.of(context).pop();
  }

  Future<void> _autoFinish(BuildContext context, WidgetRef ref) async {
    final attempt =
        await ref.read(runnerControllerProvider(attemptId).notifier).finish();
    if (attempt != null && context.mounted) {
      _navigateToResult(context, ref, attempt);
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final RunnerState state;

  @override
  Widget build(BuildContext context) {
    final isInfinite = state.isInfiniteTraining;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Eyebrow(state.activeAttempt.isMockExam ? 'Examen blanc' : 'Entraînement'),
        const SizedBox(height: 2),
        Text(
          isInfinite
              ? 'Question ${state.currentIndex + 1}'
              : 'Question ${state.currentIndex + 1} / ${state.activeAttempt.totalQuestions}',
          style: AppFonts.jakarta(
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});

  final RunnerState state;

  @override
  Widget build(BuildContext context) {
    // Pas de barre déterminée en entraînement infini (pas de total).
    if (state.isInfiniteTraining) {
      return Container(
        height: 3,
        color: AppColors.line2,
        alignment: Alignment.centerLeft,
        child: state.extending
            ? const LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.line2,
                valueColor: AlwaysStoppedAnimation(AppColors.blue),
              )
            : null,
      );
    }
    final value =
        (state.currentIndex + 1) / state.activeAttempt.totalQuestions;
    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      backgroundColor: AppColors.line2,
      valueColor: const AlwaysStoppedAnimation(AppColors.blue),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTag(label: question.difficulty.wire, tone: TagTone.red),
        const SizedBox(width: 6),
        AppTag(
          label: question.questionType.displayLabel,
          tone: TagTone.blue,
        ),
        const Spacer(),
        Flexible(
          child: Text(
            question.themeName,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _PassageBlock extends StatelessWidget {
  const _PassageBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: AppColors.blueSoft,
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 14, color: AppColors.blue),
              const SizedBox(width: 6),
              Text(
                'Document à lire',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blue,
                  letterSpacing: 1.8,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichParagraphText(
            text,
            size: 14,
            color: AppColors.ink2,
            weight: FontWeight.w500,
            height: 1.6,
            paragraphSpacing: 12,
          ),
        ],
      ),
    );
  }
}

class _StatementBlock extends StatelessWidget {
  const _StatementBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .replaceAll('\r\n', '\n')
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.length <= 1) {
      return Text(
        text.trim(),
        style: AppFonts.fraunces(
          size: 19,
          weight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          Text(
            paragraphs[i].trim(),
            style: AppFonts.fraunces(
              size: 19,
              weight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (i != paragraphs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state, required this.attemptId});

  final RunnerState state;
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(runnerControllerProvider(attemptId).notifier);
    final selected = state.answersByQuestion[state.current.id] ?? const [];
    final hasSelection = selected.isNotEmpty;
    final isTraining = state.activeAttempt.type == AttemptType.training;
    final isInfinite = state.isInfiniteTraining;
    final showValidate = isTraining && !state.hasResult;
    final isLast = state.isLast;
    final waiting = state.submitting || state.extending;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          // En entraînement infini : pas de "Précédent" (session orientée
          // avancement). En examen ou training borné, on garde l'option.
          if (!isInfinite && state.currentIndex > 0) ...[
            Expanded(
              child: AppButton(
                label: 'Précédent',
                variant: AppButtonVariant.ghost,
                onPressed: waiting ? null : ctrl.goPrevious,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: (!isInfinite && state.currentIndex > 0) ? 2 : 1,
            child: showValidate
                ? AppButton(
                    label: 'Valider',
                    variant: AppButtonVariant.primary,
                    onPressed: (!hasSelection || waiting)
                        ? null
                        : ctrl.submitCurrent,
                    isLoading: state.submitting,
                  )
                : isLast
                    ? AppButton(
                        label: isInfinite
                            ? 'Terminer la session'
                            : 'Terminer',
                        variant: AppButtonVariant.danger,
                        onPressed: waiting
                            ? null
                            : () async {
                                final attempt = await ctrl.finish();
                                if (attempt != null && context.mounted) {
                                  _navigateToResult(context, ref, attempt);
                                }
                              },
                        isLoading: state.submitting,
                      )
                    : AppButton(
                        label: 'Suivant',
                        variant: AppButtonVariant.primary,
                        onPressed: ((!hasSelection && isTraining) || waiting)
                            ? null
                            : () async {
                                if (!isTraining && hasSelection) {
                                  await ctrl.submitCurrent();
                                }
                                await ctrl.goNext();
                              },
                        isLoading: state.extending,
                      ),
          ),
        ],
      ),
    );
  }
}

void _navigateToResult(BuildContext context, WidgetRef ref, Attempt attempt) {
  if (attempt.isMockExam) {
    context.go(
      AppRoutes.examResult.replaceFirst(':attemptId', attempt.id),
    );
  } else {
    final auth = ref.read(authControllerProvider);
    final isPremium = auth is AuthAuthenticated && auth.user.isPremium;
    _showTrainingResultDialog(context, attempt, isPremium: isPremium);
  }
}

void _showTrainingResultDialog(
  BuildContext context,
  Attempt attempt, {
  required bool isPremium,
}) {
  final total = attempt.totalQuestions;
  final score = attempt.score ?? 0;
  final percent = total == 0 ? 0 : ((score / total) * 100).round();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPremium ? AppColors.blueLight : AppColors.amber
                    .withValues(alpha: 0.16),
              ),
              child: Icon(
                isPremium
                    ? Icons.check_circle
                    : Icons.workspace_premium_rounded,
                size: 36,
                color: isPremium ? AppColors.blue : AppColors.amber,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPremium ? 'Session terminée' : 'Démo terminée',
              style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '$score / $total bonnes réponses · $percent %',
              style: AppFonts.jakarta(
                size: 14,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isPremium) ...[
              const SizedBox(height: 14),
              Text(
                'Pour continuer en illimité et accéder à tous les thèmes, abonnez-vous sur le web.',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'M’abonner sur sejourfr.fr',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: _kCheckoutUrl),
                  );
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.ink,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Lien copié : $_kCheckoutUrl',
                        style: AppFonts.jakarta(
                          color: AppColors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  GoRouter.of(context).pop();
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  GoRouter.of(context).pop();
                },
                child: Text(
                  'Plus tard',
                  style: AppFonts.jakarta(
                    size: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Retour à l\'accueil',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  GoRouter.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
