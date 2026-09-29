import type {Metadata} from "next";
import {Suspense} from "react";
import {PlanUnlockGate} from "@/app/_components/plan/PlanUnlockGate";

export const metadata: Metadata = {
  title: "Débloquer mon plan — SejourFR",
  description: "Ce que votre diagnostic a trouvé, et ce que votre plan ouvre.",
};

/**
 * **L'écran de transition du Plan** — ouvert par « Débloquer mon plan », il
 * mène à la page de choix du pass.
 *
 * Route protégée par `middleware.ts` : le préfixe `/plan` la couvre déjà (le
 * test est un `startsWith`, ne pas le transformer en égalité).
 */
export default function PlanDebloquerPage() {
  return (
    // `useSearchParams` impose une frontière de Suspense côté App Router.
    <Suspense fallback={null}>
      <PlanUnlockGate />
    </Suspense>
  );
}
