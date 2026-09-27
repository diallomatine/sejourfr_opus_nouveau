"use client";

import {Compass, Landmark} from "lucide-react";
import {Cta, NoteCard, Stack, sejourStyles} from "@/app/_components/sejour/SejourKit";
import type {DiagnosticAAffiner} from "@/lib/preparation";

/**
 * **Affiner le Plan par le diagnostic** — une proposition SECONDAIRE (D-69).
 *
 * 🛑 **Jamais une porte, jamais le CTA rouge** : le Plan existe sans
 * diagnostic, cette carte se pose SOUS « À faire maintenant » (Plan TCF, Plan
 * civique, Accueil). Aucune phrase n'est écrite ici — tout vient de
 * `diagnosticAAffiner` (`lib/preparation.ts`).
 *
 * Briques du kit : `NoteCard` (soft) + `Cta` (line). Miroir mobile : la même
 * composition `SfNoteCard` + bouton secondaire.
 */
export function DiagnosticAffinerCard({
  proposition,
  module,
}: {
  proposition: DiagnosticAAffiner;
  module: "TCF" | "CIVIQUE";
}) {
  return (
    <NoteCard
      variant="soft"
      icon={module === "CIVIQUE" ? Landmark : Compass}
      title={proposition.titre}
    >
      <Stack>
        <p className={sejourStyles.sub}>{proposition.texte}</p>
        <Cta href={proposition.href} variant="line">{proposition.cta}</Cta>
      </Stack>
    </NoteCard>
  );
}
