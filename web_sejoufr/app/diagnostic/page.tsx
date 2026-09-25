import type {Metadata} from "next";
import {DiagnosticView} from "@/app/_components/diagnostic/DiagnosticView";

export const metadata: Metadata = {
  title: "Diagnostic TCF personnalisé — SejourFR",
  description:
    "Diagnostic gratuit, sans compte, pour le TCF IRN ou l'examen civique : votre niveau, vos priorités et votre plan.",
};

export default function DiagnosticPage() {
  return <DiagnosticView />;
}
