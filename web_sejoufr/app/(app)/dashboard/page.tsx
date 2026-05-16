"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { attemptApi, statsApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type {
  AttemptSummaryResponse,
  Module as ModuleEnum,
  UserStatsResponse,
} from "@/lib/types";

type StatsByModule = Partial<Record<ModuleEnum, UserStatsResponse | null>>;

export default function DashboardPage() {
  const { user, status } = useAuth();

  const [stats, setStats] = useState<StatsByModule>({});
  const [recentAttempts, setRecentAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [loadingData, setLoadingData] = useState(true);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    (async () => {
      const promises: Array<Promise<unknown>> = [];
      const result: StatsByModule = {};
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
        .listMine({ limit: 3 })
        .catch((): AttemptSummaryResponse[] => []);
      const [, attempts] = await Promise.all([Promise.all(promises), attemptsP]);
      if (cancelled) return;
      setStats(result);
      setRecentAttempts(attempts);
      setLoadingData(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  if (status === "loading") return <DashboardSkeleton />;
  if (!user) {
    return (
      <div className="dash-loading">
        <p>
          Session expirée. <Link href="/connexion">Se reconnecter</Link>
        </p>
      </div>
    );
  }

  const showCivique = user.hasCivique !== false || (stats.CIVIQUE?.questionsAnswered ?? 0) > 0;
  const showTcf = user.hasTcf !== false || (stats.TCF?.questionsAnswered ?? 0) > 0;
  const lastAttempt = recentAttempts[0] ?? null;
  const inProgressAttempt = recentAttempts.find((a) => !a.finishedAt) ?? null;

  return (
    <main className="dash">
      <header className="dash-head">
        <span className="eyebrow">Tableau de bord</span>
        <h1>
          Bonjour <em>{user.firstName ?? "à vous"}</em>.
        </h1>
        <p>
          {inProgressAttempt
            ? "Vous avez une session en cours. Reprenez où vous en étiez ou démarrez autre chose."
            : "Voici un aperçu de votre progression. Lancez-vous quand vous voulez."}
        </p>
      </header>

      {inProgressAttempt && (
        <Link href={`/sessions/${inProgressAttempt.id}`} className="dash-resume">
          <div className="dash-resume-marker" aria-hidden>
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 12h14m-6 -6 6 6 -6 6" />
            </svg>
          </div>
          <div className="dash-resume-content">
            <div className="dash-resume-title">
              Reprendre votre {inProgressAttempt.type === "MOCK_EXAM" ? "examen blanc" : "entraînement"}
            </div>
            <div className="dash-resume-sub">
              {inProgressAttempt.module === "TCF" ? "TCF IRN" : "Civique"} ·
              démarré il y a {timeAgo(inProgressAttempt.startedAt)}
            </div>
          </div>
          <span className="dash-resume-cta">Reprendre →</span>
        </Link>
      )}

      {/* Onboarding intégré : pousse à choisir un parcours administratif si
          l'utilisateur ne l'a pas encore fait. Sans parcours, l'entraînement
          reste générique (pas de niveau de difficulté adapté). */}
      {!user.targetProcedure && (
        <Link href="/parcours?from=/dashboard" className="dash-onboard">
          <div className="dash-onboard-icon" aria-hidden>
            <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
          </div>
          <div className="dash-onboard-content">
            <div className="dash-onboard-title">Choisissez votre parcours administratif</div>
            <div className="dash-onboard-sub">
              CSP, CR ou naturalisation — votre entraînement civique sera adapté à votre niveau d&apos;exigence.
            </div>
          </div>
          <span className="dash-onboard-cta">Démarrer →</span>
        </Link>
      )}

      {/* SNAPSHOT STATS */}
      <section className="dash-snapshot">
        {showCivique && (
          <SnapshotCard
            module="CIVIQUE"
            stats={stats.CIVIQUE}
            hasAccess={user.hasCivique ?? false}
            loading={loadingData}
          />
        )}
        {showTcf && (
          <SnapshotCard
            module="TCF"
            stats={stats.TCF}
            hasAccess={user.hasTcf ?? false}
            loading={loadingData}
          />
        )}
      </section>

      {/* ACTIONS RAPIDES */}
      <section className="dash-actions">
        <span className="dash-actions-label">Actions rapides</span>
        <div className="dash-actions-grid">
          <ActionCard
            tone="blue"
            href="/entrainement"
            title="Entraînement"
            desc="Sans limite si abonné, démo 20 Q sinon. Correction immédiate."
            cta="Démarrer"
          />
          <ActionCard
            tone="red"
            href="/examens-blancs"
            title="Examens blancs"
            desc="En conditions réelles, chronomètre. 1 examen offert par module."
            cta="Voir les examens"
          />
          <ActionCard
            tone="green"
            href="/revision"
            title="Révision"
            desc="Vos erreurs et favoris à retravailler en priorité."
            cta="Réviser"
          />
        </div>
      </section>

      {/* DERNIÈRES SESSIONS */}
      {recentAttempts.length > 0 && (
        <section className="dash-recent">
          <div className="dash-recent-head">
            <span className="dash-recent-title">Dernières sessions</span>
            <Link href="/historique" className="dash-recent-more">
              Voir tout →
            </Link>
          </div>
          <div className="dash-recent-list">
            {recentAttempts.slice(0, 3).map((a) => (
              <RecentRow key={a.id} attempt={a} isLastAttempt={a.id === lastAttempt?.id} />
            ))}
          </div>
        </section>
      )}

      {/* COMPTE */}
      <section className="dash-account">
        <h3>Mon compte</h3>
        <Row label="Email" value={user.email} />
        <Row
          label="Nom"
          value={`${user.firstName ?? "—"} ${user.lastName ?? ""}`.trim()}
        />
        {user.targetProcedure && (
          <Row
            label="Parcours visé"
            value={procedureLabel(user.targetProcedure)}
          />
        )}
        <Row
          label="Abonnement"
          value={
            user.isPremium
              ? user.hasTcf
                ? "Intégral (Civique + TCF)"
                : "Civique"
              : "Démo"
          }
        />
      </section>

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// SNAPSHOT
// ============================================================================
function SnapshotCard({
  module,
  stats,
  hasAccess,
  loading,
}: {
  module: ModuleEnum;
  stats: UserStatsResponse | null | undefined;
  hasAccess: boolean;
  loading: boolean;
}) {
  const isTcf = module === "TCF";
  const moduleLabel = isTcf ? "TCF IRN" : "Civique";
  const tone = isTcf ? "red" : "blue";
  const answered = stats?.questionsAnswered ?? 0;
  const successPct = stats ? Math.round(stats.successRate * 100) : 0;
  const sessions = stats?.attemptsTotal ?? 0;

  return (
    <div className={`snap snap-${tone}`}>
      <div className="snap-head">
        <span className={`snap-tag ${isTcf ? "tcf" : "civique"}`}>{moduleLabel}</span>
        {!hasAccess && <span className="snap-demo">DÉMO</span>}
      </div>
      {loading ? (
        <div className="snap-skel" />
      ) : answered === 0 ? (
        <div className="snap-empty">
          <p>Pas encore de session sur ce module.</p>
          <Link href={`/entrainement`} className="snap-empty-cta">
            Lancer un entraînement →
          </Link>
        </div>
      ) : (
        <>
          <div className="snap-main">
            <span className="snap-pct" data-tone={toneFor(successPct)}>{successPct}%</span>
            <span className="snap-pct-label">Taux de réussite</span>
          </div>
          <div className="snap-stats">
            <div className="snap-stat">
              <span className="l">Sessions</span>
              <span className="v">{sessions}</span>
            </div>
            <div className="snap-stat">
              <span className="l">Questions</span>
              <span className="v">{answered}</span>
            </div>
          </div>
          <Link href={`/statistiques`} className="snap-cta">
            Voir le détail →
          </Link>
        </>
      )}
    </div>
  );
}

function toneFor(pct: number): "green" | "amber" | "red" {
  if (pct >= 75) return "green";
  if (pct >= 50) return "amber";
  return "red";
}

// ============================================================================
// ACTION CARD
// ============================================================================
function ActionCard({
  tone,
  href,
  title,
  desc,
  cta,
}: {
  tone: "blue" | "red" | "green";
  href: string;
  title: string;
  desc: string;
  cta: string;
}) {
  return (
    <Link href={href} className={`act act-${tone}`}>
      <h3>{title}</h3>
      <p>{desc}</p>
      <span className="act-cta">{cta} →</span>
    </Link>
  );
}

// ============================================================================
// RECENT ROW
// ============================================================================
function RecentRow({
  attempt,
  isLastAttempt,
}: {
  attempt: AttemptSummaryResponse;
  isLastAttempt: boolean;
}) {
  const isTcf = attempt.module === "TCF";
  const isExam = attempt.type === "MOCK_EXAM";
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const isFinished = !!attempt.finishedAt;

  let label: string;
  let labelTone: "good" | "warn" | "neutral";
  if (!isFinished) {
    label = "En cours";
    labelTone = "neutral";
  } else if (isTcf || !isExam) {
    label = `${score}/${total}`;
    labelTone = "neutral";
  } else if (attempt.passThreshold !== null && attempt.passThreshold !== undefined) {
    const passed = score >= attempt.passThreshold;
    label = passed ? "Réussi" : "Non atteint";
    labelTone = passed ? "good" : "warn";
  } else {
    label = `${score}/${total}`;
    labelTone = "neutral";
  }

  return (
    <Link href={`/sessions/${attempt.id}`} className="recent-row">
      <div className="recent-row-date">
        <span className="recent-day">{new Date(attempt.startedAt).getDate().toString().padStart(2, "0")}</span>
        <span className="recent-month">{MONTHS[new Date(attempt.startedAt).getMonth()]}</span>
      </div>
      <div className="recent-row-body">
        <div className="recent-row-meta">
          <span className={`recent-tag ${isTcf ? "tcf" : "civique"}`}>
            {isTcf ? "TCF" : "Civique"}
          </span>
          <span className="recent-type">
            {isExam ? "Examen blanc" : "Entraînement"}
          </span>
          {isLastAttempt && !isFinished && <span className="recent-pulse">●</span>}
        </div>
        <div className="recent-row-stats">
          {isFinished
            ? `${score} bonnes / ${total}`
            : `Démarré il y a ${timeAgo(attempt.startedAt)}`}
        </div>
      </div>
      <span className={`recent-badge ${labelTone}`}>{label}</span>
    </Link>
  );
}

const MONTHS = [
  "janv.", "févr.", "mars", "avr.", "mai", "juin",
  "juil.", "août", "sept.", "oct.", "nov.", "déc.",
];

function timeAgo(iso: string): string {
  const diffMin = Math.floor((Date.now() - Date.parse(iso)) / 60000);
  if (diffMin < 1) return "moins d'une minute";
  if (diffMin < 60) return `${diffMin} min`;
  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `${diffH} h`;
  return `${Math.floor(diffH / 24)} j`;
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="dash-row">
      <span className="dash-row-l">{label}</span>
      <span className="dash-row-v">{value}</span>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="dash-loading">
      <p>Chargement…</p>
      <style>{`
        .dash-loading {
          padding: 120px 28px; text-align: center;
          color: var(--color-muted);
          font-family: var(--font-mono);
          font-size: 12px; letter-spacing: 0.1em;
        }
      `}</style>
    </div>
  );
}

function procedureLabel(p: string): string {
  switch (p) {
    case "CSP": return "Carte de séjour pluriannuelle (CSP)";
    case "CR":  return "Carte de résident (CR)";
    case "NAT": return "Naturalisation (NAT)";
    default:    return p;
  }
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .dash { padding: 36px 32px 64px; max-width: 1000px; margin: 0 auto; }
  @media (max-width: 760px) { .dash { padding: 24px 16px 56px; } }

  .dash-head { margin-bottom: 24px; }
  .dash-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 8px;
  }
  .dash-head h1 em { font-style: italic; color: var(--color-red); }
  .dash-head p {
    color: var(--color-muted); font-size: 15px; margin: 0;
    max-width: 600px; line-height: 1.55;
  }

  /* RESUME BAR */
  .dash-resume {
    display: flex; align-items: center; gap: 14px;
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    color: #fff;
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 22px;
    text-decoration: none;
    transition: transform 0.15s;
  }
  .dash-resume:hover { transform: translateY(-2px); }
  .dash-resume-marker {
    width: 38px; height: 38px;
    background: rgba(255, 255, 255, 0.15);
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .dash-resume-content { flex: 1; min-width: 0; }
  .dash-resume-title { font-weight: 700; font-size: 14.5px; line-height: 1.2; }
  .dash-resume-sub {
    font-size: 12px; opacity: 0.78; margin-top: 3px;
    font-family: var(--font-mono); letter-spacing: 0.06em;
  }
  .dash-resume-cta {
    font-weight: 700; font-size: 13px;
    flex-shrink: 0;
  }

  /* ONBOARDING — parcours non choisi */
  .dash-onboard {
    display: flex; align-items: center; gap: 14px;
    background: linear-gradient(135deg, var(--color-blue-soft) 0%, #fff 100%);
    border: 1px solid var(--color-blue-light);
    border-left: 4px solid var(--color-blue);
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 22px;
    text-decoration: none;
    color: inherit;
    transition: all 0.18s;
    font-family: var(--font-sans);
  }
  .dash-onboard:hover {
    transform: translateY(-2px);
    box-shadow: 0 14px 30px -16px rgba(30, 58, 140, 0.22);
  }
  .dash-onboard-icon {
    width: 44px; height: 44px;
    background: var(--color-blue);
    color: #fff;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .dash-onboard-content { flex: 1; min-width: 0; }
  .dash-onboard-title {
    font-weight: 800; font-size: 14.5px; color: var(--color-ink); line-height: 1.2;
  }
  .dash-onboard-sub {
    font-size: 12.5px; color: var(--color-muted); line-height: 1.4; margin-top: 4px;
  }
  .dash-onboard-cta {
    font-weight: 700; font-size: 13px; color: var(--color-blue);
    flex-shrink: 0;
  }

  /* SNAPSHOT */
  .dash-snapshot {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
    margin-bottom: 22px;
  }
  @media (max-width: 720px) { .dash-snapshot { grid-template-columns: 1fr; } }

  .snap {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px;
    position: relative;
    overflow: hidden;
  }
  .snap::before {
    content: ''; position: absolute; top: 0; left: 0; right: 0;
    height: 3px;
  }
  .snap-blue::before { background: var(--color-blue); }
  .snap-red::before { background: var(--color-red); }

  .snap-head { display: flex; align-items: center; gap: 8px; margin-bottom: 14px; }
  .snap-tag {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    padding: 3px 8px; border-radius: 4px;
    font-weight: 700;
  }
  .snap-tag.civique { background: var(--color-blue-light); color: var(--color-blue); }
  .snap-tag.tcf { background: var(--color-red-light); color: var(--color-red); }
  .snap-demo {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; font-weight: 700;
    background: rgba(232, 163, 23, 0.16);
    color: var(--color-amber);
    padding: 3px 7px; border-radius: 4px;
  }

  .snap-main {
    display: flex; flex-direction: column; gap: 4px;
    margin-bottom: 16px;
  }
  .snap-pct {
    font-family: var(--font-display); font-weight: 500;
    font-size: 42px; line-height: 1; letter-spacing: -0.04em;
  }
  .snap-pct[data-tone="green"] { color: var(--color-green); }
  .snap-pct[data-tone="amber"] { color: var(--color-amber); }
  .snap-pct[data-tone="red"] { color: var(--color-red); }
  .snap-pct-label {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.12em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }

  .snap-stats { display: flex; gap: 18px; margin-bottom: 14px; }
  .snap-stat { display: flex; flex-direction: column; gap: 2px; }
  .snap-stat .l {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }
  .snap-stat .v {
    font-family: var(--font-mono); font-size: 16px; font-weight: 700;
    color: var(--color-ink);
  }
  .snap-cta {
    font-family: var(--font-sans); font-size: 12.5px; font-weight: 700;
    color: var(--color-blue);
    text-decoration: none;
    border-top: 1px solid var(--color-line-2);
    padding-top: 10px;
    display: block;
  }
  .snap-empty p {
    font-size: 13px; color: var(--color-muted); margin: 0 0 10px; line-height: 1.5;
  }
  .snap-empty-cta {
    font-family: var(--font-sans); font-weight: 700; font-size: 13px;
    color: var(--color-blue);
  }
  .snap-skel {
    height: 110px;
    background: var(--color-paper-2);
    border-radius: 10px;
    animation: snap-pulse 1.4s ease-in-out infinite;
  }
  @keyframes snap-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }

  /* ACTIONS */
  .dash-actions { margin-bottom: 22px; }
  .dash-actions-label {
    font-family: var(--font-mono); font-size: 10.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
    margin-bottom: 10px; display: inline-block;
  }
  .dash-actions-grid {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px;
  }
  @media (max-width: 720px) { .dash-actions-grid { grid-template-columns: 1fr; } }

  .act {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 20px;
    text-decoration: none;
    color: inherit;
    transition: all 0.18s;
    position: relative; overflow: hidden;
    display: flex; flex-direction: column; gap: 6px;
  }
  .act::before {
    content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px;
  }
  .act-blue::before { background: var(--color-blue); }
  .act-red::before { background: var(--color-red); }
  .act-green::before { background: var(--color-green); }
  .act:hover {
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .act h3 {
    font-family: var(--font-display); font-weight: 500; font-size: 18px;
    letter-spacing: -0.015em; margin: 0;
    color: var(--color-ink);
  }
  .act p {
    color: var(--color-muted); font-size: 13px;
    line-height: 1.5; margin: 0; flex: 1;
  }
  .act-cta { margin-top: 6px; font-size: 13px; font-weight: 700; }
  .act-blue .act-cta { color: var(--color-blue); }
  .act-red .act-cta { color: var(--color-red); }
  .act-green .act-cta { color: var(--color-green); }

  /* RECENT */
  .dash-recent {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 20px 22px;
    margin-bottom: 22px;
  }
  .dash-recent-head {
    display: flex; align-items: baseline; justify-content: space-between;
    margin-bottom: 14px;
  }
  .dash-recent-title {
    font-family: var(--font-sans); font-weight: 800; font-size: 13.5px;
    color: var(--color-ink);
    text-transform: uppercase; letter-spacing: 0.04em;
  }
  .dash-recent-more {
    font-family: var(--font-sans); font-size: 12.5px; font-weight: 700;
    color: var(--color-blue); text-decoration: none;
  }
  .dash-recent-list { display: flex; flex-direction: column; gap: 8px; }

  .recent-row {
    display: grid;
    grid-template-columns: 40px 1fr auto;
    align-items: center; gap: 12px;
    padding: 10px 12px;
    background: var(--color-paper);
    border-radius: 10px;
    text-decoration: none;
    color: inherit;
    transition: background 0.15s;
  }
  .recent-row:hover { background: var(--color-paper-2); }
  .recent-row-date {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    text-align: center;
  }
  .recent-day {
    font-family: var(--font-display); font-weight: 500; font-size: 17px;
    line-height: 1; color: var(--color-ink);
  }
  .recent-month {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--color-muted); margin-top: 2px;
  }
  .recent-row-body { min-width: 0; }
  .recent-row-meta {
    display: flex; align-items: center; gap: 6px; margin-bottom: 2px;
  }
  .recent-tag {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 2px 6px; border-radius: 3px;
    font-weight: 700;
  }
  .recent-tag.civique { background: var(--color-blue-light); color: var(--color-blue); }
  .recent-tag.tcf { background: var(--color-red-light); color: var(--color-red); }
  .recent-type {
    font-size: 12.5px; font-weight: 600; color: var(--color-ink);
  }
  .recent-pulse {
    color: var(--color-amber); font-size: 12px;
    animation: recent-pulse 1.4s ease-in-out infinite;
  }
  @keyframes recent-pulse {
    0%, 100% { opacity: 0.5; }
    50% { opacity: 1; }
  }
  .recent-row-stats {
    font-size: 12px; color: var(--color-muted);
  }
  .recent-badge {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.1em; text-transform: uppercase;
    padding: 4px 9px; border-radius: 100px;
    font-weight: 700;
    flex-shrink: 0;
  }
  .recent-badge.good { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .recent-badge.warn { background: var(--color-red-light); color: var(--color-red); }
  .recent-badge.neutral { background: #fff; color: var(--color-muted); border: 1px solid var(--color-line); }

  /* COMPTE */
  .dash-account {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 20px 24px;
  }
  .dash-account h3 {
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
    margin: 0 0 14px;
  }
  .dash-row {
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid var(--color-line-2);
    font-size: 14px;
  }
  .dash-row:last-of-type { border-bottom: none; }
  .dash-row-l { color: var(--color-muted); }
  .dash-row-v {
    color: var(--color-ink); font-weight: 500;
    font-family: var(--font-mono); font-size: 13px;
  }
`;
