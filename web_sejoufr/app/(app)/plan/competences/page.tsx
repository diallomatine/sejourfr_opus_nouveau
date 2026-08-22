import type {Metadata} from "next";
import {PlanSkillsView} from "@/app/_components/plan/PlanSkillsView";

export const metadata: Metadata = {
  title: "Toutes mes compétences — SejourFR",
  description: "Le référentiel de votre plan : les tâches d'expression et les paliers de compréhension.",
};

export default function PlanSkillsPage() {
  return <PlanSkillsView />;
}
