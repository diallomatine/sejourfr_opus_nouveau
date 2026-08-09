"use client";

import Link from "next/link";
import {
  ArrowLeft,
  ChevronRight,
  ClipboardCheck,
  Clock,
  FileText,
  Info,
  Mic,
  PenLine,
} from "lucide-react";
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
 * `--skill-accent`. Depuis le 2026-08-09 il vaut **le bleu pour les deux
 * épreuves** : ce qui distingue l'écrit de l'oral, ce sont le titre, le
 * pictogramme (stylo / micro), le verbe d'action et la durée — plus jamais la
 * couleur (cf. `production/config.ts`).
 */

/** Les trois modes du parcours, tels que la maquette les nomme dans sa barre
 *  du bas. « Exemples » n'en fait pas partie : c'est une ressource d'appoint
 *  atteinte depuis la liste des sujets, pas un espace de travail. */
export type SkillMode = "competences" | "sujets" | "examens";

const MODES: readonly {key: SkillMode; label: string; icon: ReactNode}[] = [
  {key: "competences", label: "Compétences", icon: <Clock size={15} strokeWidth={2.2} />},
  {key: "sujets", label: "Sujets", icon: <FileText size={15} strokeWidth={2.2} />},
  {key: "examens", label: "Examens", icon: <ClipboardCheck size={15} strokeWidth={2.2} />},
];

/**
 * Barre segmentée des trois modes, **dans le flux** de la colonne, juste sous
 * la carte « Prochain entraînement » (structure de la maquette client).
 *
 * Elle a remplacé la barre flottante en bas d'écran : celle-ci masquait le
 * dernier élément de chaque liste, imposait une réserve de 118 px en pied de
 * colonne et faisait doublon avec la navigation latérale de l'application.
 *
 * `taskNumero` porte le contexte quand l'écran en a un. Sans lui (grille
 * d'examens blancs), « Sujets » comme « Compétences » retombent sur la
 * tâche 1 : une destination par défaut, jamais un chiffre affiché qui serait
 * faux. L'épreuve n'a plus d'écran d'accueil où retomber.
 */
export function SkillModeTabs({
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
    <nav className={s.modeTabs} aria-label="Espaces de l'épreuve">
      {MODES.map((m) => {
        const on = m.key === current;
        return (
          <Link
            key={m.key}
            href={hrefOf(m.key)}
            className={`${s.modeTab} ${on ? s.modeTabOn : ""}`}
            aria-current={on ? "page" : undefined}
          >
            <span aria-hidden>{m.icon}</span>
            {m.label}
          </Link>
        );
      })}
    </nav>
  );
}

/**
 * Colonne unique du parcours — même largeur sur tous les écrans.
 *
 * Deux en-têtes possibles, et un seul par écran :
 * - `title` renseigné ⇒ **en-tête de parcours** de la maquette (flèche de
 *   retour, nom de l'épreuve, sous-titre `TCF IRN · 3 tâches · 30 min`, badge
 *   de palier). C'est celui des trois modes ;
 * - sinon, le lien de retour historique, gardé pour les écrans d'appoint
 *   (modèles corrigés, historique).
 */
export function SkillShell({
  backHref,
  backLabel,
  title,
  meta,
  level,
  children,
}: {
  backHref: string;
  backLabel: string;
  /** Nom de l'épreuve. Renseigné ⇒ en-tête de parcours. */
  title?: string;
  /** Sous-titre d'épreuve (`TCF IRN · 3 tâches · 30 min`). */
  meta?: string;
  /** Palier **visé** par la démarche du candidat. `null` ⇒ pas de badge : on
   *  ne devine jamais une démarche à sa place. */
  level?: string | null;
  children: ReactNode;
}) {
  return (
    <main className={s.wrap}>
      {title ? (
        <header className={s.pageHead}>
          <Link href={backHref} className={s.backDot} aria-label={backLabel}>
            <ArrowLeft size={18} aria-hidden />
          </Link>
          <div className={s.pageHeadBody}>
            <h1 className={s.pageTitle}>{title}</h1>
            {meta && <p className={s.pageMeta}>{meta}</p>}
          </div>
          {level && (
            <span className={s.levelBadge}>
              <span className={s.levelBadgeLabel}>NIVEAU VISÉ</span>
              <strong>{level}</strong>
            </span>
          )}
        </header>
      ) : (
        <Link href={backHref} className={s.back}>
          <ArrowLeft size={16} aria-hidden />
          {backLabel}
        </Link>
      )}
      {children}
    </main>
  );
}

