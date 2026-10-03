// Helpers des catégories du GET /api/me/dashboard (hubs).

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
