import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Rapport d\'examen',
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
            // Clé unique pour que Flutter garde l'état d'ouverture par question
            // même quand on change de filtre
            _QuestionAccordion(
              key: ValueKey('q-${aq.id}'),
              attemptQuestion: aq,
            ),
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
// Accordéon par question (le truc principal)
// ---------------------------------------------------------------------------

class _QuestionAccordion extends StatefulWidget {
  const _QuestionAccordion({super.key, required this.attemptQuestion});

  final AttemptQuestion attemptQuestion;

  @override
  State<_QuestionAccordion> createState() => _QuestionAccordionState();
}

class _QuestionAccordionState extends State<_QuestionAccordion> with SingleTickerProviderStateMixin {
  late bool _open;

  @override
  void initState() {
    super.initState();
    // Toujours fermé par défaut : l'utilisateur ouvre uniquement les questions
    // qui l'intéressent.
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final aq = widget.attemptQuestion;
    final q = aq.question;
    final isCorrect = aq.correct == true;
    final isAnswered = aq.answered;
    final isWrong = isAnswered && !isCorrect;

    // Tonalité de couleur globale de l'encart
    final Color accent;
    final Color bg;
    final Color borderColor;
    if (!isAnswered) {
      accent = AppColors.muted;
      bg = AppColors.line2.withValues(alpha: 0.5);
      borderColor = AppColors.line;
    } else if (isCorrect) {
      accent = AppColors.green;
      bg = AppColors.green.withValues(alpha: 0.05);
      borderColor = AppColors.green.withValues(alpha: 0.35);
    } else {
      accent = AppColors.red;
      bg = AppColors.redLight;
      borderColor = AppColors.red.withValues(alpha: 0.35);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: bg,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ──────── Header cliquable ────────
              InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Row(
                    children: [
                      // Pastille numérotée
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
                      // Statut + énoncé tronqué
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  !isAnswered
                                      ? Icons.help_outline
                                      : isCorrect
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                  color: accent,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  !isAnswered
                                      ? 'Non répondu'
                                      : isCorrect
                                          ? 'Correct'
                                          : 'Incorrect',
                                  style: AppFonts.mono(
                                    size: 9,
                                    color: accent,
                                    letterSpacing: 1.2,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              q.statement,
                              maxLines: _open ? 10 : 2,
                              overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
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
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: accent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ──────── Contenu déplié ────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _ExpandedContent(
                  attemptQuestion: aq,
                  accentColor: borderColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenu déplié de l'accordéon : choix + explication
// ---------------------------------------------------------------------------

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.attemptQuestion,
    required this.accentColor,
  });

  final AttemptQuestion attemptQuestion;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final q = attemptQuestion.question;
    final selectedIds = attemptQuestion.selectedChoiceIds;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Séparateur visuel entre header et contenu
          Container(
            height: 1,
            color: accentColor.withValues(alpha: 0.4),
            margin: const EdgeInsets.only(bottom: 14),
          ),

          // Thème + difficulté en petite ligne discrète
          Row(
            children: [
              AppTag(label: q.difficulty.wire, tone: TagTone.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  q.themeName,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.mono(
                    size: 9,
                    color: AppColors.muted2,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Choix avec annotations
          for (final c in q.choices) ...[
            _ChoiceLine(
              label: c.label,
              isCorrect: c.correct,
              isSelected: selectedIds.contains(c.id),
            ),
            const SizedBox(height: 6),
          ],

          // Bloc explication
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.blue, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Explication',
                        style: AppFonts.mono(
                          size: 9,
                          color: AppColors.blue,
                          letterSpacing: 1.5,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation!,
                    style: AppFonts.jakarta(
                      size: 13,
                      color: AppColors.ink2,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne de choix (verte bonne réponse, rouge sélectionné incorrect, neutre sinon)
// ---------------------------------------------------------------------------

class _ChoiceLine extends StatelessWidget {
  const _ChoiceLine({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
  });

  final String label;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.white;
    Color border = AppColors.line;
    Color iconColor = AppColors.muted2;
    IconData icon = Icons.radio_button_unchecked;

    if (isCorrect) {
      bg = AppColors.green.withValues(alpha: 0.1);
      border = AppColors.green.withValues(alpha: 0.5);
      iconColor = AppColors.green;
      icon = Icons.check_circle;
    } else if (isSelected) {
      bg = AppColors.white;
      border = AppColors.red.withValues(alpha: 0.5);
      iconColor = AppColors.red;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppFonts.jakarta(
                size: 13,
                weight: isCorrect || isSelected ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
          ),
          if (isSelected && !isCorrect)
            Text(
              'Votre réponse',
              style: AppFonts.mono(
                size: 9,
                color: AppColors.red,
                letterSpacing: 1.0,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
        ],
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
