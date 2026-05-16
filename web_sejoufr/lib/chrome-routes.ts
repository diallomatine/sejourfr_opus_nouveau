/** Routes d'authentification : layout 2-pane focus, sans header ni footer
 *  public. C'est le seul cas où le chrome global est masqué. Partout ailleurs
 *  (espace public ET espace connecté) on affiche header + footer. */
export const AUTH_PREFIXES = [
  "/inscription",
  "/connexion",
  "/mot-de-passe-oublie",
  "/reinitialiser-mot-de-passe",
];

export function isAuthRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return AUTH_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/** Routes "duales" — accessibles aux guests ET aux connectés. Les connectés
 *  voient en plus la sidebar via le DualChromeShell. Le chrome global (header
 *  + footer) reste visible dans les deux cas. */
export const DUAL_CHROME_PREFIXES = [
  "/entrainement",
  "/examens-blancs",
  "/sessions",
];

export function isDualChromeRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return DUAL_CHROME_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/** Vrai si la route doit cacher le SiteHeader + Footer global.
 *  Seules les pages d'auth (focus 2-pane) cachent le chrome. */
export function shouldHideGlobalChrome(
  pathname: string | null,
  _isAuthenticated: boolean,
): boolean {
  return isAuthRoute(pathname);
}
