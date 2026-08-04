"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Flame, GraduationCap, LayoutGrid, Target, Trophy } from "lucide-react";
import { productionApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  cecrlIndex,
  formatNoteSur20,
  type NiveauCecrl,
  niveauCecrlLabel,
  type ProductionSubmissionDto,
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
import prod from "./production.module.css";

const SLOTS = 10;

/** Bande de difficulté par slot (composition déterministe backend) :
 *  1-3 = A2 facile, 4-6 = B1 moyen, 7-10 = B2 difficile. */
function slotBand(slot: number): { label: string; tone: "green" | "amber" | "red" } {
  if (slot <= 3) return { label: "Facile · A2", tone: "green" };
  if (slot <= 6) return { label: "Moyen · B1", tone: "amber" };
  return { label: "Difficile · B2", tone: "red" };
}

/** Session d'examen blanc production : note moyenne /20 + slot UI (depuis le
 *  bilan backend). Le niveau CECRL n'est plus dérivé localement. */
interface PastSession {
  attemptId: string;
  date: string;
  avgNote: number | null;
  slotNumber: number | null;
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

  const [past, setPast] = useState<PastSession[]>([]);
  const [bestLevel, setBestLevel] = useState<NiveauCecrl | null>(null);
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
      .then(async (list) => {
        if (cancelled) return;
        // Une session d'examen = un attempt portant ≥ 2 soumissions (les
        // entraînements par tâche n'en portent qu'une).
        const byAttempt = new Map<string, ProductionSubmissionDto[]>();
        for (const s of list) {
          const arr = byAttempt.get(s.attemptId) ?? [];
          arr.push(s);
          byAttempt.set(s.attemptId, arr);
        }
        const drafts: { attemptId: string; date: string; avgNote: number | null }[] = [];
        for (const [attemptId, items] of byAttempt) {
          if (items.length < 2) continue;
          const date = items
            .map((i) => i.submittedAt)
            .sort((a, b) => a.localeCompare(b))[0];
          const notes = items
            .map((i) => i.evaluation?.noteSurVingt)
            .filter((v): v is number => v != null);
          drafts.push({
            attemptId,
            date,
            // Une décimale, comme les notes elles-mêmes : arrondir à l'entier
            // afficherait 13 là où la session vaut 12,5.
            avgNote: notes.length
              ? Math.round((notes.reduce((s, v) => s + v, 0) / notes.length) * 10) / 10
              : null,
          });
        }

        // Le slot UI + le niveau global viennent du bilan backend (déjà fetché
        // ici pour la stat « niveau estimé »). On range chaque session sur son
        // vrai slot ; un slot null (anciennes sessions) retombe sur le slot 1.
        const bilans = await Promise.all(
          drafts.map((d) => productionApi.getBilan(d.attemptId).catch(() => null)),
        );
        if (cancelled) return;
        const sessions: PastSession[] = drafts.map((d, i) => ({
          ...d,
          slotNumber: bilans[i]?.slotNumber ?? null,
        }));
        sessions.sort((a, b) => a.date.localeCompare(b.date));
        setPast(sessions);

        let top: NiveauCecrl | null = null;
        for (const b of bilans) {
          const niv = b?.niveauGlobal ?? null;
          if (!niv) continue;
          if (top === null || cecrlIndex(niv) > cecrlIndex(top)) top = niv;
        }
        setBestLevel(top);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, config.epreuve]);

  /** Slot ciblé par le lancement en cours (composition déterministe backend). */
  const [pendingSlot, setPendingSlot] = useState(1);

  function requestStart(slot: number) {
    if (starting) return;
    setError(null);
    setPendingSlot(slot);
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
        slotNumber: pendingSlot,
      });
      router.push(`${config.base}/session/${attempt.id}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => setPaywallOpen(true),
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen.",
      });
      setStarting(false);
    }
  }

  // Grille indexée par slot : case i = examen du slot i+1. On range chaque
  // session sur son `slotNumber` (null → slot 1, anciennes sessions), en gardant
  // la plus récente par slot. Refaire l'examen N met à jour la case N.
  const slotData: (ExamSlotData | null)[] = useMemo(() => {
    const bySlot = new Map<number, PastSession>();
    for (const s of past) {
      const slot = s.slotNumber != null && s.slotNumber >= 1 && s.slotNumber <= SLOTS ? s.slotNumber : 1;
      const prev = bySlot.get(slot);
      if (!prev || s.date.localeCompare(prev.date) > 0) bySlot.set(slot, s);
    }
    return Array.from({ length: SLOTS }, (_, i) => {
      const s = bySlot.get(i + 1);
      return s
        ? { id: s.attemptId, score: s.avgNote, totalQuestions: s.avgNote != null ? 20 : null }
        : null;
    });
  }, [past]);

  const done = slotData.filter(Boolean).length;
  const bestNote = useMemo(() => {
    let best: number | null = null;
    for (const s of past) {
      if (s.avgNote == null) continue;
      if (best === null || s.avgNote > best) best = s.avgNote;
    }
    return best;
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
        subtitle={`${SLOTS} examens blancs de 3 tâches (${config.examMinutes}), à difficulté progressive : 1-3 niveau A2, 4-6 niveau B1, 7-10 niveau B2. Chacun est évalué par l'IA avec une note /20 et un niveau CECRL plancher.`}
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
            value={bestNote != null ? `${formatNoteSur20(bestNote)}/20` : "—"}
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

        <div className={prod.bandLegend} aria-hidden>
          {([1, 4, 7] as const).map((firstSlot) => {
            const band = slotBand(firstSlot);
            return (
              <span key={firstSlot} className={prod.bandChip} data-tone={band.tone}>
                {band.label}
              </span>
            );
          })}
        </div>

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
          eyebrow={`Examen blanc ${pendingSlot} · ${config.label}`}
          title={`${config.label} en conditions réelles`}
          subtitle="Avant de commencer, voici comment se déroule l'examen."
          facts={[
            { label: "tâches enchaînées", value: "3" },
            { label: slotBand(pendingSlot).label, value: config.examMinutes },
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
