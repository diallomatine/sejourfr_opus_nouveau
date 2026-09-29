"use client";

import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Check, Lock } from "lucide-react";
import { productionApi } from "@/lib/api";
import {
  epreuveSubjectProgress,
  examDrafts,
  loadBilan,
  loadEpreuveTasks,
  loadMySubmissions,
  productionMineKey,
  productionTasksKey,
} from "@/lib/production-catalog";
import { useAuth } from "@/lib/auth-context";
import { useCachedData } from "@/lib/use-cached-data";
import { useExamSlotLocks } from "@/lib/use-exam-slot-locks";
import {
  canAccessModule,
  cecrlIndex,
  formatNoteSur20,
  type NiveauCecrl,
  niveauCecrlLabel,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { useMockExamLauncher } from "@/app/_components/hub/MockExamLauncher";
import {
  ExamTrail,
  ParcoursHero,
  SectionHead,
  SkillBadge,
  SkillNotice,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import {
  averageExamNote,
  PRODUCTION_EXAM_SLOTS,
  useParcoursLevel,
} from "./parcours";
import s from "@/app/_components/skill-ui/skill.module.css";
import { type ProductionConfig } from "./config";

const SLOTS = PRODUCTION_EXAM_SLOTS;

/**
 * Bande de difficulté **du sujet**, par slot — composition déterministe côté
 * backend : 1-3 = A2 facile, 4-6 = B1 moyen, 7-10 = B2 difficile.
 *
 * Ce n'est **pas** un niveau attribué au candidat, et §25 bis.6 ne s'y applique
 * pas : c'est l'étiquette du contenu proposé, comme « série de niveau A2 ». Un
 * verdict sur le candidat, lui, ne s'affiche que si le serveur envoie
 * `confirmedLevel` — jamais déduit d'un pourcentage ni d'un numéro de slot.
 */
function slotBand(slot: number): { label: string; niveau: string } {
  if (slot <= 3) return { label: "Facile · A2", niveau: "A2" }; // t36-ok: niveau du sujet, pas du candidat
  if (slot <= 6) return { label: "Moyen · B1", niveau: "B1" }; // t36-ok: niveau du sujet, pas du candidat
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
  const level = useParcoursLevel();
  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const slotLocks = useExamSlotLocks(config.epreuve);

  const launchExam = useMockExamLauncher();

  const [past, setPast] = useState<PastSession[]>([]);
  const [bestLevel, setBestLevel] = useState<NiveauCecrl | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [retakeWarningOpen, setRetakeWarningOpen] = useState(false);

  // Historique de l'épreuve : même entrée de cache que l'écran des sujets — un
  // seul appel sert les deux — et invalidée à chaque soumission (`lib/api.ts`).
  const minesQuery = useCachedData(
    status === "authenticated" ? productionMineKey(config.epreuve) : null,
    () => loadMySubmissions(productionApi, config.epreuve),
  );
  // Une session d'examen = un attempt portant ≥ 2 soumissions (les
  // entraînements par tâche n'en portent qu'une).
  const drafts = useMemo(() => examDrafts(minesQuery.data), [minesQuery.data]);

  // Catalogue de l'épreuve : même entrée de cache que la liste des tâches et
  // celle des sujets — il n'y a donc pas d'appel de plus pour le héros.
  const tasksQuery = useCachedData(
    status === "authenticated" ? productionTasksKey(config.epreuve) : null,
    () => loadEpreuveTasks(productionApi, config.epreuve),
  );
  const subjects = epreuveSubjectProgress(tasksQuery.data, minesQuery.data);
  const avgNote = averageExamNote(drafts);

  useEffect(() => {
    if (drafts.length === 0) return;
    let cancelled = false;
    // Le slot UI + le niveau global viennent du bilan backend. Un bilan
    // **terminé** est mémorisé (une session close ne bouge plus) ; un bilan dont
    // l'IA évalue encore une tâche est redemandé à chaque visite.
    void Promise.all(
      drafts.map((d) => loadBilan(productionApi, d.attemptId).catch(() => null)),
    ).then((bilans) => {
      if (cancelled) return;
      const sessions: PastSession[] = drafts.map((d, i) => ({
        ...d,
        slotNumber: bilans[i]?.slotNumber ?? null,
      }));
      setPast(sessions);

      let top: NiveauCecrl | null = null;
      for (const b of bilans) {
        const niv = b?.niveauGlobal ?? null;
        if (!niv) continue;
        if (top === null || cecrlIndex(niv) > cecrlIndex(top)) top = niv;
      }
      setBestLevel(top);
    });
    return () => {
      cancelled = true;
    };
  }, [drafts]);

  /** Slot ciblé par le lancement en cours (composition déterministe backend). */
  const [pendingSlot, setPendingSlot] = useState(1);

  function requestStart(slot: number) {
    setPendingSlot(slot);
    // Gratuit : examen 1 offert. Le repasser se signale AVANT la feuille
    // d'information — le backend tranche (403) ; `past` ne voit que les
    // sessions soumises, le compteur autoritaire vit côté serveur.
    if (!isPremium && past.length >= 1) {
      setRetakeWarningOpen(true);
      return;
    }
    launch(slot);
  }

  /** 🛑 Le lancement partagé par tous les points d'entrée : feuille
   *  d'information, puis démarrage au clic « Commencer maintenant ». */
  function launch(slot: number) {
    setRetakeWarningOpen(false);
    launchExam({
      kind: "PRODUCTION",
      epreuve: config.epreuve,
      slotNumber: slot,
      onPaywall: () => setPaywallOpen(true),
    });
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
  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/examens`} />;

  return (
    <DualChromeShell>
      <SkillShell
        backHref={config.base}
        backLabel={config.label}
        title="Examens blancs"
        meta={`${config.label} · 3 tâches enchaînées`}
        level={level}
      >
        {/* Le héros du parcours reste ici — c'est le seul écran de l'épreuve où
            un score moyen /20 a un sens (une tâche isolée n'a pas de note). */}
        <ParcoursHero
          percent={subjects.total > 0 ? (subjects.done / subjects.total) * 100 : 0}
          stats={[
            {
              value: avgNote == null ? "—" : formatNoteSur20(avgNote),
              label: "Score moyen",
              unit: "/20",
            },
            {value: String(drafts.length), label: "Examens blancs", unit: `/${SLOTS}`},
            {
              value: String(subjects.done),
              label: "Sujets traités",
              unit: `/${subjects.total}`,
            },
          ]}
        />

        {/* Le score moyen et le décompte d'examens vivent désormais dans le
            héros du parcours : les répéter ici en cartes de statistiques disait
            deux fois la même chose sur la même page. */}
        <ExamTrail
          done={done}
          total={SLOTS}
          note={bestLevel ? `Niveau estimé · ${niveauCecrlLabel(bestLevel)}` : null}
        />

        <SectionHead title="Choisissez un examen" />

        <div className={s.packGrid}>
          {Array.from({ length: SLOTS }, (_, i) => i + 1).map((slot) => {
            const sess = bySlot.get(slot);
            // 🛑 Verrou SERVI (`ProductionAccessService.isProductionExamSlotLocked`,
            // la règle que le démarrage oppose en 403) : jamais déduit du rang.
            const locked = slotLocks[slot - 1] ?? true;
            const band = slotBand(slot);
            return (
              <article key={slot} className={`${s.card} ${s.pack}`}>
                <div className={s.packTop}>
                  <div>
                    <h3 className={s.packTitle}>Examen {slot}</h3>
                    <p className={s.packText}>3 tâches · {config.examTiming.short}</p>
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
          Le niveau de l&apos;épreuve tient compte de vos trois tâches, avec un garde-fou :
          pas de B2 si la tâche 3, la seule qui demande d&apos;argumenter, n&apos;atteint pas
          B1. Il faut tenir le palier partout, pas seulement sur la tâche la plus facile.
        </SkillNotice>

        <ConfirmSheet
          open={retakeWarningOpen}
          tone="warning"
          title="Repasser l'examen 1 ?"
          message="Votre examen blanc offert a déjà été corrigé. Vous pouvez le repasser, mais la correction d'un nouveau passage par l'IA fait partie du pass Intégral."
          confirmLabel="Repasser l'examen"
          cancelLabel="Annuler"
          onConfirm={() => launch(pendingSlot)}
          onClose={() => setRetakeWarningOpen(false)}
        />

        <PaywallSheet ctaLocation="MOCK_EXAM" screen="examens_production"
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          reason="Le 1ᵉʳ examen blanc corrigé par l'IA est offert ; les suivants font partie du pass Intégral."
        />
      </SkillShell>
    </DualChromeShell>
  );
}
