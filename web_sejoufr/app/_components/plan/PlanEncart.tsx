"use client";

import Link from "next/link";
import {Check, ChevronDown, ChevronRight} from "lucide-react";
import {useId, type ReactNode} from "react";
import {planTaskBadge, type PlanGroupHead} from "@/lib/plan-domain";
import {PlanDomainIcon} from "./PlanBits";
import {SkillLockBadge} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/**
 * **L'encart rétractable « épreuve → tâche »** du Plan — la brique commune de
 * « Aujourd'hui » et de « Mes priorités ».
 *
 * Fermé, il dit **où** le candidat travaille : l'icône de son domaine, le nom de
 * l'épreuve, la tâche, et une ligne de résumé. Ouvert, il déroule **ce qu'il y a
 * à y faire**. C'est la même anatomie des deux côtés — deux copies auraient fini
 * par se replier différemment.
 *
 * 🛑 **C'est un vrai bouton**, avec `aria-expanded` et `aria-controls` : le
 * `div` cliquable de la maquette est inatteignable au clavier. Le panneau n'est
 * monté **que lorsqu'il est ouvert** — rien de replié ne reste dans le parcours
 * de tabulation.
 *
 * ⚠️ **Verrouillé, il ne se déplie pas** : il porte un cadenas **à la place du
 * chevron** et mène à l'offre, par le même chemin et la même mesure que tous les
 * autres verrous du Plan. Ce n'est pas un contenu masqué de plus — ce sont les
 * lignes qu'il contient qui sont fermées, et le serveur l'a déjà dit sur
 * chacune.
 */
export function PlanEncart({
    head,
    summary,
    open,
    onToggle,
    done,
    lockHref,
    onLockClick,
    lockLabel,
    children,
}: {
    head: PlanGroupHead;
    summary: string;
    open: boolean;
    onToggle: () => void;
    /** Toutes les lignes sont faites : l'encart s'estompe et se coche. */
    done?: boolean;
    /** Renseigné ⇒ l'encart est **fermé par le serveur** et mène à l'offre. */
    lockHref?: string;
    onLockClick?: () => void;
    lockLabel?: string;
    children: ReactNode;
}) {
    /* 🛑 `useId` et pas la clé du groupe : la même tâche peut porter un encart
       dans « Aujourd'hui » ET un dans « Mes priorités » — deux `id` identiques
       sur la page, et `aria-controls` désignerait le mauvais panneau. */
    const panelId = useId();
    const inner = (
        <>
            <PlanDomainIcon epreuve={head.epreuve} active={open && !done} />
            <span className={styles.encartHeadBody}>
                <span className={styles.encartTitleRow}>
                    <span className={styles.encartTitle}>{head.label}</span>
                    {head.taskNumber !== null && (
                        <span className={styles.encartTaskPill} data-tone={(head.taskNumber - 1) % 3}>
                            {planTaskBadge(head.taskNumber)}
                        </span>
                    )}
                    {/* Sans tâche : le repère du groupe — son niveau, le
                        parcours qu'ouvre une mesure, ou « Jalon ». `null` est
                        un cas normal : on n'invente alors aucune pastille. */}
                    {head.taskNumber === null && head.context !== null && (
                        <span className={styles.encartContextPill}>{head.context}</span>
                    )}
                </span>
                <span className={styles.encartSummary}>{summary}</span>
            </span>
        </>
    );

    if (lockHref) {
        return (
            <div className={styles.encart}>
                <Link className={styles.encartHead} href={lockHref} onClick={onLockClick}>
                    {inner}
                    {lockLabel && <span className={styles.srOnly}>{lockLabel}</span>}
                    <SkillLockBadge />
                </Link>
            </div>
        );
    }

    return (
        <div className={styles.encart} data-done={done ? "1" : "0"}>
            <button
                type="button"
                className={styles.encartHead}
                aria-expanded={open}
                aria-controls={panelId}
                onClick={onToggle}
            >
                {inner}
                {done && (
                    <span className={styles.encartDone} aria-hidden>
                        <Check size={15} strokeWidth={3} />
                    </span>
                )}
                <span className={styles.encartChevron} data-open={open ? "1" : "0"} aria-hidden>
                    <ChevronDown size={19} />
                </span>
            </button>
            {open && (
                <div className={styles.encartPanel} id={panelId}>
                    {children}
                </div>
            )}
        </div>
    );
}

/**
 * Une ligne **à l'intérieur** d'un encart. Trois formes, une seule anatomie :
 * cliquable (bouton), fermée (lien vers l'offre), ou inerte.
 *
 * `title` reçoit le contenu **réel** — floutable par l'appelant, jamais un
 * décor : c'est lui qui décide ce qui passe derrière le rideau, parce que lui
 * seul sait ce qui reste vrai pour tout le monde.
 */
export function PlanEncartRow({
    title,
    meta,
    trailing,
    href,
    onClick,
    onLinkClick,
    disabled,
    done,
}: {
    title: ReactNode;
    meta?: ReactNode;
    trailing?: ReactNode;
    href?: string;
    onClick?: () => void;
    onLinkClick?: () => void;
    disabled?: boolean;
    done?: boolean;
}) {
    const inner = (
        <>
            <span className={styles.encartRowBody}>
                <span className={styles.encartRowTitle} data-done={done ? "1" : "0"}>{title}</span>
                {meta && <span className={styles.encartRowMeta}>{meta}</span>}
            </span>
            {trailing}
        </>
    );

    if (href) {
        return (
            <li className={styles.encartRowItem} data-done={done ? "1" : "0"}>
                <Link className={styles.encartRow} href={href} onClick={onLinkClick}>{inner}</Link>
            </li>
        );
    }
    if (onClick) {
        return (
            <li className={styles.encartRowItem} data-done={done ? "1" : "0"}>
                <button type="button" className={styles.encartRow} disabled={disabled} onClick={onClick}>
                    {inner}
                </button>
            </li>
        );
    }
    return (
        <li className={styles.encartRowItem} data-done={done ? "1" : "0"}>
            <span className={styles.encartRow}>{inner}</span>
        </li>
    );
}

/** Le « Commencer › » d'une ligne ouverte. */
export function PlanEncartStart({label}: {label: string}) {
    return (
        <span className={styles.encartStart}>
            {label} <ChevronRight size={14} aria-hidden />
        </span>
    );
}

/** La coche d'une ligne faite — même pastille verte que celle de l'encart. */
export function PlanEncartDone({label}: {label: string}) {
    return (
        <span className={styles.encartRowDone} aria-label={label}>
            <Check size={14} strokeWidth={3} aria-hidden />
        </span>
    );
}
