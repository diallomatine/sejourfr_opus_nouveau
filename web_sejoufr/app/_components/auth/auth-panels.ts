import { CircleCheck, Gauge, Landmark, Route, Target, type LucideIcon } from "lucide-react";
import { FREE_OFFER_FEATURES } from "@/lib/passes";
import {
  CIVIC_PRIORITES_TITLE,
  CIVIC_RESULT_SCORE_LABEL,
  CIVIC_THEMES_COUNT,
  CIVIC_THEMES_TITLE,
} from "@/lib/civic-diagnostic";
import { HERO_TRUST, NO_CARD_REQUIRED, PROMISES } from "../landing/landing-copy";
import {
  DIAGNOSTIC_DISCLAIMER,
  DIAGNOSTIC_OUTCOME_LEVEL,
  DIAGNOSTIC_OUTCOME_PLAN,
  DIAGNOSTIC_OUTCOME_PRIORITIES,
} from "../diagnostic/diagnostic-outcomes";
import { DIAGNOSTIC_LEVEL_EYEBROW } from "../diagnostic/report-labels";

/**
 * 🛑 Le panneau d'argumentaire des écrans d'auth. **Presque aucun texte
 * propre** : il reprend l'accueil (`landing-copy.ts`), l'offre gratuite servie
 * par `FREE_OFFER_FEATURES` (`lib/passes.ts`, une règle de
 * `docs/regles/freemium.md` par ligne) et, pour les diagnostics, les intitulés
 * des écrans de résultat eux-mêmes. Seuls les titres de panneau sont écrits
 * ici. Ni témoignage, ni note, ni nombre d'inscrits, ni taux de réussite : ils
 * ont existé ici (2026-09-26) et étaient inventés.
 */

export interface AuthPanelItem {
  title: string;
  text?: string;
  Icon?: LucideIcon;
}

export interface AuthPanel {
  kicker: string;
  title: { lead: string; em: string; tail?: string };
  items: readonly AuthPanelItem[];
  trust?: readonly string[];
  /** Petite ligne sous la liste (ex. « Estimation d'entraînement, non officielle. »). */
  note?: string;
  link?: { href: string; label: string };
}

/** Inscription : ce que le compte gratuit ouvre, mot pour mot celui de `/tarifs`. */
export const SIGNUP_PANEL: AuthPanel = {
  kicker: "Compte gratuit",
  title: { lead: "Ce que votre compte", em: "gratuit", tail: "ouvre." },
  items: FREE_OFFER_FEATURES.map((title) => ({ title })),
  trust: HERO_TRUST,
  link: { href: "/tarifs", label: "Comparer avec les pass" },
};

/** Connexion et mot de passe : le parcours que le compte retrouve. */
export const SIGNIN_PANEL: AuthPanel = {
  kicker: "Votre préparation",
  title: { lead: "Un parcours clair,", em: "étape par étape." },
  items: PROMISES,
};

/**
 * Écran de compte du diagnostic TCF invité : ce que l'analyse rendra. Le
 * niveau porte l'intitulé EXACT du rapport (« Niveau estimé sur cet
 * exercice ») — jamais « votre niveau TCF ». Aucun lien : on ne fait pas
 * quitter un diagnostic en cours.
 */
export const TCF_DIAGNOSTIC_PANEL: AuthPanel = {
  kicker: "Après votre compte",
  title: { lead: "Ce que l’analyse", em: "vous rendra." },
  items: [
    { Icon: Gauge, title: DIAGNOSTIC_LEVEL_EYEBROW, text: DIAGNOSTIC_OUTCOME_LEVEL.text },
    { Icon: Target, ...DIAGNOSTIC_OUTCOME_PRIORITIES },
    { Icon: Route, ...DIAGNOSTIC_OUTCOME_PLAN },
  ],
  trust: HERO_TRUST,
  note: DIAGNOSTIC_DISCLAIMER,
};

/**
 * Écran de compte du diagnostic civique invité : les blocs du résultat, sous
 * les intitulés de `CivicDiagnosticResult` (`lib/civic-diagnostic.ts`).
 * 🛑 Aucun score : c'est précisément ce qu'on échange contre le compte.
 */
export const CIVIC_DIAGNOSTIC_PANEL: AuthPanel = {
  kicker: "Après votre compte",
  title: { lead: "Ce que votre résultat", em: "vous montrera." },
  items: [
    {
      Icon: CircleCheck,
      title: CIVIC_RESULT_SCORE_LABEL,
      text: "Comparées au seuil de réussite de l’examen",
    },
    {
      Icon: Landmark,
      title: CIVIC_THEMES_TITLE,
      text: `Où vous en êtes sur chacun des ${CIVIC_THEMES_COUNT} thèmes du livret`,
    },
    { Icon: Target, title: CIVIC_PRIORITES_TITLE, text: DIAGNOSTIC_OUTCOME_PRIORITIES.text },
    { Icon: Route, ...DIAGNOSTIC_OUTCOME_PLAN },
  ],
  trust: [NO_CARD_REQUIRED],
};
