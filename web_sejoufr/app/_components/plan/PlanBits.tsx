"use client";

import Link from "next/link";
import {
    BookOpen,
    Check,
    ChevronRight,
    FilePenLine,
    Gauge,
    GraduationCap,
    Headphones,
    Lock,
    Mic,
    RefreshCw,
    ShieldCheck,
    Wrench,
    Zap,
} from "lucide-react";
import type {ReactNode} from "react";
import {track} from "@/lib/analytics";
import {useAuth} from "@/lib/auth-context";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import {
    canAccessModule,
    PLAN_ACTION_NATURE_LABEL,
    PLAN_DOMAIN_PRIORITY_LABEL,
    type PlanActionNature,
    type PlanCycleDto,
    type PlanDomainPriority,
    type PlanDomainTaskDto,
    type PlanRecentChangesDto,
    type TargetLevel,
} from "@/lib/types";
import {
    isComprehension,
    PLAN_BANNER_LABEL,
    PLAN_SKILLS_HREF,
    PLAN_SKILLS_TITLE,
    PLAN_DOMAIN_SECTION,
    PLAN_PATH_CURRENT_BADGE,
    type PlanDomainEpreuve,
    planBannerText,
    planDomainLabel,
    planPathStepMeta,
    planPathStepNote,
    planPathStepTitle,
    planRowStatusLabel,
    planTaskBadge,
    planTaskObservedLabel,
    type PlanRowStatus,
} from "@/lib/plan-domain";
import {withPlanStep} from "@/lib/plan-step";
import {RowChevron, SKILL_PREMIUM_HREF} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/**
 * Un cadenas du Plan qui renvoie au paiement, c'est LA mesure de conversion du
 * verrou freemium — et c'est ce que la table « Quel écran déclenche l'achat ? »
 * lit sous l'emplacement « Plan verrouillé ».
 *
 * 🛑 **Ne jamais inventer d'autre événement ici** : l'allowlist est doublée
 * côté serveur, tout le reste est rejeté. Déclarée ici plutôt que dans un
 * écran : les trois surfaces du Plan (priorité, séance, priorités groupées) la
 * posent, et trois copies auraient fini par mesurer trois choses.
 */
export function trackPremiumClick() {
    track("PREMIUM_CTA_CLICKED", {ctaLocation: "LOCKED_PLAN", screen: "plan"});
}

/** L'unique destination d'un cadenas du Plan, provenance suivie. */
export function usePremiumHref(): string {
    return useTrafficSourceHref(SKILL_PREMIUM_HREF);
}

/**
 * Le « tout voir » de « Mes priorités ».
 *
 * 🛑 **Aucun cadenas** (arbitrage du 2026-08-22, aligné sur le mobile et sur la
 * maquette) : le référentiel n'est ni une action ni un contenu premium, c'est
 * le **catalogue** et les **mesures** du candidat. Le verrou reste là où le
 * serveur le pose — sur chaque compétence et sur chaque sujet des écrans
 * d'arrivée. Ne pas réintroduire de verrou de navigation ici.
 */
export function AllSkillsLink() {
    return (
        <Link className={styles.blockAction} href={PLAN_SKILLS_HREF}>
            {PLAN_SKILLS_TITLE} <ChevronRight size={15} aria-hidden />
        </Link>
    );
}

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

/**
 * **« Plan actualisé »** — le bandeau de tête quand quelque chose a bougé.
 *
 * Il occupe **la place de `PlanFreeBar`**, jamais les deux à la fois : l'un dit
 * que le plan vient de changer, l'autre que certains accès sont fermés, et
 * empiler deux bandeaux au-dessus de la priorité repousserait l'action du jour
 * hors de l'écran.
 *
 * 🛑 **Miroir mot pour mot du mobile** (`PlanUpdatedBanner`,
 * `widgets/plan_banner.dart`) : mêmes mots, même destination
 * (`/plan/evolution`), même règle d'apparition. Le web n'avait pas ce bandeau —
 * un candidat dont le plan venait de se réordonner ne l'apprenait nulle part
 * tant qu'aucune **transition** n'était servie (la section « ce qui a changé »
 * ne s'affiche, elle, que sur de vraies transitions).
 *
 * ⚠️ **Rien n'est fabriqué** : l'appelant ne le rend que sur un `recentChanges`
 * non vide, et son absence est le cas normal.
 */
export function PlanUpdatedBanner({changes}: {changes: PlanRecentChangesDto}) {
    return (
        <Link className={`${styles.freeBar} ${styles.updatedBar}`} href="/plan/evolution">
            <RefreshCw size={15} strokeWidth={2.3} aria-hidden />
            <span className={styles.freeBarText}>
                <b>{PLAN_BANNER_LABEL}</b>
                <span> · {planBannerText(changes)}</span>
            </span>
            <span className={styles.freeBarCta} aria-hidden><ChevronRight size={16} /></span>
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

/**
 * **Le statut d'affichage d'une ligne de « Mes priorités »** — la nature de
 * l'action, sauf quand l'état agrégé de la compétence dit quelque chose de plus
 * précis (« Priorité », « Solide »). La règle vit dans `planRowStatus`, cette
 * pastille ne fait que la rendre.
 *
 * 🛑 **Deux teintes empruntées, pas inventées** : « Priorité » prend la teinte
 * de fragilité, « Solide » celle de la réussite — les mêmes que sur la fiche de
 * la compétence. Les quatre natures gardent les leurs, dont celle qui empêche
 * « à acquérir » de se lire « à renforcer ».
 *
 * ⚠️ **Miroir du mobile** (`planRowStatusLabel`, `PlanRowStatus.tone`).
 */
export function PlanRowStatusPill({status, level}: {
    status: PlanRowStatus;
    /** Le palier que porte le référentiel — « À acquérir · B1 ». **Un fait
     *  servi**, jamais déduit d'un code, et `null` quand il n'est pas publié :
     *  la pastille se lit alors sans lui plutôt qu'avec un palier inventé. */
    level: TargetLevel | null;
}) {
    return (
        <span className={styles.naturePill} data-status={status}>
            <span className={styles.naturePillIcon} aria-hidden>{ROW_STATUS_ICONS[status]}</span>
            {planRowStatusLabel(status, level)}
        </span>
    );
}

const ROW_STATUS_ICONS: Record<PlanRowStatus, ReactNode> = {
    PRIORITE: <Zap size={12} strokeWidth={2.4} />,
    A_RENFORCER: NATURE_ICONS.A_RENFORCER,
    A_ACQUERIR: NATURE_ICONS.A_ACQUERIR,
    A_VERIFIER: NATURE_ICONS.A_VERIFIER,
    SOLIDE: <Check size={12} strokeWidth={3} />,
    A_EVALUER: NATURE_ICONS.A_EVALUER,
};

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
