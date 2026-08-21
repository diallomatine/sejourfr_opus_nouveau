"use client";

import Link from "next/link";
import {BookOpen, Check, FilePenLine, Headphones, Lock, Mic} from "lucide-react";
import type {ReactNode} from "react";
import {useAuth} from "@/lib/auth-context";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import {
    canAccessModule,
    PLAN_DOMAIN_PRIORITY_LABEL,
    type PlanCycleDto,
    type PlanDomainPriority,
    type PlanDomainTaskDto,
    type TargetLevel,
} from "@/lib/types";
import {
    isComprehension,
    PLAN_DOMAIN_SECTION,
    PLAN_PATH_CURRENT_BADGE,
    type PlanDomainEpreuve,
    planDomainLabel,
    planPathStepMeta,
    planPathStepNote,
    planPathStepTitle,
} from "@/lib/plan-domain";
import {RowChevron, SKILL_PREMIUM_HREF} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/**
 * Les briques visuelles propres au Plan adaptatif : icône de domaine, pastille
 * d'urgence, rail de paliers, points d'avancement.
 *
 * Elles vivent ici plutôt que dans `skill-ui/` parce qu'aucune d'elles n'a de
 * sens hors du Plan — et parce que `skill.module.css` est importé par vingt
 * fichiers : on n'y touche pas pour un écran.
 */

/**
 * La barre « Version gratuite » en tête de l'écran — à la place qu'occuperait,
 * chez un abonné, une bannière « Plan actualisé » (non construite dans cette
 * passe). Elle ne masque rien : le Plan reste entièrement visible, elle ne
 * fait qu'annoncer que certains accès sont premium.
 *
 * 🛑 **Miroir mot pour mot du mobile** (`PlanFreeBar`,
 * `mobile_sejourfr/lib/screens/plan/widgets/plan_banner.dart`) — pas le texte
 * de la maquette (« 1 exercice par jour »), qui décrit une règle que ce
 * produit n'a pas.
 *
 * 🛑 **Aucun second chemin d'abonnement** : même destination
 * (`SKILL_PREMIUM_HREF`, provenance suivie) et même mesure de conversion que
 * les autres cadenas du Plan — l'appelant passe le même `onPremiumClick`
 * (`DIAGNOSTIC_TO_PREMIUM_CLICKED`) que `PlanPaywallCard`.
 *
 * Se masque elle-même dès que le compte a l'accès TCF — l'appelant n'a pas à
 * vérifier `canAccessModule` avant de la rendre.
 */
export const PLAN_FREE_BAR_TITLE = "Version gratuite";
export const PLAN_FREE_BAR_TEXT = "certains entraînements demandent l'abonnement";
export const PLAN_FREE_BAR_CTA = "Débloquer";

export function PlanFreeBar({onPremiumClick}: {
    /** Mesure de conversion du verrou, partagée avec les autres cadenas du Plan. */
    onPremiumClick: () => void;
}) {
    const {user} = useAuth();
    const premiumHref = useTrafficSourceHref(SKILL_PREMIUM_HREF);

    if (canAccessModule(user, "TCF")) return null;

    return (
        <Link className={styles.freeBar} href={premiumHref} onClick={onPremiumClick}>
            <Lock size={15} strokeWidth={2.3} aria-hidden />
            <span className={styles.freeBarText}>
                <b>{PLAN_FREE_BAR_TITLE}</b>
                <span> · {PLAN_FREE_BAR_TEXT}</span>
            </span>
            <span className={styles.freeBarCta}>{PLAN_FREE_BAR_CTA}</span>
        </Link>
    );
}

const DOMAIN_ICONS: Record<PlanDomainEpreuve, ReactNode> = {
    TCF_CO: <Headphones size={19} strokeWidth={1.9} />,
    TCF_CE: <BookOpen size={19} strokeWidth={1.9} />,
    TCF_EO: <Mic size={19} strokeWidth={1.9} />,
    TCF_EE: <FilePenLine size={19} strokeWidth={1.9} />,
};

/**
 * Le carré coloré d'un domaine. `active` le remplit — réservé au domaine dont
 * le Plan a fait sa priorité forte, jamais décoratif.
 *
 * **La teinte suit la FAMILLE du domaine** : compréhension en bleu (CO, CE),
 * expression en rouge (EO, EE), comme la maquette. Elle se dérive de
 * `PLAN_DOMAIN_SECTION` via `isComprehension` — l'autorité qui sépare déjà les
 * deux familles partout ailleurs — et **jamais** d'une seconde table de
 * couleurs à tenir à jour.
 *
 * ⚠️ À ne pas confondre avec `--skill-accent`, l'accent du **module
 * Compétences**, qui est bleu pour EE comme pour EO : c'est un autre écran et
 * une autre décision.
 */
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
            data-tone={planDomainTone(epreuve)}
            role="img"
            aria-label={planDomainLabel(epreuve)}
        >
            {DOMAIN_ICONS[epreuve]}
        </span>
    );
}

