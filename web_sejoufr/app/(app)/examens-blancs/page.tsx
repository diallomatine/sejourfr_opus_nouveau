"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ModuleSwitch } from "@/app/_components/ModuleSwitch";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ApiException, examApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type ExamTemplateSummary,
  type Module as ModuleEnum,
} from "@/lib/types";

const EMPTY_EXAMS: ExamTemplateSummary[] = [];

export default function ExamensBlancsPage() {
  const { user, status } = useAuth();

  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [data, setData] = useState<{
    loading: boolean;
    exams: ExamTemplateSummary[];
    error: string | null;
    /** Module pour lequel la liste a été chargée (évite l'affichage de civiques en onglet TCF). */
    loadedFor: ModuleEnum | null;
  }>({ loading: true, exams: [], error: null, loadedFor: null });
  const [showPaywall, setShowPaywall] = useState(false);

  const isPremiumForModule = user !== null && canAccessModule(user, module);
  const upsellPlan = module === "TCF" ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS";

  useEffect(() => {
    let cancelled = false;
    examApi
      .list(module)
      .then((list) => {
        if (cancelled) return;
        setData({ loading: false, exams: list, error: null, loadedFor: module });
      })
      .catch((e) => {
        if (cancelled) return;
        setData({
          loading: false,
          exams: [],
          error:
            e instanceof ApiException
              ? e.message
              : "Impossible de charger la liste des examens. Vérifiez que le backend tourne.",
          loadedFor: module,
        });
      });
    return () => {
      cancelled = true;
    };
  }, [module]);

  // Si on est en train de charger un autre module, on masque l'ancienne liste.
  const exams = useMemo(
    () => (data.loadedFor === module ? data.exams : EMPTY_EXAMS),
    [data.loadedFor, data.exams, module],
  );
  const loading = data.loading || data.loadedFor !== module;
  const error = data.loadedFor === module ? data.error : null;

  const sorted = useMemo(
    () => [...exams].sort((a, b) => a.position - b.position),
    [exams],
  );
  const numbers = useMemo(() => {
    const map = new Map<string, number>();
    sorted.forEach((e, i) => map.set(e.id, i + 1));
    return map;
  }, [sorted]);
  const freeExams = sorted.filter((e) => e.free);
  const premiumExams = sorted.filter((e) => !e.free);

  if (status === "loading") return <div className="eb-loading" />;
  if (!user) {
    return (
      <main className="eb-gate">
        <p>Connectez-vous pour passer un examen blanc.</p>
        <Link href="/connexion?next=/examens-blancs" className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  return (
    <main className="eb">
      <section className="eb-head">
        <div className="eb-wrap">
          <span className="eyebrow">Examens blancs</span>
          <h1>
            Préparez-vous en <em>conditions réelles</em>.
          </h1>
          <p>
            1 examen offert par module, le reste avec l&apos;abonnement.
            Chronomètre, pas de correction live, score final officiel à la fin.
          </p>

          <div className="eb-module">
            <ModuleSwitch value={module} onChange={setModule} />
          </div>
        </div>
      </section>

      <section className="eb-body">
        <div className="eb-wrap">
          {!isPremiumForModule && (
            <button
              type="button"
              className="eb-demo-banner"
              onClick={() => setShowPaywall(true)}
            >
              <div className="eb-demo-icon" aria-hidden>
                <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
                </svg>
              </div>
              <div className="eb-demo-content">
                <div className="eb-demo-title">
                  1 examen blanc {module === "TCF" ? "TCF IRN" : "civique"} offert
                </div>
                <div className="eb-demo-sub">
                  {module === "TCF"
                    ? "L'Intégral débloque les autres examens TCF + tout le civique."
                    : "L'abonnement débloque tous les examens blancs civiques (CSP, CR, NAT)."}
                </div>
              </div>
              <div className="eb-demo-arrow">→</div>
            </button>
          )}

          {error && <div className="form-error">{error}</div>}
          {loading && exams.length === 0 && <ListSkeleton />}

          {!loading && !error && exams.length === 0 && (
            <div className="eb-empty">Aucun examen blanc publié pour ce module.</div>
          )}

          {freeExams.length > 0 && (
            <>
              <SectionLabel
                title="Accès libre"
                count={freeExams.length}
                hint={`Disponible ${isPremiumForModule ? "" : "sans abonnement"}`}
              />
              <div className="eb-grid">
                {freeExams.map((e) => (
                  <ExamCard
                    key={e.id}
                    exam={e}
                    number={numbers.get(e.id) ?? 0}
                    locked={false}
                  />
                ))}
              </div>
            </>
          )}

          {premiumExams.length > 0 && (
            <>
              <SectionLabel
                title="Examens abonnés"
                count={premiumExams.length}
                hint={
                  isPremiumForModule
                    ? "Tous accessibles avec votre abonnement"
                    : "Réservés aux abonnés"
                }
              />
              <div className="eb-grid">
                {premiumExams.map((e) => (
                  <ExamCard
                    key={e.id}
                    exam={e}
                    number={numbers.get(e.id) ?? 0}
                    locked={!isPremiumForModule}
                    onLockedClick={() => setShowPaywall(true)}
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </section>

      <PaywallSheet
        open={showPaywall}
        onClose={() => setShowPaywall(false)}
        title={
          module === "TCF"
            ? "Débloquez tous les examens TCF"
            : "Débloquez tous les examens civiques"
        }
        message={
          module === "TCF"
            ? "Vous avez 1 examen blanc TCF offert. L'abonnement Intégral débloque les diagnostics A2/B1/B2, le civique illimité et la révision des erreurs."
            : "Vous avez 1 examen blanc civique offert. L'abonnement débloque les examens CSP, CR et naturalisation, plus tout l'entraînement illimité."
        }
        plan={upsellPlan}
      />

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// CARD
// ============================================================================
function ExamCard({
  exam,
  number,
  locked,
  onLockedClick,
}: {
  exam: ExamTemplateSummary;
  number: number;
  locked: boolean;
  onLockedClick?: () => void;
}) {
  const minutes = Math.round(exam.durationSeconds / 60);
  const isTcf = exam.module === "TCF";
  const targetLabel =
    exam.module === "CIVIQUE"
      ? (exam.targetProcedure ?? "Tous parcours")
      : (exam.targetLevel ?? "Diagnostic");

  const content = (
    <>
      <div className="eb-card-num">{number.toString().padStart(2, "0")}</div>
      <div className="eb-card-body">
        <div className="eb-card-head">
          <span className={`eb-tag ${isTcf ? "tcf" : "civique"}`}>
            {isTcf ? "TCF IRN" : "Civique"}
          </span>
          <span className="eb-target">{targetLabel}</span>
        </div>
        <h3 className="eb-card-title">{exam.name}</h3>
        {exam.subtitle && <p className="eb-card-sub">{exam.subtitle}</p>}
        <div className="eb-card-stats">
          <span><strong>{exam.totalQuestions}</strong> questions</span>
          <span className="dot">·</span>
          <span><strong>{minutes}</strong> min</span>
          {!isTcf && (
            <>
              <span className="dot">·</span>
              <span>seuil <strong>{exam.passingScore}</strong></span>
            </>
          )}
        </div>
      </div>
      <div className="eb-card-cta">
        {locked ? (
          <>
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            Abonnés
          </>
        ) : (
          <>Démarrer →</>
        )}
      </div>
    </>
  );

  if (locked) {
    return (
      <button
        type="button"
        className="eb-card eb-card-locked"
        onClick={onLockedClick}
      >
        {content}
      </button>
    );
  }

  return (
    <Link href={`/examens-blancs/${exam.slug}`} className="eb-card">
      {content}
    </Link>
  );
}

function SectionLabel({ title, count, hint }: { title: string; count: number; hint: string }) {
  return (
    <div className="eb-section">
      <div className="eb-section-head">
        <span className="eb-section-title">{title}</span>
        <span className="eb-section-count">{count}</span>
      </div>
      <span className="eb-section-hint">{hint}</span>
    </div>
  );
}

function ListSkeleton() {
  return (
    <div className="eb-grid">
      {[0, 1, 2, 3].map((i) => (
        <div key={i} className="eb-card eb-card-skeleton" />
      ))}
    </div>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .eb { background: var(--color-paper); min-height: calc(100vh - 110px); }
  .eb-loading { min-height: 60vh; }
  .eb-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
  }

  .eb-head { padding: 40px 16px 24px; text-align: center; }
  .eb-wrap { max-width: 920px; margin: 0 auto; }
  .eb-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .eb-head h1 em { font-style: italic; color: var(--color-red); }
  .eb-head p {
    color: var(--color-muted); font-size: 15px; line-height: 1.55;
    margin: 0 auto 22px; max-width: 540px;
  }
  .eb-module { max-width: 460px; margin: 0 auto; }

  .eb-body { padding: 8px 16px 80px; }

  .eb-demo-banner {
    display: flex; align-items: center; gap: 12px;
    width: 100%;
    background: rgba(232, 163, 23, 0.08);
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 12px 14px;
    margin: 18px 0 28px;
    cursor: pointer;
    transition: background 0.15s;
    text-align: left;
    font-family: var(--font-sans);
  }
  .eb-demo-banner:hover { background: rgba(232, 163, 23, 0.14); }
  .eb-demo-icon {
    width: 38px; height: 38px;
    background: rgba(232, 163, 23, 0.16);
    color: var(--color-amber);
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .eb-demo-content { flex: 1; min-width: 0; }
  .eb-demo-title {
    font-weight: 800; font-size: 13.5px; color: var(--color-ink); line-height: 1.2;
  }
  .eb-demo-sub {
    font-size: 12px; color: var(--color-muted); line-height: 1.4; margin-top: 3px;
  }
  .eb-demo-arrow { color: var(--color-amber); font-size: 16px; flex-shrink: 0; }

  .eb-section {
    display: flex; align-items: baseline; justify-content: space-between;
    gap: 12px;
    padding: 28px 0 14px;
  }
  .eb-section-head { display: inline-flex; align-items: center; gap: 8px; }
  .eb-section-title {
    font-family: var(--font-sans); font-weight: 800; font-size: 15px; color: var(--color-ink);
  }
  .eb-section-count {
    font-family: var(--font-mono);
    background: var(--color-line-2); color: var(--color-muted);
    padding: 2px 8px; border-radius: 100px;
    font-size: 11px; letter-spacing: 0.08em; font-weight: 700;
  }
  .eb-section-hint {
    font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.12em;
    color: var(--color-muted-2); text-transform: uppercase;
  }

  .eb-grid {
    display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px;
  }
  @media (max-width: 720px) {
    .eb-grid { grid-template-columns: 1fr; }
  }

  .eb-card {
    display: grid;
    grid-template-columns: 48px 1fr auto;
    align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px 18px;
    text-decoration: none;
    color: inherit;
    font-family: var(--font-sans);
    transition: all 0.18s;
    box-shadow: 0 2px 10px -4px rgba(30, 58, 140, 0.04);
    text-align: left;
    cursor: pointer;
    width: 100%;
    border: none;
    border: 1px solid var(--color-line);
  }
  .eb-card:hover {
    transform: translateY(-2px);
    border-color: var(--color-blue);
    box-shadow: 0 14px 30px -16px rgba(30, 58, 140, 0.22);
  }
  .eb-card.eb-card-locked {
    background: var(--color-paper);
    opacity: 0.88;
  }
  .eb-card.eb-card-locked:hover {
    border-color: var(--color-muted-2);
    box-shadow: none;
    transform: none;
  }
  .eb-card-skeleton {
    height: 96px;
    animation: eb-pulse 1.4s ease-in-out infinite;
  }
  @keyframes eb-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }

  .eb-card-num {
    font-family: var(--font-display);
    font-size: 26px; font-weight: 500;
    color: var(--color-blue);
    letter-spacing: -0.03em;
    line-height: 1;
    text-align: center;
  }
  .eb-card-locked .eb-card-num { color: var(--color-muted-2); }
  .eb-card-body { min-width: 0; }
  .eb-card-head {
    display: flex; align-items: center; gap: 8px; margin-bottom: 4px;
    flex-wrap: wrap;
  }
  .eb-tag {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    padding: 3px 8px; border-radius: 4px;
    font-weight: 700;
  }
  .eb-tag.civique { background: var(--color-blue-light); color: var(--color-blue); }
  .eb-tag.tcf { background: var(--color-red-light); color: var(--color-red); }
  .eb-target {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--color-muted);
  }
  .eb-card-title {
    font-family: var(--font-sans); font-weight: 700; font-size: 15px;
    line-height: 1.25;
    color: var(--color-ink);
    margin: 0;
    overflow: hidden; text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  .eb-card-sub {
    font-size: 12.5px; color: var(--color-muted);
    margin: 3px 0 0; line-height: 1.4;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .eb-card-stats {
    font-family: var(--font-mono); font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.06em;
    margin-top: 8px;
    display: flex; flex-wrap: wrap; align-items: center; gap: 4px;
  }
  .eb-card-stats strong {
    color: var(--color-ink); font-weight: 700;
    font-family: var(--font-mono);
  }
  .eb-card-stats .dot { color: var(--color-muted-2); }

  .eb-card-cta {
    font-family: var(--font-sans);
    font-size: 13px; font-weight: 600;
    color: var(--color-blue);
    display: inline-flex; align-items: center; gap: 4px;
    flex-shrink: 0;
  }
  .eb-card-locked .eb-card-cta { color: var(--color-muted); }

  .eb-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 14px;
    padding: 48px 16px;
    text-align: center;
    color: var(--color-muted);
    font-size: 14px;
  }
`;
