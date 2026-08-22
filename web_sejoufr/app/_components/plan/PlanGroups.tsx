"use client";

import Link from "next/link";
import {useMemo, useState} from "react";
import {ChevronRight, Play, Sparkles, Target} from "lucide-react";
import {
    PLAN_GROUP_ASIDE_TITLE,
    PLAN_GROUP_ROWS_TITLE,
    PLAN_LOCKED_PRIORITY_LABEL,
    PLAN_LOCKED_SEANCE_LABEL,
    PLAN_SEANCE_EMPTY,
    PLAN_SEANCE_ROW_DONE_LABEL,
    PLAN_SEANCE_ROW_START,
    PLAN_SEANCE_TITLE,
    PLAN_STARTING,
    PLAN_SEANCE_WHY_CTA,
    isComprehension,
    PLAN_PRIORITY_ROWS_VISIBLE,
    planDomainHref,
    planGroupContextLine,
    planGroupMoreLabel,
    planItemMeta,
    planItemTitle,
    planPriorityGroupAction,
    planPriorityGroupCta,
    planPriorityGroupSummary,
    planPriorityGroups,
    planPriorityRowMeta,
    planSeanceFreeMeta,
    planSeanceGroupSummary,
    planSeanceGroupedMeta,
    planSeanceGroups,
    planSkillHref,
    type PlanPriorityGroup,
    type PlanPriorityGroupRow,
    type PlanSeanceGroup,
    type PlanSeanceGroupRow,
} from "@/lib/plan-domain";
import type {LearningPlanDto, LearningPlanPriorityDto} from "@/lib/types";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {RowChevron, SkillLockBadge} from "@/app/_components/skill-ui/SkillLayout";
import {PlanBlur, PlanRowStatusPill, trackPremiumClick, usePremiumHref} from "./PlanBits";
import {PlanEncart, PlanEncartDone, PlanEncartRow, PlanEncartStart} from "./PlanEncart";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";
import styles from "./plan.module.css";

/**
 * **« Aujourd'hui » et « Mes priorités », groupés par épreuve puis par tâche.**
 *
 * Les deux sections partagent la même brique (`PlanEncart`) et la même lecture :
 * fermé, un encart dit **où** le candidat travaille ; ouvert, il déroule **ce
 * qu'il y a à y faire**. Le regroupement lui-même vit dans `lib/plan-domain.ts`
 * — le composant ne décide de rien, il rend ce que le serveur a ordonné.
 *
 * 🛑 **Le verrou se lit sur le `locked` SERVI**, jamais sur le rang de la ligne
 * ou de l'encart : la compétence de la première place du Plan est ouverte quel
 * que soit son rang (`PlanFocusResolver`), et flouter par l'index cacherait du
 * contenu réellement accessible.
 */

/* --------------------------------------------------------------- séance */

/** Le premier encart ouvert : celui qui porte la prochaine ligne réellement
 *  faisable, sinon le premier — jamais un encart entièrement fermé. */
function firstOpenKey(groups: PlanSeanceGroup[]): string | null {
    const pending = groups.find((group) => group.rows.some((row) => !row.done && !row.locked));
    return (pending ?? groups.find((group) => !group.locked) ?? groups[0])?.key ?? null;
}

export function PlanSeanceCard({plan, onWhy}: {plan: LearningPlanDto; onWhy: () => void}) {
    const items = plan.seance.items;
    const groups = useMemo(() => planSeanceGroups(items), [items]);
    const [open, setOpen] = useState<string | null>(() => firstOpenKey(groups));

    const rows = groups.flatMap((group) => group.rows);
    const done = rows.filter((row) => row.done).length;
    const openRows = rows.filter((row) => !row.locked).length;
    const percent = items.length ? Math.round((done / items.length) * 100) : 0;
    const minutes = plan.seance.estimatedMinutes;
    /* 🛑 Le compteur est VRAI : « 1 entraînement gratuit sur 3 » ne s'affiche que
       si le serveur a réellement fermé le reste, et le nombre ouvert est celui
       qu'il a servi — jamais la constante de la maquette. */
    /* Des **épreuves**, pas des encarts : deux tâches d'une même épreuve font
       deux encarts et une seule épreuve. Miroir du mobile. */
    const epreuves = new Set(groups.map((group) => group.epreuve)).size;
    const meta = openRows < items.length
        ? planSeanceFreeMeta(openRows, items.length, minutes)
        : planSeanceGroupedMeta(epreuves, items.length, minutes);

    return (
        <section className={styles.seance} aria-labelledby="seance-title">
            <div className={styles.seanceHead}>
                <div>
                    <h2 id="seance-title">{PLAN_SEANCE_TITLE}</h2>
                    {items.length > 0 && <p>{meta}</p>}
                </div>
                {items.length > 0 && (
                    <span className={styles.seanceCount} data-done={done === items.length ? "1" : "0"}>
                        {done}/{items.length}
                    </span>
                )}
            </div>

            {items.length > 0 && (
                <div className={styles.seanceBar} role="presentation">
                    <span style={{width: `${percent}%`}} />
                </div>
            )}

            {items.length === 0 ? (
                <p className={styles.seanceEmpty}>{PLAN_SEANCE_EMPTY}</p>
            ) : (
                groups.map((group) => (
                    <SeanceGroup
                        key={group.key}
                        group={group}
                        open={open === group.key}
                        onToggle={() => setOpen(open === group.key ? null : group.key)}
                    />
                ))
            )}

            {/* Rien à expliquer sur une séance vide — miroir du mobile, qui ne
                rend cette ligne que sous une séance non vide. */}
            {items.length > 0 && (
                <button type="button" className={styles.seanceWhy} onClick={onWhy}>
                    <Sparkles size={16} aria-hidden />
                    <span>{PLAN_SEANCE_WHY_CTA}</span>
                    <ChevronRight size={16} aria-hidden />
                </button>
            )}
        </section>
    );
}

