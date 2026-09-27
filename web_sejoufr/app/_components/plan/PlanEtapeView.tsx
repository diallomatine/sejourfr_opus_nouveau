"use client";

import {Suspense, useCallback, useState} from "react";
import {useParams, useRouter, useSearchParams} from "next/navigation";
import {journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {handleStartFailure} from "@/lib/start-failure";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {journeyEtapeHref} from "@/lib/journey";
import {sessionHref} from "@/lib/retour";
import {
    JOURNEY_ETAPE_DONE_CTA,
    JOURNEY_ETAPE_DONE_LEAD,
    JOURNEY_ETAPE_DONE_SUB,
    JOURNEY_ETAPE_DONE_TITLE,
    JOURNEY_ETAPE_ERROR,
    JOURNEY_ETAPE_LIST_TITLE,
    JOURNEY_ETAPE_LOADING,
    JOURNEY_ETAPE_LOCKED_NOTE,
    JOURNEY_ETAPE_PRIORITE,
    JOURNEY_ETAPE_RETRY,
    JOURNEY_ETAPE_SERIE_RESULT,
    JOURNEY_ETAPE_SEUIL_SUB,
    JOURNEY_ETAPE_SHEET_REDO,
    JOURNEY_ETAPE_START_ERROR,
    JOURNEY_ETAPE_VALIDATION_LEAD,
    journeyEtapeCompteur,
    journeyEtapeDernierScore,
    journeyEtapeDuree,
    journeyEtapeFoot,
    journeyEtapeObjectif,
    journeyEtapeQuestions,
    journeyEtapeSectionPill,
    journeyEtapeSerieCta,
    journeyEtapeSerieMark,
    journeyEtapeSerieState,
    journeyEtapeSerieTitle,
    journeyEtapeSerieVerdict,
    journeyEtapeSeuil,
    journeyEtapeTitle,
    journeyEtapeValidation,
} from "@/lib/journey-etape";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ExamDoneSheet} from "@/app/_components/hub/ExamDoneSheet";
import {usePlanJourneyId} from "./use-plan-journey-id";
import {
    Card,
    Cta,
    DoneRow,
    InfoNote,
    Pad,
    PanelHead,
    Pill,
    Pills,
    SejourApp,
    Section,
    SerieCard,
    SerieProgress,
    Stack,
    Top,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import type {JourneySerieDto, JourneyStepDetailDto} from "@/lib/types";

/**
 * **Le détail d'une étape de séries** — l'écran intermédiaire du Plan
 * (demande du propriétaire, 2026-09-20).
 *
 * Le cycle du Plan **n'ouvre plus une série** sur une étape d'entraînement de
 * compréhension (CO/CE) ni sur une étape civique : il ouvre **cet écran-ci**,
 * qui dit ce que l'étape demande — la compétence ou l'unité travaillée, son
 * avancement, le seuil à tenir — puis propose ses séries une par une.
 *
 * 🛑 **Rien n'est décidé ici.** Le quota, le nombre de questions, le **seuil de
 * réussite**, la durée estimée, l'ordre des séries, leur verrou (`locked`) et
 * leur validation (`validee`) sont **servis**
 * (`GET /api/me/plan/journey/steps/{stepId}`). Les phrases viennent de
 * `lib/journey-etape.ts`, miroir de `journey_etape_labels.dart`.
 *
 * 🛑 **`dernierScore` n'est JAMAIS comparé à `seuilReussite`.** L'état d'une
 * série se lit sur `locked` et `validee` ; le score est affiché, pas jugé. Un
 * front qui classerait ce nombre deviendrait une seconde autorité sur « cette
 * série est-elle réussie ? » — exactement ce que le dépôt interdit.
 *
 * 🛑 **Une étape verrouillée garde son écran ENTIER** (R16, D-18) : le
 * candidat lit ce qu'il y a à faire, seul le **geste** est fermé et il ouvre
 * l'offre. On floute l'action, jamais le résultat.
 *
 * 🛑 **Le corrigé d'une série jouée réutilise le chemin existant** — le rapport
 * de série de `/sessions/{attemptId}`, celui des séries hors Plan. Aucun écran
 * de rapport n'est écrit ici : le lancement ET « Voir mon résultat » posent
 * `?retour=` sur cet écran (`sessionHref`), et c'est ce paramètre qui fait
 * rendre le rapport complet, bouton « Continuer » qui revient ici.
 *
 * 🛑 **Une série JOUÉE se lit d'un coup d'œil** (2026-09-27) : carte compacte
 * à coche verte (réussie) ou croix rouge (ratée), rangée sous « Réussies » ou
 * « À faire ». Son toucher ouvre la feuille des séries d'entraînement
 * (`ExamDoneSheet`) : « Voir mon résultat » puis « Refaire la série ». Seule
 * une série jamais jouée garde le gros bouton « Commencer ».
 *
 * 🛑 **Étape franchie = `detail.validee`, SERVI** : « Étape validée » et
 * « Continuer mon plan » (retour au cycle, `planHref`). Jamais
 * `validees >= quota` recompté ici.
 *
 * 🛑 **Miroir de `PlanEtapeScreen` côté mobile**, brique pour brique.
 */
export function PlanEtapeView() {
    /* `useSearchParams` impose une frontière de Suspense : elle est posée ici,
       autour du seul composant qui en a besoin. */
    return (
        <Suspense fallback={null}>
            <PlanEtapeScoped />
        </Suspense>
    );
}

function PlanEtapeScoped() {
    const {status} = useAuth();
    const params = useParams<{stepId: string}>();
    const stepId = typeof params?.stepId === "string" ? params.stepId : null;
    /* 🛑 **Le défaut est TCF**, pas une déduction : l'écran est atteint depuis
       le cycle, qui a déjà fait le choix et le porte dans son lien. Le module ne
       sert qu'à savoir où le retour remonte et quel pass l'offre présente. */
    /* ⚠️ Pas `module` : Next interdit d'affecter cette variable. */
    const parcours: ParcoursModule = moduleDeLUrl(useSearchParams()) ?? "TCF";
    const journeyId = usePlanJourneyId(parcours);
    /* L'adresse de CET écran, reposée en `?retour=` sur la session : c'est ce
       qui y ramène le candidat à la fin de sa série. */
    const ici = stepId ? journeyEtapeHref(stepId, parcours) : null;

    const query = useCachedData<JourneyStepDetailDto>(
        status === "authenticated" && stepId ? journeyApi.stepCacheKeyFor(stepId) : null,
        () => journeyApi.stepDetail(stepId!),
        {errorMessage: JOURNEY_ETAPE_ERROR},
    );
    const detail = query.data;

    const router = useRouter();
    const [busy, setBusy] = useState(false);
    const [erreur, setErreur] = useState<string | null>(null);
    const [paywall, setPaywall] = useState(false);
    /** La série jouée dont la feuille « corrigé / refaire » est ouverte. */
    const [ouverte, setOuverte] = useState<JourneySerieDto | null>(null);

    /**
     * **Lancer une série.**
     *
     * 🛑 **L'index est SERVI**, on le repasse tel quel. Le **403** n'est pas
     * une panne : c'est le verrou que le serveur oppose, et il ouvre l'offre —
     * jamais un message technique (`handleStartFailure`).
     */
    const lancer = useCallback(
        async (index: number) => {
            if (!stepId || busy) return;
            setErreur(null);
            setBusy(true);
            try {
                const attempt = await journeyApi.startSerie(stepId, index);
                /* 🛑 **Le runner existant**, comme toute série : la passation
                   du web vit sur `/sessions/{id}`, et `?retour=` y fait rendre
                   le rapport de série complet, dont « Continuer » ramène
                   **ici** — pas sur le Plan, pas sur l'Accueil. */
                router.push(sessionHref(attempt.id, ici, index));
            } catch (cause) {
                handleStartFailure(cause, {
                    onPaywall: () => setPaywall(true),
                    onMessage: setErreur,
                    fallbackMessage: JOURNEY_ETAPE_START_ERROR,
                });
                setBusy(false);
            }
        },
        [busy, ici, router, stepId],
    );

    const sectionPill = detail
        ? journeyEtapeSectionPill(detail.section, detail.objectif)
        : null;

    return (
        /* Un écran de **lecture** : colonne de 720 px, `<SejourApp>` nu. Il
           n'a ni grille ni barre d'action collée. */
        <SejourApp>
            <Top
                backTo={planHref(parcours)}
                title={journeyEtapeTitle(detail)}
                lead={detail ? journeyEtapeObjectif(detail.objectif) ?? undefined : undefined}
            />
            <Pad>
                <Stack>
                    {query.loading ? (
                        <Card>
                            <p className={sejourStyles.tiny}>{JOURNEY_ETAPE_LOADING}</p>
                        </Card>
                    ) : query.error || !detail ? (
                        /* 🛑 **Un échec se DIT** : sans ce bloc, une panne
                           réseau se lirait « aucune série », c'est-à-dire un
                           mensonge sur ce qu'il reste à faire. */
                        <Card>
                            <p className={sejourStyles.tiny} role="alert">
                                {query.error ?? JOURNEY_ETAPE_ERROR}
                            </p>
                            <button
                                type="button"
                                className={sejourStyles.link}
                                onClick={query.reload}
                            >
                                {JOURNEY_ETAPE_RETRY}
                            </button>
                        </Card>
                    ) : (
                        <>
                            {(sectionPill || detail.priorite) && (
                                <Pills>
                                    {sectionPill ? (
                                        <Pill label={sectionPill} tone="now" />
                                    ) : null}
                                    {/* 🛑 **`priorite` est SERVI** : aucune
                                        position, aucun rang ne le remplace. */}
                                    {detail.priorite ? (
                                        <Pill label={JOURNEY_ETAPE_PRIORITE} tone="hot" />
                                    ) : null}
                                </Pills>
                            )}

                            <PanelHead
                                lead
                                title={detail.unite.label}
                                sub={detail.unite.description}
                            />

                            {/* 🛑 **`validees` est SERVI** : c'est le compteur
                                du moteur, celui qui clôt l'étape. Le recompter
                                depuis `series` aurait fait deux additions de la
                                même chose. */}
                            <SerieProgress
                                count={journeyEtapeCompteur(
                                    detail.validees, detail.quota)}
                                note={journeyEtapeSeuil(
                                    detail.seuilReussite, detail.questionsParSerie)}
                                noteSub={JOURNEY_ETAPE_SEUIL_SUB}
                                done={detail.validees}
                                total={detail.quota}
                            />
                        </>
                    )}
                </Stack>
            </Pad>

            {detail && (
                <>
                    {/* 🛑 **« À faire » ne coiffe jamais une série réussie** :
                        le partage se lit sur `validee`, servi, et chaque liste
                        garde l'ordre servi. Une liste vide n'a pas d'intertitre. */}
                    {[
                        {titre: JOURNEY_ETAPE_LIST_TITLE, reussies: false},
                        {titre: JOURNEY_ETAPE_DONE_TITLE, reussies: true},
                    ].map(({titre, reussies}) => {
                        const liste = detail.series.filter((serie) => serie.validee === reussies);
                        if (liste.length === 0) return null;
                        return (
                            <Section key={titre} title={titre} mono>
                                <Pad>
                                    <Stack>
                                        {liste.map((serie) => (
                                            <Serie
                                                key={serie.index}
                                                serie={serie}
                                                detail={detail}
                                                /* 🛑 **La série précédente est
                                                   celle que la LISTE SERVIE
                                                   porte avant**, jamais
                                                   `index - 1` — et la liste
                                                   ENTIÈRE, pas la section. */
                                                precedente={precedenteDe(detail, serie)}
                                                busy={busy}
                                                retour={ici}
                                                onStart={lancer}
                                                onLocked={() => setPaywall(true)}
                                                onOpen={() => setOuverte(serie)}
                                            />
                                        ))}
                                    </Stack>
                                </Pad>
                            </Section>
                        );
                    })}

                    <Pad>
                        <Stack>
                            {erreur && (
                                <p className={sejourStyles.tiny} role="alert">{erreur}</p>
                            )}

                            {/* 🛑 **`validee` de l'ÉTAPE est SERVI** : c'est la
                                fonction qui la clôt qui le rend. Le bouton
                                ramène au cycle du Plan, qui sert l'étape
                                suivante. */}
                            {detail.validee && (
                                <Card variant="ok">
                                    <DoneRow label={JOURNEY_ETAPE_DONE_LEAD} />
                                    <p className={sejourStyles.tiny}>{JOURNEY_ETAPE_DONE_SUB}</p>
                                </Card>
                            )}
                            {detail.validee && (
                                <Cta href={planHref(parcours)} variant="blue">
                                    {JOURNEY_ETAPE_DONE_CTA}
                                </Cta>
                            )}

                            <InfoNote variant="check">
                                <b>{JOURNEY_ETAPE_VALIDATION_LEAD}</b>
                                {journeyEtapeValidation(
                                    detail.quota,
                                    detail.seuilReussite,
                                    detail.questionsParSerie,
                                )}
                            </InfoNote>

                            {/* 🛑 **Le verrou se DIT, il ne masque rien** : la
                                liste reste entière au-dessus. */}
                            {detail.locked && (
                                <p className={sejourStyles.tiny}>{JOURNEY_ETAPE_LOCKED_NOTE}</p>
                            )}

                            {/* 🛑 **En compréhension ORALE seulement**, sur le
                                `section` servi — jamais déduit d'une route. */}
                            {journeyEtapeFoot(detail.section) && (
                                <p className={sejourStyles.tiny}>
                                    {journeyEtapeFoot(detail.section)}
                                </p>
                            )}
                        </Stack>
                    </Pad>
                </>
            )}

            {/* 🛑 **La feuille des séries d'entraînement**, réutilisée telle
                quelle : le corrigé par le chemin EXISTANT (`?retour=` compris),
                refaire par le même lancement que la carte — ou l'offre, si
                l'étape est fermée. */}
            <ExamDoneSheet
                open={ouverte !== null}
                title={ouverte ? journeyEtapeSerieTitle(ouverte.index) : ""}
                subtitle={
                    ouverte && detail
                        ? journeyEtapeDernierScore(ouverte.dernierScore, detail.questionsParSerie)
                        : null
                }
                detailLabel={JOURNEY_ETAPE_SERIE_RESULT}
                resumeLabel={JOURNEY_ETAPE_SHEET_REDO}
                resumeTone="blue"
                onViewDetail={() => {
                    const serie = ouverte;
                    setOuverte(null);
                    if (serie?.dernierAttemptId) {
                        router.push(sessionHref(serie.dernierAttemptId, ici, serie.index));
                    }
                }}
                onResume={() => {
                    const serie = ouverte;
                    setOuverte(null);
                    if (!serie || !detail) return;
                    if (detail.locked) setPaywall(true);
                    else void lancer(serie.index);
                }}
                onClose={() => setOuverte(null)}
            />

            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                /* 🛑 **Le pass suit le parcours** (A108) : une étape civique
                   s'ouvre avec le pass Civique, jamais l'Intégral. */
                module={parcours === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL"}
                journeyId={journeyId}
                open={paywall}
                onClose={() => {
                    setPaywall(false);
                    setBusy(false);
                }}
            />
        </SejourApp>
    );
}

/**
 * Une carte de série.
 *
 * 🛑 **Le geste se décide sur `locked` (celui de la série ET celui de
 * l'étape)** : une série ouverte d'une étape verrouillée reste lisible, mais
 * son bouton ouvre l'offre au lieu de lancer — et c'est le serveur qui aurait
 * répondu 403 de toute façon. Une seule règle, deux endroits d'application.
 */
function Serie({serie, detail, precedente, busy, retour, onStart, onLocked, onOpen}: {
    serie: JourneySerieDto;
    detail: JourneyStepDetailDto;
    precedente: number | null;
    busy: boolean;
    /** L'adresse de l'écran d'étape, où « Continuer » du rapport ramène. */
    retour: string | null;
    onStart: (index: number) => void;
    /** L'offre, quand c'est l'**étape** qui est fermée. */
    onLocked: () => void;
    /** La feuille « corrigé / refaire » d'une série jouée. */
    onOpen: () => void;
}) {
    /* 🛑 **Deux verrous, deux lectures.** Celui de la SÉRIE est pédagogique
       (« la précédente n'est pas réussie ») : le bouton devient gris et porte
       la condition. Celui de l'ÉTAPE est commercial : le bouton reste vivant,
       et il ouvre l'offre — la même que le 403 que le serveur opposerait. */
    const ferme = serie.locked;
    return (
        <SerieCard
            mark={journeyEtapeSerieMark(serie.index)}
            title={journeyEtapeSerieTitle(serie.index)}
            duree={journeyEtapeDuree(detail.dureeEstimeeMin)}
            questions={journeyEtapeQuestions(detail.questionsParSerie)}
            state={journeyEtapeSerieState(serie)}
            score={journeyEtapeDernierScore(serie.dernierScore, detail.questionsParSerie)}
            locked={ferme}
            /* 🛑 **Jouée et jugée ⇒ compacte** : la carte ne porte plus
               « Refaire », la feuille s'en charge. */
            verdict={journeyEtapeSerieVerdict(serie)}
            onOpen={onOpen}
            action={{
                label: journeyEtapeSerieCta(serie, precedente),
                disabled: ferme || busy,
                onClick: ferme
                    ? undefined
                    : detail.locked
                        ? onLocked
                        : () => onStart(serie.index),
            }}
            /* 🛑 **Jouée sans score** (session non terminée) : ni verdict ni
               feuille, le bouton « Refaire la série » reste sur la carte et le
               corrigé en lien, par le chemin EXISTANT (`?retour=` compris). */
            link={
                serie.dernierAttemptId
                    ? {
                        label: JOURNEY_ETAPE_SERIE_RESULT,
                        href: sessionHref(serie.dernierAttemptId, retour, serie.index),
                    }
                    : undefined
            }
        />
    );
}

/** L'index de la série que la liste SERVIE porte juste avant, ou `null`. */
function precedenteDe(detail: JourneyStepDetailDto, serie: JourneySerieDto): number | null {
    const rang = detail.series.findIndex((s) => s.index === serie.index);
    return rang > 0 ? detail.series[rang - 1].index : null;
}