/**
 * Porteur d'accent autonome, pour les blocs rendus **hors** de `SkillShell` —
 * typiquement les formulaires d'exercice réutilisés par la session d'examen
 * blanc, qui a sa propre colonne.
 *
 * ⚠️ **Les deux épreuves sont bleues** depuis le 2026-08-09 : l'accent rouge de
 * l'expression orale est supprimé (cf. `config.ts`). Ce porteur reste utile —
 * il pose les variables du module sur un bloc qui n'est pas dans `.wrap` — mais
 * il ne choisit plus de couleur.
 */
export function SkillAccent({
  className,
  children,
}: {
  className?: string;
  children: ReactNode;
}) {
  return <div className={`${s.accent} ${className ?? ""}`}>{children}</div>;
}

/* ------------------------------------------------- tête commune du parcours */

/** Trois indicateurs chiffrés du héros. */
export interface ParcoursStat {
  value: string;
  label: string;
  unit: string;
}

/**
 * Carte héros du parcours : anneau de progression, trois colonnes chiffrées
 * séparées par des filets, puis la ligne « Progression du parcours ».
 *
 * L'anneau et la ligne disent **la même chose** : la part des sujets publiés
 * déjà produits. C'est volontairement « du parcours » et non « de l'épreuve » —
 * la progression d'épreuve, elle, est dérivée serveur (`GET /api/me/dashboard`)
 * et ne se recalcule jamais côté front.
 */
export function ParcoursHero({
  percent,
  stats,
}: {
  percent: number;
  stats: readonly ParcoursStat[];
}) {
  const pct = Math.min(100, Math.max(0, Math.round(percent)));
  return (
    <section className={s.parcoursHero}>
      <div className={s.parcoursHeroTop}>
        <Ring percent={pct} />
        <div className={s.parcoursStats}>
          {stats.map((st) => (
            <div key={st.label} className={s.parcoursStat}>
              <span className={s.parcoursStatValue}>{st.value}</span>
              <span className={s.parcoursStatLabel}>{st.label}</span>
              <span className={s.parcoursStatUnit}>{st.unit}</span>
            </div>
          ))}
        </div>
      </div>
      <div className={s.heroProgressLabel}>
        <span>Progression du parcours</span>
        <span>{pct} %</span>
      </div>
      <span className={s.heroRail}>
        <span style={{width: `${pct}%`}} />
      </span>
    </section>
  );
}

/** Anneau SVG du héros — blanc sur le dégradé de marque. */
function Ring({percent}: {percent: number}) {
  const radius = 28;
  const circumference = 2 * Math.PI * radius;
  return (
    <svg className={s.ring} viewBox="0 0 64 64" role="img" aria-label={`${percent} %`}>
      <circle className={s.ringTrack} cx="32" cy="32" r={radius} strokeWidth="7" fill="none" />
      <circle
        className={s.ringFill}
        cx="32"
        cy="32"
        r={radius}
        strokeWidth="7"
        fill="none"
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference * (1 - percent / 100)}
      />
      <text className={s.ringText} x="32" y="32" textAnchor="middle" dominantBaseline="central">
        {percent}%
      </text>
    </svg>
  );
}

/**
 * Carte « Prochain entraînement » : pictogramme de l'épreuve, la prochaine
 * chose à faire, et le bouton qui y mène.
 *
 * Le pictogramme est **le repère écrit/oral** depuis que les deux épreuves
 * partagent le bleu : stylo à l'écrit, micro à l'oral.
 */
export function ParcoursNextCard({
  config,
  title,
  subtitle,
  actionLabel,
  href,
}: {
  config: ProductionConfig;
  title: string;
  subtitle: string;
  actionLabel: string;
  href: string;
}) {
  return (
    <section className={s.nextCard}>
      <span className={s.nextIcon} aria-hidden>
        {config.mode === "audio" ? <Mic size={20} /> : <PenLine size={20} />}
      </span>
      <div className={s.nextBody}>
        <strong className={s.nextTitle}>{title}</strong>
        <span className={s.nextText}>{subtitle}</span>
      </div>
      <Link href={href} className={s.nextBtn}>
        {actionLabel}
      </Link>
    </section>
  );
}

/** Une tâche du sélecteur : son intitulé court et sa contrainte réelle. */
export interface TaskCardData {
  numero: number;
  title: string;
  /** `null` quand l'API ne porte pas la contrainte — **aucune borne inventée**
   *  (les bornes EE vivent dans `production_tasks.mots_min/mots_max`). */
  constraint: string | null;
}

