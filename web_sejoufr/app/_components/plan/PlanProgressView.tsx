"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {ArrowLeft, ArrowRight, BarChart3, ChevronRight, RotateCcw} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  findAssessment,
  levelLabel,
  PLAN_PROGRESS_DOMAIN_EMPTY,
  PLAN_PROGRESS_LEVEL_LABEL,
  PLAN_PROGRESS_LEVEL_UNKNOWN,
  PLAN_PROGRESS_NOTE,
  PLAN_PROGRESS_OBJECTIVE_LABEL,
  PLAN_PROGRESS_TEXT,
  PLAN_STARTING,
  planAssessmentCta,
  planAssessmentMeta,
  planDomainHref,
  planDomainLabel,
  planDomainProgressLine,
  planLevelRowMeta,
  planProfileCountLabel,
  planProgressTitle,
  SKILL_TASK_TITLE,
} from "@/lib/plan-domain";
import {
  PlanDomainIcon,
  PlanDomainPriorityPill,
  PlanLevelRail,
  PlanTaskRow,
} from "./PlanBits";
import {BlockHead, EmptyCard, PlanRecentChanges, PlanShell} from "./LearningPlanView";
import {usePlanAssessment} from "./use-plan-exercise";
import type {
  LearningPlanDto,
  PlanDomainAssessmentDto,
  PlanDomainDto,
  PlanDomainLevelDto,
} from "@/lib/types";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {RowChevron, SkillMasteryPill} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/** L'eyebrow de l'écran — il dit de quelle famille d'écrans il relève. */
const PLAN_PROGRESS_EYEBROW = "Suivi";
/** Le titre de la section « ce qui a changé » vit dans `PlanRecentChanges` : la
 *  période **est** son titre, et elle vient du serveur. */
const PLAN_PROGRESS_DOMAINS_TITLE = "Mes quatre domaines";
const PLAN_PROGRESS_DOMAINS_TEXT =
  "Dans l'ordre d'urgence décidé par votre plan. Un domaine s'ouvre sur sa fiche.";
const PLAN_PROGRESS_BACK = "Mon plan";

/**
 * **« Ma progression vers le {objectif} »** — le suivi adossé au Plan.
 *
 * Il répond à « où j'en suis sur les quatre domaines du TCF, et à quelle
 * distance de mon objectif ? ». Tout vient de `GET /api/me/plan` : le niveau de
 * départ, l'objectif, le palier en construction, les paliers de compréhension,
 * la couverture des tâches d'expression, et ce qui a changé récemment.
 * **Aucune règle n'est rejouée ici.**
 *
 * ⚠️ **`/statistiques` n'est pas remplacé** : c'est un autre écran, qui garde
 * sa propre entrée et répond à une autre question (thèmes révisés, séries
 * jouées, examens passés).
 *
 * 🛑 **Trois éléments de la maquette sont IMPOSSIBLES et n'ont pas été
 * fabriqués.**
 * 1. Les **barres de pourcentage par palier** (« A2 ████ 90 % ») : le score
 *    interne du moteur de maîtrise n'est exposé à aucun front — les paliers
 *    portent donc leur **état** (`SkillMasteryPill`), qui dit la même chose
 *    sans un chiffre interdit. La note de pied ne parle donc pas de
 *    pourcentages.
 * 2. **« Voir mon bilan »** : cet écran n'existe ni dans l'app ni au serveur.
 * 3. **Le compte de jours** (« Après 4 séances ») : aucune source ne le sert.
 *
 * 🛑 **Aucun verrou freemium** : l'écran n'affiche que de la **mesure** — on
 * floute l'action pas encore accessible, jamais le résultat mesuré. Les seules
 * actions présentes (mesurer un domaine jamais évalué) sont des examens blancs
 * de slot 1, offerts, et le serveur reste l'arbitre au démarrage.
 */
