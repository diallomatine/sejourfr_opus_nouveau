"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {attemptApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type AttemptSummaryResponse, type QuestionType} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  EpreuveCard,
  ExamBlancHero,
  ExamHistoryList,
  HubDetailHeader,
  type HubTone,
  SectionCounter,
  SectionLabel,
  SectionLink,
} from "@/app/_components/hub/HubParts";
import hub from "@/app/_components/hub/hub.module.css";

/** Épreuves TCF QCM exposées sur le web (les productions EO/EE restent mobiles). */
const TCF_QCM = {
  co: {questionType: "CO" as QuestionType, title: "Compréhension orale"},
  ce: {questionType: "CE" as QuestionType, title: "Compréhension écrite"},
  structure: {questionType: "STRUCTURE" as QuestionType, title: "Structure de la langue"},
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS: {key: string; chip: string; tone: HubTone; label: string; sub: string}[] = [
  {key: "a2", chip: "A2", tone: "green", label: "Niveau débutant", sub: "15 questions par lot"},
  {key: "b1", chip: "B1", tone: "amber", label: "Niveau intermédiaire", sub: "20 questions par lot"},
  {key: "b2", chip: "B2", tone: "red", label: "Niveau avancé", sub: "25 questions par lot"},
];

/**
 * Détail d'une épreuve TCF QCM (CO/CE/Structure) — single-scroll calqué sur
 * `TcfQcmDetailScreen` mobile : header + notice (Structure) + hero examen
 * blanc du module + 3 niveaux (A2/B1/B2) + historique. L'onglet « Erreurs » est
 * retiré (les erreurs vivent dans /revision, comme sur mobile).
 */
export default function TcfQcmDetailPage() {
  const params = useParams<{code: string}>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const {user, status} = useAuth();

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);

  const questionType = config?.questionType;

  useEffect(() => {
    if (status !== "authenticated" || !questionType) return;
    let cancelled = false;
    attemptApi
      .listMine({type: "MOCK_EXAM", module: "TCF", moduleExamQuestionType: questionType, limit: 30})
      .then((list) => {
        if (cancelled) return;
        setExams(
          list
            .filter((a) => a.finishedAt)
            .sort((a, b) => b.startedAt.localeCompare(a.startedAt)),
        );
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, questionType]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}`} />;
  if (!config) {
    return (
      <DualChromeShell>
        <main className={hub.hub}>
          <p className={hub.empty}>Épreuve TCF inconnue.</p>
          <Link href="/entrainement?module=TCF" className={hub.sectionLink}>
            ← Retour à l&apos;entraînement TCF
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement?module=TCF"
          title={config.title}
          subtitle="TCF IRN · QCM"
        />

        {code === "structure" && (
          <div className={hub.notice}>
            Module non évalué au TCF IRN officiel — entraînement bonus pour consolider
            grammaire et lexique.
          </div>
        )}

        <ExamBlancHero
          eyebrow="Examen blanc · 25 questions"
          title="Passer l'examen blanc"
          description="25 questions A2 → B1 → B2, chronométrées. Score pondéré sur 50."
          ctaLabel="Voir les examens"
          accent="red"
          onClick={() => router.push(`/entrainement/tcf/${code}/examens`)}
        />

        <SectionLabel
          label="S'entraîner par niveau"
          trailing={<SectionCounter text="3 niveaux" />}
        />
        <div className={hub.list}>
          {LEVELS.map((lv) => (
            <EpreuveCard
              key={lv.key}
              icon={
                <span style={{fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 14}}>
                  {lv.chip}
                </span>
              }
              tone={lv.tone}
              title={lv.label}
              subtitle={lv.sub}
              onClick={() => router.push(`/entrainement/tcf/${code}/${lv.key}`)}
            />
          ))}
        </div>

        <SectionLabel
          label="Examens récents"
          trailing={
            <SectionLink
              label="Tout voir"
              onClick={() => router.push(`/entrainement/tcf/${code}/examens`)}
            />
          }
        />
        <ExamHistoryList items={exams.slice(0, 3)} />
      </main>
    </DualChromeShell>
  );
}
