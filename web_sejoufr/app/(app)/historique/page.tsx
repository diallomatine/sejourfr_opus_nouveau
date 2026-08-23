"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import {
  BookOpen,
  Flame,
  Gavel,
  Globe,
  Headphones,
  Landmark,
  Lightbulb,
  Mic,
  PenLine,
  RotateCw,
  Scale,
  Sparkles,
  SpellCheck,
  Target,
  Trophy,
  Users,
  Waves,
} from "lucide-react";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { attemptApi, dashboardApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import { successHint } from "@/lib/dashboard";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  type DashboardSummaryResponse,
  isProductionAttempt,
  niveauCecrlLabel,
} from "@/lib/types";

type ModuleFilter = "ALL" | "TCF" | "CIVIQUE";

const TCF_EPREUVE_LABELS: Record<string, string> = {
  CO: "Compréhension orale",
  CE: "Compréhension écrite",
  STRUCTURE: "Structure de la langue",
};

const TCF_EPREUVE_ICONS: Record<string, React.ReactNode> = {
  CO: <Headphones size={18} strokeWidth={1.8} />,
  CE: <BookOpen size={18} strokeWidth={1.8} />,
  STRUCTURE: <SpellCheck size={18} strokeWidth={1.8} />,
};

/** Tonalités (mêmes couleurs que les cards des hubs). */
const TCF_EPREUVE_TONES: Record<string, string> = {
  CO: "blue",
  CE: "green",
  STRUCTURE: "amber",
};

const CIVIQUE_THEME_TONES = new Map<string, string>([
  ["Principes et valeurs de la République", "blue"],
  ["Système institutionnel et politique", "green"],
  ["Droits et devoirs", "amber"],
  ["Histoire, géographie et culture", "red"],
  ["Vivre dans la société française", "slate"],
]);

/** Map nom de thème → icône (les libellés viennent du dashboard). */
const CIVIQUE_THEME_ICONS_BY_LABEL = new Map<string, React.ReactNode>([
  ["Principes et valeurs de la République", <Scale key="p" size={18} strokeWidth={1.8} />],
  ["Système institutionnel et politique", <Landmark key="i" size={18} strokeWidth={1.8} />],
  ["Droits et devoirs", <Gavel key="d" size={18} strokeWidth={1.8} />],
  ["Histoire, géographie et culture", <Globe key="h" size={18} strokeWidth={1.8} />],
  ["Vivre dans la société française", <Users key="v" size={18} strokeWidth={1.8} />],
]);

/**
 * /historique — « Mes résultats » (maquette sejour_fr.html) : 3 stat cards
 * (examens passés ce mois-ci, score moyen, meilleur score) + liste des
 * examens blancs finis filtrable Tous / TCF IRN / Examen civique. Chaque
 * ligne (icône catégorie, date + durée, badge CECRL, score coloré + %,
 * mini-barre) ouvre le rapport ; « Refaire » relance le même examen.
 */
