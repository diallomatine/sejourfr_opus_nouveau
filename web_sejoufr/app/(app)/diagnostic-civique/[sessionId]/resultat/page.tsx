import type {Metadata} from "next";
import {CivicDiagnosticResult} from "@/app/_components/diagnostic-civique/CivicDiagnosticResult";

export const metadata: Metadata = {
  title: "Mon diagnostic — Examen civique — SejourFR",
};

export default async function CivicDiagnosticResultPage({
  params,
}: {
  params: Promise<{sessionId: string}>;
}) {
  const {sessionId} = await params;
  return <CivicDiagnosticResult sessionId={sessionId} />;
}
