"use client";

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
  BadgeCheck,
  Check,
  ChevronDown,
  ChevronLeft,
  Circle,
  CircleDot,
  Info,
  Lock,
  Minus,
  Target,
  AlertCircle,
  type LucideIcon,
} from "lucide-react";
import { createContext, useContext, useId, useState } from "react";
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

/**
 * État d'une étape de parcours ou d'une compétence.
 *
 * 🛑 **`verify` n'est pas `done`.** Une série de petits sujets terminée n'est
 * pas une compétence acquise — c'est une preuve qui reste à faire, et elle se
 * lit au premier coup d'œil (accent ambre, icône de validation) plutôt que
 * comme une coche de plus. `doing` est la série commencée, distincte de `now`
 * qui repère la compétence que le Plan travaille **maintenant**.
 *
 * ⚠️ Miroir de `SfStepState` (`mobile .../core/widgets/sejour/sejour_kit.dart`).
 */
export type StepState = "done" | "verify" | "doing" | "now" | "todo";

const STEP_ICON: Record<StepState, LucideIcon> = {
  done: Check,
  verify: BadgeCheck,
  doing: CircleDot,
  now: ArrowRight,
  todo: Circle,
};

const toneClass: Record<Tone, string> = {
  ok: styles.ok,
  warn: styles.warn,
  hot: styles.hot,
  muted: styles.muted,
};

/* ------------------------------------------------------------------ Shell */

/**
 * Le cadre d'un écran du kit. C'est lui qui décide la **largeur de la colonne**
 * au palier desktop (≥ 960 px), exactement comme `.sf-main` dans la maquette :
 *
 * | prop | ≤ 620 px | 620 → 960 | ≥ 960 px | pour quoi |
 * |---|---|---|---|---|
 * | — | 560 px | 720 px | **720 px** | un écran de LECTURE (rapport de diagnostic) |
 * | `sticky` | 560 px | 720 px | **980 px** | un écran dont l'action est une barre collée (paywall, Plan gratuit) |
 * | `wide` | 560 px | 720 px | **1080 px** | un TABLEAU DE BORD à plusieurs colonnes (Accueil, Plan abonné) |
 *
 * 🛑 Le rendu ≤ 620 px est identique dans les trois cas : le desktop s'ajoute
 * **au-dessus** de l'existant, il ne le remplace pas.
 */
export function SejourApp({
  children,
  sticky,
  wide,
  report,
  className,
}: {
  children: ReactNode;
  /** Réserve la place de la barre d'action collée en bas. */
  sticky?: boolean;
  /** Colonne large (1080 px) : l'écran dispose plusieurs colonnes en desktop. */
  wide?: boolean;
  /**
   * **Écran de RAPPORT** : conteneur de 980 px, mais texte plafonné à 720 px.
   *
   * 🛑 C'est la quatrième *nature* d'écran, pas une quatrième borne (arbitrage
   * du propriétaire, 2026-09-12) : un rapport a des grilles qui gagnent à
   * s'étaler — épreuves, priorités, observations — et de la prose qui perd à
   * s'allonger. Dedans, **tout est du texte par défaut (720 px) et seul ce qui
   * porte une classe de grille (`deskGrid`, `deskGrid2`, `deskPair`) prend les
   * 980 px** ; un bloc nouveau n'a donc rien de plus à déclarer que sa grille.
   * Toute la règle vit dans `sejour.module.css`, bloc « LE PALIER DESKTOP ».
   */
  report?: boolean;
  className?: string;
}) {
  return (
    <div
      className={cx(
        styles.app,
        sticky && styles.hasSticky,
        wide && styles.wide,
        report && styles.report,
        className,
      )}
    >
      {children}
    </div>
  );
}

/**
 * Ce qui se glisse SOUS l'en-tête de page, dans TOUS les états d'un écran.
 *
 * 🛑 **L'ordre « eyebrow → titre → bascule de module » est posé ICI**, une
 * seule fois : l'écran parent fournit le nœud, `Top` le pose. Sans ce relais,
 * le parent devrait rendre la bascule lui-même — donc AVANT l'en-tête, l'ordre
 * qu'on corrige — ou la faire descendre en prop jusqu'aux sept variantes du
 * Plan (chargement, sans diagnostic, gratuit, abonné, TCF, civique…), chacune
 * portant son propre `Top`. Une bascule recopiée sept fois finit toujours par
 * diverger d'un état à l'autre.
 *
 * Miroir Flutter : `SfTopSlot` (`core/widgets/sejour/sejour_kit.dart`).
 */
const TopSlotContext = createContext<ReactNode>(null);

