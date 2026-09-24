import type {Metadata} from "next";
import {ProgressionEpreuveView} from "@/app/_components/progression/ProgressionEpreuveView";

export const metadata: Metadata = {
  title: "Ma progression par épreuve — SejourFR",
  description: "L'évolution de votre score sur une épreuve du TCF IRN, examen blanc après examen blanc.",
};

/** Les quatre épreuves du TCF IRN — prérendues, donc préchargées par les liens. */
export function generateStaticParams() {
  return ["co", "ce", "ee", "eo"].map((epreuve) => ({epreuve}));
}

export default function ProgressionEpreuvePage() {
  return <ProgressionEpreuveView />;
}
