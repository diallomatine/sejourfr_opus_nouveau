import { Check, Sparkles, Target, TrendingUp } from "lucide-react";

/**
 * Les textes de l'accueil que d'autres écrans publics reprennent tels quels
 * (`/connexion`, `/inscription` et les écrans de mot de passe, via
 * `app/_components/auth/auth-panels.ts`). Déclarés une fois : un argument qui
 * change sur l'accueil change partout.
 */

/** Repris seul par les écrans de compte des diagnostics. */
export const NO_CARD_REQUIRED = "Sans carte bancaire";

/** Ce que le visiteur obtient sans payer — rangée de coches du hero. */
export const HERO_TRUST: readonly string[] = [
  NO_CARD_REQUIRED,
  "Niveau estimé",
  "Analyse IA utile",
];

/** Les quatre temps du parcours — bande sous le hero. */
export const PROMISES = [
  { Icon: Target, title: "Vous vous testez", text: "Pour connaître votre point de départ" },
  { Icon: TrendingUp, title: "Vous voyez votre niveau", text: "Un repère simple et compréhensible" },
  { Icon: Sparkles, title: "L’IA vous analyse", text: "Oral et écrit avec retours utiles" },
  { Icon: Check, title: "Vous avancez mieux", text: "Plan ciblé jusqu’aux examens blancs" },
] as const;
