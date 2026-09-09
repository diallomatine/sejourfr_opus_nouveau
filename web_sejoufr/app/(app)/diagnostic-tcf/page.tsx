import type {Metadata} from "next";
import {TcfDiagnosticHub} from "@/app/_components/diagnostic-tcf/TcfDiagnosticHub";

export const metadata: Metadata = {
  title: "Diagnostic TCF — SejourFR",
  description:
    "Les 4 épreuves du TCF, à faire séparément, pour savoir où vous en êtes vraiment.",
};

export default function DiagnosticTcfPage() {
  return <TcfDiagnosticHub />;
}
