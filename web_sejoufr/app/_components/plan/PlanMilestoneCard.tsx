"use client";

import {Clock3, FilePenLine, Lock, Mic, Trophy} from "lucide-react";
import {track} from "@/lib/analytics";
import {
  PLAN_MILESTONE_CTA,
  PLAN_MILESTONE_LOCK_NOTE,
  PLAN_MILESTONE_LOCKED_CTA,
  PLAN_MILESTONE_PILL,
  PLAN_MILESTONE_SECTION_TEXT,
  PLAN_MILESTONE_SECTION_TITLE,
  planMilestoneMeta,
  planMilestoneText,
  planMilestoneTitle,
} from "@/lib/diagnostic";
import type {PlanMilestoneExerciseDto} from "@/lib/types";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {SKILL_PREMIUM_HREF} from "@/app/_components/skill-ui/SkillLayout";
import {Cta, NowCard, Pad, Section, sejourStyles} from "@/app/_components/sejour/SejourKit";
import {usePlanExercise} from "./use-plan-exercise";

/**
 * Le **jalon** du Plan : un examen blanc que le serveur juge mérité.
 *
 * ⚠️ **Rien n'est décidé ici.** Quelle épreuve, quel slot, verrouillé ou non :
 * tout vient de `LearningPlanDto.milestone` (`PlanMilestoneSelector` côté
 * serveur). Le front n'apporte que la **phrase** et le **chemin de démarrage**,
 * qui est celui des écrans d'examen blanc existants (`usePlanExercise`).
 *
 * **Verrouillé, le jalon reste entier** : titre, motif, slot et durée
 * s'affichent à l'identique, seule la destination du bouton change — le Plan
 * reste lisible, seuls les accès sont fermés.
 *
 * ⚠️ **Hors maquette, conservé** : aucun bloc de la maquette ne dit au candidat
 * qu'il est prêt pour un examen blanc, et c'est l'information la plus haute du
 * parcours.
 */
export function PlanMilestoneCard({milestone}: {milestone: PlanMilestoneExerciseDto}) {
  const premiumHref = useTrafficSourceHref(SKILL_PREMIUM_HREF);
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();

  const full = milestone.kind === "FULL_TCF_MOCK_EXAM";
  const oral = milestone.epreuve === "TCF_EO";

  return (
    <Section title={PLAN_MILESTONE_SECTION_TITLE}>
      <Pad>
        <NowCard
          icon={full ? Trophy : oral ? Mic : FilePenLine}
          title={planMilestoneTitle(milestone)}
          subtitle={PLAN_MILESTONE_SECTION_TEXT}
          badge={PLAN_MILESTONE_PILL}
          objectiveLabel="Pourquoi maintenant"
          objective={planMilestoneText(milestone)}
          meta={[{icon: Clock3, label: planMilestoneMeta(milestone)}]}
        >
          {milestone.locked ? (
            <Cta
              href={premiumHref}
              onClick={() => track("PREMIUM_CTA_CLICKED", {ctaLocation: "LOCKED_PLAN", screen: "plan_jalon"})}
              caption={PLAN_MILESTONE_LOCK_NOTE}
            >
              <Lock size={16} aria-hidden /> {PLAN_MILESTONE_LOCKED_CTA}
            </Cta>
          ) : (
            <Cta onClick={() => void start(milestone)} disabled={starting}>
              {starting ? "Démarrage…" : PLAN_MILESTONE_CTA}
            </Cta>
          )}
        </NowCard>
        {error && <p className={sejourStyles.tiny} role="alert">{error}</p>}
      </Pad>
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen="plan_jalon"
        module="INTEGRAL"
        open={paywallOpen}
        onClose={closePaywall}
      />
    </Section>
  );
}
