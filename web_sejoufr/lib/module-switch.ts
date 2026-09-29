/**
 * **Le parcours choisi — sa lecture et ses deux adresses.** Autorité unique.
 *
 * 🛑 Arbitrage du propriétaire (2026-09-12) : « **Le menu de gauche, faut le
 * laisser comme il était.** Le choix entre examen civique et TCF, dans les
 * écrans **dashboard, plan, entraînement (réviser)**. » La barre latérale a
 * donc retrouvé ses deux entrées de menu, et le choix vit **dans l'écran**, sur
 * ces trois-là, porté par la même brique du kit (`ModuleToggle`).
 *
 * ⚠️ **Ce que ce fichier N'EST PLUS** : il a porté, une passe durant, une
 * bascule *contextuelle* de barre latérale (`basculeParcours`, une liste
 * ordonnée d'espaces qui disait « où mène le choix depuis cette route »). Cette
 * bascule est révoquée, son unique lecteur a disparu, et la fonction avec —
 * refonte = suppression immédiate de l'ancien. Ne pas la réintroduire : chaque
 * écran connaît sa propre destination et la nomme lui-même.
 *
 * 🛑 **Un seul mécanisme de sélection de module, et c'est `?module=`.** Aucune
 * fonction ici ne devine un module d'après un état serveur : quand l'URL se
 * tait, `moduleDeLUrl` rend `null` et c'est à l'écran — seul à connaître le
 * défaut **servi** — de trancher (`moduleParDefaut(prep)`, `lib/preparation.ts`).
 */

export type ParcoursModule = "TCF" | "CIVIQUE";

/**
 * Le module porté par `?module=`.
 *
 * La casse est tolérée : le dépôt écrit `?module=TCF`, mais un lien tapé à la
 * main (`/plan?module=tcf`) doit ouvrir le même écran plutôt que de retomber
 * silencieusement sur l'autre parcours.
 */
export function moduleDeLUrl(
  params: {get(name: string): string | null} | null | undefined,
): ParcoursModule | null {
  const brut = params?.get("module")?.toUpperCase();
  if (brut === "TCF") return "TCF";
  if (brut === "CIVIQUE") return "CIVIQUE";
  return null;
}

/** L'adresse du Plan pour un module — la seule forme écrite dans le web. */
export function planHref(module: ParcoursModule): string {
  return `/plan?module=${module}`;
}

/**
 * L'adresse de l'espace d'entraînement pour un module : les deux entrées de la
 * barre latérale, la bascule de l'Accueil et celle du hub la partagent.
 */
export function entrainementHref(module: ParcoursModule): string {
  return `/entrainement?module=${module}`;
}
