import type {Metadata} from "next";
import {PlanHistoryView} from "@/app/_components/plan/PlanHistoryView";

export const metadata: Metadata = {
  title: "Mes plans — SejourFR",
  description: "Vos plans terminés, les compétences que vous y avez travaillées et les niveaux mesurés.",
};

export default function PlanProgressPage() {
  return <PlanHistoryView />;
}
