"use client";

import {useCallback, useState} from "react";
import {useRouter} from "next/navigation";
import {fullTcfExamApi, journeyApi} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";
import {planStepAction} from "@/lib/plan-domain";
import {
    JOURNEY_CYCLE_NOTE,
    JOURNEY_LOCKED_CAPTION,
    JOURNEY_NEEDS_OBJECTIVE_CTA,
    JOURNEY_NEEDS_OBJECTIVE_TEXT,
    JOURNEY_NEEDS_OBJECTIVE_TITLE,
    JOURNEY_NEXT_STEP_BUSY,
    JOURNEY_NEXT_STEP_ERROR,
    JOURNEY_NEXT_STEP_EXAM_CTA,
    JOURNEY_NEXT_STEP_EYEBROW,
    JOURNEY_NEXT_STEP_FACTS,
    JOURNEY_NEXT_STEP_HEADLINE,
    JOURNEY_NEXT_STEP_NOTE,
    JOURNEY_NEXT_STEP_REFRESH_CTA,
    JOURNEY_NEXT_STEP_REFRESH_ONLY_CTA,
    JOURNEY_NEXT_STEP_TEXT,
    JOURNEY_NEXT_STEP_TEXT_MESURE,
    JOURNEY_NEXT_STEP_TITLE,
    JOURNEY_SUGGESTION_MOCK_EXAM,
    JOURNEY_TARGET_PATH_HREF,
    JOURNEY_UP_TO_DATE_TEXT,
    JOURNEY_UP_TO_DATE_TITLE,
    journeyBadge,
    journeyBlocMark,
    journeyBlocMeta,
    journeyBlocStatus,
    journeyBlocTitle,
    journeyCycleBadge,
    journeyCycleHint,
    journeyCycleLabel,
    journeyExamNote,
    journeyExamState,
    journeyExamTitle,
    journeyKind,
    journeyKitState,
    journeyStepSubtitle,
    journeyStepTitle,
    journeyTitle,
} from "@/lib/journey";
import type {
    JourneyBlocDto,
    JourneyDto,
    JourneyStepDto,
    LearningPlanDto,
} from "@/lib/types";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
    BlocAccordion,
    Card,
    CycleProgress,
    Cta,
    ExamStepBox,
    InfoNote,
    JourneyList,
    JourneyRow,
    NextStepCard,
    Pad,
    Section,
    Stack,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

/**
 * **Le cycle du Plan TCF** — tout ce que l'écran affiche à partir du titre
 * « Votre parcours vers le B2 » (D-22, 2026-09-18).
 *
 * Maquettes du propriétaire : `docs/progression/plan_cycle.html` et
 * `docs/progression/cycle_termine.html`. Ordre, définitif :
 *
 * 1. l'**encart de cycle** (`CycleProgress`) — la barre continue et son compteur ;
 * 2. les **blocs d'épreuve** (`BlocAccordion`), un par entrée de `blocs`, **dans
 *    l'ordre servi**, le bloc courant seul déplié ;
 * 3. dans chaque bloc : les **lignes d'étape** (`JourneyRow`) puis l'**encart
 *    d'examen** (`ExamStepBox`) ;
 * 4. la **note** de liberté d'ordre (`InfoNote`) ;
 * 5. sur un cycle terminé : « Prochaine étape » et la **carte à deux actions**
 *    (`NextStepCard`).
 *
 * 🛑 **Rien n'est décidé ici.** L'ordre des blocs, leur état, le nombre de
 * compétences restantes, le verrou de chaque étape et « le cycle est-il
 * terminé ? » sont **servis**. L'écran ne tient qu'une chose : **quel bloc est
 * déplié**, ce qui est une préférence d'affichage et rien d'autre.
 *
 * 🛑 **Ce qui a disparu avec cette passe** : la file plate `JourneySection` et
 * son « + N étapes » (`hiddenUpcomingCount`). Les blocs portent *toutes* les
 * étapes non obsolètes — il n'y a plus rien à replier.
 *
 * 🛑 **`lot`, `step`, `journey` ne s'affichent jamais** (D-21) : chaque bloc est
 * nommé par son **épreuve**, en clair, et chaque ligne dit la sienne.
 */
