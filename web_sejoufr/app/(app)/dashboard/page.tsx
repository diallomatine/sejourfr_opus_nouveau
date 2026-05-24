"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  BookOpen,
  FileCheck2,
  Headphones,
  Mic,
  PenLine,
  RotateCcw,
  ShieldCheck,
} from "lucide-react";
import {
  type ProductionKind,
  ProductionMobileSheet,
} from "@/app/_components/ProductionMobileSheet";
import { attemptApi, statsApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  isProductionAttempt,
  type Module as ModuleEnum,
  type TargetProcedure,
  type UserStatsResponse,
} from "@/lib/types";

type StatsByModule = Partial<Record<ModuleEnum, UserStatsResponse | null>>;

export default function DashboardPage() {
  const { user, status } = useAuth();

  const [stats, setStats] = useState<StatsByModule>({});
  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [wrongCount, setWrongCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [productionSheet, setProductionSheet] = useState<ProductionKind | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    (async () => {
      const result: StatsByModule = {};
      const promises: Array<Promise<unknown>> = [];
      if (user.hasCivique !== false) {
        promises.push(
          statsApi
            .get("CIVIQUE")
            .then((s) => {
              result.CIVIQUE = s;
            })
            .catch(() => {
              result.CIVIQUE = null;
            }),
        );
      }
      if (user.hasTcf !== false) {
        promises.push(
          statsApi
            .get("TCF")
            .then((s) => {
              result.TCF = s;
            })
            .catch(() => {
              result.TCF = null;
            }),
        );
      }
      const attemptsP = attemptApi
        .listMine({ limit: 30 })
        .catch((): AttemptSummaryResponse[] => []);
      const wrongP = userContentApi
        .wrong()
        .then((q) => q.length)
        .catch(() => 0);

      const [, atts, w] = await Promise.all([
        Promise.all(promises),
        attemptsP,
        wrongP,
      ]);
      if (cancelled) return;
      setStats(result);
      setAttempts(atts);
      setWrongCount(w);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  const inProgressAttempt = useMemo(
    () => attempts.find((a) => !a.finishedAt) ?? null,
    [attempts],
  );

  const totalQuestionsAnswered = useMemo(() => {
    return (stats.CIVIQUE?.questionsAnswered ?? 0) + (stats.TCF?.questionsAnswered ?? 0);
  }, [stats]);

  const totalCorrect = useMemo(() => {
    return (stats.CIVIQUE?.questionsCorrect ?? 0) + (stats.TCF?.questionsCorrect ?? 0);
  }, [stats]);

  const overallSuccessPct = useMemo(() => {
    if (totalQuestionsAnswered === 0) return 0;
    return Math.round((totalCorrect / totalQuestionsAnswered) * 100);
  }, [totalCorrect, totalQuestionsAnswered]);

  const mockExamsFinished = useMemo(
    () => attempts.filter((a) => a.type === "MOCK_EXAM" && a.finishedAt).length,
    [attempts],
  );

  const lastFiveCiviqueAvg = useMemo(() => {
    const slice = attempts
      .filter(
        (a) =>
          a.type === "MOCK_EXAM" &&
          a.module === "CIVIQUE" &&
          a.finishedAt &&
          a.score !== null &&
          a.score !== undefined,
      )
      .slice(0, 5);
    if (slice.length === 0) return null;
    return slice.reduce((sum, a) => sum + (a.score ?? 0), 0) / slice.length;
  }, [attempts]);

  const bannerCopy = useMemo(
    () =>
      buildBannerCopy({
        user: user
          ? { firstName: user.firstName, targetProcedure: user.targetProcedure ?? null }
          : null,
        avgScore: lastFiveCiviqueAvg,
      }),
    [user, lastFiveCiviqueAvg],
  );

  const recentActivity = useMemo(() => attempts.slice(0, 4), [attempts]);

  if (status === "loading") return <DashSkeleton />;
  if (!user) {
    return (
      <div className="dash-empty">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="dash-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{emptyStyle}</style>
      </div>
    );
  }

  const initial =
    user.firstName?.[0]?.toUpperCase() ?? user.email[0].toUpperCase();
  const objective = `${tcfLevelLabel(user.targetProcedure)} · ${procedureNiceLabel(user.targetProcedure)}`;

  return (
    <main className="dash">
      {/* ---- Topbar : salutation + chip utilisateur ---- */}
      <header className="dash-top">
        <div className="dash-greeting">
          <h1>
            Bonjour {user.firstName ?? "à vous"} <span aria-hidden>👋</span>
          </h1>
          <p>Continue ta préparation à l&apos;examen civique et au TCF IRN.</p>
        </div>
        <div className="dash-userchip">
          <span className="dash-avatar">{initial}</span>
          <div>
            <strong>{user.isPremium ? "Compte Premium" : "Compte découverte"}</strong>
            <span className="dash-userchip-sub">Objectif : {objective}</span>
          </div>
        </div>
      </header>

      {/* ---- Hero + carte score ---- */}
      <section className="dash-hero">
        <div className="dash-hero-text">
          <h2>Prépare ton examen comme en conditions réelles</h2>
          <p>
            Entraîne-toi sur le TCF IRN, passe des examens blancs et révise
            l&apos;examen civique. Ta progression est synchronisée avec
            l&apos;app mobile.
          </p>
          <div className="dash-hero-actions">
            <Link href="/examens-blancs" className="btn btn-lg">
              Lancer un examen blanc
              <ArrowRight size={18} className="arrow" aria-hidden />
            </Link>
            <Link
              href={inProgressAttempt ? `/sessions/${inProgressAttempt.id}` : "/entrainement"}
              className="btn btn-ghost btn-lg"
            >
              {inProgressAttempt ? "Reprendre ma session" : "Continuer mon entraînement"}
            </Link>
          </div>
        </div>

        <div className="dash-score">
          <span className="dash-score-eyebrow">Objectif visé</span>
          <div className="dash-score-level">{tcfLevelLabel(user.targetProcedure)}</div>
          <p className="dash-score-path">{procedureNiceLabel(user.targetProcedure)}</p>
          <div className="dash-progress">
            <div className="dash-progress-fill" style={{ width: `${overallSuccessPct}%` }} />
          </div>
          <small>{overallSuccessPct}% de maîtrise globale</small>
        </div>
      </section>

      {/* ---- Grille entraînement ---- */}
      <div className="dash-section-title">
        <h2>Choisir un entraînement</h2>
        <Link href="/entrainement">Tout voir →</Link>
      </div>
      <section className="dash-modules">
        <Link href="/entrainement?module=TCF" className="dash-module">
          <span className="dash-module-icon tone-blue" aria-hidden>
            <Headphones size={22} strokeWidth={1.8} />
          </span>
          <h3>Compréhension orale</h3>
          <p>QCM audio chronométrés, correction immédiate.</p>
          <div className="dash-tags">
            <span className="dash-tag">TCF</span>
            <span className="dash-tag">QCM</span>
          </div>
        </Link>

        <Link href="/entrainement?module=TCF" className="dash-module">
          <span className="dash-module-icon tone-green" aria-hidden>
            <BookOpen size={22} strokeWidth={1.8} />
          </span>
          <h3>Compréhension écrite</h3>
          <p>Textes, annonces et mails du quotidien.</p>
          <div className="dash-tags">
            <span className="dash-tag">TCF</span>
            <span className="dash-tag">QCM</span>
          </div>
        </Link>

        <button type="button" className="dash-module" onClick={() => setProductionSheet("EE")}>
          <span className="dash-module-icon tone-amber" aria-hidden>
            <PenLine size={22} strokeWidth={1.8} />
          </span>
          <h3>Expression écrite</h3>
          <p>3 tâches corrigées par IA, niveau CECRL.</p>
          <div className="dash-tags">
            <span className="dash-tag">IA</span>
            <span className="dash-tag dash-tag-mobile">Sur mobile</span>
          </div>
        </button>

        <button type="button" className="dash-module" onClick={() => setProductionSheet("EO")}>
          <span className="dash-module-icon tone-purple" aria-hidden>
            <Mic size={22} strokeWidth={1.8} />
          </span>
          <h3>Expression orale</h3>
          <p>Enregistre-toi, transcription et feedback détaillé.</p>
          <div className="dash-tags">
            <span className="dash-tag">IA</span>
            <span className="dash-tag dash-tag-mobile">Sur mobile</span>
          </div>
        </button>
      </section>

      {/* ---- Examens recommandés + progression ---- */}
      <div className="dash-content">
        <section>
          <div className="dash-section-title">
            <h2>Examens blancs recommandés</h2>
            <Link href="/historique">Historique →</Link>
          </div>
          <div className="dash-reco">
            <article className="dash-reco-card">
              <span className="dash-reco-icon tone-red" aria-hidden>
                <FileCheck2 size={20} strokeWidth={1.8} />
              </span>
              <div className="dash-reco-body">
                <h3>Examen blanc TCF IRN</h3>
                <p>Compréhension orale et écrite, score global CECRL.</p>
              </div>
              <Link href="/examens-blancs" className="btn dash-reco-btn">
                Commencer
              </Link>
            </article>

            <article className="dash-reco-card">
              <span className="dash-reco-icon tone-green" aria-hidden>
                <ShieldCheck size={20} strokeWidth={1.8} />
              </span>
              <div className="dash-reco-body">
                <h3>Examen civique — simulation</h3>
                <p>Institutions, valeurs de la République, vie en France.</p>
              </div>
              <Link href="/examens-blancs" className="btn btn-ghost dash-reco-btn">
                Réviser
              </Link>
            </article>

            <article className="dash-reco-card">
              <span className="dash-reco-icon tone-blue" aria-hidden>
                <RotateCcw size={20} strokeWidth={1.8} />
              </span>
              <div className="dash-reco-body">
                <h3>Mes erreurs</h3>
                <p>
                  {wrongCount > 0
                    ? `${wrongCount} question${wrongCount > 1 ? "s" : ""} à retravailler.`
                    : "Aucune erreur en attente — beau parcours."}
                </p>
              </div>
              <Link href="/revision" className="btn btn-ghost dash-reco-btn">
                Réviser
              </Link>
            </article>
          </div>
        </section>

        <aside className="dash-aside">
          <div className="dash-section-title">
            <h2>Progression</h2>
            <Link href="/statistiques">Détails →</Link>
          </div>
          <div className="dash-stats">
            <div className="dash-stat">
              <span>Examens terminés</span>
              <strong>{mockExamsFinished}</strong>
            </div>
            <div className="dash-stat">
              <span>Questions résolues</span>
              <strong>{totalQuestionsAnswered}</strong>
            </div>
            <div className="dash-stat">
              <span>Taux de réussite</span>
              <strong>{overallSuccessPct}%</strong>
            </div>
          </div>

          <div className="dash-section-title">
            <h2>Activité récente</h2>
          </div>
          <div className="dash-activity">
            {loading ? (
              <div className="dash-activity-skel" />
            ) : recentActivity.length === 0 ? (
              <p className="dash-activity-empty">
                Aucune activité pour l&apos;instant. Lance un entraînement pour
                démarrer.
              </p>
            ) : (
              recentActivity.map((a) => (
                <div className="dash-activity-item" key={a.id}>
                  <span className="dash-dot" aria-hidden />
                  <div className="dash-activity-body">
                    <strong>{activityLabel(a)}</strong>
                    <span>{activityDetail(a)}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </aside>
      </div>

      {/* ---- Bannière objectif / Premium ---- */}
      <section className="dash-banner">
        <div>
          <h3>{bannerCopy.title}</h3>
          <p>{bannerCopy.body}</p>
        </div>
        <Link
          href={user.isPremium ? "/statistiques" : "/paiement"}
          className="btn btn-red dash-banner-btn"
        >
          {user.isPremium ? "Voir mes faiblesses" : "Passer Premium"}
        </Link>
      </section>

      <ProductionMobileSheet
        open={productionSheet !== null}
        kind={productionSheet}
        onClose={() => setProductionSheet(null)}
      />

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// Helpers (présentation + dérivations)
// ============================================================================

function procedureNiceLabel(p: TargetProcedure | null | undefined): string {
  switch (p) {
    case "NAT":
      return "Naturalisation";
    case "CR":
      return "Carte de résident";
    case "CSP":
      return "Carte de séjour";
    default:
      return "Parcours à définir";
  }
}

function tcfLevelLabel(p: TargetProcedure | null | undefined): string {
  switch (p) {
    case "NAT":
      return "B2";
    case "CR":
      return "B1";
    case "CSP":
      return "A2";
    default:
      return "—";
  }
}

function buildBannerCopy({
  user,
  avgScore,
}: {
  user: { firstName: string; targetProcedure: TargetProcedure | null } | null;
  avgScore: number | null;
}): { title: string; body: string } {
  if (!user || avgScore === null) {
    return {
      title: "Fixe ton prochain objectif.",
      body: "Commence par un examen blanc pour te situer, puis attaque l'entraînement par thématique. Tes premières questions sont gratuites.",
    };
  }
  const gap = 32 - avgScore;
  if (gap <= 0) {
    return {
      title: "Tu es au-dessus du seuil. Maintiens le cap.",
      body: `Score moyen sur tes 5 derniers examens blancs civiques : ${avgScore.toFixed(1)}/40. Continue à varier les thèmes pour ne pas reculer.`,
    };
  }
  return {
    title: `Tu es à ${gap.toFixed(1)} points du seuil du civique.`,
    body: `Score moyen sur tes 5 derniers examens blancs : ${avgScore.toFixed(1)}/40. Le seuil officiel est de 32/40. Trois sessions ciblées devraient suffire.`,
  };
}

function activityLabel(a: AttemptSummaryResponse): string {
  if (isProductionAttempt(a)) {
    if (a.epreuve === "TCF_COMPLET") return "Examen blanc EO + EE";
    if (a.epreuve === "TCF_EO") return "Expression orale";
    return "Expression écrite";
  }
  const moduleLabel = a.module === "CIVIQUE" ? "Civique" : "TCF";
  if (a.type === "MOCK_EXAM") return `Examen blanc ${moduleLabel}`;
  return `Entraînement ${moduleLabel}`;
}

function activityDetail(a: AttemptSummaryResponse): string {
  const date = new Date(a.startedAt).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
  });
  if (!a.finishedAt) return `En cours · ${date}`;
  if (a.score !== null && a.score !== undefined) {
    const suffix = a.type === "MOCK_EXAM" && a.module === "CIVIQUE" ? "/40" : "%";
    return `${a.score}${suffix} · ${date}`;
  }
  return `Terminé · ${date}`;
}

// ============================================================================
// Skeleton / empty
// ============================================================================

function DashSkeleton() {
  return (
    <div className="dash-skel">
      <div className="dash-skel-bar" style={{ width: "40%", height: 28 }} />
      <div className="dash-skel-bar" style={{ width: "100%", height: 180 }} />
      <div className="dash-skel-grid">
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className="dash-skel-bar" style={{ height: 130 }} />
        ))}
      </div>
      <style>{`
        .dash-skel { padding: 24px; display: flex; flex-direction: column; gap: 20px; }
        .dash-skel-bar {
          background: linear-gradient(90deg, #EEF0F8 25%, #F6F7FB 50%, #EEF0F8 75%);
          background-size: 200% 100%;
          border-radius: 14px;
          animation: dash-shimmer 1.3s ease-in-out infinite;
        }
        .dash-skel-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; }
        @media (min-width: 1000px) { .dash-skel-grid { grid-template-columns: repeat(4, 1fr); } }
        @keyframes dash-shimmer {
          0% { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>
    </div>
  );
}

const emptyStyle = `
  .dash-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    color: var(--color-muted);
    font-size: 15px;
  }
  .dash-empty-link { color: var(--color-blue); font-weight: 700; }
`;

// ============================================================================
// Styles (mobile-first, identité Bleu France)
// ============================================================================

const styles = `
  .dash {
    padding: 20px 16px 56px;
    max-width: 1180px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 28px;
  }

  /* ---- Topbar ---- */
  .dash-top {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }
  .dash-greeting h1 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(24px, 5vw, 32px);
    letter-spacing: -0.02em;
    color: var(--color-ink);
    margin: 0;
  }
  .dash-greeting p {
    margin: 6px 0 0;
    color: var(--color-muted);
    font-size: 14.5px;
  }
  .dash-userchip {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    align-self: flex-start;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 10px 14px;
  }
  .dash-avatar {
    width: 40px; height: 40px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--color-blue), var(--color-red));
    color: #fff;
    display: inline-flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 15px;
    flex-shrink: 0;
  }
  .dash-userchip strong {
    display: block;
    font-size: 13.5px;
    color: var(--color-ink);
  }
  .dash-userchip-sub {
    font-size: 12px;
    color: var(--color-muted);
  }

  /* ---- Hero ---- */
  .dash-hero {
    display: grid;
    grid-template-columns: 1fr;
    gap: 20px;
    background: linear-gradient(150deg, #fff 0%, var(--color-blue-soft) 100%);
    border: 1px solid var(--color-line);
    border-radius: 20px;
    padding: 24px;
  }
  .dash-hero-text h2 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(20px, 4.4vw, 28px);
    line-height: 1.12;
    letter-spacing: -0.02em;
    color: var(--color-ink);
    margin: 0 0 10px;
  }
  .dash-hero-text p {
    color: var(--color-muted);
    font-size: 14.5px;
    line-height: 1.6;
    margin: 0 0 20px;
    max-width: 520px;
  }
  .dash-hero-actions {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  /* Carte score */
  .dash-score {
    background: linear-gradient(150deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    color: #fff;
    border-radius: 16px;
    padding: 22px;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
  }
  .dash-score-eyebrow {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: rgba(255, 255, 255, 0.7);
  }
  .dash-score-level {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 44px;
    line-height: 1;
    margin: 8px 0 2px;
  }
  .dash-score-path {
    margin: 0 0 16px;
    font-size: 13px;
    color: rgba(255, 255, 255, 0.78);
  }
  .dash-progress {
    width: 100%;
    height: 8px;
    border-radius: 100px;
    background: rgba(255, 255, 255, 0.2);
    overflow: hidden;
  }
  .dash-progress-fill {
    height: 100%;
    border-radius: 100px;
    background: #fff;
    transition: width 0.4s ease;
  }
  .dash-score small {
    margin-top: 8px;
    font-size: 12px;
    color: rgba(255, 255, 255, 0.78);
  }

  /* ---- Titres de section ---- */
  .dash-section-title {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 14px;
  }
  .dash-section-title h2 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    letter-spacing: -0.015em;
    color: var(--color-ink);
    margin: 0;
  }
  .dash-section-title a {
    font-size: 13px;
    font-weight: 600;
    color: var(--color-blue);
    white-space: nowrap;
  }
  .dash-section-title a:hover { text-decoration: underline; }

  /* ---- Grille modules ---- */
  .dash-modules {
    display: grid;
    grid-template-columns: 1fr;
    gap: 14px;
  }
  .dash-module {
    text-align: left;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 20px;
    cursor: pointer;
    font-family: inherit;
    display: flex;
    flex-direction: column;
    transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
  }
  .dash-module:hover {
    transform: translateY(-3px);
    border-color: var(--color-blue);
    box-shadow: 0 16px 38px -22px rgba(30, 58, 140, 0.32);
  }
  .dash-module-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: inline-flex; align-items: center; justify-content: center;
    margin-bottom: 14px;
  }
  .dash-module h3 {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 15.5px;
    color: var(--color-ink);
    margin: 0 0 4px;
  }
  .dash-module p {
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.5;
    margin: 0 0 14px;
    flex: 1;
  }
  .tone-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .tone-green { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .tone-amber { background: rgba(232, 163, 23, 0.16); color: #B87908; }
  .tone-purple { background: rgba(124, 58, 173, 0.12); color: #7C3AAD; }
  .tone-red { background: var(--color-red-light); color: var(--color-red); }

  .dash-tags { display: flex; flex-wrap: wrap; gap: 6px; }
  .dash-tag {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    font-weight: 600;
    padding: 4px 9px;
    border-radius: 100px;
    background: var(--color-paper-2);
    color: var(--color-muted);
  }
  .dash-tag-mobile { background: var(--color-blue-light); color: var(--color-blue); }

  /* ---- Contenu (examens reco + aside) ---- */
  .dash-content {
    display: grid;
    grid-template-columns: 1fr;
    gap: 28px;
  }
  .dash-reco { display: flex; flex-direction: column; gap: 12px; }
  .dash-reco-card {
    display: flex;
    align-items: center;
    gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px;
  }
  .dash-reco-icon {
    width: 42px; height: 42px;
    border-radius: 11px;
    display: inline-flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .dash-reco-body { flex: 1; min-width: 0; }
  .dash-reco-body h3 {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 14.5px;
    color: var(--color-ink);
    margin: 0 0 2px;
  }
  .dash-reco-body p {
    font-size: 12.5px;
    color: var(--color-muted);
    line-height: 1.45;
    margin: 0;
  }
  .dash-reco-btn {
    flex-shrink: 0;
    padding: 9px 16px;
    font-size: 13px;
    border-radius: 9px;
  }

  /* Aside progression */
  .dash-stats {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 10px;
    margin-bottom: 28px;
  }
  .dash-stat {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 12px;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .dash-stat span {
    font-size: 11.5px;
    color: var(--color-muted);
    line-height: 1.3;
  }
  .dash-stat strong {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 24px;
    color: var(--color-ink);
    line-height: 1;
  }

  .dash-activity {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 6px 16px;
  }
  .dash-activity-item {
    display: flex;
    gap: 12px;
    padding: 12px 0;
    border-bottom: 1px solid var(--color-line-2);
  }
  .dash-activity-item:last-child { border-bottom: none; }
  .dash-dot {
    width: 8px; height: 8px;
    border-radius: 50%;
    background: var(--color-blue);
    margin-top: 6px;
    flex-shrink: 0;
  }
  .dash-activity-body { display: flex; flex-direction: column; gap: 1px; min-width: 0; }
  .dash-activity-body strong {
    font-size: 13.5px;
    color: var(--color-ink);
    font-weight: 600;
  }
  .dash-activity-body span {
    font-size: 12px;
    color: var(--color-muted);
    font-family: var(--font-mono);
  }
  .dash-activity-empty {
    padding: 18px 0;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.5;
  }
  .dash-activity-skel {
    height: 120px;
    border-radius: 8px;
    background: linear-gradient(90deg, #EEF0F8 25%, #F6F7FB 50%, #EEF0F8 75%);
    background-size: 200% 100%;
    animation: dash-shimmer 1.3s ease-in-out infinite;
  }
  @keyframes dash-shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }

  /* ---- Bannière ---- */
  .dash-banner {
    display: flex;
    flex-direction: column;
    gap: 16px;
    background: linear-gradient(135deg, var(--color-ink) 0%, #1B2550 100%);
    color: #fff;
    border-radius: 18px;
    padding: 24px;
  }
  .dash-banner h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    letter-spacing: -0.015em;
    margin: 0 0 6px;
  }
  .dash-banner p {
    margin: 0;
    font-size: 13.5px;
    color: rgba(255, 255, 255, 0.78);
    line-height: 1.55;
    max-width: 640px;
  }
  .dash-banner-btn {
    align-self: flex-start;
    flex-shrink: 0;
  }

  /* ============================================================
     Breakpoints
     ============================================================ */
  @media (min-width: 560px) {
    .dash-modules { grid-template-columns: 1fr 1fr; }
    .dash-hero-actions { flex-direction: row; flex-wrap: wrap; }
  }
  @media (min-width: 700px) {
    .dash { padding: 28px 28px 64px; gap: 32px; }
    .dash-top {
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
    }
    .dash-hero { padding: 32px; }
    .dash-banner {
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
    }
  }
  @media (min-width: 900px) {
    .dash-hero {
      grid-template-columns: 1.5fr 1fr;
      align-items: stretch;
    }
    .dash-content { grid-template-columns: 1fr 340px; }
  }
  @media (min-width: 1000px) {
    .dash-modules { grid-template-columns: repeat(4, 1fr); }
  }
`;
