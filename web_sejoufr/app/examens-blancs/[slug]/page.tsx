import { notFound } from "next/navigation";
import { examApi } from "@/lib/api";
import { ExamRunnerClient } from "./ExamRunnerClient";

export default async function ExamPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  try {
    const exam = await examApi.getBySlug(slug);
    return <ExamRunnerClient exam={exam} />;
  } catch {
    notFound();
  }
}
