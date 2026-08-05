"use client";

import {useRouter} from "next/navigation";
import {type ReactNode, useEffect, useMemo, useState} from "react";
import {Lightbulb, Target, Waves} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {GuestGateSheet} from "@/app/_components/GuestGateSheet";
import {ExamsGrid, type ExamSlotData} from "@/app/_components/hub/DetailParts";
import {ExamIntroSheet} from "@/app/_components/hub/ExamIntroSheet";
import {examSlotGrid} from "@/lib/exam-slots";
import {isCompleteExamResult} from "@/lib/exam-levels";
import {moduleAverage} from "@/lib/dashboard";
import {TcfFullExamBriefingSheet} from "@/app/examens-blancs/tcf/TcfFullExamBriefingSheet";
import {ApiException, attemptApi, dashboardApi, fullTcfExamApi, publicAttemptApi, publicExamApi,} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";
import {useAuth} from "@/lib/auth-context";
import {
    type AttemptSummaryResponse,
    canAccessModule,
    cecrlIndex,
    type DashboardSummaryResponse,
    type ExamTemplateSummary,
    type FullTcfExamSummaryResponse,
    type Module as ModuleEnum,
    type NiveauCecrl,
    niveauCecrlLabel,
} from "@/lib/types";

const SLOTS = 20;
const COLLAPSED = 8;

/** Parcours affiché par le toggle en tête de page. */
type ExamModule = "TCF" | "CIVIQUE";

/** Une stat affichée sous le toggle (valeur + libellé). */
interface StatItem {
    value: string;
    label: string;
}

/** Template de référence de l'examen civique complet (briefing + lancement). */
const CIVIQUE_FULL_EXAM_SLUG = "civique-decouverte";

/**
 * /examens-blancs : « Examens blancs complets » — une card par parcours.
 *
 * - **TCF abonné (Intégral)** : grille des 20 examens TCF complets (CO+CE+EE+EO
 *   orchestrés) ; « Démarrer » ouvre le briefing inline → hub
 *   `/examens-blancs/tcf/[id]`.
 * - **TCF invité / compte gratuit** : diagnostic gratuit CO+CE (`tcf-mix-01`),
 *   EE/EO cadenassés, rapport sur les 2 épreuves de compréhension. C'est le
 *   hook de conversion (examen 1 offert, 2+ premium).
 * - **Civique** : MOCK_EXAM 40 Q stratifiées (`civique-decouverte`).
 */
export default function ExamensBlancsHomePage() {
    const {status} = useAuth();
    if (status === "loading") return <HomeSkeleton/>;
    if (status === "guest") return <ExamsGuestHome/>;
    return (
        <DualChromeShell>
            <ExamsConnectedHome/>
        </DualChromeShell>
    );
}

