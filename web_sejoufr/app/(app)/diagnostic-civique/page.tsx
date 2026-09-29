import type {Metadata} from "next";
import {CivicDiagnosticHub} from "@/app/_components/diagnostic-civique/CivicDiagnosticHub";

export const metadata: Metadata = {
  title: "Diagnostic — Examen civique — SejourFR",
  description:
    "40 questions, le format de l'examen civique, pour savoir ce qu'il vous reste "
    + "à travailler. Sans compte : il n'est demandé qu'au moment du résultat.",
};

export default function DiagnosticCiviquePage() {
  return <CivicDiagnosticHub />;
}
