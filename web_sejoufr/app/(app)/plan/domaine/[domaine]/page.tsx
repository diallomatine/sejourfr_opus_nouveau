import type {Metadata} from "next";
import {PlanDomainView} from "@/app/_components/plan/PlanDomainView";

export const metadata: Metadata = {
  title: "Mon domaine TCF — SejourFR",
  description: "Où vous en êtes sur cette épreuve, et ce qu'il reste à y travailler.",
};

export default function PlanDomainPage() {
  return <PlanDomainView />;
}
