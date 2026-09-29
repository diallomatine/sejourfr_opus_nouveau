"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { BookOpen, Headphones, SpellCheck } from "lucide-react";
import { lotApi, publicLotApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type Difficulty,
  type LotDto,
  type QuestionType,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import {
  ComplementaryNotice,
  DetailShell,
  LevelChoiceCard,
} from "@/app/_components/hub/DetailParts";
import detail from "@/app/_components/hub/detail.module.css";
import { ExamsActionBar } from "@/app/_components/hub/ExamsActionBar";
import { PlanEpreuveReco } from "@/app/_components/plan/PlanEpreuveReco";

/** Épreuves TCF QCM exposées sur le web (les productions EO/EE ont leur parcours). */
const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    title: "Compréhension orale",
    icon: Headphones,
    /** Le bloc du cycle. 🛑 `null` pour « Structure de la langue » : elle n'est
     *  pas une des quatre épreuves du TCF IRN, le moteur ne lui fait donc
     *  **jamais** de bloc — et on n'en invente pas. */
    bloc: "TCF_CO" as string | null,
  },
  ce: {
    questionType: "CE" as QuestionType,
    title: "Compréhension écrite",
    icon: BookOpen,
    bloc: "TCF_CE" as string | null,
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    title: "Structure de la langue",
    icon: SpellCheck,
    bloc: null as string | null,
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

/** L'intertitre du catalogue de niveaux. **Miroir mot pour mot du mobile**
 *  (`kQcmLevelsSectionTitle`, `tcf_qcm_detail_screen.dart`). */
const QCM_LEVELS_SECTION_TITLE = "S'entraîner par niveau";

const LEVELS: {
  key: string;
  chip: string;
  /** Couleur du chip — même convention que le mobile : A2 vert, B1 ambre, B2 rouge. */
  chipTone: "green" | "amber" | "red";
  difficulty: Difficulty;
  title: string;
  desc: string;
}[] = [
  {
    key: "a2",
    chip: "A2",
    chipTone: "green",
    difficulty: "A2",
    title: "Débutant",
    desc: "Comprendre des phrases simples et des situations très courantes du quotidien.",
  },
  {
    key: "b1",
    chip: "B1",
    chipTone: "amber",
    difficulty: "B1",
    title: "Intermédiaire",
    desc: "Se débrouiller dans la plupart des situations rencontrées en France.",
  },
  {
    key: "b2",
    chip: "B2",
    chipTone: "red",
    difficulty: "B2",
    title: "Avancé",
    desc: "Comprendre des textes complexes et s'exprimer avec aisance et nuance.",
  },
];

interface LevelStats {
  done: number;
  total: number | null;
  percent: number | null;
}

function statsFromLots(lots: LotDto[]): LevelStats {
  const doneLots = lots.filter((l) => l.lastScore != null);
  const percent =
    doneLots.length === 0
      ? null
      : Math.round(
          doneLots.reduce(
            (sum, l) => sum + (100 * (l.lastScore ?? 0)) / Math.max(1, l.totalQuestions),
            0,
          ) / doneLots.length,
        );
  return { done: doneLots.length, total: lots.length, percent };
}

/**
 * Choix de niveau d'une épreuve TCF QCM (maquette sejour_fr.html) : 3 cards
 * A2/B1/B2 avec donut (moyenne des séries faites) + compteur "x/y séries
 * faites". Un clic ouvre les séries du niveau. Navigable en guest (compteurs
 * sans scores, la série 1 de chaque niveau est jouable sans compte).
 */
export default function TcfQcmDetailPage() {
  const params = useParams<{ code: string }>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const { status } = useAuth();

  const [byLevel, setByLevel] = useState<Record<string, LevelStats>>({});

  useEffect(() => {
    if (status === "loading" || !config) return;
    let cancelled = false;
    const api = status === "authenticated" ? lotApi : publicLotApi;
    Promise.allSettled(
      LEVELS.map((lv) => api.listTcf(config.questionType, lv.difficulty)),
    ).then((results) => {
      if (cancelled) return;
      const next: Record<string, LevelStats> = {};
      results.forEach((r, i) => {
        next[LEVELS[i].key] =
          r.status === "fulfilled"
            ? statsFromLots(r.value)
            : { done: 0, total: null, percent: null };
      });
      setByLevel(next);
    });
    return () => {
      cancelled = true;
    };
  }, [status, config]);

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
        backHref="/entrainement?module=TCF"
        backLabel="TCF IRN"
        title={config.title}
        subtitle="Choisir un niveau · TCF IRN"
        notice={code === "structure" ? <ComplementaryNotice /> : undefined}
      >
        {config.bloc && (
          <PlanEpreuveReco
            blocCode={config.bloc}
            icon={<config.icon size={24} strokeWidth={2} />}
          />
        )}

        {/* 🛑 **L'intertitre sépare la recommandation du catalogue** (demande
            du propriétaire, 2026-09-20) : sans lui, les cartes de niveau se
            lisaient comme la suite de la carte du cycle. Même rôle que
            « Les 3 tâches » sur les écrans d'expression. */}
        <h2 className={detail.sectionTitle}>{QCM_LEVELS_SECTION_TITLE}</h2>

        <div className={detail.levelGrid}>
          {LEVELS.map((lv) => {
            const stats = byLevel[lv.key] ?? { done: 0, total: null, percent: null };
            return (
              <LevelChoiceCard
                key={lv.key}
                chip={lv.chip}
                chipTone={lv.chipTone}
                title={lv.title}
                desc={lv.desc}
                percent={stats.percent}
                done={stats.done}
                total={stats.total}
                onClick={() => router.push(`/entrainement/tcf/${code}/${lv.key}`)}
              />
            );
          })}
        </div>

        <ExamsActionBar href={`/entrainement/tcf/${code}/examens`} />
      </DetailShell>
    </DualChromeShell>
  );
}
