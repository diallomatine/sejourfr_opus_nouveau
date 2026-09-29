import {Suspense} from "react";
import {CompetencePrompt} from "@/app/_components/competences/CompetencePrompt";
import {EE_CONFIG} from "@/app/_components/production/config";

/** `Suspense` obligatoire : l'écran lit le marqueur d'étape du Plan
 *  (`?etape=1`) via `useSearchParams` — convention du dépôt. */
export default function EECompetencePromptPage() {
  return (
    <Suspense>
      <CompetencePrompt config={EE_CONFIG} />
    </Suspense>
  );
}
