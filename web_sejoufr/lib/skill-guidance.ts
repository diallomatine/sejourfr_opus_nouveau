import type {SkillConstraintTagDto} from "./types";

/**
 * Règles de lecture du **guidage** d'un petit sujet (`checklist`,
 * `constraintTags`, `answerStarter`, `tip` — migration V026).
 *
 * Les quatre champs peuvent être `null` : un sujet créé depuis la console
 * d'administration naît sans guidage. Ces fonctions sont le **seul** endroit qui
 * décide ce qui s'affiche alors — deux écrans qui trancheraient chacun de leur
 * côté finiraient par se dégrader différemment. Elles sont pures et testées
 * (`skill-guidance.test.ts`), donc réutilisables par l'écrit comme par l'oral.
 *
 * Invariant : **rien de vide ne ressort**. Une chaîne blanche, un tableau vide
 * ou un `null` donnent tous le même résultat — l'absence — et l'appelant n'a
 * qu'un cas à traiter.
 */

/** Plafonds du contrat gelé. Le contenu publié les respecte déjà ; on les
 *  applique quand même, pour qu'une saisie admin trop généreuse déborde en
 *  base et non à l'écran. */
export const MAX_CHECKLIST_ITEMS = 4;
export const MAX_CONSTRAINT_TAGS = 3;

/** Sous-ensemble de `SkillPromptDto` dont dépend le guidage. Volontairement
 *  minimal : les tests n'ont pas à fabriquer un DTO complet pour vérifier une
 *  règle de dégradation. */
export interface SkillGuidanceSource {
    checklist?: string[] | null;
    constraintTags?: SkillConstraintTagDto[] | null;
    answerStarter?: string | null;
    tip?: string | null;
    recommendedMinWords?: number | null;
    recommendedMaxWords?: number | null;
    recommendedDurationSeconds?: number | null;
}

function cleanText(value: string | null | undefined): string | null {
    const trimmed = (value ?? "").trim();
    return trimmed ? trimmed : null;
}

/** Les gestes à accomplir, nettoyés et plafonnés. Vide = pas de check-list :
 *  l'appelant retombe sur la consigne du sujet. */
export function checklistOf(prompt: SkillGuidanceSource): string[] {
    const items = prompt.checklist ?? [];
    if (!Array.isArray(items)) return [];
    return items
        .map((item) => cleanText(item))
        .filter((item): item is string => item != null)
        .slice(0, MAX_CHECKLIST_ITEMS);
}

/** Les étiquettes de contrainte, nettoyées et plafonnées. Une étiquette sans
 *  libellé est retirée : une puce vide n'apprend rien et casse la rangée. */
export function constraintTagsOf(prompt: SkillGuidanceSource): SkillConstraintTagDto[] {
    const tags = prompt.constraintTags ?? [];
    if (!Array.isArray(tags)) return [];
    return tags
        .map((tag) => {
            const label = cleanText(tag?.label);
            return label ? {label, icon: tag.icon} : null;
        })
        .filter((tag): tag is SkillConstraintTagDto => tag != null)
        .slice(0, MAX_CONSTRAINT_TAGS);
}

/** L'amorce, ou `null`. L'appelant pose alors un texte grisé neutre — il ne
 *  laisse jamais le champ sans indication. */
export function answerStarterOf(prompt: SkillGuidanceSource): string | null {
    return cleanText(prompt.answerStarter);
}

/** L'astuce, ou `null`. Le mot « Astuce : » est ajouté à l'affichage, jamais
 *  stocké — le préfixer ici le ferait apparaître en double si le contenu le
 *  portait un jour. */
export function tipOf(prompt: SkillGuidanceSource): string | null {
    return cleanText(prompt.tip);
}

/** Rend une durée en toutes lettres pour la puce de longueur orale. */
function spellDuration(sec: number): string {
    if (sec < 60) return `${sec} secondes`;
    const minutes = Math.floor(sec / 60);
    const rest = sec % 60;
    if (rest === 0) return minutes === 1 ? "1 minute" : `${minutes} minutes`;
    return `${minutes} min ${rest}`;
}

/**
 * Puce de longueur, **dérivée des bornes déjà en base** — jamais dupliquée dans
 * `constraintTags` (contrat gelé). `≈ 15–35 mots` à l'écrit, `≈ 45 secondes` à
 * l'oral. `null` quand le sujet ne borne rien : on n'invente pas de repère.
 *
 * Ces bornes restent **indicatives** : elles s'affichent, elles ne bloquent
 * jamais la soumission (spec §8 règle 15).
 */
export function lengthChipLabel(prompt: SkillGuidanceSource, oral: boolean): string | null {
    if (oral) {
        const sec = prompt.recommendedDurationSeconds;
        return sec != null && sec > 0 ? `≈ ${spellDuration(sec)}` : null;
    }
    const min = prompt.recommendedMinWords;
    const max = prompt.recommendedMaxWords;
    if (min != null && max != null) return `≈ ${min}–${max} mots`;
    if (min != null) return `≈ ${min} mots minimum`;
    if (max != null) return `≈ ${max} mots maximum`;
    return null;
}
