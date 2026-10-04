import {Suspense} from "react";
import {ProductionSubjects} from "@/app/_components/production/ProductionSubjects";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoTaskPage() {
  /* `Suspense` obligatoire : l'écran lit le marqueur de provenance du Plan
     (`?etape=1`) via `useSearchParams`, sans quoi le prérendu échoue. */
  return (
    <Suspense>
      <ProductionSubjects config={EO_CONFIG} />
    </Suspense>
  );
}
