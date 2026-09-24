import {hasInAppHistory, skipNextNavigation} from "./nav-history";
import {safeInternalPath} from "./security";

/**
 * **Les deux « retours » du parcours**, dans un seul fichier parce qu'ils
 * portent le même mot et **ne veulent pas dire la même chose** :
 *
 * - `retourOuRepli` — le geste « remonter » d'une page, côté navigateur ;
 * - `RETOUR_PARAM` / `retourDe` / `withRetour` — le **chemin** d'où le candidat
 *   est parti acheter, qui voyage jusqu'à Stripe et en revient.
 */

export const RETOUR_PARAM = "retour";

/**
 * **Le chemin de retour LU et VALIDÉ**, ou `null`.
 *
 * 🛑 **Même garde qu'`?next=`** (`safeInternalPath`) : un chemin interne, jamais
 * un hôte ni un schéma, et jamais `//` ni `/\` — les deux formes
 * *protocol-relative*, qui sont l'open-redirect classique. Le serveur applique
 * déjà la même règle avant de poser la valeur sur la `success_url` ; on la
 * repasse ici parce qu'une URL se trafique dans la barre d'adresse.
 *
 * 🛑 **`null` est le cas NOMINAL le plus fréquent** — lien partagé, achat depuis
 * les tarifs, retour Stripe d'une autre session. L'appelant garde alors
 * exactement son comportement d'avant : on ne casse pas le chemin nominal pour
 * un confort.
 */
export function retourDe(params: {get(key: string): string | null}): string | null {
    const brut = params.get(RETOUR_PARAM);
    if (!brut) return null;
    const sur = safeInternalPath(brut, "");
    return sur === "" ? null : sur;
}

/**
 * **Pose le chemin de retour sur une adresse interne** du parcours d'achat.
 *
 * `null` / vide ⇒ l'adresse est rendue telle quelle : aucun paramètre vide ne
 * traîne dans l'URL.
 */
export function withRetour(href: string, retour: string | null | undefined): string {
    if (!retour) return href;
    const sep = href.includes("?") ? "&" : "?";
    return `${href}${sep}${RETOUR_PARAM}=${encodeURIComponent(retour)}`;
}

/**
 * **Le geste « retour » d'une page** : l'écran précédent de SejourFR s'il y en
 * a un, sinon l'adresse parente déclarée par la page.
 *
 * 🛑 **`router.back()` seul ne suffit pas.** Une page ouverte directement — lien
 * partagé, nouvel onglet, retour de paiement — n'a pas d'historique interne :
 * le bouton ne ferait **rien**, ou sortirait du site. D'où le compteur
 * `hasInAppHistory` (`lib/nav-history.ts`), et non `history.length`, qui
 * compte aussi les pages d'avant le site.
 *
 * ⚠️ Le repli **remplace** l'entrée courante (`replace`) : un `push` rendrait
 * au parent un historique qui pointe vers l'enfant, et la flèche du parent y
 * reviendrait — une boucle.
 *
 * C'est aussi le geste de la flèche de la barre du haut (`AppTopBar`).
 *
 * Miroir de `retourOuRepli` (`mobile_sejourfr/lib/core/router/retour.dart`).
 */
export function retourOuRepli(
    router: {back(): void; replace(href: string): void},
    repli: string,
): void {
    if (hasInAppHistory()) {
        router.back();
        return;
    }
    if (new URL(repli, window.location.origin).pathname !== window.location.pathname) {
        skipNextNavigation();
    }
    router.replace(repli);
}
