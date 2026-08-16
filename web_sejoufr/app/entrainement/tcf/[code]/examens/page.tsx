"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Flame, GraduationCap, LayoutGrid, Target, Trophy } from "lucide-react";
import { attemptApi, publicAttemptApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  niveauCecrlLabel,
  type QuestionType,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, DetailStatCard, ExamsGrid } from "@/app/_components/hub/DetailParts";
import { ExamIntroSheet, type ExamFact } from "@/app/_components/hub/ExamIntroSheet";
import { examSlotGrid } from "@/lib/exam-slots";
import { plannedEpreuveLabel } from "@/lib/exam-durations";
import detail from "@/app/_components/hub/detail.module.css";

const SLOTS = 20;

/**
 * Examens ouverts sans abonnement — et, depuis le 2026-08-16, sans compte du
 * tout. Miroir de `AttemptService.enforceMockExamSlotAccess` (slot 1 offert et
 * rejouable) et de `AttemptService.startGuestModuleExam` (slot 1 seulement).
 */
const FREE_SLOTS = 1;

// CO et CE lisent la table de référence partagée (`lib/exam-durations.ts`) :
// la même épreuve doit annoncer la même durée jouée seule et dans un examen
// complet — c'est exactement là que la CE avait divergé (30 vs 35 min).
const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    title: "Compréhension orale",
    duration: plannedEpreuveLabel("TCF_CO"),
  },
  ce: {
    questionType: "CE" as QuestionType,
    title: "Compréhension écrite",
    duration: plannedEpreuveLabel("TCF_CE"),
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
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
 * grille de 20 examens. Examen 1 gratuit, 2+ premium.
 *
 * Mode guest (règle du 2026-08-16, elle REMPLACE la vitrine intégrale) :
 * l'examen 1 se joue **sans compte**, en anonyme, par la voie publique
 * (`publicAttemptApi.startDemo` → attempt `user NULL` côté backend, exactement
 * le montage de la série 1). Les examens 2 à 20 ouvrent la GuestGateSheet.
 * Le backend applique le même verrou (403 au-delà du slot 1).
 */
export default function TcfModuleExamsPage() {
  const params = useParams<{ code: string }>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const { user, status } = useAuth();
  const isGuest = status === "guest";
  const isPremium = user ? canAccessModule(user, "TCF") : false;

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

  function requestStart(slot: number) {
    if (starting) return;
    // Un visiteur n'a droit qu'à l'examen 1 (même verrou que ExamsGrid, et
    // que le backend). Au-delà : inscription.
    if (isGuest && slot > FREE_SLOTS) {
      setGuestGateOpen(true);
      return;
    }
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
      // Échelle TCF (100-499) quand le backend a calibré, brut sinon.
      best: bestExam
        ? bestExam.calibratedScore != null
          ? `${bestExam.calibratedScore}/499`
          : `${bestExam.score ?? 0}/${bestExam.totalQuestions ?? "—"}`
        : "—",
      bestLevel: bestExam?.cecrlLevel ?? null,
    };
  }, [latest]);

  const introFacts: ExamFact[] = config
    ? [
        { label: "questions (A2→B2)", value: "25" },
        { label: "en conditions réelles", value: config.duration },
        // Barème du relevé TCF. Le /50 annoncé ici était le score pondéré
        // interne, que le candidat ne voit nulle part ailleurs.
        { label: "score + niveau CECRL", value: "/499" },
      ]
    : [];
  const introTips =
    code === "co"
      ? [
          "L'audio se lance seul et ne se joue qu'une seule fois, comme le jour J — prévoyez un casque.",
          "Pas de retour en arrière sur les questions d'écoute.",
          "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
        ]
      : [
          "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
          "Le chronomètre tourne et l'examen se termine automatiquement à la fin du temps.",
          "Vous pouvez naviguer librement entre les questions.",
        ];

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
        backLabel="TCF IRN"
        eyebrowIcon={<Target size={18} strokeWidth={2} />}
        eyebrow={config.title}
        title="Examens blancs"
        subtitle={`${SLOTS} examens blancs de 25 questions (${config.duration}), dans les conditions de l'épreuve. Choisissez-en un et retrouvez votre dernier score.`}
        action={
          <Link href={`/entrainement/tcf/${code}`} className={detail.headBtn}>
            <LayoutGrid size={17} strokeWidth={1.7} aria-hidden />
            Mode entraînement
          </Link>
        }
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
          premium={isPremium}
          freeSlots={FREE_SLOTS}
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
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="Le premier examen blanc de chaque épreuve est offert sans compte. Pour passer les suivants et retrouver vos scores, créez un compte gratuit."
        />
      </DetailShell>
    </DualChromeShell>
  );
}
