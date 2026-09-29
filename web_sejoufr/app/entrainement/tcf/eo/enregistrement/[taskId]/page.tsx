import {Suspense} from "react";
import {ProductionInputPage} from "@/app/_components/production/ProductionInputPage";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoRecordingPage() {
  /* `Suspense` : l'écran lit le marqueur de provenance du Plan (`?etape=1`). */
  return (
    <Suspense>
      <ProductionInputPage config={EO_CONFIG} />
    </Suspense>
  );
}
