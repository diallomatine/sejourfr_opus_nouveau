import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/attempt_summary.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tcf_production/widgets/exam_slot/exam_slot_card.dart';

/// Builder utilitaire pour les slots d'examens civique d'un thème. Extrait
/// de `CiviqueThemeExamsScreen` pour rester sous la limite de 400 lignes.
/// Pendant du builder inline de `TcfQcmExamsScreen._buildSlot`.
class CiviqueExamSlotBuilder {
  const CiviqueExamSlotBuilder({
    required this.number,
    required this.attempt,
    required this.isLocked,
    required this.isNext,
    required this.examTotalQuestions,
    required this.onTap,
    required this.onAction,
  });

  final int number;
  final AttemptSummary? attempt;
  final bool isLocked;
  final bool isNext;
  final int examTotalQuestions;
  final VoidCallback onTap;
  final VoidCallback onAction;

  bool get _done => attempt != null;

  Widget build() {
    final score = attempt?.score;
    final total = attempt?.totalQuestions ?? examTotalQuestions;

    Widget? secondaryStatus;
    if (_done && score != null) {
      secondaryStatus = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.circleCheck,
              size: 13, color: AppColors.green),
          const SizedBox(width: 3),
          Text(
            '$score/$total',
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      );
    } else if (!_done && isNext && !isLocked) {
      secondaryStatus = Text(
        'À FAIRE ENSUITE',
        style: AppFonts.mono(
          size: 9,
          color: AppColors.blue,
          letterSpacing: 1.2,
          weight: FontWeight.w700,
        ),
      );
    }

    return ExamSlotCard(
      slot: number,
      done: _done,
      isNext: isNext,
      isLocked: isLocked,
      badgeBaseBg: AppColors.blueLight,
      badgeBaseFg: AppColors.blue,
      title: 'Examen n°$number',
      primaryPill: const ExamSlotPill(
        label: '20 questions · 20 min',
        bg: AppColors.blueLight,
        fg: AppColors.blueDark,
      ),
      secondaryStatus: secondaryStatus,
      onTap: onTap,
      onAction: onAction,
    );
  }
}
