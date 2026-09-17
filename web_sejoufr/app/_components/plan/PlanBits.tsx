"use client";

import Link from "next/link";
import {
    BadgeCheck,
    BookOpen,
    Check,
    FilePenLine,
    Gauge,
    GraduationCap,
    Headphones,
    Mic,
    ShieldCheck,
    Wrench,
    type LucideIcon,
} from "lucide-react";
import type {ReactNode} from "react";
import {
    PLAN_ACTION_NATURE_LABEL,
    PLAN_DOMAIN_PRIORITY_LABEL,
    type PlanActionNature,
    type PlanCycleDto,
    type PlanDomainPriority,
    type PlanDomainTaskDto,
    type SkillSection,
    type TargetLevel,
} from "@/lib/types";
import {
    isComprehension,
    PLAN_DOMAIN_SECTION,
    type PlanDomainEpreuve,
    type PlanNowVue,
    planDomainLabel,
    planTaskBadge,
    planTaskObservedLabel,
} from "@/lib/plan-domain";
import {withPlanStep} from "@/lib/plan-step";
import {RowChevron} from "@/app/_components/skill-ui/SkillLayout";
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

/**
 * L'icône d'un domaine, **en composant** — ce que le kit (`NowCard`) attend.
 *
 * 🛑 Déclarée ici, et plus dans `LearningPlanView` : la carte « À faire
 * maintenant » existe sur **deux** écrans (le Plan et l'Accueil), et une
 * seconde table aurait fini par leur donner deux icônes pour la même action.
 * `lib/plan-domain.ts` reste sans React, d'où la traduction ici et pas là-bas.
 */
export const PLAN_SECTION_ICON: Record<SkillSection, LucideIcon> = {
    CO: Headphones,
    CE: BookOpen,
    EO: Mic,
    EE: FilePenLine,
};

/** L'icône de la carte « À faire maintenant » : le domaine réellement lancé —
 *  celui de la **mesure** quand elle passe devant — ou la marque de
 *  vérification quand la série vient de se terminer. */
export function planNowIcon(vue: PlanNowVue): LucideIcon {
    return vue.nature === "VERIFICATION" ? BadgeCheck : PLAN_SECTION_ICON[vue.section];
}

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

/**
 * **Ce que le Plan demande de faire sur cette ligne** — la pastille d'une carte
 * « Aujourd'hui » et d'une ligne de « Mes priorités ».
 *
 * 🛑 **Le libellé vient de `PLAN_ACTION_NATURE_LABEL`** (contrat gelé côté
 * serveur par `SkillLabelsTest`), jamais d'une chaîne recopiée ici.
 *
 * 🛑 **« À acquérir » ne peut pas se lire « à renforcer » :** les deux natures
 * ont un **libellé** distinct, une **icône** distincte et une **teinte**
 * distincte. Une compétence à acquérir n'a rien d'observé — la teinte de
 * fragilité (rouge) lui est donc interdite, et l'icône dit *apprendre*, pas
 * *réparer*.
 *
 * ⚠️ À ne pas confondre avec `PlanDomainPriorityPill`, qui qualifie un
 * **domaine** (une des quatre lignes du profil TCF) et jamais une action.
 * `SkillMasteryPill`, lui, dit l'état **agrégé** d'une compétence sur sa fiche.
 * Trois grains, trois endroits.
 */
const NATURE_ICONS: Record<PlanActionNature, ReactNode> = {
    A_EVALUER: <Gauge size={12} strokeWidth={2.4} />,
    A_RENFORCER: <Wrench size={12} strokeWidth={2.4} />,
    A_VERIFIER: <ShieldCheck size={12} strokeWidth={2.4} />,
    A_ACQUERIR: <GraduationCap size={12} strokeWidth={2.4} />,
};

export function PlanNaturePill({nature}: {nature: PlanActionNature}) {
    return (
        <span className={styles.naturePill} data-nature={nature}>
            <span className={styles.naturePillIcon} aria-hidden>{NATURE_ICONS[nature]}</span>
            {PLAN_ACTION_NATURE_LABEL[nature]}
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
    title,
}: {
    tache: PlanDomainTaskDto;
    epreuve: PlanDomainEpreuve;
    /** Le **titre éditorial** de la tâche, quand l'écran a la place de le dire
     *  (« Ma progression »). Par défaut la ligne se contente de son rang :
     *  dans une colonne latérale, le titre pousserait le compteur hors du
     *  cadre. Le numéro reste porté par la pastille dans les deux cas. */
    title?: string;
}) {
    const section = epreuve === "TCF_EO" ? "eo" : "ee";
    /* Le même marqueur que les étapes : sa seule présence dit « on arrive du
       Plan ». Sans lui, la liste des 8 compétences de la tâche affichait son
       retour hiérarchique (« ← Expression orale » → `/entrainement/tcf/eo`) et
       éjectait du Plan un candidat qui venait d'y cliquer. */
    return (
        <li>
            <Link
                className={styles.panelRow}
                href={withPlanStep(
                    `/entrainement/tcf/${section}/tache/${tache.tacheNumero}/competences`,
                )}
            >
                <span className={styles.levelBadge}>{tache.tacheNumero}</span>
                <span className={styles.panelBody}>
                    <span className={styles.panelTitle}>
                        {title ?? planTaskBadge(tache.tacheNumero)}
                    </span>
                    <span className={styles.panelMeta}>{planTaskObservedLabel(tache)}</span>
                </span>
                <span className={styles.taskCount}>{tache.taskCode}</span>
                <RowChevron />
            </Link>
        </li>
    );
}
