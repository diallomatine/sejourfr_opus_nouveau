import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/word_count.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'diagnostic_rapport_labels.dart';
import 'diagnostic_rapport_screen.dart';
import 'widgets/diagnostic_common.dart';

/// La production écrite d'un diagnostic, lue par son identifiant
/// (`GET /api/production-submissions/{id}`, le client existant).
final _diagnosticSubmissionProvider = FutureProvider.autoDispose
    .family<ProductionSubmissionDto, String>((ref, submissionId) {
  return ref.read(productionRepositoryProvider).getSubmission(submissionId);
});

/// **« Revoir ma réponse »** du rapport du diagnostic rapide (2026-10-04) :
/// le sujet (consigne servie, mise en forme par `diagnosticConsigneBlocks`)
/// et le texte rendu, retours à la ligne conservés. Lecture seule.
/// Miroir web : `/diagnostic/rapport/[sessionId]/reponse`.
class DiagnosticReponseScreen extends ConsumerWidget {
  const DiagnosticReponseScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(diagnosticSessionProvider(sessionId));
    final written = session.valueOrNull?.written;
    final submissionId = written?.submissionId;
    final submission = submissionId == null
        ? null
        : ref.watch(_diagnosticSubmissionProvider(submissionId));
    void retour() => retourOuRepli(
          context,
          repli: AppRoutes.diagnosticRapportPath(sessionId),
        );
    void reessayer() {
      ref.invalidate(diagnosticSessionProvider(sessionId));
      if (submissionId != null) {
        ref.invalidate(_diagnosticSubmissionProvider(submissionId));
      }
    }

    final Widget body;
    if (session.isLoading || (submission?.isLoading ?? false)) {
      body = DiagnosticLoadState(isLoading: true, onRetry: reessayer);
    } else if (written == null ||
        submission == null ||
        submission.hasError ||
        submission.valueOrNull?.texteSoumis == null) {
      body = DiagnosticLoadState(
        isLoading: false,
        errorMessage: kDiagnosticAnswerUnavailable,
        onRetry: reessayer,
      );
    } else {
      final texte = submission.value!.texteSoumis!;
      body = ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 32),
        children: [
          SfSection(
            child: SfStack(
              children: [
                SfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SfPanelHead(title: kDiagnosticAnswerSubject),
                      const SizedBox(height: 12),
                      DiagnosticConsigne(text: written.instruction),
                    ],
                  ),
                ),
                SfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SfPanelHead(title: kDiagnosticAnswerText),
                      const SizedBox(height: 12),
                      SfInsight(texte),
                      const SizedBox(height: 12),
                      SfTiny(diagnosticWordCountLabel(compterMots(texte))),
                    ],
                  ),
                ),
                SfTextLink(label: kDiagnosticBackToReport, onTap: retour),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: kDiagnosticAnswerTitle,
              sub: kDiagnosticAnswerKicker,
              onBack: retour,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
