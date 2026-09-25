import type { LucideIcon } from "lucide-react";
import { FREE_OFFER_FEATURES } from "@/lib/passes";
import { HERO_TRUST, PROMISES } from "../landing/landing-copy";

/**
 * 🛑 Le panneau d'argumentaire des pages d'auth. **Aucun texte propre** : il
 * reprend l'accueil (`landing-copy.ts`) et l'offre gratuite servie par
 * `FREE_OFFER_FEATURES` (`lib/passes.ts`, une règle de `docs/regles/freemium.md`
 * par ligne). Ni témoignage, ni note, ni nombre d'inscrits, ni taux de
 * réussite : ils ont existé ici (2026-09-26) et étaient inventés.
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
