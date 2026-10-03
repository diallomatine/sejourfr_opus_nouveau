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
import { useAppBarBack } from "@/app/_components/AppBarTitle";
import {
  ArrowRight,
  BadgeCheck,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Circle,
  CircleDot,
  Clock,
  Info,
  ListChecks,
  Lock,
  Minus,
  Star,
  Target,
  AlertCircle,
  X,
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

export function Top({
  backTo,
  onBack,
  kicker,
  title,
  lead,
  badge,
}: {
  backTo?: string;
  onBack?: () => void;
  kicker?: string;
  title: string;
  /**
   * La phrase de cadrage sous le titre (`.hero-copy` de la maquette).
   *
   * 🛑 Une **variante** de l'en-tête, pas une primitive de plus : un écran qui
   * s'annonce en trois lignes — œil-de-bœuf, titre, phrase — est le même motif
   * que celui qui s'annonce en deux. Miroir Flutter : `SfTop.lead`.
   */
  lead?: string;
  badge?: string;
}) {
  /* La flèche de retour monte dans la barre du haut du shell connecté — le
     chevron de l'en-tête s'efface alors (`in-bar-back`). */
  const retourDansLaBarre = useAppBarBack(
    backTo ? { fallbackHref: backTo } : onBack ? { fallbackHref: "/dashboard", onBack } : null,
  );
  /* 🛑 **L'en-tête est TOUJOURS aligné à gauche** (arbitrage du propriétaire,
     2026-09-12). Il **révoque** `.topPlain`, qui centrait sous 620 px un
     en-tête sans flèche de retour : un titre centré au-dessus d'un contenu
     entièrement calé à gauche se lit comme un bandeau, pas comme le titre de la
     page — et il ne s'aligne ni sur la bascule de parcours, ni sur les cartes
     en dessous. Même retrait côté mobile (`SfTop`) dans la même passe. */
  return (
      <header className={styles.top}>
        {backTo ? (
          <Link
            href={backTo}
            className={cx(styles.iconBtn, retourDansLaBarre && "in-bar-back")}
            aria-label="Retour"
          >
            <ChevronLeft size={24} strokeWidth={2} aria-hidden />
          </Link>
        ) : onBack ? (
          <button
            type="button"
            onClick={onBack}
            className={cx(styles.iconBtn, retourDansLaBarre && "in-bar-back")}
            aria-label="Retour"
          >
            <ChevronLeft size={24} strokeWidth={2} aria-hidden />
          </button>
        ) : null}
        <div className={styles.topText}>
          {kicker ? <p className={styles.kicker}>{kicker}</p> : null}
          <h1 className={styles.title}>{title}</h1>
          {lead ? <p className={styles.topLead}>{lead}</p> : null}
          {badge ? <span className={styles.badge}>{badge}</span> : null}
        </div>
      </header>
  );
}

/**
 * **La tête d'un écran de transition** : une croix de fermeture à gauche, un
 * œil-de-bœuf à droite.
 *
 * 🛑 **Ce n'est pas une variante de `Top`**, et c'est la différence qui compte :
 * `Top` annonce une **page** (retour en chevron, titre en `h1`) ; celui-ci
 * coiffe un écran **qu'on ferme** — une
 * étape posée par-dessus, sans titre, dont le contenu commence par son héros.
 * Les deux maquettes de l'écran de déblocage du Plan le montrent ainsi.
 *
 * Miroir Flutter : `SfSheetHead`.
 */
export function SheetHead({
  eyebrow,
  onClose,
  closeLabel = "Fermer",
}: {
  eyebrow: string;
  onClose: () => void;
  closeLabel?: string;
}) {
  return (
    <header className={styles.sheetHead}>
      <button type="button" onClick={onClose} className={styles.iconBtn} aria-label={closeLabel}>
        <X size={22} strokeWidth={2} aria-hidden />
      </button>
      <p className={styles.sheetEyebrow}>{eyebrow}</p>
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
  mono,
  lead,
  action,
}: {
  title?: string;
  children: ReactNode;
  /** Titre aligné sur le contenu au lieu des marges d'écran. */
  flush?: boolean;
  /**
   * L'intertitre en **petites capitales mono** (« À FAIRE »).
   *
   * 🛑 **Une variante, pas une primitive de plus** : c'est le même titre de
   * section, dans le registre technique que le kit emploie déjà pour ses
   * œils-de-bœuf. Miroir Flutter : `SfSection(mono: true)`.
   */
  mono?: boolean;
  /**
   * L'intertitre **de tête d'écran** (« Où vous en êtes ») : plus grand, pour
   * une section qui ouvre un tableau de bord. Miroir Flutter :
   * `SfSection(lead: true)`.
   */
  lead?: boolean;
  /**
   * Un lien discret aligné à droite du titre (« Mon plan »). 🛑 Une variante du
   * titre, pas une seconde en-tête. Miroir Flutter : `SfSection.action`.
   */
  action?: { label: string; href: string } | null;
}) {
  const heading = title ? (
    <h2
      className={cx(
        styles.sectionH,
        flush && styles.sectionHFlush,
        mono && styles.sectionHMono,
        lead && styles.sectionHLead,
      )}
    >
      {title}
    </h2>
  ) : null;
  return (
    <section className={cx(styles.section, flush && styles.pad)}>
      {heading && action ? (
        <div className={cx(styles.sectionHead, flush && styles.sectionHFlush)}>
          {heading}
          <Link href={action.href} className={styles.sectionAction}>
            {action.label}
          </Link>
        </div>
      ) : (
        heading
      )}
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
          <GoalValue value={current} />
        </div>
        <div className={styles.goalArrow} aria-hidden>
          <ArrowRight size={20} strokeWidth={2} />
        </div>
        <div>
          <small>{goalLabel}</small>
          <GoalValue value={goal} />
        </div>
      </div>
    </Card>
  );
}

/**
 * 🛑 **Jamais coupée au milieu d'un mot** : la taille se règle sur le **mot le
 * plus long** (`--goal-word`, en caractères) pour qu'il tienne dans sa colonne,
 * et le retour à la ligne ne se fait qu'entre deux mots. Sans ça,
 * « Naturalisation » débordait de la carte à 360 px. Miroir mobile :
 * `_SfGoalValue` (`sejour_kit.dart`).
 */
function GoalValue({value}: {value: string}) {
  const word = Math.max(1, ...value.split(/\s+/).map((w) => w.length));
  return <b style={{"--goal-word": word} as CSSProperties}>{value}</b>;
}

/* ----------------------------------------------------------------- Boutons */

export function Cta({
  href,
  onClick,
  children,
  lead,
  caption,
  variant = "primary",
  disabled,
  type = "button",
}: {
  href?: string;
  onClick?: () => void;
  children: ReactNode;
  /**
   * La ligne **au-dessus** du bouton — ce que l'action va coûter (« À partir de
   * 9,99 € achat unique »).
   *
   * 🛑 **Une variante de `caption`, pas une primitive de plus** : le même
   * bouton, avec de quoi décider juste avant de le presser. `caption` reste ce
   * qui se lit **après** (la nuance, la réserve). `null` ⇒ rien à sa place —
   * c'est le rendu exact d'un catalogue injoignable. Miroir Flutter :
   * `SfButton.lead`.
   */
  lead?: string | null;
  caption?: string;
  /** `tcf` / `civique` : le CTA d'un MODULE, peint de sa couleur (X1).
   *  Miroir Flutter : `SfButtonVariant.tcf` / `.civique`. */
  variant?: "primary" | "blue" | "line" | "tcf" | "civique";
  disabled?: boolean;
  type?: "button" | "submit";
}) {
  const cls = cx(
    styles.btn,
    variant === "blue" && styles.btnGhost,
    variant === "line" && styles.btnLine,
    variant === "tcf" && styles.btnModTcf,
    variant === "civique" && styles.btnModCivique,
  );
  return (
    <div>
      {lead ? <p className={styles.btnLead}>{lead}</p> : null}
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

/**
 * **Anneau de couverture** — la part parcourue d'un ensemble, entre 0 et 1.
 *
 * 🛑 **Ce n'est pas une note et ce n'est pas un état pédagogique** : un seul
 * accent, jamais une rampe de seuils. Un anneau vide veut dire « pas encore
 * commencé », jamais « mauvais ».
 *
 * Deux rendus :
 * - **sans `module`** (Réviser, `EpreuveRow`) : 40 px, trait de 4, bleu de
 *   marque, vert une fois l'ensemble entièrement parcouru — rendu d'origine ;
 * - **avec `module`** (`ThemeCard`, maquette « Navigation v2 », `.ring`) :
 *   52 px, trait de 6, couleur du module sur sa piste douce, et `text` au
 *   centre. Le vert n'y apparaît jamais : la maquette garde la teinte du
 *   module jusqu'au bout.
 *
 * `label` est le nom accessible ; `text` le texte du centre, **composé par
 * l'appelant** (« 60 % »). Miroir Flutter : `SfRing` (`ratio`, `size`,
 * `stroke`, `label` = texte du centre, `civique`).
 */
export function Ring({
  ratio,
  label,
  module,
  text,
}: {
  ratio: number;
  label?: string;
  /** Teinte de module (rendu maquette 52 px). Absent ⇒ rendu Réviser. */
  module?: ModuleTone;
  /** Le texte du centre. Absent ⇒ anneau muet. */
  text?: string | null;
}) {
  const part = Number.isFinite(ratio) ? Math.max(0, Math.min(1, ratio)) : 0;
  const size = module ? 52 : 40;
  const stroke = module ? 6 : 4;
  const center = size / 2;
  // 15 = le rayon d'origine du rendu Réviser ; 23 = 52 px moins le trait.
  const r = module ? (size - stroke) / 2 : 15;
  const c = 2 * Math.PI * r;
  const track = module ? "var(--mod-light)" : "var(--color-line)";
  const color = module ? "var(--mod)" : part >= 1 ? "var(--color-green)" : "var(--color-blue)";
  const svg = (
    <svg
      className={module ? undefined : styles.ring}
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <circle cx={center} cy={center} r={r} fill="none" stroke={track} strokeWidth={stroke} />
      <circle
        cx={center}
        cy={center}
        r={r}
        fill="none"
        stroke={color}
        strokeWidth={stroke}
        strokeDasharray={`${c * part} ${c}`}
        strokeLinecap={module ? "butt" : "round"}
        transform={`rotate(-90 ${center} ${center})`}
      />
    </svg>
  );
  if (!module) return svg;
  return (
    <span className={cx(styles.modRing, moduleToneClass[module])}>
      {svg}
      {text ? (
        <span className={styles.modRingVal} aria-hidden>
          {text}
        </span>
      ) : null}
    </span>
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

/* ⚠️ **`ProgressMini` est supprimée** (2026-09-19) : la jauge continue ne
   servait plus qu'à la ligne civique de « Où vous en êtes », qui rend désormais
   son état servi avec le **même traité segmenté que l'échelle TCF**
   (`LevelLadder`). Refonte = suppression de l'ancien : sa palette de
   remplissage (`.barOk`…`.barMuted`) part avec elle, et `BarTone` reste — il
   teinte encore la pastille de statut de `LevelCard`. Miroir Flutter :
   `SfProgressMini`, supprimée dans la même passe. */

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

/* ⚠️ **`LockRow`, `LockItem` et `LockList` sont SUPPRIMÉES** (2026-09-20), avec
   leurs classes `.lockRow` / `.lockN` / `.lockList` / `.lockItem` et leur miroir
   Flutter (`SfLockRow`, `SfLockItem`).

   Elles ne servaient qu'à l'**anatomie gratuite** des deux Plans : les trois
   bénéfices verrouillés du TCF (partis avec A114) puis les cinq du civique. Les
   deux écrans gratuits portent désormais l'anatomie de l'abonné, où le verrou se
   dit par un **cadenas servi** et un **geste** (`JourneyRow locked` +
   `JOURNEY_STEP_UNLOCK_LINK`) — jamais par une liste de choses qu'on n'a pas.
   Ne pas les réintroduire. */

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
 * **La variante de rendu d'une file d'étapes.**
 *
 * - `"default"` : la file de l'**Accueil** et son rail continu — le rendu
 *   historique, intouché (D-22 : « l'Accueil ne bouge pas d'un pixel »).
 * - `"cycle"` : le **corps déplié d'un bloc d'épreuve** du Plan, à la lettre de
 *   `docs/progression/plan_cycle.html` — retrait de 65 px, pastilles 16 px sur
 *   un rail segmenté, pointillés entre étapes, ligne d'action séparée.
 *
 * 🛑 **Elle se pose sur la LISTE, pas sur chaque ligne** : le rail, les
 * séparateurs et la position des pastilles doivent s'accorder, et deux
 * appelants qui répondraient différemment produiraient une file bancale.
 * `JourneyRow` la lit par contexte — une ligne rendue hors d'une `JourneyList`
 * (c'est le cas de l'Accueil) retombe donc sur `"default"` par construction.
 *
 * ⚠️ Miroir de `SfJourneyVariant` (`mobile .../core/widgets/sejour/sejour_kit.dart`).
 */
export type JourneyVariant = "default" | "cycle";

const JourneyVariantContext = createContext<JourneyVariant>("default");

/**
 * Une ligne du parcours.
 *
 * @param badge  **servi par l'appelant** — « MAINTENANT », « EXAMEN », « Déjà
 *               maîtrisée ». Le kit ne compose aucune phrase.
 * @param locked l'étape ne peut pas être menée à son terme avec l'accès du
 *               candidat. 🛑 **Elle reste à sa place** : on ajoute un cadenas,
 *               on ne déplace ni ne masque rien (R16).
 * @param actionLabel le libellé du lien d'action, **servi** (« Faire cette
 *               étape → »). Il n'existe que dans la variante `cycle`, où la
 *               maquette met l'action sur sa propre ligne : là, c'est **le
 *               lien** qui est le bouton, jamais la ligne entière — un
 *               `<button>` dans un `<button>` n'est pas du HTML valide.
 */
export function JourneyRow({
  title,
  subtitle,
  state,
  kind = "step",
  badge,
  locked,
  actionLabel,
  onClick,
}: {
  title: string;
  subtitle?: string;
  state: JourneyState;
  kind?: JourneyKind;
  badge?: string;
  locked?: boolean;
  actionLabel?: string;
  onClick?: () => void;
}) {
  const variant = useContext(JourneyVariantContext);
  const done = state === "done" || state === "skipped";
  const exam = kind === "exam" && !done;
  const Icon = done ? Check : exam ? Target : state === "current" ? ArrowRight : Circle;
  const className = cx(
    styles.jRow,
    done && styles.jDone,
    state === "current" && styles.jCurrent,
    /* 🛑 Posée dans la SEULE variante `cycle` : elle ne sert qu'au ton du tag,
       et l'Accueil doit rester au caractère près ce qu'il était (D-22). */
    variant === "cycle" && state === "upcoming" && styles.jUpcoming,
    locked && styles.jLocked,
  );

  /* La maquette du cycle : pastille de rail, titre, sous-titre, puis une ligne
     d'action à part. 🛑 La pastille n'y porte AUCUN glyphe sauf la coche — le
     « ◎ » de l'examen et le halo de l'étape courante sont dessinés par le CSS,
     et une icône Lucide de 15 px dans un rond de 16 px ne serait qu'une tache. */
  if (variant === "cycle") {
    const action = onClick && actionLabel ? (
      <button type="button" className={styles.jLink} onClick={onClick}>
        {actionLabel}
      </button>
    ) : null;
    const gauche = locked || badge ? (
      <span className={styles.jActionLeft}>
        {locked ? <Lock size={13} strokeWidth={2} aria-hidden /> : null}
        {badge ? <span className={styles.jTag}>{badge}</span> : null}
      </span>
    ) : null;
    return (
      <div className={className}>
        <span className={cx(styles.jBullet, exam && styles.jExam)} aria-hidden>
          {done ? <Check size={9} strokeWidth={3.5} aria-hidden /> : null}
        </span>
        <span className={styles.jText}>
          {state === "upcoming" ? <span>{title}</span> : <b>{title}</b>}
          {subtitle ? <small>{subtitle}</small> : null}
        </span>
        {gauche || action ? (
          <span className={styles.jAction}>
            {gauche ?? <span />}
            {action}
          </span>
        ) : null}
      </div>
    );
  }

  const body = (
    <>
      <span className={cx(styles.jBullet, exam && styles.jExam)}>
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
 *
 * @param exam **la dernière étape de la file** — l'`ExamStepAction` du bloc. Dans
 *   la variante `cycle`, la maquette le range SUR le rail, avec sa pastille
 *   « ◎ » : posé à côté de la liste il perdrait son repère de checkpoint. Il
 *   reste servi à part par le serveur (`bloc.exam`), et le kit ne décide donc
 *   ni de sa présence ni de son contenu.
 */
export function JourneyList({
  children,
  variant = "default",
  exam,
}: {
  children?: ReactNode;
  variant?: JourneyVariant;
  exam?: ReactNode;
}) {
  return (
    <JourneyVariantContext.Provider value={variant}>
      <div className={cx(styles.journey, variant === "cycle" && styles.journeyCycle)}>
        {children}
        {exam && variant === "cycle" ? (
          <div className={cx(styles.jRow, styles.jExamStep)}>
            <span className={cx(styles.jBullet, styles.jExam)} aria-hidden />
            {exam}
          </div>
        ) : (
          exam ?? null
        )}
      </div>
    </JourneyVariantContext.Provider>
  );
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
  module = "tcf",
}: {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  badge?: string;
  /** Couleur de module de la pastille d'icône. Miroir de `SfNowCard.civique`. */
  module?: ModuleTone;
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
        <div className={cx(styles.nowIco, module === "civique" && styles.nowIcoCivique)}>
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

/* 🛑 **`PassCard` est SUPPRIMÉE** (2026-09-20) avec son dernier lecteur : le
   sélecteur de durée de pass du Plan. Le choix de la durée vit sur la page de
   choix du pass, déjà l'autorité du catalogue — une seconde grille de durées
   deux écrans plus tôt était le défaut constaté. Miroir Flutter : le `subtitle`
   de `SfChoiceCard`, retiré dans la même passe. */

/* ========================================================================== */
/* Pastilles de statut, notes discrètes, encarts                              */
/* ========================================================================== */

/**
 * Le ton d'une **pastille de statut** — le même contrat de tons que le reste du
 * kit, mais posé sur du texte : le rouge plein y est trop clair et `muted-2`
 * trop pâle, d'où une table à part. Miroir Flutter : `_sfStatusColor`.
 */
const statusToneClass: Record<BarTone, string> = {
  ok: styles.toneOk,
  now: styles.toneNow,
  warn: styles.toneWarn,
  hot: styles.toneHot,
  muted: styles.toneMuted,
};

/* ⚠️ `LadderStep`, `LevelLadder`, `LevelCard`, `LevelCardGrid` et
   `GoalBanner` (« Où vous en êtes ») sont SUPPRIMÉES (Navigation v2, phase 3,
   2026-10-03) : l'Accueil porte « Mes objectifs » (`ObjCard`,
   `ObjectivesCard`) à leur place. Leurs miroirs Flutter partent dans la
   même passe : `SfLadderStep`, `SfLevelLadder`, `SfLevelCard`, `SfLevelCardGrid`,
   `SfGoalBanner`. */

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
 * L'encart ambre de pied de page (`.footer-info`) : ce que la liste au-dessus
 * compte, et ce qu'elle ne compte pas.
 *
 * Miroir Flutter : `SfInfoNote`.
 */
export function InfoNote({
  children,
  variant,
}: {
  children: ReactNode;
  /**
   * **`check`** : l'encart de **validation** — fond bleu clair, coche à la
   * place du « i ». Il ne signale rien à surveiller, il énonce la condition à
   * remplir ; l'ambre du défaut se lirait comme une réserve.
   *
   * 🛑 **Une variante, pas une primitive de plus.** Miroir Flutter :
   * `SfInfoNote(variant: SfInfoNoteVariant.check)`.
   */
  variant?: "check";
}) {
  const check = variant === "check";
  return (
    <div className={cx(styles.infoNote, check && styles.isCheck)}>
      <span className={styles.infoNoteIco} aria-hidden>
        {check ? (
          <Check size={14} strokeWidth={2.8} />
        ) : (
          <Info size={14} strokeWidth={2.4} />
        )}
      </span>
      <span>{children}</span>
    </div>
  );
}

/* ==========================================================================
   Maquettes « Plan — cycle » et « Plan — fin de cycle » (propriétaire,
   2026-09-18 ; `docs/progression/plan_cycle.html` ⇄ `cycle_termine.html`)

   🛑 Miroirs de `SfCycleProgress`, `SfBlocAccordion`, `SfExamStepAction` et
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
  /**
   * ⚠️ **`BarTone`, pas `Tone`** (2026-09-20) : la pastille a besoin du bleu
   * (`now`) pour le repère de domaine d'une étape (« CO · B2 »), et la feuille
   * de style portait déjà `.pill.now` sans qu'aucun chemin ne l'atteigne. Les
   * appelants existants passent un `Tone`, qui est un sous-ensemble.
   */
  tone: BarTone;
  /** Variante resserrée (`.status` de la maquette : 9,5 px, poids 900). */
  dense?: boolean;
}) {
  return (
    <span className={cx(styles.pill, pillToneClass[tone], dense && styles.dense)}>
      {label}
    </span>
  );
}

/** Les fonds clairs de la pastille. ⚠️ Distinct de `statusToneClass`, qui ne
 *  teinte qu'un **texte** : ici le ton porte aussi l'aplat. */
const pillToneClass: Record<BarTone, string> = {
  ok: styles.ok,
  now: styles.pillNow,
  warn: styles.warn,
  hot: styles.hot,
  muted: styles.muted,
};

/**
 * **L'avancement du cycle** — le `.cycleIntro` de `plan_cycle.html`, et le
 * `.progressBox` de `cycle_termine.html` quand il est terminé.
 *
 * 🛑 **Barre CONTINUE, et elle porte un chiffre.** C'est ce qui la distingue
 * des deux briques voisines, qu'il ne faut surtout pas remplacer par elle :
 * - `LevelLadder` a des **crans**, et aucun chiffre : elle situe un état servi ;
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
  title,
  module = "tcf",
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
  /**
   * **La carte « Cycle » de Navigation v2** (`.card.card-pad` de « Mon plan ») :
   * `badge` (ou `label` sur un cycle clos) en intitulé, `title` (« Votre
   * parcours vers le B2 ») en titre, `done/total` servi à droite, la barre à la
   * couleur du `module` (verte sur un cycle clos), `hint` dessous. Absent ⇒ la
   * forme historique. Miroir Flutter : `SfCycleProgress title` + `civique`.
   */
  title?: string;
  module?: ModuleTone;
}) {
  const ratio = total > 0 ? Math.max(0, Math.min(1, done / total)) : 0;
  const pct = complete && total <= 0 ? 100 : Math.round(ratio * 100);
  if (title) {
    return (
      <section className={cx(styles.modCard, moduleToneClass[module])}>
        <div className={styles.cycleCardHead}>
          <div className={styles.cycleCardCopy}>
            <p className={styles.modLabel}>{badge ?? label}</p>
            <h3 className={styles.cycleCardTitle}>{title}</h3>
          </div>
          <strong className={styles.cycleCardCount}>{`${done}/${total}`}</strong>
        </div>
        <span className={cx(styles.modBar, complete && styles.isDone)} aria-hidden>
          <span style={{ width: `${complete ? 100 : Math.round(ratio * 100)}%` }} />
        </span>
        {hint ? <p className={styles.cycleCardHint}>{hint}</p> : null}
      </section>
    );
  }
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
 * d'accessibilité et du parcours clavier, comme chez `Prio`.
 *
 * Composition attendue : une `JourneyList` de `JourneyRow` (les étapes, avec
 * leur rail), puis un `ExamStepAction`. Le corps ne porte donc aucun retrait de
 * rail — c'est la liste qui a le sien.
 *
 * **Variante LIEN** (`href`, « Mes cycles », 2026-09-27) : le même en-tête,
 * sans corps, qui **ouvre une page** au lieu de se déplier — le chevron pointe
 * alors à droite. C'est ainsi que la liste des cycles terminés mène à la
 * consultation d'un cycle : un seul motif d'en-tête, pas une carte de plus.
 *
 * Miroir Flutter : `SfBlocAccordion` (`onOpen`).
 */
export function BlocAccordion(props: BlocAccordionProps) {
  const { mark, title, meta, status, current, icon, module = "tcf" } = props;
  const panelId = useId();
  if (icon && props.href === undefined) {
    /* **L'en-tête en `.info-card`** (Navigation v2, « Priorités actuelles ») :
       pastille d'icône douce du module, repère en badge au-dessus du titre,
       méta, état en `Badge` au ton servi, puis le chevron qui pivote. */
    const { open, onToggle, children } = props;
    return (
      <article className={cx(styles.blocGroup, moduleToneClass[module], current && styles.isCurrent)}>
        <button
          type="button"
          className={styles.blocHeadInfo}
          aria-expanded={open}
          aria-controls={panelId}
          onClick={onToggle}
        >
          <IconBox icon={icon} />
          <span className={styles.infoCopy}>
            {mark ? <Badge module={module}>{mark}</Badge> : null}
            <span className={cx(styles.infoTitle, mark && styles.hasCode)}>{title}</span>
            <span className={styles.infoMeta}>{meta}</span>
          </span>
          <span className={styles.infoTrailing}>
            <Badge tone={toneToStateTone[status.tone]}>{status.label}</Badge>
          </span>
          <span className={styles.infoChevron} aria-hidden>
            <ChevronDown className={cx(styles.chevron, open && styles.chevronUp)} />
          </span>
        </button>
        <div id={panelId} className={styles.blocBody} hidden={!open}>
          {children}
        </div>
      </article>
    );
  }
  const tete = (
    <>
      {mark && <span className={styles.blocMark}>{mark}</span>}
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
    </>
  );
  if (props.href !== undefined) {
    return (
      <article className={cx(styles.blocGroup, current && styles.isCurrent)}>
        <Link
          href={props.href}
          className={cx(styles.blocHead, styles.blocLink, !mark && styles.blocHeadSansMarque)}
        >
          {tete}
          <ChevronRight size={18} strokeWidth={2.5} className={styles.blocChevron} aria-hidden />
        </Link>
      </article>
    );
  }
  const { open, onToggle, children } = props;
  return (
    <article className={cx(styles.blocGroup, current && styles.isCurrent)}>
      <button
        type="button"
        className={cx(styles.blocHead, !mark && styles.blocHeadSansMarque)}
        aria-expanded={open}
        aria-controls={panelId}
        onClick={onToggle}
      >
        {tete}
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

type BlocAccordionProps = {
  /** Le repère court de l'épreuve (« CO »), en mono : étiquette technique.
   *
   *  🛑 **Vide pour une THÉMATIQUE civique** : l'initiale à deux lettres
   *  n'existe que pour une épreuve. La colonne disparaît alors, et **rien ne la
   *  remplace** — un carré vide, un numéro de rang ou une icône choisie ici
   *  seraient tous des inventions du front (A49). */
  mark: string;
  /** Le nom de l'épreuve **en clair**, servi. */
  title: string;
  /** « 1 compétence restante · puis examen », **servi**. */
  meta: string;
  /** Le libellé d'état et son ton, tous deux **servis**. */
  status: { label: string; tone: Tone };
  /** Le bloc courant : liseré et repère accentués. **Servi**, jamais déduit. */
  current?: boolean;
  /**
   * Le pictogramme de la variante **info-card** (Navigation v2) ; absent ⇒
   * l'en-tête historique de `plan_cycle.html`. Miroir : `SfBlocAccordion icon`.
   */
  icon?: ReactNode;
  /** La teinte de la variante info-card. Miroir : `civique`. */
  module?: ModuleTone;
} & (
  | { open: boolean; onToggle: () => void; children: ReactNode; href?: undefined }
  /** La variante lien : l'en-tête ouvre une page, il n'a pas de corps. */
  | { href: string; open?: undefined; onToggle?: undefined; children?: undefined }
);

/**
 * Ce que l'étape d'examen porte **à droite** : un bouton de lancement, ou le
 * constat qu'elle est passée.
 *
 * - `start` — le bouton. **Inactif sans `onClick`** ; `locked` ajoute le
 *   cadenas. Le kit ne décide ni de l'un ni de l'autre.
 * - `done` — une pastille cochée, sans geste.
 */
export type ExamStepTrailing =
  | { kind: "start"; label: string; locked: boolean; onClick?: () => void }
  | { kind: "done"; label: string };

/**
 * **L'étape d'examen d'un bloc de cycle** : titre et sous-titre à gauche, le
 * bouton à droite (demande du propriétaire, 2026-09-26).
 *
 * 🛑 **Aucune phrase n'est écrite ici**, et aucun état n'est classé : le titre,
 * le sous-titre, le libellé du bouton, la phrase de pied et son lien arrivent
 * tous en props. Un bouton inactif se lit avec son cadenas **et** sa phrase de
 * pied — jamais un bouton muet sans raison.
 *
 * ⚠️ Le bouton passe **sous** le texte quand la ligne ne tient plus (360 px) :
 * `flex-wrap`, jamais une troncature.
 *
 * Miroir Flutter : `SfExamStepAction`. Elle sert aussi la consultation d'un
 * cycle clos (« Mes cycles ») : sans `trailing` de lancement, elle y est
 * inerte.
 */
export function ExamStepAction({
  title,
  subtitle,
  trailing,
  note,
  noteAction,
  module,
}: {
  /** La couleur du bouton : celle du module (civique rouge). Absent ⇒ bleu
   *  historique. Miroir Flutter : `SfExamStepAction.civique`. */
  module?: ModuleTone;
  title: string;
  subtitle: string;
  trailing?: ExamStepTrailing;
  /** Pourquoi le bouton est inactif, en une phrase courte. */
  note?: string;
  /** Le geste qui lève le verrou, sous la phrase de pied. */
  noteAction?: { label: string; onClick: () => void };
}) {
  return (
    <div className={cx(styles.examBox, styles.examAction, module && moduleToneClass[module])}>
      <span className={styles.examActionRow}>
        <span className={styles.examActionText}>
          <b>{title}</b>
          <span className={styles.examActionSub}>{subtitle}</span>
        </span>
        {trailing?.kind === "done" ? (
          <span className={cx(styles.examActionDone, statusToneClass.ok)}>
            <Check size={13} strokeWidth={2.6} aria-hidden />
            {trailing.label}
          </span>
        ) : trailing ? (
          <button
            type="button"
            className={styles.examActionBtn}
            onClick={trailing.onClick}
            disabled={!trailing.onClick}
          >
            {trailing.locked ? <Lock size={12} strokeWidth={2.4} aria-hidden /> : null}
            {trailing.label}
          </button>
        ) : null}
      </span>
      {note || noteAction ? (
        <span className={styles.examActionFoot}>
          {note ? <span>{note}</span> : null}
          {noteAction ? (
            <button type="button" className={styles.jLink} onClick={noteAction.onClick}>
              {noteAction.label}
            </button>
          ) : null}
        </span>
      ) : null}
    </div>
  );
}

/** Un fait de la carte de fin de cycle : une valeur et ce qu'elle nomme. */
export type NextStepFact = { value: string; label: string };

/**
 * **La carte de fin de cycle** — le `.finalCard` de `cycle_termine.html`.
 *
 * ⚠️ **Une seule action depuis le 2026-09-27** (D-66) : « Actualiser mon plan ».
 * Le second terme « Passer l'examen blanc complet » a quitté la fin de cycle —
 * il est devenu un jalon au-dessus du Plan — et l'emplacement secondaire est
 * supprimé avec lui (plus aucun appelant).
 *
 * 🛑 **Aucune phrase n'est écrite ici** : `eyebrow`, `title`, `text`, les
 * `facts` et le libellé d'action arrivent tous en props.
 *
 * Miroir Flutter : `SfNextStepCard`.
 */
export function NextStepCard({
  eyebrow,
  title,
  text,
  facts,
  primary,
}: {
  eyebrow: string;
  title: string;
  text: string;
  /** Les repères de la carte. Vide ⇒ aucune grille. */
  facts: NextStepFact[];
  primary: { label: string; onClick: () => void };
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
      </div>
    </section>
  );
}

/* ==========================================================================
   La timeline du cycle (demande du propriétaire, 2026-09-27)

   Un rail vertical ÉTROIT à gauche des blocs : un rond par bloc, relié par un
   trait, et une dernière étape « Fin du cycle » en bas. 🛑 Miroirs de
   `SfCycleRail`, `SfCycleRailStep` et `SfCycleRailEnd` côté Flutter, brique
   pour brique et au pixel près : rond 14 px, trait 2 px, gouttière 8 px — soit
   22 px pris aux cartes, pas un de plus.
   ========================================================================== */

/**
 * L'état d'un rond de la timeline. **Passé**, jamais déduit ici : l'écran le
 * traduit du statut servi du bloc.
 */
export type RailState = "done" | "current" | "upcoming";

/**
 * **La timeline du cycle** — le conteneur du rail.
 *
 * Le trait est dessiné **par étape** (du haut de l'étape jusqu'à la suivante),
 * et coupé au rond de la première et de la dernière : aucune hauteur n'est
 * mesurée, la timeline suit ce que les cartes deviennent en se dépliant.
 *
 * ⚠️ **22 px de moins pour les cartes** : sous 388 px (366 + 22), l'accordéon
 * placé dans le rail masque sa pastille d'état comme il le fait seul sous
 * 366 px — le rond porte alors l'état, et le nom d'épreuve tient sur une ligne
 * (D-21). Miroir Flutter : `SfCycleRail.retraitDe`.
 *
 * Miroir Flutter : `SfCycleRail`.
 */
export function CycleRail({ children }: { children: ReactNode }) {
  return <ol className={styles.rail}>{children}</ol>;
}

/**
 * **Une étape de la timeline** : un rond à gauche, la carte à droite, reçue
 * **telle quelle** (`BlocAccordion` sur le Plan).
 *
 * - `done` — rond plein bleu, coché ;
 * - `current` — rond épais bleu, le bloc en cours ;
 * - `upcoming` — rond gris au trait fin.
 *
 * Miroir Flutter : `SfCycleRailStep`.
 */
export function CycleRailStep({ state, children }: { state: RailState; children: ReactNode }) {
  return (
    <li className={styles.railStep}>
      <span
        className={cx(
          styles.railDot,
          state === "done" && styles.railDotDone,
          state === "current" && styles.railDotCurrent,
        )}
        aria-hidden
      >
        {state === "done" ? <Check size={9} strokeWidth={3.5} /> : null}
      </span>
      <div className={styles.railBody}>{children}</div>
    </li>
  );
}

/**
 * **La dernière étape de la timeline** — « Fin du cycle », rond étoilé.
 *
 * - **Non atteinte** : un encart en pointillés, atténué — `eyebrow`, `title`
 *   et, s'il reste des étapes, la pastille `remaining` (« Encore 4 étapes »).
 * - **Atteinte** (`reached` + `children`) : l'encart disparaît et **l'action
 *   prend sa place** — la carte de fin de cycle existante, jamais un second
 *   bouton qui la dupliquerait.
 *
 * - **Franchie** (`done`, consultation d'un cycle clos, 2026-09-27) : l'encart
 *   devient **plein** — ni pointillés, ni atténuation — et porte `note`
 *   (« Le 27 sept. 2026 »). Aucun geste : un cycle clos ne se rejoue pas.
 *
 * 🛑 **Aucune phrase n'est écrite ici**, et rien n'est compté : les libellés
 * arrivent en props.
 *
 * Miroir Flutter : `SfCycleRailEnd`.
 */
export function CycleRailEnd({
  eyebrow,
  title,
  remaining,
  reached,
  done,
  note,
  children,
}: {
  eyebrow: string;
  title: string;
  /** « Encore N étapes ». Absent ⇒ aucune pastille. */
  remaining?: string;
  reached: boolean;
  /** La fin a été franchie : l'encart est plein, et lu tel quel. */
  done?: boolean;
  /** La ligne sous le titre, **servie** : la date d'une fin franchie, ou
   *  « 3 priorités identifiées » sur une fin à venir (D-67, 2026-09-27). */
  note?: string;
  /** L'action de fin de cycle, rendue **à la place** de l'encart une fois atteinte. */
  children?: ReactNode;
}) {
  return (
    <li className={cx(styles.railStep, styles.railEnd)}>
      <span className={cx(styles.railDot, styles.railDotEnd)} aria-hidden>
        <Star size={8} strokeWidth={0} fill="currentColor" />
      </span>
      <div className={styles.railBody}>
        {reached && children ? (
          children
        ) : (
          <div className={cx(styles.railEndBox, done && styles.railEndDone)}>
            <span className={styles.railEndEyebrow}>{eyebrow}</span>
            <b className={styles.railEndTitle}>{title}</b>
            {note ? <span className={styles.railEndNote}>{note}</span> : null}
            {remaining ? (
              <span className={styles.railEndPill}>
                <Pill label={remaining} tone="warn" />
              </span>
            ) : null}
          </div>
        )}
      </div>
    </li>
  );
}

/* ==========================================================================
   Maquette « Ma progression — historique des cycles » (propriétaire,
   2026-09-18 ; `docs/progression/histo_cycle.html`)

   🛑 Miroir de `SfStatGrid` côté Flutter. Un motif qui bouge d'un côté
   bouge de l'autre dans la même passe. Son bandeau est désormais `Hero`
   (section « Navigation v2 », plus bas).
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
   * Les compteurs sont posés **sur un fond de marque** (`Hero`) : tuiles
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

/* ============================================================================
   Le BANDEAU D'OBJECTIF (né avec l'ancien écran « Votre progression »,
   2026-09-19). ⚠️ Cet écran est SUPPRIMÉ (2026-09-24) avec ses autres briques
   (`LevelStrip`, `ChartTitle`, `ChartNote`, `EpreuveStatRow/List`) ; le
   bandeau reste parce que l'écran de déblocage du Plan le lit.
   Miroir Flutter : `SfGoalHero`.
   ========================================================================== */

/**
 * **Le bandeau d'objectif d'un écran de progression** — le `.hero` du
 * template : œil-de-bœuf, intitulé + valeur en gros, pastille d'objectif à
 * droite, rail, ligne de mesure, puis ce que l'écran y pose (la bande des
 * paliers).
 *
 * 🛑 **Distinct des trois héros voisins**, qu'il ne faut pas remplacer par lui :
 * - `ProgressHero` porte **un résultat** — c'est une carte de tête de progression ;
 * - `Hero` est le bandeau de module de la maquette « Navigation v2 » ;
 * - `GoalBanner` est une bande **compacte**, posée DANS une carte.
 *
 * Celui-ci porte un **avancement** : un compteur, un rail et sa lecture en
 * pourcentage.
 *
 * 🛑 `ratio` est une **part passée**, jamais dérivée ici, et le pourcentage est
 * **écrit par l'appelant** (`metaValue`) : le kit ne convertit aucun nombre.
 * Absents tous les deux ⇒ ni rail ni chiffre, le rendu exact d'une donnée non
 * servie.
 *
 * Miroir Flutter : `SfGoalHero`.
 */
export function GoalHero({
  label,
  value,
  pill,
  ratio,
  metaLabel,
  metaValue,
  children,
}: {
  /** « Vers votre objectif ». */
  label: string;
  /**
   * « 2 épreuves sur 4 ». **Composé par l'appelant.** `null` quand le serveur
   * ne sert pas de quoi l'écrire : le bandeau garde son intitulé et sa bande de
   * paliers, mais **n'annonce aucun chiffre**.
   */
  value?: string | null;
  /** « Objectif B1 ». `null` sans démarche déclarée. */
  pill?: string | null;
  /** Part parcourue (0-1). `null` ⇒ pas de rail. */
  ratio?: number | null;
  metaLabel?: string | null;
  /** Le pourcentage, **déjà écrit**. `null` ⇒ aucun chiffre annoncé. */
  metaValue?: string | null;
  /** La bande des paliers. Absente ⇒ le bandeau s'arrête là. */
  children?: ReactNode;
}) {
  const rail = ratio == null ? null : Math.min(Math.max(ratio, 0), 1);
  return (
    <section className={styles.goalHero}>
      <div className={styles.goalHeroTop}>
        <div className={styles.goalHeroId}>
          <p className={styles.goalHeroLabel}>{label}</p>
          {value ? <p className={styles.goalHeroValue}>{value}</p> : null}
        </div>
        {pill ? <span className={styles.goalHeroPill}>{pill}</span> : null}
      </div>
      {rail != null ? (
        <span className={styles.goalHeroRail} aria-hidden>
          <i style={{ width: `${rail * 100}%` }} />
        </span>
      ) : null}
      {metaLabel || metaValue ? (
        <p className={styles.goalHeroMeta}>
          <span>{metaLabel}</span>
          {metaValue ? <b>{metaValue}</b> : null}
        </p>
      ) : null}
      {children ? <div className={styles.goalHeroBody}>{children}</div> : null}
    </section>
  );
}

/* ==========================================================================
   Les ÉCRANS DE PROGRESSION (maquettes du propriétaire, 2026-09-24 ;
   `docs/progression/maquettes-progression/*.html`)

   TCF global, une épreuve TCF, civique global, un thème civique. Ils
   assemblent ces briques et RIEN d'autre : intro, carte de tête,
   compteurs, cartes d'épreuve / de thème, courbe, légende d'échelle, lignes
   d'examen.

   🛑 **Aucune ne classe quoi que ce soit.** Score, palier, état, bande, écart,
   sens, ordinal, durée : tout arrive **écrit** par l'appelant à partir de faits
   servis (`lib/progression.ts`). La courbe PLACE des valeurs servies sur un axe
   dont les bornes sont servies — placer n'est pas classer.

   🛑 Couleurs : la maquette met du rouge sur l'anneau, le dernier point et
   l'œil-de-bœuf. Le rouge est réservé aux CTA critiques : l'anneau est bleu
   (vert au seuil, sémantique de `Ring`), le dernier point est bleu foncé avec
   un halo ; seule la pastille de l'œil-de-bœuf garde le rouge de `.heroDot`,
   convention déjà en place dans le kit.

   Miroirs Flutter (même passe, même nom, préfixe `Sf`) : `SfProgressIntro`,
   `SfProgressHero`, `SfProgressStatTile`, `SfProgressStatGrid`, `SfProgressDomainCard`, `SfProgressChart`,
   `SfProgressScaleLegend`, `SfProgressExamRow`, `SfProgressGlobalExamRow`.
   ========================================================================== */

/** Une pastille de la carte de tête ou d'une carte d'épreuve. */
export type ProgressChip = { label: string; tone: BarTone };

const progressChipClass: Record<BarTone, string> = {
  ok: styles.pChipOk,
  now: styles.pChipNow,
  warn: styles.pChipWarn,
  hot: styles.pChipHot,
  muted: styles.pChipMuted,
};

function ProgressChipView({ chip }: { chip: ProgressChip }) {
  return <span className={cx(styles.pChip, progressChipClass[chip.tone])}>{chip.label}</span>;
}

/** **L'intro** — œil-de-bœuf « Votre progression », titre, phrase de cadrage. */
export function ProgressIntro({
  eyebrow,
  title,
  lead,
}: {
  eyebrow: string;
  title: string;
  lead?: string | null;
}) {
  return (
    <section className={styles.pIntro}>
      <p className={styles.pEyebrow}>
        <i className={styles.heroDot} aria-hidden />
        {eyebrow}
      </p>
      <h1 className={styles.pTitle}>{title}</h1>
      {lead ? <p className={styles.pLead}>{lead}</p> : null}
    </section>
  );
}

/**
 * **La carte de tête** — « Dernier résultat » : le gros chiffre (ou le palier)
 * et son unité, une rangée de pastilles (palier ou état, écart), une ligne
 * secondaire, et l'anneau.
 *
 * 🛑 **L'anneau n'existe qu'en civique** (D5) : il lit le `taux` servi et
 * `reached` (`seuilAtteint` servi) le passe au vert. Aucun anneau en TCF — un
 * disque rempli à côté d'un palier se lirait comme un pourcentage de niveau.
 */
export function ProgressHero({
  label,
  value,
  unit,
  chips,
  notes,
  ring,
}: {
  label: string;
  /** Le chiffre ou le palier, déjà écrit. « — » quand rien n'est mesuré. */
  value: string;
  /** « / 499 ». Absent pour un palier. */
  unit?: string | null;
  chips?: ProgressChip[];
  /** Les lignes secondaires (niveau actuel estimé, verdict de seuil…). */
  notes?: Array<string | null>;
  ring?: { ratio: number; label: string; reached: boolean } | null;
}) {
  const lignes = (notes ?? []).filter((n): n is string => Boolean(n));
  return (
    <article className={cx(styles.pCard, styles.pHero)}>
      <div className={styles.pHeroBody}>
        <p className={styles.pHeroLabel}>{label}</p>
        <p className={styles.pHeroScore}>
          <strong>{value}</strong>
          {unit ? <span>{unit}</span> : null}
        </p>
        {chips && chips.length > 0 ? (
          <div className={styles.pChips}>
            {chips.map((c) => (
              <ProgressChipView key={c.label} chip={c} />
            ))}
          </div>
        ) : null}
        {lignes.map((n) => (
          <p key={n} className={styles.pHeroNote}>{n}</p>
        ))}
      </div>
      {ring ? <ProgressRing {...ring} /> : null}
    </article>
  );
}

function ProgressRing({ ratio, label, reached }: { ratio: number; label: string; reached: boolean }) {
  const part = Number.isFinite(ratio) ? Math.max(0, Math.min(1, ratio)) : 0;
  const r = 44;
  const c = 2 * Math.PI * r;
  return (
    <span className={styles.pRing} role="img" aria-label={label}>
      <svg viewBox="0 0 100 100" aria-hidden>
        <circle cx="50" cy="50" r={r} fill="none" stroke="var(--color-line)" strokeWidth="11" />
        <circle
          cx="50"
          cy="50"
          r={r}
          fill="none"
          stroke={reached ? "var(--color-green)" : "var(--color-blue)"}
          strokeWidth="11"
          strokeDasharray={`${c * part} ${c}`}
          transform="rotate(-90 50 50)"
        />
      </svg>
      <b>{label}</b>
    </span>
  );
}

/** **Un compteur** : son intitulé, sa valeur, sa précision. */
export function ProgressStatTile({
  label,
  value,
  sub,
}: {
  label: string;
  value: string;
  sub?: string | null;
}) {
  return (
    <div className={styles.pStat}>
      <span className={styles.pStatLabel}>{label}</span>
      <div>
        <strong className={styles.pStatValue}>{value}</strong>
        {sub ? <small className={styles.pStatSub}>{sub}</small> : null}
      </div>
    </div>
  );
}

/**
 * **La grille des compteurs.**
 *
 * - `boxed` (écrans globaux) : une carte qui range quatre encarts en 2 × 2 ;
 * - sinon (épreuve, thème) : chaque compteur est sa propre petite carte, deux
 *   par rangée.
 */
export function ProgressStatGrid({ children, boxed }: { children: ReactNode; boxed?: boolean }) {
  return (
    <div className={cx(styles.pStatGrid, boxed ? cx(styles.pCard, styles.isBoxed) : styles.isCards)}>
      {children}
    </div>
  );
}

/** La sparkline d'une carte : au plus 7 scores servis, du plus ancien au plus récent. */
function ProgressSparkline({ values }: { values: number[] }) {
  if (values.length < 2) return null;
  const w = 145;
  const h = 58;
  const pad = 6;
  const lo = Math.min(...values);
  const hi = Math.max(...values);
  const span = hi - lo || 1;
  const pts = values.map((v, i) => {
    const x = pad + (i / (values.length - 1)) * (w - 2 * pad);
    const y = hi === lo ? h / 2 : h - pad - ((v - lo) / span) * (h - 2 * pad);
    return [x, y] as const;
  });
  const last = pts[pts.length - 1];
  return (
    <svg className={styles.pSpark} viewBox={`0 0 ${w} ${h}`} aria-hidden>
      <path d={pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)} ${y.toFixed(1)}`).join(" ")} />
      <circle cx={last[0]} cy={last[1]} r="4" />
    </svg>
  );
}

/**
 * **La carte d'une épreuve ou d'un thème** — pictogramme, nom, sous-titre,
 * flèche ; puis le dernier score, sa pastille (palier ou état servi), l'écart
 * servi et la sparkline. Toute la carte est un lien vers l'écran détaillé.
 *
 * `empty` remplace le chiffre quand l'épreuve n'a aucun examen : ni pastille,
 * ni écart, ni sparkline — jamais un 0.
 */
export function ProgressDomainCard({
  href,
  icon: Icon,
  title,
  sub,
  value,
  unit,
  pill,
  delta,
  serie,
  empty,
}: {
  href: string;
  icon: LucideIcon;
  title: string;
  sub: string;
  value?: string | null;
  unit?: string | null;
  pill?: ProgressChip | null;
  delta?: ProgressChip | null;
  serie?: number[];
  /** Le mot d'une absence d'examen. Prioritaire sur `value`. */
  empty?: string | null;
}) {
  return (
    <Link href={href} className={cx(styles.pCard, styles.pDomain)}>
      <span className={styles.pDomainHead}>
        <span className={styles.pDomainName}>
          <span className={styles.pDomainIcon} aria-hidden>
            <Icon size={20} strokeWidth={1.9} />
          </span>
          <span>
            <b>{title}</b>
            <small>{sub}</small>
          </span>
        </span>
        <ChevronRight className={styles.pDomainArrow} size={20} strokeWidth={2} aria-hidden />
      </span>
      <span className={styles.pDomainMain}>
        {empty ? (
          <span className={styles.pDomainEmpty}>{empty}</span>
        ) : (
          <span className={styles.pDomainFigures}>
            <span className={styles.pDomainScore}>
              <strong>{value}</strong>
              {unit ? <span> {unit}</span> : null}
            </span>
            {pill ? <ProgressChipView chip={pill} /> : null}
            {delta ? (
              <span className={cx(styles.pDelta, statusToneClass[delta.tone])}>{delta.label}</span>
            ) : null}
          </span>
        )}
        {!empty && serie ? <ProgressSparkline values={serie} /> : null}
      </span>
    </Link>
  );
}

/** Une zone servie de l'axe, déjà nommée. `tone` teinte son fond, très pâle. */
export type ProgressChartBand = { label: string; min: number; max: number; tone: BarTone };

/** Un point : sa date d'axe, sa valeur servie, et ce qu'on écrit dessus. */
export type ProgressChartPoint = { date: string; value: number; label: string };

const progressBandClass: Record<BarTone, string> = {
  ok: styles.pBandOk,
  now: styles.pBandNow,
  warn: styles.pBandWarn,
  hot: styles.pBandHot,
  muted: styles.pBandMuted,
};

/**
 * **La courbe d'évolution** — aire, ligne, un point par examen, le dernier
 * accentué, les repères servis sur l'axe, les dates en abscisse.
 *
 * 🛑 **Les bandes ne se dessinent que SERVIES** : vides en CO/CE (D2), elles
 * n'apparaissent pas. Une bande couvre de son `min` au `min` de la suivante —
 * les notes décimales tombent ainsi dans la bande de leur partie entière.
 *
 * Plus étroite que 720 px, elle défile horizontalement (maquette).
 */
export function ProgressChart({
  min,
  max,
  reperes,
  bands,
  seuil,
  seuilLabel,
  points,
  note,
  ariaLabel,
}: {
  min: number;
  max: number;
  reperes: number[];
  bands?: ProgressChartBand[];
  seuil?: number | null;
  seuilLabel?: string | null;
  /** Du plus ancien au plus récent. */
  points: ProgressChartPoint[];
  /** Ce que mesure l'axe (« Score de progression · /499 »). */
  note?: string | null;
  ariaLabel: string;
}) {
  const gradientId = useId();
  const span = max - min || 1;
  const y = (v: number) => 100 - ((Math.min(Math.max(v, min), max) - min) / span) * 100;
  const inset = 4;
  const x = (i: number) =>
    points.length > 1 ? inset + (i / (points.length - 1)) * (100 - 2 * inset) : 50;
  const sorted = [...(bands ?? [])].sort((a, b) => a.min - b.min);
  const last = points.length - 1;
  /* Au-delà de 6 points, les dates s'écrivent une sur deux (ou moins) : le
     défilement garde un point par examen, l'axe reste lisible. */
  const pasDate = Math.max(1, Math.ceil(points.length / 7));
  const coords = points.map((p, i) => `${x(i)},${y(p.value)}`);
  return (
    <div className={styles.pChart}>
      {note ? <p className={styles.pChartNote}>{note}</p> : null}
      <div className={styles.pChartScroll}>
        <div
          className={styles.pChartInner}
          style={{ minWidth: `${Math.max(720, points.length * 44)}px` }}
          role="img"
          aria-label={ariaLabel}
        >
          <div className={styles.pChartPlot}>
            {sorted.map((b, i) => {
              const haut = i < sorted.length - 1 ? sorted[i + 1].min : max;
              const top = y(haut);
              const height = y(b.min) - top;
              return (
                <span
                  key={`${b.label}-${b.min}`}
                  className={cx(styles.pBand, progressBandClass[b.tone])}
                  style={{ top: `${top}%`, height: `${height}%` }}
                  aria-hidden
                >
                  {height >= 12 ? <i>{b.label}</i> : null}
                </span>
              );
            })}
            {reperes.map((r) => (
              <span key={`g-${r}`} className={styles.pGrid} style={{ top: `${y(r)}%` }} aria-hidden>
                <i>{r}</i>
              </span>
            ))}
            {seuil != null ? (
              <span className={styles.pSeuil} style={{ top: `${y(seuil)}%` }} aria-hidden>
                {seuilLabel ? <i>{seuilLabel}</i> : null}
              </span>
            ) : null}
            {points.length > 1 ? (
              <svg className={styles.pChartSvg} viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden>
                <defs>
                  <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" style={{ stopColor: "var(--color-blue)", stopOpacity: 0.13 }} />
                    <stop offset="100%" style={{ stopColor: "var(--color-blue)", stopOpacity: 0 }} />
                  </linearGradient>
                </defs>
                <polygon
                  points={`${x(0)},100 ${coords.join(" ")} ${x(last)},100`}
                  fill={`url(#${gradientId})`}
                />
                <polyline
                  points={coords.join(" ")}
                  fill="none"
                  stroke="var(--color-blue)"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  vectorEffect="non-scaling-stroke"
                />
              </svg>
            ) : null}
            {points.map((p, i) => (
              <span
                key={`p-${i}`}
                className={cx(styles.pDot, i === last && styles.isLast)}
                style={{ left: `${x(i)}%`, top: `${y(p.value)}%` }}
                aria-hidden
              />
            ))}
            {points.map((p, i) =>
              i === 0 || i === last || points.length <= 5 ? (
                <span
                  key={`v-${i}`}
                  className={cx(styles.pValue, i === last && styles.isLast)}
                  style={{ left: `${x(i)}%`, top: `${y(p.value)}%` }}
                  aria-hidden
                >
                  {p.label}
                </span>
              ) : null,
            )}
            {points.map((p, i) =>
              i % pasDate === 0 || i === last ? (
                <span key={`d-${i}`} className={styles.pDate} style={{ left: `${x(i)}%` }} aria-hidden>
                  {p.date}
                </span>
              ) : null,
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

/** **La légende de l'échelle** — une case par bande servie : son nom, son étendue. */
export function ProgressScaleLegend({ items }: { items: Array<{ label: string; range: string }> }) {
  if (items.length === 0) return null;
  return (
    <ul className={styles.pScale}>
      {items.map((it) => (
        <li key={`${it.label}-${it.range}`} className={styles.pScaleItem}>
          <strong>{it.label}</strong>
          <span>{it.range}</span>
        </li>
      ))}
    </ul>
  );
}

/**
 * **La ligne d'un examen** (écran épreuve / thème) — ordinal servi et date,
 * score, badge servi (palier ou état), durée fiable ou « — », « Voir → ».
 *
 * Toute la ligne est un lien vers le rapport choisi par `rapport.kind`. Sur
 * téléphone, durée et « Voir → » s'effacent (maquette) — la ligne reste un lien.
 */
export function ProgressExamRow({
  href,
  title,
  date,
  score,
  badge,
  duration,
  action,
}: {
  /** `null` ⇒ ligne sans lien (aucun rapport servi). */
  href: string | null;
  title: string;
  date: string;
  score: { label: string; value: string };
  badge?: ProgressChip | null;
  duration?: { label: string; value: string } | null;
  action: string;
}) {
  const body = (
    <>
      <span className={styles.pRowId}>
        <b>{title}</b>
        <small>{date}</small>
      </span>
      <span className={styles.pRowStat}>
        <small>{score.label}</small>
        <b>{score.value}</b>
      </span>
      <span className={styles.pRowBadgeCell}>
        {badge ? (
          <span className={cx(styles.pRowBadge, progressChipClass[badge.tone])}>{badge.label}</span>
        ) : null}
      </span>
      {duration ? (
        <span className={cx(styles.pRowStat, styles.pRowWide)}>
          <small>{duration.label}</small>
          <b>{duration.value}</b>
        </span>
      ) : (
        <span className={styles.pRowWide} />
      )}
      <span className={cx(styles.pRowAction, styles.pRowWide)}>{href ? action : null}</span>
    </>
  );
  return href ? (
    <Link href={href} className={styles.pRow}>
      {body}
    </Link>
  ) : (
    <div className={styles.pRow}>{body}</div>
  );
}

/**
 * **La ligne d'un examen COMPLET** (écrans globaux) — ordinal et date, une part
 * par épreuve ou par thème, le badge global.
 *
 * 🛑 Les parts arrivent écrites : « 392 / 499 », « 12 / 20 », « 3 / 4 »
 * posées (D11), « — » pour une épreuve verrouillée, jamais ouverte, ou un
 * thème non posé — jamais « 0 ». Sur téléphone, les parts s'effacent.
 */
export function ProgressGlobalExamRow({
  href,
  title,
  date,
  parts,
  badge,
  action,
}: {
  href: string | null;
  title: string;
  date: string;
  parts: Array<{ label: string; value: string }>;
  badge?: ProgressChip | null;
  action?: string | null;
}) {
  const body = (
    <>
      <span className={styles.pRowId}>
        <b>{title}</b>
        <small>{date}</small>
      </span>
      <span className={styles.pRowParts} style={{ gridTemplateColumns: `repeat(${parts.length}, minmax(0, 1fr))` }}>
        {parts.map((p) => (
          <span key={p.label} className={styles.pRowStat} title={p.label}>
            <small>{p.label}</small>
            <b>{p.value}</b>
          </span>
        ))}
      </span>
      <span className={styles.pRowEnd}>
        {badge ? (
          <span className={cx(styles.pRowBadge, progressChipClass[badge.tone])}>{badge.label}</span>
        ) : null}
        {href && action ? <span className={cx(styles.pRowAction, styles.pRowWide)}>{action}</span> : null}
      </span>
    </>
  );
  return href ? (
    <Link href={href} className={cx(styles.pRow, styles.isGlobal)}>
      {body}
    </Link>
  ) : (
    <div className={cx(styles.pRow, styles.isGlobal)}>{body}</div>
  );
}

/* ==========================================================================
   Maquette « Détail d'une étape de séries » (propriétaire, 2026-09-20)

   L'écran intermédiaire qui s'ouvre depuis le cycle du Plan sur une étape
   d'entraînement de compréhension (CO/CE) ou une étape civique : le domaine et
   la priorité en pastilles, la compétence en titre, l'avancement, puis une
   carte par série.

   🛑 Miroirs de `SfSerieProgress` et `SfSerieCard` côté Flutter. Un motif qui
   bouge d'un côté bouge de l'autre dans la même passe.
   ========================================================================== */

/**
 * **L'avancement d'une étape de séries** — le gros compteur à gauche, le seuil
 * à droite, et la barre en dessous.
 *
 * 🛑 **Elle n'est pas `CycleProgress`**, et il ne faut pas les confondre :
 * celle-là compte les **étapes d'un cycle** (un compteur en mots, un repère de
 * cycle) ; celle-ci compte les **séries d'une étape**, met son chiffre en
 * évidence et porte, en face, le seuil à tenir sur chacune. Deux échelles, deux
 * lectures.
 *
 * 🛑 **Aucune phrase n'est composée ici** : `count`, `note` et `noteSub`
 * arrivent en props, tous trois posés sur des faits servis
 * (`quota`, `seuilReussite`, `questionsParSerie`).
 *
 * Miroir Flutter : `SfSerieProgress`.
 */
export function SerieProgress({
  count,
  note,
  noteSub,
  done,
  total,
}: {
  /** « 0/2 séries », composé par l'appelant. */
  count: string;
  /** « 16/20 minimum ». */
  note: string;
  /** « sur chacune ». */
  noteSub: string;
  /** Les séries **validées** — un décompte de booléens servis. */
  done: number;
  /** Le quota **servi**. */
  total: number;
}) {
  const ratio = total > 0 ? Math.max(0, Math.min(1, done / total)) : 0;
  return (
    <Card>
      <div className={styles.serieProgTop}>
        <b className={styles.serieProgCount}>{count}</b>
        <span className={styles.serieProgNote}>
          <b>{note}</b>
          <small>{noteSub}</small>
        </span>
      </div>
      <div className={styles.serieProgBar} aria-hidden>
        <i style={{ width: `${Math.round(ratio * 100)}%` }} />
      </div>
    </Card>
  );
}

/**
 * **La carte d'une série** — repère carré, titre, méta, badge d'état, puis le
 * bouton pleine largeur et, si la série a déjà été jouée, l'accès à son
 * corrigé.
 *
 * 🛑 **Le kit ne décide d'aucun état.** `state`, `action.disabled` et la
 * présence de `link` sont posés par l'appelant à partir de `locked` et
 * `validee`, **servis** — jamais d'une comparaison entre un score et un seuil.
 *
 * 🛑 **`locked` grise la carte, il ne la masque pas** : le repère, le titre, la
 * méta et le bouton restent lisibles (R16 — on floute l'action, jamais le
 * résultat). Le bouton porte alors la condition (« Après la série 1 ») et ne
 * répond pas.
 *
 * **Carte JOUÉE = carte COMPACTE** (demande du propriétaire, 2026-09-27) :
 * quand `verdict` et `onOpen` sont posés, la carte se réduit à une ligne
 * touchable — repère à **coche verte** (`ok`) ou **croix rouge** (`fail`), le
 * motif des cartes de séries et d'examens blancs (`serieCheck` /
 * `examCheckFail` du hub) —, titre, score et état. Ni gros bouton ni lien :
 * « Refaire » et le corrigé passent par la feuille que l'appelant ouvre
 * (`ExamDoneSheet`, la même que les séries d'entraînement). 🛑 **Une variante,
 * pas une primitive de plus.**
 *
 * Miroir Flutter : `SfSerieCard`.
 */
export function SerieCard({
  mark,
  title,
  duree,
  questions,
  state,
  score,
  locked,
  action,
  link,
  verdict,
  onOpen,
}: {
  /** Le chiffre du carré — l'`index` **servi**, mis en texte par l'appelant. */
  mark: string;
  /** « Série 1 ». */
  title: string;
  /** « 16 min ». `null` quand la durée n'est pas servie : rien à sa place. */
  duree: string | null;
  /** « 20 questions ». */
  questions: string;
  /** Le badge d'état et son ton, **composés** par l'appelant. */
  state: { label: string; tone: BarTone };
  /** « Dernier score : 17/20 ». `null` tant que la série n'a pas été jouée. */
  score: string | null;
  locked: boolean;
  /** Le bouton pleine largeur. Sans `onClick`, il est inerte. */
  action: { label: string; onClick?: () => void; disabled?: boolean };
  /** Le second accès d'une série jouée : son corrigé. */
  link?: { label: string; href: string };
  /**
   * Le verdict d'une série **jouée**, composé par l'appelant sur des faits
   * servis. Avec `onOpen`, il rend la carte compacte ; `null` = carte à faire.
   */
  verdict?: "ok" | "fail" | null;
  /** Le toucher d'une carte compacte : la feuille « corrigé / refaire ». */
  onOpen?: () => void;
}) {
  if (verdict && onOpen) {
    const ok = verdict === "ok";
    return (
      <button
        type="button"
        className={cx(styles.serieCard, styles.serieCardCompact)}
        onClick={onOpen}
      >
        <span className={cx(styles.serieMark, ok ? styles.isOk : styles.isFail)}>
          {mark}
          <span className={styles.serieMarkCheck} aria-hidden>
            {ok ? <Check size={11} strokeWidth={3} /> : <X size={11} strokeWidth={3} />}
          </span>
        </span>
        <span className={styles.serieCardText}>
          <b>{title}</b>
          {score ? <span className={styles.serieMeta}>{score}</span> : null}
        </span>
        <span className={cx(styles.serieState, statusToneClass[state.tone])}>
          {state.label}
        </span>
        <ChevronRight size={16} strokeWidth={2.2} className={styles.serieChevron} aria-hidden />
      </button>
    );
  }
  const inerte = action.disabled || !action.onClick;
  return (
    <div className={cx(styles.serieCard, locked && styles.isLocked)}>
      <div className={styles.serieCardTop}>
        <span className={cx(styles.serieMark, locked && styles.isLocked)}>{mark}</span>
        <span className={styles.serieCardText}>
          <b>{title}</b>
          <span className={styles.serieMeta}>
            {duree ? (
              <span>
                <Clock size={13} strokeWidth={2.2} aria-hidden />
                {duree}
              </span>
            ) : null}
            <span>
              <ListChecks size={13} strokeWidth={2.2} aria-hidden />
              {questions}
            </span>
          </span>
        </span>
        <span className={cx(styles.serieState, statusToneClass[state.tone])}>
          {state.label}
          {locked ? <Lock size={12} strokeWidth={2.2} aria-hidden /> : null}
        </span>
      </div>
      {score ? <p className={styles.serieScore}>{score}</p> : null}
      <button
        type="button"
        className={cx(styles.serieBtn, inerte && styles.isOff)}
        onClick={action.onClick}
        disabled={inerte}
      >
        {action.label}
        {inerte ? null : <ArrowRight size={18} strokeWidth={2} aria-hidden />}
      </button>
      {link ? (
        <Link href={link.href} className={styles.serieLink}>
          {link.label}
          <ChevronRight size={15} strokeWidth={2.2} aria-hidden />
        </Link>
      ) : null}
    </div>
  );
}

/* ==========================================================================
   NAVIGATION V2 — ACCUEIL (phase 3, 2026-10-03)

   Maquette : `docs/redesign/sejourfr-navigation-web.html` (`#accueil`) et
   `sejourfr-navigation-mobile.html` (`.objectives-card`). Miroirs Flutter,
   mêmes noms préfixés `Sf` (`sejour_kit.dart`) : `SfActionCard`, `SfObjCard`,
   `SfObjectivesCard`, `SfObjectiveRow`, `SfBlockSkeleton`, `SfBlockError`.
   `PageHead` (web) ⇄ `SfModuleHeader` (mobile, phase 2) : même anatomie —
   kicker teinté, grand titre, phrase de cadrage —, le web y ajoute la
   rangée de pastilles à droite (`aside`), sans équivalent téléphone.

   🛑 **Rien n'est calculé ici** : valeurs, libellés et gestes arrivent
   composés par l'écran (`lib/accueil.ts`), à partir de faits servis.
   ========================================================================== */

/** Le module qui teinte une primitive : TCF bleu, civique rouge (X1). */
export type ModuleTone = "tcf" | "civique";

const moduleToneClass: Record<ModuleTone, string> = {
  tcf: styles.modTcf,
  civique: styles.modCivique,
};

/**
 * **L'en-tête de page de la maquette** (`.page-head`) : kicker en pastille
 * teintée, grand titre (`--shell-h1-size`, 32 → 26 px sous 760 px), phrase
 * de cadrage, et à droite des pastilles facultatives (`aside`).
 *
 * Miroir Flutter : `SfModuleHeader` (`civique`, `kicker?`, `title`, `lead`) —
 * `aside` n'a pas d'équivalent téléphone.
 */
export function PageHead({
  kicker,
  title,
  subtitle,
  tone = "tcf",
  aside,
}: {
  /** `null` ⇒ pas de pastille (démarche inconnue : rien n'est deviné). */
  kicker?: string | null;
  title: string;
  subtitle?: string | null;
  /** La teinte du kicker. `tcf` (bleu) par défaut, comme la maquette. */
  tone?: ModuleTone;
  aside?: ReactNode;
}) {
  return (
    <header className={cx(styles.pageHead, moduleToneClass[tone])}>
      <div className={styles.pageHeadText}>
        {kicker ? <span className={styles.pageKicker}>{kicker}</span> : null}
        <h1 className={styles.pageTitle}>{title}</h1>
        {subtitle ? <p className={styles.pageSub}>{subtitle}</p> : null}
      </div>
      {aside ? <div className={styles.pageHeadAside}>{aside}</div> : null}
    </header>
  );
}

/** Le geste d'une carte : un lien, ou un bouton. */
export type ActionCardCta = {
  label: string;
  /** Un lien (`OUVRIR_ETAPE`, page d'offre). Exclusif avec `onClick`. */
  href?: string;
  onClick?: () => void;
  /** Lancement en cours. */
  disabled?: boolean;
};

/**
 * L'emphase d'un CTA de module (`.cta` de la maquette) :
 * - `solid` — plein, couleur du module, flèche (`.cta.blue|red`) ;
 * - `soft` — gris doux, texte encre, sans flèche (`.cta.soft`) ;
 * - `ghost` — teinte douce du module, texte du module (`.cta.ghost-blue|red`).
 */
export type CtaEmphasis = "solid" | "soft" | "ghost";

const ctaEmphasisClass: Record<CtaEmphasis, string | undefined> = {
  solid: undefined,
  soft: styles.isSoft,
  ghost: styles.isGhost,
};

function ModuleCta({
  cta,
  block,
  emphasis = "solid",
}: {
  cta: ActionCardCta;
  block?: boolean;
  emphasis?: CtaEmphasis;
}) {
  const cls = cx(styles.modCta, block && styles.isBlock, ctaEmphasisClass[emphasis]);
  const body = (
    <>
      {cta.label}
      {emphasis === "solid" ? <ArrowRight aria-hidden /> : null}
    </>
  );
  return cta.href && !cta.disabled ? (
    <Link href={cta.href} className={cls} onClick={cta.onClick}>
      {body}
    </Link>
  ) : (
    <button type="button" className={cls} onClick={cta.onClick} disabled={cta.disabled}>
      {body}
    </button>
  );
}

/**
 * **La carte « À faire maintenant » d'un module** (`.card.action-card`) :
 * icône PLEINE du module, label, titre, méta, badge facultatif à droite, puis
 * le CTA plein du module.
 *
 * 🛑 **`cta: null` = état neutre** — rien à lancer (`AUCUN` servi) : l'icône
 * passe en teinte douce et aucun bouton mort n'est posé. `children` porte une
 * note éventuelle (verrou, erreur de lancement), entre l'en-tête et le CTA.
 *
 * Miroir Flutter : `SfActionCard` (`civique`, `icon`, `label`, `title`,
 * `meta?`, `badge?`, `cta?` (libellé), `onPressed?`) — `cta` ou `onPressed`
 * nuls ⇒ carte neutre. Ici `cta` porte libellé + geste (`href` | `onClick`) ;
 * `block` et `children` (note) sont propres au web.
 */
export function ActionCard({
  module,
  icon,
  label,
  title,
  meta,
  badge,
  cta,
  block,
  children,
}: {
  module: ModuleTone;
  /** Le pictogramme (trait de la maquette), teinté par la carte. */
  icon: ReactNode;
  label: string;
  title: string;
  /** « Examen blanc · ≈ 20 min ». `null` ⇒ pas de ligne. */
  meta?: string | null;
  /** Le code court servi (« CO »). `null` ⇒ pas de badge. */
  badge?: string | null;
  cta?: ActionCardCta | null;
  /** CTA pleine largeur (`.cta.block` de la maquette web). */
  block?: boolean;
  children?: ReactNode;
}) {
  return (
    <article className={cx(styles.actionCard, moduleToneClass[module], !cta && styles.isNeutral)}>
      <div className={styles.actionTop}>
        <span className={styles.actionIcon} aria-hidden>
          {icon}
        </span>
        <div className={styles.actionCopy}>
          <p className={styles.actionLabel}>{label}</p>
          <h3 className={styles.actionTitle}>{title}</h3>
          {meta ? <p className={styles.actionMeta}>{meta}</p> : null}
        </div>
        {badge ? <Badge module={module}>{badge}</Badge> : null}
      </div>
      {children}
      {cta ? <ModuleCta cta={cta} block={block} /> : null}
    </article>
  );
}

/** Une métrique de carte d'objectif : la valeur en gros, son mot dessous. */
export type ObjMetric = { value: string; label: string };

/**
 * **La grande carte d'objectif web** (`.obj-card`) : dégradé du module, halo,
 * pictogramme et pastille, titre, description, barre blanche, puis trois
 * métriques. Toute la carte est un lien.
 *
 * 🛑 `progress` est une **fraction déjà calculée** par l'écran sur des faits
 * servis (0 → 1) ; `null` retire la barre — jamais une barre à 0 inventée.
 *
 * Miroir Flutter : `SfObjCard` (`civique`, `icon`, `pill`, `title`,
 * `description?`, `progress?`, `metrics` (`SfObjMetric`), `onTap?`) ; ici
 * `href` (un lien web) tient lieu d'`onTap`.
 */
export function ObjCard({
  module,
  icon,
  pill,
  title,
  description,
  progress,
  metrics,
  href,
}: {
  module: ModuleTone;
  icon: ReactNode;
  pill: string;
  title: string;
  description?: string | null;
  progress?: number | null;
  metrics: ObjMetric[];
  href: string;
}) {
  const ratio =
    progress == null || !Number.isFinite(progress) ? null : Math.max(0, Math.min(1, progress));
  return (
    <Link href={href} className={cx(styles.objCard, moduleToneClass[module])}>
      <span className={styles.objTop}>
        <span className={styles.objIcon} aria-hidden>
          {icon}
        </span>
        <span className={styles.objPill}>{pill}</span>
      </span>
      <span className={styles.objTitle}>{title}</span>
      {description ? <span className={styles.objDesc}>{description}</span> : null}
      <span className={styles.objBottom}>
        {ratio !== null ? (
          <span className={styles.objBar} aria-hidden>
            <span style={{ width: `${Math.round(ratio * 100)}%` }} />
          </span>
        ) : null}
        {metrics.length > 0 ? (
          <span className={styles.objMetrics}>
            {metrics.map((m) => (
              <span key={m.label} className={styles.objMetric}>
                <strong>{m.value}</strong>
                <span>{m.label}</span>
              </span>
            ))}
          </span>
        ) : null}
      </span>
    </Link>
  );
}

/**
 * **Le squelette d'UN bloc**, aux dimensions du composant qu'il remplace —
 * jamais un spinner plein écran (brief §7). Décoratif : il ne se lit pas.
 * `radius` en px ; absent, le rayon des cartes du kit (`--sf-radius-4xl`).
 *
 * Miroir Flutter : `SfBlockSkeleton` (`height`, `radius`).
 */
export function BlockSkeleton({ height, radius }: { height: number; radius?: number }) {
  return (
    <span
      className={styles.skel}
      style={{ height, ...(radius != null ? { borderRadius: radius } : null) }}
      aria-hidden
    />
  );
}

/**
 * **L'échec d'UN bloc** : un message et « Réessayer », à la place du bloc
 * seul — le reste de l'écran reste utilisable (brief §7).
 *
 * Miroir Flutter : `SfBlockError` (`message`, `onRetry`, `retryLabel`).
 */
export function BlockError({
  message,
  onRetry,
  retryLabel = "Réessayer",
}: {
  message: string;
  onRetry: () => void;
  retryLabel?: string;
}) {
  return (
    <div className={styles.blockError} role="alert">
      <AlertCircle className={styles.blockErrorIco} size={20} strokeWidth={2} aria-hidden />
      <p className={styles.blockErrorText}>{message}</p>
      <button type="button" className={styles.blockErrorRetry} onClick={onRetry}>
        {retryLabel}
      </button>
    </div>
  );
}

/* ==========================================================================
   NAVIGATION V2 — PRIMITIVES DES ÉCRANS DE MODULE (phase 4a, 2026-10-03)

   Maquette : `docs/redesign/sejourfr-navigation-web.html`, écrans TCF ·
   Mon plan / Entraînement / Examens blancs / Progression, Civique · Plan /
   Entraînement / Examens / Progression, Profil (`.hero`, `.info-card`,
   `.metric`, `.timeline`, `.theme-card`, `.ring`, `.tip-card`,
   `.exam-row`, `.badge`, `.split`, `.grid-2`, `.grid-4`).

   Miroirs Flutter, même nom préfixé `Sf` (`sejour_kit.dart`) : `Hero`,
   `InfoCard`, `Metric`, `Timeline`, `ThemeCard`, `TipCard`,
   `ProgressionHead`, `ExamRow`, `Badge`. Le web prend
   `module: "tcf" | "civique"` là où le mobile prend `civique: bool`, comme
   `ActionCard`. `Split` et `Grid` sont des règles de MISE EN PAGE (media
   queries) : aucun miroir.

   🛑 **Rien n'est calculé ni classé ici.** Valeurs, libellés, états et tons
   arrivent composés par l'écran à partir de faits SERVIS. Un `tone` est
   toujours celui d'un état servi, jamais un seuil appliqué à un nombre.
   ========================================================================== */

/**
 * Le ton d'un état **servi** sur les primitives de la maquette : vert, ambre
 * (texte en `amber-dark`), rouge, neutre.
 *
 * 🛑 `neutral` couvre aussi le « non mesuré » : `null = inconnu, jamais
 * mauvais`. Miroir Flutter : `SfTone` (`ok|warn|hot|muted`) via `SfState`.
 */
export type StateTone = "success" | "warning" | "danger" | "neutral";

/** Un état servi, déjà mis en mots : son libellé et son ton. */
export type ServedState = { label: string; tone: StateTone };

/**
 * Le ton du kit historique (`ok | warn | hot | muted`) lu dans la palette des
 * primitives v2 — une traduction de palette, pas un classement. Seule table du
 * web (`lib/etats-servis.ts` la relit). Miroir : `SfTone` est commun.
 */
export const toneToStateTone: Record<Tone, StateTone> = {
  ok: "success",
  warn: "warning",
  hot: "danger",
  muted: "neutral",
};

const stateToneClass: Record<StateTone, string> = {
  success: styles.toneSuccess,
  warning: styles.toneWarning,
  danger: styles.toneDanger,
  neutral: styles.toneNeutral,
};

/** Un chiffre mis en avant et ce qu'il nomme (« 1/4 » · « épreuves au B2 »). */
export type HeroStat = { value: string; label: string };

/** Le pictogramme d'une `Hero`, d'une `InfoCard`, d'une `ThemeCard`… */
function IconBox({ icon, solid }: { icon: ReactNode; solid?: boolean }) {
  return (
    <span className={cx(styles.iconBox, solid && styles.isSolid)} aria-hidden>
      {icon}
    </span>
  );
}

/** Une part entre 0 et 1, ou `null` quand elle n'est pas exploitable. */
function clampRatio(value: number | null | undefined): number | null {
  if (value == null || !Number.isFinite(value)) return null;
  return Math.max(0, Math.min(1, value));
}

/** Le lien ou le bouton qui enveloppe une ligne cliquable ; un `div` sinon. */
function Pressable({
  className,
  href,
  onClick,
  children,
}: {
  className: string;
  href?: string | null;
  onClick?: (() => void) | null;
  children: ReactNode;
}) {
  if (href) {
    return (
      <Link href={href} className={cx(className, styles.isPressable)}>
        {children}
      </Link>
    );
  }
  if (onClick) {
    return (
      <button type="button" className={cx(className, styles.isPressable)} onClick={onClick}>
        {children}
      </button>
    );
  }
  return <div className={className}>{children}</div>;
}

/**
 * **La pastille de la maquette** (`.badge`) : code court (« CO »), chip
 * d'en-tête (« Objectif · B2 »), compteur (« {terminées}/{total} séries ») ou état servi.
 *
 * - `tone` posé ⇒ couleurs de l'état servi (vert / ambre / rouge / neutre) ;
 * - sinon ⇒ teinte douce du module (`module`, TCF par défaut).
 * - `check` ⇒ une coche avant le texte (« ✓ Objectif atteint ») ; sans texte,
 *   `label` nomme la coche.
 *
 * Miroir Flutter : `SfBadge` (`civique`, `tone?`, `check`, `label`).
 */
export function Badge({
  children,
  tone,
  module = "tcf",
  check,
  label,
}: {
  children?: ReactNode;
  tone?: StateTone | null;
  module?: ModuleTone;
  check?: boolean;
  /** Nom accessible d'une coche sans texte. */
  label?: string;
}) {
  return (
    <span
      className={cx(styles.modBadge, tone ? stateToneClass[tone] : moduleToneClass[module])}
      aria-label={!children && label ? label : undefined}
      role={!children && label ? "img" : undefined}
    >
      {check ? <Check aria-hidden /> : null}
      {children}
    </span>
  );
}

/**
 * **Le bandeau de module** (`.hero` / `.hero.red`) : dégradé du module, deux
 * halos clairs, label, titre, phrase, chiffre mis en avant à droite, barre
 * blanche, puis un CTA translucide.
 *
 * Remplace `HeroBanner` (le bandeau d'archive) : même rôle de tête d'écran,
 * `children` y pose encore les compteurs (`StatGrid onHero`).
 *
 * 🛑 `progress` est une **part déjà calculée** sur des faits servis (0 → 1) ;
 * `null` retire la barre — jamais une barre à 0 inventée. `stat` absent ⇒
 * rien à droite.
 *
 * Miroir Flutter : `SfHero` (`civique`, `label`, `title`, `sub?`, `stat?`,
 * `progress?`, `cta?` (libellé) + `onPressed?`, `icon?`, `child?`).
 */
export function Hero({
  module,
  label,
  title,
  sub,
  stat,
  progress,
  cta,
  icon,
  children,
}: {
  module: ModuleTone;
  label: string;
  title: string;
  sub?: string | null;
  stat?: HeroStat | null;
  progress?: number | null;
  cta?: ActionCardCta | null;
  /** Pictogramme facultatif, en pastille translucide avant le label. */
  icon?: ReactNode;
  /** Ce que l'écran pose sous le bandeau (compteurs). */
  children?: ReactNode;
}) {
  const ratio = clampRatio(progress);
  return (
    <section className={cx(styles.modHero, moduleToneClass[module])}>
      <div className={styles.modHeroTop}>
        <div className={styles.modHeroId}>
          {icon ? (
            <span className={styles.modHeroIcon} aria-hidden>
              {icon}
            </span>
          ) : null}
          <div className={styles.modHeroCopy}>
            <p className={styles.modHeroLabel}>{label}</p>
            <h2 className={styles.modHeroTitle}>{title}</h2>
            {sub ? <p className={styles.modHeroSub}>{sub}</p> : null}
          </div>
        </div>
        {stat ? (
          <p className={styles.modHeroStat}>
            <strong>{stat.value}</strong>
            <span>{stat.label}</span>
          </p>
        ) : null}
      </div>
      {ratio !== null ? (
        <span className={cx(styles.modBar, styles.isOnHero)} aria-hidden>
          <span style={{ width: `${Math.round(ratio * 100)}%` }} />
        </span>
      ) : null}
      {children ? <div className={styles.modHeroBody}>{children}</div> : null}
      {cta ? (
        cta.href && !cta.disabled ? (
          <Link href={cta.href} className={styles.modHeroCta} onClick={cta.onClick}>
            {cta.label}
            <ArrowRight aria-hidden />
          </Link>
        ) : (
          <button
            type="button"
            className={styles.modHeroCta}
            onClick={cta.onClick}
            disabled={cta.disabled}
          >
            {cta.label}
            <ArrowRight aria-hidden />
          </button>
        )
      ) : null}
    </section>
  );
}

/**
 * **Une ligne-carte d'information** (`.info-card`) : pictogramme doux du
 * module, code court facultatif, titre, méta, et à droite un `trailing`
 * (`Badge`, texte, ou `"chevron"`).
 *
 * `href` ⇒ lien ; `onClick` ⇒ bouton ; aucun des deux ⇒ ligne inerte (sans
 * survol). Sert les « Priorités actuelles » du Plan TCF et « Mon compte » du
 * Profil.
 *
 * Miroir Flutter : `SfInfoCard` (`civique`, `icon`, `code?`, `title`,
 * `meta?`, `trailing?`, `onTap?`).
 */
export function InfoCard({
  module = "tcf",
  icon,
  code,
  title,
  meta,
  trailing,
  href,
  onClick,
}: {
  module?: ModuleTone;
  icon: ReactNode;
  /** Le code court servi (« CO »), en pastille au-dessus du titre. */
  code?: string | null;
  title: string;
  meta?: string | null;
  /** `"chevron"`, une `Badge`, ou tout autre bloc court. */
  trailing?: ReactNode | "chevron";
  href?: string | null;
  onClick?: (() => void) | null;
}) {
  return (
    <Pressable
      className={cx(styles.infoCard, moduleToneClass[module])}
      href={href}
      onClick={onClick}
    >
      <IconBox icon={icon} />
      <span className={styles.infoCopy}>
        {code ? <Badge module={module}>{code}</Badge> : null}
        <span className={cx(styles.infoTitle, code && styles.hasCode)}>{title}</span>
        {meta ? <span className={styles.infoMeta}>{meta}</span> : null}
      </span>
      {trailing === "chevron" ? (
        <span className={styles.infoChevron} aria-hidden>
          <ChevronRight />
        </span>
      ) : trailing ? (
        <span className={styles.infoTrailing}>{trailing}</span>
      ) : null}
    </Pressable>
  );
}

/**
 * **La tuile d'une épreuve** (`.metric`) : code en pastille, valeur en gros
 * (le niveau servi, « — » quand il manque), état servi coloré, méta, puis le
 * CTA pleine largeur — `solid` (plein, couleur du module) sur l'épreuve que
 * le serveur désigne, `soft` sinon.
 *
 * 🛑 `ctaEmphasis` est une **décision d'écran** prise sur un fait servi (la
 * priorité désignée), jamais sur la valeur affichée.
 *
 * Miroir Flutter : `SfMetric` (`civique`, `code`, `value`, `state?`,
 * `meta?`, `cta?` + `onPressed?`, `ctaEmphasis`).
 */
export function Metric({
  module,
  code,
  title,
  value,
  state,
  meta,
  cta,
  ctaEmphasis = "soft",
}: {
  module: ModuleTone;
  code: string;
  /** Le nom de l'épreuve, lisible d'un coup d'œil sous la pastille. */
  title?: string | null;
  value: string;
  state?: ServedState | null;
  meta?: string | null;
  cta?: ActionCardCta | null;
  ctaEmphasis?: "solid" | "soft";
}) {
  return (
    <article className={cx(styles.metric, moduleToneClass[module])}>
      <span className={styles.metricHead}>
        <Badge module={module}>{code}</Badge>
      </span>
      {title ? <p className={styles.metricTitle}>{title}</p> : null}
      <p className={styles.metricValue}>{value}</p>
      {state ? (
        <p className={cx(styles.metricState, stateToneClass[state.tone])}>{state.label}</p>
      ) : null}
      {meta ? <p className={styles.metricMeta}>{meta}</p> : null}
      {cta ? (
        <div className={styles.metricCta}>
          <ModuleCta cta={cta} block emphasis={ctaEmphasis} />
        </div>
      ) : null}
    </article>
  );
}

/**
 * **La frise des derniers repères** (`.card` + `.timeline` + `.step`) : un
 * label, des pastilles reliées par des flèches — la DERNIÈRE est active,
 * pleine couleur du module —, puis une ligne de méta.
 *
 * 🛑 Les repères sont des valeurs **servies** déjà écrites (un palier, un taux),
 * dans l'ordre servi, sans « + » ni demi-palier inventé. Liste vide ⇒ aucune
 * frise : l'écran pose son état vide à la place.
 *
 * Miroir Flutter : `SfTimeline` (`civique`, `steps`, `label?`, `caption?`).
 */
export function Timeline({
  module,
  steps,
  label,
  caption,
}: {
  module: ModuleTone;
  steps: string[];
  label?: string | null;
  caption?: string | null;
}) {
  return (
    <section className={cx(styles.modCard, moduleToneClass[module])}>
      {label ? <p className={styles.modLabel}>{label}</p> : null}
      {steps.length > 0 ? (
        <ol className={styles.timeline}>
          {steps.map((step, index) => {
            const last = index === steps.length - 1;
            return (
              <li key={`${index}-${step}`} className={styles.timelineItem}>
                <span
                  className={cx(styles.timelineStep, last && styles.isActive)}
                  aria-current={last ? "step" : undefined}
                >
                  {step}
                </span>
                {last ? null : (
                  <span className={styles.timelineArrow} aria-hidden>
                    →
                  </span>
                )}
              </li>
            );
          })}
        </ol>
      ) : null}
      {caption ? <p className={styles.modMeta}>{caption}</p> : null}
    </section>
  );
}

/**
 * **La carte d'un thème** (`.theme-card`) : pictogramme doux, nom servi,
 * description servie (absente ⇒ rien), anneau de couverture à droite, puis
 * le compteur en pastille, l'état servi, et le CTA doux du module.
 *
 * 🛑 `ring` est un **pourcentage déjà calculé** par l'autorité unique
 * (`avancementSeriesCivique`) ; l'état n'en est jamais déduit.
 *
 * `href` sans `cta` ⇒ toute la carte est un lien ; avec `cta`, seul le
 * bouton agit (pas de lien imbriqué).
 *
 * Miroir Flutter : `SfThemeCard` (`civique`, `icon`, `title`,
 * `description?`, `ring`, `count`, `state?`, `cta?` + `onPressed?`).
 */
export function ThemeCard({
  module,
  icon,
  title,
  description,
  ring,
  count,
  state,
  cta,
  href,
}: {
  module: ModuleTone;
  icon: ReactNode;
  title: string;
  description?: string | null;
  /** 0 → 100, déjà calculé. */
  ring: number;
  /** « {terminées}/{total} séries ». */
  count: string;
  state?: ServedState | null;
  cta?: ActionCardCta | null;
  href?: string | null;
}) {
  const pct = Number.isFinite(ring) ? Math.max(0, Math.min(100, Math.round(ring))) : 0;
  const body = (
    <>
      <span className={styles.themeHead}>
        <IconBox icon={icon} />
        <span className={styles.themeCopy}>
          <span className={styles.themeTitle}>{title}</span>
          {description ? <span className={styles.infoMeta}>{description}</span> : null}
        </span>
        <Ring ratio={pct / 100} module={module} text={`${pct} %`} label={`${pct} %`} />
      </span>
      <span className={styles.themeFoot}>
        <Badge module={module}>{count}</Badge>
        {state ? (
          <span className={styles.themeState}>
            <i className={cx(styles.stateDot, stateToneClass[state.tone])} aria-hidden />
            {state.label}
          </span>
        ) : null}
      </span>
    </>
  );
  const cls = cx(styles.themeCardV2, moduleToneClass[module]);
  if (href && !cta) {
    return (
      <Link href={href} className={cx(cls, styles.isPressable)}>
        {body}
      </Link>
    );
  }
  return (
    <article className={cls}>
      {body}
      {cta ? <ModuleCta cta={cta} block emphasis="ghost" /> : null}
    </article>
  );
}

/**
 * **La carte conseil** (`.tip-card`) : fond ambré, label ambre, une phrase,
 * un CTA facultatif (plein, couleur de `module`, TCF par défaut).
 *
 * 🛑 Le texte est éditorial ou composé sur des faits servis : la carte ne
 * fabrique aucun conseil. Sans texte à dire, l'écran ne la pose pas.
 *
 * Miroir Flutter : `SfTipCard` (`icon?`, `label`, `text`, `cta?` +
 * `onPressed?`, `civique`).
 */
export function TipCard({
  icon,
  label,
  text,
  cta,
  module = "tcf",
}: {
  icon?: ReactNode;
  label: string;
  text: string;
  cta?: ActionCardCta | null;
  module?: ModuleTone;
}) {
  return (
    <aside className={cx(styles.tipCard, moduleToneClass[module])}>
      <p className={styles.tipLabel}>
        {icon ? (
          <span className={styles.tipIcon} aria-hidden>
            {icon}
          </span>
        ) : null}
        {label}
      </p>
      <p className={styles.tipText}>{text}</p>
      {cta ? (
        <div className={styles.tipCta}>
          <ModuleCta cta={cta} block />
        </div>
      ) : null}
    </aside>
  );
}

/** Une valeur de tête de progression : le chiffre et ce qu'il nomme. */
export type HeadValue = { value: string; label: string };

/**
 * **La carte de tête d'un écran Progression** (`.card.card-pad` « Objectif
 * global » / « Maîtrise globale »), deux formes :
 *
 * - **`from` / `to`** (TCF) : niveau actuel → objectif, une flèche ronde
 *   entre les deux, le libellé AU-DESSUS de la valeur, l'objectif à la
 *   couleur du module. 🛑 **Aucune barre** dans cette forme : un pourcentage
 *   posé à côté de deux niveaux se lirait comme une distance entre eux.
 * - **`primary` / `secondary?` / `progress?`** (civique) : la valeur
 *   principale à la couleur du module, la secondaire à droite, le libellé
 *   SOUS la valeur, puis la barre du module (part déjà calculée, `null` ⇒
 *   pas de barre).
 *
 * Miroir Flutter : `SfProgressionHead` (`civique`, `label`, `from?`/`to?`
 * ou `primary?`/`secondary?`/`progress?`).
 */
export function ProgressionHead(
  props: { module: ModuleTone; label: string } & (
    | { from: HeadValue; to: HeadValue }
    | { primary: HeadValue; secondary?: HeadValue | null; progress?: number | null }
  ),
) {
  const { module, label } = props;
  if ("from" in props) {
    return (
      <section className={cx(styles.modCard, moduleToneClass[module])}>
        <p className={styles.modLabel}>{label}</p>
        <div className={styles.headRow}>
          <p className={styles.headValue}>
            <span>{props.from.label}</span>
            <strong>{props.from.value}</strong>
          </p>
          <span className={styles.headArrow} aria-hidden>
            <ArrowRight />
          </span>
          <p className={cx(styles.headValue, styles.isEnd, styles.isModule)}>
            <span>{props.to.label}</span>
            <strong>{props.to.value}</strong>
          </p>
        </div>
      </section>
    );
  }
  const ratio = clampRatio(props.progress);
  return (
    <section className={cx(styles.modCard, moduleToneClass[module])}>
      <p className={styles.modLabel}>{label}</p>
      <div className={styles.headRow}>
        <p className={cx(styles.headValue, styles.isModule)}>
          <strong>{props.primary.value}</strong>
          <span>{props.primary.label}</span>
        </p>
        {props.secondary ? (
          <p className={cx(styles.headValue, styles.isEnd)}>
            <strong>{props.secondary.value}</strong>
            <span>{props.secondary.label}</span>
          </p>
        ) : null}
      </div>
      {ratio !== null ? (
        <span className={styles.modBar} aria-hidden>
          <span style={{ width: `${Math.round(ratio * 100)}%` }} />
        </span>
      ) : null}
    </section>
  );
}

/**
 * L'état d'un créneau d'examen, **lu sur `locked` et l'état servi** :
 * `done` (passé), `go` (le prochain à lancer), `locked` (verrou servi),
 * `neutral` (ouvert, sans mise en avant). Miroir : `SfExamRowStatus`.
 */
export type ExamRowStatus = "done" | "go" | "locked" | "neutral";

/**
 * **Une ligne d'examen** (`.exam-row`) : numéro dans un carré — plein au
 * module quand l'examen est passé, doux sinon —, titre, méta servie, et la
 * pastille de statut à droite — pleine au module sur `go`, grise sinon. Une
 * ligne `locked` est atténuée.
 *
 * 🛑 `statusLabel` (« Fait », « Commencer », « Verrouillé ») est passé : le
 * kit n'écrit aucun mot. `href` ⇒ lien, `onClick` ⇒ bouton (un créneau
 * verrouillé peut ouvrir l'offre), aucun ⇒ ligne inerte.
 *
 * Remplace l'ancienne ligne d'épreuve icône + titre du rapport de
 * diagnostic, passée sur `InfoCard`.
 *
 * Miroir Flutter : `SfExamRow` (`civique`, `number`, `title`, `meta?`,
 * `status`, `statusLabel`, `onTap?`).
 */
export function ExamRow({
  module,
  number,
  title,
  meta,
  status,
  statusLabel,
  href,
  onClick,
}: {
  module: ModuleTone;
  number: string | number;
  title: string;
  meta?: string | null;
  status: ExamRowStatus;
  statusLabel: string;
  href?: string | null;
  onClick?: (() => void) | null;
}) {
  return (
    <Pressable
      className={cx(
        styles.examRow,
        moduleToneClass[module],
        status === "locked" && styles.isLocked,
      )}
      href={href}
      onClick={onClick}
    >
      <span className={cx(styles.examNum, status === "done" && styles.isSolid)}>{number}</span>
      <span className={styles.examCopy}>
        <span className={styles.examTitle}>{title}</span>
        {meta ? <span className={styles.infoMeta}>{meta}</span> : null}
      </span>
      <span className={cx(styles.examStatus, status === "go" && styles.isGo)}>
        {statusLabel}
      </span>
    </Pressable>
  );
}

/**
 * **Deux colonnes de la maquette** (`.split`) : principale (1,9 fr) et
 * latérale (≥ 280 px, ses blocs espacés de 18 px), côte à côte au-delà de
 * 1 180 px de fenêtre, empilées en dessous. Une règle de mise en page : pas
 * de miroir Flutter (le mobile empile).
 */
export function Split({ main, side }: { main: ReactNode; side?: ReactNode }) {
  if (side == null) return <>{main}</>;
  return (
    <div className={styles.split}>
      <div className={styles.splitMain}>{main}</div>
      <div className={styles.splitSide}>{side}</div>
    </div>
  );
}

/**
 * **La grille de la maquette** : `cols={4}` (`.grid-4`, 4 → 2 colonnes sous
 * 1 180 px) ou `cols={2}` (`.grid-2`, 2 → 1 colonne sous 760 px). Une carte
 * seule sur sa rangée la prend en entier (règle du kit). Mise en page seule :
 * pas de miroir Flutter.
 */
export function Grid({ cols, children }: { cols: 2 | 4; children: ReactNode }) {
  return <div className={cx(styles.modGrid, cols === 4 ? styles.isFour : styles.isTwo)}>{children}</div>;
}
