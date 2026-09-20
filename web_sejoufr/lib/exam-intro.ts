/**
 * La **copie du sas d'examen** — ce qu'on annonce avant de lancer une épreuve,
 * déclaré une fois pour tout le web.
 *
 * 🛑 **Extrait à la 2ᵉ surface (2026-09-13).** Ces phrases vivaient dans la
 * page des examens blancs de module et dans celle des examens de production ;
 * le **diagnostic TCF** en a maintenant besoin, parce qu'une de ses sections
 * **est** un examen blanc de son épreuve et doit s'annoncer pareil. Trois
 * copies écrites à la main auraient fini par décrire trois examens différents.
 *
 * 🛑 **Aucune durée ni aucun volume n'est écrit ici** : ils arrivent en
 * paramètres — de la table de référence (`lib/exam-durations.ts`) pour un
 * examen qui n'existe pas encore, du DTO servi pour une section de diagnostic
 * déjà composée. Un chiffre en dur ici mentirait sur l'une des deux surfaces.
 */
import type {ExamFact} from "@/app/_components/hub/ExamIntroSheet";
import type {EpreuveType, QuestionType} from "./types";

export interface ExamIntroCopy {
    facts: ExamFact[];
    tips: string[];
}

/**
 * Le sas d'une épreuve de **compréhension** (CO ou CE).
 *
 * @param questionsLabel nombre de questions, **servi** ou lu dans la table
 * @param durationLabel  durée de l'épreuve, même règle
 */
export function comprehensionExamIntro(
    questionType: QuestionType | "CO" | "CE",
    questionsLabel: string,
    durationLabel: string,
): ExamIntroCopy {
    return {
        facts: [
            {label: "questions (A2→B2)", value: questionsLabel},
            {label: "en conditions réelles", value: durationLabel},
            // 🛑 Score de PROGRESSION, pas le barème du relevé TCF — le
            // relevé officiel a une échelle que nous n'avons pas. Le pondéré
            // interne, lui, n'est affiché nulle part.
            {label: "score de progression + niveau", value: "/499"},
        ],
        tips:
            questionType === "CO"
                ? [
                      "L'audio se lance seul et ne se joue qu'une seule fois, comme le jour J — prévoyez un casque.",
                      "Pas de retour en arrière sur les questions d'écoute.",
                      "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
                  ]
                : [
                      "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
                      "Le chronomètre tourne et l'examen se termine automatiquement à la fin du temps.",
                      "Vous pouvez naviguer librement entre les questions.",
                  ],
    };
}

/**
 * Le sas d'une épreuve de **production** (EE ou EO), ses 3 tâches enchaînées.
 *
 * @param timingLabel / `timingValue` le couple déjà servi par la config
 *                    d'épreuve (« en conditions réelles · 30 min » à l'écrit,
 *                    « chrono par tâche » à l'oral).
 */
export function productionExamIntro(
    epreuve: EpreuveType | "TCF_EE" | "TCF_EO",
    timingLabel: string,
    timingValue: string,
): ExamIntroCopy {
    const oral = epreuve === "TCF_EO";
    return {
        facts: [
            {label: "tâches enchaînées", value: "3"},
            {label: timingLabel, value: timingValue},
            {label: "note + niveau CECRL", value: "/20"},
        ],
        tips: [
            oral
                ? "Autorisez le micro : chaque tâche s'enregistre, comme le jour J."
                : "Vous rédigez directement les 3 productions, un brouillon est sauvegardé.",
            oral
                ? "Lisez la consigne sans pression : le chrono d'une tâche ne part que lorsque vous la lancez."
                : "Le chrono porte sur les 3 tâches ensemble ; le temps conseillé par tâche n'est qu'un repère.",
            "Les 3 tâches sont évaluées par l'IA après l'examen.",
            "Le niveau final est le plancher de vos 3 tâches.",
        ],
    };
}
