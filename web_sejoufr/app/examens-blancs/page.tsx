"use client";

import {useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleToggle} from "@/app/_components/ModuleToggle";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {GuestGateSheet} from "@/app/_components/GuestGateSheet";
import {ExamDoneSheet} from "@/app/_components/hub/ExamDoneSheet";
import {ExamIntroSheet} from "@/app/_components/hub/ExamIntroSheet";
import {
    Badge,
    BlockError,
    BlockSkeleton,
    ExamRow,
    Hero,
    PageHead,
    Pad,
    Section,
    SejourApp,
    sejourStyles,
    type ActionCardCta,
    type ExamRowStatus,
    type HeroStat,
    type ModuleTone,
} from "@/app/_components/sejour/SejourKit";
import {IconShield, IconTarget} from "@/app/_components/shell/ShellIcons";
import {examSlotGrid} from "@/lib/exam-slots";
import {moduleDeLUrl, type ParcoursModule} from "@/lib/module-switch";
import {useExamSlotGrid} from "@/lib/use-exam-slot-locks";
import {EPREUVE_PRESENTATION, FULL_TCF_EXAM_INDICATIVE_SEC, minutesLabel, plannedEpreuveLabel} from "@/lib/exam-durations";
import {isCompleteExamResult} from "@/lib/exam-levels";
import {TcfFullExamBriefingSheet} from "@/app/examens-blancs/tcf/TcfFullExamBriefingSheet";
import {
    ApiException,
    attemptApi,
    dashboardApi,
    fullTcfExamApi,
    progressionApi,
    publicAttemptApi,
    publicExamApi,
} from "@/lib/api";
import {CIVIQUE_EXAM_DUREE_MINUTES, CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "@/lib/civique-examen";
import {unlockCoAudio} from "@/lib/co-audio";
import {handleStartFailure} from "@/lib/start-failure";
import {useAuth} from "@/lib/auth-context";
import {
    EXAMENS_BLOCK_ERROR,
    EXAMENS_CIVIQUE_HERO_CTA,
    EXAMENS_CIVIQUE_HERO_PASS,
    EXAMENS_CIVIQUE_HERO_LABEL,
    EXAMENS_CIVIQUE_HERO_TITLE,
    EXAMENS_CIVIQUE_LIST_TITLE,
    EXAMENS_CIVIQUE_SUBTITLE,
    EXAMENS_CIVIQUE_TITLE,
    EXAMENS_DONE_DETAIL,
    EXAMENS_DONE_RESUME,
    EXAMENS_LIST_TITLE,
    EXAMENS_META_GUEST_LOCKED,
    EXAMENS_META_IN_PROGRESS,
    EXAMENS_META_OPEN,
    EXAMENS_META_PENDING,
    EXAMENS_MINUTES_LABEL,
    EXAMENS_QUESTIONS_LABEL,
    EXAMENS_REDUIRE,
    EXAMENS_RETRY,
    EXAMENS_STATUS_DONE,
    EXAMENS_STATUS_GO,
    EXAMENS_STATUS_LOCKED,
    EXAMENS_STATUS_RESUME,
    EXAMENS_TCF_HERO_LABEL,
    EXAMENS_TCF_HERO_SUB,
    EXAMENS_TCF_HERO_TITLE,
    EXAMENS_TCF_MINUTES,
    EXAMENS_TCF_SUBTITLE,
    EXAMENS_TCF_TITLE,
    creneauxOuverts,
    examenCiviqueTitre,
    examenTcfTitre,
    examensCiviqueHeroSub,
    examensTermines,
    examensTcfHeroResume,
    EXAMENS_TCF_HERO_PASS,
    EXAMENS_TERMINES_LABEL,
    examensGuestOffre,
    examensMeilleurScore,
    examensMetaCiviqueTermine,
    examensMetaLocked,
    examensMetaTcfTermine,
    examensTcfHeroCta,
    examensTcfOffert,
    examensVisibles,
    examensVoirSuite,
    premierCreneauOuvert,
    prochainCreneau,
} from "@/lib/examens-blancs";
import {MODULE_CIVIQUE_KICKER, MODULE_TCF_KICKER} from "@/lib/module-ecrans";
import {progressionTaux} from "@/lib/progression";
import {TCF_EPREUVES_OFFICIELLES} from "@/lib/tcf-epreuves";
import {
    type AttemptSummaryResponse,
    canAccessModule,
    cecrlIndex,
    type DashboardSummaryResponse,
    estimatedTcfLevelScopeLabel,
    type ExamTemplateSummary,
    type FullTcfExamSummaryResponse,
    type Module as ModuleEnum,
    type NiveauCecrl,
    niveauCecrlLabel,
    niveauCecrlShort,
    type ProgressionCiviqueDto,
} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";

/** Une stat affichée sous le bandeau (valeur + libellé). */
interface StatItem {
    value: string;
    label: string;
    /** Précision facultative sous le libellé (périmètre d'un niveau estimé
     *  partiel). Absente ⇒ la stat garde exactement ses deux lignes. */
    hint?: string | null;
}

/** Template de référence de l'examen civique complet (briefing + lancement). */
const CIVIQUE_FULL_EXAM_SLUG = "civique-decouverte";

/** Une ligne de la liste « Mes examens », prête pour `ExamRow`. */
interface ExamLine {
    slot: number;
    title: string;
    meta: string | null;
    status: ExamRowStatus;
    statusLabel: string;
    /** Un examen déjà passé : la ligne compte dans « passés » (repli). */
    passe: boolean;
    onClick: () => void;
}

/** L'examen passé dont la feuille « Voir le rapport / Refaire » est ouverte. */
interface DoneSheet {
    title: string;
    subtitle: string | null;
    onDetail: () => void;
    onResume: () => void;
}

/**
 * `/examens-blancs` — Navigation v2, phase 4 (maquette `#tcf-examens` /
 * `#civique-examens`).
 *
 * - **TCF** : en-tête, bandeau « Examen blanc complet » (épreuves du miroir,
 *   durée de la table unique, CTA sur le prochain créneau ouvert servi), puis
 *   « Mes examens » : la grille SERVIE en `ExamRow`. « Commencer » ouvre le
 *   briefing inline → hub `/examens-blancs/tcf/[id]`.
 * - **Civique** : bandeau rouge « Examen blanc civique » (format de l'arrêté,
 *   nombre de thèmes servi), « Historique » : la grille servie en `ExamRow`,
 *   « réussi » lu sur `seuilAtteint` servi seulement.
 * - **Gardés** : stats + tips, grille repliée, briefing, feuille
 *   d'introduction, paywall, mention de l'examen offert, la bascule du
 *   VISITEUR (DEC-13).
 *
 * 🛑 Le nombre de créneaux est celui de la grille servie, jamais une constante.
 */
export default function ExamensBlancsHomePage() {
    return (
        <Suspense fallback={<HomeSkeleton/>}>
            <ExamensBlancsRoot/>
        </Suspense>
    );
}

/**
 * 🛑 **Le parcours affiché vient de l'URL** (`?module=TCF|CIVIQUE`, nu → TCF),
 * plus d'un état local (Navigation v2, 2026-10-03) : la barre latérale porte
 * une entrée « Examens » par module, et l'adresse se partage.
 */
function useExamModule(): ParcoursModule {
    return moduleDeLUrl(useSearchParams()) ?? "TCF";
}

function ExamensBlancsRoot() {
    const {status} = useAuth();
    if (status === "loading") return <HomeSkeleton/>;
    if (status === "guest") return <ExamsGuestHome/>;
    return (
        <DualChromeShell>
            <ExamsConnectedHome/>
        </DualChromeShell>
    );
}

/** Une lecture réessayable : la donnée, son échec, et « Réessayer ». */
function useLecture<T>(enabled: boolean, load: () => Promise<T>, deps: ReadonlyArray<unknown>) {
    const [state, setState] = useState<{data: T | undefined; error: boolean}>({data: undefined, error: false});
    const [tentative, setTentative] = useState(0);
    useEffect(() => {
        if (!enabled) return;
        let vivant = true;
        load()
            .then((data) => {
                if (vivant) setState({data, error: false});
            })
            .catch(() => {
                if (vivant) setState((s) => ({data: s.data, error: true}));
            });
        return () => {
            vivant = false;
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [enabled, tentative, ...deps]);
    return {
        ...state,
        reload: () => {
            setState((s) => ({data: s.data, error: false}));
            setTentative((n) => n + 1);
        },
    };
}

function ExamsConnectedHome() {
    const router = useRouter();
    const {user, status} = useAuth();
    const active = useExamModule();
    const actif = status === "authenticated";

    const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);
    /** Slot dont le briefing d'examen complet est ouvert (lancement inline). */
    const [briefingSlot, setBriefingSlot] = useState<number | null>(null);
    /** Examen civique : template de référence + état de la modale d'intro. */
    const [civiqueTemplate, setCiviqueTemplate] = useState<ExamTemplateSummary | null>(null);
    const [civiqueSlot, setCiviqueSlot] = useState<number | null>(null);
    const [civiqueStarting, setCiviqueStarting] = useState(false);
    const [civiqueError, setCiviqueError] = useState<string | null>(null);
    const [doneSheet, setDoneSheet] = useState<DoneSheet | null>(null);
    /** Dashboard agrégé (cache 30 s) : niveau TCF estimé, maîtrise et thèmes civiques. */
    const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);

    // 🛑 Les verrous des deux grilles sont SERVIS, créneau par créneau : la
    // page ne les déduit ni du rang ni de l'accès du compte.
    const tcfGrid = useExamSlotGrid(active === "TCF" ? "TCF_COMPLET" : null);
    const civiqueGrid = useExamSlotGrid(active === "CIVIQUE" ? "CIVIQUE" : null);
    const tcfSlots = tcfGrid.locks.length;
    const civiqueSlots = civiqueGrid.locks.length;

    // Examens complets civiques (40 Q tous thèmes) : on écarte les examens
    // thématiques (lotThemeId non null). Rangés par slot plus bas.
    const civique = useLecture<AttemptSummaryResponse[]>(
        actif && active === "CIVIQUE",
        () => attemptApi
            .listMine({type: "MOCK_EXAM", module: "CIVIQUE", limit: 100})
            .then((list) => list.filter((a) => a.finishedAt && !a.lotThemeId)),
        [],
    );

    // Examens TCF complets, lus sur autant de créneaux que la grille servie.
    const fullExams = useLecture<FullTcfExamSummaryResponse[]>(
        actif && active === "TCF" && tcfSlots > 0,
        () => fullTcfExamApi.listMine(tcfSlots),
        [tcfSlots],
    );

    // Les examens civiques globaux SERVIS (`seuilAtteint`, meilleur taux) : la
    // même lecture que l'écran Progression, en cache.
    const progressionCivique = useCachedData<ProgressionCiviqueDto>(
        actif && active === "CIVIQUE" ? progressionApi.civiqueKey(true) : null,
        () => progressionApi.civique(true),
    );

    // Métadonnées du template civique (questions / durée / seuil) pour la modale.
    useEffect(() => {
        if (!actif) return;
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
    }, [actif]);

    // Dashboard agrégé (cache 30 s, partagé avec la barre latérale).
    useEffect(() => {
        if (!actif) return;
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
    }, [actif]);

    // Grilles indexées par slot : refaire l'examen N met à jour la case N.
    const civiqueBySlot = useMemo(
        () => examSlotGrid(civique.data ?? [], civiqueSlots).bySlot,
        [civique.data, civiqueSlots],
    );
    const fullExamBySlot = useMemo(
        () => examSlotGrid(fullExams.data ?? [], tcfSlots).bySlot,
        [fullExams.data, tcfSlots],
    );
    if (status === "loading" || !user) return <HomeSkeleton/>;

    const tcfPremium = canAccessModule(user, "TCF");
    const nbThemes = summary ? summary.civique.length : null;

    function startFullExam(slot: number) {
        setBriefingSlot(slot);
    }

    // Civique : modale d'intro inline, puis lancement.
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

    // ---- TCF ----------------------------------------------------------------
    const tcfNext = prochainCreneau(tcfGrid.locks, fullExamBySlot);
    /* Un examen en cours se reprend : aucun autre créneau n'est mis en avant
       (parité mobile). */
    const tcfEnCours = fullExamBySlot.some((e) => e?.status === "IN_PROGRESS");
    const tcfLines: ExamLine[] = fullExamBySlot.map((e, i) => {
        const slot = i + 1;
        const locked = tcfGrid.locks[i] ?? true;
        if (e) {
            if (e.status === "IN_PROGRESS") {
                // Un examen suspendu garde son slot et reste reprenable : on
                // ouvre son hub, jamais un bilan, et pas de « Refaire ».
                return {
                    slot, title: examenTcfTitre(slot), meta: EXAMENS_META_IN_PROGRESS,
                    status: "go", statusLabel: EXAMENS_STATUS_RESUME, passe: true,
                    onClick: () => router.push(`/examens-blancs/tcf/${e.id}`),
                };
            }
            return {
                slot,
                title: examenTcfTitre(slot),
                meta: e.status === "COMPLETED"
                    ? examensMetaTcfTermine(niveauCecrlShort(e.finalCecrlLevel), e.finalLevelPartial)
                    : EXAMENS_META_PENDING,
                status: "done",
                statusLabel: EXAMENS_STATUS_DONE,
                passe: true,
                onClick: () => setDoneSheet({
                    title: examenTcfTitre(slot),
                    subtitle: null,
                    onDetail: () => router.push(`/examens-blancs/tcf/${e.id}/bilan`),
                    onResume: () => (locked ? setPaywallModule("INTEGRAL") : startFullExam(slot)),
                }),
            };
        }
        return lineToStart(slot, examenTcfTitre(slot), locked, "INTEGRAL", tcfEnCours ? null : tcfNext,
            () => startFullExam(slot), () => setPaywallModule("INTEGRAL"));
    });
    /* Le bandeau : reprendre l'examen en cours, sinon le 1ᵉʳ créneau libre
       ouvert, sinon (tout verrouillé) l'offre ; rien à faire ⇒ pas de bouton. */
    const enCoursIndex = fullExamBySlot.findIndex((e) => e?.status === "IN_PROGRESS");
    const enCours = enCoursIndex >= 0 ? fullExamBySlot[enCoursIndex] : null;
    const tcfHeroCta: ActionCardCta | null = enCours
        ? {label: examensTcfHeroResume(enCoursIndex + 1), href: `/examens-blancs/tcf/${enCours.id}`}
        : tcfNext
            ? {label: examensTcfHeroCta(tcfNext), onClick: () => startFullExam(tcfNext)}
            : tcfSlots > 0 && tcfGrid.locks.some((l, i) => l && !fullExamBySlot[i])
                ? {label: EXAMENS_TCF_HERO_PASS, onClick: () => setPaywallModule("INTEGRAL")}
                : null;
    const tcfOffert = !tcfPremium ? premierCreneauOuvert(tcfGrid.locks) : null;

    // Durée indicative, jamais un chrono : chaque épreuve porte le sien.
    // Seuls les examens **complets** alimentent « Meilleur niveau » / « Dernier
    // examen » : un bilan partiel ne porte pas sur les 4 épreuves.
    const completedFull = (fullExams.data ?? []).filter(isCompleteExamResult);
    const bestFullLevel = completedFull.reduce<NiveauCecrl | null>(
        (best, e) =>
            best == null || cecrlIndex(e.finalCecrlLevel) > cecrlIndex(best) ? e.finalCecrlLevel : best,
        null,
    );
    const lastFull = mostRecentFull(completedFull);
    const tcfFaits = fullExamBySlot.filter(Boolean).length;
    const tcfStats: StatItem[] = [
        {value: examensTermines(tcfFaits, tcfSlots || null), label: EXAMENS_TERMINES_LABEL},
        {value: niveauCecrlLabel(bestFullLevel), label: "Meilleur niveau"},
        {value: lastFull ? niveauCecrlLabel(lastFull.finalCecrlLevel) : "—", label: "Dernier examen"},
        // Un niveau estimé partiel le dit : à côté de « Meilleur niveau », il
        // se lirait sinon comme un résultat de même portée.
        {
            value: niveauCecrlLabel(summary?.estimatedTcfLevel ?? null),
            label: "Niveau estimé",
            hint: estimatedTcfLevelScopeLabel(summary),
        },
    ];
    const tcfTips = [
        "Conditions réelles",
        `≈ ${minutesLabel(FULL_TCF_EXAM_INDICATIVE_SEC)}`,
        `${TCF_EPREUVES_OFFICIELLES.length} épreuves`,
        "Niveau CECRL",
    ];

    // ---- Civique ------------------------------------------------------------
    const civiqueNext = prochainCreneau(civiqueGrid.locks, civiqueBySlot);
    const civiqueLines: ExamLine[] = civiqueBySlot.map((a, i) => {
        const slot = i + 1;
        const locked = civiqueGrid.locks[i] ?? true;
        if (a) {
            return {
                slot,
                title: examenCiviqueTitre(slot),
                // Aucun verdict de seuil n'est servi par créneau : pas de « réussi ».
                meta: examensMetaCiviqueTermine(civiqueScoreLabel(a)),
                status: "done",
                statusLabel: EXAMENS_STATUS_DONE,
                passe: true,
                onClick: () => setDoneSheet({
                    title: examenCiviqueTitre(slot),
                    subtitle: null,
                    onDetail: () => router.push(`/sessions/${a.id}`),
                    onResume: () => (locked ? setPaywallModule("CIVIQUE") : startCivique(slot)),
                }),
            };
        }
        return lineToStart(slot, examenCiviqueTitre(slot), locked, "CIVIQUE", civiqueNext,
            () => startCivique(slot), () => setPaywallModule("CIVIQUE"));
    });

    /* 🛑 « Terminés x/N », plus « Progression % » (parité mobile) : l'ancienne
       stat était `moduleAverage` (moyenne des maîtrises de thème), une seconde
       lecture d'avancement à côté du pourcentage de séries. On compte les
       créneaux passés sur la grille SERVIE. */
    const civiqueFaits = civiqueBySlot.filter(Boolean).length;
    const civiqueExams = civique.data ?? [];
    const civiqueStats: StatItem[] = [
        {value: civiqueScoreLabel(bestScored(civiqueExams)), label: "Meilleur score"},
        {value: civiqueScoreLabel(mostRecent(civiqueExams)), label: "Dernier examen"},
        {value: examensTermines(civiqueFaits, civiqueSlots || null), label: EXAMENS_TERMINES_LABEL},
    ];
    /* 🛑 LE FORMAT VIENT DE LA LOI, PAS DU TEMPLATE (2026-09-19). Miroir gelé :
       `lib/civique-examen.ts` ⇄ `mobile/core/utils/civique_examen.dart`. */
    /* Le bandeau : le 1ᵉʳ créneau libre ouvert, sinon (créneaux libres tous
       verrouillés) l'offre ; rien à faire ⇒ pas de bouton. Même règle que le
       TCF et que le mobile. */
    const civiqueHeroCta: ActionCardCta | null = civiqueNext
        ? {label: EXAMENS_CIVIQUE_HERO_CTA, onClick: () => startCivique(civiqueNext)}
        : civiqueSlots > 0 && civiqueGrid.locks.some((l, i) => l && !civiqueBySlot[i])
            ? {label: EXAMENS_CIVIQUE_HERO_PASS, onClick: () => setPaywallModule("CIVIQUE")}
            : null;
    const civiqueTips = [
        "Conditions réelles",
        `${CIVIQUE_EXAM_DUREE_MINUTES} minutes`,
        `Seuil ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`,
        `${CIVIQUE_EXAM_QUESTIONS} questions`,
    ];
    const categories = nbThemes ? `${nbThemes} catégories` : "catégories";
    const meilleurTaux = progressionCivique.data && progressionCivique.data.global.nombre > 0
        ? progressionTaux(progressionCivique.data.global.meilleur?.taux ?? null)
        : null;

    const tcf = active === "TCF";

    return (
        <SejourApp className={sejourStyles.home}>
            <Pad>
                {tcf ? (
                    <PageHead
                        kicker={MODULE_TCF_KICKER}
                        title={EXAMENS_TCF_TITLE}
                        subtitle={EXAMENS_TCF_SUBTITLE}
                    />
                ) : (
                    <PageHead
                        kicker={MODULE_CIVIQUE_KICKER}
                        tone="civique"
                        title={EXAMENS_CIVIQUE_TITLE}
                        subtitle={EXAMENS_CIVIQUE_SUBTITLE}
                        aside={meilleurTaux ? (
                            <Badge module="civique">{examensMeilleurScore(meilleurTaux)}</Badge>
                        ) : null}
                    />
                )}
            </Pad>

            <Pad>
                <div className={sejourStyles.pageBody}>
                    {tcf ? (
                        <Hero
                            module="tcf"
                            icon={<IconTarget/>}
                            label={EXAMENS_TCF_HERO_LABEL}
                            title={EXAMENS_TCF_HERO_TITLE}
                            sub={EXAMENS_TCF_HERO_SUB}
                            stat={{value: String(EXAMENS_TCF_MINUTES), label: EXAMENS_MINUTES_LABEL}}
                            cta={tcfHeroCta}
                        />
                    ) : (
                        <Hero
                            module="civique"
                            icon={<IconShield/>}
                            label={EXAMENS_CIVIQUE_HERO_LABEL}
                            title={EXAMENS_CIVIQUE_HERO_TITLE}
                            sub={examensCiviqueHeroSub(nbThemes)}
                            stat={{value: String(CIVIQUE_EXAM_QUESTIONS), label: EXAMENS_QUESTIONS_LABEL}}
                            cta={civiqueHeroCta}
                        />
                    )}
                    <ExamStats module={tcf ? "tcf" : "civique"} stats={tcf ? tcfStats : civiqueStats} tips={tcf ? tcfTips : civiqueTips}/>
                </div>
            </Pad>

            <Section title={tcf ? EXAMENS_LIST_TITLE : EXAMENS_CIVIQUE_LIST_TITLE}>
                <Pad>
                    {tcf && tcfOffert ? <p className={`${sejourStyles.tiny} ebh-note`}>{examensTcfOffert(tcfOffert)}</p> : null}
                    {tcf ? (
                        <ExamList
                            module="tcf"
                            lines={tcfLines}
                            loading={tcfGrid.loading || (tcfSlots > 0 && fullExams.data === undefined && !fullExams.error)}
                            error={tcfGrid.error || fullExams.error}
                            onRetry={() => {
                                if (tcfGrid.error) tcfGrid.reload();
                                if (fullExams.error) fullExams.reload();
                            }}
                        />
                    ) : (
                        <ExamList
                            module="civique"
                            lines={civiqueLines}
                            loading={civiqueGrid.loading || (civique.data === undefined && !civique.error)}
                            error={civiqueGrid.error || civique.error}
                            onRetry={() => {
                                if (civiqueGrid.error) civiqueGrid.reload();
                                if (civique.error) civique.reload();
                            }}
                        />
                    )}
                </Pad>
            </Section>

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
                    {label: `questions · ${categories}`, value: String(CIVIQUE_EXAM_QUESTIONS)},
                    {label: "en conditions réelles", value: `${CIVIQUE_EXAM_DUREE_MINUTES} min`},
                    {
                        label: "seuil de réussite",
                        value: `${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`,
                        highlight: true,
                    },
                ]}
                tips={[
                    `L'examen brasse ${nbThemes ? `les ${nbThemes}` : "les"} catégories du programme civique.`,
                    "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
                    "Pas de retour en arrière : une réponse validée est définitive, comme le jour J.",
                ]}
                loading={civiqueStarting}
                error={civiqueError}
                onConfirm={() => void launchCivique()}
                onClose={() => setCiviqueSlot(null)}
            />

            <ExamDoneSheet
                open={doneSheet !== null}
                title={doneSheet?.title}
                subtitle={doneSheet?.subtitle}
                detailLabel={EXAMENS_DONE_DETAIL}
                resumeLabel={EXAMENS_DONE_RESUME}
                onViewDetail={() => {
                    const sheet = doneSheet;
                    setDoneSheet(null);
                    sheet?.onDetail();
                }}
                onResume={() => {
                    const sheet = doneSheet;
                    setDoneSheet(null);
                    sheet?.onResume();
                }}
                onClose={() => setDoneSheet(null)}
            />

            <PaywallSheet ctaLocation="MOCK_EXAM" screen="examens_blancs"
                open={paywallModule !== null}
                onClose={() => setPaywallModule(null)}
                module={paywallModule ?? "CIVIQUE"}
            />

            <style>{styles}</style>
        </SejourApp>
    );
}

