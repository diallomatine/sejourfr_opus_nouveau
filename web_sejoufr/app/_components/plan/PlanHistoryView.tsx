"use client";

import {useState} from "react";
import {journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {
    BlocAccordion,
    Card,
    ExamStepBox,
    HeroBanner,
    InfoNote,
    JourneyList,
    JourneyRow,
    Pad,
    PanelHead,
    SejourApp,
    Stack,
    StatGrid,
    Top,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
    JOURNEY_HISTORY_DONE_PILL,
    JOURNEY_HISTORY_EMPTY_TEXT,
    JOURNEY_HISTORY_EMPTY_TITLE,
    JOURNEY_HISTORY_ERROR,
    JOURNEY_HISTORY_EYEBROW,
    JOURNEY_HISTORY_FOOT_LEAD,
    JOURNEY_HISTORY_FOOT_TEXT,
    JOURNEY_HISTORY_HEADLINE,
    JOURNEY_HISTORY_LEAD,
    JOURNEY_HISTORY_LOADING,
    JOURNEY_HISTORY_RETRY,
    JOURNEY_HISTORY_SECTION_SUB,
    JOURNEY_HISTORY_SECTION_TITLE,
    JOURNEY_HISTORY_TITLE,
    journeyHistoryBlocSkills,
    journeyHistoryCycleMark,
    journeyHistoryCycleMeta,
    journeyHistoryCycleTitle,
    journeyHistoryLevelNote,
    journeyHistoryLevelState,
    journeyHistoryLevelTitle,
    journeyHistoryStatCycles,
    journeyHistoryStatExams,
    journeyHistoryStatSkills,
    journeyHistoryBlocTitle,
} from "@/lib/journey";
import type {JourneyHistoryCycleDto, JourneyHistoryDto} from "@/lib/types";

/**
 * **« Ma progression »** — l'archive du parcours, derrière « Voir ma
 * progression » au bas du Plan.
 *
 * Maquette du propriétaire : `docs/progression/histo_cycle.html`.
 *
 * 🛑 **Rien n'est calculé ici.** Les trois compteurs, les cycles, leur ordre,
 * les titres de compétence et les deux niveaux sont **servis**
 * (`GET /api/me/plan/journey/history`) ; les phrases viennent de
 * `lib/journey.ts`, et les dates de son seul formateur d'intervalle.
 *
 * 🛑 **Ce n'est plus l'écran des quatre domaines.** Il montrait « où j'en suis
 * sur les quatre domaines », qui est déjà ce que le Plan et l'Accueil disent ;
 * il montre maintenant ce que le Plan ne peut pas dire : **ce qui a été
 * travaillé avant**. `/plan/evolution` (« ce qui a changé ») a disparu dans la
 * même passe, pour la même raison — le Plan porte déjà « Progression
 * détectée ».
 *
 * 🛑 **Miroir de `PlanHistoryScreen` côté mobile**, brique pour brique.
 */
export function PlanHistoryView() {
    const {status} = useAuth();
    const query = useCachedData<JourneyHistoryDto>(
        status === "authenticated" ? journeyApi.historyCacheKey : null,
        () => journeyApi.history(),
        {errorMessage: JOURNEY_HISTORY_ERROR},
    );
    const history = query.data;

    /**
     * Le cycle déplié. 🛑 **Un seul à la fois, le plus récent par défaut** — et
     * c'est le `numero` servi qui l'identifie, jamais un index de liste : une
     * liste rechargée pendant qu'on lit ne doit pas rouvrir un autre cycle.
     */
    const [ouvert, setOuvert] = useState<number | null>(null);
    const premier = history?.cycles[0]?.numero ?? null;
    const deplie = ouvert ?? premier;

    return (
        <SejourApp>
            <Top title={JOURNEY_HISTORY_TITLE} backTo="/plan" />
            <Pad>
                <Stack>
                    {/* 🛑 Le bandeau et ses compteurs restent dans TOUS les
                        états : ils sont vrais même sans cycle terminé. */}
                    <HeroBanner
                        eyebrow={JOURNEY_HISTORY_EYEBROW}
                        title={JOURNEY_HISTORY_HEADLINE}
                        text={JOURNEY_HISTORY_LEAD}
                    >
                        <StatGrid
                            onHero
                            accentIndex={1}
                            stats={[
                                {
                                    value: String(history?.stats.competencesTravaillees ?? 0),
                                    label: journeyHistoryStatSkills(
                                        history?.stats.competencesTravaillees ?? 0),
                                },
                                {
                                    value: String(history?.stats.examensPasses ?? 0),
                                    label: journeyHistoryStatExams(
                                        history?.stats.examensPasses ?? 0),
                                },
                                {
                                    value: String(history?.stats.cyclesTermines ?? 0),
                                    label: journeyHistoryStatCycles(
                                        history?.stats.cyclesTermines ?? 0),
                                },
                            ]}
                        />
                    </HeroBanner>

                    {query.loading ? (
                        <Card>
                            <p className={sejourStyles.tiny}>{JOURNEY_HISTORY_LOADING}</p>
                        </Card>
                    ) : query.error ? (
                        /* 🛑 **Un échec se DIT** : sans ce bloc, une panne
                           réseau se lirait « aucun cycle terminé », c'est-à-dire
                           un mensonge sur l'archive du candidat. */
                        <Card>
                            <p className={sejourStyles.tiny} role="alert">{query.error}</p>
                            <button
                                type="button"
                                className={sejourStyles.link}
                                onClick={query.reload}
                            >
                                {JOURNEY_HISTORY_RETRY}
                            </button>
                        </Card>
                    ) : !history || history.cycles.length === 0 ? (
                        <Card>
                            <PanelHead
                                title={JOURNEY_HISTORY_EMPTY_TITLE}
                                sub={JOURNEY_HISTORY_EMPTY_TEXT}
                            />
                        </Card>
                    ) : (
                        <>
                            <PanelHead
                                title={JOURNEY_HISTORY_SECTION_TITLE}
                                sub={JOURNEY_HISTORY_SECTION_SUB}
                            />
                            <Stack>
                                {history.cycles.map((cycle) => (
                                    <CycleTermine
                                        key={cycle.numero}
                                        cycle={cycle}
                                        open={deplie === cycle.numero}
                                        onToggle={() => setOuvert(
                                            deplie === cycle.numero ? -1 : cycle.numero)}
                                    />
                                ))}
                            </Stack>
                        </>
                    )}

                    <InfoNote>
                        <b>{JOURNEY_HISTORY_FOOT_LEAD}</b>
                        {JOURNEY_HISTORY_FOOT_TEXT}
                    </InfoNote>
                </Stack>
            </Pad>
        </SejourApp>
    );
}

/**
 * Un cycle archivé : ses épreuves travaillées, puis son encart de niveau.
 *
 * 🛑 **`BlocAccordion` est réutilisé tel quel** : son `mark` est un texte, et
 * le numéro du cycle y entre sans qu'un second accordéon soit écrit.
 *
 * 🛑 **Aucune action** : un cycle historisé ne se rejoue pas. Les lignes n'ont
 * donc pas d'`onClick`, et l'encart de niveau est `locked` — c'est-à-dire
 * inerte, mais entièrement lisible.
 */
function CycleTermine({cycle, open, onToggle}: {
    cycle: JourneyHistoryCycleDto;
    open: boolean;
    onToggle: () => void;
}) {
    return (
        <BlocAccordion
            mark={journeyHistoryCycleMark(cycle.numero)}
            title={journeyHistoryCycleTitle(cycle.numero)}
            meta={journeyHistoryCycleMeta(cycle)}
            status={{label: JOURNEY_HISTORY_DONE_PILL, tone: "ok"}}
            open={open}
            onToggle={onToggle}
        >
            {/* 🛑 Une épreuve sans compétence travaillée garde sa ligne : elle a
                reçu un examen, et l'omettre effacerait ce qui y a été mesuré.

                Le corps d'un cycle archivé prend la **même** variante que celui
                du cycle en cours : c'est le même bloc, et deux corps différents
                sous le même en-tête se liraient comme deux écrans. Les lignes y
                sont toutes `done` — coche verte, aucune ligne d'action — et
                l'encart de niveau ferme le rail avec sa pastille « ◎ ». */}
            <JourneyList
                variant="cycle"
                exam={
                    <ExamStepBox
                        title={journeyHistoryLevelTitle(cycle)}
                        state={journeyHistoryLevelState(cycle)}
                        note={journeyHistoryLevelNote(cycle)}
                        locked
                    />
                }
            >
                {cycle.blocs.map((bloc) => (
                    <JourneyRow
                        key={bloc.bloc.code}
                        state="done"
                        title={journeyHistoryBlocTitle(bloc)}
                        subtitle={journeyHistoryBlocSkills(bloc)}
                    />
                ))}
            </JourneyList>
        </BlocAccordion>
    );
}
