/// Longueur maximale d'une preuve citée dans une carte de priorité.
///
/// Le serveur renvoie la preuve telle que le correcteur l'a désignée : sur une
/// production orale, c'est souvent le tour de parole **entier**. Affichée sans
/// borne, elle occupait la moitié de la carte d'étape du Plan et noyait ce
/// qu'on venait y lire — la compétence et l'action à faire.
///
/// Miroir mot pour mot de `EVIDENCE_EXCERPT_MAX_CHARS` (`web_sejoufr/lib/
/// evidence-excerpt.ts`) : la même preuve doit se couper au même endroit sur
/// les deux fronts.
const int kEvidenceExcerptMaxChars = 180;

/// Ramène [text] à un extrait lisible, coupé sur une **frontière de mot** et
/// suivi d'une ellipse.
///
/// On tronque le texte plutôt que de laisser le rendu ellipser sur un nombre de
/// lignes : la citation reste ainsi **fermée** par son guillemet, et les deux
/// fronts coupent au même caractère quelle que soit la largeur d'écran.
String evidenceExcerpt(String text, {int maxChars = kEvidenceExcerptMaxChars}) {
  final trimmed = text.trim();
  if (trimmed.length <= maxChars) return trimmed;

  final head = trimmed.substring(0, maxChars);
  final lastSpace = head.lastIndexOf(' ');
  // Un texte sans espace dans la fenêtre (mot très long, transcription collée)
  // se coupe net : mieux vaut ça qu'une carte qui déborde.
  final cut = lastSpace > maxChars ~/ 2 ? head.substring(0, lastSpace) : head;

  return '${cut.replaceAll(RegExp(r'[\s,;:.…]+$'), '')}…';
}
