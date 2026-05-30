"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ApiException, attemptApi, lotApi, themeApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule} from "@/lib/types";
import type {AttemptSummaryResponse, LotDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  ExamBlancHero,
  ExamHistoryList,
  HubDetailHeader,
  LotRow,
  SectionCounter,
  SectionLabel,
  SectionLink,
  SeeMoreButton,
} from "@/app/_components/hub/HubParts";
import {ExamDoneSheet} from "@/app/_components/hub/ExamDoneSheet";
import hub from "@/app/_components/hub/hub.module.css";

const LOTS_CAP = 6;

/**
 * Détail d'un thème civique — single-scroll calqué sur
 * `CiviqueThemeDetailScreen` mobile : header + hero examen blanc du thème
 * (20 Q) + section lots (lot 1 gratuit, 2+ premium) + historique des examens
 * du thème. L'ancien onglet « Erreurs » est retiré (les erreurs vivent dans
 * /revision, comme sur mobile).
 */
export default function CiviqueThemeDetailPage() {
  const params = useParams<{themeId: string}>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const [themeName, setThemeName] = useState("Thème civique");
  const [questionCount, setQuestionCount] = useState<number>(0);
  const [lots, setLots] = useState<LotDto[]>([]);
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [showAllLots, setShowAllLots] = useState(false);
  const [selected, setSelected] = useState<AttemptSummaryResponse | null>(null);
  const [selectedLot, setSelectedLot] = useState<LotDto | null>(null);

  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  useEffect(() => {
    if (status !== "authenticated" || !themeId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([
      themeApi.list("CIVIQUE"),
      lotApi.listCivique(themeId),
      attemptApi.listMine({type: "MOCK_EXAM", module: "CIVIQUE", themeId, limit: 30}),
    ]).then(([t, l, e]) => {
      if (cancelled) return;
      if (t.status === "fulfilled") {
        const found = t.value.find((x) => x.id === themeId);
        if (found) {
          setThemeName(found.name);
          setQuestionCount(found.questionCount ?? 0);
        }
      }
      if (l.status === "fulfilled") setLots(l.value);
      if (e.status === "fulfilled") {
        setExams(
          e.value
            .filter((a) => a.finishedAt)
            .sort((a, b) => b.startedAt.localeCompare(a.startedAt)),
        );
      }
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, themeId]);

  async function startLot(lot: LotDto) {
    if (starting) return;
    // Lot 1 = découverte gratuite ; lots 2+ réservés aux abonnés (parité mobile).
    if (!isPremium && lot.numero > 1) {
      setPaywallOpen(true);
      return;
    }
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
      const a = await attemptApi.start({type: "MOCK_EXAM", module: "CIVIQUE", themeId});
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  function resumeSelected() {
    setSelected(null);
    // 1er examen gratuit déjà consommé (celui-ci est terminé) → refaire est premium.
    if (!isPremium) {
      setPaywallOpen(true);
      return;
    }
    void startThemeExam();
  }

  const visibleLots = useMemo(
    () => (showAllLots ? lots : lots.slice(0, LOTS_CAP)),
    [lots, showAllLots],
  );

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/civique/${themeId}`} />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement?module=CIVIQUE"
          title={themeName}
          subtitle={`Civique · ${questionCount} questions`}
        />

        <ExamBlancHero
          eyebrow="Examen blanc · 20 questions"
          title="Lancer un examen blanc"
          description="20 questions de ce thème, en 20 minutes. Seuil : 16/20."
          ctaLabel="Voir les examens"
          accent="blue"
          onClick={() => router.push(`/entrainement/civique/${themeId}/examens`)}
        />

        {error && <div className={hub.error}>{error}</div>}

        {loading ? (
          <div className={hub.loading}>Chargement…</div>
        ) : (
          <>
            <SectionLabel
              label="S'entraîner par lot"
              trailing={<SectionCounter text={`${lots.length} lots`} />}
            />
            {lots.length === 0 ? (
              <p className={hub.empty}>Aucun lot disponible pour ce thème pour l&apos;instant.</p>
            ) : (
              <div className={hub.list}>
                {visibleLots.map((lot) => (
                  <LotRow
                    key={lot.numero}
                    lot={lot}
                    tone="blue"
                    locked={!isPremium && lot.numero > 1}
                    disabled={starting}
                    onClick={() =>
                      lot.lastScore != null ? setSelectedLot(lot) : startLot(lot)
                    }
                  />
                ))}
                {!showAllLots && lots.length > LOTS_CAP && (
                  <SeeMoreButton
                    label={`Voir les ${lots.length - LOTS_CAP} autres lots`}
                    onClick={() => setShowAllLots(true)}
                  />
                )}
              </div>
            )}

            <SectionLabel
              label="Historique"
              trailing={
                <SectionLink
                  label="Tout voir"
                  onClick={() => router.push(`/entrainement/civique/${themeId}/examens`)}
                />
              }
            />
            <ExamHistoryList
              items={exams.slice(0, 3)}
              emptyLabel="Aucun examen passé. Lance un examen blanc ou entraîne-toi par lot."
              onSelect={setSelected}
            />
          </>
        )}

        <ExamDoneSheet
          open={selected !== null}
          subtitle={
            selected && selected.totalQuestions
              ? `Dernier score : ${selected.score ?? 0} / ${selected.totalQuestions}`
              : null
          }
          onViewDetail={() => {
            const id = selected?.id;
            setSelected(null);
            if (id) router.push(`/sessions/${id}`);
          }}
          onResume={resumeSelected}
          onClose={() => setSelected(null)}
        />
        <ExamDoneSheet
          open={selectedLot !== null}
          title={selectedLot ? `Lot ${selectedLot.numero}` : "Lot"}
          subtitle={
            selectedLot && selectedLot.lastScore != null
              ? `Dernier score : ${selectedLot.lastScore} / ${selectedLot.totalQuestions}`
              : null
          }
          onViewDetail={() => {
            const id = selectedLot?.lastAttemptId;
            setSelectedLot(null);
            if (id) router.push(`/sessions/${id}`);
          }}
          onResume={() => {
            const lot = selectedLot;
            setSelectedLot(null);
            if (lot) void startLot(lot);
          }}
          onClose={() => setSelectedLot(null)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
      </main>
    </DualChromeShell>
  );
}
