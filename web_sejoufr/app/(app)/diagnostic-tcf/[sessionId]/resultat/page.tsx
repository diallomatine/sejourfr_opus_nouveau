import type {Metadata} from "next";
import {TcfDiagnosticResult} from "@/app/_components/diagnostic-tcf/TcfDiagnosticResult";

export const metadata: Metadata = {
  title: "Mon diagnostic TCF — SejourFR",
  description: "Votre niveau par épreuve et les tâches qui vous limitent.",
};

export default async function DiagnosticTcfResultPage({
  params,
}: {
  params: Promise<{sessionId: string}>;
}) {
  const {sessionId} = await params;
  return <TcfDiagnosticResult sessionId={sessionId} />;
}
