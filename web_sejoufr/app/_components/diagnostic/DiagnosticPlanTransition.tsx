"use client";

/**
 * **La transition « Votre plan commence ici »** (2026-10-04,
 * `docs/diagnostic/maquette-rapport-diagnostic-premium.html`, écran 2) —
 * `/diagnostic/rapport/[sessionId]/plan`, ouverte par « Découvrir mon plan ».
 *
 * Elle dit ce que le diagnostic devient dans le Plan : **les priorités du lot**
 * (`result.planPriorities`, dans l'ordre servi, sans plafond), l'état des
 * quatre épreuves (`plan.domaines[].evaluated`, servi par `GET /api/me/plan`)
 * et l'étape courante du parcours (`journey.current`, `GET /api/me/plan/journey`).
 * 🛑 Rien n'y est trié ni recalculé ; une lecture en échec retire son bloc,
 * jamais l'écran.
 *
 * 🛑 **Aucun style local** : briques du kit. Miroir mobile :
 * `DiagnosticPlanTransitionScreen`.
 */

import {useEffect, useState} from "react";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {
  Badge,
  Card,
  Cta,
  DoneHero,
  EpreuveTiles,
  MicroNote,
  NextStepCard,
  NumberedSteps,
  Pad,
  PanelHead,
  SejourApp,
  Section,
  Stack,
  TextLink,
  sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {journeyApi, learningPlanApi} from "@/lib/api";
import {planHref} from "@/lib/module-switch";
import {diagnosticRapportHref} from "@/lib/preparation";
import {
  DIAGNOSTIC_BACK_TO_REPORT,
  DIAGNOSTIC_BRIDGE_TEXT,
  DIAGNOSTIC_BRIDGE_TITLE,
  DIAGNOSTIC_NEXT_STEP_EYEBROW,
  DIAGNOSTIC_NEXT_STEP_TEXT,
  DIAGNOSTIC_PRIORITIES_SUB,
  DIAGNOSTIC_TRANSITION_KICKER,
  DIAGNOSTIC_TRANSITION_PLAN_CTA,
  DIAGNOSTIC_TRANSITION_TITLE,
  diagnosticEpreuveTiles,
  diagnosticNextStepTitle,
  diagnosticPrioritiesNote,
  diagnosticPrioritiesPill,
  diagnosticPrioritiesTitle,
  diagnosticTransitionLead,
} from "@/lib/diagnostic-rapport";
import type {DiagnosticResultDto, JourneyDto, LearningPlanDto} from "@/lib/types";

/** Une lecture du Plan : en cours, arrivée, ou en échec (`null`). */
type Lecture<T> = {pending: true} | {pending: false; value: T | null};

const PENDING = {pending: true} as const;

export function DiagnosticPlanTransition({
  sessionId,
  result,
}: {
  sessionId: string;
  result: DiagnosticResultDto | null;
}) {
  const [plan, setPlan] = useState<Lecture<LearningPlanDto>>(PENDING);
  const [journey, setJourney] = useState<Lecture<JourneyDto>>(PENDING);

  /* Lectures FRAÎCHES : on sort du diagnostic, le cache dirait encore « aucune
     épreuve mesurée » et pourrait ignorer le parcours qui vient d'être amorcé. */
  useEffect(() => {
    let annule = false;
    learningPlanApi.get().then(
      (value) => !annule && setPlan({pending: false, value}),
      () => !annule && setPlan({pending: false, value: null}),
    );
    journeyApi.get("TCF").then(
      (value) => !annule && setJourney({pending: false, value}),
      () => !annule && setJourney({pending: false, value: null}),
    );
    return () => {
      annule = true;
    };
  }, []);

  const objectif = result?.objectiveLevel ?? null;
  const priorites = result?.planPriorities ?? [];
  const pill = diagnosticPrioritiesPill(priorites);
  const note = diagnosticPrioritiesNote(priorites);
  const rapportHref = diagnosticRapportHref(sessionId);
  const nextTitle = journey.pending ? null : diagnosticNextStepTitle(journey.value);
  /* Écran poussé : la flèche de la barre du haut remonte au rapport. */
  useAppBarBack({fallbackHref: rapportHref});

  return (
    <SejourApp report>
      <DoneHero
        kicker={DIAGNOSTIC_TRANSITION_KICKER}
        title={DIAGNOSTIC_TRANSITION_TITLE}
        text={diagnosticTransitionLead(objectif)}
      />

      <Section>
        <Pad>
          <Stack>
            {/* 1 — les priorités du lot, numérotées par leur rang servi. */}
            {priorites.length > 0 && (
              <Card>
                {pill && <Badge>{pill}</Badge>}
                <PanelHead
                  title={diagnosticPrioritiesTitle(priorites.length)}
                  sub={DIAGNOSTIC_PRIORITIES_SUB}
                />
                <NumberedSteps
                  steps={priorites.map((p) => ({
                    number: p.rank,
                    title: p.skillTitle,
                    text: p.generalCriterion || null,
                  }))}
                />
                {note && <MicroNote>{note}</MicroNote>}
              </Card>
            )}

            {/* 2 — le pont vers le niveau réel : les quatre épreuves et leur
                état servi. Le Plan illisible ⇒ la phrase reste, sans tuiles. */}
            <Card variant="warn">
              <PanelHead title={DIAGNOSTIC_BRIDGE_TITLE} />
              <p className={styles.tiny}>{DIAGNOSTIC_BRIDGE_TEXT}</p>
              {/* Plan pas (encore) lu ⇒ les tuiles sans état : `null` = inconnu. */}
              <EpreuveTiles
                tiles={diagnosticEpreuveTiles(plan.pending ? null : plan.value?.domaines ?? null)}
              />
            </Card>

            {/* 3 — l'étape courante, nommée comme le Plan la nomme. */}
            {nextTitle ? (
              <NextStepCard
                eyebrow={DIAGNOSTIC_NEXT_STEP_EYEBROW}
                title={nextTitle}
                text={DIAGNOSTIC_NEXT_STEP_TEXT}
                facts={[]}
              />
            ) : null}

            <div>
              <Cta href={planHref("TCF")}>{DIAGNOSTIC_TRANSITION_PLAN_CTA}</Cta>
              <TextLink href={rapportHref}>{DIAGNOSTIC_BACK_TO_REPORT}</TextLink>
            </div>
          </Stack>
        </Pad>
      </Section>
    </SejourApp>
  );
}
