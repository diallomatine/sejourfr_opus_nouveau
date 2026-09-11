"use client";

/**
 * **Le résultat du diagnostic RAPIDE TCF.**
 *
 * Une seule production écrite a été observée : l'écran annonce une
 * *estimation*, dit ce qu'il a vu, dit **ce qu'il n'a pas vu**, et conduit au
 * diagnostic complet. Il ne pousse aucun abonnement — le candidat n'a pas
 * encore ses quatre niveaux sous les yeux, et un plan vendu sur un seul écrit
 * serait vendu à l'aveugle.
 *
 * 🛑 **Aucun style local.** Tout l'habillage vient du kit partagé
 * `app/_components/sejour/` (miroir du kit Flutter). Un motif qui manque
 * s'ajoute là-bas, jamais ici.
 *
 * 🛑 **`null` = inconnu, jamais mauvais.** Une production inexploitable
 * (`NON_EVALUABLE`) n'a pas de niveau : on écrit « — » et on dit ce qui manque.
 * Afficher A1 serait rendre un verdict que personne n'a rendu (V040/V041/V042).
 */

import type {ReactNode} from "react";
import {ArrowUp, Check, Info} from "lucide-react";
import {
  Card,
  CheckList,
  Cta,
  ExamRow,
  LevelTrack,
  NoteCard,
  Observation,
  Pad,
  SejourApp,
  Section,
  Stack,
  Top,
  sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {TCF_DIAGNOSTIC_HUB_HREF, levelTrackPosition} from "@/lib/tcf-diagnostic";
import {
  DIAGNOSTIC_COMPLET_BENEFITS,
  DIAGNOSTIC_COMPLET_CTA,
  DIAGNOSTIC_COMPLET_EPREUVES,
  DIAGNOSTIC_COMPLET_NOTE,
  DIAGNOSTIC_COMPLET_PROMISE,
  DIAGNOSTIC_COMPLET_TITLE,
  DIAGNOSTIC_GOAL_PREFIX,
  DIAGNOSTIC_INCOMPLETE_TEXT,
  DIAGNOSTIC_LEVEL_EYEBROW,
  DIAGNOSTIC_LEVEL_UNKNOWN,
  DIAGNOSTIC_OBJECTIVE_UNKNOWN,
  DIAGNOSTIC_OBSERVE_TITLE,
  DIAGNOSTIC_REPORT_BACK_HREF,
  DIAGNOSTIC_REPORT_KICKER,
  DIAGNOSTIC_REPORT_TITLE,
  DIAGNOSTIC_TRANSITION_EMPHASIS,
  DIAGNOSTIC_TRANSITION_TEXT,
  DIAGNOSTIC_TRANSITION_TITLE,
  observationLines,
} from "./report-labels";
import {niveauCecrlShort, type DiagnosticResultDto} from "@/lib/types";

/* ------------------------------------------------------------------- écran */

export function DiagnosticReport({
  diagnostic,
  targetLevel,
  notice,
}: {
  diagnostic: {result: DiagnosticResultDto | null};
  /** Palier visé, servi par `/api/auth/me`. `null` = démarche non déclarée. */
  targetLevel: string | null;
  notice?: ReactNode;
}) {
  const result = diagnostic.result;
  const written = result?.written ?? null;
  // 🛑 Seule la valeur `NON_EVALUABLE` **explicite** se lit « rendue, rien à
  // observer » : l'absence du champ, elle, ne veut rien dire (backend ancien).
  const inexploitable = written?.evaluabilite === "NON_EVALUABLE";
  const niveau = written?.levelEstimate ?? null;
  const analyse = inexploitable ? DIAGNOSTIC_INCOMPLETE_TEXT : written?.summary ?? null;
  const track = levelTrackPosition(niveau, targetLevel);
  const observations = observationLines(result);

  return (
    <SejourApp>
      {notice}
      <Top
        backTo={DIAGNOSTIC_REPORT_BACK_HREF}
        kicker={DIAGNOSTIC_REPORT_KICKER}
        title={DIAGNOSTIC_REPORT_TITLE}
      />

      {/* 1 — le niveau. L'élément dominant de l'écran. */}
      <Pad>
        <Card variant="hero">
          <p className={styles.label}>{DIAGNOSTIC_LEVEL_EYEBROW}</p>
          <p className={styles.level}>{niveau ? niveauCecrlShort(niveau) : DIAGNOSTIC_LEVEL_UNKNOWN}</p>
          <p className={styles.goalLine}>
            {DIAGNOSTIC_GOAL_PREFIX} <span>{targetLevel ?? DIAGNOSTIC_OBJECTIVE_UNKNOWN}</span>
          </p>
          {/* Piste absente quand un palier sort de l'échelle affichée : mieux
              vaut rien qu'un candidat rabattu sur un palier qui n'est pas le sien. */}
          {track && (
            <LevelTrack
              levels={[...track.levels]}
              currentIndex={track.currentIndex}
              goalIndex={track.goalIndex}
            />
          )}
          {analyse && <p className={styles.insight}>{analyse}</p>}
        </Card>
      </Pad>

      {/* 2 — ce que nous avons observé. Absent quand le serveur n'a rien
          classé : un bloc vide ne se remplit pas. */}
      {observations.length > 0 && (
        <Section title={DIAGNOSTIC_OBSERVE_TITLE}>
          <Pad>
            <Stack>
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

      {/* 3 — la transition. Ce n'est pas décoratif, c'est une obligation
          d'honnêteté : le diagnostic rapide n'observe qu'un écrit. */}
      <Section>
        <Pad>
          <NoteCard variant="soft" icon={Info} title={DIAGNOSTIC_TRANSITION_TITLE}>
            <p className={styles.insight}>{DIAGNOSTIC_TRANSITION_TEXT}</p>
            <span className={styles.emphasis}>{DIAGNOSTIC_TRANSITION_EMPHASIS}</span>
          </NoteCard>
        </Pad>
      </Section>

      {/* 4 — le diagnostic complet, seule suite proposée par cet écran. */}
      <Section title={DIAGNOSTIC_COMPLET_TITLE}>
        <Pad>
          <Stack>
            {DIAGNOSTIC_COMPLET_EPREUVES.map((epreuve) => (
              <ExamRow key={epreuve.label} icon={epreuve.icon} title={epreuve.label} />
            ))}
            <Card>
              <p className={styles.label}>{DIAGNOSTIC_COMPLET_PROMISE}</p>
              <CheckList items={DIAGNOSTIC_COMPLET_BENEFITS} />
            </Card>
            <Cta href={TCF_DIAGNOSTIC_HUB_HREF} caption={DIAGNOSTIC_COMPLET_NOTE}>
              {DIAGNOSTIC_COMPLET_CTA}
            </Cta>
          </Stack>
        </Pad>
      </Section>
    </SejourApp>
  );
}
