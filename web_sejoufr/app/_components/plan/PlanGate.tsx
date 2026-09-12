"use client";

import {Compass, type LucideIcon} from "lucide-react";
import {useEffect, useState} from "react";
import {Cta, NoteCard, Pad, Section, Stack, Top, sejourStyles} from "@/app/_components/sejour/SejourKit";
import {DiagnosticReport} from "@/app/_components/diagnostic/DiagnosticReport";
import {diagnosticApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import type {PlanIndisponible} from "@/lib/preparation";
import type {DiagnosticResultDto, ModulePreparation} from "@/lib/types";

/**
 * **Pourquoi ce plan n'existe pas encore**, et la seule porte qui le débloque.
 *
 * 🛑 Jamais un plan vide, jamais un plan bâti sur une mesure qui n'existe pas.
 * Le titre, le texte, le libellé et la destination viennent de
 * `planIndisponible` (`lib/preparation.ts`) — **la même autorité** que
 * l'Accueil et les Examens, pour que le candidat ne se voie pas proposer trois
 * choses différentes selon l'écran où il arrive. Aucune phrase n'est écrite
 * ici, et **aucun état n'est déduit d'un compteur** : l'étape, sa phrase et son
 * geste arrivent servis.
 *
 * 🛑 **Dès que le diagnostic RAPIDE est fait et tant que le Plan n'est pas
 * prêt, cette porte affiche SON RAPPORT** (arbitrage du propriétaire). Le
 * déclencheur n'est pas une étape mais un **fait servi** :
 * `prep.estimationSessionId`, l'identifiant de la session rapide close, servi à
 * **toutes** les étapes. Il couvre donc aussi bien « rapide fait, complet pas
 * commencé » que « complet entamé, 0 à 3 épreuves sur 4 » — c'est le second cas
 * qui manquait, parce que l'étape y bascule sur `DIAGNOSTIC_EN_COURS` et que
 * `sessionId` y désigne le **complet**. Le seul état sans rapport est celui où
 * aucun rapide n'a été clos : il n'y a rien à montrer.
 *
 * 🛑 **Le rapport est le COMPOSANT DE `/diagnostic`, encastré** — pas un résumé
 * écrit ici : deux lectures du même diagnostic auraient fini par en dire deux
 * choses. Et **la porte garde le geste de fin** (`closingCta={false}`) : sa
 * phrase dépend de l'étape servie, alors que le bouton du rapport dit toujours
 * « Faire le diagnostic complet » — un contresens une fois le complet entamé,
 * où l'étape sert « Continuer le diagnostic ».
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
  const {user} = useAuth();
  const rapide = useDiagnosticRapide(prep);

  /* L'explication vient EN TÊTE : le rapport dit où en est le candidat, il ne
     dit pas pourquoi son plan manque encore. */
  const explication = (
    <NoteCard icon={Icon} title={gate.titre} titleSize="lg">
      <p className={sejourStyles.sub}>{gate.texte}</p>
    </NoteCard>
  );
  const action = <Cta href={gate.href}>{gate.cta}</Cta>;

  return (
    <>
      <Top kicker={kicker} title="Mon plan du jour" />
      {rapide ? (
        <>
          <Section>
            <Pad>{explication}</Pad>
          </Section>
          <DiagnosticReport
            embedded
            closingCta={false}
            diagnostic={{result: rapide}}
            /* 🛑 La MÊME source de palier que la page `/diagnostic` :
               l'objectif vient du compte, jamais d'un second champ qui
               dériverait. */
            targetLevel={user?.targetLevel ?? null}
          />
          <Section>
            <Pad>{action}</Pad>
          </Section>
        </>
      ) : (
        <Section>
          <Pad>
            <Stack>
              {explication}
              {action}
            </Stack>
          </Pad>
        </Section>
      )}
    </>
  );
}

/**
 * Le résultat du diagnostic RAPIDE déjà passé — lu, jamais recalculé.
 *
 * 🛑 On relit **la session que le serveur a désignée**
 * (`prep.estimationSessionId`), pas « la session courante » : `current()` est
 * borné au couple (code, version) actif et répondrait `NOT_STARTED` sur une
 * version antérieure du diagnostic.
 *
 * 🛑 **Aucun repli en cas d'échec** : le rapport n'apparaît pas, la porte
 * retombe sur sa forme minimale avec son geste. Un rapport absent est un état
 * normal ; un rapport reconstitué de mémoire ne l'est pas.
 */
function useDiagnosticRapide(prep: ModulePreparation | null | undefined) {
  const sessionId = prep?.estimationSessionId ?? null;
  /* Le résultat est retenu AVEC la session dont il vient : sans ce couple, une
     bascule de module rendrait une seconde le rapport de l'autre parcours. */
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
        // Le rapport disparaît, la porte reste : elle n'a jamais dépendu de lui.
      });
    return () => {
      vivant = false;
    };
  }, [sessionId]);

  return lu?.sessionId === sessionId ? lu.result : null;
}