export function TopSlot({ node, children }: { node: ReactNode; children: ReactNode }) {
  return <TopSlotContext.Provider value={node}>{children}</TopSlotContext.Provider>;
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
  const slot = useContext(TopSlotContext);
  /* 🛑 **L'en-tête est TOUJOURS aligné à gauche** (arbitrage du propriétaire,
     2026-09-12). Il **révoque** `.topPlain`, qui centrait sous 620 px un
     en-tête sans flèche de retour : un titre centré au-dessus d'un contenu
     entièrement calé à gauche se lit comme un bandeau, pas comme le titre de la
     page — et il ne s'aligne ni sur la bascule de parcours, ni sur les cartes
     en dessous. Même retrait côté mobile (`SfTop`) dans la même passe. */
  return (
    <>
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
      {slot}
    </>
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

/**
 * **Le choix TCF IRN / Examen civique**, et il n'y en a qu'un.
 *
 * 🛑 Arbitrage du propriétaire (2026-09-12) : le menu de gauche garde ses deux
 * entrées de parcours, et le choix TCF / civique vit dans les **deux écrans où
 * il change ce qui est affiché** — `/dashboard` et `/plan`. Ils rendent donc
 * **cette** brique, au même endroit (sous l'en-tête), pas deux variantes.
 *
 * ⚠️ Les hubs `/entrainement` ne la portent **pas** : on y arrive par le menu,
 * qui a déjà fait le choix — « il faut afficher directement l'écran ». La prop
 * `className` et la classe `segFlush` qui les servaient sont parties avec eux.
 */
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

/**
 * **Anneau de couverture** — la part parcourue d'un ensemble, entre 0 et 1.
 *
 * 🛑 **Ce n'est pas une note et ce n'est pas un état pédagogique** : un seul
 * accent de marque, jamais une rampe de seuils. Un anneau vide veut dire « pas
 * encore commencé », jamais « mauvais ». Miroir Flutter : `ProgressRing`.
 */
export function Ring({ ratio, label }: { ratio: number; label?: string }) {
  const part = Number.isFinite(ratio) ? Math.max(0, Math.min(1, ratio)) : 0;
  const r = 15;
  const c = 2 * Math.PI * r;
  return (
    <svg
      className={styles.ring}
      width="40"
      height="40"
      viewBox="0 0 40 40"
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <circle cx="20" cy="20" r={r} fill="none" stroke="var(--color-line)" strokeWidth="4" />
      <circle
        cx="20"
        cy="20"
        r={r}
        fill="none"
        stroke={part >= 1 ? "var(--color-green)" : "var(--color-blue)"}
        strokeWidth="4"
        strokeDasharray={`${c * part} ${c}`}
        strokeLinecap="round"
        transform="rotate(-90 20 20)"
      />
    </svg>
  );
}

/**
 * **Ligne d'une épreuve ou d'un thème** sur l'écran Réviser : pictogramme,
 * titre, ligne d'état **servie**, compteur, et à droite soit un anneau de
 * couverture, soit un chevron.
 *
 * 🛑 Le `status` et le `meta` arrivent **composés** (`lib/reviser.ts` ⇄
 * `reviser_labels.dart`) : cette brique ne classe rien et ne compte rien.
 *
 * Miroir Flutter : `SfEpreuveRow`.
 */
export function EpreuveRow({
  icon: Icon,
  title,
  status,
  meta,
  ratio,
  href,
  onClick,
}: {
  icon: LucideIcon;
  title: string;
  status: string;
  meta?: string | null;
  /** Part parcourue (0-1). Absent ⇒ un chevron prend la place de l'anneau. */
  ratio?: number | null;
  href?: string;
  onClick?: () => void;
}) {
  const body = (
    <>
      <span className={styles.epreuveIco}>
        <Icon size={22} strokeWidth={1.8} aria-hidden />
      </span>
      <span className={styles.epreuveBody}>
        <b>{title}</b>
        <span>{status}</span>
        {meta ? <span className={styles.epreuveMeta}>{meta}</span> : null}
      </span>
      {typeof ratio === "number" ? (
        <Ring ratio={ratio} />
      ) : (
        <span className={styles.epreuveEnd} aria-hidden>
          <ArrowRight size={18} strokeWidth={2} />
        </span>
      )}
    </>
  );
  if (href) {
    return (
      <Link href={href} className={styles.epreuve}>
        {body}
      </Link>
    );
  }
  return (
    <button type="button" className={styles.epreuve} onClick={onClick}>
      {body}
    </button>
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

/**
 * Carte de priorité, avec son liseré de rang.
 *
 * **Rétractable dès qu'on en empile plusieurs.** `details` est le contenu que
 * l'encart FERMÉ ne montre pas ; `children` reste toujours lisible. Sans
 * `details`, la carte est exactement celle d'avant — c'est le cas d'une
 * priorité seule, qu'il n'y a aucune raison de replier.
 *
 * 🛑 **Les deux libellés du bouton sont SERVIS** (`moreLabel` / `lessLabel`) :
 * le kit ne compose aucune phrase et ne compte rien. Sans eux, pas de bouton —
 * on n'affiche pas une bascule anonyme.
 */
export function Prio({
  rank,
  tag,
  title,
  text,
  children,
  details,
  moreLabel,
  lessLabel,
  defaultOpen = false,
}: {
  rank: 1 | 2 | 3;
  tag: string;
  title: string;
  text?: string;
  children?: ReactNode;
  details?: ReactNode;
  moreLabel?: string;
  lessLabel?: string;
  defaultOpen?: boolean;
}) {
  const rankClass = rank === 1 ? styles.p1 : rank === 2 ? styles.p2 : styles.p3;
  const [open, setOpen] = useState(defaultOpen);
  const panelId = useId();
  const foldable = details != null && moreLabel != null && lessLabel != null;
  return (
    <article className={cx(styles.prio, rankClass)}>
      <div className={styles.prioN}>{rank}</div>
      <div>
        <p className={styles.prioTag}>{tag}</p>
        <h3>{title}</h3>
        {text ? <p>{text}</p> : null}
        {children}
        {foldable ? (
          <>
            {/* `hidden` plutôt qu'un démontage : le contenu replié sort de
                l'arbre d'accessibilité ET du parcours clavier, au lieu de
                rester atteignable derrière un encart fermé. */}
            <div id={panelId} hidden={!open}>
              {details}
            </div>
            <button
              type="button"
              className={styles.link}
              aria-expanded={open}
              aria-controls={panelId}
              onClick={() => setOpen((was) => !was)}
            >
              {open ? lessLabel : moreLabel}
              <ChevronDown
                size={15}
                strokeWidth={2.5}
                className={cx(styles.chevron, open && styles.chevronUp)}
                aria-hidden
              />
            </button>
          </>
        ) : null}
      </div>
    </article>
  );
}

/**
 * Le ton du remplissage d'une jauge.
 *
 * 🛑 Il se **passe**, il ne se dérive d'aucun nombre : l'appelant le tient d'un
 * état servi. Même palette que les segments de parcours — vert = tenu, bleu =
 * en cours, ambre = à vérifier, rouge = prioritaire, neutre = non mesuré.
 * Miroir Flutter : `SfBarTone` (`sejour_kit.dart`).
 */
export type BarTone = Tone | "now";

const barToneClass: Record<BarTone, string> = {
  ok: styles.barOk,
  now: styles.barNow,
  warn: styles.barWarn,
  hot: styles.barHot,
  muted: styles.barMuted,
};

/**
 * Barre de progression fine d'une priorité (compétences validées).
 *
 * 🛑 **Aucun chiffre n'est rendu** : c'est une part parcourue, jamais une note
 * ni un pourcentage annoncé au candidat. Le `%` ne sert qu'à poser la largeur.
 */
export function ProgressMini({
  ratio,
  label,
  tone = "now",
}: {
  ratio: number;
  label?: string;
  /** Défaut `now` : c'est le bleu que la brique rendait avant. */
  tone?: BarTone;
}) {
  const pct = Math.round(Math.min(Math.max(ratio, 0), 1) * 100);
  /* `<span>` et non `<div>` : la jauge est rendue **dans** une ligne d'épreuve
     (`LevelRow`), donc à l'intérieur d'un lien — un `<div>` y serait un nœud de
     flux dans du contenu phrasé. `display: block` lui garde exactement le même
     rendu chez ses appelants d'origine. */
  return (
    <span className={cx(styles.progressMini, barToneClass[tone])} aria-label={label}>
      <span style={{ width: `${pct}%` }} />
    </span>
  );
}

/** Sous-ligne d'une priorité : une compétence et son état. */
export function SkillRow({ label, state }: { label: string; state: StepState }) {
  const Icon = STEP_ICON[state];
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

/**
 * Une étape de parcours. `pill` est **servi** par l'appelant (le libellé de
 * l'état d'étape, « Série terminée · 5/5 »…) : le kit ne compose aucune phrase
 * et n'en déduit aucune d'un compteur.
 */
export type PathStep = { label: string; state: StepState; pill?: string };

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
            className={cx(
              s.state === "done" && styles.on,
              s.state === "verify" && styles.verifySeg,
              (s.state === "now" || s.state === "doing") && styles.nowSeg,
            )}
          />
        ))}
      </div>
      {steps.map((s, i) => (
        <PathRow key={`${s.label}-${i}`} label={s.label} state={s.state} pill={s.pill} />
      ))}
    </Card>
  );
}

