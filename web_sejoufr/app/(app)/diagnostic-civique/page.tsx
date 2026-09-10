import type {Metadata} from "next";
import {CivicDiagnosticHub} from "@/app/_components/diagnostic-civique/CivicDiagnosticHub";

export const metadata: Metadata = {
  title: "Diagnostic — Examen civique — SejourFR",
  description:
    "24 questions sur les 5 thèmes de l'examen civique, pour savoir ce qu'il vous reste à travailler.",
};

export default function DiagnosticCiviquePage() {
  return <CivicDiagnosticHub />;
}
