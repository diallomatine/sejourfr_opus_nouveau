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

/** Header + Footer publics sont désormais affichés sur toutes les pages,
 *  y compris les routes d'auth. Cette fonction est conservée pour les call
 *  sites existants (SiteHeader / Footer) mais retourne toujours false. */
export function shouldHideGlobalChrome(
  _pathname: string | null,
  _isAuthenticated: boolean,
): boolean {
  return false;
}
