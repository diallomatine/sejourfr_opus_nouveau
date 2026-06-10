import { Suspense } from "react";
import { ProductionSession } from "@/app/_components/production/ProductionSession";
import { EE_CONFIG } from "@/app/_components/production/config";

export default function EeSessionPage() {
  return (
    <Suspense>
      <ProductionSession config={EE_CONFIG} />
    </Suspense>
  );
}
