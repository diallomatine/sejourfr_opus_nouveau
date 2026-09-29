import {Suspense} from "react";
import {CompetenceDetail} from "@/app/_components/competences/CompetenceDetail";
import {EE_CONFIG} from "@/app/_components/production/config";

/** `Suspense` obligatoire : l'écran lit le marqueur d'étape du Plan
 *  (`?etape=1`) via `useSearchParams` — convention du dépôt. */
export default function EECompetenceDetailPage() {
  return (
    <Suspense>
      <CompetenceDetail config={EE_CONFIG} />
    </Suspense>
  );
}
