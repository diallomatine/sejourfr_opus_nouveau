"use client";

import Link from "next/link";
import {ArrowLeft, ChevronRight, FileText, Info, Layers, Target} from "lucide-react";
import type {ReactNode} from "react";
import {type ProductionConfig} from "@/app/_components/production/config";
import s from "./skill.module.css";

/**
 * Briques de mise en page du parcours TCF EE/EO, reprises de la maquette
 * client : shell, hero en dégradé, pastilles de tâche, intertitres, encart
 * d'information, cartes en ligne, filtres, statistiques.
 *
 * Elles vivent **hors** du module « Compétences » depuis que le parcours entier
 * (hub d'épreuve, sujets TCF, exercice, résultat, examens blancs, historique)
 * suit la même maquette : recopier plutôt que partager, c'est la garantie de
 * voir les deux versions diverger à la première retouche.
 *
 * **Aucune de ces briques ne choisit sa couleur** : elles héritent toutes de
 * `--skill-accent`, posé une seule fois par `SkillShell` (ou `SkillAccent` hors
 * colonne) selon l'épreuve — bleu à l'écrit, rouge à l'oral.
 */

/** Les trois modes du parcours, tels que la maquette les nomme dans sa barre
 *  du bas. « Exemples » n'en fait pas partie : c'est une ressource d'appoint
 *  atteinte depuis la liste des sujets, pas un espace de travail. */
export type SkillMode = "competences" | "sujets" | "examens";

const MODES: readonly {key: SkillMode; label: string; icon: ReactNode}[] = [
  {key: "competences", label: "Compétences", icon: <Layers size={20} strokeWidth={2} />},
  {key: "sujets", label: "Sujets", icon: <FileText size={20} strokeWidth={2} />},
  {key: "examens", label: "Examens", icon: <Target size={20} strokeWidth={2} />},
];

/**
 * Barre de modes du prototype (`nav.bottom`). Rendue par `SkillShell`, jamais
 * en direct : c'est ce qui garantit qu'elle est au même endroit, avec la même
 * réserve de place en bas de colonne, sur tous les écrans qui la portent.
 *
 * `taskNumero` porte le contexte quand l'écran en a un. Sans lui (grille
 * d'examens blancs), « Sujets » comme « Compétences » retombent sur la
 * tâche 1 : une destination par défaut, jamais un chiffre affiché qui serait
 * faux. L'épreuve n'a plus d'écran d'accueil où retomber.
 */
