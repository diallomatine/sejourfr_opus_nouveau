import type {Metadata} from "next";
import {PlanEvolutionView} from "@/app/_components/plan/PlanEvolutionView";

export const metadata: Metadata = {
  title: "Votre programme évolue — SejourFR",
  description: "Ce que vos dernières productions ont changé dans votre plan.",
};

export default function PlanEvolutionPage() {
  return <PlanEvolutionView />;
}
