import type {Metadata} from "next";
import {DiagnosticRapportView} from "@/app/_components/diagnostic/DiagnosticView";

export const metadata: Metadata = {
  title: "Votre plan commence ici — TCF IRN — SejourFR",
  robots: {index: false},
};

export default async function DiagnosticTransitionPage({
  params,
}: {
  params: Promise<{sessionId: string}>;
}) {
  const {sessionId} = await params;
  return <DiagnosticRapportView sessionId={sessionId} vue="plan" />;
}
