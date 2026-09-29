import type {EpreuveType, FullTcfExamSubAttempt} from "@/lib/types";

/**
 * Durées des épreuves TCF IRN — **source unique du web**.
 *
 * La règle du dépôt est simple : une durée affichée vient du backend. Le DTO la
 * porte (`FullTcfExamSubAttempt.timeLimitSeconds`) dès qu'un examen existe, et
 * c'est toujours lui qui fait foi. Reste les écrans **antérieurs à l'examen**
 * (briefing de lancement, vitrines de la liste d'examens blancs) : aucun objet
 * serveur n'y est encore disponible, donc la valeur y est repliée sur la table
 * ci-dessous, miroir déclaré **une seule fois**.
 *
 * ⚠️ Il n'y a plus de chrono global : le temps d'une épreuve ne se transfère
 * jamais à la suivante, et le total ci-dessous n'est qu'un **ordre de grandeur**
 * annoncé au candidat.
 */
export const EPREUVE_PLANNED_SEC: Record<
    "TCF_CO" | "TCF_CE" | "TCF_EE" | "TCF_EO",
    number
> = {
    TCF_CO: 1200,
    TCF_CE: 2100,
    TCF_EE: 1800,
    /** L'EO n'a **pas** de chrono d'épreuve : ce nombre est la somme des temps
     *  de parole de ses 3 tâches (180 + 210 + 210 s), purement indicatif. */
    TCF_EO: 600,
};

/** Ordre canonique + libellé/pictogramme des 4 épreuves d'un examen complet. */
export const EPREUVE_PRESENTATION: Record<
    "TCF_CO" | "TCF_CE" | "TCF_EE" | "TCF_EO",
    {icon: string; label: string; volume: string}
> = {
    TCF_CO: {icon: "🎧", label: "Compréhension orale", volume: "25 questions"},
    TCF_CE: {icon: "📖", label: "Compréhension écrite", volume: "25 questions"},
    TCF_EE: {icon: "✍️", label: "Expression écrite", volume: "3 tâches"},
    TCF_EO: {icon: "🎙️", label: "Expression orale", volume: "3 tâches"},
};

/** Somme indicative des 4 épreuves (~95 min). Recalculée, jamais écrite. */
export const FULL_TCF_EXAM_INDICATIVE_SEC = Object.values(EPREUVE_PLANNED_SEC).reduce(
    (total, sec) => total + sec,
    0,
);

/** « 35 min ». Arrondi à la minute — aucune épreuve n'a de secondes isolées. */
export function minutesLabel(sec: number): string {
    return `${Math.round(sec / 60)} min`;
}

/** L'oral ne s'annonce pas en minutes d'épreuve : il se chronomètre tâche par
 *  tâche, et le décompte ne part qu'au lancement de la tâche. Libellé unique. */
export const EO_PAR_TACHE_LABEL = "Chronométré par tâche";

/** Durée annoncée d'une épreuve **avant** qu'un examen existe (briefings). */
export function plannedEpreuveLabel(epreuve: keyof typeof EPREUVE_PLANNED_SEC): string {
    return epreuve === "TCF_EO"
        ? EO_PAR_TACHE_LABEL
        : minutesLabel(EPREUVE_PLANNED_SEC[epreuve]);
}

/** Durée d'une épreuve d'un examen en cours : le DTO d'abord, la table ensuite
 *  (une épreuve verrouillée ne porte pas de `timeLimitSeconds`). */
export function subAttemptDurationLabel(sub: FullTcfExamSubAttempt): string {
    if (sub.epreuve === "TCF_EO") return EO_PAR_TACHE_LABEL;
    if (sub.timeLimitSeconds != null) return minutesLabel(sub.timeLimitSeconds);
    const planned = EPREUVE_PLANNED_SEC[sub.epreuve as keyof typeof EPREUVE_PLANNED_SEC];
    return planned != null ? minutesLabel(planned) : "";
}

/**
 * Temps **conseillé** par tâche d'expression écrite, en minutes.
 *
 * 🛑 Aide au rythme, **jamais bloquante** : rien ne se ferme dessus, aucune
 * tâche n'est coupée. Le seul chrono réel de l'EE est celui de l'épreuve
 * (30 min sur les 3 tâches ensemble), servi par le backend. Ces trois nombres
 * sont éditoriaux — le serveur n'en publie aucun — et leur somme vaut le chrono
 * réel, pour ne jamais conseiller plus de temps qu'il n'en reste.
 */
export const EE_ADVISED_MINUTES_BY_TACHE: Record<number, number> = {
    1: 7,
    2: 10,
    3: 13,
};

export function eeAdvisedMinutesLabel(tacheNumero: number): string | null {
    const min = EE_ADVISED_MINUTES_BY_TACHE[tacheNumero];
    return min == null ? null : `≈ ${min} min conseillées`;
}

/** Décompte restant, en secondes, d'une échéance servie par le serveur. Null
 *  quand l'épreuve n'a pas encore été lancée : elle n'a alors aucune échéance,
 *  et on n'en invente pas une. */
export function secondsUntil(deadlineAt: string | null | undefined): number | null {
    if (!deadlineAt) return null;
    const ms = Date.parse(deadlineAt);
    if (Number.isNaN(ms)) return null;
    return Math.max(0, (ms - Date.now()) / 1000);
}

/** L'épreuve d'un examen complet, retrouvée dans ses sous-attempts. */
export function findSubAttempt(
    subs: readonly FullTcfExamSubAttempt[],
    epreuve: EpreuveType,
): FullTcfExamSubAttempt | null {
    return subs.find((sa) => sa.epreuve === epreuve) ?? null;
}