export function PlanProgressView() {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authStatus === "loading" || !user) return;
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => { if (!cancelled) { setPlan(current); setError(null); } },
      (cause: unknown) => {
        if (!cancelled) {
          setError(cause instanceof ApiException ? cause.message : "Impossible de charger votre progression.");
        }
      },
    ).finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [authStatus, user]);

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return (
      <main className={styles.page} aria-busy="true" aria-label="Chargement de votre progression">
        <div className={styles.skeletonHead} />
        <div className={styles.skeletonHero} />
      </main>
    );
  }

  if (!plan) {
    return (
      <PlanShell>
        <div className={styles.narrow}>
          <BackToPlan />
          <EmptyCard
            icon={<RotateCcw size={28} />}
            title="Votre progression n'a pas pu être chargée"
            text={error ?? "Réessayez dans un instant."}
            role="alert"
          >
            <Link className={styles.primaryButton} href="/plan">Revenir à mon plan</Link>
          </EmptyCard>
        </div>
      </PlanShell>
    );
  }

  return <ProgressDetail plan={plan} />;
}

function BackToPlan() {
  return (
    <Link className={styles.back} href="/plan">
      <ArrowLeft size={17} aria-hidden /> {PLAN_PROGRESS_BACK}
    </Link>
  );
}

function ProgressDetail({plan}: {plan: LearningPlanDto}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();

  return (
    <PlanShell>
      <div className={styles.narrow}>
        <BackToPlan />

        <header className={styles.header}>
          <p className={styles.eyebrow}><BarChart3 size={15} aria-hidden /> {PLAN_PROGRESS_EYEBROW}</p>
          <h1>{planProgressTitle(plan.cycle)}</h1>
          <p>{PLAN_PROGRESS_TEXT}</p>
        </header>

        <div className={styles.stack}>
          <ProgressHero plan={plan} />

          <section aria-labelledby="progress-domains">
            <BlockHead
              title={PLAN_PROGRESS_DOMAINS_TITLE}
              text={PLAN_PROGRESS_DOMAINS_TEXT}
              titleId="progress-domains"
            />
            <div className={styles.progressGrid}>
              {plan.domaines.map((domain) => (
                <ProgressDomainCard
                  key={domain.epreuve}
                  domain={domain}
                  assessment={findAssessment(plan, domain.epreuve)}
                  busy={starting === domain.epreuve}
                  onStart={(target) => void start(target)}
                />
              ))}
            </div>
            {error && <p className={styles.milestoneError} role="alert">{error}</p>}
          </section>

          <PlanRecentChanges plan={plan} />

          <p className={styles.asideNote}>{PLAN_PROGRESS_NOTE}</p>
        </div>

        <PaywallSheet
          ctaLocation="LOCKED_PLAN"
          screen="plan_progression"
          open={paywallOpen}
          onClose={closePaywall}
          module="INTEGRAL"
        />
      </div>
    </PlanShell>
  );
}

/**
 * La carte de tête : d'où part le candidat, où il va, et sur combien de
 * domaines son profil repose.
 *
 * 🛑 **L'objectif n'est affiché que s'il est SERVI.** `objectiveLevel` est
 * nullable, et aucun front n'écrit « B2 » à sa place : sans démarche déclarée,
 * la carte ne montre que le niveau estimé et le rail du palier en construction.
 * `startingLevel` suit la même règle — rien de mesuré ⇒ « Pas encore mesuré »,
 * jamais un « A1 » inventé.
 */
function ProgressHero({plan}: {plan: LearningPlanDto}) {
  const {cycle} = plan;
  const starting = levelLabel(cycle.startingLevel);
  return (
    <section className={styles.progressHero} aria-labelledby="progress-hero">
      <h2 className={styles.srOnly} id="progress-hero">{planProgressTitle(cycle)}</h2>
      <div className={styles.progressHeroRow}>
        <p className={styles.progressHeroBlock}>
          <span className={styles.progressHeroLabel}>{PLAN_PROGRESS_LEVEL_LABEL}</span>
          <span className={styles.progressHeroValue} data-unknown={starting ? "0" : "1"}>
            {starting ?? PLAN_PROGRESS_LEVEL_UNKNOWN}
          </span>
        </p>
        {cycle.objectiveLevel && (
          <>
            <ArrowRight className={styles.progressHeroArrow} size={20} aria-hidden />
            <p className={`${styles.progressHeroBlock} ${styles.progressHeroGoal}`}>
              <span className={styles.progressHeroLabel}>{PLAN_PROGRESS_OBJECTIVE_LABEL}</span>
              <span className={styles.progressHeroValue}>{cycle.objectiveLevel}</span>
            </p>
          </>
        )}
      </div>
      <div className={styles.progressHeroRail}>
        <PlanLevelRail current={cycle.targetLevel} />
      </div>
      <p className={styles.progressHeroCount}>{planProfileCountLabel(cycle)}</p>
    </section>
  );
}

