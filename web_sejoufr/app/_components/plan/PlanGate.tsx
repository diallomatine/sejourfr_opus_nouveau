"use client";

import {ArrowUp, Check, Compass, type LucideIcon} from "lucide-react";
import {useEffect, useState} from "react";
import {
  Card,
  Cta,
  NoteCard,
  Observation,
  Pad,
  Section,
  Stack,
  Top,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
  DIAGNOSTIC_GOAL_PREFIX,
  DIAGNOSTIC_LEVEL_EYEBROW,
  observationLines,
} from "@/app/_components/diagnostic/report-labels";
import {diagnosticApi} from "@/lib/api";
import {
  DIAGNOSTIC_RAPIDE_HREF,
  PLAN_GATE_RAPPORT_CTA,
  type PlanIndisponible,
} from "@/lib/preparation";
import {niveauCecrlShort, type DiagnosticResultDto, type ModulePreparation} from "@/lib/types";

/**
 * **Pourquoi ce plan n'existe pas encore**, et la seule porte qui le débloque.
 *
 * 🛑 Jamais un plan vide, jamais un plan bâti sur une mesure qui n'existe pas.
 * Le titre, le texte, le libellé et la destination viennent de
 * `planIndisponible` (`lib/preparation.ts`) — **la même autorité** que
 * l'Accueil et les Examens, pour que le candidat ne se voie pas proposer trois
 * choses différentes selon l'écran où il arrive. Aucune phrase n'est écrite
 * ici.
 *
 * 🛑 **Trois états, et c'est le SERVEUR qui dit lequel** (`prep.etape`) :
 * `DIAGNOSTIC_A_FAIRE` ouvre le diagnostic rapide, `ESTIMATION_FAITE` rappelle
 * ce que ce rapide a mesuré puis invite au diagnostic complet, `PLAN_PRET`
 * n'arrive jamais ici (l'appelant affiche le vrai Plan). Aucun front ne déduit
 * cet état d'un compteur ni d'un score.
 */
export function PlanGate({
  gate,
  kicker,
  prep,
  icon: Icon = Compass,
}: {
  gate: PlanIndisponible;
  kicker: string;
  /**
   * L'état servi du module affiché. Absent chez les appelants qui n'ont que
   * l'état du Plan (`LearningPlanView`, `CivicPlanPanel`) : la porte se réduit
   * alors à sa forme minimale, elle n'invente rien.
   */
  prep?: ModulePreparation | null;
  icon?: LucideIcon;
}) {
  const estimation = useEstimationRapide(prep);

  return (
    <>
      <Top kicker={kicker} title="Mon plan du jour" />
      <Section>
        <Pad>
          <Stack>
            <NoteCard icon={Icon} title={gate.titre} titleSize="lg">
              <p className={sejourStyles.sub}>{gate.texte}</p>
            </NoteCard>
            {/* 🛑 Pas de niveau estimé ⇒ pas de carte. Une production
                inexploitable n'a rien mesuré : on n'écrit ni « — » ni A1 à la
                place d'un verdict que personne n'a rendu (V040/V041/V042). */}
            {estimation?.niveau && (
              <Card>
                <p className={sejourStyles.label}>{DIAGNOSTIC_LEVEL_EYEBROW}</p>
                <p className={sejourStyles.level}>{niveauCecrlShort(estimation.niveau)}</p>
                {/* 🛑 L'objectif est servi (`cible`) ou absent : aucun front
                    n'écrit « B2 » pour un candidat sans démarche déclarée. */}
                {prep?.cible && (
                  <p className={sejourStyles.goalLine}>
                    {DIAGNOSTIC_GOAL_PREFIX} <span>{prep.cible}</span>
                  </p>
                )}
              </Card>
            )}
            {estimation?.observations.map((line) => (
              <Observation
                key={`${line.kicker}-${line.title}`}
                tone={line.tone}
                kicker={line.kicker}
                title={line.title}
                text={line.text ?? undefined}
                icon={line.tone === "ok" ? Check : ArrowUp}
              />
            ))}
            <Cta href={gate.href}>{gate.cta}</Cta>
            {estimation && (
              <Cta href={DIAGNOSTIC_RAPIDE_HREF} variant="line">
                {PLAN_GATE_RAPPORT_CTA}
              </Cta>
            )}
          </Stack>
        </Pad>
      </Section>
    </>
  );
}

/**
 * Ce que le diagnostic RAPIDE a déjà mesuré — lu, jamais recalculé.
 *
 * 🛑 On relit **la session que le serveur a désignée** (`prep.sessionId`), pas
 * « la session courante » : `preparation()` retient la dernière session close,
 * qui peut appartenir à une version antérieure du diagnostic — `current()`
 * répondrait alors `NOT_STARTED` et la porte perdrait l'estimation du candidat.
 *
 * 🛑 **Aucun repli en cas d'échec** : le bloc n'apparaît pas, le CTA reste. Un
 * rappel absent est un état normal ; une estimation inventée ne l'est pas.
 */
function useEstimationRapide(prep: ModulePreparation | null | undefined) {
  const sessionId = prep?.etape === "ESTIMATION_FAITE" ? prep.sessionId : null;
  /* Le résultat est retenu AVEC la session dont il vient : sans ce couple, une
     bascule de module rendrait une seconde l'estimation de l'autre parcours. */
  const [lu, setLu] = useState<{sessionId: string; result: DiagnosticResultDto | null} | null>(
    null,
  );

  useEffect(() => {
    if (!sessionId) return;
    let vivant = true;
    diagnosticApi
      .get(sessionId)
      .then((session) => {
        if (vivant) setLu({sessionId, result: session.result ?? null});
      })
      .catch(() => {
        // Le rappel disparaît, la porte reste : elle n'a jamais dépendu de lui.
      });
    return () => {
      vivant = false;
    };
  }, [sessionId]);

  if (!sessionId || lu?.sessionId !== sessionId || !lu.result) return null;
  return {
    // 🛑 `null` = inconnu : une production inexploitable n'a pas de niveau, et
    // on n'affiche jamais A1 à sa place (V040/V041/V042).
    niveau: lu.result.written?.levelEstimate ?? null,
    observations: observationLines(lu.result),
  };
}
