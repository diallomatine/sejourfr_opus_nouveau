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
  "/historique",
  "/paiement",
  "/parcours",
  "/profil",
  "/recommandations",
  "/revision",
  "/statistiques",
  "/succes",
];

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
  if (!isAuthenticated) return false;
  return isAppGroupRoute(pathname) || isDualChromeRoute(pathname);
}
