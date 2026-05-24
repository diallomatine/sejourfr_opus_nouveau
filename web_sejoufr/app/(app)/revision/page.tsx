"use client";

import Link from "next/link";
import {useSearchParams} from "next/navigation";
import {Suspense, useCallback, useEffect, useMemo, useState} from "react";
import {ApiException, userContentApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type Module as ModuleEnum, type QuestionReviewResponse} from "@/lib/types";
import {QuestionDetailModal} from "@/app/_components/QuestionDetailModal";

type Tab = "erreurs" | "favoris";

export default function RevisionPage() {
    return (
        <Suspense fallback={<RevisionSkeleton/>}>
            <RevisionInner/>
        </Suspense>
    );
}

function RevisionInner() {
    const searchParams = useSearchParams();
    const {user, status} = useAuth();

    const urlTab: Tab = useMemo(() => {
        const t = searchParams?.get("tab");
        return t === "favoris" ? "favoris" : "erreurs";
    }, [searchParams]);

    const urlModule: ModuleEnum = useMemo(() => {
        const m = searchParams?.get("module");
        return m === "TCF" ? "TCF" : "CIVIQUE";
    }, [searchParams]);

    const [module, setModule] = useState<ModuleEnum>(urlModule);
    const [tab, setTab] = useState<Tab>(urlTab);

    // Sync sur les changements d'URL : navigation depuis la sidebar
    // (?tab=erreurs ↔ ?tab=favoris) doit basculer l'onglet visible sans
    // remonter le composant.
    useEffect(() => {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setTab(urlTab);
    }, [urlTab]);
    useEffect(() => {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setModule(urlModule);
    }, [urlModule]);

    const [errors, setErrors] = useState<QuestionReviewResponse[]>([]);
    const [favorites, setFavorites] = useState<QuestionReviewResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [selectedQuestion, setSelectedQuestion] = useState<QuestionReviewResponse | null>(null);

    const refresh = useCallback(async (m: ModuleEnum) => {
        setLoading(true);
        try {
            const [wrongList, favList] = await Promise.all([
                userContentApi.wrong(m),
                userContentApi.favorites(m),
            ]);
            setErrors(wrongList);
            setFavorites(favList);
            setLoadError(null);
        } catch (e) {
            setLoadError(
                e instanceof ApiException
                    ? e.message
                    : "Impossible de charger la révision.",
            );
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        refresh(module).then(() => {
            if (cancelled) return;
        });
        return () => {
            cancelled = true;
        };
    }, [module, refresh, status]);

    const onToggleFavorite = useCallback(
        async (q: QuestionReviewResponse, wasFavorite: boolean) => {
            // Optimiste : retire/ajoute, rollback en cas d'échec via refresh complet.
            if (wasFavorite) {
                setFavorites((prev) => prev.filter((x) => x.id !== q.id));
            } else {
                setFavorites((prev) => [q, ...prev.filter((x) => x.id !== q.id)]);
            }
            try {
                if (wasFavorite) {
                    await userContentApi.removeFavorite(q.id);
                } else {
                    await userContentApi.addFavorite(q.id);
                }
            } catch {
                await refresh(module);
            }
        },
        [module, refresh],
    );

    const list = tab === "erreurs" ? errors : favorites;

    if (status === "loading") return <RevisionSkeleton/>;
    if (!user) {
        return (
            <main className="rv-gate">
                <p>Connectez-vous pour réviser vos questions.</p>
                <Link href="/connexion?next=/revision" className="rv-gate-cta">
                    Se connecter →
                </Link>
                <style>{gateStyles}</style>
            </main>
        );
    }

    return (
        <main className="rv">
            {/* ============ TOPBAR ============ */}
            <header className="topbar">
                <div>
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span> RÉVISION{" "}
                        <span className="sep">/</span>{" "}
                        {tab === "erreurs" ? "MES ERREURS" : "MES FAVORIS"}
                    </div>
                    <h1>
                        Retravaillez ce qui <em>résiste</em>.
                    </h1>
                </div>
                <div className="topbar-actions">
                    <Link href="/entrainement" className="btn-outline">
                        Entraînement →
                    </Link>
                </div>
            </header>

            {/* ============ MODULE TABS ============ */}
            <div className="filters">
                <div className="filter-tabs" role="tablist" aria-label="Module">
                    <button
                        type="button"
                        role="tab"
                        aria-selected={module === "CIVIQUE"}
                        className={`tab tab-blue ${module === "CIVIQUE" ? "is-active" : ""}`}
                        onClick={() => setModule("CIVIQUE")}
                    >
                        Civique
                    </button>
                    <button
                        type="button"
                        role="tab"
                        aria-selected={module === "TCF"}
                        className={`tab tab-red ${module === "TCF" ? "is-active" : ""}`}
                        onClick={() => setModule("TCF")}
                    >
                        TCF
                    </button>
                </div>
            </div>

            {/* ============ SECTION TABS (Erreurs / Favoris) ============ */}
            <div className="section-tabs" role="tablist" aria-label="Section">
                <button
                    type="button"
                    role="tab"
                    aria-selected={tab === "erreurs"}
                    className={`section-tab ${tab === "erreurs" ? "is-active" : ""}`}
                    onClick={() => setTab("erreurs")}
                >
          <span className="section-tab-icon section-tab-icon-red">
            <XCircleIcon/>
          </span>
                    <span className="section-tab-text">
            <span className="section-tab-label">Mes erreurs</span>
            <span className="section-tab-desc">À retravailler en priorité</span>
          </span>
                    <span className="section-tab-count">{errors.length}</span>
                </button>
                <button
                    type="button"
                    role="tab"
                    aria-selected={tab === "favoris"}
                    className={`section-tab ${tab === "favoris" ? "is-active" : ""}`}
                    onClick={() => setTab("favoris")}
                >
          <span className="section-tab-icon section-tab-icon-blue">
            <StarIcon/>
          </span>
                    <span className="section-tab-text">
            <span className="section-tab-label">Favoris</span>
            <span className="section-tab-desc">Mises de côté pour plus tard</span>
          </span>
                    <span className="section-tab-count">{favorites.length}</span>
                </button>
            </div>

            {/* ============ LIST ============ */}
            {loadError && <div className="form-error rv-error">{loadError}</div>}

            {loading ? (
                <ListSkeleton/>
            ) : list.length === 0 ? (
                <EmptyState tab={tab} module={module}/>
            ) : (
                <div className="rv-list">
                    {list.map((q) => (
                        <QuestionRow
                            key={q.id}
                            question={q}
                            tab={tab}
                            isFavorite={favorites.some((f) => f.id === q.id)}
                            onClick={() => setSelectedQuestion(q)}
                        />
                    ))}
                </div>
            )}

            {selectedQuestion && (
                <QuestionDetailModal
                    question={selectedQuestion}
                    isFavorite={favorites.some((f) => f.id === selectedQuestion.id)}
                    onClose={() => setSelectedQuestion(null)}
                    onToggleFavorite={(was) => onToggleFavorite(selectedQuestion, was)}
                />
            )}

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// QUESTION ROW
// ============================================================================
function QuestionRow({
                         question,
                         tab,
                         isFavorite,
                         onClick,
                     }: {
    question: QuestionReviewResponse;
    tab: Tab;
    isFavorite: boolean;
    onClick: () => void;
}) {
    const isErr = tab === "erreurs";
    return (
        <button type="button" className={`rv-row rv-row-${isErr ? "red" : "blue"}`} onClick={onClick}>
      <span className={`rv-row-marker rv-row-marker-${isErr ? "red" : "blue"}`}>
        {isErr ? <XCircleIcon/> : <StarIcon/>}
      </span>
            <div className="rv-row-body">
                <div className="rv-row-meta">
                    <span className="rv-tag rv-tag-blue">{question.themeName}</span>
                    <span className="rv-tag rv-tag-mono">{question.difficulty}</span>
                    {isFavorite && !isErr ? null : isFavorite ? (
                        <span className="rv-tag rv-tag-fav" aria-label="En favoris">
              <StarIcon/>
            </span>
                    ) : null}
                </div>
                <p className="rv-row-statement">{question.statement}</p>
            </div>
            <span className="rv-row-arrow" aria-hidden>
        ›
      </span>
        </button>
    );
}

// ============================================================================
// EMPTY STATES
// ============================================================================
function EmptyState({tab, module}: { tab: Tab; module: ModuleEnum }) {
    const moduleLabel = module === "TCF" ? "TCF" : "civique";
    if (tab === "erreurs") {
        return (
            <div className="rv-empty">
                <div className="rv-empty-icon rv-empty-icon-green">
                    <svg
                        viewBox="0 0 24 24"
                        width="28"
                        height="28"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    >
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                        <path d="m9 11 3 3L22 4"/>
                    </svg>
                </div>
                <h3>Aucune erreur récente en {moduleLabel}</h3>
                <p>
                    Bravo ! Continuez à vous entraîner pour faire émerger les zones à
                    retravailler.
                </p>
                <Link href="/entrainement" className="btn-primary">
                    Lancer un entraînement →
                </Link>
            </div>
        );
    }
    return (
        <div className="rv-empty">
            <div className="rv-empty-icon rv-empty-icon-blue">
                <StarIcon/>
            </div>
            <h3>Aucun favori en {moduleLabel}</h3>
            <p>
                Pendant un entraînement, cliquez sur l&apos;icône étoile (ou la touche{" "}
                <kbd>B</kbd>) pour mettre une question de côté.
            </p>
            <Link href="/entrainement" className="btn-primary">
                Lancer un entraînement →
            </Link>
        </div>
    );
}

function ListSkeleton() {
    return (
        <div className="rv-list">
            {[0, 1, 2, 3].map((i) => (
                <div key={i} className="rv-row rv-row-skeleton"/>
            ))}
        </div>
    );
}

function RevisionSkeleton() {
    return (
        <div className="rv-loading">
            <style>{`.rv-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
        </div>
    );
}

const gateStyles = `
  .rv-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .rv-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// ============================================================================
// ICONS
// ============================================================================
const I = (props: React.SVGProps<SVGSVGElement>) => (
    <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        {...props}
    />
);
const XCircleIcon = () => (
    <I>
        <circle cx="12" cy="12" r="10"/>
        <line x1="15" y1="9" x2="9" y2="15"/>
        <line x1="9" y1="9" x2="15" y2="15"/>
    </I>
);
const StarIcon = ({filled = false}: { filled?: boolean }) => (
    <I fill={filled ? "currentColor" : "none"}>
        <polygon
            points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
    </I>
);
// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .rv { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .rv { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    gap: 16px; flex-wrap: wrap;
    margin-bottom: 20px;
  }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.2vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0;
    line-height: 1.15;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
  .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
    font-family: inherit;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .btn-primary {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid transparent;
    background: var(--color-blue); color: #fff;
    transition: all 0.15s;
    cursor: pointer;
    font-family: inherit;
  }
  .btn-primary:hover { background: var(--color-blue-dark); }

  .rv-error { margin-bottom: 18px; }

  /* ========== MODULE TABS ========== */
  .filters {
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    margin-bottom: 18px;
  }
  .filter-tabs {
    display: inline-flex;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 4px;
    gap: 2px;
  }
  .tab {
    padding: 8px 18px;
    background: transparent;
    border: none;
    border-radius: 8px;
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .tab:hover { color: var(--color-ink); }
  .tab.tab-blue.is-active { background: var(--color-blue); color: #fff; }
  .tab.tab-red.is-active { background: var(--color-red); color: #fff; }

  /* ========== SECTION TABS ========== */
  .section-tabs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
    margin-bottom: 22px;
  }
  .section-tab {
    display: flex; align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px 20px;
    cursor: pointer;
    font-family: inherit;
    text-align: left;
    transition: all 0.15s;
    position: relative;
    overflow: hidden;
  }
  .section-tab:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 24px -14px rgba(15, 24, 57, 0.18);
  }
  .section-tab.is-active {
    border-width: 2px;
    padding: 17px 19px;
  }
  .section-tab.is-active::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 3px;
  }
  .section-tab:first-child.is-active {
    border-color: var(--color-red);
  }
  .section-tab:first-child.is-active::before { background: var(--color-red); }
  .section-tab:last-child.is-active {
    border-color: var(--color-blue);
  }
  .section-tab:last-child.is-active::before { background: var(--color-blue); }
  .section-tab-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .section-tab-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .section-tab-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .section-tab-text { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
  .section-tab-label {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 18px;
    color: var(--color-ink);
    letter-spacing: -0.015em;
    line-height: 1.2;
  }
  .section-tab-desc {
    font-size: 12.5px;
    color: var(--color-muted);
  }
  .section-tab-count {
    font-family: var(--font-mono);
    font-size: 22px;
    font-weight: 700;
    color: var(--color-ink);
    flex-shrink: 0;
    letter-spacing: -0.02em;
  }

  @media (max-width: 680px) {
    .section-tabs { grid-template-columns: 1fr; }
  }

  /* ========== LIST ========== */
  .rv-list { display: flex; flex-direction: column; gap: 8px; }
  .rv-row {
    display: grid;
    grid-template-columns: 36px 1fr 24px;
    align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 16px;
    text-align: left;
    cursor: pointer;
    font-family: var(--font-sans);
    transition: all 0.15s;
    width: 100%;
  }
  .rv-row:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 20px -12px rgba(15, 24, 57, 0.18);
  }
  .rv-row-red:hover { border-color: var(--color-red); }
  .rv-row-blue:hover { border-color: var(--color-blue); }
  .rv-row-skeleton {
    height: 76px;
    animation: rv-pulse 1.4s ease-in-out infinite;
  }
  @keyframes rv-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }
  .rv-row-marker {
    width: 32px; height: 32px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .rv-row-marker-red {
    background: var(--color-red-light);
    color: var(--color-red);
  }
  .rv-row-marker-blue {
    background: var(--color-blue-light);
    color: var(--color-blue);
  }
  .rv-row-body { min-width: 0; }
  .rv-row-meta {
    display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
    margin-bottom: 6px;
  }
  .rv-row-statement {
    margin: 0;
    font-weight: 600; font-size: 14.5px; line-height: 1.4;
    color: var(--color-ink);
    overflow: hidden; text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  .rv-row-arrow {
    color: var(--color-muted-2); font-size: 20px;
    flex-shrink: 0;
  }
  .rv-tag {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    font-weight: 700;
  }
  .rv-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .rv-tag-mono { background: var(--color-paper-2); color: var(--color-muted); }
  .rv-tag-fav {
    background: var(--color-blue-light);
    color: var(--color-blue);
    display: inline-flex; align-items: center;
    padding: 3px 5px;
  }

  /* ----- Empty state ----- */
  .rv-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 16px;
    padding: 60px 32px;
    text-align: center;
  }
  .rv-empty-icon {
    width: 56px; height: 56px;
    margin: 0 auto 14px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .rv-empty-icon-green { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .rv-empty-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .rv-empty h3 {
    font-family: var(--font-display); font-weight: 600; font-size: 22px;
    color: var(--color-ink); margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .rv-empty p {
    color: var(--color-muted); font-size: 13.5px; line-height: 1.55;
    margin: 0 auto 18px; max-width: 380px;
  }
  .rv-empty kbd {
    background: var(--color-paper-2);
    padding: 1px 6px; border-radius: 4px;
    font-family: var(--font-mono); font-size: 11px;
    color: var(--color-ink);
  }
`;
