"use client";

import {track} from "@/lib/analytics";
import Link from "next/link";
import {
  ArrowLeft,
  ArrowRight,
  ChevronRight,
  Info,
  Lock,
  Mic,
  PenLine,
} from "lucide-react";
import type {ReactNode} from "react";
import {type ProductionConfig} from "@/app/_components/production/config";
import {LEARNING_PLAN_SKILL_STATUS_LABEL} from "@/lib/diagnostic";
import {
  type LearningPlanSkillStatus,
  SKILL_MASTERY_STATE_LABEL,
  type SkillMasteryState,
  type SkillPromptStatus,
} from "@/lib/types";
import s from "./skill.module.css";

/**
 * Briques de mise en page du parcours TCF EE/EO, reprises de la maquette
 * client : shell, hero en dégradé, intertitres, encart d'information, cartes
 * en ligne, filtres, statistiques.
 *
 * ⚠️ **Trois briques ont été supprimées le 2026-08-21, faute d'appelant** :
 * `SkillModeTabs` (la barre à trois modes, remplacée par les deux onglets de
 * `TaskChrome` quand les examens blancs ont quitté la tâche), `TaskCards` (le
 * sélecteur de tâche à trois cartes, remplacé par la liste de tâches du hub
 * d'épreuve) et `MiniBar`. Leurs classes CSS sont parties avec elles : une
 * brique dont plus aucun écran ne se sert n'est pas une réserve, c'est de la
 * dette.
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

/**
 * Colonne unique du parcours — même largeur sur tous les écrans.
 *
 * Deux en-têtes possibles, et un seul par écran :
 * - `title` renseigné ⇒ **en-tête de parcours** de la maquette (flèche de
 *   retour, nom de l'épreuve, sous-titre `TCF IRN · 3 tâches · 30 min`, badge
 *   de palier). C'est celui des écrans du parcours ;
 * - sinon, le lien de retour historique, gardé pour les écrans d'appoint
 *   (modèles corrigés, historique).
 */
