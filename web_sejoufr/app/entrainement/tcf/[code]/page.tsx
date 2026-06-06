"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { BookOpen, Headphones, SpellCheck, Target } from "lucide-react";
import { attemptApi, lotApi, publicLotApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  niveauCecrlLabel,
  type AttemptSummaryResponse,
  type Difficulty,
  type LotDto,
  type QuestionType,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, LevelChoiceCard } from "@/app/_components/hub/DetailParts";
import detail from "@/app/_components/hub/detail.module.css";

/** Épreuves TCF QCM exposées sur le web (les productions EO/EE ont leur parcours). */
const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    title: "Compréhension orale",
    icon: <Headphones size={18} strokeWidth={2} />,
  },
  ce: {
    questionType: "CE" as QuestionType,
    title: "Compréhension écrite",
    icon: <BookOpen size={18} strokeWidth={2} />,
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    title: "Structure de la langue",
    icon: <SpellCheck size={18} strokeWidth={2} />,
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

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

const DATE_FMT = new Intl.DateTimeFormat("fr-FR", {
  day: "numeric",
  month: "long",
  year: "numeric",
});

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
  /** 3 derniers examens blancs finis sur cette épreuve (connectés seulement). */
  const [history, setHistory] = useState<AttemptSummaryResponse[]>([]);

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
    if (status === "authenticated") {
      attemptApi
        .listMine({
          type: "MOCK_EXAM",
          module: "TCF",
          moduleExamQuestionType: config.questionType,
          limit: 30,
        })
        .then((list) => {
          if (cancelled) return;
          setHistory(
            list
              .filter((a) => a.finishedAt)
              .sort((a, b) =>
                (b.finishedAt ?? "").localeCompare(a.finishedAt ?? ""),
              )
              .slice(0, 3),
          );
        })
        .catch(() => undefined);
    }
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
        eyebrowIcon={config.icon}
        eyebrow={config.title}
        title="Choisissez votre niveau"
        subtitle="Les questions sont organisées par niveau du Cadre européen (CECRL). Commencez par le niveau qui vous correspond, puis montez progressivement."
        action={
          <Link href={`/entrainement/tcf/${code}/examens`} className={detail.headBtn}>
            <Target size={17} strokeWidth={1.7} aria-hidden />
            Examens blancs
          </Link>
        }
      >
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

        {/* Historique des 3 derniers examens blancs de l'épreuve — miroir du
            hub mobile (qcm_history_section.dart). Connectés seulement. */}
        {status === "authenticated" && (
          <section className={detail.histSection}>
            <div className={detail.histHead}>
              <span className={detail.histTitle}>Historique</span>
              <Link
                href={`/entrainement/tcf/${code}/examens`}
                className={detail.histLink}
              >
                Tout voir
              </Link>
            </div>
            {history.length === 0 ? (
              <div className={detail.histEmpty}>
                Aucun examen passé. Lancez un examen blanc ou entraînez-vous
                par niveau.
              </div>
            ) : (
              <ul className={detail.histList}>
                {history.map((a) => (
                  <li key={a.id}>
                    <Link href={`/sessions/${a.id}`} className={detail.histRow}>
                      <span className={detail.histIco} aria-hidden>
                        <Target size={18} strokeWidth={1.8} />
                      </span>
                      <span className={detail.histBody}>
                        <span className={detail.histLabel}>Examen blanc</span>
                        <span className={detail.histDate}>
                          {a.finishedAt
                            ? DATE_FMT.format(new Date(a.finishedAt))
                            : "—"}
                          {" · "}
                          {a.score ?? 0}/{a.totalQuestions ?? "—"} bonnes
                          réponses
                        </span>
                      </span>
                      <span className={detail.histScore}>
                        {a.calibratedScore != null
                          ? `${a.calibratedScore}/499`
                          : `${a.score ?? 0}/${a.totalQuestions ?? "—"}`}
                        {a.cecrlLevel && (
                          <>
                            <br />
                            <span className={detail.histLevel}>
                              {niveauCecrlLabel(a.cecrlLevel)}
                            </span>
                          </>
                        )}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </section>
        )}
      </DetailShell>
    </DualChromeShell>
  );
}