/**
 * La ligne d'un créneau encore vide : « Commencer » (plein sur le prochain à
 * lancer, doux sinon) ou « Verrouillé » selon le verrou SERVI.
 */
function lineToStart(
    slot: number,
    title: string,
    locked: boolean,
    pass: "INTEGRAL" | "CIVIQUE",
    next: number | null,
    onStart: () => void,
    onLocked: () => void,
): ExamLine {
    if (locked) {
        return {
            slot, title, meta: examensMetaLocked(pass), status: "locked",
            statusLabel: EXAMENS_STATUS_LOCKED, passe: false, onClick: onLocked,
        };
    }
    return {
        slot, title, meta: EXAMENS_META_OPEN, status: slot === next ? "go" : "neutral",
        statusLabel: EXAMENS_STATUS_GO, passe: false, onClick: onStart,
    };
}

// ============================================================================
// Blocs
// ============================================================================

/** Les stats + les puces de conditions, sous le bandeau (blocs gardés). */
function ExamStats({module, stats, tips}: {module: ModuleTone; stats?: StatItem[]; tips: string[]}) {
    return (
        <>
            {stats && stats.length > 0 && (
                <div className="ebh-stats">
                    {stats.map((s) => (
                        <div className="ebh-stat" key={s.label}>
                            <span className="ebh-stat-val">{s.value}</span>
                            <span className="ebh-stat-lbl">{s.label}</span>
                            {s.hint && <span className="ebh-stat-hint">{s.hint}</span>}
                        </div>
                    ))}
                </div>
            )}
            <div className="ebh-tips">
                {tips.map((t) => (
                    <span className={`ebh-tip ebh-tip-${module}`} key={t}>{t}</span>
                ))}
            </div>
        </>
    );
}

