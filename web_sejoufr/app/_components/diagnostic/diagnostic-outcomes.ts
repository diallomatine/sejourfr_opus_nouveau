/**
 * Ce qu'un diagnostic rend au candidat, en trois lignes — déclaré une fois.
 *
 * Lu par l'écran de choix du visiteur (`DiagnosticChoice`, bande du bas) et
 * par le panneau d'argumentaire des deux écrans de compte des diagnostics
 * (`auth-panels.ts`). Une promesse qui change ici change partout.
 *
 * 🛑 Rien d'autre qu'un constat vrai : pas de chiffre, pas de durée, pas de
 * résultat inventé. Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_outcomes.dart`.
 */

export interface DiagnosticOutcome {
  title: string;
  text: string;
}

export const DIAGNOSTIC_OUTCOME_LEVEL: DiagnosticOutcome = {
  title: "Votre niveau",
  text: "Une estimation simple à comprendre",
};
export const DIAGNOSTIC_OUTCOME_PRIORITIES: DiagnosticOutcome = {
  title: "Vos priorités",
  text: "Ce qu’il faut travailler en premier",
};
export const DIAGNOSTIC_OUTCOME_PLAN: DiagnosticOutcome = {
  title: "Votre plan",
  text: "Un parcours adapté à votre résultat",
};

export const DIAGNOSTIC_OUTCOMES: readonly DiagnosticOutcome[] = [
  DIAGNOSTIC_OUTCOME_LEVEL,
  DIAGNOSTIC_OUTCOME_PRIORITIES,
  DIAGNOSTIC_OUTCOME_PLAN,
];

export const DIAGNOSTIC_DISCLAIMER = "Estimation d’entraînement, non officielle.";
