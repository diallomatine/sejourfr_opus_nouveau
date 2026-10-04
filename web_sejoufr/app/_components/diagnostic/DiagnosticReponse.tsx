"use client";

/**
 * **« Revoir ma réponse »** — `/diagnostic/rapport/[sessionId]/reponse`
 * (2026-10-04). Le sujet (`written.instruction`, servi par la session) et le
 * texte rendu (`texteSoumis` de `GET /api/production-submissions/{id}`, lu au
 * propriétaire). Lecture seule : rien ne s'y modifie, rien ne s'y relance.
 *
 * 🛑 **Aucun style local** : briques du kit, plus la mise en forme partagée de
 * la consigne (`DiagnosticConsigne`). Miroir mobile : `DiagnosticReponseScreen`.
 */

import {Fragment, useEffect, useState} from "react";
import {
  BlockError,
  BlockSkeleton,
  Card,
  Pad,
  PanelHead,
  SejourApp,
  Section,
  Stack,
  TextLink,
  Top,
  sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {productionApi} from "@/lib/api";
import {countEeWords} from "@/lib/ee-word-bounds";
import {diagnosticRapportHref} from "@/lib/preparation";
import {
  DIAGNOSTIC_BACK_TO_REPORT,
  DIAGNOSTIC_REPONSE_ERROR,
  DIAGNOSTIC_REPONSE_KICKER,
  DIAGNOSTIC_REPONSE_SUBJECT,
  DIAGNOSTIC_REPONSE_TEXT_TITLE,
  DIAGNOSTIC_REPONSE_TITLE,
  diagnosticReponseWords,
} from "@/lib/diagnostic-rapport";
import type {DiagnosticExerciseDto} from "@/lib/types";
import {DiagnosticConsigne} from "./DiagnosticConsigne";

type Etat =
  | {kind: "loading"}
  | {kind: "error"}
  | {kind: "ready"; texte: string | null};

export function DiagnosticReponse({
  sessionId,
  written,
}: {
  sessionId: string;
  written: DiagnosticExerciseDto | null;
}) {
  const submissionId = written?.submissionId ?? null;
  const [etat, setEtat] = useState<Etat>(
    submissionId ? {kind: "loading"} : {kind: "ready", texte: null},
  );

  /* L'état ne se pose qu'à l'arrivée de la réponse (l'état de départ est déjà
     « en cours ») ; seule la relance repasse par « en cours ». */
  const [essai, setEssai] = useState(0);
  useEffect(() => {
    if (!submissionId) return;
    let annule = false;
    productionApi.getSubmission(submissionId).then(
      (submission) => !annule && setEtat({kind: "ready", texte: submission.texteSoumis}),
      () => !annule && setEtat({kind: "error"}),
    );
    return () => {
      annule = true;
    };
  }, [submissionId, essai]);

  const relancer = () => {
    setEtat({kind: "loading"});
    setEssai((n) => n + 1);
  };

  const rapportHref = diagnosticRapportHref(sessionId);

  return (
    <SejourApp report>
      <Top
        backTo={rapportHref}
        kicker={DIAGNOSTIC_REPONSE_KICKER}
        title={DIAGNOSTIC_REPONSE_TITLE}
      />
      <Section>
        <Pad>
          <Stack>
            {written?.instruction ? (
              <Card>
                <PanelHead title={DIAGNOSTIC_REPONSE_SUBJECT} />
                <DiagnosticConsigne text={written.instruction} />
              </Card>
            ) : null}

            {etat.kind === "loading" ? (
              <BlockSkeleton height={180} />
            ) : etat.kind === "error" ? (
              <BlockError
                message={DIAGNOSTIC_REPONSE_ERROR}
                onRetry={relancer}
              />
            ) : etat.texte?.trim() ? (
              <Card>
                <PanelHead
                  title={DIAGNOSTIC_REPONSE_TEXT_TITLE}
                  sub={diagnosticReponseWords(countEeWords(etat.texte))}
                />
                {/* Les retours à la ligne du candidat sont conservés, sans CSS
                    d'écran : une ligne, un saut. */}
                <p className={styles.insight}>
                  {etat.texte.split("\n").map((ligne, index) => (
                    <Fragment key={index}>
                      {index > 0 && <br />}
                      {ligne}
                    </Fragment>
                  ))}
                </p>
              </Card>
            ) : (
              <Card>
                <PanelHead title={DIAGNOSTIC_REPONSE_TEXT_TITLE} />
                <p className={styles.tiny}>{DIAGNOSTIC_REPONSE_ERROR}</p>
              </Card>
            )}

            <TextLink href={rapportHref}>{DIAGNOSTIC_BACK_TO_REPORT}</TextLink>
          </Stack>
        </Pad>
      </Section>
    </SejourApp>
  );
}
