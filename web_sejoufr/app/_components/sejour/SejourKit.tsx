/**
 * Kit « parcours » — primitives partagées par les 7 écrans de diagnostic et de
 * plan (TCF et civique), web et miroir du kit Flutter
 * `mobile_sejourfr/lib/core/widgets/sejour/`.
 *
 * 🛑 Règle d'usage : un écran de ce périmètre n'écrit PAS de CSS à lui. Il
 * assemble ces primitives. Si un motif manque, il s'ajoute ici et dans le
 * miroir Flutter dans la même passe — sinon les deux fronts divergent.
 *
 * Les libellés et les valeurs viennent TOUJOURS du serveur : aucune primitive
 * ci-dessous ne classe un nombre en état pédagogique ni en niveau CECRL.
 */

import Link from "next/link";
import {
  ArrowRight,
  Check,
  ChevronLeft,
  Circle,
  Minus,
  AlertCircle,
  type LucideIcon,
} from "lucide-react";
import type { CSSProperties, ReactNode } from "react";
import styles from "./sejour.module.css";

export { styles as sejourStyles };

/** Concatène des classes en ignorant les valeurs vides. */
export function cx(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}

/**
 * Ton d'état servi par le backend. `hot` = prioritaire, `warn` = à renforcer,
 * `ok` = acquis.
 *
 * 🛑 `muted` = **non mesuré**, et ce n'est pas un quatrième degré de gravité :
 * c'est l'absence de mesure. Sans lui, un thème `NON_EVALUE` retombait sur
 * `warn` et s'affichait en ambre — le front désignait comme fragile quelque
 * chose que le serveur n'a jamais évalué. `null = inconnu, jamais mauvais`.
 */
export type Tone = "ok" | "warn" | "hot" | "muted";

/** État d'une étape de parcours ou d'une compétence. */
export type StepState = "done" | "now" | "todo";

const toneClass: Record<Tone, string> = {
  ok: styles.ok,
  warn: styles.warn,
  hot: styles.hot,
  muted: styles.muted,
};

/* ------------------------------------------------------------------ Shell */

export function SejourApp({
  children,
  sticky,
  className,
}: {
  children: ReactNode;
  /** Réserve la place de la barre d'action collée en bas. */
  sticky?: boolean;
  className?: string;
}) {
  return (
    <div className={cx(styles.app, sticky && styles.hasSticky, className)}>
      {children}
    </div>
  );
}

export function Top({
  backTo,
  onBack,
  kicker,
  title,
  badge,
}: {
  backTo?: string;
  onBack?: () => void;
  kicker?: string;
  title: string;
  badge?: string;
}) {
  return (
    <header className={styles.top}>
      {backTo ? (
        <Link href={backTo} className={styles.iconBtn} aria-label="Retour">
          <ChevronLeft size={24} strokeWidth={2} aria-hidden />
        </Link>
      ) : onBack ? (
        <button type="button" onClick={onBack} className={styles.iconBtn} aria-label="Retour">
          <ChevronLeft size={24} strokeWidth={2} aria-hidden />
        </button>
      ) : null}
      <div className={styles.topText}>
        {kicker ? <p className={styles.kicker}>{kicker}</p> : null}
        <h1 className={styles.title}>{title}</h1>
        {badge ? <span className={styles.badge}>{badge}</span> : null}
      </div>
    </header>
  );
}

export function Pad({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cx(styles.pad, className)}>{children}</div>;
}

export function Stack({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cx(styles.stack, className)}>{children}</div>;
}

export function Section({
  title,
  children,
  flush,
}: {
  title?: string;
  children: ReactNode;
  /** Titre aligné sur le contenu au lieu des marges d'écran. */
  flush?: boolean;
}) {
  return (
    <section className={cx(styles.section, flush && styles.pad)}>
      {title ? (
        <h2 className={cx(styles.sectionH, flush && styles.sectionHFlush)}>{title}</h2>
      ) : null}
      {children}
    </section>
  );
}