export function PlanCycleSection({
    journey,
    plan,
}: {
    /** `null` est un cas NORMAL — pas encore chargé, ou backend antérieur à
     *  l'endpoint : la section disparaît, elle n'affiche jamais un squelette. */
    journey: JourneyDto | null;
    plan: LearningPlanDto;
}) {
    if (!journey) return null;

    /* 🛑 **Aucun objectif déclaré ⇒ aucun parcours en base** (arbitrage D-3).
       Ce n'est pas un cycle vide : c'est l'absence de cycle, et le distinguer
       évite de féliciter un candidat qui n'a rien commencé. */
    if (journey.state === "NEEDS_OBJECTIVE") {
        return (
            <Section title={JOURNEY_NEEDS_OBJECTIVE_TITLE}>
                <Pad>
                    <Stack>
                        <Card>
                            <p className={sejourStyles.sub}>{JOURNEY_NEEDS_OBJECTIVE_TEXT}</p>
                        </Card>
                        <Cta href={JOURNEY_TARGET_PATH_HREF}>{JOURNEY_NEEDS_OBJECTIVE_CTA}</Cta>
                    </Stack>
                </Pad>
            </Section>
        );
    }

    /* Plus rien d'ouvert, et plus rien à proposer. 🛑 La **suggestion** est hors
       cycle : elle n'a pas de position, elle ne se clôt pas, et l'ignorer ne
       laisse rien « en attente ». */
    if (journey.state === "UP_TO_DATE") {
        return (
            <Section title={JOURNEY_UP_TO_DATE_TITLE}>
                <Pad>
                    <Card>
                        <p className={sejourStyles.sub}>{JOURNEY_UP_TO_DATE_TEXT}</p>
                        {journey.suggestion === "MOCK_EXAM" && (
                            <p className={sejourStyles.tiny}>{JOURNEY_SUGGESTION_MOCK_EXAM}</p>
                        )}
                    </Card>
                </Pad>
            </Section>
        );
    }

    if (!journey.cycle || journey.blocs.length === 0) return null;
    return <CycleBody journey={journey} plan={plan} />;
}

/**
 * 🛑 **Les hooks vivent ici, pas dans la racine** : la racine rend `null` sur
 * quatre états, et appeler un hook au-dessus de ces retours anticipés ferait
 * dépendre l'ordre des hooks d'une branche.
 */