export default function HistoriquePage() {
  const router = useRouter();
  const { user, status } = useAuth();

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [filter, setFilter] = useState<ModuleFilter>("ALL");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryingId, setRetryingId] = useState<string | null>(null);
  const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    Promise.allSettled([
      attemptApi.listMine({ type: "MOCK_EXAM", limit: 100 }),
      dashboardApi.summaryCached(),
    ]).then(([a, d]) => {
      if (cancelled) return;
      if (a.status === "fulfilled") {
        setExams(
          a.value
            .filter(
              (x) => x.finishedAt && !isProductionAttempt(x) && x.totalQuestions != null,
            )
            .sort((x, y) => y.startedAt.localeCompare(x.startedAt)),
        );
      }
      if (d.status === "fulfilled") setSummary(d.value);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  // themeId civique → libellé (les summaries ne portent que lotThemeId).
  const themeLabels = useMemo(() => {
    const m = new Map<string, string>();
    for (const c of summary?.civique ?? []) {
      if (c.themeId) m.set(c.themeId, c.label);
    }
    return m;
  }, [summary]);

  const filtered = useMemo(
    () => (filter === "ALL" ? exams : exams.filter((e) => e.module === filter)),
    [exams, filter],
  );

  const stats = useMemo(() => {
    const now = new Date();
    const thisMonth = exams.filter((e) => {
      const d = new Date(e.startedAt);
      return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
    }).length;
    const pcts = exams.map((e) => percentOf(e)).filter((p): p is number => p !== null);
    const avg = pcts.length
      ? Math.round(pcts.reduce((s, p) => s + p, 0) / pcts.length)
      : null;
    const best = pcts.length ? Math.max(...pcts) : null;
    return { thisMonth, avg, best };
  }, [exams]);

  /** Relance un examen avec les mêmes paramètres que l'original. */
  async function retry(exam: AttemptSummaryResponse) {
    if (retryingId || !user) return;
    if (!canAccessModule(user, exam.module)) {
      setPaywallModule(exam.module === "TCF" ? "INTEGRAL" : "CIVIQUE");
      return;
    }
    setError(null);
    setRetryingId(exam.id);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: exam.module,
        examTemplateId: exam.examTemplateId ?? undefined,
        themeId: exam.lotThemeId ?? undefined,
        moduleExamQuestionType: exam.moduleExamQuestionType ?? undefined,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => setPaywallModule(exam.module === "TCF" ? "INTEGRAL" : "CIVIQUE"),
        onMessage: setError,
        fallbackMessage: "Impossible de relancer l'examen.",
      });
      setRetryingId(null);
    }
  }

  if (status === "loading" || (loading && status === "authenticated")) {
    return (
      <div className="res res-loading" aria-busy>
        <div className="res-sk" />
        <div className="res-sk res-sk-tall" />
        <style>{styles}</style>
      </div>
    );
  }
  if (!user) {
    return (
      <div className="res-empty-page">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="res-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{styles}</style>
      </div>
    );
  }

  return (
    <main className="res">
      <header className="res-head">
        <div className="res-head-text">
          <div className="res-eyebrow">
            <Trophy size={16} aria-hidden />
            <span>Historique</span>
          </div>
          <h1>Mes résultats</h1>
          <p>Tous vos examens blancs, du plus récent au plus ancien.</p>
        </div>
        <Link href="/recommandations" className="res-head-btn">
          <Sparkles size={16} aria-hidden />
          Mes recommandations
        </Link>
      </header>

      <section className="res-stats" aria-label="Vos indicateurs">
        <article className="res-stat">
          <span className="res-stat-icon res-stat-blue" aria-hidden>
            <Trophy size={20} />
          </span>
          <div>
            <div className="res-stat-value">{stats.thisMonth}</div>
            <div className="res-stat-label">Examens passés</div>
            <div className="res-stat-sub">ce mois-ci</div>
          </div>
        </article>
        <article className="res-stat">
          <span className="res-stat-icon res-stat-green" aria-hidden>
            <Target size={20} />
          </span>
          <div>
            <div className="res-stat-value">
              {stats.avg !== null ? `${stats.avg}%` : "—"}
            </div>
            <div className="res-stat-label">Score moyen</div>
            <div className="res-stat-sub">{successHint(stats.avg)}</div>
          </div>
        </article>
        <article className="res-stat">
          <span className="res-stat-icon res-stat-red" aria-hidden>
            <Flame size={20} />
          </span>
          <div>
            <div className="res-stat-value">
              {stats.best !== null ? `${stats.best}%` : "—"}
            </div>
            <div className="res-stat-label">Meilleur score</div>
            <div className="res-stat-sub">record personnel</div>
          </div>
        </article>
      </section>

      {error && <div className="res-error">{error}</div>}

      <section className="res-list-card">
        <div className="res-filters">
          {(
            [
              ["ALL", "Tous"],
              ["TCF", "TCF IRN"],
              ["CIVIQUE", "Examen civique"],
            ] as [ModuleFilter, string][]
          ).map(([key, label]) => (
            <button
              key={key}
              type="button"
              className={`res-chip ${filter === key ? "is-active" : ""}`}
              onClick={() => setFilter(key)}
            >
              {label}
            </button>
          ))}
        </div>

        {filtered.length === 0 ? (
          <p className="res-none">
            Aucun examen blanc passé pour l&apos;instant —{" "}
            <Link href="/examens-blancs">lancez-en un</Link> pour voir vos
            résultats ici.
          </p>
        ) : (
          <ul className="res-rows">
            {filtered.map((exam) => (
              <ResultRow
                key={exam.id}
                exam={exam}
                themeLabels={themeLabels}
                retrying={retryingId === exam.id}
                onRetry={() => retry(exam)}
              />
            ))}
          </ul>
        )}
      </section>

      <ProductionHistoryLinks />

      <PaywallSheet
        open={paywallModule !== null}
        onClose={() => setPaywallModule(null)}
        module={paywallModule ?? "CIVIQUE"}
      />
      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// LIGNE DE RÉSULTAT
// ============================================================================

function percentOf(exam: AttemptSummaryResponse): number | null {
  if (exam.score == null || !exam.totalQuestions) return null;
  return Math.round((100 * exam.score) / exam.totalQuestions);
}

/** Libellé + icône + tonalité de la catégorie d'un examen. */
function examIdentity(
  exam: AttemptSummaryResponse,
  themeLabels: Map<string, string>,
): { title: string; icon: React.ReactNode; iconTone: string } {
  if (exam.module === "TCF") {
    const qt = exam.moduleExamQuestionType;
    if (qt && TCF_EPREUVE_LABELS[qt]) {
      return {
        title: TCF_EPREUVE_LABELS[qt],
        icon: TCF_EPREUVE_ICONS[qt],
        iconTone: TCF_EPREUVE_TONES[qt] ?? "blue",
      };
    }
    // Examen TCF complet : couleur pleine du module (rouge).
    return {
      title: exam.examTemplateName ?? "TCF IRN complet",
      icon: <Waves size={18} strokeWidth={1.8} />,
      iconTone: "module-red",
    };
  }
  if (exam.lotThemeId) {
    const label = themeLabels.get(exam.lotThemeId);
    return {
      title: label ?? "Thème civique",
      icon:
        (label && CIVIQUE_THEME_ICONS_BY_LABEL.get(label)) ?? (
          <Lightbulb size={18} strokeWidth={1.8} />
        ),
      iconTone: (label && CIVIQUE_THEME_TONES.get(label)) ?? "blue",
    };
  }
  // Examen civique complet : couleur pleine du module (bleu).
  return {
    title: exam.examTemplateName ?? "Examen civique complet",
    icon: <Lightbulb size={18} strokeWidth={1.8} />,
    iconTone: "module-blue",
  };
}

/**
 * **Vos productions EE/EO**, les deux seules séances que cette page ne liste
 * pas : elle ne montre que des examens blancs QCM (`isProductionAttempt` est
 * explicitement filtré plus haut, une production n'a ni score ni pourcentage à
 * ranger dans ces colonnes).
 *
 * Elles ont pourtant leur écran, `…/historique` par épreuve — qui n'avait
 * **aucun point d'entrée** : la route existait, rien n'y menait, et le rapport
 * d'un entraînement libre n'était donc plus joignable une fois quitté (la carte
 * d'un sujet déjà traité rouvre la rédaction, pas la correction). Une
 * correction IA que le candidat a payée et ne peut plus relire est une valeur
 * perdue, pas une simplification.
 *
 * ⚠️ **Ici, et pas dans le hub de l'épreuve** : la maquette du parcours a
 * volontairement retiré l'historique de cet écran (arbitrage client du
 * 2026-08-06), et c'est ce choix-là qu'on ne rouvre pas. La place naturelle est
 * cette page — miroir de « Mes historiques » côté mobile, qui range au même
 * endroit les examens civiques, les examens TCF et les deux sessions IA.
 */
function ProductionHistoryLinks() {
  return (
    <section className="res-prod" aria-label="Vos productions évaluées par l'IA">
      <h2 className="res-prod-title">Vos productions</h2>
      <p className="res-prod-text">
        Expression écrite et orale : sessions d&apos;examen blanc et entraînements libres, avec
        leur correction.
      </p>
      <div className="res-prod-links">
        <Link href="/entrainement/tcf/ee/historique" className="res-prod-link">
          <span className="res-prod-icon" aria-hidden>
            <PenLine size={18} strokeWidth={1.8} />
          </span>
          <span>
            <strong>Expression écrite</strong>
            <em>Vos rédactions corrigées</em>
          </span>
        </Link>
        <Link href="/entrainement/tcf/eo/historique" className="res-prod-link">
          <span className="res-prod-icon" aria-hidden>
            <Mic size={18} strokeWidth={1.8} />
          </span>
          <span>
            <strong>Expression orale</strong>
            <em>Vos enregistrements transcrits et corrigés</em>
          </span>
        </Link>
      </div>
    </section>
  );
}

function ResultRow({
  exam,
  themeLabels,
  retrying,
  onRetry,
}: {
  exam: AttemptSummaryResponse;
  themeLabels: Map<string, string>;
  retrying: boolean;
  onRetry: () => void;
}) {
  const { title, icon, iconTone } = examIdentity(exam, themeLabels);
  const pct = percentOf(exam);
  const tone = pct === null ? "blue" : pct >= 80 ? "green" : pct < 60 ? "amber" : "blue";
  const moduleLabel = exam.module === "TCF" ? "TCF IRN" : "Examen civique";

  return (
    <li className="res-row-wrap">
      <Link href={`/sessions/${exam.id}`} className="res-row">
        <span className={`res-row-icon res-icon-${iconTone}`} aria-hidden>
          {icon}
        </span>
        <span className="res-row-titles">
          <span className="res-row-title">{title}</span>
          <span className="res-row-sub">
            {moduleLabel} · {formatDay(exam.finishedAt ?? exam.startedAt)} ·{" "}
            {formatDuration(exam.startedAt, exam.finishedAt)}
          </span>
        </span>
        {exam.cecrlLevel ? (
          <span className="res-cecrl">{niveauCecrlLabel(exam.cecrlLevel)}</span>
        ) : (
          <span aria-hidden />
        )}
        <span className="res-score">
          {/* Examens TCF stratifiés : échelle calibrée 100-499, brut sinon. */}
          <span className={`res-score-main res-tone-${tone}`}>
            {exam.calibratedScore != null
              ? `${exam.calibratedScore}/499`
              : `${exam.score ?? 0}/${exam.totalQuestions}`}
          </span>
          <span className="res-score-pct">{pct !== null ? `${pct}%` : "—"}</span>
        </span>
        <span className="res-bar" aria-hidden>
          <span
            className={`res-bar-fill res-fill-${tone}`}
            style={{ width: `${Math.min(100, Math.max(0, pct ?? 0))}%` }}
          />
        </span>
      </Link>
      <button
        type="button"
        className="res-retry"
        onClick={onRetry}
        disabled={retrying}
      >
        <RotateCw size={15} aria-hidden />
        {retrying ? "…" : "Refaire"}
      </button>
    </li>
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

function formatDuration(startedAt: string, finishedAt?: string | null): string {
  if (!finishedAt) return "—";
  const sec = Math.round(
    (new Date(finishedAt).getTime() - new Date(startedAt).getTime()) / 1000,
  );
  if (!Number.isFinite(sec) || sec <= 0) return "—";
  const m = Math.round(sec / 60);
  if (m < 1) return `${sec} s`;
  if (m < 60) return `${m} min`;
  // Une session laissée ouverte puis finalisée plus tard produit des durées de
  // plusieurs heures : « 3036 min » n'est pas lisible.
  return `${Math.floor(m / 60)} h ${String(m % 60).padStart(2, "0")}`;
}

const styles = `
  .res {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 40px 80px;
  }

  /* ===== header ===== */
  .res-head {
    display: flex; align-items: flex-end; justify-content: space-between;
    gap: 20px; flex-wrap: wrap;
    margin-bottom: 22px;
  }
  .res-head-text { min-width: 0; }
  .res-eyebrow {
    display: inline-flex; align-items: center; gap: 8px;
    font-size: 13px; font-weight: 700;
    letter-spacing: 0.04em; text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 8px;
  }
  .res-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.1;
  }
  .res-head p {
    margin: 0;
    color: var(--color-muted);
    font-size: 15.5px; line-height: 1.5;
  }
  .res-head-btn {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 11px 20px;
    font-size: 14.5px; font-weight: 600; line-height: 1;
    background: #fff; color: var(--color-ink);
    border: 1px solid var(--color-line);
    border-radius: 999px;
    text-decoration: none;
    flex-shrink: 0;
    transition: box-shadow 0.18s, border-color 0.18s;
  }
  .res-head-btn:hover {
    border-color: var(--color-muted-2);
    box-shadow: 0 4px 12px rgba(15, 24, 57, 0.06);
  }

  /* ===== stat cards ===== */
  .res-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 22px;
  }
  .res-stat {
    display: flex; align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    min-width: 0;
  }
  .res-stat-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: grid; place-items: center;
    flex-shrink: 0;
  }
  .res-stat-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .res-stat-green { background: color-mix(in srgb, var(--color-green) 12%, #fff); color: var(--color-green); }
  .res-stat-red { background: var(--color-red-light); color: var(--color-red); }
  .res-stat-value {
    font-family: var(--font-sans);
    font-size: 22px; font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.15;
  }
  .res-stat-label { font-size: 13px; font-weight: 700; color: var(--color-ink-2); margin-top: 2px; }
  .res-stat-sub { font-size: 12px; color: var(--color-muted); margin-top: 1px; }

  .res-error {
    background: var(--color-red-light);
    border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent);
    color: var(--color-red-dark);
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 13.5px;
    margin-bottom: 16px;
  }

  /* ===== liste ===== */
  .res-list-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 16px 0 6px;
    overflow: hidden;
  }
  .res-filters {
    display: flex; flex-wrap: wrap; gap: 8px;
    padding: 0 22px 14px;
    border-bottom: 1px solid var(--color-line-2);
  }
  .res-chip {
    padding: 8px 16px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 999px;
    font-family: var(--font-sans);
    font-size: 13px; font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    transition: all 0.15s;
  }
  .res-chip:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .res-chip.is-active {
    background: var(--color-blue);
    border-color: var(--color-blue);
    color: #fff;
  }

  .res-none {
    margin: 0; padding: 28px 22px;
    font-size: 14px; color: var(--color-muted);
  }
  .res-none a { color: var(--color-blue); font-weight: 700; }

  .res-rows { list-style: none; margin: 0; padding: 0; }
  .res-row-wrap {
    display: flex; align-items: center; gap: 12px;
    border-bottom: 1px solid var(--color-line-2);
    padding-right: 22px;
  }
  .res-rows .res-row-wrap:last-child { border-bottom: none; }
  .res-row {
    flex: 1;
    display: grid;
    grid-template-columns: 38px minmax(170px, 1.2fr) auto 92px minmax(90px, 0.6fr);
    align-items: center;
    gap: 14px;
    padding: 13px 0 13px 22px;
    text-decoration: none;
    min-width: 0;
    transition: background 0.15s;
  }
  .res-row:hover { background: var(--color-blue-soft); }

  .res-row-icon {
    width: 38px; height: 38px;
    border-radius: 11px;
    display: grid; place-items: center;
    flex-shrink: 0;
  }
  .res-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .res-icon-green { background: color-mix(in srgb, var(--color-green) 14%, #fff); color: var(--color-green); }
  .res-icon-amber { background: color-mix(in srgb, var(--color-amber) 18%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .res-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .res-icon-slate { background: var(--color-paper-2); color: var(--color-muted); }
  /* Examens complets : couleur pleine du module (icône blanche). */
  .res-icon-module-blue { background: var(--color-blue); color: #fff; }
  .res-icon-module-red { background: var(--color-red); color: #fff; }
  .res-row-titles { min-width: 0; }
  .res-row-title {
    display: block;
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.3;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .res-row-sub {
    display: block;
    font-size: 12px; color: var(--color-muted);
    margin-top: 2px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }

  .res-cecrl {
    font-size: 11.5px; font-weight: 800;
    background: var(--color-blue-light); color: var(--color-blue);
    padding: 4px 9px; border-radius: 999px;
    white-space: nowrap;
    justify-self: start;
  }

  .res-score { text-align: right; }
  .res-score-main {
    display: block;
    font-family: var(--font-sans);
    font-size: 15px; font-weight: 800; letter-spacing: -0.01em;
  }
  .res-tone-green { color: var(--color-green); }
  .res-tone-blue { color: var(--color-blue); }
  .res-tone-amber { color: color-mix(in srgb, var(--color-amber) 80%, var(--color-ink)); }
  .res-score-pct { display: block; font-size: 11.5px; color: var(--color-muted-2); margin-top: 1px; }

  .res-bar {
    height: 8px; border-radius: 999px;
    background: var(--color-line-2);
    overflow: hidden;
    min-width: 0;
  }
  .res-bar-fill { display: block; height: 100%; border-radius: 999px; }
  .res-fill-green { background: var(--color-green); }
  .res-fill-blue { background: var(--color-blue); }
  .res-fill-amber { background: var(--color-amber); }

  .res-retry {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 8px 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 999px;
    font-family: var(--font-sans);
    font-size: 12.5px; font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    flex-shrink: 0;
    transition: all 0.15s;
  }
  .res-retry:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .res-retry:disabled { opacity: 0.6; cursor: progress; }

  /* ===== états ===== */
  .res-empty-page {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px; color: var(--color-muted);
  }
  .res-empty-link { color: var(--color-blue); font-weight: 700; }
  .res-sk {
    height: 110px; border-radius: 16px; margin-bottom: 16px;
    background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
    background-size: 200% 100%;
    animation: res-shimmer 1.4s infinite;
  }
  .res-sk-tall { height: 460px; }
  @keyframes res-shimmer { to { background-position: -200% 0; } }

  /* ===== productions EE/EO (l'écran ne les liste pas, il y renvoie) ===== */
  .res-prod {
    margin-top: 18px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 18px 22px 20px;
  }
  .res-prod-title {
    margin: 0;
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 700;
    color: var(--color-ink);
  }
  .res-prod-text {
    margin: 6px 0 0;
    font-size: 13.5px;
    line-height: 1.5;
    color: var(--color-muted);
  }
  .res-prod-links {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
    margin-top: 14px;
  }
  .res-prod-link {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 14px;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    color: inherit;
    transition: border-color 0.15s;
  }
  .res-prod-link:hover { border-color: var(--color-blue); }
  .res-prod-link:focus-visible {
    outline: 2px solid var(--color-blue);
    outline-offset: 2px;
  }
  .res-prod-icon {
    display: grid; place-items: center;
    width: 38px; height: 38px; flex: none;
    border-radius: 12px;
    background: var(--color-blue-light);
    color: var(--color-blue);
  }
  .res-prod-link strong {
    display: block;
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
  }
  .res-prod-link em {
    display: block;
    margin-top: 2px;
    font-size: 12.5px; font-style: normal;
    color: var(--color-muted);
  }

  /* ===== responsive ===== */
  @media (max-width: 1000px) {
    .res-prod-links { grid-template-columns: 1fr; }
    .res-stats { grid-template-columns: 1fr; }
    .res-row { grid-template-columns: 38px 1fr auto 92px; }
    .res-bar { display: none; }
  }
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .res { padding: 64px 18px 48px; }
    .res-cecrl { display: none; }
    .res-row { grid-template-columns: 38px 1fr 80px; gap: 10px; }
    .res-prod { padding: 16px 16px 18px; }
  }
`;
