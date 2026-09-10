"use client";

import {Check} from "lucide-react";
import styles from "./diagnostic.module.css";

/**
 * Le fil du parcours, repris de la maquette (barre numérotée en tête d'écran).
 *
 * 🛑 **Il décrit ce qui reste à faire, il ne le décide pas.** L'étape courante
 * est passée par l'appelant, qui la tient de l'état réel (production locale
 * présente ou non, session serveur, statut d'analyse) : cette barre ne calcule
 * rien et ne peut donc jamais contredire l'écran affiché.
 *
 * La marche **Compréhension** n'existe que dans le parcours complet, et elle
 * arrive volontairement **après** le compte : un attempt sans compte n'a
 * personne à qui attribuer un progrès (cf. `DiagnosticIntro`).
 */
export type DiagnosticStepKey = "written" | "oral" | "account" | "report" | "comprehension";

const LABELS: Record<DiagnosticStepKey, string> = {
  written: "Écrit",
  oral: "Oral",
  account: "Compte",
  report: "Rapport",
  comprehension: "Compréhension",
};

export function diagnosticSteps(options: {
  guest: boolean;
  complete: boolean;
  /**
   * Ce diagnostic comporte-t-il une étape orale ? (L3)
   *
   * 🛑 Le diagnostic rapide n'en a pas, et la marche ne doit **pas** être
   * dessinée : une barre qui annonce une étape qui n'arrivera jamais fait
   * croire au candidat qu'il n'a pas fini, exactement au moment où on lui
   * demande de créer son compte. Absent ⇒ `true`, la forme historique.
   */
  oral?: boolean;
}): DiagnosticStepKey[] {
  const steps: DiagnosticStepKey[] =
    options.oral === false ? ["written"] : ["written", "oral"];
  // Un compte déjà créé n'a plus de marche « Compte » à franchir : l'afficher
  // ferait compter une étape que le candidat ne verra jamais.
  if (options.guest) steps.push("account");
  steps.push("report");
  if (options.complete) steps.push("comprehension");
  return steps;
}

export function DiagnosticSteps({
  current,
  guest,
  complete,
  oral,
}: {
  current: DiagnosticStepKey;
  guest: boolean;
  complete: boolean;
  oral?: boolean;
}) {
  const steps = diagnosticSteps({guest, complete, oral});
  const index = Math.max(0, steps.indexOf(current));
  return (
    <ol className={styles.steps} aria-label="Étapes du diagnostic">
      {steps.map((step, i) => {
        const state = i < index ? "done" : i === index ? "current" : "todo";
        return (
          <li key={step} data-state={state} aria-current={state === "current" ? "step" : undefined}>
            <span className={styles.stepMark} aria-hidden>
              {state === "done" ? <Check size={12} strokeWidth={3.2} /> : i + 1}
            </span>
            <span className={styles.stepLabel}>{LABELS[step]}</span>
          </li>
        );
      })}
    </ol>
  );
}
