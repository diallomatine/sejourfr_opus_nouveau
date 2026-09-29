import { Suspense } from "react";
import { ProductionSession } from "@/app/_components/production/ProductionSession";
import { EO_CONFIG } from "@/app/_components/production/config";

export default function EoSessionPage() {
  return (
    <Suspense>
      <ProductionSession config={EO_CONFIG} />
    </Suspense>
  );
}