export function SkillShell({
  backHref,
  backLabel,
  title,
  meta,
  level,
  wide = false,
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
  /**
   * Élargit la colonne au-delà de 1024 px, pour le **seul** écran qui porte
   * une colonne latérale (le résultat d'un micro-exercice de compétence, où la
   * compétence travaillée et la mention d'estimation accompagnent la
   * restitution).
   *
   * ⚠️ Modificateur **opt-in** : sans lui, la colonne garde exactement les
   * 880 px des vingt autres écrans qui montent dans cette coquille. Ne pas
   * l'activer « par symétrie » — un écran d'une seule colonne posé dans
   * 1120 px se lit comme une page inachevée.
   */
  wide?: boolean;
  children: ReactNode;
}) {
  return (
    <main className={`${s.wrap} ${wide ? s.wrapWide : ""}`}>
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
  titleId,
}: {
  title: string;
  text?: string;
  action?: ReactNode;
  /** Pour qu'une `<section>` puisse se nommer par son intertitre. */
  titleId?: string;
}) {
  return (
    <div className={s.sectionHead}>
      <div>
        <h2 className={s.sectionHeadTitle} id={titleId}>{title}</h2>
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

/** Teinte d'un verdict de production. Même échelle que les états de maîtrise
 *  ci-dessous : les deux se lisent sur les mêmes écrans. */
const PLAN_STATUS_TONE: Record<LearningPlanSkillStatus, SkillBadgeTone> = {
  NOT_OBSERVED: "todo",
  PRIORITY: "priority",
  TO_REINFORCE: "reinforce",
  SOLID: "validated",
};

/** Le verdict d'**une** production sur une compétence (frise de la fiche, cartes
 *  du Plan). À ne pas confondre avec `SkillMasteryPill`, qui agrège l'historique. */
export function LearningPlanStatusPill({status}: {status: LearningPlanSkillStatus}) {
  return (
    <SkillBadge tone={PLAN_STATUS_TONE[status]}>
      {LEARNING_PLAN_SKILL_STATUS_LABEL[status]}
    </SkillBadge>
  );
}

/**
 * Teinte d'un état de maîtrise. **Aucune teinte nouvelle** : on réemploie
 * exactement celles des statuts de compétence, pour qu'un candidat lise le même
 * code couleur dans le module Compétences et dans son Plan.
 */
const MASTERY_TONE: Record<SkillMasteryState, SkillBadgeTone> = {
  PRIORITY: "priority",
  TO_REINFORCE: "reinforce",
  CONSOLIDATING: "treated",
  SOLID: "validated",
};

/**
 * Où en est le candidat sur une compétence, tout son historique confondu —
 * **ce que la carte affiche à la place du compteur de sujets traités**.
 *
 * `null` (aucune observation) ⇒ rien : on n'invente pas un état pour une
 * compétence que le serveur n'a jamais vue, et l'appelant reprend son compteur.
 * Brique partagée par la liste des compétences et par le Plan.
 */
export function SkillMasteryPill({state}: {state: SkillMasteryState | null | undefined}) {
  if (!state) return null;
  return (
    <SkillBadge tone={MASTERY_TONE[state]}>{SKILL_MASTERY_STATE_LABEL[state]}</SkillBadge>
  );
}

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

/* -------------------------------------------------------- verrou freemium */

/**
 * Unique chemin d'abonnement du parcours TCF. Le module Compétences est ouvert
 * par le pass **Intégral** : on pré-sélectionne donc le module, comme
 * `PaywallSheet` le fait déjà, et on ne fabrique surtout pas un second parcours
 * de paiement.
 */
export const SKILL_PREMIUM_HREF = "/paiement?module=INTEGRAL";

/** Le libellé du bouton qui ouvre l'offre depuis le module. Wording neutre
 *  (guidelines Apple 3.1.1), **miroir mot pour mot** de `kPremiumLockCta`
 *  (`mobile_sejourfr/lib/core/widgets/premium_lock.dart`). */
export const SKILL_PREMIUM_CTA = "Voir l'abonnement Intégral";

/**
 * Les deux actions proposées sur un petit sujet **déjà traité** : relire son
 * dernier retour, ou le refaire. Libellés gelés, **miroirs mot pour mot** de
 * `kSkillPromptRedoCta` / `skillPromptLastAttemptCta`
 * (`mobile_sejourfr/lib/screens/tcf_production/competences/competence_detail_screen.dart`).
 *
 * ⚠️ Le premier libellé **suit le statut servi**, et c'est volontaire : une
 * tentative `TREATED` a été produite **sans analyse IA** (quota épuisé, ou
 * production rendue sans la demander). Son écran de résultat le dit lui-même
 * (« Sujet marqué comme traité ») et ne montre que la production et les
 * références — lui promettre un « rapport » serait faux.
 */
export const SKILL_PROMPT_REPORT_CTA = "Voir mon dernier rapport";
export const SKILL_PROMPT_ANSWER_CTA = "Voir ma dernière réponse";
export const SKILL_PROMPT_REDO_CTA = "Refaire ce sujet";

/** Le libellé exact du premier choix, selon qu'un verdict existe ou non. */
export function skillPromptLastAttemptCta(status: SkillPromptStatus): string {
  return status === "VALIDATED" || status === "TO_REINFORCE"
    ? SKILL_PROMPT_REPORT_CTA
    : SKILL_PROMPT_ANSWER_CTA;
}

/** Pastille « Premium » d'une carte verrouillée — une seule formulation dans
 *  tout le module, cadenas compris. */
export function SkillLockBadge() {
  return (
    <SkillBadge tone="todo" icon={<Lock size={10} aria-hidden />}>
      Premium
    </SkillBadge>
  );
}

/**
 * Invitation à s'abonner, affichée **à la place** d'une zone de production
 * verrouillée (accès direct par URL à un sujet fermé).
 *
 * Le verrou est celui du serveur (`locked`), qui refuserait la soumission en
 * 403 : laisser le candidat écrire puis perdre sa production serait le pire des
 * deux mondes. On ne masque donc que la saisie, jamais l'endroit où il se
 * trouve.
 */
export function SkillLockedCard({
  title,
  text,
  ctaLabel = SKILL_PREMIUM_CTA,
}: {
  title: string;
  text: string;
  ctaLabel?: string;
}) {
  return (
    <section className={`${s.card} ${s.lockCard}`}>
      <span className={s.lockCardIcon} aria-hidden>
        <Lock size={24} strokeWidth={2.2} />
      </span>
      <h2 className={s.lockCardTitle}>{title}</h2>
      <p className={s.lockCardText}>{text}</p>
      <Link
        href={SKILL_PREMIUM_HREF}
        className={`${s.primary} ${s.lockCardCta}`}
        onClick={() =>
          track("PREMIUM_CTA_CLICKED", {ctaLocation: "OTHER", screen: "competence_verrou"})
        }
      >
        {ctaLabel} <ArrowRight size={16} aria-hidden />
      </Link>
    </section>
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

