"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ApiException, attemptApi, lotApi, themeApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule } from "@/lib/types";
import type {
  AttemptSummaryResponse,
  LotDto,
  QuestionReviewResponse,
} from "@/lib/types";
import { QuestionDetailModal } from "@/app/_components/QuestionDetailModal";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  ErrorsList,
  ExamSlots,
  LotsGrid,
  ModuleDetailGate,
  ModuleDetailShell,
  ModuleHero,
  ModuleTabs,
  SkeletonGrid,
  moduleDetailStyles as s,
} from "@/app/_components/module_detail/parts";

type Tab = "lots" | "examens" | "erreurs";
const EXAM_SLOTS = 10;

export default function CiviqueThemeDetailPage() {
  const params = useParams<{ themeId: string }>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [tab, setTab] = useState<Tab>("lots");
  const [themeName, setThemeName] = useState("Thème civique");
  const [lots, setLots] = useState<LotDto[]>([]);
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [errors, setErrors] = useState<QuestionReviewResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedQuestion, setSelectedQuestion] = useState<QuestionReviewResponse | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  useEffect(() => {
    if (status !== "authenticated" || !themeId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([
      themeApi.list("CIVIQUE"),
      lotApi.listCivique(themeId),
      attemptApi.listMine({ type: "MOCK_EXAM", module: "CIVIQUE", themeId, limit: 30 }),
      userContentApi.wrong("CIVIQUE", { themeId }),
    ]).then(([t, l, e, w]) => {
      if (cancelled) return;
      if (t.status === "fulfilled") {
        const found = t.value.find((x) => x.id === themeId);
        if (found) setThemeName(found.name);
      }
      if (l.status === "fulfilled") setLots(l.value);
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
  }, [status, themeId]);

  async function startLot(lot: LotDto) {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module: "CIVIQUE",
        themeId,
        lotNumero: lot.numero,
      });
      router.push(`/sessions/${a.id}?lot=${lot.numero}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer le lot.");
      setStarting(false);
    }
  }

  async function startThemeExam() {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "CIVIQUE",
        themeId,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  const examsSorted = useMemo(() => exams, [exams]);

  if (status === "loading") return <div className={s.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/civique/${themeId}`} />;

  return (
    <ModuleDetailShell accent="blue">
      <div className={s.breadcrumb}>
        <Link href="/entrainement?module=CIVIQUE">Entraînement</Link>
        <span className="sep">/</span> Examen civique <span className="sep">/</span>{" "}
        <strong>{themeName}</strong>
      </div>

      <ModuleHero
        eyebrow="Thème civique"
        title={themeName}
        description="Travaille ce thème par lots, passe des examens ciblés et revois tes erreurs."
      />

      <ModuleTabs<Tab>
        tabs={[
          { key: "lots", label: "Lots" },
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

      {tab === "lots" &&
        (loading ? (
          <SkeletonGrid />
        ) : lots.length === 0 ? (
          <p className={s.empty}>Aucun lot disponible pour ce thème pour l&apos;instant.</p>
        ) : (
          <LotsGrid lots={lots} starting={starting} onStart={startLot} />
        ))}

      {tab === "examens" && (
        <section>
          <p className={s.intro}>
            Examen ciblé sur ce thème : <strong>20 questions</strong> · 20 min · seuil de
            réussite 16/20.
          </p>
          {loading ? (
            <SkeletonGrid />
          ) : (
            <ExamSlots
              count={EXAM_SLOTS}
              exams={examsSorted}
              premium={isPremium}
              starting={starting}
              onStart={startThemeExam}
              onLocked={() => setPaywallOpen(true)}
            />
          )}
        </section>
      )}

      {tab === "erreurs" &&
        (loading ? (
          <SkeletonGrid />
        ) : errors.length === 0 ? (
          <p className={s.empty}>Aucune erreur sur ce thème — beau parcours&nbsp;!</p>
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
        module="CIVIQUE"
      />
    </ModuleDetailShell>
  );
}
