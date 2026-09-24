"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Flame, GraduationCap, Trophy } from "lucide-react";
import { attemptApi, publicAttemptApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  type EpreuveType,
  niveauCecrlLabel,
  type QuestionType,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import {
  ComplementaryNotice,
  DetailShell,
  DetailStatCard,
  ExamsGrid,
} from "@/app/_components/hub/DetailParts";
import { ExamIntroSheet, type ExamFact } from "@/app/_components/hub/ExamIntroSheet";
import { comprehensionExamIntro } from "@/lib/exam-intro";
import { examSlotGrid } from "@/lib/exam-slots";
import { useExamSlotLocks } from "@/lib/use-exam-slot-locks";
import { plannedEpreuveLabel } from "@/lib/exam-durations";
import detail from "@/app/_components/hub/detail.module.css";

const SLOTS = 20;

// CO et CE lisent la table de référence partagée (`lib/exam-durations.ts`) :
// la même épreuve doit annoncer la même durée jouée seule et dans un examen
// complet — c'est exactement là que la CE avait divergé (30 vs 35 min).
const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    epreuve: "TCF_CO" as EpreuveType,
    title: "Compréhension orale",
    duration: plannedEpreuveLabel("TCF_CO"),
  },
  ce: {
    questionType: "CE" as QuestionType,
    epreuve: "TCF_CE" as EpreuveType,
    title: "Compréhension écrite",
    duration: plannedEpreuveLabel("TCF_CE"),
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    epreuve: "TCF_STRUCTURE" as EpreuveType,
    title: "Structure de la langue",
    // Épreuve absente de l'examen complet : aucune donnée serveur avant le
    // démarrage, la minute reste écrite ici (cf. rapport).
    duration: "20 min",
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

/**
 * Examens blancs d'une épreuve TCF QCM (25 Q A2→B1→B2, score /499) — maquette
 * sejour_fr.html : 3 stat cards (passés / meilleur score / niveau estimé) +
 * grille de 20 examens. 🛑 Le verrou de chaque créneau est SERVI
 * (`GET /api/exam-slots?epreuve=…`, `/api/public/…` pour un visiteur) et
 * opposable (403) : l'écran le lit, il ne le déduit jamais du rang.
 *
 * Mode guest (règle du 2026-08-16, elle REMPLACE la vitrine intégrale) :
 * l'examen 1 se joue **sans compte**, en anonyme, par la voie publique
 * (`publicAttemptApi.startDemo` → attempt `user NULL` côté backend, exactement
 * le montage de la série 1). Un créneau verrouillé ouvre la GuestGateSheet.
 */
export default function TcfModuleExamsPage() {
  const params = useParams<{ code: string }>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const { status } = useAuth();
  const isGuest = status === "guest";

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [guestGateOpen, setGuestGateOpen] = useState(false);
  const [introOpen, setIntroOpen] = useState(false);
  const [pendingSlot, setPendingSlot] = useState(1);

  const questionType = config?.questionType;

  useEffect(() => {
    if (status !== "authenticated" || !questionType) return;
    let cancelled = false;
    attemptApi
      .listMine({ type: "MOCK_EXAM", module: "TCF", moduleExamQuestionType: questionType, limit: 30 })
      .then((list) => {
        if (cancelled) return;
        setExams(list.filter((a) => a.finishedAt));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, questionType]);

  // Grille indexée par slot : refaire l'examen N met à jour la case N.
  const { bySlot, latest, doneCount } = useMemo(() => examSlotGrid(exams, SLOTS), [exams]);
  // 🛑 Le verrou est SERVI créneau par créneau (compte ou visiteur) : l'écran
  // ne le déduit jamais du rang. Un créneau verrouillé ouvre l'offre (compte)
  // ou l'inscription (visiteur) via `onLocked`.
  const slotLocks = useExamSlotLocks(config?.epreuve ?? null);

  function requestStart(slot: number) {
    if (starting) return;
    setError(null);
    setPendingSlot(slot);
    setIntroOpen(true);
  }

  async function launch() {
    if (starting || !questionType) return;
    setError(null);
    setStarting(true);
    try {
      const body = {
        type: "MOCK_EXAM" as const,
        module: "TCF" as const,
        moduleExamQuestionType: questionType,
        slotNumber: pendingSlot,
      };
      // Visiteur : voie publique (attempt anonyme), jamais l'API authentifiée
      // — même montage que la série 1 de /entrainement/tcf/[code]/[level].
      const a = isGuest
        ? await publicAttemptApi.startDemo(body)
        : await attemptApi.start(body);
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => {
          setIntroOpen(false);
          if (isGuest) setGuestGateOpen(true);
          else setPaywallOpen(true);
        },
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen.",
      });
      setStarting(false);
    }
  }

  const done = Math.min(doneCount, SLOTS);
  const { best, bestLevel } = useMemo(() => {
    let bestExam: AttemptSummaryResponse | null = null;
    for (const e of latest) {
      if (!bestExam || (e.score ?? 0) > (bestExam.score ?? 0)) bestExam = e;
    }
    return {
      // 🛑 Score de PROGRESSION (100-499) quand le backend l'a calibré,
      // brut sinon. Ce n'est pas un score TCF.
      best: bestExam
        ? bestExam.calibratedScore != null
          ? `${bestExam.calibratedScore}/499`
          : `${bestExam.score ?? 0}/${bestExam.totalQuestions ?? "—"}`
        : "—",
      bestLevel: bestExam?.cecrlLevel ?? null,
    };
  }, [latest]);

  // 🛑 La copie du sas vit dans `lib/exam-intro.ts` depuis le 2026-09-13 : le
  // diagnostic TCF annonce ses sections avec EXACTEMENT la même, une section
  // etant un examen blanc de son épreuve.
  const intro = config
    ? comprehensionExamIntro(code === "co" ? "CO" : "CE", "25", config.duration)
    : null;
  const introFacts: ExamFact[] = intro?.facts ?? [];
  const introTips = intro?.tips ?? [];

  if (status === "loading") return <div className={ds.gate} />;
  if (!config) {
    return (
      <DualChromeShell>
        <main className={detail.wrap}>
          <p className={detail.empty}>Épreuve TCF inconnue.</p>
          <Link href="/entrainement?module=TCF" className={detail.back}>
            ← Retour à l&apos;entraînement TCF
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <DetailShell
        backHref={`/entrainement/tcf/${code}`}
        backLabel={config.title}
        title="Examens blancs"
        subtitle={`${config.title} · TCF IRN`}
        notice={code === "structure" ? <ComplementaryNotice /> : undefined}
      >
        <div className={detail.statCards}>
          <DetailStatCard
            icon={<Trophy size={20} />}
            tone="blue"
            value={isGuest ? "—" : `${done}/${SLOTS}`}
            label="Examens passés"
            sub={isGuest ? "compte requis pour l'historique" : "dans cette catégorie"}
          />
          <DetailStatCard
            icon={<Flame size={20} />}
            tone="red"
            value={best}
            label="Meilleur score"
            sub="sur cette épreuve"
          />
          <DetailStatCard
            icon={<GraduationCap size={20} />}
            tone="green"
            value={bestLevel ? niveauCecrlLabel(bestLevel) : "—"}
            label="Niveau estimé"
            sub="sur votre meilleur essai"
          />
        </div>

        {error && <div className={detail.error}>{error}</div>}

        <ExamsGrid
          count={SLOTS}
          exams={bySlot}
          slotLocks={slotLocks}
          lockedLabel={isGuest ? "Compte gratuit" : undefined}
          starting={starting}
          onStart={requestStart}
          onLocked={() => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true))}
        />
        <ExamIntroSheet
          open={introOpen}
          eyebrow={`Examen blanc · ${config.title}`}
          title={`${config.title} en conditions réelles`}
          subtitle="Avant de commencer, voici comment se déroule l'épreuve."
          facts={introFacts}
          tips={introTips}
          loading={starting}
          error={error}
          onConfirm={() => void launch()}
          onClose={() => setIntroOpen(false)}
        />
        <PaywallSheet ctaLocation="MOCK_EXAM" screen="examens_tcf" open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="Le premier examen blanc de chaque épreuve est offert sans compte. Pour passer les suivants et retrouver vos scores, créez un compte gratuit."
        />
      </DetailShell>
    </DualChromeShell>
  );
}
