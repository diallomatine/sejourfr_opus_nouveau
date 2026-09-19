/**
 * **Le format de l'examen civique, et il vient de la loi.**
 *
 * 🛑 Miroir mot pour mot de `mobile_sejourfr/lib/core/utils/civique_examen.dart`
 * et de `backend_sejourfr/.../enums/CivicExamFormat.java`, qui est l'autorité.
 *
 * Source de droit : **arrêté du 10 octobre 2025** relatif au programme, aux
 * épreuves et aux modalités d'organisation de l'examen civique — JORF n° 0240
 * du 12 octobre 2025, NOR **INTV2527907A**, article 3 et annexe I.
 *
 * 🛑 **Ce n'est pas un réglage produit.** Ces valeurs ne se négocient pas, ne se
 * configurent pas, et ne se lisent surtout pas depuis un `ExamTemplate` : un
 * template est une **fiche d'offre**, pas l'autorité du format. L'écran
 * `examens-blancs` lisait `civiqueTemplate?.durationSeconds ?? 2400` — soit
 * **40 minutes** en repli, là où l'arrêté en fixe **45**. Un repli en dur qui
 * contredit la loi de cinq minutes, c'est la loi écrite à un endroit qui n'est
 * pas son autorité.
 *
 * ⚠️ **Ce qui n'est PAS ici, et ne doit pas y venir** : le quota par unité
 * officielle (Devise et symboles 3, Laïcité 2, …) et les totaux par thématique
 * (11 / 6 / 11 / 8 / 4). Le premier vit dans `civic_official_units` côté
 * serveur ; les seconds ne sont déclarés **nulle part** et se dérivent par
 * somme. Un front n'a besoin d'aucun des deux : il affiche un examen, il ne le
 * compose pas.
 */

/** Questions d'un examen civique réel. */
export const CIVIQUE_EXAM_QUESTIONS = 40;

/** Bonnes réponses exigées pour réussir (80 %). */
export const CIVIQUE_EXAM_SEUIL = 32;

/** Durée maximale de l'épreuve, en secondes. */
export const CIVIQUE_EXAM_DUREE_SECONDES = 45 * 60;

/** Durée maximale de l'épreuve, en minutes — ce que l'écran affiche. */
export const CIVIQUE_EXAM_DUREE_MINUTES = 45;

/**
 * L'examen de **thème** : un format **SejourFR**, jamais un format officiel.
 * L'examen réel porte sur les cinq thématiques à la fois.
 */
export const CIVIQUE_THEME_EXAM_QUESTIONS = 20;

/** Bonnes réponses exigées sur un examen de thème (80 %, comme l'officiel). */
export const CIVIQUE_THEME_EXAM_SEUIL = 16;

/** Durée d'un examen de thème, en minutes. */
export const CIVIQUE_THEME_EXAM_DUREE_MINUTES = 20;
