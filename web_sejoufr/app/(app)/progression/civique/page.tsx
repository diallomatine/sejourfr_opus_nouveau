import type {Metadata} from "next";
import {ProgressionCiviqueView} from "@/app/_components/progression/ProgressionCiviqueView";

export const metadata: Metadata = {
  title: "Ma progression — Examen civique — SejourFR",
  description: "Vos examens civiques globaux face au seuil de réussite, et votre progression thème par thème.",
};

export default function ProgressionCiviquePage() {
  return <ProgressionCiviqueView />;
}
