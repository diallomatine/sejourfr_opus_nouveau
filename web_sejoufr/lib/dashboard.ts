// Helpers des catégories du GET /api/me/dashboard (hubs, examens blancs,
// historique).

import type { DashboardCategoryStat } from "./types";

/** Moyenne des pourcentages renseignés d'un module (null si aucun). */
export function moduleAverage(cats: DashboardCategoryStat[]): number | null {
  const known = cats.filter((c) => c.percent !== null);
  if (known.length === 0) return null;
  return Math.round(
    known.reduce((sum, c) => sum + (c.percent ?? 0), 0) / known.length,
  );
}

/**
 * Sous-titre d'un taux de réussite — **il dit d'où vient le chiffre, il ne le
 * juge pas**.
 *
 * 🛑 Il rendait « Excellent niveau » / « En bonne voie » / « À consolider »
 * selon des seuils locaux. Supprimé le 2026-08-23 : un état pédagogique vient
 * servi ou n'existe pas (§25 bis.3). Le pourcentage affiché ici est un taux de
 * bonnes réponses, pas un score TCF ni une probabilité de réussite.
 */
export function successHint(percent: number | null): string {
  return percent === null
    ? "Commencez l'entraînement"
    : "sur vos réponses enregistrées";
}

/**
 * Badge d'une catégorie dans les hubs — **le seul fait qu'il énonce, c'est si
 * la catégorie a déjà été travaillée**.
 *
 * 🛑 Il rendait « Solide » ≥ 80, « En bonne voie » ≥ 60, « À renforcer » en
 * dessous : trois verdicts pédagogiques calculés dans le navigateur à partir
 * d'un taux de bonnes réponses. Supprimé le 2026-08-23 (§25 bis.3, §25 bis.4).
 *
 * Le vrai état — « À renforcer », « En progression », « Prêt à vérifier »,
 * « Acquis », « À vérifier » — viendra du serveur avec le moteur de
 * progression, avec son ton (`lib/progression-contract.ts`). D'ici là, on
 * n'invente rien : un chiffre brut ne dit pas où en est un candidat.
 */
export function categoryBadge(percent: number | null): {
  label: string;
  tone: "green" | "blue" | "amber" | "none";
} {
  return percent === null
    ? { label: "À découvrir", tone: "none" }
    : { label: "Déjà travaillé", tone: "blue" };
}
