import {Suspense} from "react";
import {ProductionInputPage} from "@/app/_components/production/ProductionInputPage";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeRedactionPage() {
  /* `Suspense` : l'écran lit le marqueur de provenance du Plan (`?etape=1`). */
  return (
    <Suspense>
      <ProductionInputPage config={EE_CONFIG} />
    </Suspense>
  );
}
