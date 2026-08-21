"use client";

import {BookOpen, FilePenLine, Headphones, Mic} from "lucide-react";
import type {ReactNode} from "react";
import {
    PLAN_DOMAIN_PRIORITY_LABEL,
    type PlanDomainPriority,
    type TargetLevel,
} from "@/lib/types";
import {type PlanDomainEpreuve, planDomainLabel} from "@/lib/plan-domain";
import styles from "./plan.module.css";

/**
 * Les briques visuelles propres au Plan adaptatif : icône de domaine, pastille
 * d'urgence, rail de paliers, points d'avancement.
 *
 * Elles vivent ici plutôt que dans `skill-ui/` parce qu'aucune d'elles n'a de
 * sens hors du Plan — et parce que `skill.module.css` est importé par vingt
 * fichiers : on n'y touche pas pour un écran.
 */

const DOMAIN_ICONS: Record<PlanDomainEpreuve, ReactNode> = {
    TCF_CO: <Headphones size={19} strokeWidth={1.9} />,
    TCF_CE: <BookOpen size={19} strokeWidth={1.9} />,
    TCF_EO: <Mic size={19} strokeWidth={1.9} />,
    TCF_EE: <FilePenLine size={19} strokeWidth={1.9} />,
};

/** Le carré coloré d'un domaine. `active` le remplit — réservé au domaine dont
 *  le Plan a fait sa priorité forte, jamais décoratif. */
export function PlanDomainIcon({
    epreuve,
    active,
    small,
}: {
    epreuve: PlanDomainEpreuve;
    active?: boolean;
    small?: boolean;
}) {
    return (
        <span
            className={`${styles.domainIcon} ${active ? styles.domainIconActive : ""} ${small ? styles.domainIconSmall : ""}`}
            role="img"
            aria-label={planDomainLabel(epreuve)}
        >
            {DOMAIN_ICONS[epreuve]}
        </span>
    );
}

/**
 * Ce que le Plan a décidé d'un domaine. **Le libellé vient de
 * `PLAN_DOMAIN_PRIORITY_LABEL`** (contrat gelé côté serveur), jamais d'une
 * chaîne recopiée ici.
 *
 * 🛑 Aucune des cinq valeurs ne nomme une faiblesse : `A_EVALUER` veut dire
 * « il manque des données ». Le ton des couleurs suit — rouge pour l'urgence,
 * neutre pour l'absence de mesure, jamais l'inverse.
 */
export function PlanDomainPriorityPill({priority}: {priority: PlanDomainPriority}) {
    return (
        <span className={styles.domainPill} data-priority={priority}>
            {priority === "FORTE" && <span className={styles.domainPillDot} aria-hidden />}
            {PLAN_DOMAIN_PRIORITY_LABEL[priority]}
        </span>
    );
}

const RAIL_LEVELS: readonly TargetLevel[] = ["A2", "B1", "B2"];

/**
 * Le rail A2 → B1 → B2. `current` est le palier que le **cycle construit**
 * (`cycle.targetLevel`), pas le niveau atteint : c'est ce que le candidat est
 * en train de bâtir.
 */
export function PlanLevelRail({current, dark}: {current: TargetLevel; dark?: boolean}) {
    const index = Math.max(0, RAIL_LEVELS.indexOf(current));
    return (
        <div className={`${styles.rail} ${dark ? styles.railDark : ""}`} aria-label={`Palier en construction : ${current}`}>
            {RAIL_LEVELS.map((level, i) => (
                <div key={level} className={styles.railCell}>
                    <span className={styles.railStep} data-state={i === index ? "current" : i < index ? "done" : "todo"}>
                        <span className={styles.railDot} aria-hidden />
                        <span className={styles.railLabel}>{level}</span>
                    </span>
                    {i < RAIL_LEVELS.length - 1 && (
                        <span className={styles.railLink} data-state={i < index ? "done" : "todo"} aria-hidden />
                    )}
                </div>
            ))}
        </div>
    );
}

/** Les points d'avancement d'une étape : **les compteurs servis**, jamais
 *  recomptés. `total === 0` (compréhension, qui n'a pas d'étape à cinq sujets)
 *  ⇒ rien du tout, plutôt qu'une rangée vide qui se lirait « 0 fait ». */
export function PlanDots({done, total}: {done: number; total: number}) {
    if (total <= 0) return null;
    return (
        <span className={styles.dots} aria-hidden>
            {Array.from({length: total}).map((_, i) => (
                <span key={i} data-on={i < done ? "1" : "0"} />
            ))}
        </span>
    );
}
