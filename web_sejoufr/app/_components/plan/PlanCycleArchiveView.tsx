"use client";

import {Suspense, useState} from "react";
import {useParams, useSearchParams} from "next/navigation";
import {journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {moduleDeLUrl, type ParcoursModule} from "@/lib/module-switch";
import {
    JOURNEY_ARCHIVE_ERROR,
    JOURNEY_ARCHIVE_KICKER,
    JOURNEY_ARCHIVE_NOTE,
    JOURNEY_EXAM_TITLE,
    JOURNEY_HISTORY_LOADING,
    JOURNEY_HISTORY_RETRY,
    JOURNEY_RAIL_END_EYEBROW,
    journeyArchiveEndNote,
    journeyArchiveEndTitle,
    journeyArchiveExamResult,
    journeyArchiveExamSubtitle,
    journeyArchiveHint,
    journeyBadge,
    journeyBlocMark,
    journeyBlocRailState,
    journeyBlocStatus,
    journeyBlocTitle,
    journeyCycleLabel,
    journeyCycleStepSubtitle,
    journeyCycleStepTitle,
    journeyHistoryCycleTitle,
    journeyHistoryDates,
    journeyHistoryHref,
    journeyKind,
    journeyKitState,
    journeyTitle,
} from "@/lib/journey";
import type {JourneyBlocDto, JourneyCycleArchiveDto} from "@/lib/types";
import {
    BlocAccordion,
    Card,
    CycleProgress,
    CycleRail,
    CycleRailEnd,
    CycleRailStep,
    ExamStepAction,
    InfoNote,
    JourneyList,
    JourneyRow,
    Pad,
    SejourApp,
    Section,
    Stack,
    Top,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";

/**
 * **Un cycle terminé, consulté tel qu'il était** — la page ouverte depuis
 * « Mes cycles » (`/plan/progression/cycle/{journeyId}`, 2026-09-27).
 *
 * 🛑 **Le MÊME écran que le cycle du Plan, en lecture seule.** Mêmes briques
 * du kit — `CycleProgress`, `CycleRail` / `CycleRailStep` / `CycleRailEnd`,
 * `BlocAccordion`, `JourneyList` / `JourneyRow`, `ExamStepAction` —, les mêmes
 * libellés (`lib/journey.ts`) sur les mêmes DTO (`JourneyCycleArchiveDto` porte
 * le `cycle` et les `blocs` du Plan). Ce qui fait la consultation est SERVI :
 * aucune étape verrouillée, aucune action, une étape restée ouverte
 * `NON_FAITE`, un bloc incomplet `INACHEVE`. L'écran ne pose donc **aucun**
 * geste — ni « Commencer », ni « Débloquer », ni « Faire cette étape » — et
 * aucun cadenas.
 *
 * 🛑 **La fin du cycle est FRANCHIE** (`CycleRailEnd done`) : son titre est le
 * geste qui l'a clos, servi (`finDeCycle`, V077) ; inconnu ⇒ « Cycle
 * terminé ».
 *
 * 🛑 **Miroir de `PlanCycleArchiveScreen` côté mobile**, brique pour brique.
 */
export function PlanCycleArchiveView() {
    /* `useSearchParams` impose une frontière de Suspense : elle est posée ici,
       autour du seul composant qui en a besoin. */
    return (
        <Suspense fallback={null}>
            <PlanCycleArchiveScoped />
        </Suspense>
    );
}

function PlanCycleArchiveScoped() {
    const {status} = useAuth();
    const params = useParams<{journeyId: string}>();
    const journeyId = typeof params?.journeyId === "string" ? params.journeyId : null;
    /* Le module ne sert qu'au MOT de la mesure et au retour : le cycle porte le
       sien côté serveur. ⚠️ Pas `module` : Next interdit d'affecter cette
       variable. */
    const parcours: ParcoursModule = moduleDeLUrl(useSearchParams()) ?? "TCF";

    const query = useCachedData<JourneyCycleArchiveDto>(
        status === "authenticated" && journeyId
            ? journeyApi.historyCycleCacheKey(journeyId)
            : null,
        () => journeyApi.historyCycle(journeyId!),
        {errorMessage: JOURNEY_ARCHIVE_ERROR},
    );
    const archive = query.data;
    const retour = journeyHistoryHref(parcours);

    return (
        <SejourApp>
            <Top
                kicker={JOURNEY_ARCHIVE_KICKER}
                title={archive ? journeyHistoryCycleTitle(archive.numero) : JOURNEY_ARCHIVE_KICKER}
                lead={archive ? journeyHistoryDates(archive.debut, archive.fin) : undefined}
                backTo={retour}
                keepMenu
            />
            {query.loading && !archive ? (
                <Pad>
                    <Card>
                        <p className={sejourStyles.tiny}>{JOURNEY_HISTORY_LOADING}</p>
                    </Card>
                </Pad>
            ) : !archive ? (
                /* 🛑 **Un échec se DIT** — y compris le 404 d'un cycle qui n'est
                   pas le sien : jamais un écran vide. */
                <Pad>
                    <Card>
                        <p className={sejourStyles.tiny} role="alert">
                            {query.error ?? JOURNEY_ARCHIVE_ERROR}
                        </p>
                        <button type="button" className={sejourStyles.link} onClick={query.reload}>
                            {JOURNEY_HISTORY_RETRY}
                        </button>
                    </Card>
                </Pad>
            ) : (
                <ArchiveBody archive={archive} module={parcours} />
            )}
        </SejourApp>
    );
}

/**
 * Le cycle lui-même. 🛑 **Le premier bloc est déplié**, les autres repliés : on
 * vient consulter ce qui a été fait, et le premier bloc servi est le premier de
 * l'ordre des épreuves. Le seul état tenu ici est ce dépli.
 */
function ArchiveBody({archive, module}: {archive: JourneyCycleArchiveDto; module: ParcoursModule}) {
    const [choix, setChoix] = useState<{key: string | null} | null>(null);
    const ouvert = choix ? choix.key : archive.blocs[0]?.bloc.code ?? null;
    const cycle = archive.cycle;

    return (
        <Section title={journeyTitle(archive.objectif)}>
            <Pad>
                <Stack>
                    <CycleProgress
                        label={journeyCycleLabel(cycle)}
                        done={cycle.etapesTerminees}
                        total={cycle.etapesTotal}
                        hint={journeyArchiveHint(archive, module)}
                        /* 🛑 Servi, jamais déduit de `done === total`. */
                        complete={cycle.complete}
                    />

                    <CycleRail>
                        {archive.blocs.map((bloc) => (
                            <CycleRailStep key={bloc.bloc.code} state={journeyBlocRailState(bloc.status)}>
                                <BlocAccordion
                                    mark={journeyBlocMark(bloc.bloc)}
                                    title={journeyBlocTitle(bloc.bloc)}
                                    meta={bloc.meta}
                                    status={journeyBlocStatus(bloc.status)}
                                    open={ouvert === bloc.bloc.code}
                                    onToggle={() =>
                                        setChoix({key: ouvert === bloc.bloc.code ? null : bloc.bloc.code})
                                    }
                                >
                                    <ArchiveBloc bloc={bloc} />
                                </BlocAccordion>
                            </CycleRailStep>
                        ))}
                        <CycleRailEnd
                            eyebrow={JOURNEY_RAIL_END_EYEBROW}
                            title={journeyArchiveEndTitle(archive.finDeCycle)}
                            note={journeyArchiveEndNote(archive.fin)}
                            reached={false}
                            done
                        />
                    </CycleRail>

                    <InfoNote>{JOURNEY_ARCHIVE_NOTE}</InfoNote>
                </Stack>
            </Pad>
        </Section>
    );
}

/**
 * Le corps d'un bloc clos : ses étapes, puis son examen. 🛑 **Aucun geste** —
 * ni `onClick`, ni `actionLabel`, ni `locked` : les états sont lus, jamais
 * actionnés.
 */
function ArchiveBloc({bloc}: {bloc: JourneyBlocDto}) {
    const exam = bloc.exam;
    const resultat = exam ? journeyArchiveExamResult(exam) : undefined;
    return (
        <JourneyList
            variant="cycle"
            exam={
                exam && (
                    <ExamStepAction
                        title={JOURNEY_EXAM_TITLE}
                        subtitle={journeyArchiveExamSubtitle(exam)}
                        trailing={resultat ? {kind: "done", label: resultat} : undefined}
                    />
                )
            }
        >
            {bloc.steps.map((step) => (
                <JourneyRow
                    key={step.id}
                    title={journeyCycleStepTitle(step, null)}
                    subtitle={journeyCycleStepSubtitle(step)}
                    state={journeyKitState(step)}
                    kind={journeyKind(step)}
                    badge={journeyBadge(step)}
                />
            ))}
        </JourneyList>
    );
}