function ExamsConnectedHome() {
    const router = useRouter();
    const {user, status} = useAuth();

    const [civique, setCivique] = useState<AttemptSummaryResponse[]>([]);
    const [fullExams, setFullExams] = useState<FullTcfExamSummaryResponse[]>([]);
    const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);
    /** Slot dont le briefing d'examen complet est ouvert (lancement inline). */
    const [briefingSlot, setBriefingSlot] = useState<number | null>(null);
    /** Examen civique : template de référence + état de la modale d'intro. */
    const [civiqueTemplate, setCiviqueTemplate] = useState<ExamTemplateSummary | null>(null);
    const [civiqueSlot, setCiviqueSlot] = useState<number | null>(null);
    const [civiqueStarting, setCiviqueStarting] = useState(false);
    const [civiqueError, setCiviqueError] = useState<string | null>(null);
    const [active, setActive] = useState<ExamModule>("TCF");
    /** Dashboard agrégé (cache 30 s) : sert niveau TCF estimé + progression civique. */
    const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);

    const tcfPremium = user != null && canAccessModule(user, "TCF");
    const civiquePremium = user != null && canAccessModule(user, "CIVIQUE");

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        // Examens complets civiques (40 Q tous thèmes) : on écarte les examens
        // thématiques (lotThemeId non null). Rangés par slot plus bas.
        attemptApi
            .listMine({type: "MOCK_EXAM", module: "CIVIQUE", limit: 100})
            .then((list) => {
                if (!cancelled) setCivique(list.filter((a) => a.finishedAt && !a.lotThemeId));
            })
            .catch(() => undefined);
        return () => {
            cancelled = true;
        };
    }, [status]);

    // Métadonnées du template civique (questions / durée / seuil) pour la modale.
    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        publicExamApi
            .getBySlug(CIVIQUE_FULL_EXAM_SLUG)
            .then((tpl) => {
                if (!cancelled) setCiviqueTemplate(tpl);
            })
            .catch(() => undefined);
        return () => {
            cancelled = true;
        };
    }, [status]);

    // Dashboard agrégé (cache 30 s, partagé sidebar) : niveau TCF estimé +
    // progression civique pour les stat cards sous le toggle.
    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        dashboardApi
            .summaryCached()
            .then((s) => {
                if (!cancelled) setSummary(s);
            })
            .catch(() => undefined);
        return () => {
            cancelled = true;
        };
    }, [status]);

    // Examens TCF complets : pour tous les comptes. Le 1ᵉʳ examen est offert aux
    // comptes gratuits (EE/EO évaluées une fois), les suivants sont premium.
    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        fullTcfExamApi
            .listMine(SLOTS)
            .then((list) => {
                if (!cancelled) setFullExams(list);
            })
            .catch(() => {
                /* silencieux : la grille s'affichera vide */
            });
        return () => {
            cancelled = true;
        };
    }, [status]);

    // Grilles indexées par slot : refaire l'examen N met à jour la case N.
    const {bySlot: civiqueBySlot} = useMemo(
        () => examSlotGrid(civique, SLOTS),
        [civique],
    );
    // Check vert civique : examen terminé (qu'il soit réussi ou non, comme le
    // full exam TCF qui coche dès qu'il est terminé). Le score reste coloré
    // vert/rouge selon le seuil ; le check marque juste « déjà passé ».
    const civiqueSlotData: (ExamSlotData | null)[] = useMemo(
        () =>
            civiqueBySlot.map((a) =>
                a
                    ? {
                        id: a.id,
                        score: a.score,
                        totalQuestions: a.totalQuestions,
                        passThreshold: a.passThreshold,
                        passed: true,
                    }
                    : null,
            ),
        [civiqueBySlot],
    );
    const {bySlot: fullExamBySlot} = useMemo(
        () => examSlotGrid(fullExams, SLOTS),
        [fullExams],
    );

    if (status === "loading" || !user) return <HomeSkeleton/>;

    // Cards full-exam (abonné) : mêmes cards que Civique. Un slot rempli =
    // examen complet déjà passé (Refaire relance, Rapport → bilan ou hub si
    // encore en cours). « Démarrer » ouvre le briefing inline. Rangé par slot :
    // refaire l'examen N met à jour la case N (parité mobile, V110).
    // Un examen dont l'EE/EO était verrouillée (ou dont les évaluations ont
    // échoué) porte un niveau **partiel** : il est annoté et ne prend pas le
    // check de réussite — sinon un examen amputé se lit comme un vrai résultat.
    const fullExamSlotData: (ExamSlotData | null)[] = fullExamBySlot.map((e) =>
        e
            ? {
                id: e.id,
                passed: isCompleteExamResult(e),
                metaOverride:
                    e.status === "COMPLETED"
                        ? e.finalLevelPartial
                            ? `${niveauCecrlLabel(e.finalCecrlLevel)} · partiel`
                            : niveauCecrlLabel(e.finalCecrlLevel)
                        : e.status === "PENDING_EVALUATIONS"
                            ? "Éval en cours…"
                            : "En cours",
            }
            : null,
    );

    // « Rapport » : examen en cours → hub (reprise), terminé/éval → bilan.
    function fullExamReportPath(id: string): string {
        const e = fullExams.find((x) => x.id === id);
        return e?.status === "IN_PROGRESS"
            ? `/examens-blancs/tcf/${id}`
            : `/examens-blancs/tcf/${id}/bilan`;
    }

    // « Démarrer / Refaire » : ouvre le briefing inline (il crée l'examen et
    // route vers le hub /examens-blancs/tcf/[id]).
    function startFullExam(slot: number) {
        setBriefingSlot(slot);
    }

    // Civique : modale d'intro inline (comme le full exam TCF), puis lancement.
    function startCivique(slot: number) {
        setCiviqueError(null);
        setCiviqueSlot(slot);
    }

    async function launchCivique() {
        if (civiqueSlot === null || civiqueStarting) return;
        setCiviqueStarting(true);
        setCiviqueError(null);
        try {
            const a = await attemptApi.start({
                type: "MOCK_EXAM",
                module: "CIVIQUE",
                examTemplateId: civiqueTemplate?.id,
                slotNumber: civiqueSlot,
            });
            router.push(`/sessions/${a.id}`);
        } catch (e) {
            handleStartFailure(e, {
                onPaywall: () => {
                    setCiviqueSlot(null);
                    setPaywallModule("CIVIQUE");
                },
                onMessage: setCiviqueError,
                fallbackMessage: "Impossible de démarrer l'examen.",
            });
            setCiviqueStarting(false);
        }
    }

    // ---- Stat cards + tips sous le toggle (données réelles, pas de valeurs en dur) ----
    // Tous les comptes passent désormais l'examen complet (le 1ᵉʳ offert aux
    // gratuits) : mêmes stats niveau CECRL pour tous, basées sur fullExams.
    const estimatedTcf = niveauCecrlLabel(summary?.estimatedTcfLevel ?? null);
    // Seuls les examens **complets** alimentent « Meilleur niveau » / « Dernier
    // examen » : un bilan partiel (EE/EO verrouillée, évaluations échouées) ne
    // porte pas sur les 4 épreuves et ne vaut pas un résultat d'examen.
    const completedFull = fullExams.filter(isCompleteExamResult);
    const bestFullLevel = completedFull.reduce<NiveauCecrl | null>(
        (best, e) =>
            best == null || cecrlIndex(e.finalCecrlLevel) > cecrlIndex(best)
                ? e.finalCecrlLevel
                : best,
        null,
    );
    const lastFull = mostRecentFull(completedFull);
    const tcfStats: StatItem[] = [
        {value: niveauCecrlLabel(bestFullLevel), label: "Meilleur niveau"},
        {value: lastFull ? niveauCecrlLabel(lastFull.finalCecrlLevel) : "—", label: "Dernier examen"},
        {value: estimatedTcf, label: "Niveau estimé"},
    ];
    const tcfTips = ["Conditions réelles", "90 minutes", "4 épreuves", "Niveau CECRL"];

    const civiqueProgress = summary ? moduleAverage(summary.civique) : null;
    const civiqueStats: StatItem[] = [
        {value: civiqueScoreLabel(bestScored(civique)), label: "Meilleur score"},
        {value: civiqueScoreLabel(mostRecent(civique)), label: "Dernier examen"},
        {value: civiqueProgress != null ? `${civiqueProgress}%` : "—", label: "Progression"},
    ];
    const civTotalQ = civiqueTemplate?.totalQuestions ?? 40;
    const civMin = Math.round((civiqueTemplate?.durationSeconds ?? 2400) / 60);
    const civPass = civiqueTemplate?.passingScore ?? 32;
    const civiqueTips = [
        "Conditions réelles",
        `${civMin} minutes`,
        `Seuil ${civPass}/${civTotalQ}`,
        `${civTotalQ} questions`,
    ];

    return (
        <main className="ebh">
            <header className="ebh-head">
                <div className="ebh-eyebrow">
                    <Target size={16} aria-hidden/>
                    <span>Conditions réelles</span>
                </div>
                <h1>Examens blancs complets</h1>
                <p>
                    Une épreuve entière par parcours, qui mélange tous les thèmes.
                    Retrouvez les examens déjà passés et leur score, ou lancez-en un
                    nouveau.
                </p>
            </header>

            <ModuleToggle active={active} onChange={setActive}/>

            {active === "TCF" ? (
                <ModuleExamsSection
                    tone="red"
                    icon={<Waves size={22} strokeWidth={1.8}/>}
                    title="TCF IRN"
                    chip="CO · CE · EE · EO"
                    sub={tcfPremium ? undefined : "Examen 1 offert · expression écrite et orale évaluées une fois"}
                    stats={tcfStats}
                    tips={tcfTips}
                >
                    <ExamsGrid
                        count={SLOTS}
                        exams={fullExamSlotData}
                        premium={tcfPremium}
                        freeSlots={1}
                        starting={false}
                        itemLabel="Examen"
                        collapsedCount={COLLAPSED}
                        reportPath={fullExamReportPath}
                        onStart={startFullExam}
                        onLocked={() => setPaywallModule("INTEGRAL")}
                    />
                </ModuleExamsSection>
            ) : (
                <ModuleExamsSection
                    tone="blue"
                    icon={<Lightbulb size={22} strokeWidth={1.8}/>}
                    title="Examen civique"
                    chip="5 catégories mélangées"
                    stats={civiqueStats}
                    tips={civiqueTips}
                >
                    <ExamsGrid
                        count={SLOTS}
                        exams={civiqueSlotData}
                        premium={civiquePremium}
                        starting={false}
                        itemLabel="Examen"
                        collapsedCount={COLLAPSED}
                        onStart={startCivique}
                        onLocked={() => setPaywallModule("CIVIQUE")}
                    />
                </ModuleExamsSection>
            )}

            {briefingSlot !== null && (
                <TcfFullExamBriefingSheet
                    slotNumber={briefingSlot}
                    isFreeAccount={!tcfPremium}
                    onClose={() => setBriefingSlot(null)}
                    onNeedsPremium={() => {
                        setBriefingSlot(null);
                        setPaywallModule("INTEGRAL");
                    }}
                />
            )}

            <ExamIntroSheet
                open={civiqueSlot !== null}
                eyebrow="Examen blanc · Examen civique"
                title="Examen civique en conditions réelles"
                subtitle="Avant de commencer, voici comment se déroule l'examen."
                facts={[
                    {
                        label: "questions · 5 catégories",
                        value: String(civiqueTemplate?.totalQuestions ?? 40),
                    },
                    {
                        label: "en conditions réelles",
                        value: `${Math.round((civiqueTemplate?.durationSeconds ?? 2400) / 60)} min`,
                    },
                    {
                        label: "seuil de réussite",
                        value: `${civiqueTemplate?.passingScore ?? 32}/${civiqueTemplate?.totalQuestions ?? 40}`,
                        highlight: true,
                    },
                ]}
                tips={[
                    "L'examen brasse les 5 catégories du programme civique.",
                    "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
                    "Pas de retour en arrière : une réponse validée est définitive, comme le jour J.",
                ]}
                loading={civiqueStarting}
                error={civiqueError}
                onConfirm={() => void launchCivique()}
                onClose={() => setCiviqueSlot(null)}
            />

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
// Helpers stats (meilleur / dernier examen)
// ============================================================================

/** Attempt au meilleur score brut (civique). Null si aucun score. */
function bestScored(exams: AttemptSummaryResponse[]): AttemptSummaryResponse | null {
    return exams.reduce<AttemptSummaryResponse | null>(
        (best, a) =>
            a.score != null && (best == null || a.score > (best.score ?? -1)) ? a : best,
        null,
    );
}

/** Attempt le plus récent (par date de fin, fallback date de début). */
function mostRecent(exams: AttemptSummaryResponse[]): AttemptSummaryResponse | null {
    return exams.reduce<AttemptSummaryResponse | null>((latest, a) => {
        const t = a.finishedAt ?? a.startedAt;
        const lt = latest ? (latest.finishedAt ?? latest.startedAt) : "";
        return latest == null || t > lt ? a : latest;
    }, null);
}

/** Examen complet TCF le plus récent. */
function mostRecentFull(
    exams: FullTcfExamSummaryResponse[],
): FullTcfExamSummaryResponse | null {
    return exams.reduce<FullTcfExamSummaryResponse | null>((latest, e) => {
        const t = e.finishedAt ?? e.startedAt;
        const lt = latest ? (latest.finishedAt ?? latest.startedAt) : "";
        return latest == null || t > lt ? e : latest;
    }, null);
}

/** Score civique affichable : brut sur le total de questions, sinon « — ». */
function civiqueScoreLabel(a: AttemptSummaryResponse | null): string {
    if (!a || a.score == null) return "—";
    return `${a.score}/${a.totalQuestions ?? 40}`;
}

// ============================================================================
// TOGGLE PARCOURS — 2 boutons demi-largeur (TCF / Examen civique). On n'affiche
// que les examens du parcours sélectionné, plutôt que de tout empiler.
// ============================================================================
function ModuleToggle({
                          active,
                          onChange,
                      }: {
    active: ExamModule;
    onChange: (m: ExamModule) => void;
}) {
    return (
        <div className="ebh-toggle" role="tablist" aria-label="Choisir un parcours">
            <button
                type="button"
                role="tab"
                aria-selected={active === "TCF"}
                className={`ebh-toggle-btn ebh-toggle-btn-red${active === "TCF" ? " is-active" : ""}`}
                onClick={() => onChange("TCF")}
            >
                <Waves size={18} strokeWidth={1.8} aria-hidden/>
                TCF IRN
            </button>
            <button
                type="button"
                role="tab"
                aria-selected={active === "CIVIQUE"}
                className={`ebh-toggle-btn ebh-toggle-btn-blue${active === "CIVIQUE" ? " is-active" : ""}`}
                onClick={() => onChange("CIVIQUE")}
            >
                <Lightbulb size={18} strokeWidth={1.8} aria-hidden/>
                Examen civique
            </button>
        </div>
    );
}

// ============================================================================
// SECTION MODULE — card TCF IRN / Examen civique (chrome + grille en children)
// ============================================================================
function ModuleExamsSection({
                                tone,
                                icon,
                                title,
                                chip,
                                sub,
                                stats,
                                tips,
                                children,
                            }: {
    tone: "blue" | "red";
    icon: ReactNode;
    title: string;
    chip: string;
    sub?: string;
    stats?: StatItem[];
    tips: string[];
    children: ReactNode;
}) {
    return (
        <section className="ebh-module">
            <header className="ebh-module-head">
                <span className={`ebh-module-icon ebh-module-icon-${tone}`} aria-hidden>
                    {icon}
                </span>
                <div className="ebh-module-titles">
                    <h2>{title}</h2>
                    {sub && <p>{sub}</p>}
                </div>
                <span className="ebh-module-chip">{chip}</span>
            </header>

            {stats && stats.length > 0 && (
                <div className="ebh-stats">
                    {stats.map((s) => (
                        <div className="ebh-stat" key={s.label}>
                            <span className="ebh-stat-val">{s.value}</span>
                            <span className="ebh-stat-lbl">{s.label}</span>
                        </div>
                    ))}
                </div>
            )}

            <div className="ebh-tips">
                {tips.map((t) => (
                    <span className={`ebh-tip ebh-tip-${tone}`} key={t}>
                        {t}
                    </span>
                ))}
            </div>

            {children}
        </section>
    );
}

// ============================================================================
// HELPERS
// ============================================================================
function HomeSkeleton() {
    return (
        <div className="ebh-loading">
            <style>{`.ebh-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
        </div>
    );
}

// ============================================================================
// VERSION GUEST — même grille que les connectés gratuits : examen 1 jouable en
// anonyme (diagnostic CO+CE, analytics user NULL + clientIp), 2-20 →
// inscription. Le full exam (EE/EO) exige un compte + abonnement.
// ============================================================================

function ExamsGuestHome() {
    const router = useRouter();
    const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
    const [error, setError] = useState<string | null>(null);
    const [guestGateOpen, setGuestGateOpen] = useState(false);
    /** Module dont la modale d'intro est ouverte (lancement démo inline). */
    const [introModule, setIntroModule] = useState<ModuleEnum | null>(null);
    const [demoStarting, setDemoStarting] = useState(false);
    const [demoError, setDemoError] = useState<string | null>(null);
    const [active, setActive] = useState<ExamModule>("TCF");

    useEffect(() => {
        let cancelled = false;
        publicExamApi
            .list()
            .then((list) => {
                if (!cancelled) setExams(list);
            })
            .catch((e: unknown) => {
                if (!cancelled)
                    setError(
                        e instanceof ApiException ? e.message : "Impossible de charger les examens.",
                    );
            });
        return () => {
            cancelled = true;
        };
    }, []);

    /** Template free de référence de chaque module pour l'examen 1 anonyme. */
    const examsByModule = useMemo(() => {
        const civique =
            exams.find((e) => e.module === "CIVIQUE" && e.free) ??
            exams.find((e) => e.module === "CIVIQUE") ??
            null;
        const tcf =
            exams.find((e) => e.module === "TCF" && e.free) ??
            exams.find((e) => e.module === "TCF") ??
            null;
        return {CIVIQUE: civique, TCF: tcf};
    }, [exams]);

    // Démarrer = ouvrir la même modale d'intro qu'en mode connecté (inline, pas
    // de navigation vers la page briefing). EE/EO restent verrouillés côté TCF.
    function openIntro(module: ModuleEnum) {
        if (!examsByModule[module]) {
            // Pas de template free pour ce module → on pousse à l'inscription.
            setGuestGateOpen(true);
            return;
        }
        setDemoError(null);
        setIntroModule(module);
    }

    async function launchDemo() {
        if (introModule === null || demoStarting) return;
        const tpl = examsByModule[introModule];
        if (!tpl) return;
        setDemoStarting(true);
        setDemoError(null);
        try {
            const a = await publicAttemptApi.startDemo({
                type: "MOCK_EXAM",
                module: introModule,
                examTemplateId: tpl.id,
            });
            router.push(`/sessions/${a.id}`);
        } catch (e) {
            handleStartFailure(e, {
                onPaywall: () => {
                    setIntroModule(null);
                    setGuestGateOpen(true);
                },
                onMessage: setDemoError,
                fallbackMessage: "Démarrage impossible.",
            });
            setDemoStarting(false);
        }
    }

    const civiqueTpl = examsByModule.CIVIQUE;
    const tcfTpl = examsByModule.TCF;

    return (
        <main className="ebh">
            <header className="ebh-head">
                <div className="ebh-eyebrow">
                    <Target size={16} aria-hidden/>
                    <span>Conditions réelles</span>
                </div>
                <h1>Examens blancs complets</h1>
                <p>
                    Une épreuve entière par parcours, qui mélange tous les thèmes.
                    Le premier examen de chaque parcours est offert, sans création de
                    compte — vos résultats ne seront pas sauvegardés.
                </p>
            </header>

            {error && <div className="ebh-error">{error}</div>}

            <ModuleToggle active={active} onChange={setActive}/>

            {active === "TCF" ? (
                <ModuleExamsSection
                    tone="red"
                    icon={<Waves size={22} strokeWidth={1.8}/>}
                    title="TCF IRN"
                    chip="Tous les modules"
                    // Sans compte, l'épreuve offerte est le diagnostic de
                    // compréhension (CO + CE, 50 Q / 55 min) : annoncer les
                    // 90 minutes et 4 épreuves de l'examen complet promettait
                    // ce que la modale de lancement refuse juste après.
                    tips={["Conditions réelles", "55 minutes", "50 questions", "Niveau CECRL"]}
                    sub={`${SLOTS} épreuves disponibles · 1 offerte sans compte`}
                >
                    <ExamsGrid
                        count={SLOTS}
                        exams={[]}
                        premium={false}
                        starting={false}
                        itemLabel="Épreuve"
                        collapsedCount={COLLAPSED}
                        lockedLabel="Compte gratuit"
                        onStart={() => openIntro("TCF")}
                        onLocked={() => setGuestGateOpen(true)}
                    />
                </ModuleExamsSection>
            ) : (
                <ModuleExamsSection
                    tone="blue"
                    icon={<Lightbulb size={22} strokeWidth={1.8}/>}
                    title="Examen civique"
                    chip="5 catégories mélangées"
                    tips={["Conditions réelles", "45 minutes", "Seuil 32/40", "40 questions"]}
                    sub={`${SLOTS} épreuves disponibles · 1 offerte sans compte`}
                >
                    <ExamsGrid
                        count={SLOTS}
                        exams={[]}
                        premium={false}
                        starting={false}
                        itemLabel="Examen"
                        collapsedCount={COLLAPSED}
                        lockedLabel="Compte gratuit"
                        onStart={() => openIntro("CIVIQUE")}
                        onLocked={() => setGuestGateOpen(true)}
                    />
                </ModuleExamsSection>
            )}

            {/* TCF : même modale qu'en connecté, mais EE/EO verrouillés (compte requis)
          et copie adaptée à la démo anonyme. Le « Commencer » lance le
          diagnostic CO+CE en anonyme. */}
            <ExamIntroSheet
                open={introModule === "TCF"}
                eyebrow="Examen blanc · TCF IRN"
                title="TCF IRN — compréhension en conditions réelles"
                subtitle="Sans compte, vous passez les 2 épreuves de compréhension. L'expression écrite et orale demandent un compte."
                facts={[
                    {
                        label: "questions de compréhension",
                        value: String(tcfTpl?.totalQuestions ?? 50),
                    },
                    {
                        label: "en conditions réelles",
                        value: `${Math.round((tcfTpl?.durationSeconds ?? 3300) / 60)} min`,
                    },
                    {label: "restitution", value: "Niveau CECRL", highlight: true},
                ]}
                epreuves={[
                    {icon: "🎧", label: "Compréhension orale", meta: "25 questions · 20 min"},
                    {icon: "📖", label: "Compréhension écrite", meta: "25 questions · 35 min"},
                    {icon: "✍️", label: "Expression écrite", meta: "3 tâches", locked: true},
                    {icon: "🎙️", label: "Expression orale", meta: "3 tâches", locked: true},
                ]}
                epreuvesLabel="Les 4 épreuves du TCF IRN"
                tips={[
                    "L'examen enchaîne la compréhension orale puis écrite, comme le vrai TCF.",
                    "En orale, chaque audio se lance seul et n'est joué qu'une seule fois.",
                    "Expression écrite et orale (évaluées par l'IA) : réservées aux comptes.",
                    "Sans compte, vos résultats ne sont pas sauvegardés.",
                ]}
                confirmLabel="Commencer"
                loading={demoStarting}
                error={introModule === "TCF" ? demoError : null}
                onConfirm={() => void launchDemo()}
                onClose={() => setIntroModule(null)}
            />

            {/* Civique : strictement la même modale qu'en connecté (pas d'EE/EO). */}
            <ExamIntroSheet
                open={introModule === "CIVIQUE"}
                eyebrow="Examen blanc · Examen civique"
                title="Examen civique en conditions réelles"
                subtitle="Le premier examen est offert, sans compte. Vos résultats ne seront pas sauvegardés."
                facts={[
                    {
                        label: "questions · 5 catégories",
                        value: String(civiqueTpl?.totalQuestions ?? 40),
                    },
                    {
                        label: "en conditions réelles",
                        value: `${Math.round((civiqueTpl?.durationSeconds ?? 2400) / 60)} min`,
                    },
                    {
                        label: "seuil de réussite",
                        value: `${civiqueTpl?.passingScore ?? 32}/${civiqueTpl?.totalQuestions ?? 40}`,
                        highlight: true,
                    },
                ]}
                tips={[
                    "L'examen brasse les 5 catégories du programme civique.",
                    "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
                    "Pas de retour en arrière : une réponse validée est définitive, comme le jour J.",
                    "Sans compte, vos résultats ne sont pas sauvegardés — créez un compte gratuit pour suivre votre progression.",
                ]}
                confirmLabel="Commencer"
                loading={demoStarting}
                error={introModule === "CIVIQUE" ? demoError : null}
                onConfirm={() => void launchDemo()}
                onClose={() => setIntroModule(null)}
            />

            <GuestGateSheet
                open={guestGateOpen}
                onClose={() => setGuestGateOpen(false)}
                message="Le premier examen blanc de chaque parcours est offert. Créez un compte gratuit pour passer les suivants et conserver vos résultats."
            />

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .ebh {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 40px 80px;
  }

  /* ===== header ===== */
  .ebh-head { margin-bottom: 24px; }
  .ebh-eyebrow {
    display: inline-flex; align-items: center; gap: 8px;
    font-size: 13px; font-weight: 700;
    letter-spacing: 0.04em; text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 8px;
  }
  .ebh-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.1;
  }
  .ebh-head p {
    margin: 0;
    color: var(--color-muted);
    font-size: 15.5px; line-height: 1.5;
    max-width: 640px;
  }

  .ebh-error {
    background: var(--color-red-light);
    border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent);
    color: var(--color-red-dark);
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 13.5px;
    margin-bottom: 16px;
  }

  /* ===== toggle parcours (2 boutons demi-largeur) ===== */
  .ebh-toggle {
    display: flex;
    gap: 10px;
    margin-bottom: 22px;
  }
  .ebh-toggle-btn {
    flex: 1 1 0;
    min-width: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 9px;
    padding: 14px 16px;
    border-radius: 14px;
    border: 1px solid var(--color-line);
    background: #fff;
    font-family: var(--font-sans);
    font-size: 15px;
    font-weight: 700;
    color: var(--color-muted);
    cursor: pointer;
    transition: color 0.15s ease, background 0.15s ease, border-color 0.15s ease;
  }
  .ebh-toggle-btn svg { flex-shrink: 0; }
  .ebh-toggle-btn:hover {
    color: var(--color-ink);
    border-color: color-mix(in srgb, var(--color-ink) 18%, transparent);
  }
  .ebh-toggle-btn.is-active {
    color: #fff;
    border-color: transparent;
  }
  .ebh-toggle-btn-red.is-active { background: var(--color-red); }
  .ebh-toggle-btn-blue.is-active { background: var(--color-blue); }

  /* ===== card module ===== */
  .ebh-module {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px;
    box-shadow: 0 1px 3px rgba(15, 24, 57, 0.04);
    margin-bottom: 22px;
  }
  .ebh-module-head {
    display: flex; align-items: center; gap: 14px;
    margin-bottom: 14px;
  }
  .ebh-module-icon {
    width: 46px; height: 46px;
    border-radius: 13px;
    display: grid; place-items: center;
    flex-shrink: 0;
    color: #fff;
  }
  .ebh-module-icon-blue { background: var(--color-blue); }
  .ebh-module-icon-red { background: var(--color-red); }
  .ebh-module-titles { flex: 1; min-width: 0; }
  .ebh-module-titles h2 {
    margin: 0 0 2px;
    font-family: var(--font-sans);
    font-size: 18px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .ebh-module-titles p {
    margin: 0;
    font-size: 13px; color: var(--color-muted);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .ebh-module-chip {
    font-size: 12px; font-weight: 700;
    color: var(--color-blue);
    background: var(--color-blue-light);
    padding: 5px 12px; border-radius: 999px;
    white-space: nowrap;
    flex-shrink: 0;
  }

  /* ===== stat cards (meilleur / dernier / niveau ou progression) ===== */
  .ebh-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin-bottom: 14px;
  }
  .ebh-stat {
    display: flex;
    flex-direction: column;
    gap: 3px;
    background: var(--color-blue-soft);
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 12px 14px;
    min-width: 0;
  }
  .ebh-stat-val {
    font-family: var(--font-sans);
    font-size: 20px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
    line-height: 1.1;
  }
  .ebh-stat-lbl {
    font-size: 12px; font-weight: 600;
    color: var(--color-muted);
  }

  /* ===== tips chips (remplace la phrase descriptive) ===== */
  .ebh-tips {
    display: flex; flex-wrap: wrap; gap: 8px;
    margin-bottom: 16px;
  }
  .ebh-tip {
    font-size: 12px; font-weight: 600;
    padding: 5px 11px; border-radius: 999px;
    background: var(--color-blue-soft);
    color: var(--color-blue);
    border: 1px solid var(--color-line);
    white-space: nowrap;
  }
  .ebh-tip-red {
    background: var(--color-red-light);
    color: var(--color-red-dark);
    border-color: color-mix(in srgb, var(--color-red) 18%, transparent);
  }

  .ebh-guest-foot {
    margin-top: 6px;
    text-align: center;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.55;
  }
  .ebh-guest-foot a {
    color: var(--color-blue); font-weight: 700;
    text-decoration: none;
  }
  .ebh-guest-foot a:hover { text-decoration: underline; }

  /* ===== responsive ===== */
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .ebh { padding: 64px 18px 48px; }
    .ebh-module-chip { display: none; }
    .ebh-module-titles p { white-space: normal; }
    .ebh-toggle-btn { font-size: 13.5px; padding: 12px 10px; gap: 7px; }
    .ebh-stats { gap: 7px; }
    .ebh-stat { padding: 10px; }
    .ebh-stat-val { font-size: 17px; }
    .ebh-stat-lbl { font-size: 11px; }
  }
`;
