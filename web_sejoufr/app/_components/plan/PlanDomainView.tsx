"use client";

import Link from "next/link";
import {useParams} from "next/navigation";
import {useEffect, useState} from "react";
import {ArrowLeft, ArrowRight, ChevronRight, RotateCcw, Sparkles} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  findAssessment,
  findDomain,
  levelLabel,
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_DOMAIN_SECTION,
  PLAN_DOMAIN_NOT_EVALUATED,
  PLAN_LOCKED_PRIORITY_LABEL,
  planActivePriorities,
  planAssessmentCta,
  planAssessmentMeta,
  planDomainFromSlug,
  planDomainLabel,
  planSkillHref,
  planSkillMeta,
} from "@/lib/plan-domain";
import {PlanBlur, PlanDomainIcon, PlanDomainPriorityPill, PlanNaturePill, PlanTaskRow} from "./PlanBits";
import {BlockHead, EmptyCard, PlanShell} from "./LearningPlanView";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";
import {
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type PlanDomainDto,
  type PlanDomainLevelDto,
} from "@/lib/types";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  RowChevron,
  SkillLockBadge,
  SkillMasteryPill,
  SKILL_PREMIUM_HREF,
} from "@/app/_components/skill-ui/SkillLayout";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import styles from "./plan.module.css";

/**
 * **La fiche d'un domaine du TCF** — CO, CE, EE ou EO.
 *
 * Elle répond à « où j'en suis sur cette épreuve, et qu'est-ce que j'y fais
 * maintenant ? ». Tout vient de `GET /api/me/plan` : le niveau, l'urgence, le
 * palier bloquant, la couverture des tâches, et par quoi mesurer le domaine
 * quand il ne l'a jamais été. **Aucune règle n'est rejouée ici.**
 *
 * Les deux familles ne se travaillent pas pareil, et le contrat l'impose :
 * - **compréhension** (CO / CE) : trois paliers, chacun avec sa compétence,
 *   qui se travaillent en **série ciblée** (`paliers` est rempli, `taches` est
 *   vide) ;
 * - **expression** (EE / EO) : trois tâches et leur couverture en compétences
 *   observées (`taches` est rempli, `paliers` est vide).
 *
 * 🛑 **Une série ciblée n'évalue pas le domaine** : elle fait progresser les
 * compétences, mais seul un examen blanc lui donne un niveau. La note du bas le
 * dit, et « Compléter mon profil » désigne le vrai parcours de mesure.
 */
export function PlanDomainView() {
  const params = useParams<{domaine: string}>();
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const epreuve = planDomainFromSlug(params?.domaine ?? "");

  useEffect(() => {
    if (authStatus === "loading" || !user) return;
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => { if (!cancelled) { setPlan(current); setError(null); } },
      (cause: unknown) => {
        if (!cancelled) {
          setError(cause instanceof ApiException ? cause.message : "Impossible de charger votre plan.");
        }
      },
    ).finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [authStatus, user]);

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return (
      <main className={styles.page} aria-busy="true" aria-label="Chargement du domaine">
        <div className={styles.skeletonHead} />
        <div className={styles.skeletonHero} />
      </main>
    );
  }

  if (!epreuve) {
    return (
      <PlanShell>
        <BackToPlan />
        <EmptyCard
          icon={<RotateCcw size={28} />}
          title="Domaine introuvable"
          text="Ce domaine n'existe pas. Revenez à votre plan pour choisir une épreuve."
        >
          <Link className={styles.primaryButton} href="/plan">Revenir à mon plan</Link>
        </EmptyCard>
      </PlanShell>
    );
  }

  const domain = plan ? findDomain(plan, epreuve) : undefined;
  if (!plan || !domain) {
    return (
      <PlanShell>
        <BackToPlan />
        <EmptyCard
          icon={<RotateCcw size={28} />}
          title="Ce domaine n'a pas pu être chargé"
          text={error ?? "Réessayez dans un instant."}
          role="alert"
        >
          <Link className={styles.primaryButton} href="/plan">Revenir à mon plan</Link>
        </EmptyCard>
      </PlanShell>
    );
  }

  return <DomainDetail plan={plan} domain={domain} />;
}

function BackToPlan() {
  return (
    <Link className={styles.back} href="/plan">
      <ArrowLeft size={17} aria-hidden /> Mon plan
    </Link>
  );
}

