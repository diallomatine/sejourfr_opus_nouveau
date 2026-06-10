"use client";

import {useRouter} from "next/navigation";
import {type ReactNode, useEffect, useMemo, useState} from "react";
import {Info, Lightbulb, Target, Waves} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {GuestGateSheet} from "@/app/_components/GuestGateSheet";
import {ExamsGrid, type ExamSlotData} from "@/app/_components/hub/DetailParts";
import {ExamIntroSheet} from "@/app/_components/hub/ExamIntroSheet";
import {examSlotGrid} from "@/lib/exam-slots";
import {TcfFullExamBriefingSheet} from "@/app/examens-blancs/tcf/TcfFullExamBriefingSheet";
import {ApiException, attemptApi, fullTcfExamApi, publicAttemptApi, publicExamApi,} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  cecrlIndex,
  type ExamTemplateSummary,
  type FullTcfExamSummaryResponse,
  isProductionAttempt,
  type Module as ModuleEnum,
  niveauCecrlLabel,
} from "@/lib/types";

const SLOTS = 20;
const COLLAPSED = 8;

/** Templates de référence des examens complets (briefing + lancement). */
const TCF_FREE_DIAGNOSTIC_SLUG = "tcf-mix-01";
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
    const [tcfComprehension, setTcfComprehension] = useState<AttemptSummaryResponse[]>([]);
    const [fullExams, setFullExams] = useState<FullTcfExamSummaryResponse[]>([]);
    const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);
    /** Slot dont le briefing d'examen complet est ouvert (lancement inline). */
    const [briefingSlot, setBriefingSlot] = useState<number | null>(null);
    /** Examen civique : template de référence + état de la modale d'intro. */
    const [civiqueTemplate, setCiviqueTemplate] = useState<ExamTemplateSummary | null>(null);
    const [civiqueSlot, setCiviqueSlot] = useState<number | null>(null);
    const [civiqueStarting, setCiviqueStarting] = useState(false);
    const [civiqueError, setCiviqueError] = useState<string | null>(null);

    const tcfPremium = user != null && canAccessModule(user, "TCF");
    const civiquePremium = user != null && canAccessModule(user, "CIVIQUE");

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        Promise.allSettled([
            attemptApi.listMine({type: "MOCK_EXAM", module: "CIVIQUE", limit: 100}),
            attemptApi.listMine({type: "MOCK_EXAM", module: "TCF", limit: 100}),
        ]).then(([c, t]) => {
            if (cancelled) return;
            if (c.status === "fulfilled") {
                // Examens complets civiques (40 Q tous thèmes) : on écarte les examens
                // thématiques (lotThemeId non null). Rangés par slot plus bas.
                setCivique(c.value.filter((a) => a.finishedAt && !a.lotThemeId));
            }
            if (t.status === "fulfilled") {
                // Diagnostic de compréhension TCF (50 Q CO → CE) : on écarte les examens
                // module (CO/CE/Structure) et les productions / TCF_COMPLET. Sert de
                // carte pour les comptes gratuits (1 offert).
                setTcfComprehension(
                    t.value.filter(
                        (a) =>
                            a.finishedAt &&
                            !a.moduleExamQuestionType &&
                            !isProductionAttempt(a) &&
                            a.totalQuestions != null,
                    ),
                );
            }
        });
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

    // Examens TCF complets : seulement pour les abonnés (le backend exige hasTcf).
    useEffect(() => {
        if (status !== "authenticated" || !tcfPremium) return;
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
    }, [status, tcfPremium]);

    // Grilles indexées par slot : refaire l'examen N met à jour la case N.
    const {bySlot: civiqueBySlot, latest: civiqueLatest} = useMemo(
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
    const {bySlot: tcfCompBySlot, latest: tcfCompLatest} = useMemo(
        () => examSlotGrid(tcfComprehension, SLOTS),
        [tcfComprehension],
    );
    const {bySlot: fullExamBySlot, latest: fullExamLatest} = useMemo(
        () => examSlotGrid(fullExams, SLOTS),
        [fullExams],
    );

    if (status === "loading" || !user) return <HomeSkeleton/>;

    // Cards full-exam (abonné) : mêmes cards que Civique. Un slot rempli =
    // examen complet déjà passé (Refaire relance, Rapport → bilan ou hub si
    // encore en cours). « Démarrer » ouvre le briefing inline. Rangé par slot :
    // refaire l'examen N met à jour la case N (parité mobile, V110).
    const fullExamSlotData: (ExamSlotData | null)[] = fullExamBySlot.map((e) =>
        e
            ? {
                id: e.id,
                passed: e.status === "COMPLETED",
                metaOverride:
                    e.status === "COMPLETED"
                        ? niveauCecrlLabel(e.finalCecrlLevel)
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
            if (e instanceof ApiException && e.status === 403) {
                setCiviqueSlot(null);
                setPaywallModule("CIVIQUE");
            } else {
                setCiviqueError(
                    e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.",
                );
            }
            setCiviqueStarting(false);
        }
    }

    // Le slot voulu est transmis au briefing TCF gratuit (?slot=N) qui le repasse
    // au start : refaire l'examen N réutilise slot_number=N.
    function startTcfDiagnostic(slot: number) {
        router.push(`/examens-blancs/${TCF_FREE_DIAGNOSTIC_SLUG}?slot=${slot}`);
    }

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

            <ModuleExamsSection
                tone="red"
                icon={<Waves size={22} strokeWidth={1.8}/>}
                title="TCF IRN"
                chip={tcfPremium ? "CO · CE · EE · EO" : "CO puis CE"}
                brewLine={
                    tcfPremium
                        ? "L'examen complet enchaîne les 4 épreuves dans l'ordre du vrai TCF IRN : compréhension orale et écrite, puis expression écrite et orale évaluées par l'IA. 90 min, niveau CECRL plancher des 4 épreuves."
                        : "Enchaîne les épreuves de compréhension dans l'ordre du vrai TCF : orale (25 questions · 20 min) puis écrite (25 questions · 35 min). L'expression écrite et orale se débloquent avec l'abonnement Intégral."
                }
                sub={
                    tcfPremium
                        ? fullExamSubline(fullExamLatest)
                        : comprehensionSubline(tcfCompLatest)
                }
            >
                {tcfPremium ? (
                    <ExamsGrid
                        count={SLOTS}
                        exams={fullExamSlotData}
                        premium
                        starting={false}
                        itemLabel="Examen"
                        collapsedCount={COLLAPSED}
                        reportPath={fullExamReportPath}
                        onStart={startFullExam}
                        onLocked={() => setPaywallModule("INTEGRAL")}
                    />
                ) : (
                    <ExamsGrid
                        count={SLOTS}
                        exams={tcfCompBySlot}
                        premium={false}
                        starting={false}
                        itemLabel="Épreuve"
                        collapsedCount={COLLAPSED}
                        onStart={startTcfDiagnostic}
                        onLocked={() => setPaywallModule("INTEGRAL")}
                    />
                )}
            </ModuleExamsSection>

            <ModuleExamsSection
                tone="blue"
                icon={<Lightbulb size={22} strokeWidth={1.8}/>}
                title="Examen civique"
                chip="5 catégories mélangées"
                brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
                sub={comprehensionSubline(civiqueLatest, 40)}
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

            {briefingSlot !== null && (
                <TcfFullExamBriefingSheet
                    slotNumber={briefingSlot}
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
// Sous-titres de card (stats récap)
// ============================================================================

/** Récap des examens QCM (compréhension TCF / civique) : score brut ou échelle
 *  calibrée TCF (100-499) dès qu'un examen calibré existe. */
function comprehensionSubline(
    exams: AttemptSummaryResponse[],
    scoreOutOf = 50,
): string {
    const done = Math.min(exams.length, SLOTS);
    if (done === 0) {
        return `${SLOTS} épreuves disponibles · aucune passée pour l'instant`;
    }
    const bestCalibrated = exams.reduce(
        (max: number | null, a) =>
            a.calibratedScore != null ? Math.max(max ?? 0, a.calibratedScore) : max,
        null,
    );
    const best = exams.reduce((max, a) => Math.max(max, a.score ?? 0), 0);
    const bestLabel =
        bestCalibrated != null ? `${bestCalibrated}/499` : `${best}/${scoreOutOf}`;
    return `${done}/${SLOTS} épreuves passées · meilleur ${bestLabel}`;
}

/** Récap des examens TCF complets : nombre terminés + meilleur niveau CECRL. */
function fullExamSubline(exams: FullTcfExamSummaryResponse[]): string {
    const completed = exams.filter(
        (e) => e.status === "COMPLETED" && e.finalCecrlLevel != null,
    );
    if (completed.length === 0) {
        return `${SLOTS} examens complets disponibles · aucun terminé pour l'instant`;
    }
    const bestLevel = completed.reduce<FullTcfExamSummaryResponse["finalCecrlLevel"]>(
        (best, e) =>
            best == null || cecrlIndex(e.finalCecrlLevel) > cecrlIndex(best)
                ? e.finalCecrlLevel
                : best,
        null,
    );
    return `${completed.length}/${SLOTS} examens complets · meilleur niveau ${niveauCecrlLabel(bestLevel)}`;
}

// ============================================================================
// SECTION MODULE — card TCF IRN / Examen civique (chrome + grille en children)
// ============================================================================
function ModuleExamsSection({
                                tone,
                                icon,
                                title,
                                chip,
                                brewLine,
                                sub,
                                children,
                            }: {
    tone: "blue" | "red";
    icon: ReactNode;
    title: string;
    chip: string;
    brewLine: string;
    sub: string;
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
                    <p>{sub}</p>
                </div>
                <span className="ebh-module-chip">{chip}</span>
            </header>

            <div className="ebh-brew">
                <Info size={15} aria-hidden/>
                <span>{brewLine}</span>
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
            setDemoError(
                e instanceof ApiException ? e.message : "Démarrage impossible.",
            );
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

            <ModuleExamsSection
                tone="red"
                icon={<Waves size={22} strokeWidth={1.8}/>}
                title="TCF IRN"
                chip="CO puis CE"
                brewLine="Enchaîne les épreuves de compréhension dans l'ordre du vrai TCF : orale (25 questions · 20 min) puis écrite (25 questions · 35 min). L'expression écrite et orale se débloquent avec un compte abonné."
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

            <ModuleExamsSection
                tone="blue"
                icon={<Lightbulb size={22} strokeWidth={1.8}/>}
                title="Examen civique"
                chip="5 catégories mélangées"
                brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
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

  .ebh-brew {
    display: flex; align-items: flex-start; gap: 8px;
    background: var(--color-blue-soft);
    border: 1px solid var(--color-line);
    border-radius: 11px;
    padding: 10px 14px;
    font-size: 12.5px; line-height: 1.5;
    color: var(--color-muted);
    margin-bottom: 16px;
  }
  .ebh-brew svg { flex-shrink: 0; margin-top: 2px; color: var(--color-blue); }

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
  }
`;
