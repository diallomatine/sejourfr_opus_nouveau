"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Flame, GraduationCap, LayoutGrid, Target, Trophy } from "lucide-react";
import { ApiException, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  cecrlIndex,
  type NiveauCecrl,
  niveauCecrlLabel,
  type ProductionSubmissionDto,
  resolveTcfLevel,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import {
  DetailShell,
  DetailStatCard,
  type ExamSlotData,
  ExamsGrid,
} from "@/app/_components/hub/DetailParts";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { ExamIntroSheet } from "@/app/_components/hub/ExamIntroSheet";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";

const SLOTS = 20;

/** Session d'examen blanc production : note moyenne /20 + CECRL plancher. */
interface PastSession {
  attemptId: string;
  date: string;
  avgNote: number | null;
  floorLevel: NiveauCecrl | null;
}

/**
 * Examens blancs d'une épreuve productive (EE/EO) — maquette sejour_fr.html :
 * 3 stat cards (passés / meilleure note / niveau estimé) + grille de 20
 * examens (3 tâches enchaînées, évaluation IA). Comptes gratuits : examen 1
 * offert ; le refaire consomme les essais d'entraînement EE/EO restants
 * (avertissement avant) ; au-delà (et examens 2-20) → abonnés Intégral.
 * Rapport → session de l'examen, Refaire → nouvelle session.
 */
export function ProductionExams({ config }: { config: ProductionConfig }) {
  const router = useRouter();
  const { user, status } = useAuth();
  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const level = resolveTcfLevel(user);

  const [past, setPast] = useState<PastSession[]>([]);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [retakeWarningOpen, setRetakeWarningOpen] = useState(false);
  const [introOpen, setIntroOpen] = useState(false);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    productionApi
      .listMine({ epreuve: config.epreuve, limit: 100 })
      .then((list) => {
        if (cancelled) return;
        // Une session d'examen = un attempt portant ≥ 2 soumissions (les
        // entraînements par tâche n'en portent qu'une).
        const byAttempt = new Map<string, ProductionSubmissionDto[]>();
        for (const s of list) {
          const arr = byAttempt.get(s.attemptId) ?? [];
          arr.push(s);
          byAttempt.set(s.attemptId, arr);
        }
        const sessions: PastSession[] = [];
        for (const [attemptId, items] of byAttempt) {
          if (items.length < 2) continue;
          const date = items
            .map((i) => i.submittedAt)
            .sort((a, b) => a.localeCompare(b))[0];
          const notes = items
            .map((i) => i.evaluation?.noteSurVingt)
            .filter((v): v is number => v != null);
          const levels = items
            .map((i) => i.evaluation?.niveauCecrl)
            .filter((v): v is NiveauCecrl => v != null);
          sessions.push({
            attemptId,
            date,
            avgNote: notes.length
              ? Math.round(notes.reduce((s, v) => s + v, 0) / notes.length)
              : null,
            // Plancher CECRL : règle préfecture — le niveau global d'une
            // session productive est le plus bas de ses tâches.
            floorLevel: levels.length
              ? levels.reduce((min, l) => (cecrlIndex(l) < cecrlIndex(min) ? l : min))
              : null,
          });
        }
        sessions.sort((a, b) => a.date.localeCompare(b.date));
        setPast(sessions);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, config.epreuve]);

  function requestStart() {
    if (starting) return;
    setError(null);
    setIntroOpen(true);
  }

  function start() {
    if (starting) return;
    setIntroOpen(false);
    // Gratuit : examen 1 offert. Le refaire est possible mais consomme les
    // essais d'entraînement EE/EO restants → avertissement avant. Le backend
    // tranche (403 au-delà de 2 sessions) ; `past` ne voit que les sessions
    // soumises, le compteur autoritaire vit côté serveur.
    if (!isPremium && past.length >= 1) {
      setRetakeWarningOpen(true);
      return;
    }
    void launch();
  }

  async function launch() {
    setRetakeWarningOpen(false);
    setError(null);
    setStarting(true);
    try {
      const attempt = await productionApi.startAttempt({
        module: "TCF",
        epreuve: config.epreuve,
        exam: true,
      });
      router.push(`${config.base}/session/${attempt.id}`);
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  const slotData: ExamSlotData[] = useMemo(
    () =>
      past.map((s) => ({
        id: s.attemptId,
        score: s.avgNote,
        totalQuestions: s.avgNote != null ? 20 : null,
      })),
    [past],
  );

  const done = Math.min(past.length, SLOTS);
  const { bestNote, bestLevel } = useMemo(() => {
    let best: PastSession | null = null;
    for (const s of past) {
      if (s.avgNote == null) continue;
      if (!best || s.avgNote > (best.avgNote ?? -1)) best = s;
    }
    return {
      bestNote: best?.avgNote ?? null,
      bestLevel: best?.floorLevel ?? null,
    };
  }, [past]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/examens`} />;

  return (
    <DualChromeShell>
      <DetailShell
        backHref={config.base}
        backLabel={config.label}
        eyebrowIcon={<Target size={18} strokeWidth={2} />}
        eyebrow={config.label}
        title="Examens blancs"
        subtitle={`${SLOTS} examens blancs de 3 tâches (${config.examMinutes}, niveau ${level}), évalués par l'IA avec une note /20 et un niveau CECRL plancher. Choisissez-en un et retrouvez votre dernier score.`}
        action={
          <Link href={config.base} className={detail.headBtn}>
            <LayoutGrid size={17} strokeWidth={1.7} aria-hidden />
            Mode entraînement
          </Link>
        }
      >
        <div className={detail.statCards}>
          <DetailStatCard
            icon={<Trophy size={20} />}
            tone="blue"
            value={`${done}/${SLOTS}`}
            label="Examens passés"
            sub="dans cette épreuve"
          />
          <DetailStatCard
            icon={<Flame size={20} />}
            tone="red"
            value={bestNote != null ? `${bestNote}/20` : "—"}
            label="Meilleure note"
            sub="moyenne des 3 tâches"
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
          exams={slotData}
          premium={isPremium}
          freeSlots={1}
          starting={starting}
          itemLabel="Examen"
          reportPath={(attemptId) => `${config.base}/session/${attemptId}`}
          onStart={requestStart}
          onLocked={() => setPaywallOpen(true)}
        />

        <ExamIntroSheet
          open={introOpen}
          eyebrow={`Examen blanc · ${config.label}`}
          title={`${config.label} en conditions réelles`}
          subtitle="Avant de commencer, voici comment se déroule l'examen."
          facts={[
            { label: "tâches enchaînées", value: "3" },
            { label: `niveau ${level}`, value: config.examMinutes },
            { label: "note + niveau CECRL", value: "/20" },
          ]}
          tips={[
            config.mode === "audio"
              ? "Autorisez le micro : chaque tâche s'enregistre, comme le jour J."
              : "Vous rédigez directement les 3 productions, un brouillon est sauvegardé.",
            "Les 3 tâches sont évaluées par l'IA après l'examen.",
            "Le niveau final est le plancher de vos 3 tâches (règle TCF IRN).",
          ]}
          loading={starting}
          error={error}
          onConfirm={start}
          onClose={() => setIntroOpen(false)}
        />

        <ConfirmSheet
          open={retakeWarningOpen}
          tone="warning"
          title="Refaire l'examen 1 ?"
          message="Refaire cet examen blanc utilisera vos essais gratuits d'entraînement EE et EO : après cette session, les tâches d'entraînement seront réservées aux abonnés Intégral."
          confirmLabel="Refaire l'examen"
          cancelLabel="Annuler"
          onConfirm={() => void launch()}
          onClose={() => setRetakeWarningOpen(false)}
        />

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez les examens blancs ${config.shortLabel}`}
          message="Le premier examen blanc (3 tâches + évaluation IA) est offert. Les suivants sont réservés aux abonnés Intégral, qui débloque aussi tout le TCF, le civique et les examens blancs illimités."
        />
      </DetailShell>
    </DualChromeShell>
  );
}
