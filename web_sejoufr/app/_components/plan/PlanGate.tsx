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
 * ici.
 *
 * 🛑 **Trois états, et c'est le SERVEUR qui dit lequel** (`prep.etape`) :
 * `DIAGNOSTIC_A_FAIRE` ouvre le diagnostic rapide, `ESTIMATION_FAITE` affiche
 * le **rapport du diagnostic rapide** (arbitrage du propriétaire), `PLAN_PRET`
 * n'arrive jamais ici — l'appelant affiche le vrai Plan. Aucun front ne déduit
 * cet état d'un compteur ni d'un score.
 *
 * 🛑 **En `ESTIMATION_FAITE`, le rapport est le COMPOSANT DE `/diagnostic`,
 * encastré** (`DiagnosticReport embedded`), pas un résumé écrit ici : deux
 * lectures du même diagnostic auraient fini par en dire deux choses. Il porte
 * **son propre CTA de fin** vers le diagnostic complet — c'est pourquoi
 * `gate.cta` n'est pas rendu dans cet état, il ferait doublon sur la même
 * destination.
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

  return (
    <>
      <Top kicker={kicker} title="Mon plan du jour" />
      <Section>
        <Pad>
          <Stack>
            {/* L'explication vient EN TÊTE : le rapport dit où en est le
                candidat, il ne dit pas pourquoi son plan manque encore. */}
            <NoteCard icon={Icon} title={gate.titre} titleSize="lg">
              <p className={sejourStyles.sub}>{gate.texte}</p>
            </NoteCard>
            {!rapide && <Cta href={gate.href}>{gate.cta}</Cta>}
          </Stack>
        </Pad>
      </Section>
      {rapide && (
        <DiagnosticReport
          embedded
          diagnostic={{result: rapide}}
          /* 🛑 La MÊME source de palier que la page `/diagnostic` : l'objectif
             vient du compte, jamais d'un second champ qui dériverait. */
          targetLevel={user?.targetLevel ?? null}
        />
      )}
    </>
  );
}

/**
 * Le résultat du diagnostic RAPIDE déjà passé — lu, jamais recalculé.
 *
 * 🛑 On relit **la session que le serveur a désignée** (`prep.sessionId`), pas
 * « la session courante » : `preparation()` retient la dernière session close,
 * qui peut appartenir à une version antérieure du diagnostic — `current()`
 * répondrait alors `NOT_STARTED` et la porte perdrait le rapport du candidat.
 *
 * 🛑 **Aucun repli en cas d'échec** : le rapport n'apparaît pas, la porte
 * retombe sur sa forme minimale avec son CTA. Un rapport absent est un état
 * normal ; un rapport reconstitué de mémoire ne l'est pas.
 */
function useDiagnosticRapide(prep: ModulePreparation | null | undefined) {
  const sessionId = prep?.etape === "ESTIMATION_FAITE" ? prep.sessionId : null;
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