export function Card({
  children,
  variant,
  padding,
  className,
  style,
}: {
  children: ReactNode;
  variant?: "soft" | "warn" | "ok" | "hero";
  /** `tight` pour une carte qui n'empile que des lignes séparées d'un filet. */
  padding?: "tight" | "rows";
  className?: string;
  style?: CSSProperties;
}) {
  const base = variant === "hero" ? styles.cardHero : styles.card;
  return (
    <div
      className={cx(
        base,
        variant === "soft" && styles.cardSoft,
        variant === "warn" && styles.cardWarn,
        variant === "ok" && styles.cardOk,
        padding === "tight" && styles.cardTight,
        padding === "rows" && styles.cardRows,
        className,
      )}
      style={style}
    >
      {children}
    </div>
  );
}

/* ------------------------------------------------------------------ Niveau */

/**
 * Piste de niveau CECRL. Les paliers, le palier courant et l'objectif sont
 * SERVIS : ce composant ne devine ni l'ordre ni la position.
 */
export function LevelTrack({
  levels,
  currentIndex,
  goalIndex,
  youLabel = "Vous",
  goalLabel = "Objectif",
}: {
  levels: string[];
  currentIndex: number;
  goalIndex: number;
  youLabel?: string;
  goalLabel?: string;
}) {
  const n = Math.max(levels.length, 1);
  // La piste va du centre de la 1ʳᵉ colonne au centre de la dernière : 16 % de
  // chaque côté. On remplit au prorata du palier courant.
  const span = 100 - 16 * 2;
  const fill = n > 1 ? (span * Math.max(currentIndex, 0)) / (n - 1) : 0;

  return (
    <div
      className={styles.trackWrap}
      role="img"
      aria-label={`Vous êtes à ${levels[currentIndex] ?? "—"}, objectif ${levels[goalIndex] ?? "—"}`}
    >
      <div
        className={styles.track}
        style={
          {
            gridTemplateColumns: `repeat(${n}, 1fr)`,
            "--sf-track-fill": `${fill}%`,
          } as CSSProperties
        }
      >
        {levels.map((lvl, i) => {
          const state =
            i === currentIndex ? styles.isNow : i === goalIndex ? styles.isGoal : i < currentIndex ? styles.isDone : "";
          const caption = i === currentIndex ? youLabel : i === goalIndex ? goalLabel : " ";
          return (
            <div key={lvl} className={cx(styles.trackCol, state)}>
              <span className={styles.dot} />
              <span className={styles.lvl}>{lvl}</span>
              <span className={styles.cap}>{caption}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Bandeau compact « niveau actuel → objectif ». */
export function GoalStrip({
  currentLabel = "Niveau actuel",
  current,
  goalLabel = "Objectif",
  goal,
}: {
  currentLabel?: string;
  current: string;
  goalLabel?: string;
  goal: string;
}) {
  return (
    <Card>
      <div className={styles.goal}>
        <div>
          <small>{currentLabel}</small>
          <b>{current}</b>
        </div>
        <div className={styles.goalArrow} aria-hidden>
          <ArrowRight size={20} strokeWidth={2} />
        </div>
        <div>
          <small>{goalLabel}</small>
          <b>{goal}</b>
        </div>
      </div>
    </Card>
  );
}

/* ----------------------------------------------------------------- Boutons */

export function Cta({
  href,
  onClick,
  children,
  caption,
  variant = "primary",
  disabled,
  type = "button",
}: {
  href?: string;
  onClick?: () => void;
  children: ReactNode;
  caption?: string;
  variant?: "primary" | "blue" | "line";
  disabled?: boolean;
  type?: "button" | "submit";
}) {
  const cls = cx(
    styles.btn,
    variant === "blue" && styles.btnGhost,
    variant === "line" && styles.btnLine,
  );
  return (
    <div>
      {href && !disabled ? (
        <Link href={href} className={cls} onClick={onClick}>
          {children}
          <ArrowRight size={20} strokeWidth={2} aria-hidden />
        </Link>
      ) : (
        <button type={type} className={cls} onClick={onClick} disabled={disabled}>
          {children}
          <ArrowRight size={20} strokeWidth={2} aria-hidden />
        </button>
      )}
      {caption ? <p className={styles.btnCaption}>{caption}</p> : null}
    </div>
  );
}

export function Sticky({ children }: { children: ReactNode }) {
  return <div className={styles.sticky}>{children}</div>;
}

/* ------------------------------------------------------- Bascule de module */

export function ModuleToggle({
  current,
  onSelect,
  tcfHref,
  civicHref,
}: {
  current: "tcf" | "civique";
  onSelect?: (module: "tcf" | "civique") => void;
  tcfHref?: string;
  civicHref?: string;
}) {
  const items: Array<{ id: "tcf" | "civique"; label: string; href?: string }> = [
    { id: "tcf", label: "TCF IRN", href: tcfHref },
    { id: "civique", label: "Examen civique", href: civicHref },
  ];
  return (
    <div className={styles.segWrap}>
      <div className={styles.seg} role="tablist" aria-label="Parcours">
        {items.map((item) =>
          item.href ? (
            <Link
              key={item.id}
              href={item.href}
              role="tab"
              aria-selected={current === item.id}
              className={current === item.id ? styles.isOn : undefined}
            >
              {item.label}
            </Link>
          ) : (
            <button
              key={item.id}
              type="button"
              role="tab"
              aria-selected={current === item.id}
              className={current === item.id ? styles.isOn : undefined}
              onClick={() => onSelect?.(item.id)}
            >
              {item.label}
            </button>
          ),
        )}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------- Observations */

export function Observation({
  tone,
  kicker,
  title,
  text,
  icon: Icon,
}: {
  tone: "ok" | "up";
  kicker: string;
  title: string;
  text?: string;
  icon: LucideIcon;
}) {
  return (
    <article className={styles.obs}>
      <div className={cx(styles.obsIco, tone === "ok" ? styles.ok : styles.up)}>
        <Icon size={20} strokeWidth={2} aria-hidden />
      </div>
      <div>
        <p className={cx(styles.obsKicker, tone === "ok" ? styles.ok : styles.up)}>{kicker}</p>
        <strong>{title}</strong>
        {text ? <p>{text}</p> : null}
      </div>
    </article>
  );
}

/** Encart d'explication ou de réassurance : icône ronde + titre + texte. */
export function NoteCard({
  variant,
  icon: Icon,
  iconTone = "blue",
  title,
  children,
  titleSize = "sm",
}: {
  variant?: "soft" | "ok" | "warn";
  icon: LucideIcon;
  iconTone?: "blue" | "ok";
  title: string;
  children?: ReactNode;
  titleSize?: "sm" | "lg";
}) {
  return (
    <Card variant={variant}>
      <div className={styles.noteRow}>
        <div
          className={
            iconTone === "ok" ? cx(styles.obsIco, styles.ok, styles.onWhite) : styles.examIco
          }
        >
          <Icon size={20} strokeWidth={2} aria-hidden />
        </div>
        <div>
          <h2 className={cx(styles.noteTitle, titleSize === "lg" && styles.noteTitleLg)}>{title}</h2>
          {children}
        </div>
      </div>
    </Card>
  );
}

/* ------------------------------------------------------------------ Lignes */

/** Ligne d'épreuve : icône + libellé, et à droite le niveau + son état servi. */
export function ExamRow({
  icon: Icon,
  title,
  subtitle,
  level,
  status,
  tone,
}: {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  level?: string;
  status?: string;
  tone?: Tone;
}) {
  const simple = !level && !status;
  return (
    <div className={cx(styles.exam, simple && styles.simple)}>
      <div className={styles.examIco}>
        <Icon size={20} strokeWidth={2} aria-hidden />
      </div>
      <div>
        <b>{title}</b>
        {subtitle ? <small>{subtitle}</small> : null}
      </div>
      {simple ? null : (
        <div className={styles.examEnd}>
          {level ? <span className={styles.lvlChip}>{level}</span> : null}
          {status ? (
            <span className={cx(styles.status, tone && toneClass[tone])}>{status}</span>
          ) : null}
        </div>
      )}
    </div>
  );
}

/** Ligne de thème civique : pastille d'état + nom + libellé d'état servi. */
export function ThemeLine({
  tone,
  name,
  status,
}: {
  tone: Tone;
  name: string;
  status: string;
}) {
  // `muted` et `warn` partagent le tiret : ce qui les distingue, c'est la
  // couleur (neutre / ambre) et le libellé servi, jamais une icône d'alerte.
  const Icon = tone === "ok" ? Check : tone === "hot" ? AlertCircle : Minus;
  return (
    <div className={styles.themeLine}>
      <span className={cx(styles.themeMark, toneClass[tone])}>
        <Icon size={16} strokeWidth={2} aria-hidden />
      </span>
      <b>{name}</b>
      <span className={cx(styles.status, toneClass[tone])}>{status}</span>
    </div>
  );
}

/** Carte de priorité, avec son liseré de rang. */
export function Prio({
  rank,
  tag,
  title,
  text,
  children,
}: {
  rank: 1 | 2 | 3;
  tag: string;
  title: string;
  text?: string;
  children?: ReactNode;
}) {
  const rankClass = rank === 1 ? styles.p1 : rank === 2 ? styles.p2 : styles.p3;
  return (
    <article className={cx(styles.prio, rankClass)}>
      <div className={styles.prioN}>{rank}</div>
      <div>
        <p className={styles.prioTag}>{tag}</p>
        <h3>{title}</h3>
        {text ? <p>{text}</p> : null}
        {children}
      </div>
    </article>
  );
}

/** Barre de progression fine d'une priorité (compétences validées). */
export function ProgressMini({ ratio, label }: { ratio: number; label?: string }) {
  const pct = Math.round(Math.min(Math.max(ratio, 0), 1) * 100);
  return (
    <div className={styles.progressMini} aria-label={label}>
      <span style={{ width: `${pct}%` }} />
    </div>
  );
}

/** Sous-ligne d'une priorité : une compétence et son état. */
export function SkillRow({ label, state }: { label: string; state: StepState }) {
  const Icon = state === "done" ? Check : state === "now" ? ArrowRight : Circle;
  return (
    <div
      className={cx(
        styles.skillMiniRow,
        state === "done" && styles.isDone,
        state === "now" && styles.isNow,
      )}
    >
      <span>
        <Icon size={16} strokeWidth={2} aria-hidden />
      </span>
      <span>{label}</span>
    </div>
  );
}

export function SkillList({ children }: { children: ReactNode }) {
  return <div className={styles.skillMini}>{children}</div>;
}

/* ---------------------------------------------------------------- Parcours */

export type PathStep = { label: string; state: StepState };

/**
 * Parcours d'une tâche / d'une notion : la barre segmentée, le compteur
 * « Étape X / Y » et les étapes. Les états sont SERVIS.
 */
export function PathCard({
  currentLabel,
  counterLabel,
  steps,
}: {
  currentLabel: string;
  counterLabel: string;
  steps: PathStep[];
}) {
  return (
    <Card>
      <div className={styles.progressLabel}>
        <b>{currentLabel}</b>
        <span>{counterLabel}</span>
      </div>
      <div
        className={styles.bar}
        style={{ gridTemplateColumns: `repeat(${steps.length}, 1fr)` }}
        aria-hidden
      >
        {steps.map((s, i) => (
          <i
            key={`${s.label}-${i}`}
            className={cx(s.state === "done" && styles.on, s.state === "now" && styles.nowSeg)}
          />
        ))}
      </div>
      {steps.map((s, i) => (
        <PathRow key={`${s.label}-${i}`} label={s.label} state={s.state} />
      ))}
    </Card>
  );
}

export function PathRow({ label, state }: { label: string; state: StepState }) {
  const Icon = state === "done" ? Check : state === "now" ? ArrowRight : Circle;
  return (
    <div
      className={cx(
        styles.step,
        state === "done" && styles.isDone,
        state === "now" && styles.isNext,
      )}
    >
      <span className={styles.bullet}>
        <Icon size={16} strokeWidth={2} aria-hidden />
      </span>
      {state === "todo" ? <span>{label}</span> : <b>{label}</b>}
      {state === "now" ? <span className={styles.nowPill}>Maintenant</span> : null}
    </div>
  );
}

/**
 * Étape verrouillée (plan gratuit).
 *
 * `label` accepte un nœud : sur le Plan, le titre d'une ligne **verrouillée**
 * passe derrière le rideau (`PlanBlur`) — le rang et le cadenas, eux, restent
 * nets.
 */
export function LockRow({ n, label, icon: Icon }: { n: number; label: ReactNode; icon: LucideIcon }) {
  return (
    <div className={styles.lockRow}>
      <span className={styles.lockN}>{n}</span>
      <span>{label}</span>
      <Icon size={16} strokeWidth={2} aria-hidden />
    </div>
  );
}

export function LockItem({ label, icon: Icon }: { label: string; icon: LucideIcon }) {
  return (
    <div className={styles.lockItem}>
      <Icon size={16} strokeWidth={2} aria-hidden />
      {label}
    </div>
  );
}

export function LockList({ children }: { children: ReactNode }) {
  return <div className={styles.lockList}>{children}</div>;
}

/* ------------------------------------------------- « À faire maintenant » */

export function NowCard({
  icon: Icon,
  title,
  subtitle,
  badge,
  objectiveLabel,
  objective,
  meta,
  children,
  caption,
}: {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  badge?: string;
  objectiveLabel?: string;
  objective?: string;
  meta?: Array<{ icon: LucideIcon; label: string }>;
  children?: ReactNode;
  caption?: string;
}) {
  return (
    <article className={styles.now}>
      <div className={styles.nowHead}>
        <div className={styles.nowIco}>
          <Icon size={24} strokeWidth={2} aria-hidden />
        </div>
        <div>
          <b>{title}</b>
          {subtitle ? <span className={styles.nowSub}>{subtitle}</span> : null}
          {badge ? <span className={styles.nowBadge}>{badge}</span> : null}
        </div>
      </div>
      {objective ? (
        <div className={styles.nowObj}>
          {objectiveLabel ? <small>{objectiveLabel}</small> : null}
          <p>{objective}</p>
        </div>
      ) : null}
      {meta && meta.length > 0 ? (
        <div className={styles.meta}>
          {meta.map(({ icon: MetaIcon, label }) => (
            <span key={label}>
              <MetaIcon size={16} strokeWidth={2} aria-hidden />
              {label}
            </span>
          ))}
        </div>
      ) : null}
      {children}
      {caption ? <p className={styles.reco}>{caption}</p> : null}
    </article>
  );
}

/* ------------------------------------------------------------ Petites vues */

export function MiniPlan({
  rows,
}: {
  rows: Array<{ label: string; pill?: string; tone?: Tone }>;
}) {
  return (
    <div className={styles.mini}>
      {rows.map((row, i) => (
        <div key={`${row.label}-${i}`} className={styles.miniRow}>
          <span className={styles.miniN}>{i + 1}</span>
          <span>{row.label}</span>
          {row.pill ? (
            <span className={cx(styles.pill, row.tone && toneClass[row.tone])}>{row.pill}</span>
          ) : (
            <span />
          )}
        </div>
      ))}
    </div>
  );
}

export function CheckList({ items }: { items: string[] }) {
  return (
    <div className={styles.checks}>
      {items.map((item) => (
        <div key={item} className={styles.check}>
          <span className={styles.tick}>
            <Check size={16} strokeWidth={2} aria-hidden />
          </span>
          {item}
        </div>
      ))}
    </div>
  );
}

export function DoneRow({ label }: { label: string }) {
  return (
    <div className={styles.doneRow}>
      <span className={cx(styles.tick, styles.tickLg)}>
        <Check size={16} strokeWidth={2} aria-hidden />
      </span>
      {label}
    </div>
  );
}

export function PillMeta({ children }: { children: ReactNode }) {
  return <span className={styles.pillMeta}>{children}</span>;
}

export function Pills({ children }: { children: ReactNode }) {
  return <div className={styles.pills}>{children}</div>;
}

/** Carte de choix à cocher (démarche visée, durée de pass…). */
export function ChoiceCard({
  label,
  selected,
  onSelect,
}: {
  label: string;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      className={cx(styles.choice, selected && styles.isOn)}
      aria-pressed={selected}
      onClick={onSelect}
    >
      <span className={styles.choiceRow}>
        {label}
        <span className={styles.choiceMark} />
      </span>
    </button>
  );
}

export function PassCard({
  title,
  subtitle,
  selected,
  onSelect,
}: {
  title: string;
  subtitle: string;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      className={cx(styles.pass, selected && styles.isOn)}
      aria-pressed={selected}
      onClick={onSelect}
    >
      <div>
        <b>{title}</b>
        <span>{subtitle}</span>
      </div>
      <span className={styles.choiceMark} />
    </button>
  );
}
