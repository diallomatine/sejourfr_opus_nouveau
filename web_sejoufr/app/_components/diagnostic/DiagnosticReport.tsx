"use client";

/**
 * **Le rapport du diagnostic RAPIDE TCF** (2026-10-04,
 * `docs/diagnostic/maquette-rapport-diagnostic-premium.html`, écran 1).
 *
 * Une seule production écrite a été observée : l'écran annonce une
 * *estimation*, la situe face à l'objectif, dit ce qu'il a vu — le point fort,
 * puis **les priorités du lot du Plan** (`planPriorities`, la seule autorité) —,
 * dit **ce qu'il n'a pas vu**, puis mène à la transition « Votre plan commence
 * ici ». Il ne pousse aucune offre : un constat mesuré se montre en clair,
 * l'offre vit dans le Plan.
 *
 * 🛑 **Aucun style local.** Tout l'habillage vient du kit partagé
 * `app/_components/sejour/` (miroir du kit Flutter).
 *
 * 🛑 **`null` = inconnu, jamais mauvais.** Une production inexploitable
 * (`NON_EVALUABLE`, le fait servi) n'a pas de niveau : « — » et la pastille
 * « Évaluation incomplète », sans situation, sans piste, sans phrase de
 * communication. Afficher A1 serait rendre un verdict que personne n'a rendu.
 *
 * Il est la page `/diagnostic` quand la session est close, et la relecture
 * `/diagnostic/rapport/[sessionId]` : un seul composant de rapport.
 * Miroir mobile : `DiagnosticResultView`.
 */

