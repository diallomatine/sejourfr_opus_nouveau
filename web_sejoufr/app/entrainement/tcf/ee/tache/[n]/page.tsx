import {Suspense} from "react";
import {ProductionSubjects} from "@/app/_components/production/ProductionSubjects";
import {EE_CONFIG, PRODUCTION_TASK_PARAMS} from "@/app/_components/production/config";

export default function EeTaskPage() {
  /* `Suspense` obligatoire : l'écran lit le marqueur de provenance du Plan
     (`?etape=1`) via `useSearchParams`, sans quoi le prérendu échoue. */
  return (
    <Suspense>
      <ProductionSubjects config={EE_CONFIG} />
    </Suspense>
  );
}

/** Les 3 tâches sont prérendues : changer de mode ne redemande pas la page au
 *  serveur (cf. `PRODUCTION_TASK_PARAMS`). */
export function generateStaticParams() {
  return [...PRODUCTION_TASK_PARAMS];
}
