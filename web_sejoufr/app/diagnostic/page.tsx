import type {Metadata} from "next";
import {DiagnosticView} from "@/app/_components/diagnostic/DiagnosticView";

export const metadata: Metadata = {
  title: "Diagnostic TCF personnalisé — SejourFR",
  description:
    "Un exercice écrit et un oral enregistré pour identifier vos priorités de travail au TCF.",
};

export default function DiagnosticPage() {
  return <DiagnosticView />;
}
