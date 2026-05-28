import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/question_detail_sheet.dart';

/// Carte « question ratée » utilisée par l'onglet Erreurs des hubs TCF QCM.
/// Filet ambre à gauche, chip difficulté + chip type de question, preview du
/// statement (3 lignes), thème en bas. Tap → `reviewQuestion` + bottomsheet.
class WrongQuestionCard extends ConsumerWidget {
  const WrongQuestionCard({super.key, required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(context, ref),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: AppColors.amber),
                              ),
                              const SizedBox(width: 10),
                              QcmDifficultyTag(
                                label: question.difficulty.wire,
                                fg: AppColors.amber,
                                bg: AppColors.amber.withValues(alpha: 0.12),
                              ),
                              const SizedBox(width: 6),
                              QcmDifficultyTag(
                                label: question.questionType.displayLabel,
                                fg: AppColors.blue,
                                bg: AppColors.blueLight,
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.muted2, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.statement,
                            style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w600,
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.bookmarks_outlined,
                                  size: 12, color: AppColors.muted2),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  question.themeName,
                                  style: AppFonts.mono(
                                    size: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detailed = await ref
          .read(userContentRepositoryProvider)
          .reviewQuestion(question.id);
      if (!context.mounted) return;
      showQuestionDetailSheet(context, question: detailed);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}

/// Petit chip « difficulté » / « type de question » utilisé sur les cartes
/// d'erreurs QCM. Distinct du `QuestionMiniTag` mono de
/// `question_detail_sheet.dart` (qui sert dans les sheets de revue d'une
/// question) — celui-ci est en Jakarta 10/800 sur radius pill.
class QcmDifficultyTag extends StatelessWidget {
  const QcmDifficultyTag({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppFonts.jakarta(size: 10, weight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/// Box d'erreur réseau colorée rouge clair — utilisée sur les pages QCM
/// (Examens, Erreurs).
class QcmErrorBox extends StatelessWidget {
  const QcmErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppFonts.jakarta(size: 12, color: AppColors.redDark),
      ),
    );
  }
}
