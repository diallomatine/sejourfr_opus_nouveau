"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { ApiException, attemptApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule, type QuestionType } from "@/lib/types";
import type { AttemptSummaryResponse, QuestionReviewResponse } from "@/lib/types";
import { QuestionDetailModal } from "@/app/_components/QuestionDetailModal";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  ErrorsList,
  ExamSlots,
  ModuleDetailGate,
  ModuleDetailShell,
  ModuleHero,
  ModuleTabs,
  SkeletonGrid,
  moduleDetailStyles as s,
} from "@/app/_components/module_detail/parts";

type Tab = "series" | "examens" | "erreurs";
const EXAM_SLOTS = 10;

/** Épreuves TCF QCM exposées sur le web (les productions EO/EE restent mobiles). */
const TCF_QCM = {
  co: { questionType: "CO" as QuestionType, title: "Compréhension orale", examDuration: "20 min" },
  ce: { questionType: "CE" as QuestionType, title: "Compréhension écrite", examDuration: "35 min" },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    title: "Structure de la langue",
    examDuration: "20 min",
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS = [
  { level: "a2", label: "Niveau débutant", sub: "Bases — 15 questions par lot", color: "var(--color-green)" },
  { level: "b1", label: "Niveau intermédiaire", sub: "Intermédiaire — 20 questions par lot", color: "var(--color-amber)" },
  { level: "b2", label: "Niveau avancé", sub: "Challenge — 25 questions par lot", color: "var(--color-red)" },
] as const;

export default function TcfQcmDetailPage() {
  const params = useParams<{ code: string }>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const { user, status } = useAuth();

  const [tab, setTab] = useState<Tab>("series");
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [errors, setErrors] = useState<QuestionReviewResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedQuestion, setSelectedQuestion] = useState<QuestionReviewResponse | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const questionType = config?.questionType;

  useEffect(() => {
    if (status !== "authenticated" || !questionType) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([
      attemptApi.listMine({
        type: "MOCK_EXAM",
        module: "TCF",
        moduleExamQuestionType: questionType,
        limit: 30,
      }),
      userContentApi.wrong("TCF", { questionType }),
    ]).then(([e, w]) => {
      if (cancelled) return;
      if (e.status === "fulfilled") {
        setExams(
          e.value
            .filter((a) => a.finishedAt)
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
        );
      }
      if (w.status === "fulfilled") setErrors(w.value);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, questionType]);

  async function startModuleExam() {
    if (starting || !questionType) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "TCF",
        moduleExamQuestionType: questionType,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  if (status === "loading") return <div className={s.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}`} />;
  if (!config) {
    return (
      <ModuleDetailShell accent="red">
        <p className={s.empty}>Épreuve TCF inconnue.</p>
        <Link href="/entrainement?module=TCF" className={s.errCta}>
          ← Retour à l&apos;entraînement TCF
        </Link>
      </ModuleDetailShell>
    );
  }

  return (
    <ModuleDetailShell accent="red">
      <div className={s.breadcrumb}>
        <Link href="/entrainement?module=TCF">Entraînement</Link>
        <span className="sep">/</span> TCF IRN <span className="sep">/</span>{" "}
        <strong>{config.title}</strong>
      </div>

      <ModuleHero
        eyebrow="Épreuve TCF"
        title={config.title}
        description="Entraîne-toi par séries de niveau, passe des examens chronométrés et revois tes erreurs."
      />

      <ModuleTabs<Tab>
        tabs={[
          { key: "series", label: "Séries" },
          { key: "examens", label: "Examens" },
          {
            key: "erreurs",
            label: errors.length > 0 ? `Erreurs (${errors.length})` : "Erreurs",
          },
        ]}
        active={tab}
        onChange={setTab}
      />

      {error && <div className={`form-error ${s.error}`}>{error}</div>}

      {tab === "series" && (
        <section>
          <p className={s.intro}>
            Choisis ton niveau : les questions sont découpées en lots dans l&apos;ordre du
            programme, de plus en plus exigeants.
          </p>
          <section className={s.grid}>
            {LEVELS.map((lv) => (
              <Link
                key={lv.level}
                href={`/entrainement/tcf/${code}/${lv.level}`}
                className={s.levelCard}
              >
                <span className={s.levelChip} style={{ background: lv.color }}>
                  {lv.level.toUpperCase()}
                </span>
                <span className={s.levelBody}>
                  <span className={s.levelTitle}>{lv.label}</span>
                  <span className={s.levelSub}>{lv.sub}</span>
                </span>
                <span className={s.levelArrow} aria-hidden>
                  ›
                </span>
              </Link>
            ))}
          </section>
        </section>
      )}

      {tab === "examens" && (
        <section>
          <p className={s.intro}>
            Examen blanc de l&apos;épreuve : <strong>25 questions</strong> (A2 → B1 → B2) ·{" "}
            {config.examDuration} · score pondéré sur 50.
          </p>
          {loading ? (
            <SkeletonGrid />
          ) : (
            <ExamSlots
              count={EXAM_SLOTS}
              exams={exams}
              premium={isPremium}
              starting={starting}
              onStart={startModuleExam}
              onLocked={() => setPaywallOpen(true)}
            />
          )}
        </section>
      )}

      {tab === "erreurs" &&
        (loading ? (
          <SkeletonGrid />
        ) : errors.length === 0 ? (
          <p className={s.empty}>Aucune erreur sur cette épreuve — beau parcours&nbsp;!</p>
        ) : (
          <ErrorsList errors={errors} onSelect={setSelectedQuestion} />
        ))}

      {selectedQuestion && (
        <QuestionDetailModal
          question={selectedQuestion}
          onClose={() => setSelectedQuestion(null)}
        />
      )}
      <PaywallSheet
        open={paywallOpen}
        onClose={() => setPaywallOpen(false)}
        module="INTEGRAL"
      />
    </ModuleDetailShell>
  );
}
