import type {Metadata} from "next";
import {LearningPlanView} from "@/app/_components/plan/LearningPlanView";

export const metadata: Metadata = {
  title: "Mon plan personnalisé — SejourFR",
  description: "Votre priorité du moment et les prochains exercices recommandés.",
};

export default function PlanPage() {
  return <LearningPlanView />;
}
