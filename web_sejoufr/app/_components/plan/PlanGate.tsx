"use client";

import {Compass, type LucideIcon} from "lucide-react";
import {Cta, NoteCard, Pad, Section, Stack, Top, sejourStyles} from "@/app/_components/sejour/SejourKit";
import type {PlanIndisponible} from "@/lib/preparation";

/**
 * **Pourquoi ce plan n'existe pas encore**, et la seule porte qui le débloque.
 *
 * 🛑 Jamais un plan vide, jamais un plan bâti sur une mesure qui n'existe pas.
 * Le titre, le texte, le libellé et la destination viennent de
 * `planIndisponible` (`lib/preparation.ts`) — **la même autorité** que
 * l'Accueil et les Examens, pour que le candidat ne se voie pas proposer trois
 * choses différentes selon l'écran où il arrive. Aucune phrase n'est écrite
 * ici.
 */
export function PlanGate({
  gate,
  kicker,
  icon: Icon = Compass,
}: {
  gate: PlanIndisponible;
  kicker: string;
  icon?: LucideIcon;
}) {
  return (
    <>
      <Top kicker={kicker} title="Mon plan" />
      <Section>
        <Pad>
          <Stack>
            <NoteCard icon={Icon} title={gate.titre} titleSize="lg">
              <p className={sejourStyles.sub}>{gate.texte}</p>
            </NoteCard>
            <Cta href={gate.href}>{gate.cta}</Cta>
          </Stack>
        </Pad>
      </Section>
    </>
  );
}
