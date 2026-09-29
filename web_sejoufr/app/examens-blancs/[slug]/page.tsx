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
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ slot?: string }>;
}) {
  const { slug } = await params;
  const { slot } = await searchParams;
  let exam: ExamTemplateSummary;
  try {
    exam = await publicExamApi.getBySlug(slug);
  } catch {
    notFound();
  }
  // Slot d'examen blanc cible (grille /examens-blancs) — propagé au start pour
  // que refaire « l'examen N » réutilise slot_number=N (cf. migration V110).
  const slotNumber = slot != null && /^\d+$/.test(slot) ? Number(slot) : undefined;
  return <ExamBriefingClient exam={exam} slotNumber={slotNumber} />;
}