/**
 * « Mes examens » : la grille SERVIE en `ExamRow`, repliée à 8 lignes (jamais
 * moins que les examens passés + le suivant), avec son squelette et son échec.
 */
function ExamList({
    module,
    lines,
    loading,
    error,
    onRetry,
}: {
    module: ModuleTone;
    lines: ExamLine[];
    loading: boolean;
    error: boolean;
    onRetry: () => void;
}) {
    const [deplie, setDeplie] = useState(false);
    if (error) return <BlockError message={EXAMENS_BLOCK_ERROR} retryLabel={EXAMENS_RETRY} onRetry={onRetry}/>;
    if (loading) {
        return (
            <div className="ebh-list">
                <BlockSkeleton height={74} radius={22}/>
                <BlockSkeleton height={74} radius={22}/>
                <BlockSkeleton height={74} radius={22}/>
            </div>
        );
    }
    if (lines.length === 0) return null;
    const passes = lines.filter((l) => l.passe).length;
    const visibles = examensVisibles(lines.length, passes, deplie);
    return (
        <>
            <div className="ebh-list">
                {lines.slice(0, visibles).map((l) => (
                    <ExamRow
                        key={l.slot}
                        module={module}
                        number={l.slot}
                        title={l.title}
                        meta={l.meta}
                        status={l.status}
                        statusLabel={l.statusLabel}
                        onClick={l.onClick}
                    />
                ))}
            </div>
            {visibles < lines.length ? (
                <button type="button" className={sejourStyles.link} onClick={() => setDeplie(true)}>
                    {examensVoirSuite(visibles + 1, lines.length)}
                </button>
            ) : deplie ? (
                <button type="button" className={sejourStyles.link} onClick={() => setDeplie(false)}>
                    {EXAMENS_REDUIRE}
                </button>
            ) : null}
        </>
    );
}