/**
 * Un domaine et ce que le candidat y a démontré.
 *
 * **Les deux familles ne se lisent pas pareil, et le contrat l'impose** :
 * `paliers` est rempli en compréhension, `taches` en expression — jamais les
 * deux. Un domaine jamais mesuré n'a ni l'un ni l'autre : il dit alors ce qui
 * manque, et par quoi le mesurer.
 */
function ProgressDomainCard({
  domain,
  assessment,
  busy,
  onStart,
}: {
  domain: PlanDomainDto;
  assessment: PlanDomainAssessmentDto | undefined;
  busy: boolean;
  onStart: (assessment: PlanDomainAssessmentDto) => void;
}) {
  const titleId = `progress-${domain.epreuve}`;
  return (
    <section className={styles.panel} aria-labelledby={titleId}>
      <Link className={styles.progressCardHead} href={planDomainHref(domain.epreuve)}>
        <PlanDomainIcon
          epreuve={domain.epreuve}
          active={domain.evaluated && domain.priority === "FORTE"}
          small
        />
        <span className={styles.panelBody}>
          <span className={styles.panelTitle} id={titleId}>{planDomainLabel(domain.epreuve)}</span>
          <span className={styles.panelMeta}>{planDomainProgressLine(domain)}</span>
        </span>
        <PlanDomainPriorityPill priority={domain.priority} />
        <RowChevron />
      </Link>

      {(domain.paliers.length > 0 || domain.taches.length > 0) && (
        <ul className={styles.panelList}>
          {domain.paliers.map((palier) => (
            <ProgressLevelRow key={palier.skillId} palier={palier} domain={domain} />
          ))}
          {domain.taches.map((tache) => (
            <PlanTaskRow
              key={tache.taskCode}
              tache={tache}
              epreuve={domain.epreuve}
              title={SKILL_TASK_TITLE[tache.taskCode]}
            />
          ))}
        </ul>
      )}

      {!domain.evaluated && (
        <div className={styles.progressEmpty}>
          <p className={styles.cardText}>{PLAN_PROGRESS_DOMAIN_EMPTY}</p>
          {/* Pas de mesure servie ⇒ pas de bouton : on ne fabrique pas un
              parcours que le serveur n'a pas désigné. */}
          {assessment && (
            <button
              type="button"
              className={styles.primaryButton}
              disabled={busy}
              onClick={() => onStart(assessment)}
            >
              {busy ? PLAN_STARTING : planAssessmentCta(assessment)}
              <ChevronRight size={16} aria-hidden />
            </button>
          )}
          {assessment && (
            <p className={styles.progressEmptyMeta}>{planAssessmentMeta(assessment)}</p>
          )}
        </div>
      )}
    </section>
  );
}

/**
 * Un palier de compréhension : son rang, s'il bloque la suite, et son **état**.
 *
 * 🛑 **Jamais un pourcentage** — cf. la note de tête de ce fichier. Un palier
 * jamais mesuré n'a pas d'état : il le dit, il n'en emprunte pas un.
 */
function ProgressLevelRow({palier, domain}: {palier: PlanDomainLevelDto; domain: PlanDomainDto}) {
  return (
    <li>
      <Link className={styles.panelRow} href={planDomainHref(domain.epreuve)}>
        <span className={`${styles.levelBadge} ${palier.blocking ? styles.levelBadgeBlocking : ""}`}>
          {palier.niveau}
        </span>
        <span className={styles.panelBody}>
          <span className={styles.panelTitle}>{palier.skillCode}</span>
          <span className={styles.panelMeta}>{planLevelRowMeta(palier)}</span>
        </span>
        {palier.masteryState ? (
          <SkillMasteryPill state={palier.masteryState} />
        ) : (
          <span className={styles.progressUnknown}>{PLAN_PROGRESS_LEVEL_UNKNOWN}</span>
        )}
        <RowChevron />
      </Link>
    </li>
  );
}