/** Bleu pour la compréhension, rouge pour l'expression. Aucune couleur n'est
 *  écrite ici : le CSS lit ce jeton et va chercher les tokens de la charte. */
function planDomainTone(epreuve: PlanDomainEpreuve): "comprehension" | "expression" {
    return isComprehension(PLAN_DOMAIN_SECTION[epreuve]) ? "comprehension" : "expression";
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

/**
 * Le verrou freemium de la maquette : le contenu **réel** du candidat, rendu
 * illisible tant que son accès n'est pas ouvert.
 *
 * 🛑 **Rien n'est fabriqué pour remplir le flou** — ce sont les lignes que le
 * serveur a réellement servies, et l'abonnement les révèle telles quelles. Un
 * décor sous le flou serait un mensonge que le déverrouillage démentirait.
 *
 * Illisible à l'œil **et** au lecteur d'écran : `aria-hidden` le sort de
 * l'arbre d'accessibilité, `inert` le rend en plus non focusable et hors du
 * parcours clavier. Sans les deux, le contenu verrouillé resterait lisible en
 * synthèse vocale — à la fois un contournement et un mensonge d'accessibilité.
 * Le flou n'est donc jamais la protection : il est la mise en scène.
 *
 * ⚠️ **L'information nette vit HORS de ce bloc** (le badge de verrou, le
 * libellé lu par un lecteur d'écran) : ce qui reste vrai pour tout le monde ne
 * se floute pas.
 */
export function PlanBlur({children}: {children: ReactNode}) {
    return (
        <span className={styles.blur} aria-hidden inert>
            {children}
        </span>
    );
}

/* --------------------------------------------------------------- le chemin */

/**
 * **Le chemin de palier**, servi par `cycle.path` — la même liste sur le Plan
 * et sur « Votre programme évolue ». Extraite à la **2ᵉ occurrence** : les deux
 * écrans en portaient une copie, et la note du gate n'en aurait alors touché
 * qu'un seul.
 *
 * 🛑 **Rien n'est décidé ici** : l'ordre, le statut de chaque étape et le palier
 * concerné viennent du serveur. Le front n'apporte que la phrase — dont celle
 * qui manquait au candidat : **un palier se confirme par un examen blanc TCF
 * complet** (`planPathStepNote`). C'est ce que réclame
 * `cycle.state === "READY_FOR_GATE_MOCK"`, et le jalon correspondant est servi
 * à côté (`LearningPlanDto.milestone`).
 */
export function PlanPathList({cycle, titleId}: {cycle: PlanCycleDto; titleId?: string}) {
    if (cycle.path.length === 0) return null;
    return (
        <ol className={styles.pathList} aria-labelledby={titleId}>
            {cycle.path.map((step, index) => {
                const note = planPathStepNote(step, cycle);
                return (
                    <li key={`${step.kind}-${step.level ?? index}`} data-status={step.status}>
                        <span className={styles.pathMark} aria-hidden>
                            {step.status === "DONE" ? <Check size={13} strokeWidth={3} /> : index + 1}
                        </span>
                        <span className={styles.pathBody}>
                            <span className={styles.pathTitle}>
                                {planPathStepTitle(step)}
                                {step.status === "CURRENT" && (
                                    <span className={styles.pathBadge}>{PLAN_PATH_CURRENT_BADGE}</span>
                                )}
                            </span>
                            <span className={styles.pathMeta}>{planPathStepMeta(step, cycle)}</span>
                            {note && <span className={styles.pathNote}>{note}</span>}
                        </span>
                    </li>
                );
            })}
        </ol>
    );
}

/* ------------------------------------------------------ tâche d'expression */

/**
 * Une **tâche d'expression** et sa couverture en compétences observées. Elle
 * ouvre la liste des huit compétences de la tâche — l'écran qui existe déjà
 * (« Réviser → épreuve → Compétences ») : aucune seconde UX n'est créée.
 *
 * « 3 / 8 observées » **n'est pas une note** : une compétence non observée est
 * une compétence que le candidat n'a pas encore eu l'occasion de montrer, et le
 * dénominateur vient de la base.
 */
export function PlanTaskRow({
    tache,
    epreuve,
}: {
    tache: PlanDomainTaskDto;
    epreuve: PlanDomainEpreuve;
}) {
    const section = epreuve === "TCF_EO" ? "eo" : "ee";
    return (
        <li>
            <Link
                className={styles.panelRow}
                href={`/entrainement/tcf/${section}/tache/${tache.tacheNumero}/competences`}
            >
                <span className={styles.levelBadge}>{tache.tacheNumero}</span>
                <span className={styles.panelBody}>
                    <span className={styles.panelTitle}>Tâche {tache.tacheNumero}</span>
                    <span className={styles.panelMeta}>
                        {tache.observedSkills} / {tache.totalSkills} compétences observées
                    </span>
                </span>
                <span className={styles.taskCount}>{tache.taskCode}</span>
                <RowChevron />
            </Link>
        </li>
    );
}