// ============================================================================
// Helpers stats (meilleur / dernier examen)
// ============================================================================

/** Attempt au meilleur score brut (civique). Null si aucun score. */
function bestScored(exams: AttemptSummaryResponse[]): AttemptSummaryResponse | null {
    return exams.reduce<AttemptSummaryResponse | null>(
        (best, a) => (a.score != null && (best == null || a.score > (best.score ?? -1)) ? a : best),
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
function mostRecentFull(exams: FullTcfExamSummaryResponse[]): FullTcfExamSummaryResponse | null {
    return exams.reduce<FullTcfExamSummaryResponse | null>((latest, e) => {
        const t = e.finishedAt ?? e.startedAt;
        const lt = latest ? (latest.finishedAt ?? latest.startedAt) : "";
        return latest == null || t > lt ? e : latest;
    }, null);
}

/** Score civique affichable : brut sur le total de questions, sinon « — ». */
function civiqueScoreLabel(a: AttemptSummaryResponse | null): string {
    if (!a || a.score == null) return "—";
    return `${a.score}/${a.totalQuestions ?? CIVIQUE_EXAM_QUESTIONS}`;
}

function HomeSkeleton() {
    return (
        <div className="ebh-loading">
            <style>{`.ebh-loading { min-height: calc(100vh - 80px); background: var(--color-paper); }`}</style>
        </div>
    );
}

// ============================================================================
// VERSION GUEST — examen 1 jouable en anonyme (diagnostic CO+CE côté TCF,
// examen civique offert), les suivants → inscription. 🛑 La bascule de
// parcours reste pour le visiteur seul, en liens `?module=` (DEC-13).
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
    const active = useExamModule();
    // Grilles vues d'un visiteur : le serveur n'y ouvre que ce qui est offert
    // sans compte (l'examen gratuit de chaque parcours).
    const grid = useExamSlotGrid(active === "TCF" ? "TCF_COMPLET" : "CIVIQUE");

    useEffect(() => {
        let cancelled = false;
        publicExamApi
            .list()
            .then((list) => {
                if (!cancelled) setExams(list);
            })
            .catch((e: unknown) => {
                if (!cancelled) setError(e instanceof ApiException ? e.message : "Impossible de charger les examens.");
            });
        return () => {
            cancelled = true;
        };
    }, []);

    /** Template free de référence de chaque module pour l'examen anonyme. */
    const examsByModule = useMemo(() => {
        const civique =
            exams.find((e) => e.module === "CIVIQUE" && e.free) ?? exams.find((e) => e.module === "CIVIQUE") ?? null;
        const tcf = exams.find((e) => e.module === "TCF" && e.free) ?? exams.find((e) => e.module === "TCF") ?? null;
        return {CIVIQUE: civique, TCF: tcf};
    }, [exams]);

    // Démarrer = ouvrir la même modale d'intro qu'en mode connecté.
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
        // Dans le clic, avant tout `await` : la 1re question CO partira seule.
        if (introModule === "TCF") unlockCoAudio();
        setDemoStarting(true);
        setDemoError(null);
        try {
            const a = await publicAttemptApi.startDemo({type: "MOCK_EXAM", module: introModule, examTemplateId: tpl.id});
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

    const tcfTpl = examsByModule.TCF;
    const tcf = active === "TCF";
    const tone: ModuleTone = tcf ? "tcf" : "civique";
    const slots = grid.locks.length;
    const ouverts = creneauxOuverts(grid.locks);
    const next = prochainCreneau(grid.locks, []);
    const lines: ExamLine[] = grid.locks.map((locked, i) => {
        const slot = i + 1;
        const title = tcf ? examenTcfTitre(slot) : examenCiviqueTitre(slot);
        return locked
            ? {
                slot, title, meta: EXAMENS_META_GUEST_LOCKED, status: "locked" as const,
                statusLabel: EXAMENS_STATUS_LOCKED, passe: false, onClick: () => setGuestGateOpen(true),
            }
            : {
                slot, title, meta: EXAMENS_META_OPEN, status: slot === next ? "go" as const : "neutral" as const,
                statusLabel: EXAMENS_STATUS_GO, passe: false, onClick: () => openIntro(active),
            };
    });

    // Sans compte, l'épreuve TCF offerte est le diagnostic de compréhension
    // (CO + CE) : durée et volume lus sur SON gabarit, jamais ceux de l'examen
    // complet que la modale refuserait juste après.
    const tcfMinutes = tcfTpl?.durationSeconds ? Math.round(tcfTpl.durationSeconds / 60) : null;
    const heroStat: HeroStat | null = tcf
        ? (tcfMinutes ? {value: String(tcfMinutes), label: EXAMENS_MINUTES_LABEL} : null)
        : {value: String(CIVIQUE_EXAM_QUESTIONS), label: EXAMENS_QUESTIONS_LABEL};
    const tips = tcf
        ? [
            "Conditions réelles",
            ...(tcfMinutes ? [`${tcfMinutes} minutes`] : []),
            ...(tcfTpl?.totalQuestions ? [`${tcfTpl.totalQuestions} questions`] : []),
            "Niveau CECRL",
        ]
        : [
            "Conditions réelles",
            `${CIVIQUE_EXAM_DUREE_MINUTES} minutes`,
            `Seuil ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`,
            `${CIVIQUE_EXAM_QUESTIONS} questions`,
        ];
    const heroCta: ActionCardCta | null = next
        ? {label: tcf ? examensTcfHeroCta(next) : EXAMENS_CIVIQUE_HERO_CTA, onClick: () => openIntro(active)}
        : null;

    return (
        <main className="ebh">
            <SejourApp className={sejourStyles.home}>
                <Pad>
                    <PageHead
                        kicker={tcf ? MODULE_TCF_KICKER : MODULE_CIVIQUE_KICKER}
                        tone={tone}
                        title={tcf ? EXAMENS_TCF_TITLE : EXAMENS_CIVIQUE_TITLE}
                        subtitle={tcf ? EXAMENS_TCF_SUBTITLE : EXAMENS_CIVIQUE_SUBTITLE}
                    />
                </Pad>

                <Pad>
                    <div className={sejourStyles.pageBody}>
                        {/* Un visiteur n'a pas la barre latérale : la bascule reste,
                            en LIENS (`?module=`), seule porte vers l'autre parcours. */}
                        <ModuleToggle active={active} hrefFor={(m) => `/examens-blancs?module=${m}`}/>
                        {error && <div className="ebh-error">{error}</div>}
                        <Hero
                            module={tone}
                            icon={tcf ? <IconTarget/> : <IconShield/>}
                            label={tcf ? EXAMENS_TCF_HERO_LABEL : EXAMENS_CIVIQUE_HERO_LABEL}
                            title={tcf ? EXAMENS_TCF_HERO_TITLE : EXAMENS_CIVIQUE_HERO_TITLE}
                            sub={slots > 0 ? examensGuestOffre(slots, ouverts) : null}
                            stat={heroStat}
                            cta={heroCta}
                        />
                        <ExamStats module={tone} tips={tips}/>
                    </div>
                </Pad>

                <Section title={tcf ? EXAMENS_LIST_TITLE : EXAMENS_CIVIQUE_LIST_TITLE}>
                    <Pad>
                        <ExamList
                            module={tone}
                            lines={lines}
                            loading={grid.loading}
                            error={grid.error}
                            onRetry={grid.reload}
                        />
                    </Pad>
                </Section>
            </SejourApp>

            {/* TCF : même modale qu'en connecté, mais EE/EO verrouillés (compte
                requis) et copie adaptée à la démo anonyme. */}
            <ExamIntroSheet
                open={introModule === "TCF"}
                eyebrow="Examen blanc · TCF IRN"
                title="TCF IRN — compréhension en conditions réelles"
                subtitle="Sans compte, vous passez les 2 épreuves de compréhension. L'expression écrite et orale demandent un compte."
                facts={[
                    ...(tcfTpl?.totalQuestions
                        ? [{label: "questions de compréhension", value: String(tcfTpl.totalQuestions)}]
                        : []),
                    ...(tcfMinutes ? [{label: "en conditions réelles", value: `${tcfMinutes} min`}] : []),
                    {label: "restitution", value: "Niveau CECRL", highlight: true},
                ]}
                epreuves={[
                    {
                        icon: EPREUVE_PRESENTATION.TCF_CO.icon,
                        label: EPREUVE_PRESENTATION.TCF_CO.label,
                        meta: `${EPREUVE_PRESENTATION.TCF_CO.volume} · ${plannedEpreuveLabel("TCF_CO")}`,
                    },
                    {
                        icon: EPREUVE_PRESENTATION.TCF_CE.icon,
                        label: EPREUVE_PRESENTATION.TCF_CE.label,
                        meta: `${EPREUVE_PRESENTATION.TCF_CE.volume} · ${plannedEpreuveLabel("TCF_CE")}`,
                    },
                    {
                        icon: EPREUVE_PRESENTATION.TCF_EE.icon,
                        label: EPREUVE_PRESENTATION.TCF_EE.label,
                        meta: EPREUVE_PRESENTATION.TCF_EE.volume,
                        locked: true,
                    },
                    {
                        icon: EPREUVE_PRESENTATION.TCF_EO.icon,
                        label: EPREUVE_PRESENTATION.TCF_EO.label,
                        meta: EPREUVE_PRESENTATION.TCF_EO.volume,
                        locked: true,
                    },
                ]}
                epreuvesLabel={`Les ${TCF_EPREUVES_OFFICIELLES.length} épreuves du TCF IRN`}
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

            {/* Civique : le format de l'arrêté (miroir gelé), comme en connecté. */}
            <ExamIntroSheet
                open={introModule === "CIVIQUE"}
                eyebrow="Examen blanc · Examen civique"
                title="Examen civique en conditions réelles"
                subtitle="Le premier examen est offert, sans compte. Vos résultats ne seront pas sauvegardés."
                facts={[
                    {label: "questions · toutes les catégories", value: String(CIVIQUE_EXAM_QUESTIONS)},
                    {label: "en conditions réelles", value: `${CIVIQUE_EXAM_DUREE_MINUTES} min`},
                    {label: "seuil de réussite", value: `${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`, highlight: true},
                ]}
                tips={[
                    "L'examen brasse toutes les catégories du programme civique.",
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
                message="Le 1ᵉʳ examen blanc de chaque parcours est offert. Les suivants font partie des pass : créez d'abord votre compte gratuit, qui conserve vos résultats."
            />

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// STYLES — blocs gardés (stats, puces) et mise en page du visiteur. Tokens
// seuls, aucune valeur hexadécimale.
// ============================================================================
const styles = `
  /* Visiteur : hors du shell connecté, la page porte sa propre gouttière. */
  .ebh {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 40px 80px;
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
  .ebh-note { margin: 0 0 12px; }
  .ebh-list { display: grid; gap: 10px; }

  /* ===== stats (meilleur / dernier / niveau ou maîtrise) ===== */
  .ebh-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 10px;
    margin-top: 16px;
  }
  .ebh-stat {
    display: flex;
    flex-direction: column;
    gap: 3px;
    background: var(--color-white);
    border: 1px solid var(--color-line);
    border-radius: var(--sf-radius-2xl);
    padding: 14px 16px;
    min-width: 0;
  }
  .ebh-stat-val {
    font-family: var(--font-sans);
    font-size: 20px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
    line-height: 1.1;
  }
  .ebh-stat-lbl {
    font-family: var(--font-mono);
    font-size: 11px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
    color: var(--color-muted);
  }
  /* Périmètre d'un niveau estimé partiel : une précision, pas une alerte. */
  .ebh-stat-hint {
    margin-top: 2px;
    font-size: 11px; font-weight: 500; line-height: 1.3;
    color: var(--color-muted-2);
    overflow-wrap: anywhere;
  }

  /* ===== puces de conditions ===== */
  .ebh-tips {
    display: flex; flex-wrap: wrap; gap: 8px;
    margin-top: 12px;
  }
  .ebh-tip {
    font-size: 12px; font-weight: 600;
    padding: 5px 11px; border-radius: 999px;
    white-space: nowrap;
    border: 1px solid transparent;
  }
  .ebh-tip-tcf {
    background: var(--color-module-tcf-light);
    color: var(--color-module-tcf-dark);
    border-color: color-mix(in srgb, var(--color-module-tcf) 18%, transparent);
  }
  .ebh-tip-civique {
    background: var(--color-module-civique-light);
    color: var(--color-module-civique-dark);
    border-color: color-mix(in srgb, var(--color-module-civique) 18%, transparent);
  }

  @media (max-width: 768px) {
    .ebh { padding: 20px 0 48px; }
    .ebh-stats { gap: 7px; }
    .ebh-stat { padding: 10px; }
    .ebh-stat-val { font-size: 17px; }
    .ebh-stat-lbl { font-size: 10px; }
    .ebh-stat-hint { font-size: 10.5px; }
  }
`;
