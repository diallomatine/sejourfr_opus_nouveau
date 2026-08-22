import type {Metadata} from "next";
import {PlanProgressView} from "@/app/_components/plan/PlanProgressView";

export const metadata: Metadata = {
  title: "Ma progression — SejourFR",
  description: "Où vous en êtes sur les quatre domaines du TCF, et à quelle distance de votre objectif.",
};

export default function PlanProgressPage() {
  return <PlanProgressView />;
}