import type {ReactNode} from "react";
import {ArrowUp, Check, Info} from "lucide-react";
import {
  Card,
  Cta,
  LevelGoal,
  LevelTrack,
  NoteCard,
  Observation,
  Pad,
  Pill,
  SejourApp,
  Section,
  Stack,
  TextLink,
  Top,
  sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {planHref} from "@/lib/module-switch";
import {levelTrackPosition} from "@/lib/tcf-diagnostic";
import {
  DIAGNOSTIC_GOAL_LABEL,
  DIAGNOSTIC_INCOMPLETE_TAG,
  DIAGNOSTIC_LEVEL_EYEBROW,
  DIAGNOSTIC_LEVEL_UNKNOWN,
  DIAGNOSTIC_NOTE_TEXT,
  DIAGNOSTIC_NOTE_TITLE,
  DIAGNOSTIC_OBSERVE_TITLE,
  DIAGNOSTIC_REPORT_KICKER,
  DIAGNOSTIC_REPORT_PLAN_CTA,
  DIAGNOSTIC_REPORT_REPONSE_LINK,
  DIAGNOSTIC_REPORT_TITLE,
  DIAGNOSTIC_TRACK_CAPTION,
  DIAGNOSTIC_TRACK_GOAL,
  diagnosticReponseHref,
  diagnosticSituationPhrase,
  diagnosticSynthese,
  diagnosticTrackLevels,
  diagnosticTransitionHref,
  observationLines,
} from "@/lib/diagnostic-rapport";
import {niveauCecrlShort, type DiagnosticResultDto} from "@/lib/types";

export function DiagnosticReport({
  diagnostic,
  notice,
  backTo = null,
}: {
  diagnostic: {sessionId: string | null; result: DiagnosticResultDto | null};
  notice?: ReactNode;
  /**
   * Le retour de l'en-tête. `null` ⇒ aucun : le rapport est alors un écran
   * racine, la barre du haut garde son menu. L'hôte ne le pose que si le
   * rapport a été ouvert depuis un autre écran de l'app — jamais au sortir du
   * tunnel invité, où « retour » ramènerait à l'écran de compte.
   */
  backTo?: string | null;
}) {
  const result = diagnostic.result;
  const written = result?.written ?? null;
  // 🛑 Seule la valeur `NON_EVALUABLE` **explicite** se lit « rendue, rien à
  // observer » : l'absence du champ, elle, ne veut rien dire (backend ancien).
  const inexploitable = written?.evaluabilite === "NON_EVALUABLE";
  const niveau = inexploitable ? null : written?.levelEstimate ?? null;
  const objectif = result?.objectiveLevel ?? null;
  const situation = inexploitable
    ? null
    : diagnosticSituationPhrase(result?.situationObjectif, objectif);
  const track = inexploitable ? null : levelTrackPosition(niveau, objectif);
  const synthese = diagnosticSynthese(result, inexploitable);
  const observations = observationLines(result);
  const sessionId = diagnostic.sessionId;

  return (
    /* 🛑 `report` : 980 px de conteneur, 720 px de texte. La grille des
       observations prend la largeur, la carte de niveau garde sa colonne. */
    <SejourApp report>
      {notice}
      <Top
        backTo={backTo ?? undefined}
        kicker={DIAGNOSTIC_REPORT_KICKER}
        title={DIAGNOSTIC_REPORT_TITLE}
      />

      {/* 1 — le niveau face à l'objectif. L'élément dominant de l'écran. */}
      <Pad>
        <Card variant="hero">
          <p className={styles.label}>{DIAGNOSTIC_LEVEL_EYEBROW}</p>
          <LevelGoal
            level={niveau ? niveauCecrlShort(niveau) : DIAGNOSTIC_LEVEL_UNKNOWN}
            goalLabel={DIAGNOSTIC_GOAL_LABEL}
            goal={objectif}
          />
          {inexploitable && (
            <div className={styles.insight}>
              <Pill label={DIAGNOSTIC_INCOMPLETE_TAG} tone="muted" />
            </div>
          )}
          {situation && (
            <div className={styles.insight}>
              <Card variant="soft">
                <span className={styles.emphasis}>{situation}</span>
              </Card>
            </div>
          )}
          {/* Piste absente quand un palier manque ou sort de l'échelle :
              mieux vaut rien qu'un candidat rabattu sur un palier qui n'est
              pas le sien. Jamais de pourcentage. */}
          {track && (
            <LevelTrack
              levels={diagnosticTrackLevels(track)}
              currentIndex={track.currentIndex}
              goalIndex={track.goalIndex}
              youLabel=""
              goalLabel={DIAGNOSTIC_TRACK_GOAL}
              caption={DIAGNOSTIC_TRACK_CAPTION}
            />
          )}
          {synthese && <p className={styles.insight}>{synthese}</p>}
        </Card>
      </Pad>

      {/* 2 — ce que nous avons observé : le point fort, puis TOUTES les
          priorités du lot du Plan. Absent quand rien n'est servi. */}
      {observations.length > 0 && (
        <Section title={DIAGNOSTIC_OBSERVE_TITLE}>
          <Pad>
            <Stack className={styles.deskGrid}>
              {observations.map((line) => (
                <Observation
                  key={`${line.kicker}-${line.title}`}
                  tone={line.tone}
                  kicker={line.kicker}
                  title={line.title}
                  text={line.text ?? undefined}
                  icon={line.tone === "ok" ? Check : ArrowUp}
                />
              ))}
            </Stack>
          </Pad>
        </Section>
      )}

      {/* 3 — l'encart d'honnêteté : le rapide n'observe qu'un écrit. */}
      <Section>
        <Pad>
          <Stack>
            <NoteCard variant="soft" icon={Info} title={DIAGNOSTIC_NOTE_TITLE}>
              <p className={styles.insight}>{DIAGNOSTIC_NOTE_TEXT}</p>
            </NoteCard>
            {/* 4 — la suite : la transition vers le Plan. Sans identifiant de
                session (jamais en pratique), on rejoint le Plan directement. */}
            <div>
              <Cta href={sessionId ? diagnosticTransitionHref(sessionId) : planHref("TCF")}>
                {DIAGNOSTIC_REPORT_PLAN_CTA}
              </Cta>
              {sessionId && (
                <TextLink href={diagnosticReponseHref(sessionId)}>
                  {DIAGNOSTIC_REPORT_REPONSE_LINK}
                </TextLink>
              )}
            </div>
          </Stack>
        </Pad>
      </Section>
    </SejourApp>
  );
}
