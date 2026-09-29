import type {Metadata} from "next";
import {Suspense} from "react";
import {PlanModules} from "@/app/_components/plan/PlanModules";

export const metadata: Metadata = {
  title: "Mon plan personnalisé — SejourFR",
  description: "Votre priorité du moment et les prochains exercices recommandés.",
};

export default function PlanPage() {
  return (
    // `useSearchParams` impose une frontière de Suspense côté App Router.
    <Suspense fallback={null}>
      <PlanModules />
    </Suspense>
  );
}
