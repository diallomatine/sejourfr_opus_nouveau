/** Routes qui portent leur propre chrome (sidebar pour l'espace connecté,
 *  layout 2-pane pour les pages d'auth). Le SiteHeader et le Footer globaux
 *  se cachent sur ces routes pour éviter une double-navigation. */
export const APP_PREFIXES = [
  // Espace personnel (sidebar). /entrainement, /examens-blancs et /sessions
  // sont volontairement absents : ces routes sont accessibles aux visiteurs
  // anonymes en mode démo (header + footer publics visibles).
  "/dashboard",
  "/historique",
  "/paiement",
  "/parcours",
  "/profil",
  "/revision",
  "/statistiques",
  // Pages d'authentification (layout 2-pane, brand link en haut à gauche)
  "/inscription",
  "/connexion",
  "/mot-de-passe-oublie",
  "/reinitialiser-mot-de-passe",
];

export function isAppRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return APP_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/** Routes accessibles aux guests ET aux connectés, mais avec chrome différent :
 *  - connecté → sidebar app-shell (header/footer publics cachés)
 *  - guest    → header + footer publics (pas de sidebar) */
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

/** Vrai si la route doit cacher le SiteHeader + Footer global :
 *  - dans APP_PREFIXES (toujours)
 *  - OU dans DUAL_CHROME_PREFIXES ET l'utilisateur est authentifié. */
export function shouldHideGlobalChrome(
  pathname: string | null,
  isAuthenticated: boolean,
): boolean {
  if (isAppRoute(pathname)) return true;
  if (isAuthenticated && isDualChromeRoute(pathname)) return true;
  return false;
}
