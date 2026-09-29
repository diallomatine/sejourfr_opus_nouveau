/**
 * Helpers de sécurité front partagés.
 */

/**
 * Anti open-redirect : ne renvoie `value` que si c'est un chemin interne sûr.
 *
 * Un chemin valide commence par un seul "/" et n'est pas protocol-relative
 * ("//host") ni un trick backslash ("/\\host") — qui seraient résolus par le
 * navigateur comme une URL absolue vers un domaine externe. Tout le reste
 * (URL absolue "https://…", "javascript:…", valeur nulle) retombe sur
 * `fallback`.
 *
 * À utiliser pour toute redirection dérivée d'un paramètre d'URL (`?next=`,
 * `?from=`, etc.) avant de la passer à `router.push/replace`.
 */
export function safeInternalPath(
  value: string | null | undefined,
  fallback: string,
): string {
  if (!value || !value.startsWith("/")) return fallback;
  if (value.length > 1 && (value[1] === "/" || value[1] === "\\")) return fallback;
  return value;
}

/**
 * La destination après connexion / inscription / complétion du profil.
 * 🛑 L'accueil public (`/`) n'en est jamais une : un compte connecté y
 * retomberait sur la vitrine au lieu de son espace — il va au tableau de bord.
 */
export function postLoginPath(value: string | null | undefined): string {
  const path = safeInternalPath(value, "/dashboard");
  return path === "/" || path.startsWith("/?") || path.startsWith("/#") ? "/dashboard" : path;
}

/**
 * Sérialise un objet JSON-LD pour injection dans un <script type="application/ld+json">
 * via dangerouslySetInnerHTML, en échappant "<" pour empêcher un breakout
 * "</script>" (XSS) si une valeur venait à contenir du markup.
 */
export function safeJsonLd(data: unknown): string {
  return JSON.stringify(data).replace(/</g, "\\u003c");
}
