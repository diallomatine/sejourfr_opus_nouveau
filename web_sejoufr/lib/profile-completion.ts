import { isAppGroupRoute, isDualChromeRoute } from "./chrome-routes";
import type { AuthenticatedUser } from "./types";

/** L'écran qui pose, avant l'application, les questions de l'inscription. */
export const PROFILE_COMPLETION_PATH = "/completer-profil";

/**
 * Routes de l'application qui restent ouvertes à un profil incomplet.
 *
 * 🛑 **Les diagnostics d'abord.** Un invité qui crée son compte par Google sur
 * l'écran de compte d'un diagnostic doit voir le rattachement de sa session et
 * le lancement de son analyse partir de CET écran (`DiagnosticView`,
 * `CivicDiagnosticResult`) : le détourner au moment précis où
 * l'authentification bascule démonterait l'écran qui porte l'adoption. La
 * complétion s'intercale au pas suivant (« Voir mon plan »), avec ce pas en
 * `?next=`. Le centre d'aide reste lisible.
 */
const OPEN_WHILE_INCOMPLETE = ["/diagnostic", "/diagnostic-civique", "/aide"];

/**
 * La route demande-t-elle un profil complet ? L'application — groupe `(app)/`
 * et routes duales —, moins les exemptions ci-dessus. Les pages publiques
 * (accueil, légales, tarifs, blog, auth) ne sont jamais concernées.
 */
export function requiresCompleteProfile(pathname: string | null): boolean {
  if (!pathname) return false;
  if (OPEN_WHILE_INCOMPLETE.some((p) => pathname === p || pathname.startsWith(`${p}/`))) {
    return false;
  }
  return isAppGroupRoute(pathname) || isDualChromeRoute(pathname);
}

/**
 * 🛑 **Le fait est SERVI** (`AuthenticatedUser.profileIncomplete`,
 * `ProfilObligatoire` côté backend). Aucune lecture de `targetProcedure == null`
 * ici : c'est le serveur qui dit ce qui manque.
 */
export function mustCompleteProfile(user: AuthenticatedUser | null): boolean {
  return Boolean(user?.profileIncomplete);
}

/** `/completer-profil?next=<la destination>` — la destination est rendue telle quelle après. */
export function profileCompletionHref(next: string): string {
  return `${PROFILE_COMPLETION_PATH}?next=${encodeURIComponent(next)}`;
}
