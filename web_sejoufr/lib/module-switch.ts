/**
 * **Où mène la bascule TCF / Examen civique depuis ici** — autorité unique.
 *
 * 🛑 Arbitrage du propriétaire (2026-09-12) : « une seule bascule TCF / Examen
 * civique visible à la fois, et **son action dépend du contexte courant** — sur
 * Plan elle change le Plan, sur Réviser / Entraînement elle change l'espace
 * d'entraînement. »
 *
 * C'est donc une bascule **contextuelle**, et c'est exactement le genre de
 * règle qui se recopie en trois `if` qui divergent : la barre latérale, le
 * marquage de l'onglet actif et le sous-titre de parcours en ont tous besoin.
 * Elle vit ici, une fois, sous forme d'une **liste ordonnée d'espaces** — le
 * premier qui reconnaît la route gagne.
 *
 * 🛑 **Aucun second mécanisme de sélection de module.** Le module courant se lit
 * là où il a toujours été transporté : le paramètre `?module=` de l'URL. Cette
 * fonction ne devine jamais le module d'après un état serveur — quand l'URL ne
 * le dit pas, `courant` vaut `null` et **aucun** côté n'est marqué actif, comme
 * le sous-titre de parcours qui affiche la ligne de marque hors d'un parcours.
 * C'est l'écran, seul à connaître le défaut **servi**, qui inscrit sa résolution
 * dans l'URL (cf. `PlanModules`).
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

/** L'adresse de l'espace d'entraînement pour un module. */
export function entrainementHref(module: ParcoursModule): string {
  return `/entrainement?module=${module}`;
}

export interface BasculeParcours {
  /** Où mène le côté `module` de la bascule, depuis la route courante. */
  href: (module: ParcoursModule) => string;
  /**
   * Le parcours courant, **lu** — jamais déduit d'un état serveur. `null`
   * signifie « cette route n'est dans aucun des deux parcours » : la bascule
   * s'affiche alors sans côté actif.
   */
  courant: ParcoursModule | null;
}

interface Espace {
  reconnait: (pathname: string) => boolean;
  href: (module: ParcoursModule) => string;
  courant: (
    pathname: string,
    params: {get(name: string): string | null} | null | undefined,
  ) => ParcoursModule | null;
}

/**
 * 🛑 **Ordonné, et le premier qui reconnaît gagne.** Le dernier reconnaît tout :
 * hors du Plan, la bascule garde sa destination historique — l'espace
 * d'entraînement —, ce qui conserve les deux seules entrées du menu qui y
 * mènent.
 */
const ESPACES: readonly Espace[] = [
  {
    // Le Plan et ses vues secondaires (`/plan/competences`, `/plan/domaine/…`).
    reconnait: (pathname) => pathname === "/plan" || pathname.startsWith("/plan/"),
    href: planHref,
    // Les vues secondaires ne portent pas de `?module=` : `null`, et la bascule
    // n'y marque aucun côté. On n'invente pas le parcours d'un écran qui ne le
    // dit pas.
    courant: (_pathname, params) => moduleDeLUrl(params),
  },
  {
    reconnait: () => true,
    href: entrainementHref,
    courant: (pathname, params) => {
      if (pathname.startsWith("/entrainement/tcf") || pathname.startsWith("/diagnostic-tcf")) {
        return "TCF";
      }
      if (
        pathname.startsWith("/entrainement/civique") ||
        pathname.startsWith("/diagnostic-civique")
      ) {
        return "CIVIQUE";
      }
      // Le hub rend le civique quand l'URL ne dit rien : ce n'est pas une
      // déduction, c'est ce que la page affiche (`app/entrainement/page.tsx`).
      if (pathname === "/entrainement") return moduleDeLUrl(params) ?? "CIVIQUE";
      return null;
    },
  },
];

export function basculeParcours(
  pathname: string | null,
  params: {get(name: string): string | null} | null | undefined,
): BasculeParcours {
  const path = pathname ?? "/";
  const espace = ESPACES.find((candidat) => candidat.reconnait(path)) ?? ESPACES[ESPACES.length - 1];
  return {href: espace.href, courant: espace.courant(path, params)};
}
