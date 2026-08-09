/** Routes "duales" — accessibles aux guests ET aux connectés. Les connectés
 *  voient en plus la sidebar via le DualChromeShell. */
export const DUAL_CHROME_PREFIXES = [
  "/entrainement",
  "/examens-blancs",
  "/sessions",
];

/** Routes du groupe (app) — espace personnel, toujours derrière le login.
 *  Partagé entre SiteHeader (burger unique) et shouldHideGlobalChrome. */
export const APP_GROUP_PREFIXES = [
  "/dashboard",
  "/diagnostic",
  "/historique",
  "/paiement",
  "/parcours",
  "/profil",
  "/plan",
  "/recommandations",
  "/revision",
  "/statistiques",
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
