import type {Metadata} from "next";
import {PlanCycleArchiveView} from "@/app/_components/plan/PlanCycleArchiveView";

export const metadata: Metadata = {
  title: "Cycle terminé — SejourFR",
  description: "Le plan d'un cycle terminé, tel qu'il était : ses épreuves, ses étapes et ses examens.",
};

/**
 * **Un cycle terminé, en consultation** — ouvert depuis « Mes cycles ».
 *
 * 🛑 Le préfixe `/plan` est déjà dans `APP_GROUP_PREFIXES`
 * (`lib/chrome-routes.ts`) et dans les préfixes protégés du middleware.
 */
export default function PlanCycleArchivePage() {
  return <PlanCycleArchiveView />;
}
