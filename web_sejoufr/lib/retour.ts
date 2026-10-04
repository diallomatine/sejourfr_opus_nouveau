import {hasInAppHistory, skipNextNavigation} from "./nav-history";
import {safeInternalPath} from "./security";

/**
 * **Les deux « retours » du parcours**, dans un seul fichier parce qu'ils
 * portent le même mot et **ne veulent pas dire la même chose** :
 *
 * - `retourOuRepli` — le geste « remonter » d'une page, côté navigateur ;
 * - `RETOUR_PARAM` / `retourDe` / `withRetour` — le **chemin** d'où le candidat
 *   est parti acheter, qui voyage jusqu'à Stripe et en revient ; le même
 *   paramètre porte l'écran de lancement d'une série (`sessionHref`) et d'un
 *   examen blanc (`retourExamenDe`).
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
    remplacerEcran(router, repli);
}

/**
 * **Remplace l'écran courant** par `href` (`router.replace`), sans fausser le
 * compteur d'historique interne : un remplacement n'ajoute aucune entrée, et
 * le compter (+1) ferait croire plus tard à un écran SejourFR derrière — un
 * `retourOuRepli` sortirait alors du site. Miroir du `pushReplacement` mobile.
 */
export function remplacerEcran(router: {replace(href: string): void}, href: string): void {
    if (new URL(href, window.location.origin).pathname !== window.location.pathname) {
        skipNextNavigation();
    }
    router.replace(href);
}

/**
 * **Le clic d'un LIEN de retour qui remonte à l'écran précédent** — le lien
 * garde son `href` (il se partage, s'ouvre dans un onglet, et c'est le repli
 * sans historique), le clic simple fait `retourOuRepli`. Un clic modifié
 * (nouvel onglet, fenêtre) suit le lien, comme tout lien.
 */
export function clicDeRetour(
    router: {back(): void; replace(href: string): void},
    repli: string,
): (event: {
    metaKey: boolean;
    ctrlKey: boolean;
    shiftKey: boolean;
    button: number;
    preventDefault(): void;
}) => void {
    return (event) => {
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.button !== 0) return;
        event.preventDefault();
        retourOuRepli(router, repli);
    };
}

/**
 * **L'adresse d'une session lancée depuis un écran qui veut la voir revenir**
 * — le Plan, l'écran d'une étape, le Plan civique.
 *
 * 🛑 **Le retour fait de la session une SÉRIE** : `/sessions/[attemptId]` rend
 * alors le rapport de série complet (le même qu'une série hors Plan) et son
 * bouton principal « Continuer » ramène **à `retour`** — jamais la carte de
 * score d'un entraînement libre, jamais « Nouvel entraînement / Accueil ».
 * Aucune variante de rapport n'existe pour le Plan : c'est ce paramètre, posé
 * par le point de lancement, qui en tient lieu.
 *
 * `lot` : le numéro de série **servi**, quand le lanceur en a un (carte d'une
 * étape) — il ne sert qu'aux libellés (« Série 2 »).
 *
 * Miroir mobile : `AppRoutes.runnerDepuisPlan` (`from=plan`).
 */
export function sessionHref(
    attemptId: string,
    retour: string | null,
    lot?: number | null,
): string {
    const base = lot == null ? `/sessions/${attemptId}` : `/sessions/${attemptId}?lot=${lot}`;
    return withRetour(base, retour);
}

/** L'adresse de l'écran courant, pour la reposer en `retour`. Client seulement. */
export function adresseCourante(): string {
    return `${window.location.pathname}${window.location.search}`;
}

/**
 * **Les écrans d'un examen blanc** — runner QCM, session EE/EO, hub et bilan de
 * l'examen complet. Un `retour` qui en désigne un est refusé : le « Retour »
 * d'un bilan ne doit jamais rouvrir l'examen qu'il vient de clore.
 */
const ECRANS_D_EXAMEN = [
    /^\/sessions\//,
    /^\/entrainement\/tcf\/(ee|eo)\/session\//,
    /^\/examens-blancs\/tcf\/[^/]+/,
];

/**
 * **L'écran d'où un examen blanc a été lancé**, lu et validé, ou `null`.
 *
 * Le lanceur (`MockExamLauncher`, les feuilles de l'examen complet, le Plan)
 * pose l'adresse de l'écran courant en `?retour=` sur la première page de
 * l'examen ; chaque page de l'examen la fait suivre ; le bilan s'en sert pour
 * son lien « Retour ». 🛑 Même garde que `retourDe` (chemin interne, jamais
 * `//` ni `/\`), plus le refus des écrans d'examen. `null` (lien direct, ancien
 * lien, valeur trafiquée) ⇒ le bilan garde sa destination historique.
 *
 * Miroir mobile : `retourExamenDe` (`core/router/retour.dart`).
 */
export function retourExamenDe(params: {get(key: string): string | null}): string | null {
    const sur = retourDe(params);
    if (!sur) return null;
    const chemin = sur.split(/[?#]/)[0];
    return ECRANS_D_EXAMEN.some((motif) => motif.test(chemin)) ? null : sur;
}

/** Le hub d'un examen blanc TCF complet, avec l'écran de lancement à rejoindre. */
export function fullExamHubHref(examId: string, retour: string | null): string {
    return withRetour(`/examens-blancs/tcf/${examId}`, retour);
}

/** Le bilan d'un examen blanc TCF complet, avec l'écran de lancement à rejoindre. */
export function fullExamBilanHref(examId: string, retour: string | null): string {
    return withRetour(`/examens-blancs/tcf/${examId}/bilan`, retour);
}
