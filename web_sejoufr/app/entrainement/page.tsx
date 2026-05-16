"use client";

import Link from "next/link";
import {useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {Lock} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {TargetPathBanner} from "@/app/_components/TargetPathBanner";
import {
  ApiException,
  attemptApi,
  examApi,
  publicAttemptApi,
  publicExamApi,
  publicThemeApi,
  statsApi,
  themeApi,
} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  type AuthenticatedUser,
  canAccessModule,
  type ExamTemplateSummary,
  type Module as ModuleEnum,
  type ThemeUserResponse,
  type UserStatsResponse,
} from "@/lib/types";

const DEMO_BATCH_SIZE = 20;
const PREMIUM_BATCH_SIZE = 30;

type Filter = "CIVIQUE" | "TCF";

export default function EntrainementPage() {
    return (
        <Suspense fallback={<EntrainementSkeleton/>}>
            <EntrainementRoot/>
        </Suspense>
    );
}

function EntrainementRoot() {
    const {status, user} = useAuth();
    if (status === "loading") return <EntrainementSkeleton/>;
    const safeUser = status === "authenticated" ? user : null;
    // Connecté → on emballe dans le DualChromeShell pour avoir la sidebar.
    // Guest → on garde le chrome public (SiteHeader/Footer rendus par le layout racine).
    if (safeUser) {
        return (
            <DualChromeShell>
                <EntrainementHub user={safeUser}/>
            </DualChromeShell>
        );
    }
    return <EntrainementHub user={null}/>;
}

// ============================================================================
// HUB (rendu unifié guest ↔ connecté)
// ============================================================================

