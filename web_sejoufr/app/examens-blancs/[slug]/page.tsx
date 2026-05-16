import { notFound } from "next/navigation";
import { publicExamApi } from "@/lib/api";
import type { ExamTemplateSummary } from "@/lib/types";
import { ExamBriefingClient } from "./ExamBriefingClient";

/**
 * Server component : pré-fetch les métadonnées du template d'examen pour
 * afficher rapidement le briefing. La logique de démarrage (et redirect vers
 * /sessions/<attemptId>) vit dans le client component. Endpoint public —
 * accessible aussi bien aux guests qu'aux comptes connectés.
 */
export default async function ExamBriefingPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  let exam: ExamTemplateSummary;
  try {
    exam = await publicExamApi.getBySlug(slug);
  } catch {
    notFound();
  }
  return <ExamBriefingClient exam={exam} />;
}
