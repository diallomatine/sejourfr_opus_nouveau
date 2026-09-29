import {Suspense} from "react";
import {ProductionResults} from "@/app/_components/production/ProductionResults";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoResultsPage() {
  return (
    <Suspense>
      <ProductionResults config={EO_CONFIG} />
    </Suspense>
  );
}
