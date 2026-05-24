"use client";

import Link from "next/link";
import {useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {BookOpen, Headphones, Landmark, Lock, Mic, PenLine} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  type ProductionKind,
  ProductionMobileSheet,
} from "@/app/_components/ProductionMobileSheet";
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
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setFilter(filterFromUrl);
    }, [filterFromUrl]);
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
    const [productionSheet, setProductionSheet] = useState<ProductionKind | null>(null);

    // ========== LOAD ==========
    useEffect(() => {
        let cancelled = false;
        // eslint-disable-next-line react-hooks/set-state-in-effect
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

    // Synthèse du module courant pour les "summary boxes" du hero (façon template).
    const heroStats = useMemo(() => {
        const s = statsByModule[filter];
        const answered = s?.questionsAnswered ?? 0;
        const correct = s?.questionsCorrect ?? 0;
        const byTheme = s?.byTheme ?? [];
        const mastered = byTheme.filter((t) => t.total > 0 && t.correct / t.total >= 0.8).length;
        const tcfLevelOf = (p: string | null | undefined) =>
            p === "NAT" ? "B2" : p === "CR" ? "B1" : p === "CSP" ? "A2" : "—";
        const objective =
            filter === "TCF"
                ? tcfLevelOf(user?.targetProcedure)
                : (user?.targetProcedure ?? "—");
        return {
            objective: isGuest ? "—" : objective || "—",
            mastery: isGuest || answered === 0 ? "—" : `${Math.round((correct / answered) * 100)}%`,
            themes: isGuest ? "—" : `${mastered}/${byTheme.length}`,
            questions: isGuest ? "—" : String(answered),
        };
    }, [statsByModule, filter, isGuest, user]);


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

    // Cartes "Modules" façon template : 4 épreuves pour TCF (CO/CE = thèmes web,
    // EE/EO = productions → app mobile), thèmes civiques pour CIVIQUE.
    type ModuleItem = {
        key: string;
        kind: "theme" | "prod";
        theme?: ThemeUserResponse | null;
        prod?: ProductionKind;
        tone: string;
        badge: string;
        icon: string;
        title: string;
        desc: string;
        tags: string[];
        cta: string;
    };
    const moduleItems = useMemo<ModuleItem[]>(() => {
        if (filter === "TCF") {
            const tcf = themes.TCF;
            return [
                {
                    key: "co", kind: "theme", theme: tcf.find((t) => t.code === "CO") ?? null,
                    tone: "blue", badge: "CO", icon: "co", title: "Compréhension orale",
                    desc: "Écoute des audios, réponds aux QCM et améliore ta rapidité.",
                    tags: ["25 questions", "20 min"], cta: "Commencer",
                },
                {
                    key: "ce", kind: "theme", theme: tcf.find((t) => t.code === "CE") ?? null,
                    tone: "green", badge: "CE", icon: "ce", title: "Compréhension écrite",
                    desc: "Textes courts, annonces, e-mails, consignes et documents simples.",
                    tags: ["25 questions", "35 min"], cta: "Commencer",
                },
                {
                    key: "ee", kind: "prod", prod: "EE", tone: "amber", badge: "EE", icon: "ee",
                    title: "Expression écrite",
                    desc: "Rédige 3 tâches, obtiens une correction IA et un niveau CECRL.",
                    tags: ["3 tâches", "Sur mobile"], cta: "S'entraîner",
                },
                {
                    key: "eo", kind: "prod", prod: "EO", tone: "purple", badge: "EO", icon: "eo",
                    title: "Expression orale",
                    desc: "Enregistre tes réponses, reçois transcription et feedback IA.",
                    tags: ["3 tâches", "Sur mobile"], cta: "S'entraîner",
                },
            ];
        }
        const tones = ["blue", "green", "amber", "purple", "red"];
        return themes.CIVIQUE.map((t, i) => ({
            key: t.id, kind: "theme" as const, theme: t, tone: tones[i % tones.length],
            badge: t.code.slice(0, 3), icon: "civique", title: t.name,
            desc: themeBlurb(t.code), tags: [`${t.questionCount ?? "—"} questions`], cta: "Commencer",
        }));
    }, [filter, themes]);

    return (
        <main className="train">
            {/* ============ TOPBAR ============ */}
            <header className="train-hero">
                <div className="train-hero-main">
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span>{" "}
                        {filter === "TCF" ? "TCF IRN" : "EXAMEN CIVIQUE"}
                    </div>
                    <h1>
                        {filter === "TCF" ? (
                            <>
                                Préparation <em>TCF IRN</em>
                            </>
                        ) : (
                            <>
                                Examen <em>civique</em>
                            </>
                        )}
                    </h1>
                    <p>
                        {filter === "TCF"
                            ? "Compréhension orale et écrite, expression écrite et orale, examens blancs — entraîne-toi par thème."
                            : "Valeurs de la République, institutions, droits et devoirs, histoire et société — révise par thème."}
                    </p>
                    {!isGuest && (
                        <div className="train-hero-actions">
                            <Link href="/examens-blancs" className="train-hero-btn">
                                Lancer un examen blanc
                            </Link>
                            <Link href="/revision" className="train-hero-btn train-hero-btn-ghost">
                                Mes erreurs
                            </Link>
                        </div>
                    )}
                </div>

                <div className="train-summary">
                    <div className="summary-box">
                        <strong>{heroStats.objective}</strong>
                        <span>Niveau visé</span>
                    </div>
                    <div className="summary-box">
                        <strong>{heroStats.mastery}</strong>
                        <span>Score moyen</span>
                    </div>
                    <div className="summary-box">
                        <strong>{heroStats.themes}</strong>
                        <span>Thèmes maîtrisés</span>
                    </div>
                    <div className="summary-box">
                        <strong>{heroStats.questions}</strong>
                        <span>Questions</span>
                    </div>
                </div>
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
            </div>

            {error && <div className="form-error train-error">{error}</div>}

            {/* ============ MODULES (façon template tcf-irn-page) ============ */}
            <div className="hub-section-title">
                <h2>Modules {filter === "TCF" ? "TCF IRN" : "Examen civique"}</h2>
                {!isGuest && <Link href="/statistiques">Voir ma progression →</Link>}
            </div>
            {loading ? (
                <ThemesGridSkeleton/>
            ) : (
                <section className="hub-grid">
                    {moduleItems.map((it) => {
                        const m =
                            it.kind === "theme" && it.theme && !isGuest
                                ? (mastery.byTheme[it.theme.id] ?? null)
                                : null;
                        const onClick =
                            it.kind === "prod"
                                ? () => setProductionSheet(it.prod ?? "EO")
                                : () =>
                                      startTraining(
                                          isPremiumForFilter && it.theme
                                              ? {module: filter, themeId: it.theme.id, label: it.theme.id}
                                              : {module: filter, label: `__mixed_${filter}`},
                                      );
                        const starting =
                            it.kind === "theme"
                                ? startingThemeId === it.theme?.id ||
                                  startingThemeId === `__mixed_${filter}`
                                : false;
                        return (
                            <HubModuleCard
                                key={it.key}
                                tone={it.tone}
                                badge={it.badge}
                                icon={it.icon}
                                title={it.title}
                                desc={it.desc}
                                masteryPct={m ? m.pct : null}
                                tags={it.tags}
                                cta={it.cta}
                                starting={starting}
                                onClick={onClick}
                            />
                        );
                    })}
                </section>
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

            <ProductionMobileSheet
                open={productionSheet !== null}
                kind={productionSheet}
                onClose={() => setProductionSheet(null)}
            />

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
                module={paywallModule === "TCF" ? "INTEGRAL" : "CIVIQUE"}
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
// Score de maîtrise = correct / total (questions distinctes maîtrisées sur le
// pool du thème). C'est l'indicateur cohérent : une session unique avec 2/2
// dans un thème de 50 questions donne 4%, pas 100%.
function buildMastery(stats: Partial<Record<ModuleEnum, UserStatsResponse | null>>) {
    const byTheme: Record<string, { pct: number; answered: number; total: number }> = {};
    (["CIVIQUE", "TCF"] as ModuleEnum[]).forEach((m) => {
        const list = stats[m]?.byTheme ?? [];
        for (const t of list) {
            const pct = t.total > 0 ? Math.round((t.correct / t.total) * 100) : 0;
            byTheme[t.themeId] = {
                pct,
                answered: t.answered,
                total: t.total,
            };
        }
    });
    return {byTheme};
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
// HUB MODULE CARD (façon template tcf-irn-page)
// ============================================================================
function HubModuleCard({
                           tone,
                           badge,
                           icon,
                           title,
                           desc,
                           masteryPct,
                           tags,
                           cta,
                           starting,
                           onClick,
                       }: {
    tone: string;
    badge: string;
    icon: string;
    title: string;
    desc: string;
    masteryPct: number | null;
    tags: string[];
    cta: string;
    starting: boolean;
    onClick: () => void;
}) {
    const Icon =
        icon === "co" ? Headphones
            : icon === "ce" ? BookOpen
                : icon === "ee" ? PenLine
                    : icon === "eo" ? Mic
                        : Landmark;
    return (
        <article className="hub-card">
            <div className="hub-card-head">
                <span className={`hub-card-icon tone-${tone}`} aria-hidden>
                    <Icon size={20} strokeWidth={1.8}/>
                </span>
                <span className="hub-card-badge">{badge}</span>
            </div>
            <h3 className="hub-card-title">{title}</h3>
            <p className="hub-card-desc">{desc}</p>
            <div className="hub-progress">
                <span style={{width: `${Math.max(3, masteryPct ?? 0)}%`}}/>
            </div>
            <div className="hub-tags">
                {tags.map((t) => (
                    <span key={t} className="hub-tag">{t}</span>
                ))}
            </div>
            <button type="button" className="hub-cta" onClick={onClick} disabled={starting}>
                {starting ? "…" : cta}
            </button>
        </article>
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

  /* ========== HERO (façon template tcf-irn-page) ========== */
  .train-hero {
    display: grid;
    grid-template-columns: 1fr;
    gap: 22px;
    background: linear-gradient(135deg, var(--color-blue) 0%, #3355B5 100%);
    color: #fff;
    border-radius: 20px;
    padding: 24px;
    margin-bottom: 22px;
  }
  .train-hero .breadcrumb { color: rgba(255, 255, 255, 0.7); }
  .train-hero-main h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.4vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.12;
    margin: 8px 0 0;
    color: #fff;
  }
  .train-hero-main h1 em { font-style: italic; font-weight: 500; opacity: 0.92; }
  .train-hero-main p {
    color: rgba(255, 255, 255, 0.82);
    font-size: 14.5px;
    line-height: 1.6;
    margin: 10px 0 0;
    max-width: 540px;
  }
  .train-hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 18px; }
  .train-hero-btn {
    display: inline-flex; align-items: center; justify-content: center;
    padding: 11px 20px; border-radius: 10px;
    font-family: var(--font-sans); font-size: 14px; font-weight: 700;
    background: var(--color-ink); color: #fff;
    text-decoration: none; border: 1px solid transparent;
    transition: transform 0.15s, background 0.15s;
  }
  .train-hero-btn:hover { transform: translateY(-1px); background: #0A1230; }
  .train-hero-btn-ghost { background: transparent; border-color: rgba(255, 255, 255, 0.4); }
  .train-hero-btn-ghost:hover { background: rgba(255, 255, 255, 0.12); }
  .train-summary { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; align-content: start; }
  .train-summary .summary-box {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 14px;
    padding: 14px 16px;
    display: flex; flex-direction: column; gap: 4px;
  }
  .train-summary .summary-box strong {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 24px;
    line-height: 1;
    color: #fff;
    font-variant-numeric: tabular-nums;
  }
  .train-summary .summary-box span { font-size: 11.5px; color: rgba(255, 255, 255, 0.7); }

  /* ========== SECTION TITLE + HUB CARDS (4 modules) ========== */
  .hub-section-title {
    display: flex; align-items: baseline; justify-content: space-between;
    gap: 12px; margin: 26px 0 14px;
  }
  .hub-section-title h2 {
    font-family: var(--font-display); font-weight: 600; font-size: 19px;
    letter-spacing: -0.015em; color: var(--color-ink); margin: 0;
  }
  .hub-section-title a { font-size: 13px; font-weight: 600; color: var(--color-blue); white-space: nowrap; }
  .hub-section-title a:hover { text-decoration: underline; }
  .hub-grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
  .hub-card {
    background: #fff; border: 1px solid var(--color-line); border-radius: 16px;
    padding: 20px; display: flex; flex-direction: column;
    transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
  }
  .hub-card:hover {
    transform: translateY(-3px); border-color: var(--color-blue);
    box-shadow: 0 16px 38px -22px rgba(30, 58, 140, 0.3);
  }
  .hub-card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
  .hub-card-icon { width: 44px; height: 44px; border-radius: 12px; display: inline-flex; align-items: center; justify-content: center; }
  .hub-card-badge {
    font-family: var(--font-mono); font-size: 11px; font-weight: 700;
    letter-spacing: 0.06em; color: var(--color-muted);
    background: var(--color-paper-2); padding: 4px 9px; border-radius: 8px;
  }
  .hub-card-title { font-family: var(--font-sans); font-weight: 700; font-size: 15.5px; color: var(--color-ink); margin: 0 0 4px; }
  .hub-card-desc { font-size: 13px; color: var(--color-muted); line-height: 1.5; margin: 0 0 14px; flex: 1; }
  .hub-progress { height: 6px; border-radius: 100px; background: var(--color-line-2); overflow: hidden; margin-bottom: 14px; }
  .hub-progress span { display: block; height: 100%; border-radius: 100px; background: var(--color-blue); }
  .hub-tags { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 16px; }
  .hub-tag {
    font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.04em;
    text-transform: uppercase; font-weight: 600; padding: 4px 9px; border-radius: 100px;
    background: var(--color-paper-2); color: var(--color-muted);
  }
  .hub-cta {
    width: 100%; padding: 11px; border-radius: 10px; border: none;
    background: var(--color-ink); color: #fff;
    font-family: var(--font-sans); font-weight: 700; font-size: 13.5px; cursor: pointer;
    transition: background 0.15s;
  }
  .hub-cta:hover:not(:disabled) { background: #0A1230; }
  .hub-cta:disabled { opacity: 0.6; cursor: not-allowed; }
  .tone-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .tone-green { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .tone-amber { background: rgba(232, 163, 23, 0.16); color: #B87908; }
  .tone-purple { background: rgba(124, 58, 173, 0.12); color: #7C3AAD; }
  .tone-red { background: var(--color-red-light); color: var(--color-red); }

  @media (min-width: 560px) { .hub-grid { grid-template-columns: 1fr 1fr; } }
  @media (min-width: 900px) {
    .train-hero { grid-template-columns: 1.4fr 1fr; align-items: center; padding: 30px; }
  }
  @media (min-width: 1100px) { .hub-grid { grid-template-columns: repeat(4, 1fr); } }

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

  /* ========== PRODUCTIONS TCF (EO/EE) ========== */
  .prod-section {
    margin-top: 32px;
    padding-top: 28px;
    border-top: 1px solid var(--color-line-2);
  }
  .prod-section-head { margin-bottom: 18px; }
  .prod-section-head h2 {
    font-family: var(--font-display);
    font-size: clamp(20px, 2.4vw, 24px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0 0 6px;
    color: var(--color-ink);
  }
  .prod-section-head p {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.55;
    margin: 0;
    max-width: 640px;
  }
  .prod-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
  }
  .prod-card {
    background:
      radial-gradient(at 100% 0%, rgba(225, 55, 47, 0.06) 0px, transparent 50%),
      #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    text-align: left;
    font-family: inherit;
    cursor: pointer;
    transition: all 0.15s;
    display: flex;
    flex-direction: column;
    min-height: 170px;
  }
  .prod-card:hover {
    border-color: var(--color-red);
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .prod-card-head {
    display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 14px;
    gap: 10px;
  }
  .prod-card-icon {
    width: 34px; height: 34px;
    border-radius: 10px;
    background: var(--color-red-light);
    color: var(--color-red);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .prod-card-title {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 600;
    letter-spacing: -0.015em;
    margin: 0 0 6px;
    color: var(--color-ink);
  }
  .prod-card-desc {
    color: var(--color-muted);
    font-size: 13px;
    line-height: 1.45;
    margin: 0 0 14px;
    flex: 1;
  }
  .prod-card-foot {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
  }
  .prod-card-pill {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.14em;
    padding: 3px 8px;
    border-radius: 5px;
    font-weight: 700;
    background: var(--color-blue-soft);
    color: var(--color-blue);
  }
  .prod-card-cta {
    color: var(--color-red);
    font-weight: 700;
    font-size: 12px;
  }
  .prod-card:hover .prod-card-cta { text-decoration: underline; }

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
    .prod-grid { grid-template-columns: 1fr; }
    .search-wrap { margin-left: 0; width: 100%; }
    .search-wrap input { width: 100%; }
  }
`;