function CycleBody({journey, plan}: {journey: JourneyDto; plan: LearningPlanDto}) {
    const cycle = journey.cycle!;
    const termine = journey.state === "CYCLE_COMPLETED";

    /* Le bloc **courant** est le seul déplié — c'est un fait servi
       (`status === "EN_COURS"`), jamais une position dans la liste. Sur un cycle
       terminé, aucun bloc ne l'est : les quatre sont repliés, comme dans
       `cycle_termine.html`. */
    const courant = journey.blocs.find((bloc) => bloc.status === "EN_COURS") ?? null;
    /* `null` = le candidat n'a rien choisi, on suit le bloc courant. Une fois
       qu'il a touché un en-tête, c'est **son** choix qui vaut — y compris
       « tout replié ». */
    const [choix, setChoix] = useState<{key: string | null} | null>(null);
    const ouvert = choix ? choix.key : courant?.examType ?? null;

    const exercises = usePlanExercise();
    const assessments = usePlanAssessment();
    const busy = exercises.starting || assessments.starting !== null;

    /* 🛑 **L'action d'une ligne passe par le MÊME chemin que la carte « À faire
       maintenant »** : `planStepAction` résout avec les deux autorités de
       `planNowCard`, et les lanceurs sont ceux du Plan. Rien ne se résout ⇒
       **aucun geste** : la ligne nomme l'étape, sans bouton (garde-fou du
       2026-09-17).

       🛑 **Une étape verrouillée ne lance rien depuis le Plan** : le Plan d'un
       compte sans accès est un constat, le déblocage passe par le bouton ancré
       en bas du cycle. */
    const actionDe = useCallback(
        (etape: JourneyStepDto): (() => void) | undefined => {
            if (etape.locked || busy) return undefined;
            const action = planStepAction(plan, etape);
            if (!action) return undefined;
            if (action.mesure) {
                const mesure = action.mesure;
                return () => void assessments.start(mesure.assessment);
            }
            const exercise = action.exercise!;
            return () => void exercises.start(exercise);
        },
        [assessments, busy, exercises, plan],
    );

    return (
        <>
            <Section title={journeyTitle(journey.targetLevel)}>
                <Pad>
                    <Stack>
                        <CycleProgress
                            label={journeyCycleLabel(cycle)}
                            done={cycle.etapesTerminees}
                            total={cycle.etapesTotal}
                            badge={journeyCycleBadge(cycle)}
                            hint={journeyCycleHint(cycle)}
                            /* 🛑 **Servi, jamais déduit de `done === total`** :
                               un cycle peut afficher « 8 sur 8 » sans être clos
                               côté serveur. */
                            complete={cycle.complete}
                        />

                        {/* 🛑 **L'ordre servi est l'autorité** : aucun `sort`,
                            aucun filtre — les quatre épreuves sont là, même
                            celles que la file n'a pas encore peuplées. */}
                        {journey.blocs.map((bloc) => (
                            <BlocAccordion
                                key={bloc.examType}
                                mark={journeyBlocMark(bloc.examType)}
                                title={journeyBlocTitle(bloc.examType)}
                                meta={journeyBlocMeta(bloc)}
                                status={journeyBlocStatus(bloc.status)}
                                current={bloc.status === "EN_COURS"}
                                open={ouvert === bloc.examType}
                                onToggle={() =>
                                    setChoix({
                                        key: ouvert === bloc.examType ? null : bloc.examType,
                                    })
                                }
                            >
                                <BlocBody bloc={bloc} actionDe={actionDe} />
                            </BlocAccordion>
                        ))}

                        <InfoNote>{JOURNEY_CYCLE_NOTE}</InfoNote>

                        {/* 🛑 Des étapes restent, mais **aucune n'est
                            exécutable** : on le dit, au lieu de laisser un cycle
                            sans étape courante qui se lirait comme une panne. */}
                        {journey.state === "LOCKED" && (
                            <p className={sejourStyles.tiny}>{JOURNEY_LOCKED_CAPTION}</p>
                        )}

                        {(exercises.error ?? assessments.error) && (
                            <p className={sejourStyles.tiny} role="alert">
                                {exercises.error ?? assessments.error}
                            </p>
                        )}
                    </Stack>
                </Pad>
            </Section>

            {termine && journey.nextStep && (
                /* 🛑 **`examenCompletPossible` est SERVI** : il dit déjà « ce
                   cycle est un cycle de mesure », et le redéduire de
                   `cycle.cycleDeMesure` ferait deux autorités pour un fait. */
                <NextStep examenCompletPossible={journey.nextStep.examenCompletPossible} />
            )}

            <PaywallSheet
                origin="plan"
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module="INTEGRAL"
                open={exercises.paywallOpen || assessments.paywallOpen}
                onClose={() => {
                    exercises.closePaywall();
                    assessments.closePaywall();
                }}
            />
        </>
    );
}

/**
 * Le corps d'un bloc : ses **lignes d'étape** puis son **encart d'examen**.
 *
 * 🛑 L'examen est servi **à part** (`bloc.exam`) et rendu en fin de bloc : c'est
 * un checkpoint, pas une étape de plus dans la liste.
 */
function BlocBody({
    bloc,
    actionDe,
}: {
    bloc: JourneyBlocDto;
    actionDe: (etape: JourneyStepDto) => (() => void) | undefined;
}) {
    return (
        <>
            {bloc.steps.length > 0 && (
                <JourneyList>
                    {bloc.steps.map((step) => (
                        <JourneyRow
                            key={step.id}
                            title={journeyStepTitle(step)}
                            subtitle={journeyStepSubtitle(step)}
                            state={journeyKitState(step)}
                            kind={journeyKind(step)}
                            badge={journeyBadge(step)}
                            locked={step.locked}
                            onClick={actionDe(step)}
                        />
                    ))}
                </JourneyList>
            )}
            {bloc.exam && (
                <ExamStepBox
                    title={journeyExamTitle(bloc.exam)}
                    state={journeyExamState(bloc.exam)}
                    note={journeyExamNote(bloc, bloc.exam)}
                    locked={bloc.exam.locked}
                    onClick={actionDe(bloc.exam)}
                />
            )}
        </>
    );
}

