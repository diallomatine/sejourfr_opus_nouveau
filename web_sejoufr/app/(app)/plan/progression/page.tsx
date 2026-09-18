import type {Metadata} from "next";
import {PlanHistoryView} from "@/app/_components/plan/PlanHistoryView";

export const metadata: Metadata = {
  title: "Ma progression — SejourFR",
  description: "Vos cycles terminés, les compétences que vous y avez travaillées et les niveaux mesurés.",
};

export default function PlanProgressPage() {
  return <PlanHistoryView />;
}
