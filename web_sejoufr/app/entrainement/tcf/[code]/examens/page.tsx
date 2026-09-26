"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Flame, GraduationCap, Trophy } from "lucide-react";
import { attemptApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  type EpreuveType,
  niveauCecrlLabel,
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
import { useMockExamLauncher } from "@/app/_components/hub/MockExamLauncher";
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
    questionType: "CO" as const,
    epreuve: "TCF_CO" as EpreuveType,
    title: "Compréhension orale",
    duration: plannedEpreuveLabel("TCF_CO"),
  },
  ce: {
    questionType: "CE" as const,
    epreuve: "TCF_CE" as EpreuveType,
    title: "Compréhension écrite",
    duration: plannedEpreuveLabel("TCF_CE"),
  },
  structure: {
    questionType: "STRUCTURE" as const,
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
  const launchExam = useMockExamLauncher();
  const { status } = useAuth();
  const isGuest = status === "guest";

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [guestGateOpen, setGuestGateOpen] = useState(false);

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

  /** 🛑 Le lancement partagé par tous les points d'entrée (Plan, Accueil,
   *  Réviser…) : feuille d'information, puis démarrage au clic — le chrono
   *  ne part qu'à ce moment-là. Visiteur : voie publique (attempt anonyme). */
  function requestStart(slot: number) {
    if (!config) return;
    launchExam({
      kind: "COMPREHENSION",
      questionType: config.questionType,
      title: config.title,
      durationLabel: config.duration,
      slotNumber: slot,
      guest: isGuest,
      onPaywall: () => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true)),
    });
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

        <ExamsGrid
          count={SLOTS}
          exams={bySlot}
          slotLocks={slotLocks}
          lockedLabel={isGuest ? "Compte gratuit" : undefined}
          starting={false}
          onStart={requestStart}
          onLocked={() => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true))}
        />
        <PaywallSheet ctaLocation="MOCK_EXAM" screen="examens_tcf" open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="Le 1ᵉʳ examen blanc de chaque épreuve est offert sans compte. Les suivants font partie du pass Intégral : créez d'abord votre compte gratuit, qui garde vos scores."
        />
      </DetailShell>
    </DualChromeShell>
  );
}
