"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useState} from "react";
import {ArrowRight, Clock3, FilePenLine, Lock, Mic, Trophy} from "lucide-react";
import {fullTcfExamApi, productionApi} from "@/lib/api";
import {
  PLAN_MILESTONE_CTA,
  PLAN_MILESTONE_LOCK_NOTE,
  PLAN_MILESTONE_LOCKED_CTA,
  PLAN_MILESTONE_PILL,
  planMilestoneMeta,
  planMilestoneText,
  planMilestoneTitle,
} from "@/lib/diagnostic";
import {handleStartFailure} from "@/lib/start-failure";
import type {PlanMilestoneExerciseDto} from "@/lib/types";
import {EE_CONFIG, EO_CONFIG} from "@/app/_components/production/config";
import {SKILL_PREMIUM_HREF, SkillLockBadge} from "@/app/_components/skill-ui/SkillLayout";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
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
  const router = useRouter();
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const full = milestone.kind === "FULL_TCF_MOCK_EXAM";
  const oral = milestone.epreuve === "TCF_EO";

  async function launch() {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      if (full) {
        const exam = await fullTcfExamApi.start(milestone.slotNumber);
        router.push(`/examens-blancs/tcf/${exam.id}`);
        return;
      }
      const config = oral ? EO_CONFIG : EE_CONFIG;
      const attempt = await productionApi.startAttempt({
        module: "TCF",
        epreuve: config.epreuve,
        exam: true,
        slotNumber: milestone.slotNumber,
      });
      router.push(`${config.base}/session/${attempt.id}`);
    } catch (cause) {
      // Le 403 est un refus attendu (verrou périmé côté client), pas une panne :
      // il ouvre l'offre, comme partout ailleurs sur les démarrages d'examen.
      handleStartFailure(cause, {
        onPaywall: () => setPaywallOpen(true),
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen blanc.",
      });
      setStarting(false);
    }
  }

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
            href={SKILL_PREMIUM_HREF}
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
          onClick={() => void launch()}
          disabled={starting}
        >
          {starting ? "Démarrage…" : PLAN_MILESTONE_CTA} <ArrowRight size={17} aria-hidden />
        </button>
      )}

      {error && <p className={styles.milestoneError} role="alert">{error}</p>}

      <PaywallSheet
        open={paywallOpen}
        onClose={() => {
          setPaywallOpen(false);
          setStarting(false);
        }}
        module="INTEGRAL"
      />
    </section>
  );
}
