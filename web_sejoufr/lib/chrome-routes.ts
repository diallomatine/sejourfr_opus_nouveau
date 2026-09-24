/** Routes "duales" — accessibles aux guests ET aux connectés. Les connectés
 *  voient en plus la sidebar via le DualChromeShell. */
export const DUAL_CHROME_PREFIXES = [
  "/diagnostic",
  "/entrainement",
  "/examens-blancs",
  "/sessions",
];

/** Routes du groupe (app) — espace personnel, toujours derrière le login.
 *  Partagé entre SiteHeader (burger unique) et shouldHideGlobalChrome.
 *
 *  🛑 **Cette liste est le miroir de `app/(app)/` sur le disque, et rien
 *  d'autre.** Une route posée dans le groupe sans être déclarée ici monte DEUX
 *  chromes : le shell applicatif (`app/(app)/layout.tsx` → `AppSidebar` +
 *  `MobileSidebarToggle`) ET le chrome public, dont le `SiteHeader` garde son
 *  propre bouton de menu — d'où deux burgers empilés sous 900 px. C'est ce qui
 *  est arrivé à `/diagnostic-tcf` et `/diagnostic-civique`, ajoutés au groupe
 *  sans passer par ici. Ajouter un dossier dans `app/(app)/` ⇒ ajouter son
 *  préfixe ici, dans la même passe.
 *
 *  ⚠️ Le test est un **préfixe** : `/paiement` couvre `/paiement/succes` et
 *  `/diagnostic-tcf` couvre `/diagnostic-tcf/{id}/resultat`. */
export const APP_GROUP_PREFIXES = [
  "/dashboard",
  "/diagnostic-civique",
  "/diagnostic-tcf",
  "/historique",
  "/paiement",
  "/parcours",
  "/profil",
  "/plan",
  "/progression",
  "/recommandations",
  "/revision",
  "/succes",
];

/** Routes autoportantes : landings de campagne qui portent leur propre en-tête,
 *  leurs propres CTA et leur propre pied de page. Le chrome global (SiteHeader,
 *  Footer, bandeau app mobile) y est masqué **pour tout le monde**, connecté ou
 *  non — une page de lien de bio réseaux n'a qu'un seul job, chaque lien de nav
 *  supplémentaire est une fuite. */
export const STANDALONE_PREFIXES = ["/reussir"];

export function isStandaloneRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return STANDALONE_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

export function isDualChromeRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return DUAL_CHROME_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

export function isAppGroupRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return APP_GROUP_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/** Refonte web_refonte : pour un utilisateur connecté, les routes "app"
 *  (groupe (app) + routes duales) sont un shell applicatif pur — la sidebar
 *  porte toute la navigation, le header marketing et le footer publics
 *  disparaissent. Les guests gardent le chrome global partout.
 *
 *  L'accueil `/` reste hors de ce périmètre : un connecté y garde le header +
 *  footer marketing (desktop comme avant, sans sidebar) ; seul le drawer mobile
 *  du SiteHeader bascule sur l'AppSidebar (cf. SiteHeader). */
export function shouldHideGlobalChrome(
  pathname: string | null,
  isAuthenticated: boolean,
): boolean {
  if (isStandaloneRoute(pathname)) return true;
  if (!isAuthenticated) return false;
  return isAppGroupRoute(pathname) || isDualChromeRoute(pathname);
}

/** Routes du groupe `(app)/` qu'un VISITEUR rend réellement (diagnostic
 *  civique joué avant le compte, V053). Sur elles, un invité n'a pas de shell. */
const GUEST_ACCESSIBLE_PREFIXES = ["/diagnostic-civique"];

export function isGuestAccessibleRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return GUEST_ACCESSIBLE_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/**
 * 🛑 **L'autorité unique de « le shell applicatif (et donc SON burger) est
 * monté »** sur une route du groupe `(app)/`. `(app)/layout.tsx` la suit pour
 * rendre `MobileSidebarToggle`, `SiteHeader` la suit pour cacher le sien :
 * deux conditions écrites séparément laissaient passer deux burgers empilés
 * pour un invité (et pendant le chargement de la session).
 *
 * - connecté : shell ;
 * - invité résolu : jamais de shell — le chrome public porte le menu ;
 * - session en cours de résolution : shell, sauf sur une route duale (pas de
 *   flash de sidebar sur les routes protégées, qui redirigent ensuite).
 */
export function isAppShellMounted(
  pathname: string | null,
  status: "loading" | "authenticated" | "guest",
): boolean {
  if (!isAppGroupRoute(pathname)) return false;
  if (status === "authenticated") return true;
  if (status === "guest") return false;
  return !isGuestAccessibleRoute(pathname);
}