/**
 * Une ligne de parcours. 🛑 **Le libellé de la pastille vient de l'appelant**,
 * jamais d'ici : il porte un état **servi**, pas une phrase du kit. Sans `pill`
 * la ligne n'en affiche aucune.
 */
export function PathRow({ label, state, pill }: {
  label: string;
  state: StepState;
  pill?: string;
}) {
  const Icon = STEP_ICON[state];
  return (
    <div
      className={cx(
        styles.step,
        state === "done" && styles.isDone,
        state === "verify" && styles.isVerify,
        (state === "now" || state === "doing") && styles.isNext,
      )}
    >
      <span className={styles.bullet}>
        <Icon size={16} strokeWidth={2} aria-hidden />
      </span>
      {state === "todo" ? <span>{label}</span> : <b>{label}</b>}
      {pill ? <span className={styles.nowPill}>{pill}</span> : null}
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

/* ---------------------------------------------- Parcours TCF (la timeline) */

/**
 * L'état d'une étape du **parcours TCF**, tel que le serveur le sert
 * (`JourneyStepDto.status`).
 *
 * 🛑 **Rien n'est déduit ici** : ni d'un compteur, ni d'une position dans la
 * liste. `skipped` — « Déjà maîtrisée » / « Déjà travaillée » — est une nuance
 * de rendu de `completed` que le **serveur** dérive de l'ordre de clôture, et
 * `current` dépend du verrou du candidat. Un front qui les recalculerait
 * finirait par désigner une autre étape que le serveur.
 *
 * ⚠️ **Distinct de {@link StepState}**, qui décrit une étape de *tâche* (les
 * 5 petits sujets d'une compétence). Deux objets, deux vocabulaires : les
 * confondre ferait cocher en vert une série finie qui n'a rien prouvé.
 *
 * ⚠️ Miroir de `SfJourneyState` (`mobile .../core/widgets/sejour/sejour_kit.dart`).
 */
export type JourneyState = "done" | "skipped" | "current" | "upcoming";

/**
 * La nature d'une étape, pour son marqueur.
 *
 * 🛑 Un **examen** porte un double cercle et non un rond plein : c'est un
 * *checkpoint*, pas une tâche de plus — le candidat doit le repérer de loin
 * dans la file.
 */
export type JourneyKind = "step" | "exam";

/**
 * Une ligne du parcours.
 *
 * @param badge  **servi par l'appelant** — « MAINTENANT », « EXAMEN », « Déjà
 *               maîtrisée ». Le kit ne compose aucune phrase.
 * @param locked l'étape ne peut pas être menée à son terme avec l'accès du
 *               candidat. 🛑 **Elle reste à sa place** : on ajoute un cadenas,
 *               on ne déplace ni ne masque rien (R16).
 */
export function JourneyRow({
  title,
  subtitle,
  state,
  kind = "step",
  badge,
  locked,
  onClick,
}: {
  title: string;
  subtitle?: string;
  state: JourneyState;
  kind?: JourneyKind;
  badge?: string;
  locked?: boolean;
  onClick?: () => void;
}) {
  const done = state === "done" || state === "skipped";
  const Icon = done ? Check : kind === "exam" ? Target : state === "current" ? ArrowRight : Circle;
  const body = (
    <>
      <span className={cx(styles.jBullet, kind === "exam" && !done && styles.jExam)}>
        <Icon size={15} strokeWidth={2.2} aria-hidden />
      </span>
      <span className={styles.jText}>
        {state === "upcoming" ? <span>{title}</span> : <b>{title}</b>}
        {subtitle ? <small>{subtitle}</small> : null}
      </span>
      {locked ? <Lock size={14} strokeWidth={2} aria-hidden className={styles.jLock} /> : null}
      {badge ? <span className={styles.jBadge}>{badge}</span> : null}
    </>
  );
  const className = cx(
    styles.jRow,
    done && styles.jDone,
    state === "current" && styles.jCurrent,
    locked && styles.jLocked,
  );
  return onClick ? (
    <button type="button" className={cx(className, styles.jRowButton)} onClick={onClick}>
      {body}
    </button>
  ) : (
    <div className={className}>{body}</div>
  );
}

/**
 * La file d'étapes, avec son rail vertical.
 *
 * 🛑 **L'ordre est celui du serveur**, jamais retrié : la position d'une étape
 * *est* la décision d'ordonnancement que le parcours a prise, et elle ne se
 * recalcule pas.
 */
export function JourneyList({ children }: { children: ReactNode }) {
  return <div className={styles.journey}>{children}</div>;
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
  variant = "default",
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
  /**
   * 🛑 `"verify"` change **la carte**, pas seulement son bouton. Quand la série
   * de petits sujets se termine, le nom de la compétence reste le même : sans
   * accent propre, le candidat lit « rien n'a bougé » alors que l'action a
   * changé de nature. Miroir de `SfNowCardVariant` côté mobile.
   */
  variant?: "default" | "verify";
}) {
  return (
    <article className={cx(styles.now, variant === "verify" && styles.isVerify)}>
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

/* ========================================================================== */
/* Maquette « Où vous en êtes » + « Vos résultats » (propriétaire, 2026-09-16) */
/*                                                                            */
/* ⚠️ « Où vous en êtes » a été REFAIT le même jour sur une seconde maquette   */
/* (`ou_en_vous_v2.html`) : la grille de cartes compactes est devenue une      */
/* LISTE verticale dans une seule carte, chaque ligne portant une échelle      */
/* CECRL à six crans. `LevelCard`, `LevelGrid` et `GoalRibbon` sont            */
/* **supprimées** avec leurs classes — refonte = suppression de l'ancien.     */
/* ========================================================================== */

/**
 * Le ton d'une **pastille de statut** — le même contrat que celui d'une jauge,
 * mais posé sur du texte : `barToneClass` ne teinte qu'un enfant de barre.
 */
const statusToneClass: Record<BarTone, string> = {
  ok: styles.toneOk,
  now: styles.toneNow,
  warn: styles.toneWarn,
  hot: styles.toneHot,
  muted: styles.toneMuted,
};

/**
 * Un cran de l'échelle CECRL, **composé par l'appelant**
 * (`accueilEchelons`, `lib/progres.ts` ⇄ `progres_labels.dart`).
 *
 * 🛑 Le kit ne sait ni ce qu'est un palier, ni lequel est atteint : il reçoit
 * des crans déjà situés, et il en rend autant qu'on lui en donne — c'est
 * l'appelant qui décide que l'échelle s'arrête à B2. Miroir Flutter :
 * `SfLadderStep`.
 */
export type LadderStep = {
  /** Ce qui s'écrit sous le cran (« A1 »…). Décoratif : l'échelle est un `img`. */
  label: string;
  /** `done` = palier acquis · `target` = le cran visé · `empty` = le reste. */
  state: "done" | "target" | "empty";
  /** Le palier ACTUEL du candidat — au plus un cran, aucun quand rien n'est mesuré. */
  current: boolean;
  /** Le palier VISÉ — au plus un cran, aucun sans démarche déclarée. */
  goal: boolean;
};

/**
 * **L'échelle CECRL** — l'élément signature de la maquette v2 : les crans du
 * parcours et leurs libellés, sous la ligne d'une épreuve.
 *
 * 🛑 **Ce n'est pas une jauge et elle n'affiche aucun chiffre** : elle situe un
 * **palier servi** face à un **objectif servi**. Aucun pourcentage de
 * progression vers un palier n'est calculé ni montré — la règle qui l'interdit
 * tient toujours.
 *
 * 🛑 **Rendue en `role="img"`** avec un `aria-label` composé par l'appelant :
 * les libellés sont `aria-hidden`, un lecteur d'écran n'a pas à épeler quatre
 * crans pour comprendre « Niveau B1, objectif B2 ».
 *
 * Miroir Flutter : `SfLevelLadder`.
 */
export function LevelLadder({
  steps,
  label,
  dim,
}: {
  steps: LadderStep[];
  /** Ce que l'échelle DIT. Jamais dérivé ici. */
  label: string;
  /**
   * Épreuve jamais mesurée : les crans passent en contour, sans remplissage.
   * 🛑 **Passé, jamais deviné** d'un cran vide — une épreuve `<A1` n'a elle non
   * plus aucun cran rempli, et ce n'est pas la même chose.
   */
  dim?: boolean;
}) {
  return (
    <span className={cx(styles.ladder, dim && styles.isDim)} role="img" aria-label={label}>
      <span className={styles.ladderTrack}>
        {steps.map((step) => (
          <i
            key={step.label}
            className={cx(
              styles.ladderStep,
              step.state === "done" && styles.isDone,
              step.state === "target" && styles.isTarget,
            )}
          />
        ))}
      </span>
      <span className={styles.ladderLabels} aria-hidden>
        {steps.map((step) => (
          <span
            key={step.label}
            className={cx(
              step.current && styles.isCur,
              !step.current && step.goal && styles.isTgt,
            )}
          >
            {step.label}
          </span>
        ))}
      </span>
    </span>
  );
}

/**
 * **La légende de l'échelle CECRL** — les quatre paliers, écrits **une seule
 * fois** pour toute la liste.
 *
 * 🛑 **Elle remplace quatre répétitions** (2026-09-17) : chaque ligne d'épreuve
 * écrivait « A1 A2 B1 B2 » sous son échelle, soit la même échelle quatre fois
 * et une ligne de texte par épreuve. Le palier atteint se lit déjà en gros à
 * droite de la ligne, et l'objectif est annoncé par le bandeau au-dessus : les
 * libellés par ligne n'ajoutaient rien et coûtaient une hauteur d'écran sur
 * téléphone.
 *
 * 🛑 **Le cran d'objectif reste marqué en rouge** : c'est le seul repère des
 * libellés qui portait une information, et il est **global** — le même pour les
 * quatre épreuves.
 *
 * ⚠️ **Elle disparaît au palier DESKTOP** (`@media`), où la liste passe à deux
 * colonnes — une légende ne peut pas s'aligner sur deux échelles à la fois — et
 * où les libellés par ligne reviennent, la hauteur n'y étant pas une
 * contrainte. C'est une media query sur des primitives existantes, pas une
 * seconde anatomie. Miroir Flutter : `SfLadderLegend` (sans palier desktop :
 * l'app est en portrait téléphone).
 */
export function LadderLegend({
  labels,
  goalIndex,
}: {
  /** Les paliers de l'échelle, dans l'ordre. **Passés**, jamais dérivés ici. */
  labels: string[];
  /** Le rang du palier visé. `null` sans démarche déclarée. */
  goalIndex: number | null;
}) {
  return (
    <p className={styles.ladderLegend} aria-hidden>
      {labels.map((label, i) => (
        <span key={label} className={cx(i === goalIndex && styles.isTgt)}>
          {label}
        </span>
      ))}
    </p>
  );
}

/**
 * **La ligne d'une épreuve** — le `.test` de la maquette v2 : repère court en
 * pastille mono, intitulé, statut à pastille colorée, palier à droite, puis
 * l'échelle et sa ligne d'action.
 *
 * 🛑 **Cette brique ne classe rien.** Tout lui arrive **composé** par
 * `accueilEpreuve*` (`lib/progres.ts` ⇄ `progres_labels.dart`).
 *
 * Miroir Flutter : `SfLevelRow`.
 */
export function LevelRow({
  mark,
  title,
  status,
  tone,
  level,
  measured,
  scale,
  cta,
  ctaPrimary,
  href,
  onClick,
  busy,
}: {
  /** Repère court (« CO »). `null` quand rien n'en sert — on n'en invente pas. */
  mark: string | null;
  title: string;
  /** L'état en un mot. `null` = rien à dire, jamais « rien à faire ». */
  status: string | null;
  /** Le ton de la pastille de statut. */
  tone: BarTone;
  /**
   * Le palier servi, ou le mot d'une absence de mesure. `null` retire la
   * pastille : le civique n'a aucun palier CECRL servi.
   */
  level: string | null;
  /**
   * Y a-t-il une mesure derrière `level` ?
   *
   * 🛑 **Passé, jamais deviné du texte** : comparer un libellé pour décider
   * d'une couleur ferait dépendre l'apparence d'une chaîne reformulable.
   */
  measured: boolean;
  /** L'échelle, ou la jauge du civique. `null` quand rien ne la sert. */
  scale?: ReactNode;
  cta: string;
  /** Le CTA devient un bouton plein — l'action qui manque, pas celle qui relit. */
  ctaPrimary?: boolean;
  /** Où mène la ligne. `null` quand elle **lance** au lieu de naviguer. */
  href: string | null;
  onClick?: () => void;
  busy?: boolean;
}) {
  const body = (
    <>
      <span className={styles.levelRowTop}>
        {mark ? <span className={styles.levelMark}>{mark}</span> : null}
        <span className={styles.levelRowId}>
          <span className={styles.levelRowName}>{title}</span>
          {status ? (
            <span className={cx(styles.levelRowStatus, statusToneClass[tone])}>{status}</span>
          ) : null}
        </span>
        {level ? (
          <span className={cx(styles.levelChip, !measured && styles.isNa)}>{level}</span>
        ) : null}
      </span>
      {scale ? <span className={styles.levelRowScale}>{scale}</span> : null}
      {/* 🛑 **Plus d'« Objectif B2 » par ligne** (2026-09-17) : il valait la
          MÊME chaîne sur les quatre lignes, et le bandeau juste au-dessus dit
          déjà « Atteindre B2 partout ». Quatre répétitions du bandeau. */}
      <span className={styles.levelRowMeta}>
        <span className={cx(styles.levelRowCta, ctaPrimary && styles.isPrimary)}>
          {cta}
          {ctaPrimary ? null : <ArrowRight size={14} strokeWidth={2.6} aria-hidden />}
        </span>
      </span>
    </>
  );
  /* Sans repère court (le civique), l'échelle et la ligne de pied n'ont rien
     sous quoi s'aligner : elles reprennent le bord du texte. */
  const cls = cx(styles.levelRowLink, !measured && styles.isTodo, !mark && styles.isFlush);
  return (
    <li className={styles.levelRow}>
      {href ? (
        <Link href={href} className={cls}>
          {body}
        </Link>
      ) : (
        <button type="button" className={cls} onClick={onClick} disabled={busy}>
          {body}
        </button>
      )}
    </li>
  );
}

/**
 * La liste des épreuves — **une seule colonne** sur téléphone, comme la
 * maquette (calée sur 440 px).
 *
 * ⚠️ **Deux colonnes au palier desktop du kit (≥ 960 px), et rien de plus** :
 * une échelle de six crans étirée sur 1 000 px ne veut plus rien dire. C'est
 * une **media query sur une primitive existante**, donc **sans miroir Flutter**
 * — l'app est en portrait téléphone. Le pendant de `.deskGrid2`.
 *
 * Miroir Flutter : `SfLevelList`.
 */
export function LevelList({ children }: { children: ReactNode }) {
  return <ul className={styles.levelList}>{children}</ul>;
}

/**
 * **Le bandeau d'objectif** — la bande bleue pleine de la maquette v2 :
 * cocarde, intitulé + valeur, puis le compteur « 3 / 4 », ses pastilles et le
 * mot qu'elles comptent.
 *
 * 🛑 `count` et `total` sont **passés**, jamais comptés ici — et `total` pose
 * le nombre de pastilles, donc l'écran ne peut pas en dessiner quatre quand le
 * serveur en publie trois.
 *
 * ⚠️ **Remplace `GoalRibbon`** (bande claire à filet, maquette v1).
 * Miroir Flutter : `SfGoalBanner`.
 */
export function GoalBanner({
  label,
  value,
  count,
  total,
  caption,
}: {
  label: string;
  value: string;
  /** Le nombre de mesures faites. `null` retire le compteur entier. */
  count?: number | null;
  total?: number | null;
  caption?: string;
}) {
  const pips = count != null && total != null && total > 0;
  return (
    <div className={styles.goalBanner}>
      <span className={styles.goalCocarde} aria-hidden />
      <span className={styles.goalBannerBody}>
        <small>{label}</small>
        <b>{value}</b>
      </span>
      {pips ? (
        <span className={styles.goalCount}>
          <b>{`${count} / ${total}`}</b>
          <span className={styles.goalPips} aria-hidden>
            {Array.from({ length: total }, (_, i) => (
              <i key={i} className={cx(i < count && styles.isOn)} />
            ))}
          </span>
          {caption ? <small>{caption}</small> : null}
        </span>
      ) : null}
    </div>
  );
}

/**
 * La note discrète de bas de carte (`.micro-note`) : une pastille « i » et une
 * phrase fine. Miroir Flutter : `SfMicroNote`.
 */
export function MicroNote({ children }: { children: ReactNode }) {
  return (
    <p className={styles.microNote}>
      <span className={styles.microNoteIco} aria-hidden>
        <Info size={11} strokeWidth={2.6} />
      </span>
      <span>{children}</span>
    </p>
  );
}

/**
 * L'en-tête d'un panneau : son titre, et ce qu'il contient en sous-titre.
 *
 * `lead` est la variante **de tête de carte** (maquette « Où vous en êtes »
 * v2) : titre éditorial plus grand et sous-titre en phrase de cadrage, là où la
 * variante par défaut coiffe un bloc à l'intérieur d'une page de résultats.
 * 🛑 Une **variante**, pas une seconde primitive.
 */
export function PanelHead({
  title,
  sub,
  lead,
}: {
  title: string;
  sub?: string | null;
  lead?: boolean;
}) {
  return (
    <div className={cx(styles.panelHead, lead && styles.isLead)}>
      <h3 className={styles.panelTitle}>{title}</h3>
      {sub ? <p className={styles.panelSub}>{sub}</p> : null}
    </div>
  );
}

/**
 * **Le héros d'une page de résultats** — le `.result-hero` de la maquette :
 * fond sombre de marque, le palier en très gros, l'objectif à droite, une
 * pastille d'évolution et une note de portée.
 *
 * 🛑 **Aucune valeur n'est dérivée ici** : palier, objectif et pastille
 * arrivent composés d'un fait servi. Miroir Flutter : `SfResultHero`.
 */
export function ResultHero({
  label,
  level,
  goalLabel,
  goal,
  trend,
  note,
}: {
  label: string;
  level: string;
  goalLabel: string;
  /** `null` quand aucune démarche n'est déclarée : rien vers quoi situer. */
  goal: string | null;
  /** `null` quand l'évolution est inconnue — surtout pas un « = » consolant. */
  trend?: string | null;
  note?: string | null;
}) {
  return (
    <div className={styles.resultHero}>
      <p className={styles.resultHeroLabel}>{label}</p>
      <div className={styles.resultHeroRow}>
        <span className={styles.resultHeroLevel}>{level}</span>
        {goal ? (
          <span className={styles.resultHeroGoal}>
            {goalLabel}
            <b>{goal}</b>
          </span>
        ) : null}
      </div>
      {trend ? <span className={styles.trendChip}>{trend}</span> : null}
      {note ? <p className={styles.resultHeroFoot}>{note}</p> : null}
    </div>
  );
}

/** Un point de la courbe : sa date, son palier, et sa ligne dans l'échelle. */
export type ChartPoint = {
  /** Abscisse lisible (« 11 sept. »). */
  date: string;
  /** Le palier, tel qu'il s'écrit sur la pastille. */
  level: string;
  /** Index dans `ladder`, 0 = le palier le plus haut. **Passé, jamais deviné.** */
  row: number;
};

/**
 * **La courbe d'évolution** d'une épreuve.
 *
 * 🛑 **Aucune interpolation, aucune moyenne** : un point par évaluation
 * **servie**, posé sur l'échelle de paliers que l'appelant lui donne. L'axe ne
 * porte aucun chiffre — seulement des paliers.
 *
 * Miroir Flutter : `SfLevelChart`.
 */
export function LevelChart({
  ladder,
  points,
  activeIndex,
  onSelect,
}: {
  /** Du plus haut au plus bas (« B2 », « B1 », « A2 »). */
  ladder: string[];
  /** Du plus ancien au plus récent. */
  points: ChartPoint[];
  activeIndex: number;
  onSelect: (index: number) => void;
}) {
  const rows = Math.max(ladder.length - 1, 1);
  const cols = Math.max(points.length - 1, 1);
  const y = (row: number) => (ladder.length > 1 ? (row / rows) * 100 : 50);
  const x = (i: number) => (points.length > 1 ? (i / cols) * 100 : 50);

  return (
    <div className={styles.chart}>
      <div className={styles.chartYAxis} aria-hidden>
        {ladder.map((lvl, i) => (
          <span key={lvl} className={styles.chartYLabel} style={{ top: `${y(i)}%` }}>
            {lvl}
          </span>
        ))}
      </div>
      <div className={styles.chartPlot}>
        {ladder.map((lvl, i) => (
          <span key={lvl} className={styles.chartGrid} style={{ top: `${y(i)}%` }} aria-hidden />
        ))}
        {points.length > 1 ? (
          <svg
            className={styles.chartLine}
            viewBox="0 0 100 100"
            preserveAspectRatio="none"
            aria-hidden
          >
            <polyline
              points={points.map((p, i) => `${x(i)},${y(p.row)}`).join(" ")}
              fill="none"
              stroke="var(--color-blue)"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
              vectorEffect="non-scaling-stroke"
            />
          </svg>
        ) : null}
        {points.map((p, i) => (
          <button
            key={`p-${i}`}
            type="button"
            className={cx(styles.chartDot, i === activeIndex && styles.isOn)}
            style={{ left: `${x(i)}%`, top: `${y(p.row)}%` }}
            aria-label={`${p.date} : niveau ${p.level}`}
            aria-pressed={i === activeIndex}
            onClick={() => onSelect(i)}
          />
        ))}
        {points.map((p, i) => (
          <span
            key={`d-${i}`}
            className={styles.chartDate}
            style={{ left: `${x(i)}%` }}
            aria-hidden
          >
            {p.date}
          </span>
        ))}
      </div>
    </div>
  );
}

/**
 * La rangée de filtres d'une liste. 🛑 **Les options sont servies par
 * l'appelant** : le kit ne sait pas ce qu'il filtre.
 *
 * Miroir Flutter : `SfFilterChips`.
 */
export function FilterChips<T extends string>({
  options,
  value,
  onChange,
}: {
  options: ReadonlyArray<{ id: T; label: string }>;
  value: T;
  onChange: (id: T) => void;
}) {
  return (
    <div className={styles.filterRow} role="tablist">
      {options.map((o) => (
        <button
          key={o.id}
          type="button"
          role="tab"
          aria-selected={o.id === value}
          className={cx(styles.filter, o.id === value && styles.isOn)}
          onClick={() => onChange(o.id)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

/**
 * **Une ligne d'historique dépliable** : pictogramme, intitulé + date, palier,
 * et un détail qui s'ouvre au toucher.
 *
 * Miroir Flutter : `SfHistoryRow`.
 */
export function HistoryRow({
  icon: Icon,
  title,
  date,
  level,
  detail,
  active,
  open,
  onToggle,
}: {
  icon: LucideIcon;
  title: string;
  /** `null` quand le serveur n'a pas de date — on n'en invente pas. */
  date: string | null;
  level: string;
  detail: ReactNode;
  active?: boolean;
  open: boolean;
  onToggle: () => void;
}) {
  const panelId = useId();
  return (
    <article className={cx(styles.histItem, active && styles.isOn)}>
      <button
        type="button"
        className={styles.histMain}
        aria-expanded={open}
        aria-controls={panelId}
        onClick={onToggle}
      >
        <span className={styles.histIco}>
          <Icon size={18} strokeWidth={2} aria-hidden />
        </span>
        <span className={styles.histBody}>
          <b>{title}</b>
          {date ? <small>{date}</small> : null}
        </span>
        <span className={styles.histLevel}>{level}</span>
      </button>
      {/* `hidden` plutôt qu'un démontage : le détail replié sort de l'arbre
          d'accessibilité ET du parcours clavier. */}
      <div id={panelId} className={styles.histDetail} hidden={!open}>
        {detail}
      </div>
    </article>
  );
}

/**
 * L'encart ambre de pied de page (`.footer-info`) : ce que la liste au-dessus
 * compte, et ce qu'elle ne compte pas.
 *
 * Miroir Flutter : `SfInfoNote`.
 */
export function InfoNote({ children }: { children: ReactNode }) {
  return (
    <div className={styles.infoNote}>
      <span className={styles.infoNoteIco} aria-hidden>
        <Info size={14} strokeWidth={2.4} />
      </span>
      <span>{children}</span>
    </div>
  );
}

/* ==========================================================================
   Maquettes « Plan — cycle » et « Plan — fin de cycle » (propriétaire,
   2026-09-18 ; `docs/progression/plan_cycle.html` ⇄ `cycle_termine.html`)

   🛑 Miroirs de `SfCycleProgress`, `SfBlocAccordion`, `SfExamStepBox` et
   `SfNextStepCard` côté Flutter, plus `Pill` (rattrapage web de `SfPill`). Un
   motif qui bouge d'un côté bouge de l'autre dans la même passe.

   Périmètre : la zone du Plan qui commence à « Votre parcours vers le B2 »
   (D-22). Tout ce qui est au-dessus — en-tête, bascule de module, bloc
   objectif, « À faire maintenant » — reste l'existant.
   ========================================================================== */

/**
 * **Pastille d'état autonome** — fond clair, texte du même ton.
 *
 * 🛑 Rattrapage de parité (2026-09-18) : le mobile avait `SfPill` depuis le
 * début, le web n'avait que des pastilles **internes** à des lignes
 * (`MiniPlan`, `ThemeLine`). Un écran qui voulait la même pastille devait donc
 * passer par `sejourStyles.pill` — c'est-à-dire écrire du CSS d'écran, ce que
 * la règle du dépôt interdit sur ce périmètre.
 *
 * Le `label` est **servi** : cette brique ne compose et ne classe rien.
 *
 * ⚠️ **Brique partagée** : sa taille par défaut est celle de la maquette et
 * plusieurs écrans l'appellent. `dense` est la seule variante — la pastille
 * plus petite d'une ligne d'en-tête serrée, où la largeur doit aller au **nom
 * de l'épreuve** (`BlocAccordion`, D-21). Aucun autre appelant n'est touché.
 *
 * Miroir Flutter : `SfPill` / `SfPill(dense: true)`.
 */
export function Pill({
  label,
  tone,
  dense,
}: {
  label: string;
  tone: Tone;
  /** Variante resserrée (`.status` de la maquette : 9,5 px, poids 900). */
  dense?: boolean;
}) {
  return (
    <span className={cx(styles.pill, toneClass[tone], dense && styles.dense)}>{label}</span>
  );
}

/**
 * **L'avancement du cycle** — le `.cycleIntro` de `plan_cycle.html`, et le
 * `.progressBox` de `cycle_termine.html` quand il est terminé.
 *
 * 🛑 **Barre CONTINUE, et elle porte un chiffre.** C'est ce qui la distingue
 * des deux briques voisines, qu'il ne faut surtout pas remplacer par elle :
 * - `ProgressMini` a un contrat qui **interdit tout chiffre** (« c'est une part
 *   parcourue, jamais une note ni un pourcentage annoncé au candidat ») ;
 * - `PathCard` a une barre **segmentée**, un segment par étape — elle décrit un
 *   parcours de tâche, pas l'avancement d'un cycle entier.
 *
 * Le pourcentage est **dérivé de `done` / `total`**, deux faits servis : ce
 * n'est pas un état pédagogique, seulement la lecture arithmétique du compteur
 * que `label` écrit déjà en mots.
 *
 * Miroir Flutter : `SfCycleProgress`.
 */
export function CycleProgress({
  label,
  done,
  total,
  badge,
  hint,
  complete,
}: {
  /** Le compteur en mots (« 3 étapes sur 8 terminées »), **servi**. */
  label: string;
  done: number;
  total: number;
  /** Le repère de cycle (« Cycle 2 »), **servi**. Absent ⇒ rien à droite. */
  badge?: string;
  /** La phrase sous la barre, **servie**. */
  hint?: string;
  /**
   * L'état 100 % : la barre se termine en vert et le pourcentage prend la place
   * du badge, comme dans `cycle_termine.html`.
   *
   * 🛑 **Passé, jamais déduit de `done === total`** : un cycle peut afficher
   * « 8 sur 8 » sans être clos côté serveur (un examen reste à passer), et le
   * kit n'a pas à en décider.
   */
  complete?: boolean;
}) {
  const ratio = total > 0 ? Math.max(0, Math.min(1, done / total)) : 0;
  const pct = complete && total <= 0 ? 100 : Math.round(ratio * 100);
  return (
    <Card>
      <div className={styles.cycleTop}>
        <b>{label}</b>
        {complete ? (
          <span className={styles.cyclePct}>{`${pct} %`}</span>
        ) : badge ? (
          <span className={styles.cycleBadge}>{badge}</span>
        ) : null}
      </div>
      <div className={cx(styles.cycleBar, complete && styles.isDone)} aria-hidden>
        <i style={{ width: `${complete ? 100 : pct}%` }} />
      </div>
      {hint ? <p className={styles.cycleHint}>{hint}</p> : null}
    </Card>
  );
}

/**
 * **L'en-tête d'un bloc d'épreuve, dépliable** — le `.examGroup` de
 * `plan_cycle.html` : repère d'épreuve, nom en clair, méta, pastille d'état, et
 * un corps qui s'ouvre.
 *
 * 🛑 **L'état d'ouverture est EXTERNE** (`open` + `onToggle`), jamais interne :
 * l'écran doit pouvoir n'en déplier **qu'un** — le bloc courant. C'est
 * exactement ce que `Prio` ne sait pas faire (son `useState` est privé), et
 * c'est pourquoi cette brique existe au lieu d'une variante de `Prio`.
 *
 * 🛑 **Le nom de l'épreuve est EN CLAIR** (D-21) : « Compréhension orale », pas
 * « CO » seul, pas « lot », pas « step ». Le vocabulaire interne reste interne.
 * Corollaire : il **ne se tronque jamais** et doit tenir sur une ligne. C'est
 * la maquette qui le garantit — sous 360 px elle **masque l'état** et l'en-tête
 * passe à deux colonnes (`.blocStatus`, `@media (max-width: 360px)`), plutôt
 * que de rétrécir le titre. Miroir Flutter présent : 360 px est un téléphone.
 *
 * ⚠️ Le corps est rendu **replié, pas démonté** (`hidden`) : il sort de l'arbre
 * d'accessibilité et du parcours clavier, comme chez `Prio` et `HistoryRow`.
 *
 * Composition attendue : une `JourneyList` de `JourneyRow` (les étapes, avec
 * leur rail), puis un `ExamStepBox`. Le corps ne porte donc aucun retrait de
 * rail — c'est la liste qui a le sien.
 *
 * Miroir Flutter : `SfBlocAccordion`.
 */
export function BlocAccordion({
  mark,
  title,
  meta,
  status,
  open,
  onToggle,
  current,
  children,
}: {
  /** Le repère court de l'épreuve (« CO »), en mono : étiquette technique. */
  mark: string;
  /** Le nom de l'épreuve **en clair**, servi. */
  title: string;
  /** « 1 compétence restante · puis examen », **servi**. */
  meta: string;
  /** Le libellé d'état et son ton, tous deux **servis**. */
  status: { label: string; tone: Tone };
  open: boolean;
  onToggle: () => void;
  /** Le bloc courant : liseré et repère accentués. **Servi**, jamais déduit. */
  current?: boolean;
  children: ReactNode;
}) {
  const panelId = useId();
  return (
    <article className={cx(styles.blocGroup, current && styles.isCurrent)}>
      <button
        type="button"
        className={styles.blocHead}
        aria-expanded={open}
        aria-controls={panelId}
        onClick={onToggle}
      >
        <span className={styles.blocMark}>{mark}</span>
        <span className={styles.blocId}>
          <span className={styles.blocTitle}>{title}</span>
          <span className={styles.blocMeta}>{meta}</span>
        </span>
        {/* 🛑 Sous 360 px, la maquette MASQUE l'état et l'en-tête passe à deux
            colonnes : c'est comme ça que le nom de l'épreuve tient sur une
            ligne sur les téléphones les plus étroits. Le masquage est dans
            `.blocStatus`, pas ici — un rendu conditionnel en JS n'a pas de
            miroir dans une media query. */}
        <span className={styles.blocStatus}>
          <Pill label={status.label} tone={status.tone} dense />
        </span>
        {/* La seule affordance visible qu'un bloc se déplie : la maquette compte
            sur le curseur, qui n'existe pas au doigt. Le chevron PIVOTE, il ne
            se remplace pas — aucun saut de largeur à l'ouverture. */}
        <ChevronDown
          size={18}
          strokeWidth={2.5}
          className={cx(styles.blocChevron, open && styles.chevronUp)}
          aria-hidden
        />
      </button>
      <div id={panelId} className={styles.blocBody} hidden={!open}>
        {children}
      </div>
    </article>
  );
}

/**
 * **L'encart d'examen imbriqué en fin de bloc** — le `.examBox` de
 * `plan_cycle.html`.
 *
 * 🛑 **`locked` rend l'encart inerte** : ni bouton, ni curseur, ni `onTap`. Le
 * contenu reste **entièrement lisible** — on ajoute un verrou, on ne masque
 * rien (R16, contradiction #1 tranchée le 2026-08-21).
 *
 * `state` porte le libellé **servi** (« Verrouillé », « Disponible ») et son
 * ton : `muted` quand il n'y a rien à faire, `now` quand l'examen s'ouvre.
 *
 * Miroir Flutter : `SfExamStepBox`.
 */
export function ExamStepBox({
  title,
  state,
  note,
  locked,
  onClick,
}: {
  /** « Examen blanc · Compréhension orale », ou la mesure d'un niveau. Servi. */
  title: string;
  state: { label: string; tone: BarTone };
  /** La phrase de condition, **servie**. */
  note: string;
  locked: boolean;
  onClick?: () => void;
}) {
  const body = (
    <>
      <span className={styles.examBoxTop}>
        <b>{title}</b>
        <span className={cx(styles.examBoxState, statusToneClass[state.tone])}>
          {state.label}
        </span>
        {locked ? <Lock size={13} strokeWidth={2.2} aria-hidden /> : null}
      </span>
      <span className={styles.examBoxNote}>{note}</span>
    </>
  );
  if (locked || !onClick) {
    return <div className={cx(styles.examBox, locked && styles.isLocked)}>{body}</div>;
  }
  return (
    <button type="button" className={cx(styles.examBox, styles.isOpen)} onClick={onClick}>
      {body}
    </button>
  );
}

/** Un fait de la carte de fin de cycle : une valeur et ce qu'elle nomme. */
export type NextStepFact = { value: string; label: string };

/**
 * **La carte de fin de cycle** — le `.finalCard` de `cycle_termine.html`, et
 * 🛑 **la seule primitive du kit à DEUX actions**.
 *
 * C'est la raison de son existence : aucune brique n'a deux emplacements
 * d'action (`NowCard` en a un, `Sticky` en porte une, `Cta` est un bouton). Le
 * choix « passer l'examen complet » / « actualiser mon plan sans examen » est
 * un vrai choix, et le second terme ne doit pas se lire comme un renoncement —
 * d'où une action **discrète mais entière** sous le CTA, pas un lien de pied.
 *
 * 🛑 **Aucune phrase n'est écrite ici** : `eyebrow`, `title`, `text`, les
 * `facts` et les deux libellés d'action arrivent tous en props.
 *
 * Miroir Flutter : `SfNextStepCard`.
 */
export function NextStepCard({
  eyebrow,
  title,
  text,
  facts,
  primary,
  secondary,
}: {
  eyebrow: string;
  title: string;
  text: string;
  /** Les repères de l'examen (3 dans la maquette). Vide ⇒ aucune grille. */
  facts: NextStepFact[];
  primary: { label: string; onClick: () => void };
  /**
   * 🛑 **Facultative, et c'est une vraie issue du produit** : à la fin d'un
   * cycle de mesure, « passer l'examen blanc complet » n'a plus de sens — il ne
   * reste qu'une action. Absente, la carte n'affiche **rien** à sa place : on
   * ne fabrique pas un second terme pour tenir la forme.
   */
  secondary?: { label: string; onClick: () => void };
}) {
  return (
    <section className={styles.nextStep}>
      <p className={styles.nextEyebrow}>{eyebrow}</p>
      <h3 className={styles.nextTitle}>{title}</h3>
      <p className={styles.nextText}>{text}</p>
      {facts.length > 0 ? (
        <div className={styles.nextFacts}>
          {facts.map((fact) => (
            <div key={fact.label} className={styles.nextFact}>
              <b>{fact.value}</b>
              <span>{fact.label}</span>
            </div>
          ))}
        </div>
      ) : null}
      <div className={styles.nextActions}>
        {/* Le CTA rouge est celui du kit : une seule définition de bouton
            principal, ici comme partout. */}
        <Cta onClick={primary.onClick}>{primary.label}</Cta>
        {secondary ? (
          <button type="button" className={styles.nextSecondary} onClick={secondary.onClick}>
            {secondary.label}
          </button>
        ) : null}
      </div>
    </section>
  );
}

/* ==========================================================================
   Maquette « Ma progression — historique des cycles » (propriétaire,
   2026-09-18 ; `docs/progression/histo_cycle.html`)

   🛑 Miroirs de `SfStatGrid` et `SfHeroBanner` côté Flutter. Un motif qui
   bouge d'un côté bouge de l'autre dans la même passe.
   ========================================================================== */

/**
 * Une colonne de compteurs : une valeur et ce qu'elle nomme.
 *
 * Miroir Flutter : `SfStat`.
 */
export type Stat = { value: string; label: string };

/**
 * **La rangée de compteurs** — le `.stats` de `histo_cycle.html`, et le
 * `.sf-stat-grid` des cartes d'intro.
 *
 * 🛑 **Le nombre de colonnes suit la liste** : un compteur que le serveur ne
 * sert pas ne s'affiche pas plutôt que de s'inventer un zéro.
 *
 * 🛑 **Rien n'est compté ici.** `value` arrive déjà en texte : cette brique ne
 * somme rien et ne classe rien.
 *
 * Rattrapage de parité (2026-09-18) : le mobile avait `SfStatGrid` depuis le
 * début, le web n'avait que la classe CSS — un écran qui voulait les mêmes
 * compteurs devait donc écrire son propre balisage, ce que la règle du dépôt
 * interdit sur ce périmètre.
 *
 * Miroir Flutter : `SfStatGrid`.
 */
export function StatGrid({
  stats,
  onHero,
  accentIndex,
}: {
  stats: Stat[];
  /**
   * Les compteurs sont posés **sur un fond de marque** (`HeroBanner`) : tuiles
   * translucides, valeur blanche, libellé adouci. Sans lui, la rangée est nue
   * sur fond clair, valeur bleue et texte centré.
   */
  onHero?: boolean;
  /**
   * Le compteur **accentué** de la maquette (celui du milieu). 🛑 **Passé, et
   * c'est une décision d'ÉCRAN** : le kit n'élit pas le chiffre important.
   */
  accentIndex?: number;
}) {
  return (
    <div className={cx(styles.statGrid, onHero && styles.isOnHero)}>
      {stats.map((stat, index) => (
        <div
          key={stat.label}
          className={cx(styles.stat, index === accentIndex && styles.isAccent)}
        >
          <b>{stat.value}</b>
          <span>{stat.label}</span>
        </div>
      ))}
    </div>
  );
}

/**
 * **Le bandeau de tête d'un écran d'archive** — le `.hero` de
 * `histo_cycle.html` : fond de marque, œil-de-bœuf, titre éditorial, phrase de
 * cadrage, puis ce que l'écran y pose (les compteurs, dans la maquette).
 *
 * 🛑 **Distinct des deux briques voisines**, qu'il ne faut pas remplacer par
 * lui :
 * - `ResultHero` porte **un palier** en très gros — c'est un résultat, pas une
 *   introduction ;
 * - `NextStepCard` porte **deux actions** — c'est une décision à prendre.
 *
 * Ce bandeau, lui, n'a **aucune action** : il présente. C'est ce qui lui évite
 * d'être une variante de l'un ou de l'autre.
 *
 * 🛑 **Aucune phrase n'est écrite ici** : `eyebrow`, `title` et `text`
 * arrivent tous en props.
 *
 * Miroir Flutter : `SfHeroBanner`.
 */
export function HeroBanner({
  eyebrow,
  title,
  text,
  children,
}: {
  eyebrow: string;
  title: string;
  /** La phrase de cadrage. Absente ⇒ rien à sa place. */
  text?: string;
  /** Ce que l'écran pose sous la phrase. Absent ⇒ le bandeau s'arrête là. */
  children?: ReactNode;
}) {
  return (
    <section className={styles.heroBanner}>
      <p className={styles.heroEyebrow}>
        <i className={styles.heroDot} aria-hidden />
        {eyebrow}
      </p>
      <h2 className={styles.heroTitle}>{title}</h2>
      {text ? <p className={styles.heroText}>{text}</p> : null}
      {children ? <div className={styles.heroBody}>{children}</div> : null}
    </section>
  );
}
