import '../diagnostic_controller.dart' show DiagnosticSyncStage;
import 'diagnostic_wait.dart';

/// Textes des écrans d'attente du diagnostic TCF : envoi des productions faites
/// en invité, analyse en cours, échec de l'envoi ou de l'analyse — déclarés une
/// fois. Miroir mot pour mot de
/// `web_sejoufr/app/_components/diagnostic/analysis-labels.ts`.
///
/// 🛑 **La forme du diagnostic est LUE, jamais supposée** (correctif du
/// 2026-09-26). Le diagnostic rapide (`QUICK_TCF`) ne comporte qu'une
/// production écrite ; l'écran d'attente annonçait pourtant « vos deux
/// productions » et un « Oral reçu » qui n'existait pas. Chaque texte prend
/// `hasOral`, lu sur la session servie (`journey.oral`) ou sur la production
/// locale (`DiagnosticDraft.oralRequired`).
///
/// 🛑 Aucune promesse non vérifiée. « Moins de deux minutes » est mesuré : sur
/// la base locale au 2026-09-26, aucune analyse terminée sans relance n'a
/// dépassé 23 s (20 sessions). Au-delà de deux minutes, l'écran cesse de
/// l'annoncer.

/* ------------------------------------------------------ analyse en cours */

const kDiagnosticAnalysisKicker = 'Diagnostic rapide · analyse IA';

/// « Analyse de votre texte en cours » — le mot en emphase est le sujet.
({String lead, String em, String tail}) diagnosticAnalysisTitle(
  bool hasOral,
) =>
    hasOral
        ? (lead: 'Analyse de vos', em: 'deux réponses', tail: 'en cours')
        : (lead: 'Analyse de votre', em: 'texte', tail: 'en cours');

const kDiagnosticAnalysisLead =
    'Votre rapport s’affichera ici dès qu’il sera prêt.';

/// Les étapes de l'attente, **dans l'état servi** : une ligne par production
/// que la session comporte (reçue ou non), puis l'analyse, puis le rapport.
/// Aucune ligne pour une production qui n'existe pas (`null`).
List<DiagnosticWaitStep> diagnosticAnalysisSteps({
  required bool? writtenReceived,
  required bool? oralReceived,
}) {
  final steps = <DiagnosticWaitStep>[
    if (writtenReceived != null)
      DiagnosticWaitStep(
        writtenReceived ? 'Texte reçu' : 'Texte en cours de réception',
        writtenReceived
            ? DiagnosticWaitState.done
            : DiagnosticWaitState.active,
      ),
    if (oralReceived != null)
      DiagnosticWaitStep(
        oralReceived
            ? 'Enregistrement reçu'
            : 'Enregistrement en cours de réception',
        oralReceived ? DiagnosticWaitState.done : DiagnosticWaitState.active,
      ),
  ];
  final allReceived =
      steps.every((step) => step.state == DiagnosticWaitState.done);
  return [
    ...steps,
    DiagnosticWaitStep(
      'Analyse en cours',
      allReceived ? DiagnosticWaitState.active : DiagnosticWaitState.pending,
    ),
    const DiagnosticWaitStep('Votre rapport', DiagnosticWaitState.pending),
  ];
}

const kDiagnosticElapsedLabel = 'Temps écoulé';

/// Au-delà, on cesse d'annoncer « moins de deux minutes » : ce serait faux.
const kDiagnosticAnalysisUsual = Duration(minutes: 2);

const kDiagnosticAnalysisUsualText = 'En général, moins de deux minutes. '
    'Vous pouvez quitter cette page : l’analyse continue sans vous.';

String diagnosticAnalysisSlow(bool hasOral) =>
    'C’est plus long que d’habitude. '
    '${hasOral ? 'Vos deux réponses sont enregistrées' : 'Votre texte est enregistré'}'
    ' : vous pouvez revenir plus tard.';

const kDiagnosticOutcomesTitle = 'Ce que contiendra votre rapport';

/// L'onglet « Accueil » de l'app (`AppRoutes.home`).
const kDiagnosticAnalysisHomeCta = 'Revenir à l’accueil';

/* ------------------------------------------------------- échec d'analyse */

const kDiagnosticAnalysisFailedTitle = 'L’analyse n’a pas pu aboutir';

String diagnosticAnalysisFailedText(bool hasOral) =>
    '${hasOral ? 'Vos deux réponses sont conservées' : 'Votre texte est conservé'}'
    '. Vous n’avez rien à refaire.';

String diagnosticAnalysisRetryExhausted(bool hasOral) =>
    'Le nombre de relances automatiques est épuisé. '
    '${hasOral ? 'Vos deux réponses restent enregistrées' : 'Votre texte reste enregistré'}'
    ' : vous n’avez rien à refaire. L’analyse a échoué de notre côté, et '
    'votre plan reste accessible en attendant.';

String diagnosticRetryRateLimited(bool hasOral) =>
    'Trop de relances en peu de temps. Patientez quelques minutes, puis '
    'réessayez : '
    '${hasOral ? 'vos deux réponses restent conservées' : 'votre texte reste conservé'}'
    '.';

/* ------------------------------------ envoi des productions faites en invité */

String diagnosticSendingTitle(bool hasOral) => hasOral
    ? 'Nous enregistrons vos deux réponses'
    : 'Nous enregistrons votre texte';

String diagnosticSendingText(bool hasOral) => hasOral
    ? 'Elles restent sur cet appareil tant que le serveur ne les a pas '
        'confirmées.'
    : 'Il reste sur cet appareil tant que le serveur ne l’a pas confirmé.';

/// Les étapes de l'envoi — l'oral n'y figure que s'il existe.
List<DiagnosticWaitStep> diagnosticSendingSteps(
  bool hasOral,
  DiagnosticSyncStage current,
) {
  final stages = <(DiagnosticSyncStage, String)>[
    (DiagnosticSyncStage.session, 'Ouverture de votre session'),
    (DiagnosticSyncStage.written, 'Envoi de votre texte'),
    if (hasOral) (DiagnosticSyncStage.oral, 'Envoi de votre enregistrement'),
    (DiagnosticSyncStage.confirming, 'Confirmation par le serveur'),
  ];
  final found = stages.indexWhere((stage) => stage.$1 == current);
  final active = found < 0 ? 0 : found;
  return [
    for (var index = 0; index < stages.length; index++)
      DiagnosticWaitStep(
        stages[index].$2,
        index < active
            ? DiagnosticWaitState.done
            : index == active
                ? DiagnosticWaitState.active
                : DiagnosticWaitState.pending,
      ),
  ];
}

String diagnosticSendFailedTitle(bool hasOral) => hasOral
    ? 'Vos réponses n’ont pas pu être envoyées'
    : 'Votre texte n’a pas pu être envoyé';

String diagnosticSendFailedText(bool hasOral) => hasOral
    ? 'Elles sont toujours conservées sur cet appareil : vous pouvez '
        'réessayer maintenant ou plus tard.'
    : 'Il est toujours conservé sur cet appareil : vous pouvez réessayer '
        'maintenant ou plus tard.';

String diagnosticSendUnconfirmed(bool hasOral) => hasOral
    ? 'Le serveur n’a pas confirmé la réception de vos deux réponses.'
    : 'Le serveur n’a pas confirmé la réception de votre texte.';

const kDiagnosticSendRetryCta = 'Réessayer l’envoi';
