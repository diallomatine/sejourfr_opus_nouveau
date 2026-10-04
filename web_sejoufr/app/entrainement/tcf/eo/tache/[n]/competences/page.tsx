import {Suspense} from "react";
import {CompetencesList} from "@/app/_components/competences/CompetencesList";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EOCompetencesPage() {
  /* `Suspense` obligatoire : l'écran lit le marqueur de provenance du Plan
     (`?etape=1`) via `useSearchParams` — convention du dépôt, sans quoi le
     build de production échoue au prérendu. */
  return (
    <Suspense>
      <CompetencesList config={EO_CONFIG} />
    </Suspense>
  );
}
