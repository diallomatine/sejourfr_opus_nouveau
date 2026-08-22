"use client";

import Link from "next/link";
import {ArrowRight, Clock3, FilePenLine, Lock, Mic, Trophy} from "lucide-react";
import {
  PLAN_MILESTONE_CTA,
  PLAN_MILESTONE_LOCK_NOTE,
  PLAN_MILESTONE_LOCKED_CTA,
  PLAN_MILESTONE_PILL,
  planMilestoneMeta,
  planMilestoneText,
  planMilestoneTitle,
} from "@/lib/diagnostic";
import type {PlanMilestoneExerciseDto} from "@/lib/types";
import {SKILL_PREMIUM_HREF, SkillLockBadge} from "@/app/_components/skill-ui/SkillLayout";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {usePlanExercise} from "./use-plan-exercise";
import styles from "./plan.module.css";

/**
 * Le **jalon** du Plan : un examen blanc que le serveur juge mérité.
 *
 * ⚠️ **Rien n'est décidé ici.** Quelle épreuve, quel slot, verrouillé ou non :
 * tout vient de `LearningPlanDto.milestone` (`PlanMilestoneSelector` côté
 * serveur). Le front n'apporte que la **phrase** — le serveur n'expose que des
 * faits — et le **chemin de démarrage**, qui est celui des écrans d'examen
 * blanc existants, réutilisé tel quel :
 *
 * - `EPREUVE_MOCK_EXAM` → `productionApi.startAttempt({exam: true, slotNumber})`
 *   puis la session de production, exactement comme `ProductionExams` ;
 * - `FULL_TCF_MOCK_EXAM` → `fullTcfExamApi.start(slotNumber)` puis le hub de
 *   progression, exactement comme `TcfFullExamBriefingSheet`.
 *
 * Aucune route n'est créée, aucun appel n'est réinventé.
 *
 * **Verrouillé, le jalon reste entier** : titre, motif, épreuve, slot et durée
 * s'affichent à l'identique, seule la destination du bouton change — le Plan
 * reste intégralement visible, seuls les accès sont fermés.
 */
export function PlanMilestoneCard({
  milestone,
  onPremiumClick,
}: {
  milestone: PlanMilestoneExerciseDto;
  /** Mesure de conversion du verrou, partagée avec les autres cadenas du Plan. */
  onPremiumClick: () => void;
}) {
  // La provenance suit le candidat jusqu'à la page d'achat.
  const premiumHref = useTrafficSourceHref(SKILL_PREMIUM_HREF);
  // Le démarrage vit dans le lanceur PARTAGÉ du Plan : deux copies auraient
  // fini par ouvrir deux slots différents pour le même jalon.
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();

  const full = milestone.kind === "FULL_TCF_MOCK_EXAM";
  const oral = milestone.epreuve === "TCF_EO";

  return (
    <section className={styles.today} aria-labelledby="milestone-title">
      <div className={styles.todayTop}>
        <div>
          <span className={`${styles.todayPill} ${styles.milestonePill}`}>{PLAN_MILESTONE_PILL}</span>
          {milestone.locked && <span className={styles.lockAside}><SkillLockBadge /></span>}
          <h3 id="milestone-title">{planMilestoneTitle(milestone)}</h3>
        </div>
        <span className={styles.todayDuration}>
          <Clock3 size={15} aria-hidden /> ≈ {milestone.estimatedMinutes} min
        </span>
      </div>

      <p className={styles.milestoneText}>{planMilestoneText(milestone)}</p>

      <div className={styles.todayTask}>
        <span className={styles.todayTaskIcon} aria-hidden>
          {full ? <Trophy size={17} /> : oral ? <Mic size={17} /> : <FilePenLine size={17} />}
        </span>
        <span>
          <b>{planMilestoneTitle(milestone)}</b>
          <small>{planMilestoneMeta(milestone)}</small>
        </span>
      </div>

      {milestone.locked ? (
        <>
          <Link
            className={`${styles.primaryButton} ${styles.todayCta}`}
            href={premiumHref}
            onClick={onPremiumClick}
          >
            <Lock size={16} aria-hidden /> {PLAN_MILESTONE_LOCKED_CTA}
          </Link>
          <p className={styles.lockNote}>{PLAN_MILESTONE_LOCK_NOTE}</p>
        </>
      ) : (
        <button
          type="button"
          className={`${styles.primaryButton} ${styles.todayCta}`}
          onClick={() => void start(milestone)}
          disabled={starting}
        >
          {starting ? "Démarrage…" : PLAN_MILESTONE_CTA} <ArrowRight size={17} aria-hidden />
        </button>
      )}

      {error && <p className={styles.milestoneError} role="alert">{error}</p>}

      <PaywallSheet ctaLocation="LOCKED_PLAN" screen="plan_jalon" open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </section>
  );
}
