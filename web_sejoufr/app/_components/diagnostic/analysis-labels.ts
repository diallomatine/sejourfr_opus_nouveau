/**
 * Textes des écrans d'attente du diagnostic TCF : envoi des productions faites
 * en invité, analyse en cours, échec de l'envoi ou de l'analyse — déclarés une
 * fois. Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_analysis_labels.dart`.
 *
 * 🛑 **La forme du diagnostic est LUE, jamais supposée** (correctif du
 * 2026-09-26). Le diagnostic rapide (`QUICK_TCF`) ne comporte qu'une
 * production écrite ; l'écran d'attente annonçait pourtant « vos deux
 * productions » et une « Réponse orale en attente » qui n'arriverait jamais.
 * Chaque texte ci-dessous prend `hasOral`, lu sur la session servie
 * (`diagnostic.oral`) ou sur la production locale (`oralRequired`).
 *
 * 🛑 Aucune promesse non vérifiée. « Moins de deux minutes » est mesuré : sur
 * la base locale au 2026-09-26, aucune analyse terminée sans relance n'a
 * dépassé 23 s (20 sessions). Au-delà de deux minutes, l'écran cesse de
 * l'annoncer.
 */

export type DiagnosticWaitState = "done" | "active" | "pending";

export interface DiagnosticWaitStep {
  key: string;
  label: string;
  state: DiagnosticWaitState;
}

/* ------------------------------------------------------ analyse en cours */

export const DIAGNOSTIC_ANALYSIS_KICKER = "Diagnostic rapide · analyse IA";

/** « Analyse de votre texte en cours » — le mot en `<em>` est le sujet. */
export function diagnosticAnalysisTitle(hasOral: boolean): {lead: string; em: string; tail: string} {
  return hasOral
    ? {lead: "Analyse de vos", em: "deux réponses", tail: "en cours"}
    : {lead: "Analyse de votre", em: "texte", tail: "en cours"};
}

export const DIAGNOSTIC_ANALYSIS_LEAD = "Votre rapport s’affichera ici dès qu’il sera prêt.";

/**
 * Les étapes de l'attente, **dans l'état servi** : une ligne par production
 * que la session comporte (reçue ou non), puis l'analyse, puis le rapport.
 * Aucune ligne pour une production qui n'existe pas.
 */
export function diagnosticAnalysisSteps(productions: {
  writtenReceived: boolean | null;
  oralReceived: boolean | null;
}): DiagnosticWaitStep[] {
  const steps: DiagnosticWaitStep[] = [];
  if (productions.writtenReceived != null) {
    steps.push({
      key: "written",
      label: productions.writtenReceived ? "Texte reçu" : "Texte en cours de réception",
      state: productions.writtenReceived ? "done" : "active",
    });
  }
  if (productions.oralReceived != null) {
    steps.push({
      key: "oral",
      label: productions.oralReceived ? "Enregistrement reçu" : "Enregistrement en cours de réception",
      state: productions.oralReceived ? "done" : "active",
    });
  }
  const allReceived = steps.every((step) => step.state === "done");
  steps.push({key: "analysis", label: "Analyse en cours", state: allReceived ? "active" : "pending"});
  steps.push({key: "report", label: "Votre rapport", state: "pending"});
  return steps;
}

export const DIAGNOSTIC_ELAPSED_LABEL = "Temps écoulé";

/** Au-delà, on cesse d'annoncer « moins de deux minutes » : ce serait faux. */
export const DIAGNOSTIC_ANALYSIS_USUAL_MS = 120_000;

export const DIAGNOSTIC_ANALYSIS_USUAL =
  "En général, moins de deux minutes. Vous pouvez quitter cette page : l’analyse continue sans vous.";

export function diagnosticAnalysisSlow(hasOral: boolean): string {
  return `C’est plus long que d’habitude. ${
    hasOral ? "Vos deux réponses sont enregistrées" : "Votre texte est enregistré"
  } : vous pouvez revenir plus tard.`;
}

export const DIAGNOSTIC_OUTCOMES_TITLE = "Ce que contiendra votre rapport";

/** La page que le shell connecté appelle « Accueil » (`/dashboard`). */
export const DIAGNOSTIC_ANALYSIS_HOME_CTA = "Revenir à l’accueil";

/* ------------------------------------------------------- échec d'analyse */

export const DIAGNOSTIC_ANALYSIS_FAILED_TITLE = "L’analyse n’a pas pu aboutir";

export function diagnosticAnalysisFailedText(hasOral: boolean): string {
  return `${hasOral ? "Vos deux réponses sont conservées" : "Votre texte est conservé"}. Vous n’avez rien à refaire.`;
}

export function diagnosticAnalysisRetryExhausted(hasOral: boolean): string {
  return `Le nombre de relances automatiques est épuisé. ${
    hasOral ? "Vos deux réponses restent enregistrées" : "Votre texte reste enregistré"
  } : vous n’avez rien à refaire. L’analyse a échoué de notre côté, et votre plan reste accessible en attendant.`;
}

export function diagnosticRetryRateLimited(hasOral: boolean): string {
  return `Trop de relances en peu de temps. Patientez quelques minutes, puis réessayez : ${
    hasOral ? "vos deux réponses restent conservées" : "votre texte reste conservé"
  }.`;
}

/* ------------------------------------ envoi des productions faites en invité */

export type DiagnosticSendingStage = "session" | "written" | "oral" | "confirming";

export function diagnosticSendingTitle(hasOral: boolean): string {
  return hasOral ? "Nous enregistrons vos deux réponses" : "Nous enregistrons votre texte";
}

export function diagnosticSendingText(hasOral: boolean): string {
  return hasOral
    ? "Elles restent sur cet appareil tant que le serveur ne les a pas confirmées."
    : "Il reste sur cet appareil tant que le serveur ne l’a pas confirmé.";
}

/** Les étapes de l'envoi — l'oral n'y figure que s'il existe. */
export function diagnosticSendingSteps(
  hasOral: boolean,
  current: DiagnosticSendingStage,
): DiagnosticWaitStep[] {
  const stages: Array<{key: DiagnosticSendingStage; label: string}> = [
    {key: "session", label: "Ouverture de votre session"},
    {key: "written", label: "Envoi de votre texte"},
    ...(hasOral ? [{key: "oral" as const, label: "Envoi de votre enregistrement"}] : []),
    {key: "confirming", label: "Confirmation par le serveur"},
  ];
  const active = Math.max(0, stages.findIndex((stage) => stage.key === current));
  return stages.map((stage, index) => ({
    key: stage.key,
    label: stage.label,
    state: index < active ? "done" : index === active ? "active" : "pending",
  }));
}

export function diagnosticSendFailedTitle(hasOral: boolean): string {
  return hasOral ? "Vos réponses n’ont pas pu être envoyées" : "Votre texte n’a pas pu être envoyé";
}

export function diagnosticSendFailedText(hasOral: boolean): string {
  return hasOral
    ? "Elles sont toujours conservées sur cet appareil : vous pouvez réessayer maintenant ou plus tard."
    : "Il est toujours conservé sur cet appareil : vous pouvez réessayer maintenant ou plus tard.";
}

export function diagnosticSendUnconfirmed(hasOral: boolean): string {
  return hasOral
    ? "Le serveur n’a pas confirmé la réception de vos deux réponses."
    : "Le serveur n’a pas confirmé la réception de votre texte.";
}

export const DIAGNOSTIC_SEND_RETRY_CTA = "Réessayer l’envoi";
