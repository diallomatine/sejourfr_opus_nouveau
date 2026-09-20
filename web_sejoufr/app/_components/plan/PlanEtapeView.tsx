"use client";

import {Suspense, useCallback, useState} from "react";
import {useParams, useRouter, useSearchParams} from "next/navigation";
import {journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {handleStartFailure} from "@/lib/start-failure";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {
    JOURNEY_ETAPE_ERROR,
    JOURNEY_ETAPE_LIST_TITLE,
    JOURNEY_ETAPE_LOADING,
    JOURNEY_ETAPE_LOCKED_NOTE,
    JOURNEY_ETAPE_PRIORITE,
    JOURNEY_ETAPE_RETRY,
    JOURNEY_ETAPE_SERIE_RESULT,
    JOURNEY_ETAPE_SEUIL_SUB,
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
    journeyEtapeSeuil,
    journeyEtapeTitle,
    journeyEtapeValidation,
} from "@/lib/journey-etape";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
    Card,
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
 * de `/sessions/{attemptId}`, celui des séries de « Réviser ». Aucun écran de
 * rapport n'est écrit ici.
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
                /* 🛑 **Le runner existant**, comme toute série ciblée : la
                   passation du web vit sur `/sessions/{id}`, et le retour du
                   candidat ramène **ici** — pas sur le Plan. */
                router.push(`/sessions/${attempt.id}`);
            } catch (cause) {
                handleStartFailure(cause, {
                    onPaywall: () => setPaywall(true),
                    onMessage: setErreur,
                    fallbackMessage: JOURNEY_ETAPE_START_ERROR,
                });
                setBusy(false);
            }
        },
        [busy, router, stepId],
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
                    <Section title={JOURNEY_ETAPE_LIST_TITLE} mono>
                        <Pad>
                            <Stack>
                                {detail.series.map((serie, rang) => (
                                    <Serie
                                        key={serie.index}
                                        serie={serie}
                                        detail={detail}
                                        /* 🛑 **La série précédente est celle
                                           que la LISTE SERVIE porte avant**,
                                           jamais `index - 1` : c'est l'ordre
                                           servi qui dit ce qui précède. */
                                        precedente={detail.series[rang - 1]?.index ?? null}
                                        busy={busy}
                                        onStart={lancer}
                                        onLocked={() => setPaywall(true)}
                                    />
                                ))}
                            </Stack>
                        </Pad>
                    </Section>

                    <Pad>
                        <Stack>
                            {erreur && (
                                <p className={sejourStyles.tiny} role="alert">{erreur}</p>
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

            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                /* 🛑 **Le pass suit le parcours** (A108) : une étape civique
                   s'ouvre avec le pass Civique, jamais l'Intégral. */
                module={parcours === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL"}
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
function Serie({serie, detail, precedente, busy, onStart, onLocked}: {
    serie: JourneySerieDto;
    detail: JourneyStepDetailDto;
    precedente: number | null;
    busy: boolean;
    onStart: (index: number) => void;
    /** L'offre, quand c'est l'**étape** qui est fermée. */
    onLocked: () => void;
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
            action={{
                label: journeyEtapeSerieCta(serie, precedente),
                disabled: ferme || busy,
                onClick: ferme
                    ? undefined
                    : detail.locked
                        ? onLocked
                        : () => onStart(serie.index),
            }}
            /* 🛑 **Le corrigé passe par le chemin EXISTANT** — le rapport des
               séries de « Réviser ». `?lot=` est ce qui le fait rendre un
               rapport de série plutôt qu'une carte de score d'entraînement. */
            link={
                serie.dernierAttemptId
                    ? {
                        label: JOURNEY_ETAPE_SERIE_RESULT,
                        href: `/sessions/${serie.dernierAttemptId}?lot=${serie.index}`,
                    }
                    : undefined
            }
        />
    );
}