/**
 * **La fin de cycle** (spec §6) : « Prochaine étape », puis un vrai choix.
 *
 * - « Passer l'examen blanc complet » appelle `POST …/measurement-cycle` **puis**
 *   lance l'examen complet par le chemin existant (`fullTcfExamApi.start`) — le
 *   geste crée le cycle de mesure, il ne démarre rien par lui-même côté serveur.
 *   🛑 **Il n'apparaît que si `examenCompletPossible`** : à la fin d'un cycle de
 *   mesure, enchaîner un second examen complet ne mesurerait rien de nouveau.
 * - « Actualiser mon plan sans examen complet » appelle `POST …/refresh`.
 *
 * 🛑 **Les deux purgent le cache du parcours et du Plan** (`journeyApi` le fait
 * déjà, à la source) puis **repeignent** — l'écran recharge ses deux lectures
 * ensemble, jamais l'une sans l'autre.
 *
 * 🛑 **Un échec réseau se DIT** : le bouton ne reste jamais muet.
 */
function NextStep({examenCompletPossible}: {examenCompletPossible: boolean}) {
    const router = useRouter();
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const actualiser = useCallback(async () => {
        setError(null);
        setBusy(true);
        try {
            await journeyApi.refresh();
            /* Le cache est déjà purgé par `journeyApi` : il ne reste qu'à
               redemander le rendu de la route, qui relit Plan et parcours. */
            router.refresh();
            router.replace("/plan?module=TCF");
        } catch {
            setError(JOURNEY_NEXT_STEP_ERROR);
        } finally {
            setBusy(false);
        }
    }, [router]);

    const examenComplet = useCallback(async () => {
        setError(null);
        setBusy(true);
        try {
            await journeyApi.measurementCycle();
            const exam = await fullTcfExamApi.start();
            router.push(`/examens-blancs/tcf/${exam.id}`);
        } catch (cause) {
            /* Un **403** au démarrage de l'examen n'est pas une panne : c'est le
               verrou freemium que le serveur oppose, et il ouvre l'offre. Le
               cycle de mesure, lui, est déjà créé — le candidat le retrouvera. */
            handleStartFailure(cause, {
                onPaywall: () => setPaywallOpen(true),
                onMessage: setError,
                fallbackMessage: JOURNEY_NEXT_STEP_ERROR,
            });
        } finally {
            setBusy(false);
        }
    }, [router]);

    return (
        <Section title={JOURNEY_NEXT_STEP_TITLE}>
            <Pad>
                <Stack>
                    <NextStepCard
                        eyebrow={JOURNEY_NEXT_STEP_EYEBROW}
                        title={JOURNEY_NEXT_STEP_HEADLINE}
                        text={
                            examenCompletPossible
                                ? JOURNEY_NEXT_STEP_TEXT
                                : JOURNEY_NEXT_STEP_TEXT_MESURE
                        }
                        /* 🛑 Les repères décrivent l'examen complet : sans lui,
                           ils n'ont rien à dire. */
                        facts={examenCompletPossible ? JOURNEY_NEXT_STEP_FACTS : []}
                        /* Une carte à deux actions dont la première n'existe
                           pas : l'actualisation prend la place principale, et
                           c'est la seule issue d'un cycle de mesure clos. */
                        primary={
                            examenCompletPossible
                                ? {
                                    label: busy
                                        ? JOURNEY_NEXT_STEP_BUSY
                                        : JOURNEY_NEXT_STEP_EXAM_CTA,
                                    onClick: () => void examenComplet(),
                                }
                                : {
                                    label: busy
                                        ? JOURNEY_NEXT_STEP_BUSY
                                        : JOURNEY_NEXT_STEP_REFRESH_ONLY_CTA,
                                    onClick: () => void actualiser(),
                                }
                        }
                        /* 🛑 **Absente quand l'examen complet n'est pas
                           proposé** : il ne reste qu'une issue, et fabriquer un
                           second bouton pour tenir la forme ferait deux fois le
                           même geste. */
                        secondary={
                            examenCompletPossible
                                ? {
                                    label: JOURNEY_NEXT_STEP_REFRESH_CTA,
                                    onClick: () => void actualiser(),
                                }
                                : undefined
                        }
                    />
                    {/* 🛑 La note ne se lit que face à un choix : sans examen
                        complet à proposer, elle décrirait une option absente. */}
                    {examenCompletPossible && <InfoNote>{JOURNEY_NEXT_STEP_NOTE}</InfoNote>}
                    {error && (
                        <p className={sejourStyles.tiny} role="alert">
                            {error}
                        </p>
                    )}
                </Stack>
            </Pad>
            <PaywallSheet
                origin="plan"
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module="INTEGRAL"
                open={paywallOpen}
                onClose={() => setPaywallOpen(false)}
            />
        </Section>
    );
}
