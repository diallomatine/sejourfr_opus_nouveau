/**
 * Les **mots du niveau d'une épreuve** partagés par Réviser et le parcours —
 * **purs**, déclarés une fois pour tout le web.
 *
 * ⚠️ **Élagué le 2026-09-24** (écrans « Votre progression », « Vos résultats »,
 * « Ce qui a bougé » remplacés par `lib/progression.ts`), puis le 2026-10-03
 * (Navigation v2, phase 3) : « Où vous en êtes » quitte l'Accueil, et avec lui
 * `accueilEpreuve*`, `accueilEchelons*`, `accueilEvaluees*`,
 * `progresCiviqueScore`, `NON_MESURE_LABEL` et `ACCUEIL_*`.
 *
 * 🛑 **Le serveur n'expose que des faits.** Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/progres/progres_labels.dart`.
 */
import type {NiveauCecrl, TcfDomainProfileDto} from "./types";

/* ---------------------------------------------------------------------------
 * L'AUTORITÉ D'AFFICHAGE du niveau d'une épreuve
 * ------------------------------------------------------------------------- */

/**
 * **Le niveau ACTUEL d'une épreuve, tel qu'il est AFFICHÉ partout.**
 *
 * 🛑 **L'autorité d'affichage, et elle seule** : `tcfDomainProfile` publie le
 * niveau de `TcfProfileService.levelProfileAccueil` — la **moyenne des ≤ 3
 * derniers examens qualifiants** —, exactement ce que disent l'Accueil, le
 * Profil, le Diagnostic et Réviser. Les écrans de suivi lisaient
 * `DashboardCategoryStat.level`, une **troisième** autorité (le dernier niveau
 * CECRL de n'importe quelle soumission, **entraînements compris**) : un
 * candidat dont la seule trace EO était un entraînement de trois minutes y
 * lisait un palier pendant que tous les autres écrans disaient « à évaluer ».
 * → `docs/decisions/diagnostic.md`, 2026-09-16.
 *
 * 🛑 **`null` = pas mesuré, jamais un plancher** : la ligne retombe alors sur
 * ce que son écran sait **compter**.
 *
 * Le code de catégorie **est** la valeur de `epreuve` pour les quatre
 * épreuves : aucune table de correspondance n'est écrite ici. `TCF_STRUCTURE`
 * et les thèmes civiques n'y figurent pas — ils rendent `null`, ce qui est
 * exact : aucun palier CECRL ne leur est servi.
 *
 * 🛑 **Miroir de `niveauActuelEpreuve` côté mobile**
 * (`screens/progres/progres_labels.dart`).
 */
export function niveauActuelEpreuve(
    profil: TcfDomainProfileDto | null,
    code: string,
): NiveauCecrl | null {
    return profil?.domaines.find((d) => d.epreuve === code)?.niveau ?? null;
}

/** « 14 sept. » — une date courte, sans l'année. */
export function jourCourt(iso: string | null): string {
    if (!iso) return "—";
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}
