"use client";

import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Check, Lock } from "lucide-react";
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
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { ExamIntroSheet } from "@/app/_components/hub/ExamIntroSheet";
import {
  SectionHead,
  SkillBadge,
  SkillHero,
  SkillNotice,
  SkillShell,
  SkillStats,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import { type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL } from "./config";

const SLOTS = 10;
/** Examen 1 offert à tous les comptes (règle backend `ProductionAccessService`). */
const FREE_SLOTS = 1;

/** Bande de difficulté par slot (composition déterministe backend) :
 *  1-3 = A2 facile, 4-6 = B1 moyen, 7-10 = B2 difficile. */
function slotBand(slot: number): { label: string; niveau: string } {
  if (slot <= 3) return { label: "Facile · A2", niveau: "A2" };
  if (slot <= 6) return { label: "Moyen · B1", niveau: "B1" };
  return { label: "Difficile · B2", niveau: "B2" };
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
 * Examens blancs d'une épreuve productive (EE/EO) — mode « Examens » de la
 * maquette : hero de parcours, trois indicateurs, puis une grille de packs
 * d'examen (titre, palier, note obtenue, actions Rapport / Démarrer).
 *
 * Comptes gratuits : examen 1 offert ; le refaire consomme les essais
 * d'entraînement EE/EO restants (avertissement avant) ; au-delà (et examens
 * 2-10) → abonnés Intégral.
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
        for (const sub of list) {
          const arr = byAttempt.get(sub.attemptId) ?? [];
          arr.push(sub);
          byAttempt.set(sub.attemptId, arr);
        }
        const drafts: { attemptId: string; date: string; avgNote: number | null }[] = [];
        for (const [attemptId, items] of byAttempt) {
          if (items.length < 2) continue;
          const date = items.map((i) => i.submittedAt).sort((a, b) => a.localeCompare(b))[0];
          const notes = items
            .map((i) => i.evaluation?.noteSurVingt)
            .filter((v): v is number => v != null);
          drafts.push({
            attemptId,
            date,
            // Une décimale, comme les notes elles-mêmes : arrondir à l'entier
            // afficherait 13 là où la session vaut 12,5.
            avgNote: notes.length
              ? Math.round((notes.reduce((acc, v) => acc + v, 0) / notes.length) * 10) / 10
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
  const bySlot = useMemo(() => {
    const m = new Map<number, PastSession>();
    for (const sess of past) {
      const slot =
        sess.slotNumber != null && sess.slotNumber >= 1 && sess.slotNumber <= SLOTS
          ? sess.slotNumber
          : 1;
      const prev = m.get(slot);
      if (!prev || sess.date.localeCompare(prev.date) > 0) m.set(slot, sess);
    }
    return m;
  }, [past]);

  const done = bySlot.size;
  const bestNote = useMemo(() => {
    let best: number | null = null;
    for (const sess of past) {
      if (sess.avgNote == null) continue;
      if (best === null || sess.avgNote > best) best = sess.avgNote;
    }
    return best;
  }, [past]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/examens`} />;

  return (
    <DualChromeShell>
      <SkillShell
        config={config}
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        mode="examens"
      >
        <SkillHero
          eyebrow={`${config.label} · Examens blancs`}
          title="Examens blancs"
          text={`Trois tâches enchaînées en ${config.examMinutes}, en conditions réelles, puis une évaluation IA et un niveau CECRL.`}
          level={null}
          attempted={done}
          total={SLOTS}
          percent={Math.round((done / SLOTS) * 100)}
          unit="examens"
        />

        <SkillStats
          stats={[
            { value: `${done}/${SLOTS}`, label: "Examens passés", sub: "dans cette épreuve" },
            {
              value: bestNote != null ? `${formatNoteSur20(bestNote)}/20` : "—",
              label: "Meilleure note",
              sub: "moyenne des 3 tâches",
            },
            {
              value: bestLevel ? niveauCecrlLabel(bestLevel) : "—",
              label: "Niveau estimé",
              sub: "sur votre meilleur essai",
            },
          ]}
        />

        <SectionHead
          title="Choisissez un examen"
          text="La difficulté monte avec le numéro : 1-3 niveau A2, 4-6 niveau B1, 7-10 niveau B2."
        />

        {error && <div className={s.error}>{error}</div>}

        <div className={s.packGrid}>
          {Array.from({ length: SLOTS }, (_, i) => i + 1).map((slot) => {
            const sess = bySlot.get(slot);
            const locked = !isPremium && slot > FREE_SLOTS;
            const band = slotBand(slot);
            return (
              <article key={slot} className={`${s.card} ${s.pack}`}>
                <div className={s.packTop}>
                  <div>
                    <h3 className={s.packTitle}>Examen {slot}</h3>
                    <p className={s.packText}>3 tâches · {config.examMinutes}</p>
                  </div>
                  <SkillBadge tone="level">{band.niveau}</SkillBadge>
                </div>

                <div className={s.chips}>
                  {sess ? (
                    <SkillBadge
                      tone="treated"
                      icon={<Check size={11} strokeWidth={2.6} aria-hidden />}
                    >
                      {sess.avgNote != null
                        ? `${formatNoteSur20(sess.avgNote)}/20`
                        : "Passé"}
                    </SkillBadge>
                  ) : locked ? (
                    <SkillBadge tone="todo" icon={<Lock size={10} aria-hidden />}>
                      Premium
                    </SkillBadge>
                  ) : (
                    <SkillBadge tone="todo">À faire</SkillBadge>
                  )}
                  <span className={s.chip}>{band.label}</span>
                </div>

                <div className={s.packActions}>
                  {sess && (
                    <button
                      type="button"
                      className={s.packBtn}
                      onClick={() => router.push(`${config.base}/session/${sess.attemptId}`)}
                    >
                      Rapport
                    </button>
                  )}
                  <button
                    type="button"
                    className={`${s.packBtn} ${locked ? "" : s.packBtnStart}`}
                    disabled={starting}
                    onClick={() => (locked ? setPaywallOpen(true) : requestStart(slot))}
                  >
                    {locked ? "Premium" : sess ? "Refaire" : "Démarrer"}
                  </button>
                </div>
              </article>
            );
          })}
        </div>

        <SkillNotice title="Ce que mesure un examen blanc">
          Le niveau final est le plancher de vos trois tâches, comme au TCF IRN : il faut
          tenir le palier partout, pas seulement sur la tâche la plus facile.
        </SkillNotice>

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
      </SkillShell>
    </DualChromeShell>
  );
}