function DomainDetail({plan, domain}: {plan: LearningPlanDto; domain: PlanDomainDto}) {
  const assessment = findAssessment(plan, domain.epreuve);
  const {start: startAssessment, starting, error: assessmentError, paywallOpen, closePaywall} =
    usePlanAssessment();
  const objectif = plan.cycle.objectiveLevel;
  const priorities = planActivePriorities(plan).filter(
    (priority) => priority.section === PLAN_DOMAIN_SECTION[domain.epreuve],
  );

  return (
    <PlanShell>
      <div className={styles.narrow}>
        <BackToPlan />

        <header className={styles.header}>
          <p className={styles.eyebrow}>
            <PlanDomainIcon epreuve={domain.epreuve} small /> Domaine
          </p>
          <h1>{planDomainLabel(domain.epreuve)}</h1>
          <p>
            {objectif ? `Objectif ${objectif} · ` : ""}
            {domain.evaluated && domain.niveau
              ? `niveau estimé ${levelLabel(domain.niveau)}`
              : PLAN_DOMAIN_NOT_EVALUATED.toLowerCase()}
          </p>
        </header>

        <div className={styles.stack}>
          <section className={styles.domainHero}>
            <PlanDomainIcon
              epreuve={domain.epreuve}
              active={domain.evaluated && domain.priority === "FORTE"}
            />
            <div className={styles.domainHeroBody}>
              <p className={styles.domainHeroLevel}>
                {domain.evaluated && domain.niveau ? levelLabel(domain.niveau) : "À évaluer"}
              </p>
              <p className={styles.domainHeroMeta}>
                {domain.evaluated ? "niveau estimé" : "aucune donnée pour le moment"}
              </p>
            </div>
            <PlanDomainPriorityPill priority={domain.priority} />
          </section>

          {/* Jamais mesuré : on dit par quoi le mesurer, sans jamais présenter
              l'absence de donnée comme une faiblesse. */}
          {!domain.evaluated && assessment && (
            <section className={`${styles.card} ${styles.tint}`}>
              <h2 className={styles.cardTitle}>
                <Sparkles size={17} aria-hidden /> Comment compléter ce domaine ?
              </h2>
              <p className={styles.cardText}>
                Ce domaine n&apos;a encore aucun passage réel. {planAssessmentMeta(assessment)} lui
                donnera un niveau, et votre plan s&apos;ajustera aussitôt.
              </p>
              <button
                type="button"
                className={`${styles.primaryButton} ${styles.todayCta}`}
                disabled={starting === assessment.epreuve}
                onClick={() => void startAssessment(assessment)}
              >
                {starting === assessment.epreuve ? "Démarrage…" : planAssessmentCta(assessment)}
                <ArrowRight size={17} aria-hidden />
              </button>
              {assessmentError && <p className={styles.milestoneError} role="alert">{assessmentError}</p>}
            </section>
          )}

          {/* Compréhension : trois paliers, et le premier non consolidé est
              celui qui bloque les suivants. C'est une règle SERVEUR
              (`blocking`), jamais recalculée ici. */}
          {domain.paliers.length > 0 && (
            <section className={styles.panel} aria-labelledby="paliers-title">
              <div className={styles.panelHead}>
                <div>
                  <h2 id="paliers-title">Mes paliers</h2>
                  <p>
                    {domain.consolidatedLevel
                      ? `Consolidé jusqu'au ${domain.consolidatedLevel}`
                      : "Aucun palier consolidé pour l'instant"}
                    {domain.blockingLevel ? ` · le ${domain.blockingLevel} bloque la suite` : ""}
                  </p>
                </div>
              </div>
              <ul className={styles.panelList}>
                {domain.paliers.map((palier) => (
                  <LevelRow key={palier.skillId} palier={palier} />
                ))}
              </ul>
              <p className={styles.panelNote}>{PLAN_COMPLETE_PROFILE_NOTE}</p>
            </section>
          )}

          {/* Expression : les trois tâches et leur couverture. « 3 / 8
              observées » n'est PAS une note — une compétence non observée est
              une compétence que le candidat n'a pas encore eu l'occasion de
              montrer. Le dénominateur vient de la base. */}
          {domain.taches.length > 0 && (
            <section className={styles.panel} aria-labelledby="taches-title">
              <div className={styles.panelHead}>
                <div>
                  <h2 id="taches-title">Les 3 tâches de l&apos;épreuve</h2>
                  <p>Combien de compétences ont déjà été observées sur chacune.</p>
                </div>
              </div>
              <ul className={styles.panelList}>
                {domain.taches.map((tache) => (
                  <PlanTaskRow key={tache.taskCode} tache={tache} epreuve={domain.epreuve} />
                ))}
              </ul>
            </section>
          )}

          {priorities.length > 0 && (
            <section aria-labelledby="domain-priorities">
              <BlockHead
                title="Vos priorités sur ce domaine"
                text="Dans l'ordre décidé par votre plan."
                titleId="domain-priorities"
              />
              <ul className={styles.panelList}>
                {priorities.map((priority) => (
                  <DomainPriorityRow key={priority.skillId} priority={priority} />
                ))}
              </ul>
            </section>
          )}
        </div>

        <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
      </div>
    </PlanShell>
  );
}

