import {Suspense} from "react";
import {CompetencesList} from "@/app/_components/competences/CompetencesList";
import {EE_CONFIG, PRODUCTION_TASK_PARAMS} from "@/app/_components/production/config";

export default function EECompetencesPage() {
  /* `Suspense` obligatoire : l'écran lit le marqueur de provenance du Plan
     (`?etape=1`) via `useSearchParams` — convention du dépôt, sans quoi le
     build de production échoue au prérendu. */
  return (
    <Suspense>
      <CompetencesList config={EE_CONFIG} />
    </Suspense>
  );
}

/** Les 3 tâches sont prérendues : changer de mode ne redemande pas la page au
 *  serveur (cf. `PRODUCTION_TASK_PARAMS`). */
export function generateStaticParams() {
  return [...PRODUCTION_TASK_PARAMS];
}