/**
 * Sélecteur de tâche : trois cartes « 1 · Message · 30-60 mots », l'active
 * encadrée. Remplace les pastilles T1/T2/T3, qui ne disaient que « Tâche 2 »
 * alors que le format et la contrainte sont précisément ce qui distingue les
 * trois tâches.
 *
 * Ce sont de vrais liens (chaque tâche a son URL, partageable). **`onPick`**
 * les transforme en filtre quand l'écran a déjà les trois tâches en mémoire :
 * le clic simple est intercepté, l'écran filtre, l'URL est réécrite en
 * navigation superficielle. Les clics *modifiés* (Ctrl, ⌘, Maj, clic du
 * milieu) gardent leur comportement natif.
 */
export function TaskCards({
  tasks,
  current,
  hrefOf,
  onPick,
}: {
  tasks: readonly TaskCardData[];
  current: number;
  hrefOf: (n: number) => string;
  onPick?: (n: number) => void;
}) {
  return (
    <nav className={s.taskCards} aria-label="Tâches de l'épreuve">
      {tasks.map((t) => {
        const on = t.numero === current;
        return (
          <Link
            key={t.numero}
            href={hrefOf(t.numero)}
            className={`${s.taskCard} ${on ? s.taskCardOn : ""}`}
            aria-current={on ? "page" : undefined}
            onClick={
              onPick
                ? (e) => {
                    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
                    e.preventDefault();
                    onPick(t.numero);
                  }
                : undefined
            }
          >
            <span className={s.taskCardNum} aria-hidden>
              {t.numero}
            </span>
            <span className={s.taskCardTitle}>{t.title}</span>
            {t.constraint && <span className={s.taskCardMeta}>{t.constraint}</span>}
          </Link>
        );
      })}
    </nav>
  );
}

/**
 * Barre segmentée « Parcours examens blancs · n/N » : un segment par examen,
 * rempli quand l'examen a été passé.
 */
export function ExamTrail({
  done,
  total,
  note,
}: {
  done: number;
  total: number;
  /** Mention libre sous le titre (« Niveau estimé · B1 »). Absente tant que le
   *  backend n'a rendu aucun bilan : on n'écrit pas un niveau inconnu. */
  note?: string | null;
}) {
  return (
    <section className={s.trail}>
      <div className={s.trailTop}>
        <div>
          <strong className={s.trailTitle}>Parcours examens blancs</strong>
          {note && <span className={s.trailNote}>{note}</span>}
        </div>
        <span className={s.trailCount}>
          {done}/{total}
        </span>
      </div>
      <div className={s.trailSegments} aria-hidden>
        {Array.from({length: total}, (_, i) => (
          <span key={i} className={i < done ? s.trailSegmentOn : s.trailSegment} />
        ))}
      </div>
    </section>
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

/**
 * Anneau de progression d'une compétence (« 2/5 »), structure de la maquette.
 *
 * Il a remplacé la pastille de numéro + barre fine sur les lignes de
 * compétence : le rang d'une compétence dans sa tâche n'apprend rien au
 * candidat, alors que « où j'en suis » est exactement ce qu'il vient chercher.
 */
export function SkillRing({
  attempted,
  total,
  done = false,
}: {
  attempted: number;
  total: number;
  done?: boolean;
}) {
  const radius = 19;
  const circumference = 2 * Math.PI * radius;
  const pct = total > 0 ? Math.min(100, Math.max(0, (attempted / total) * 100)) : 0;
  return (
    <svg
      className={`${s.skillRing} ${done ? s.skillRingDone : ""}`}
      viewBox="0 0 46 46"
      role="img"
      aria-label={`${attempted} sur ${total}`}
    >
      <circle className={s.skillRingTrack} cx="23" cy="23" r={radius} strokeWidth="5" fill="none" />
      <circle
        className={s.skillRingFill}
        cx="23"
        cy="23"
        r={radius}
        strokeWidth="5"
        fill="none"
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference * (1 - pct / 100)}
      />
      <text className={s.skillRingValue} x="23" y="21" textAnchor="middle">
        {attempted}
      </text>
      <text className={s.skillRingTotal} x="23" y="32" textAnchor="middle">
        /{total}
      </text>
    </svg>
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

/** `priority` est la seule teinte **rouge** du module : elle sert au Plan, qui
 *  réutilise ces cartes pour les mêmes compétences et a besoin d'un cran plus
 *  fort que `reinforce`. Ajout additif — aucune autre teinte ne change. */
export type SkillBadgeTone =
  | "todo"
  | "treated"
  | "validated"
  | "reinforce"
  | "priority"
  | "level";

const BADGE_CLASS: Record<SkillBadgeTone, string> = {
  todo: s.badgeTodo,
  treated: s.badgeTreated,
  validated: s.badgeValidated,
  reinforce: s.badgeReinforce,
  priority: s.badgePriority,
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

