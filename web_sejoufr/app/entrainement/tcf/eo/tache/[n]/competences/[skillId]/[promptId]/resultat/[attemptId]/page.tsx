import {Suspense} from "react";
import {CompetenceResult} from "@/app/_components/competences/CompetenceResult";
import {EO_CONFIG} from "@/app/_components/production/config";

/** `Suspense` obligatoire : l'écran lit le marqueur d'étape du Plan
 *  (`?etape=1`) via `useSearchParams` — convention du dépôt. */
export default function EOCompetenceResultPage() {
  return (
    <Suspense>
      <CompetenceResult config={EO_CONFIG} />
    </Suspense>
  );
}