function EntrainementHub({user}: { user: AuthenticatedUser | null }) {
    const router = useRouter();
    const searchParams = useSearchParams();
    const isGuest = user === null;

    // Filter pré-rempli depuis le query string (?module=CIVIQUE|TCF).
    // Navigation interne (Link footer) ne remount pas la page → on resynchronise
    // l'état local quand searchParams change.
    const filterFromUrl: Filter = useMemo(() => {
        const m = searchParams?.get("module");
        return m === "TCF" ? "TCF" : "CIVIQUE";
    }, [searchParams]);

    const [filter, setFilter] = useState<Filter>(filterFromUrl);
    useEffect(() => {
        setFilter(filterFromUrl);
    }, [filterFromUrl]);
    const [query, setQuery] = useState("");
    const [themes, setThemes] = useState<Record<ModuleEnum, ThemeUserResponse[]>>({
        CIVIQUE: [],
        TCF: [],
    });
    const [statsByModule, setStatsByModule] = useState<
        Partial<Record<ModuleEnum, UserStatsResponse | null>>
    >({});
    const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [startingThemeId, setStartingThemeId] = useState<string | null>(null);
    const [startingExamId, setStartingExamId] = useState<string | null>(null);
    const [paywallModule, setPaywallModule] = useState<ModuleEnum | null>(null);

    // ========== LOAD ==========
    useEffect(() => {
        let cancelled = false;
        setLoading(true);

        const themeFetcher = isGuest ? publicThemeApi.list : themeApi.list;
        const examFetcher = isGuest ? publicExamApi.list : examApi.list;

        Promise.allSettled([
            themeFetcher("CIVIQUE"),
            themeFetcher("TCF"),
            isGuest
                ? Promise.resolve(null)
                : statsApi.get("CIVIQUE").catch(() => null),
            isGuest ? Promise.resolve(null) : statsApi.get("TCF").catch(() => null),
            examFetcher(),
        ]).then((results) => {
            if (cancelled) return;
            const [civT, tcfT, civS, tcfS, exL] = results;
            setThemes({
                CIVIQUE: civT.status === "fulfilled" ? civT.value : [],
                TCF: tcfT.status === "fulfilled" ? tcfT.value : [],
            });
            setStatsByModule({
                CIVIQUE: civS.status === "fulfilled" ? civS.value : null,
                TCF: tcfS.status === "fulfilled" ? tcfS.value : null,
            });
            setExams(exL.status === "fulfilled" ? exL.value : []);
            setLoading(false);
        });
        return () => {
            cancelled = true;
        };
    }, [isGuest]);

    const isPremiumCivique = !isGuest && canAccessModule(user, "CIVIQUE");
    const isPremiumTcf = !isGuest && canAccessModule(user, "TCF");
    // Guest = toujours en démo sur les 2 modules. Connecté = démo si pas premium.
    const showDemoBanner = isGuest || !isPremiumCivique || !isPremiumTcf;

    // ========== STARTERS ==========
    async function startTraining(opts: {
        module: ModuleEnum;
        themeId?: string;
        label: string; // pour startingThemeId
    }) {
        const {module, themeId, label} = opts;
        const isPremium = module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf;

        // Thème spécifique verrouillé : la démo ne couvre que le mixte du module.
        // Guest → inscription, connecté non-premium → paywall. (Le mixed passe.)
        if (themeId && !isPremium) {
            if (isGuest) {
                router.push("/connexion");
            } else {
                setPaywallModule(module);
            }
            return;
        }

        setError(null);
        setStartingThemeId(label);
        try {
            const size = isPremium ? PREMIUM_BATCH_SIZE : DEMO_BATCH_SIZE;
            const body = themeId
                ? {type: "TRAINING" as const, module, themeId, size}
                : {type: "TRAINING" as const, module, size};
            const a = isGuest
                ? await publicAttemptApi.startDemo(body)
                : await attemptApi.start(body);
            router.push(`/sessions/${a.id}`);
        } catch (e) {
            setError(
                e instanceof ApiException
                    ? e.message
                    : "Impossible de démarrer l'entraînement.",
            );
            setStartingThemeId(null);
        }
    }

    async function startExam(exam: ExamTemplateSummary) {
        const isPremium = exam.module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf;
        // Connecté non-premium qui clique sur un exam non-free → paywall.
        if (!isGuest && !isPremium && !exam.free) {
            setPaywallModule(exam.module);
            return;
        }
        // Guest sur un exam non-free → push compte.
        if (isGuest && !exam.free) {
            return;
        }

        setError(null);
        setStartingExamId(exam.id);
        try {
            const body = {
                type: "MOCK_EXAM" as const,
                module: exam.module,
                examTemplateId: exam.id,
            };
            const a = isGuest
                ? await publicAttemptApi.startDemo(body)
                : await attemptApi.start(body);
            router.push(`/sessions/${a.id}`);
        } catch (e) {
            setError(
                e instanceof ApiException
                    ? e.message
                    : "Impossible de démarrer l'examen.",
            );
            setStartingExamId(null);
        }
    }

    // ========== DERIVED ==========
    const mastery = useMemo(
        () => buildMastery(statsByModule),
        [statsByModule],
    );

    const filteredThemes = useMemo(() => {
        const list = themes[filter] ?? [];
        const q = query.trim().toLowerCase();
        if (!q) return list;
        return list.filter(
            (t) =>
                t.name.toLowerCase().includes(q) ||
                t.code.toLowerCase().includes(q),
        );
    }, [filter, query, themes]);

    const visibleMixedModules: ModuleEnum[] = useMemo(
        () => (query.trim() ? [] : [filter]),
        [filter, query],
    );

    // Exams pour la section "Examens blancs" : on prend le 1er free de chaque
    // module + les autres en mode locked.
    const examsForFilter = useMemo(
        () => exams.filter((e) => e.module === filter),
        [exams, filter],
    );
    const freeExam = useMemo(
        () => examsForFilter.find((e) => e.free) ?? null,
        [examsForFilter],
    );
    const lockedExams = useMemo(
        () => examsForFilter.filter((e) => !e.free),
        [examsForFilter],
    );
    const isPremiumForFilter = filter === "CIVIQUE" ? isPremiumCivique : isPremiumTcf;

    // CTAs pour les locked exams : tarifs si connecté, inscription si guest.
    const upsellHref = isGuest ? "/connexion" : "/paiement";
    const upsellLabel = isGuest ? "Se connecter" : "Voir les tarifs";

    return (
        <main className="train">
            {/* ============ TOPBAR ============ */}
            <header className="topbar">
                <div>
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span> ENTRAÎNEMENT
                    </div>
                    <h1>
                        Choisissez une <em>thématique</em>.
                    </h1>
                </div>
                {!isGuest && (
                    <div className="topbar-actions">
                        <Link href="/revision" className="btn-outline">
                            Mes erreurs
                        </Link>
                    </div>
                )}
            </header>

            {/* parcours visé (connecté avec target seulement) */}
            {!isGuest && user.targetProcedure && (
                <div className="train-target">
                    <TargetPathBanner
                        procedure={user.targetProcedure ?? null}
                        level={user.targetLevel ?? null}
                    />
                </div>
            )}

            {/* démo banner */}
            {showDemoBanner && (
                <DemoBanner
                    isGuest={isGuest}
                    isPremiumCivique={isPremiumCivique}
                    isPremiumTcf={isPremiumTcf}
                    onOpenPaywall={(m) => setPaywallModule(m)}
                />
            )}

            {/* ============ FILTERS ============ */}
            <div className="filters">
                <div className="filter-tabs" role="tablist" aria-label="Module">
                    <button
                        type="button"
                        role="tab"
                        aria-selected={filter === "CIVIQUE"}
                        className={`tab tab-blue ${filter === "CIVIQUE" ? "is-active" : ""}`}
                        onClick={() => setFilter("CIVIQUE")}
                    >
                        Civique
                    </button>
                    <button
                        type="button"
                        role="tab"
                        aria-selected={filter === "TCF"}
                        className={`tab tab-red ${filter === "TCF" ? "is-active" : ""}`}
                        onClick={() => setFilter("TCF")}
                    >
                        TCF
                    </button>
                </div>
                <div className="search-wrap">
                    <svg
                        width="14"
                        height="14"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        aria-hidden
                    >
                        <circle cx="11" cy="11" r="8"/>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                    <input
                        type="search"
                        value={query}
                        onChange={(e) => setQuery(e.target.value)}
                        placeholder="Rechercher un thème…"
                        aria-label="Rechercher une thématique"
                    />
                </div>
            </div>

            {error && <div className="form-error train-error">{error}</div>}

            {/* ============ GRID ============ */}
            {loading ? (
                <ThemesGridSkeleton/>
            ) : (
                <div className="theme-grid">
                    {visibleMixedModules.map((m) => (
                        <MixedCard
                            key={`mixed-${m}`}
                            module={m}
                            isPremium={m === "CIVIQUE" ? isPremiumCivique : isPremiumTcf}
                            isGuest={isGuest}
                            onClick={() =>
                                startTraining({module: m, label: `__mixed_${m}`})
                            }
                            starting={startingThemeId === `__mixed_${m}`}
                        />
                    ))}
                    {filteredThemes.map((t) => (
                        <ThemeTile
                            key={t.id}
                            theme={t}
                            mastery={isGuest ? null : (mastery.byTheme[t.id] ?? null)}
                            isPremium={
                                t.module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf
                            }
                            isGuest={isGuest}
                            onClick={() =>
                                startTraining({
                                    module: t.module,
                                    themeId: t.id,
                                    label: t.id,
                                })
                            }
                            starting={startingThemeId === t.id}
                        />
                    ))}
                    {filteredThemes.length === 0 && visibleMixedModules.length === 0 && (
                        <div className="theme-empty">
                            <p>Aucun thème ne correspond à votre recherche.</p>
                            <button
                                type="button"
                                className="theme-empty-cta"
                                onClick={() => setQuery("")}
                            >
                                Effacer la recherche
                            </button>
                        </div>
                    )}
                </div>
            )}

            {/* ============ EXAMENS BLANCS ============ */}
            {/* Section masquée pour les connectés : ils ont déjà /examens-blancs
                dans la sidebar — éviter la redondance. */}
            {isGuest && (
                <section className="exams-section">
                    <div className="exams-section-head">
                        <h2>Examens blancs</h2>
                        <p>
                            Conditions réelles d&apos;examen : 40 questions chronométrées en
                            45 minutes pour CIVIQUE, 60 questions en 90 minutes pour TCF.
                        </p>
                    </div>

                    {loading ? (
                        <div className="exams-grid">
                            {Array.from({length: 3}).map((_, i) => (
                                <div key={i} className="exam-skel"/>
                            ))}
                        </div>
                    ) : examsForFilter.length === 0 ? (
                        <div className="exams-empty">
                            Aucun examen blanc disponible pour ce module.
                        </div>
                    ) : (
                        <div className="exams-grid">
                            {freeExam && (
                                <ExamCard
                                    exam={freeExam}
                                    tone={filter === "CIVIQUE" ? "blue" : "red"}
                                    locked={false}
                                    onStart={() => startExam(freeExam)}
                                    starting={startingExamId === freeExam.id}
                                    ctaLabel="Démo gratuite →"
                                    upsellHref={upsellHref}
                                />
                            )}
                            {lockedExams.map((e) => (
                                <ExamCard
                                    key={e.id}
                                    exam={e}
                                    tone={filter === "CIVIQUE" ? "blue" : "red"}
                                    locked={true}
                                    onStart={() => startExam(e)}
                                    starting={startingExamId === e.id}
                                    ctaLabel={upsellLabel}
                                    upsellHref={upsellHref}
                                />
                            ))}
                        </div>
                    )}
                </section>
            )}

            {/* Foot CTA pour les guests */}
            {isGuest && (
                <div className="train-foot">
                    Pour suivre votre progression, débloquer la révision ciblée et
                    accéder à tous les examens blancs,{" "}
                    <Link href="/inscription">créez votre compte gratuit</Link>.
                </div>
            )}

            <PaywallSheet
                open={paywallModule !== null}
                onClose={() => setPaywallModule(null)}
                title={
                    paywallModule === "TCF"
                        ? "Débloquez tout le TCF IRN"
                        : "Choisissez votre thématique"
                }
                message={
                    paywallModule === "TCF"
                        ? "Vous avez 20 questions de découverte et 1 examen blanc offerts en TCF. L'abonnement Intégral débloque l'entraînement illimité TCF + Civique, les examens blancs sans limite et la révision des erreurs."
                        : "L'entraînement par thématique est réservé aux abonnés. Avec l'abonnement Civique, débloquez tous les thèmes et l'entraînement illimité."
                }
                plan={paywallModule === "TCF" ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS"}
            />

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================

function DemoBanner({
                        isGuest,
                        isPremiumCivique,
                        isPremiumTcf,
                        onOpenPaywall,
                    }: {
    isGuest: boolean;
    isPremiumCivique: boolean;
    isPremiumTcf: boolean;
    onOpenPaywall: (m: ModuleEnum) => void;
}) {
    // Guest : message générique, CTA vers /inscription.
    if (isGuest) {
        return (
            <Link href="/connexion" className="demo-banner demo-banner-link">
                <div className="demo-banner-icon" aria-hidden>
                    <svg
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    >
                        <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z"/>
                    </svg>
                </div>
                <div className="demo-banner-content">
                    <div className="demo-banner-title">
                        Démo gratuite — {DEMO_BATCH_SIZE} questions par module.
                    </div>
                    <div className="demo-banner-sub">
                        Créez un compte pour sauvegarder vos résultats, débloquer la
                        révision ciblée et passer plusieurs examens blancs.
                    </div>
                </div>
                <div className="demo-banner-arrow" aria-hidden>→</div>
            </Link>
        );
    }
    // Connecté non-premium : ouvre le paywall.
    const locked: ModuleEnum[] = [];
    if (!isPremiumCivique) locked.push("CIVIQUE");
    if (!isPremiumTcf) locked.push("TCF");
    const lockedLabel = locked
        .map((m) => (m === "TCF" ? "TCF" : "Civique"))
        .join(" + ");
    const upsell: ModuleEnum = !isPremiumCivique ? "CIVIQUE" : "TCF";
    return (
        <button
            type="button"
            className="demo-banner"
            onClick={() => onOpenPaywall(upsell)}
        >
            <div className="demo-banner-icon" aria-hidden>
                <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                >
                    <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z"/>
                </svg>
            </div>
            <div className="demo-banner-content">
                <div className="demo-banner-title">
                    Mode démo {lockedLabel} · {DEMO_BATCH_SIZE} questions par session
                </div>
                <div className="demo-banner-sub">
                    Cliquez sur une thématique en démo pour déclencher la session mixte.
                    Activez l&apos;abonnement pour débloquer l&apos;entraînement par
                    thème et l&apos;illimité.
                </div>
            </div>
            <div className="demo-banner-arrow" aria-hidden>→</div>
        </button>
    );
}

function MixedCard({
                       module,
                       isPremium,
                       isGuest,
                       onClick,
                       starting,
                   }: {
    module: ModuleEnum;
    isPremium: boolean;
    isGuest: boolean;
    onClick: () => void;
    starting: boolean;
}) {
    const isCivique = module === "CIVIQUE";
    const label = isCivique ? "Civique mixte" : "TCF mixte";
    const desc = isCivique
        ? "Toutes thématiques mélangées · l'entraînement le plus polyvalent."
        : "CO + CE + Structure mélangés · pour réviser large.";
    const tag = isCivique ? "CIVIQUE · TOUT" : "TCF · TOUT";
    const size = isPremium ? PREMIUM_BATCH_SIZE : DEMO_BATCH_SIZE;
    const isDemo = !isPremium;
    return (
        <button
            type="button"
            className={`theme-card mixed mixed-${isCivique ? "blue" : "red"}`}
            onClick={onClick}
            disabled={starting}
        >
            <div className="theme-card-head">
        <span className={`theme-tag ${isCivique ? "tag-civique" : "tag-tcf"}`}>
          {tag}
        </span>
                <span className="theme-mixed-icon" aria-hidden>
          {isCivique ? "⚜" : "✶"}
        </span>
            </div>
            <h4 className="theme-card-title">{label}</h4>
            <p className="theme-card-desc">{desc}</p>
            <div className="theme-card-foot">
        <span>
          {size} QUESTIONS{isDemo ? " · DÉMO" : ""}
        </span>
                <span className="theme-card-start">
          {starting
              ? "…"
              : isGuest
                  ? "Lancer la démo →"
                  : "Démarrer →"}
        </span>
            </div>
        </button>
    );
}

function ThemeTile({
                       theme,
                       mastery,
                       isPremium,
                       isGuest,
                       onClick,
                       starting,
                   }: {
    theme: ThemeUserResponse;
    mastery: { pct: number; answered: number; total: number } | null;
    isPremium: boolean;
    isGuest: boolean;
    onClick: () => void;
    starting: boolean;
}) {
    const isCivique = theme.module === "CIVIQUE";
    const tone = mastery ? toneFor(mastery.pct) : null;
    const tagLabel = `${isCivique ? "CIVIQUE" : "TCF"} · ${theme.code}`;
    const desc = themeBlurb(theme.code);

    // Sur les thèmes spécifiques : verrouillé pour les guests et les connectés
    // non-premium (la démo ne couvre que le mixte du module).
    const locked = isGuest || !isPremium;

    return (
        <button
            type="button"
            className={`theme-card ${locked ? "is-locked" : ""} ${
                tone === "red" ? "border-red" : tone === "amber" ? "border-amber" : ""
            }`}
            onClick={onClick}
            disabled={starting}
        >
            {locked && (
                <span className="theme-lock" aria-hidden>
          <Lock size={14}/>
        </span>
            )}
            <div className="theme-card-head">
        <span className={`theme-tag ${isCivique ? "tag-civique" : "tag-tcf"}`}>
          {tagLabel}
        </span>
                {mastery && (
                    <span className={`theme-mastery theme-mastery-${tone}`}>
            {mastery.pct}%
          </span>
                )}
            </div>
            <h4 className="theme-card-title">{theme.name}</h4>
            {desc && <p className="theme-card-desc">{desc}</p>}
            <div className="theme-bar">
                <div
                    className={`theme-bar-fill theme-bar-${tone ?? "blue"}`}
                    style={{width: `${Math.max(2, mastery?.pct ?? 0)}%`}}
                />
            </div>
            <div className="theme-card-foot">
        <span>
          {mastery
              ? `${mastery.answered} / ${theme.questionCount ?? mastery.total} QUESTIONS`
              : `${theme.questionCount ?? "—"} QUESTIONS`}
        </span>
                <span className="theme-card-start">
          {starting ? "…" : locked ? "Débloquer →" : "Démarrer →"}
        </span>
            </div>
        </button>
    );
}

function ExamCard({
                      exam,
                      tone,
                      locked,
                      onStart,
                      starting,
                      ctaLabel,
                      upsellHref,
                  }: {
    exam: ExamTemplateSummary;
    tone: "blue" | "red";
    locked: boolean;
    onStart: () => void;
    starting: boolean;
    ctaLabel: string;
    upsellHref: string;
}) {
    const minutes = Math.round(exam.durationSeconds / 60);
    return (
        <div className={`exam-card exam-card-${tone} ${locked ? "is-locked" : ""}`}>
            {locked && (
                <span className="exam-lock" aria-hidden>
          <Lock size={14}/>
        </span>
            )}
            <span className={`exam-tag exam-tag-${tone}`}>
        {exam.free ? "OFFERT" : "PREMIUM"}
                {exam.module === "TCF" && exam.targetLevel ? ` · ${exam.targetLevel}` : ""}
                {exam.module === "CIVIQUE" && exam.targetProcedure
                    ? ` · ${exam.targetProcedure}`
                    : ""}
      </span>
            <h3 className="exam-title">{exam.name}</h3>
            {exam.subtitle && <p className="exam-sub">{exam.subtitle}</p>}
            <div className="exam-meta">
                <div className="exam-meta-item">
                    <div className="l">QUESTIONS</div>
                    <div className="v">{exam.totalQuestions}</div>
                </div>
                <div className="exam-meta-item">
                    <div className="l">DURÉE</div>
                    <div className="v">{minutes} min</div>
                </div>
                <div className="exam-meta-item">
                    <div className="l">{exam.module === "CIVIQUE" ? "SEUIL" : "RESTITUTION"}</div>
                    <div className="v">
                        {exam.module === "CIVIQUE"
                            ? `${exam.passingScore}/${exam.totalQuestions}`
                            : "CECRL"}
                    </div>
                </div>
            </div>
            <div className="exam-foot">
                {locked ? (
                    <>
                        <div className="exam-msg">Réservé aux abonnés Premium.</div>
                        <Link href={upsellHref} className={`btn btn-${tone}`}>
                            {ctaLabel}
                        </Link>
                    </>
                ) : (
                    <button
                        type="button"
                        className={`btn btn-${tone} btn-lg`}
                        onClick={onStart}
                        disabled={starting}
                    >
                        {starting ? "Préparation…" : ctaLabel}
                    </button>
                )}
            </div>
        </div>
    );
}

// ============================================================================
// HELPERS
// ============================================================================
function buildMastery(stats: Partial<Record<ModuleEnum, UserStatsResponse | null>>) {
    const byTheme: Record<string, { pct: number; answered: number; total: number }> = {};
    (["CIVIQUE", "TCF"] as ModuleEnum[]).forEach((m) => {
        const list = stats[m]?.byTheme ?? [];
        for (const t of list) {
            if (t.answered === 0) {
                byTheme[t.themeId] = {pct: 0, answered: 0, total: t.total};
                continue;
            }
            byTheme[t.themeId] = {
                pct: Math.round((t.correct / t.answered) * 100),
                answered: t.answered,
                total: t.total,
            };
        }
    });
    return {byTheme};
}

function toneFor(pct: number): "green" | "blue" | "amber" | "red" {
    if (pct >= 80) return "green";
    if (pct >= 65) return "blue";
    if (pct >= 45) return "amber";
    return "red";
}

function themeBlurb(code: string): string {
    const map: Record<string, string> = {
        PRINCIPES: "Devise, symboles, laïcité, République",
        INSTITUTIONS: "Président, gouvernement, parlement",
        DROITS_DEVOIRS: "Citoyenneté, libertés, obligations",
        HISTOIRE_GEO: "Révolution, République, géographie",
        SOCIETE: "Vie quotidienne, services, mises en situation",
        CO: "Audios, dialogues, exposés",
        CE: "SMS, e-mails, articles, annonces",
        STRUCTURE: "Grammaire, lexique, conjugaison",
    };
    return map[code] ?? "";
}

// ============================================================================
// SKELETONS
// ============================================================================
function EntrainementSkeleton() {
    return (
        <div className="train-loading">
            <style>{`
        .train-loading {
          min-height: calc(100vh - 80px);
          background: #F7F8FC;
        }
      `}</style>
        </div>
    );
}

function ThemesGridSkeleton() {
    return (
        <div className="theme-grid">
            {Array.from({length: 6}).map((_, i) => (
                <div key={i} className="theme-skel"/>
            ))}
            <style>{`
        .theme-skel {
          height: 180px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          animation: theme-pulse 1.4s ease-in-out infinite;
        }
        @keyframes theme-pulse {
          0%, 100% { opacity: 0.55; }
          50% { opacity: 1; }
        }
      `}</style>
        </div>
    );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .train { padding: 24px 36px 64px; max-width: 1320px; margin: 0 auto; }
  @media (max-width: 760px) { .train { padding: 20px 16px 56px; } }

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
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }

  .train-target { margin-bottom: 18px; }
  .train-error { margin-bottom: 18px; }

  /* ========== DEMO BANNER ========== */
  .demo-banner {
    display: flex; align-items: center; gap: 14px;
    width: 100%;
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.10), rgba(232, 163, 23, 0.02));
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 22px;
    cursor: pointer;
    text-align: left;
    font-family: var(--font-sans);
    transition: background 0.15s, transform 0.15s;
  }
  .demo-banner-link { text-decoration: none; color: inherit; }
  .demo-banner:hover {
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.14), rgba(232, 163, 23, 0.04));
    transform: translateY(-1px);
  }
  .demo-banner-icon {
    width: 40px; height: 40px;
    background: var(--color-amber);
    color: #fff;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .demo-banner-content { flex: 1; min-width: 0; }
  .demo-banner-title {
    font-weight: 700; font-size: 14px;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .demo-banner-sub {
    font-size: 12.5px; color: var(--color-muted);
    line-height: 1.4; margin-top: 4px;
  }
  .demo-banner-arrow {
    color: var(--color-amber);
    font-size: 18px; font-weight: 700;
    flex-shrink: 0;
  }

  /* ========== FILTERS ========== */
  .filters {
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    margin-bottom: 22px;
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
  .tab.tab-blue.is-active {
    background: var(--color-blue);
    color: #fff;
  }
  .tab.tab-red.is-active {
    background: var(--color-red);
    color: #fff;
  }

  .search-wrap {
    position: relative;
    margin-left: auto;
  }
  .search-wrap svg {
    position: absolute;
    left: 12px; top: 50%;
    transform: translateY(-50%);
    color: var(--color-muted);
  }
  .search-wrap input {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    padding: 9px 14px 9px 36px;
    font-family: inherit;
    font-size: 13px;
    width: 260px;
    color: var(--color-ink);
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .search-wrap input:focus {
    outline: none;
    border-color: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.12);
  }

  /* ========== GRID ========== */
  .theme-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
  .theme-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    cursor: pointer;
    text-align: left;
    font-family: inherit;
    transition: all 0.15s;
    position: relative;
    display: flex;
    flex-direction: column;
    min-height: 180px;
  }
  .theme-card:hover:not(:disabled) {
    border-color: var(--color-blue);
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .theme-card:disabled { opacity: 0.6; cursor: progress; }
  .theme-card.border-amber { border-color: rgba(232, 163, 23, 0.6); }
  .theme-card.border-red { border-color: rgba(225, 55, 47, 0.6); }
  .theme-card.is-locked {
    background:
      repeating-linear-gradient(45deg, var(--color-paper) 0 6px, #fff 6px 14px);
  }
  .theme-lock {
    position: absolute; top: 18px; right: 18px;
    display: inline-flex;
    color: var(--color-muted);
    opacity: 0.75;
  }

  .theme-card-head {
    display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 14px;
    gap: 10px;
  }
  .theme-tag {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    padding: 3px 8px;
    border-radius: 5px;
    font-weight: 700;
  }
  .tag-civique { background: var(--color-blue-light); color: var(--color-blue); }
  .tag-tcf { background: var(--color-red-light); color: var(--color-red); }

  .theme-mastery {
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 700;
    color: var(--color-muted);
  }
  .theme-mastery-green { color: var(--color-green); }
  .theme-mastery-blue { color: var(--color-blue); }
  .theme-mastery-amber { color: var(--color-amber); }
  .theme-mastery-red { color: var(--color-red); }

  .theme-card-title {
    font-family: var(--font-display);
    font-size: 17px;
    margin: 0 0 6px;
    font-weight: 600;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .theme-card-desc {
    color: var(--color-muted);
    font-size: 12.5px;
    margin: 0 0 14px;
    line-height: 1.45;
    flex: 1;
  }
  .theme-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 3px;
    overflow: hidden;
    margin-bottom: 12px;
  }
  .theme-bar-fill {
    height: 100%; border-radius: 3px;
    background: var(--color-blue);
    transition: width 0.3s;
  }
  .theme-bar-green { background: var(--color-green); }
  .theme-bar-blue { background: var(--color-blue); }
  .theme-bar-amber { background: var(--color-amber); }
  .theme-bar-red { background: var(--color-red); }

  .theme-card-foot {
    display: flex; justify-content: space-between; align-items: center;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.05em;
  }
  .theme-card-start {
    color: var(--color-blue);
    font-weight: 700;
    font-family: var(--font-sans);
    font-size: 12px;
    letter-spacing: 0;
  }
  .theme-card:hover .theme-card-start { text-decoration: underline; }

  .theme-card.mixed {
    background:
      radial-gradient(at 100% 0%, rgba(30, 58, 140, 0.06) 0px, transparent 50%),
      #fff;
    border-width: 1.5px;
  }
  .theme-card.mixed.mixed-red {
    background:
      radial-gradient(at 100% 0%, rgba(225, 55, 47, 0.06) 0px, transparent 50%),
      #fff;
  }
  .theme-mixed-icon {
    color: var(--color-blue);
    font-size: 20px;
  }
  .mixed.mixed-red .theme-mixed-icon { color: var(--color-red); }

  .theme-empty {
    grid-column: 1 / -1;
    text-align: center;
    padding: 60px 20px;
    color: var(--color-muted);
  }
  .theme-empty p { margin: 0 0 12px; font-size: 14px; }
  .theme-empty-cta {
    background: none; border: none;
    color: var(--color-blue);
    font-family: inherit;
    font-weight: 700;
    font-size: 13px;
    cursor: pointer;
  }
  .theme-empty-cta:hover { text-decoration: underline; }

  /* ========== EXAMS SECTION ========== */
  .exams-section {
    margin-top: 48px;
    padding-top: 36px;
    border-top: 1px solid var(--color-line-2);
  }
  .exams-section-head {
    margin-bottom: 22px;
  }
  .exams-section-head h2 {
    font-family: var(--font-display);
    font-size: clamp(22px, 2.6vw, 26px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0 0 6px;
    color: var(--color-ink);
  }
  .exams-section-head p {
    color: var(--color-muted);
    font-size: 14px;
    line-height: 1.55;
    margin: 0;
    max-width: 720px;
  }
  .exams-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
  .exam-skel {
    height: 240px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    animation: theme-pulse 1.4s ease-in-out infinite;
  }
  .exams-empty {
    background: var(--color-paper);
    border: 1px dashed var(--color-line);
    border-radius: 14px;
    padding: 24px;
    color: var(--color-muted);
    font-size: 14px;
    text-align: center;
  }
  .exam-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px;
    display: flex; flex-direction: column;
    min-height: 280px;
    position: relative;
    transition: all 0.15s;
  }
  .exam-card-blue:hover:not(.is-locked) {
    border-color: var(--color-blue);
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .exam-card-red:hover:not(.is-locked) {
    border-color: var(--color-red);
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .exam-card.is-locked {
    opacity: 0.7;
    background:
      repeating-linear-gradient(45deg, var(--color-paper) 0 6px, #fff 6px 14px);
  }
  .exam-lock {
    position: absolute; top: 18px; right: 18px;
    display: inline-flex;
    color: var(--color-muted);
  }
  .exam-tag {
    display: inline-block; align-self: flex-start;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    padding: 4px 9px;
    border-radius: 5px;
    font-weight: 700;
    margin-bottom: 12px;
  }
  .exam-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .exam-tag-red { background: var(--color-red-light); color: var(--color-red); }
  .exam-title {
    font-family: var(--font-display);
    font-size: 19px;
    font-weight: 600;
    letter-spacing: -0.015em;
    color: var(--color-ink);
    margin: 0 0 6px;
    line-height: 1.15;
  }
  .exam-sub {
    color: var(--color-muted);
    font-size: 13px;
    line-height: 1.5;
    margin: 0 0 14px;
  }
  .exam-meta {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    margin: 4px 0 16px;
  }
  .exam-meta-item {
    background: var(--color-paper);
    border: 1px solid var(--color-line);
    border-radius: 10px;
    padding: 8px 10px;
  }
  .exam-meta-item .l {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
    margin-bottom: 4px;
  }
  .exam-meta-item .v {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 15px;
    color: var(--color-ink);
    letter-spacing: -0.01em;
    line-height: 1.1;
  }
  .exam-foot {
    margin-top: auto;
    display: flex; flex-direction: column; gap: 10px;
  }
  .exam-msg {
    font-size: 12.5px;
    color: var(--color-muted);
    line-height: 1.45;
  }

  /* ========== FOOT ========== */
  .train-foot {
    margin-top: 36px;
    text-align: center;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.55;
  }
  .train-foot a {
    color: var(--color-blue); font-weight: 700;
    text-decoration: none;
  }
  .train-foot a:hover { text-decoration: underline; }

  /* ========== RESPONSIVE ========== */
  @media (max-width: 1100px) {
    .theme-grid { grid-template-columns: repeat(2, 1fr); }
    .exams-grid { grid-template-columns: repeat(2, 1fr); }
  }
  @media (max-width: 680px) {
    .theme-grid { grid-template-columns: 1fr; }
    .exams-grid { grid-template-columns: 1fr; }
    .search-wrap { margin-left: 0; width: 100%; }
    .search-wrap input { width: 100%; }
  }
`;
