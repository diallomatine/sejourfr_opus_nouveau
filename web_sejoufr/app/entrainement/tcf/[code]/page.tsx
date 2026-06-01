"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {Info} from "lucide-react";
import {ApiException, attemptApi, lotApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  type Difficulty,
  type QuestionType,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  ExamBlancHero,
  ExamHistoryList,
  HubDetailHeader,
  type HubTone,
  LevelRow,
  SectionLabel,
  SectionLink,
} from "@/app/_components/hub/HubParts";
import {ExamDoneSheet} from "@/app/_components/hub/ExamDoneSheet";
import hub from "@/app/_components/hub/hub.module.css";

/** Épreuves TCF QCM exposées sur le web (les productions EO/EE restent mobiles). */
const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    title: "Compréhension orale",
    examSubtitle: "25 questions · 20 min",
    heroLine: "progression A2 → B1 → B2",
  },
  ce: {
    questionType: "CE" as QuestionType,
    title: "Compréhension écrite",
    examSubtitle: "25 questions · 35 min",
    heroLine: "progression A2 → B1 → B2",
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    title: "Structure de la langue",
    examSubtitle: "25 questions · 20 min",
    heroLine: "grammaire en conditions réelles",
    notice:
      "Module non évalué dans le TCF IRN officiel. Cet entraînement reste très utile pour consolider ta grammaire et progresser sur les autres épreuves.",
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS: {key: string; chip: string; tone: HubTone; label: string; difficulty: Difficulty}[] = [
  {key: "a2", chip: "A2", tone: "green", label: "Débutant", difficulty: "A2"},
  {key: "b1", chip: "B1", tone: "amber", label: "Intermédiaire", difficulty: "B1"},
  {key: "b2", chip: "B2", tone: "red", label: "Avancé", difficulty: "B2"},
];

/**
 * Détail d'une épreuve TCF QCM (CO/CE/Structure) — single-scroll calqué sur
 * `TcfQcmDetailScreen` mobile : header + notice bleue (Structure) + hero examen
 * blanc rouge + 3 niveaux (A2/B1/B2 avec compteur de lots) + historique. Tap
 * sur un examen passé → feuille « Voir le détail / Reprendre » (ExamDoneSheet).
 */
export default function TcfQcmDetailPage() {
  const params = useParams<{code: string}>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const config = TCF_QCM[code];
  const router = useRouter();
  const {user, status} = useAuth();
  const isPremium = user ? canAccessModule(user, "TCF") : false;

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [lotCounts, setLotCounts] = useState<Record<string, number | null>>({});
  const [selected, setSelected] = useState<AttemptSummaryResponse | null>(null);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const questionType = config?.questionType;

  useEffect(() => {
    if (status !== "authenticated" || !questionType) return;
    let cancelled = false;
    Promise.allSettled([
      attemptApi.listMine({type: "MOCK_EXAM", module: "TCF", moduleExamQuestionType: questionType, limit: 30}),
      lotApi.listTcf(questionType, "A2"),
      lotApi.listTcf(questionType, "B1"),
      lotApi.listTcf(questionType, "B2"),
    ]).then(([e, a2, b1, b2]) => {
      if (cancelled) return;
      if (e.status === "fulfilled") {
        setExams(
          e.value
            .filter((x) => x.finishedAt)
            .sort((x, y) => y.startedAt.localeCompare(x.startedAt)),
        );
      }
      setLotCounts({
        a2: a2.status === "fulfilled" ? a2.value.length : null,
        b1: b1.status === "fulfilled" ? b1.value.length : null,
        b2: b2.status === "fulfilled" ? b2.value.length : null,
      });
    });
    return () => {
      cancelled = true;
    };
  }, [status, questionType]);

  async function startModuleExam() {
    if (starting || !questionType) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "TCF",
        moduleExamQuestionType: questionType,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  function resumeSelected() {
    setSelected(null);
    // 1er passage gratuit déjà consommé (cet examen est terminé) → refaire est premium.
    if (!isPremium) {
      setPaywallOpen(true);
      return;
    }
    void startModuleExam();
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}`} />;
  if (!config) {
    return (
      <DualChromeShell>
        <main className={hub.hub}>
          <p className={hub.empty}>Épreuve TCF inconnue.</p>
          <Link href="/entrainement?module=TCF" className={hub.sectionLink}>
            ← Retour à l&apos;entraînement TCF
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  const notice = "notice" in config ? config.notice : null;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement?module=TCF"
          title={config.title}
          subtitle="TCF IRN · QCM"
        />

        {notice && (
          <div className={hub.notice}>
            <span className={hub.noticeIcon}>
              <Info size={18} strokeWidth={2} />
            </span>
            <span className={hub.noticeBody}>
              <span className={hub.noticeLabel}>À SAVOIR</span>
              <span className={hub.noticeText}>{notice}</span>
            </span>
          </div>
        )}

        <ExamBlancHero
          eyebrow={`Examen complet · ${config.examSubtitle}`}
          title="Lancer un examen blanc"
          description={`Conditions réelles : ${config.examSubtitle}, ${config.heroLine}.`}
          ctaLabel="Commencer"
          accent="red"
          onClick={() => router.push(`/entrainement/tcf/${code}/examens`)}
        />

        {error && <div className={hub.error}>{error}</div>}

        <SectionLabel label="S'entraîner par niveau" />
        <div className={hub.list}>
          {LEVELS.map((lv) => (
            <LevelRow
              key={lv.key}
              chip={lv.chip}
              tone={lv.tone}
              title={`Niveau ${lv.chip}`}
              subtitle={lv.label}
              lotCount={lotCounts[lv.key]}
              onClick={() => router.push(`/entrainement/tcf/${code}/${lv.key}`)}
            />
          ))}
        </div>

        <SectionLabel
          label="Historique"
          trailing={
            <SectionLink
              label="Tout voir"
              onClick={() => router.push(`/entrainement/tcf/${code}/examens`)}
            />
          }
        />
        <ExamHistoryList
          items={exams.slice(0, 3)}
          emptyLabel="Aucun examen passé. Lance un examen blanc ou entraîne-toi par niveau."
          onSelect={setSelected}
        />

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
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
      </main>
    </DualChromeShell>
  );
}
