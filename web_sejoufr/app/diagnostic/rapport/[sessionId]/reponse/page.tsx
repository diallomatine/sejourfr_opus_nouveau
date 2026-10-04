import type {Metadata} from "next";
import {DiagnosticRapportView} from "@/app/_components/diagnostic/DiagnosticView";

export const metadata: Metadata = {
  title: "Votre réponse — TCF IRN — SejourFR",
  robots: {index: false},
};

export default async function DiagnosticReponsePage({
  params,
}: {
  params: Promise<{sessionId: string}>;
}) {
  const {sessionId} = await params;
  return <DiagnosticRapportView sessionId={sessionId} vue="reponse" />;
}
