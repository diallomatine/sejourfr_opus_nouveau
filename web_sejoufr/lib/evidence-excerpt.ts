/**
 * Longueur maximale d'une preuve citée dans une carte de priorité.
 *
 * Le serveur renvoie la preuve telle que le correcteur l'a désignée : sur une
 * production orale, c'est souvent le tour de parole **entier**. Affichée sans
 * borne, elle occupait la moitié de la carte d'étape du Plan et noyait ce qu'on
 * venait y lire — la compétence et l'action à faire.
 *
 * Miroir mot pour mot de `kEvidenceExcerptMaxChars`
 * (`mobile_sejourfr/lib/core/utils/evidence_excerpt.dart`) : la même preuve
 * doit se couper au même endroit sur les deux fronts.
 */
export const EVIDENCE_EXCERPT_MAX_CHARS = 180;

/**
 * Ramène `text` à un extrait lisible, coupé sur une **frontière de mot** et
 * suivi d'une ellipse.
 *
 * On tronque le texte plutôt que de le clamper en CSS (`line-clamp`) : la
 * citation reste ainsi **fermée** par son guillemet, et les deux fronts coupent
 * au même caractère quelle que soit la largeur d'écran.
 */
export function evidenceExcerpt(
  text: string,
  maxChars: number = EVIDENCE_EXCERPT_MAX_CHARS,
): string {
  const trimmed = text.trim();
  if (trimmed.length <= maxChars) return trimmed;

  const head = trimmed.slice(0, maxChars);
  const lastSpace = head.lastIndexOf(" ");
  // Un texte sans espace dans la fenêtre (mot très long, transcription collée)
  // se coupe net : mieux vaut ça qu'une carte qui déborde.
  const cut = lastSpace > Math.floor(maxChars / 2) ? head.slice(0, lastSpace) : head;

  return `${cut.replace(/[\s,;:.…]+$/, "")}…`;
}
