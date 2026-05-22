import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/question_detail_sheet.dart';

/// Provider qui charge l'attempt finalisé pour le rapport.
final examReportProvider = FutureProvider.autoDispose.family<Attempt, String>((ref, id) {
  return ref.watch(attemptsRepositoryProvider).getById(id);
});

/// Mode d'affichage du rapport.
enum _ReportFilter { all, errors, correct }

class ExamReportScreen extends ConsumerStatefulWidget {
  const ExamReportScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends ConsumerState<ExamReportScreen> {
  _ReportFilter _filter = _ReportFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examReportProvider(widget.attemptId));

    // Contexte de l'écran lu dans la query string (renseigné par le runner).
    // - `from=civiqueLot&themeId=...` : on vient d'un lot civique → titre
    //   "Bilan du lot" et fallback de la flèche vers le détail thème
    //   (le runner a poussé via `context.go` qui reset la nav stack, donc
    //   `canPop()` renvoie false — il faut un fallback explicite).
    final qp = GoRouterState.of(context).uri.queryParameters;
    final fromCiviqueLot = qp['from'] == 'civiqueLot';
    final themeId = qp['themeId'];
    final title = fromCiviqueLot ? 'Bilan du lot' : 'Rapport d\'examen';

    void onBack() {
      // Prefère un vrai `pop` (préserve la stack en aval — quand on est
      // arrivé via `pushReplacement` depuis le runner, la stack contient
      // toujours le détail thème en dessous, donc pop suffit et le détail
      // thème conserve sa propre stack). Fallback contextuel uniquement
      // si `canPop` est false (cas d'un deep link / hot reload).
      if (context.canPop()) {
        context.pop();
        return;
      }
      if (fromCiviqueLot && themeId != null) {
        context.go(
          AppRoutes.civiqueThemeDetail.replaceFirst(':themeId', themeId),
        );
        return;
      }
      context.go(AppRoutes.home);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: onBack,
        ),
        title: Text(
          title,
          style: AppFonts.jakarta(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(examReportProvider(widget.attemptId)),
          ),
          data: (attempt) => _buildContent(attempt),
        ),
      ),
    );
  }

  Widget _buildContent(Attempt attempt) {
    final all = attempt.questions;
    final errors = all.where((q) => q.correct == false).toList();
    final correct = all.where((q) => q.correct == true).toList();

    final filtered = switch (_filter) {
      _ReportFilter.all => all,
      _ReportFilter.errors => errors,
      _ReportFilter.correct => correct,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _Summary(attempt: attempt),
        const SizedBox(height: 20),
        const Eyebrow('§ Filtrer'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FilterChip(
                label: 'Tout (${all.length})',
                selected: _filter == _ReportFilter.all,
                onTap: () => setState(() => _filter = _ReportFilter.all),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChip(
                label: 'Erreurs (${errors.length})',
                selected: _filter == _ReportFilter.errors,
                color: AppColors.red,
                onTap: () => setState(() => _filter = _ReportFilter.errors),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChip(
                label: 'Justes (${correct.length})',
                selected: _filter == _ReportFilter.correct,
                color: AppColors.green,
                onTap: () => setState(() => _filter = _ReportFilter.correct),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                _filter == _ReportFilter.errors
                    ? 'Aucune erreur sur cet examen 🎉'
                    : 'Aucune question à afficher',
                style: AppFonts.jakarta(
                  color: AppColors.muted,
                  size: 13,
                ),
              ),
            ),
          )
        else
          for (final aq in filtered) ...[
            _QuestionReviewCard(attemptQuestion: aq),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau récap en haut
// ---------------------------------------------------------------------------

class _Summary extends StatelessWidget {
  const _Summary({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final score = attempt.score ?? 0;
    final total = attempt.totalQuestions;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    final passed = attempt.passThreshold != null && score >= attempt.passThreshold!;

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: passed ? AppColors.green.withValues(alpha: 0.06) : AppColors.blueSoft,
      border: Border.all(
        color: passed ? AppColors.green.withValues(alpha: 0.3) : AppColors.blue.withValues(alpha: 0.15),
      ),
      boxShadow: const [],
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: passed ? AppColors.green : AppColors.blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: AppFonts.fraunces(
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/ $total',
                  style: AppFonts.mono(
                    size: 9,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percent % de réussite',
                  style: AppFonts.jakarta(
                    size: 15,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  passed ? 'Examen réussi' : 'Touchez une question pour voir le détail',
                  style: AppFonts.jakarta(
                    size: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.white,
          border: Border.all(
            color: selected ? accent : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.jakarta(
            size: 12,
            weight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.muted,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card review-style par question — tap → ouvre QuestionDetailSheet
// ---------------------------------------------------------------------------

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.attemptQuestion});

  final AttemptQuestion attemptQuestion;

  @override
  Widget build(BuildContext context) {
    final aq = attemptQuestion;
    final q = aq.question;
    final isCorrect = aq.correct == true;
    final isAnswered = aq.answered;

    final Color accent;
    final Color bg;
    final Color borderColor;
    final IconData statusIcon;
    final String statusLabel;
    if (!isAnswered) {
      accent = AppColors.muted;
      bg = AppColors.line2.withValues(alpha: 0.5);
      borderColor = AppColors.line;
      statusIcon = Icons.help_outline;
      statusLabel = 'Non répondu';
    } else if (isCorrect) {
      accent = AppColors.green;
      bg = AppColors.green.withValues(alpha: 0.05);
      borderColor = AppColors.green.withValues(alpha: 0.35);
      statusIcon = Icons.check_circle;
      statusLabel = 'Correct';
    } else {
      accent = AppColors.red;
      bg = AppColors.redLight;
      borderColor = AppColors.red.withValues(alpha: 0.35);
      statusIcon = Icons.cancel;
      statusLabel = 'Incorrect';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: () => showQuestionDetailSheet(
            context,
            question: q,
            // La sélection vient de l'AttemptQuestion (review déjà chargée).
            userSelectedChoiceIdsOverride: aq.selectedChoiceIds,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${aq.position + 1}',
                    style: AppFonts.jakarta(
                      size: 12,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: accent, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: AppFonts.mono(
                              size: 9,
                              color: accent,
                              letterSpacing: 1.2,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          if (q.hasAudio)
                            Icon(
                              Icons.headphones,
                              size: 12,
                              color: accent.withValues(alpha: 0.7),
                            )
                          else if (q.passageText != null &&
                              q.passageText!.isNotEmpty)
                            Icon(
                              Icons.menu_book_rounded,
                              size: 12,
                              color: accent.withValues(alpha: 0.7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.statement,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