/**
 * Un encart de séance.
 *
 * **Les deux lanceurs vivent ici, pas sur chaque ligne** : un entraînement part
 * chez `usePlanExercise`, une **mesure de domaine** chez `usePlanAssessment` —
 * celui qui sert déjà « Compléter mon profil ». On lit `item.exercise === null`,
 * ce que le type impose, jamais la nullité d'un autre champ.
 */
function SeanceGroup({group, open, onToggle}: {
    group: PlanSeanceGroup;
    open: boolean;
    onToggle: () => void;
}) {
    const premiumHref = usePremiumHref();
    const exercises = usePlanExercise();
    const assessments = usePlanAssessment();
    const busy = exercises.starting || assessments.starting !== null;

    const startRow = (row: PlanSeanceGroupRow) => {
        if (row.item.exercise === null) {
            void assessments.start(row.item.assessment);
            return;
        }
        void exercises.startItem(row.item);
    };

    return (
        <div className={styles.seanceGroup}>
            <PlanEncart
                head={group}
                summary={planSeanceGroupSummary(group)}
                open={open}
                onToggle={onToggle}
                done={group.done}
                lockHref={group.locked ? premiumHref : undefined}
                onLockClick={group.locked ? trackPremiumClick : undefined}
                lockLabel={PLAN_LOCKED_SEANCE_LABEL}
            >
                <ul className={styles.encartRows}>
                    {/* 🛑 **La nature et la durée restent NETTES**, même
                        verrouillées : elles disent de quelle sorte d'action il
                        s'agit et combien elle prend, jamais ce qu'il y a à y
                        faire. Seul le titre passe derrière le rideau — et c'est
                        le titre RÉEL, jamais un décor. */}
                    {group.rows.map((row) => (
                        <PlanEncartRow
                            key={row.key}
                            done={row.done}
                            title={row.locked ? (
                                <>
                                    <span className={styles.srOnly}>{PLAN_LOCKED_SEANCE_LABEL}</span>
                                    <PlanBlur>{planItemTitle(row.item)}</PlanBlur>
                                </>
                            ) : planItemTitle(row.item)}
                            meta={planItemMeta(row.item)}
                            trailing={row.locked ? <SkillLockBadge />
                                : row.done ? <PlanEncartDone label={PLAN_SEANCE_ROW_DONE_LABEL} />
                                    : <PlanEncartStart label={PLAN_SEANCE_ROW_START} />}
                            href={row.locked ? premiumHref : undefined}
                            onLinkClick={row.locked ? trackPremiumClick : undefined}
                            onClick={row.locked ? undefined : () => startRow(row)}
                            disabled={busy}
                        />
                    ))}
                </ul>
            </PlanEncart>
            {(exercises.error ?? assessments.error) && (
                <p className={styles.milestoneError} role="alert">
                    {exercises.error ?? assessments.error}
                </p>
            )}
            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module="INTEGRAL"
                open={exercises.paywallOpen || assessments.paywallOpen}
                onClose={() => { exercises.closePaywall(); assessments.closePaywall(); }}
            />
        </div>
    );
}

/* ------------------------------------------------------------ priorités */

export function PlanPriorityGroups({plan, priorities}: {
    plan: LearningPlanDto;
    priorities: LearningPlanPriorityDto[];
}) {
    const groups = useMemo(() => planPriorityGroups(plan, priorities), [plan, priorities]);
    const [open, setOpen] = useState<string | null>(
        () => (groups.find((group) => !group.locked) ?? groups[0])?.key ?? null,
    );
    if (groups.length === 0) return null;
    return (
        <div className={styles.encartStack}>
            {groups.map((group) => (
                <PriorityGroup
                    key={group.key}
                    group={group}
                    open={open === group.key}
                    onToggle={() => setOpen(open === group.key ? null : group.key)}
                />
            ))}
        </div>
    );
}

