import {Suspense} from "react";
import {CompetenceDetail} from "@/app/_components/competences/CompetenceDetail";
import {EO_CONFIG} from "@/app/_components/production/config";

/** `Suspense` obligatoire : l'écran lit le marqueur d'étape du Plan
 *  (`?etape=1`) via `useSearchParams` — convention du dépôt. */
export default function EOCompetenceDetailPage() {
  return (
    <Suspense>
      <CompetenceDetail config={EO_CONFIG} />
    </Suspense>
  );
}
