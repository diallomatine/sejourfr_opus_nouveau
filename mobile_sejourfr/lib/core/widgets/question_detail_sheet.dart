import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_config.dart';
import '../models/question_models.dart';
import '../theme/app_theme.dart';
import 'audio_player.dart';
import '../../screens/question_runner/widgets/question_media_view.dart';

/// Bottomsheet de détail d'une question : chips niveau/type, audio rejouable
/// (CO), passage (CE), statement, choices avec marquage correct vert /
/// selectedWrong rouge, explication en bas.
///
/// Utilisé par :
///   - l'onglet Erreurs du détail TCF QCM (`TcfQcmDetailScreen`)
///   - le rapport d'examen (`ExamReportScreen`)
///
/// Le caller fournit la `QuestionDto` déjà résolue (avec correct flags sur
/// les choices). Pour le marquage rouge, soit `question.userSelectedChoiceIds`
/// est rempli (cas review), soit `userSelectedChoiceIdsOverride` est passé
/// (cas rapport où la sélection vient de `AttemptQuestion.selectedChoiceIds`).
class QuestionDetailSheet extends StatelessWidget {
  const QuestionDetailSheet({
    super.key,
    required this.question,
    this.userSelectedChoiceIdsOverride,
  });

  final QuestionDto question;
  final List<String>? userSelectedChoiceIdsOverride;

  List<String> get _selected =>
      userSelectedChoiceIdsOverride ?? question.userSelectedChoiceIds;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Text(
              'DÉTAIL · ${question.module.wire}',
              style: AppFonts.mono(
                size: 9,
                color: AppColors.muted,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              children: [
                Row(
                  children: [
                    QuestionMiniTag(
                      label: question.difficulty.wire,
                      fg: AppColors.red,
                      bg: AppColors.redLight,
                    ),
                    const SizedBox(width: 6),
                    QuestionMiniTag(
                      label: question.questionType.displayLabel,
                      fg: AppColors.blue,
                      bg: AppColors.blueLight,
                    ),
                  ],
                ),
                if (question.hasAudio) ...[
                  const SizedBox(height: 14),
                  // En révision (rapport / erreurs), pas de maxPlays : l'utilisateur
                  // peut réécouter autant qu'il veut pour comprendre son erreur.
                  SejourAudioPlayer(
                    url: ApiConfig.resolveMediaUrl(question.media!.url),
                  ),
                ],
                // CO_IMAGE : l'image vit dans media, l'audio des propositions
                // dans audioMedia. On rend les deux en révision pour que le
                // contexte de l'erreur soit complet.
                if (question.hasImage) ...[
                  const SizedBox(height: 14),
                  QuestionMediaView(media: question.media!),
                ],
                if (question.audioMedia != null) ...[
                  const SizedBox(height: 14),
                  SejourAudioPlayer(
                    url: ApiConfig.resolveMediaUrl(question.audioMedia!.url),
                  ),
                ],
                if (question.passageText != null &&
                    question.passageText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  QuestionPassageBlock(text: question.passageText!),
                ],
                const SizedBox(height: 14),
                Text(
                  question.statement,
                  style: AppFonts.ui(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final choice in orderedDisplayChoices(question))
                  QuestionChoiceRow(
                    label: choice.label,
                    correct: choice.correct,
                    selectedWrong:
                        !choice.correct && _selected.contains(choice.id),
                  ),
                if (question.explanation != null &&
                    question.explanation!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.blue.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPLICATION',
                          style: AppFonts.mono(
                            size: 9.5,
                            color: AppColors.blue,
                            letterSpacing: 1.8,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation!,
                          style: AppFonts.ui(
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
          ),
        ],
      ),
    );
  }
}

/// Helper : ouvre le sheet via `showModalBottomSheet` avec la config standard.
void showQuestionDetailSheet(
  BuildContext context, {
  required QuestionDto question,
  List<String>? userSelectedChoiceIdsOverride,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => QuestionDetailSheet(
      question: question,
      userSelectedChoiceIdsOverride: userSelectedChoiceIdsOverride,
    ),
  );
}

/// Petit tag mono utilisé en tête du sheet (niveau, type, etc.).
class QuestionMiniTag extends StatelessWidget {
  const QuestionMiniTag({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppFonts.mono(
          size: 9.5,
          color: fg,
          letterSpacing: 1.2,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Encadré crème affichant le passage texte d'une question CE.
class QuestionPassageBlock extends StatelessWidget {
  const QuestionPassageBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.bookOpen,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                'PASSAGE',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.ui(
              size: 13.5,
              color: AppColors.ink2,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'un choix dans le sheet : vert si correct, rouge si selectedWrong,
/// neutre sinon. Garde label "Ton choix" pour la sélection incorrecte.
class QuestionChoiceRow extends StatelessWidget {
  const QuestionChoiceRow({
    super.key,
    required this.label,
    required this.correct,
    this.selectedWrong = false,
  });

  final String label;
  final bool correct;
  final bool selectedWrong;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final IconData icon;
    final Color iconBg;
    final Color iconFg;
    final FontWeight labelWeight;
    final Color labelColor;
    final double borderWidth;

    if (correct) {
      bg = AppColors.green.withValues(alpha: 0.08);
      border = AppColors.green;
      borderWidth = 1.5;
      icon = LucideIcons.check;
      iconBg = AppColors.green;
      iconFg = AppColors.white;
      labelWeight = FontWeight.w700;
      labelColor = AppColors.ink;
    } else if (selectedWrong) {
      bg = AppColors.red.withValues(alpha: 0.08);
      border = AppColors.red;
      borderWidth = 1.5;
      icon = LucideIcons.x;
      iconBg = AppColors.red;
      iconFg = AppColors.white;
      labelWeight = FontWeight.w600;
      labelColor = AppColors.ink2;
    } else {
      bg = AppColors.white;
      border = AppColors.line;
      borderWidth = 1;
      icon = LucideIcons.circle;
      iconBg = AppColors.line2;
      iconFg = AppColors.muted2;
      labelWeight = FontWeight.w500;
      labelColor = AppColors.ink2;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            child: Icon(icon, size: 14, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(
                size: 14,
                weight: labelWeight,
                color: labelColor,
                height: 1.4,
              ),
            ),
          ),
          if (selectedWrong) ...[
            const SizedBox(width: 8),
            Text(
              'Ton choix',
              style: AppFonts.mono(
                size: 9,
                color: AppColors.red,
                letterSpacing: 1.4,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