export function SkillModeBar({
  config,
  current,
  taskNumero,
}: {
  config: ProductionConfig;
  current: SkillMode;
  taskNumero?: number;
}) {
  const n = taskNumero ?? 1;
  const hrefOf = (mode: SkillMode): string => {
    if (mode === "examens") return `${config.base}/examens`;
    if (mode === "competences") return `${config.base}/tache/${n}/competences`;
    return `${config.base}/tache/${n}`;
  };

  return (
    <nav className={s.modeBar} aria-label="Espaces de l'épreuve">
      <div className={s.modeBarInner}>
        {MODES.map((m) => {
          const on = m.key === current;
          return (
            <Link
              key={m.key}
              href={hrefOf(m.key)}
              className={`${s.modeBtn} ${on ? s.modeBtnOn : ""}`}
              aria-current={on ? "page" : undefined}
            >
              <span aria-hidden>{m.icon}</span>
              {m.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

/**
 * Colonne unique du parcours — même largeur sur tous les écrans.
 *
 * `mode` allume la barre des trois espaces. Elle n'est **pas** posée sur les
 * écrans de production (exercice, résultat, session d'examen) : l'action y vit
 * en bas de page, une barre flottante s'assoirait dessus.
 */
export function SkillShell({
  config,
  backHref,
  backLabel,
  mode,
  taskNumero,
  children,
}: {
  config: ProductionConfig;
  backHref: string;
  backLabel: string;
  mode?: SkillMode;
  taskNumero?: number;
  children: ReactNode;
}) {
  return (
    <main
      className={`${s.wrap} ${config.accent === "red" ? s.wrapEo : ""} ${mode ? s.wrapBar : ""}`}
    >
      <Link href={backHref} className={s.back}>
        <ArrowLeft size={16} aria-hidden />
        {backLabel}
      </Link>
      {mode && <SkillModeBar config={config} current={mode} taskNumero={taskNumero} />}
      {children}
    </main>
  );
}

/**
 * Porteur d'accent autonome, pour les blocs rendus **hors** de `SkillShell` —
 * typiquement les formulaires d'exercice réutilisés par la session d'examen
 * blanc, qui a sa propre colonne. Sans lui, une carte d'exercice d'expression
 * orale retombait sur le bleu au milieu d'une épreuve rouge.
 */
export function SkillAccent({
  accent,
  className,
  children,
}: {
  accent: "blue" | "red";
  className?: string;
  children: ReactNode;
}) {
  return (
    <div className={`${s.accent} ${accent === "red" ? s.accentEo : ""} ${className ?? ""}`}>
      {children}
    </div>
  );
}

/**
 * Bandeau d'ouverture : eyebrow, titre, promesse, pilule de palier et **barre
 * de progression** du périmètre affiché.
 *
 * Le pourcentage n'est pas décoratif : c'est la seule vue d'ensemble du
 * parcours, l'information n'existait jusqu'ici que noyée dans une phrase.
 * `unit` nomme ce qui est compté (« sujets », « tâches ») — un compteur sans
 * unité laisse deviner, et deux écrans finiraient par compter deux choses.
 */
export function SkillHero({
  eyebrow,
  title,
  text,
  level,
  attempted,
  total,
  percent,
  unit = "sujets",
}: {
  eyebrow: string;
  title: string;
  text: string;
  level: string | null;
  attempted: number;
  total: number;
  percent: number;
  unit?: string;
}) {
  return (
    <section className={s.hero}>
      <div className={s.heroTop}>
        <div>
          <div className={s.eyebrow}>{eyebrow}</div>
          <h1 className={s.heroTitle}>{title}</h1>
          <p className={s.heroText}>{text}</p>
        </div>
        {level && <span className={s.heroLevel}>{level}</span>}
      </div>
      {total > 0 && (
        <div className={s.heroProgress}>
          <div className={s.heroProgressLabel}>
            <span>
              Progression · {attempted}/{total} {unit}
            </span>
            <span>{percent} %</span>
          </div>
          <span className={s.heroRail}>
            <span style={{width: `${percent}%`}} />
          </span>
        </div>
      )}
    </section>
  );
}

/**
 * Pastilles T1 / T2 / T3 : changer de tâche sans revenir en arrière. Ce sont de
 * vrais liens (chaque tâche a son URL, partageable et ouvrable directement),
 * donc navigables au clavier et ouvrables dans un onglet ; la rangée défile
 * horizontalement sous 360 px sans jamais élargir la page.
 *
 * `hrefOf` dit où va chaque pastille : les sujets TCF pointent la tâche, les
 * micro-exercices pointent son sous-espace « compétences ».
 *
 * **`onPick` transforme la pastille en filtre.** Quand l'écran a déjà les trois
 * tâches en mémoire (c'est le cas depuis qu'on charge l'épreuve entière en un
 * appel), changer de tâche ne doit ni remonter la page, ni relancer un `fetch` :
 * le clic simple est intercepté, l'écran filtre, et l'URL est réécrite en
 * navigation superficielle par l'appelant. Les clics *modifiés* (Ctrl, ⌘, Maj,
 * clic du milieu) gardent leur comportement natif — sinon « ouvrir dans un
 * nouvel onglet » cesserait de fonctionner. Sans `onPick`, on navigue comme
 * avant.
 */
export function TaskPills({
  config,
  current,
  labelOf,
  hrefOf,
  onPick,
}: {
  config: ProductionConfig;
  current: number;
  labelOf: (n: number) => string;
  hrefOf?: (n: number) => string;
  onPick?: (n: number) => void;
}) {
  const href = hrefOf ?? ((n: number) => `${config.base}/tache/${n}`);
  return (
    <nav className={s.taskPills} aria-label="Tâches de l'épreuve">
      {[1, 2, 3].map((n) => {
        const on = n === current;
        return (
          <Link
            key={n}
            href={href(n)}
            className={`${s.taskPill} ${on ? s.taskPillOn : ""}`}
            aria-current={on ? "page" : undefined}
            onClick={
              onPick
                ? (e) => {
                    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
                    e.preventDefault();
                    onPick(n);
                  }
                : undefined
            }
          >
            <span className={s.taskNum} aria-hidden>
              {n}
            </span>
            {labelOf(n)}
          </Link>
        );
      })}
    </nav>
  );
}

/** Intertitre de section + sa phrase d'explication, et son lien discret. */
export function SectionHead({
  title,
  text,
  action,
}: {
  title: string;
  text?: string;
  action?: ReactNode;
}) {
  return (
    <div className={s.sectionHead}>
      <div>
        <h2 className={s.sectionHeadTitle}>{title}</h2>
        {text && <p className={s.sectionHeadText}>{text}</p>}
      </div>
      {action}
    </div>
  );
}

/** Encart d'information (icône ambre + titre + phrase). */
export function SkillNotice({title, children}: {title: string; children: ReactNode}) {
  return (
    <aside className={s.notice}>
      <span className={s.noticeIcon} aria-hidden>
        <Info size={18} strokeWidth={2.2} />
      </span>
      <div>
        <strong>{title}</strong>
        {children}
      </div>
    </aside>
  );
}

/** Barre fine « traités / total » sous un titre de carte. */
export function MiniBar({
  attempted,
  total,
  percent,
  label,
}: {
  attempted: number;
  total: number;
  percent: number;
  /** Remplace « n/N traités » quand l'unité comptée n'est pas un sujet. */
  label?: string;
}) {
  return (
    <span className={s.rowMeta}>
      <span className={s.mini}>
        <span
          className={`${s.miniFill} ${percent >= 100 ? s.miniFillDone : ""}`}
          style={{width: `${percent}%`}}
        />
      </span>
      <span className={s.count}>{label ?? `${attempted}/${total} traités`}</span>
    </span>
  );
}

/** Chevron de fin de carte cliquable. */
export function RowChevron() {
  return (
    <span className={s.chev} aria-hidden>
      <ChevronRight size={18} strokeWidth={2.4} />
    </span>
  );
}

/* -------------------------------------------------------------- badges */

export type SkillBadgeTone = "todo" | "treated" | "validated" | "reinforce" | "level";

const BADGE_CLASS: Record<SkillBadgeTone, string> = {
  todo: s.badgeTodo,
  treated: s.badgeTreated,
  validated: s.badgeValidated,
  reinforce: s.badgeReinforce,
  level: s.levelPill,
};

/** Pastille d'état d'une carte. Une seule forme dans tout le parcours. */
export function SkillBadge({
  tone,
  icon,
  children,
}: {
  tone: SkillBadgeTone;
  icon?: ReactNode;
  children: ReactNode;
}) {
  return (
    <span className={`${s.badge} ${BADGE_CLASS[tone]}`}>
      {icon}
      {children}
    </span>
  );
}

/* --------------------------------------------------------- carte en ligne */

/** Liseré vertical d'une carte : **uniquement** sur les sujets traités — un
 *  liseré gris sur les sujets à faire lui retirerait tout pouvoir de
 *  distinction. */
export type SkillRowMark = "none" | "done" | "validated" | "reinforce";

const MARK_CLASS: Record<SkillRowMark, string> = {
  none: "",
  done: s.rowCardDone,
  validated: `${s.rowCardDone} ${s.rowCardValidated}`,
  reinforce: `${s.rowCardDone} ${s.rowCardReinforce}`,
};

/**
 * Carte cliquable de la maquette : grille 48 / 1fr / auto — pastille, corps,
 * aside. Rendue en `<button>` ou en `<Link>` selon que l'action navigue ou non.
 */
export function SkillRowCard({
  tile,
  tileDone = false,
  title,
  text,
  meta,
  aside,
  mark = "none",
  href,
  onClick,
  disabled = false,
  ariaLabel,
}: {
  tile: ReactNode;
  tileDone?: boolean;
  title: ReactNode;
  text?: ReactNode;
  meta?: ReactNode;
  aside?: ReactNode;
  mark?: SkillRowMark;
  href?: string;
  onClick?: () => void;
  disabled?: boolean;
  ariaLabel?: string;
}) {
  const className = `${s.card} ${s.rowCard} ${MARK_CLASS[mark]}`;
  const inner = (
    <>
      <span className={`${s.tile} ${tileDone ? s.tileDone : ""}`} aria-hidden>
        {tile}
      </span>
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{title}</span>
        {text && <span className={s.rowText}>{text}</span>}
        {meta && <span className={s.rowMeta}>{meta}</span>}
      </span>
      {aside ?? <RowChevron />}
    </>
  );

  if (href && !disabled) {
    return (
      <Link href={href} className={className} aria-label={ariaLabel}>
        {inner}
      </Link>
    );
  }
  return (
    <button
      type="button"
      className={className}
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel}
    >
      {inner}
    </button>
  );
}

/* ------------------------------------------------------------- filtres */

export interface SkillFilter<T extends string> {
  key: T;
  label: string;
  /** Compteur affiché à droite du libellé. Omis = pas de compteur. */
  count?: number;
}

/**
 * Rangée de filtres du prototype. `role="tablist"` : ce sont des vues d'une
 * même liste, pas des navigations — un lecteur d'écran doit l'entendre.
 */
export function SkillFilterRow<T extends string>({
  filters,
  active,
  onPick,
  label,
}: {
  filters: readonly SkillFilter<T>[];
  active: T;
  onPick: (key: T) => void;
  label: string;
}) {
  return (
    <div className={s.filterRow} role="tablist" aria-label={label}>
      {filters.map((f) => (
        <button
          key={f.key}
          type="button"
          role="tab"
          aria-selected={f.key === active}
          className={`${s.filter} ${f.key === active ? s.filterOn : ""}`}
          onClick={() => onPick(f.key)}
        >
          {f.label}
          {f.count != null ? ` ${f.count}` : ""}
        </button>
      ))}
    </div>
  );
}

/* --------------------------------------------------------- statistiques */

export interface SkillStat {
  value: string;
  label: string;
  sub?: string;
}

/** Rangée de trois indicateurs, au-dessus d'une grille d'examens. */
export function SkillStats({stats}: {stats: readonly SkillStat[]}) {
  return (
    <div className={s.stats}>
      {stats.map((st) => (
        <div key={st.label} className={s.stat}>
          <span className={s.statValue}>{st.value}</span>
          <span className={s.statLabel}>{st.label}</span>
          {st.sub && <span className={s.statSub}>{st.sub}</span>}
        </div>
      ))}
    </div>
  );
}