function PriorityGroup({group, open, onToggle}: {
    group: PlanPriorityGroup;
    open: boolean;
    onToggle: () => void;
}) {
    const premiumHref = usePremiumHref();
    const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
    const action = planPriorityGroupAction(group);
    /* 🛑 Le plafond d'affichage vit ICI, à côté du compteur qu'il alimente :
       tronquer le groupe à la source rendrait le « + N autres » faux par
       construction, et ferait perdre en silence ce qui dépasse. */
    const visible = group.rows.slice(0, PLAN_PRIORITY_ROWS_VISIBLE);
    const hidden = group.rows.length - visible.length;

    return (
        <div className={styles.encartCard} data-open={open && !group.locked ? "1" : "0"}>
            <PlanEncart
                head={group}
                summary={planPriorityGroupSummary(group)}
                open={open}
                onToggle={onToggle}
                lockHref={group.locked ? premiumHref : undefined}
                onLockClick={group.locked ? trackPremiumClick : undefined}
                lockLabel={PLAN_LOCKED_PRIORITY_LABEL}
            >
                <div className={styles.encartSplit}>
                    <div className={styles.encartAside}>
                        <p className={styles.encartEyebrow}>{PLAN_GROUP_ASIDE_TITLE}</p>
                        <p className={styles.encartAsideTitle}>{group.label}</p>
                        <p className={styles.encartAsideText}>{planGroupContextLine(group)}</p>
                        {action && (
                            <PriorityGroupCta
                                row={action}
                                premiumHref={premiumHref}
                                starting={starting}
                                onStart={() => {
                                    const exercise = action.priority?.recommendedExercise;
                                    if (exercise) void start(exercise);
                                }}
                            />
                        )}
                    </div>
                    <div className={styles.encartRowsBlock}>
                        <p className={styles.encartEyebrow}>{PLAN_GROUP_ROWS_TITLE}</p>
                        <ul className={styles.encartRows}>
                            {visible.map((row) => (
                                <PriorityRow key={row.skillId} row={row} premiumHref={premiumHref} />
                            ))}
                        </ul>
                        {/* `hidden === 0` ⇒ aucun lien : on n'annonce jamais un
                            reste qui n'existe pas. La fiche du domaine porte le
                            référentiel complet de l'épreuve. */}
                        {hidden > 0 && (
                            <Link className={styles.encartMore} href={planDomainHref(group.epreuve)}>
                                {planGroupMoreLabel(hidden)} <ChevronRight size={15} aria-hidden />
                            </Link>
                        )}
                    </div>
                </div>
            </PlanEncart>
            {error && <p className={styles.milestoneError} role="alert">{error}</p>}
            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module="INTEGRAL"
                open={paywallOpen}
                onClose={closePaywall}
            />
        </div>
    );
}

/**
 * Le bouton d'un encart de priorités.
 *
 * **Deux gestes, parce que deux parcours** : une compétence de compréhension se
 * **démarre** (série ciblée, un `TRAINING` ordinaire), une compétence
 * d'expression s'**ouvre** sur sa fiche d'étape. Fermée, elle mène à l'offre —
 * même chemin et même mesure que tous les autres cadenas du Plan.
 */
function PriorityGroupCta({row, premiumHref, starting, onStart}: {
    row: PlanPriorityGroupRow;
    premiumHref: string;
    starting: boolean;
    onStart: () => void;
}) {
    const label = planPriorityGroupCta(row);
    /* Une série ne se lance que si le serveur en a désigné une : une compétence
       de compréhension seulement observée n'en porte aucune, et sa fiche de
       domaine est alors la bonne destination. */
    const series = isComprehension(row.section)
        && (row.priority?.recommendedExercise ?? null) !== null;

    if (row.locked) {
        return (
            <Link className={styles.encartCta} href={premiumHref} onClick={trackPremiumClick}>
                <Target size={15} aria-hidden /> {label}
            </Link>
        );
    }
    if (series) {
        return (
            <button type="button" className={styles.encartCta} disabled={starting} onClick={onStart}>
                <Play size={15} aria-hidden /> {starting ? PLAN_STARTING : label}
            </button>
        );
    }
    return (
        <Link className={styles.encartCta} href={planSkillHref(row, {planStep: true})}>
            <Target size={15} aria-hidden /> {label}
        </Link>
    );
}

/**
 * Une ligne de priorité.
 *
 * **Ce que le verrou ferme** : le titre de la compétence et son avancement.
 * **Ce qui reste net** : la nature de l'action et son palier — c'est
 * précisément ce qui empêche « à acquérir » de se lire « à renforcer », et ça
 * reste vrai pour tout le monde.
 */
function PriorityRow({row, premiumHref}: {row: PlanPriorityGroupRow; premiumHref: string}) {
    return (
        <PlanEncartRow
            title={row.locked ? (
                <>
                    <span className={styles.srOnly}>{PLAN_LOCKED_PRIORITY_LABEL}</span>
                    <PlanBlur>{row.title}</PlanBlur>
                </>
            ) : row.title}
            meta={planPriorityRowMeta(row)}
            trailing={(
                <span className={styles.encartRowAside}>
                    <PlanRowStatusPill status={row.status} level={row.level} />
                    {row.locked ? <SkillLockBadge /> : <RowChevron />}
                </span>
            )}
            href={row.locked ? premiumHref : planSkillHref(row, {planStep: true})}
            onLinkClick={row.locked ? trackPremiumClick : undefined}
        />
    );
}