/**
 * Une priorité du domaine — **exactement la même ligne que sur le Plan**, verrou
 * compris.
 *
 * 🛑 **C'est la MÊME liste** que « Mes priorités » : la montrer en clair ici
 * démentirait le flou posé là-bas. Le piège s'est déjà présenté plusieurs fois
 * dans ce chantier (la carte de tête du rapport de diagnostic, la modale
 * « Pourquoi cette séance ? » et sa jumelle mobile) — d'où la reprise du même
 * `PlanBlur`, du même libellé accessible et du même renvoi vers l'offre.
 *
 * La **nature** remplace l'état agrégé, comme sur le Plan : une compétence à
 * acquérir n'a aucun état, et n'affichait donc rien du tout.
 */
function DomainPriorityRow({priority}: {priority: LearningPlanPriorityDto}) {
  const premiumHref = useTrafficSourceHref(SKILL_PREMIUM_HREF);
  const locked = priority.locked;
  const text = (
    <>
      <span className={styles.panelTitle}>{priority.title}</span>
      <span className={styles.panelMeta}>{planSkillMeta(priority)}</span>
    </>
  );

  return (
    <li>
      <Link
        className={styles.panelRow}
        href={locked ? premiumHref : planSkillHref(priority, {planStep: true})}
      >
        <span className={styles.panelBody}>
          {locked ? (
            <>
              <span className={styles.srOnly}>{PLAN_LOCKED_PRIORITY_LABEL}</span>
              <PlanBlur>{text}</PlanBlur>
            </>
          ) : (
            text
          )}
        </span>
        {locked ? <SkillLockBadge /> : <PlanNaturePill nature={priority.nature} />}
        <RowChevron />
      </Link>
    </li>
  );
}

/**
 * Un palier de compréhension. Le clic **démarre une série ciblée** sur sa
 * compétence : `attemptApi.startTargetedSeries(skillId)`, puis le runner QCM
 * existant. Aucun second runner n'est créé.
 *
 * `PlanDomainLevelDto` ne porte **pas** de `locked` : c'est le serveur qui
 * tranche au démarrage (403 ⇒ paywall). On ne devine pas le verrou, on ne
 * masque rien à l'avance.
 */
function LevelRow({palier}: {palier: PlanDomainLevelDto}) {
  const {startSeries, starting, error, paywallOpen, closePaywall} = usePlanExercise();

  return (
    <li>
      <button
        type="button"
        className={styles.levelRow}
        disabled={starting}
        /* Aucun événement d'audience ici : `PLAN_RECOMMENDED_EXERCISE_STARTED`
           mesure l'exercice DÉSIGNÉ par le Plan, pas un palier choisi à la
           main sur une fiche de domaine — les deux dans le même compteur
           rendraient la mesure illisible. */
        onClick={() => void startSeries(palier.skillId)}
      >
        <span className={`${styles.levelBadge} ${palier.blocking ? styles.levelBadgeBlocking : ""}`}>
          {palier.niveau}
        </span>
        <span className={styles.panelBody}>
          <span className={styles.panelTitle}>
            {palier.skillCode}
            {palier.blocking && <span className={styles.levelFlag}>Palier bloquant</span>}
          </span>
          <span className={styles.panelMeta}>
            {starting ? "Démarrage…" : "Série ciblée de questions"}
          </span>
        </span>
        <SkillMasteryPill state={palier.masteryState} />
        <ChevronRight size={16} aria-hidden />
      </button>
      {error && <p className={styles.milestoneError} role="alert">{error}</p>}
      <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </li>
  );
}

