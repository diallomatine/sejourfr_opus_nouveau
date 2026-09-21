"use client";

import {useCallback, useState} from "react";
import {useRouter} from "next/navigation";
import {attemptApi, fullTcfExamApi, journeyApi} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";
import {planHref, type ParcoursModule} from "@/lib/module-switch";
import {planSkillTargetLevelDeCode, planStepAction, planStepActionLocked} from "@/lib/plan-domain";
import {planUnlockHref} from "@/lib/plan-unlock";
import {
    JOURNEY_CYCLE_NOTE,
    journeyLockedCaption,
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
    JOURNEY_STEP_ACTION_LINK,
    JOURNEY_STEP_UNLOCK_LINK,
    JOURNEY_SUGGESTION_MOCK_EXAM,
    JOURNEY_TARGET_PATH_HREF,
    JOURNEY_UP_TO_DATE_TEXT,
    JOURNEY_UP_TO_DATE_TITLE,
    journeyBadge,
    journeyBlocMark,
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
    journeyCycleStepSubtitle,
    journeyCycleStepTitle,
    journeyEtapeASeries,
    journeyEtapeHref,
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
 *    l'ordre servi**, le premier seul déplié ;
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
 *
 * 🛑 **Une étape VERROUILLÉE porte un geste, pas un cadenas muet** (demande du
 * propriétaire, 2026-09-20) : là où un abonné lit « Faire cette étape », un
 * compte gratuit lit « Débloquer mon plan » et le tap ouvre l'offre. Le cadenas
 * reste à sa place — il code l'état —, c'est le **silence** qui disparaît. Le
 * bouton rouge « Débloquer mon plan {objectif} » reste le seul CTA critique de
 * l'écran, ancré sous le cycle (A46) : ce geste-ci prend la variante **bleue**
 * du lien d'action.
 */
export function PlanCycleSection({
    journey,
    plan,
    module = "TCF",
}: {
    /** `null` est un cas NORMAL — pas encore chargé, ou backend antérieur à
     *  l'endpoint : la section disparaît, elle n'affiche jamais un squelette. */
    journey: JourneyDto | null;
    /** Le Plan TCF, **seulement** pour résoudre l'action d'une étape TCF.
     *  `null` côté civique : l'action y est la série sur l'**unité** servie. */
    plan: LearningPlanDto | null;
    /** 🛑 **Le module du cycle affiché** (D-50) : cette section est COMMUNE aux
     *  deux, et c'est le module qui dit où repartir après une fin de cycle. */
    module?: ParcoursModule;
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
    return <CycleBody journey={journey} plan={plan} module={module} />;
}

/**
 * 🛑 **Les hooks vivent ici, pas dans la racine** : la racine rend `null` sur
 * quatre états, et appeler un hook au-dessus de ces retours anticipés ferait
 * dépendre l'ordre des hooks d'une branche.
 */
function CycleBody({journey, plan, module}: {
    journey: JourneyDto;
    plan: LearningPlanDto | null;
    module: ParcoursModule;
}) {
    const cycle = journey.cycle!;
    const termine = journey.state === "CYCLE_COMPLETED";

    /* 🛑 **Le PREMIER bloc servi est le seul déplié** (demande du propriétaire,
       2026-09-20). Il suivait auparavant `status === "EN_COURS"`, ce qui était
       juste tant que l'ordre était figé — mais depuis que les blocs porteurs de
       travail passent devant (D-56), le bloc courant peut être en 2ᵈ position :
       le candidat arrivait alors sur un cycle dont la tête était repliée et le
       milieu ouvert. L'ordre servi dit déjà ce qui compte d'abord ; le dépli le
       suit, il ne le contredit pas.

       ⚠️ **Sauf sur un cycle TERMINÉ** : les quatre blocs restent repliés, comme
       dans `cycle_termine.html` — la maquette de référence de D-22. Il n'y a
       alors plus rien à faire dedans, et c'est la carte de fin de cycle qui
       porte le geste. */
    const premier = journey.blocs[0] ?? null;
    /* `null` = le candidat n'a rien choisi, on suit le premier bloc. Une fois
       qu'il a touché un en-tête, c'est **son** choix qui vaut — y compris
       « tout replié ». */
    const [choix, setChoix] = useState<{key: string | null} | null>(null);
    const ouvert = choix ? choix.key : termine ? null : premier?.bloc?.code ?? null;

    const routerCycle = useRouter();
    const exercises = usePlanExercise();
    const assessments = usePlanAssessment();
    const busy = exercises.starting || assessments.starting !== null;


    /* 🛑 **Le pass n'est pas le même selon le parcours** : le cycle civique
       s'ouvre avec le pass **Civique** (comme `openCivicOffer` côté mobile et
       les trois `PaywallSheet` du panneau civique), le cycle TCF avec
       l'**Intégral**. Un seul endroit le décide. */
    const passOffre = module === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL";

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
            /* 🛑 **UNE ÉTAPE DE SÉRIES OUVRE SON ÉCRAN, ELLE NE LANCE PLUS RIEN**
               (demande du propriétaire, 2026-09-20). Compréhension CO/CE et
               civique : le candidat voit d'abord ce que l'étape demande — la
               compétence ou l'unité travaillée, le seuil, ses deux séries — puis
               choisit la série qu'il lance.

               ⚠️ **Révoque** le lancement direct depuis la ligne du cycle : la
               série ciblée partait de `planStepAction` côté TCF et de
               `useCivicUniteSerie` côté civique, et le hook a quitté cet écran
               avec elle (ses autres appelants le gardent).

               ⚠️ **Les étapes d'EXPRESSION ne sont PAS concernées** : elles
               portent une tâche et gardent leur chemin vers leurs petits sujets. */
            if (journeyEtapeASeries(etape)) {
                return () => routerCycle.push(journeyEtapeHref(etape.id, module));
            }
            /* 🛑 **Le Plan TCF n'a rien à dire d'une étape civique** (A86) : hors
               étape de séries, une ligne civique n'a pas de geste — l'examen d'un
               bloc se lance depuis son propre encart. */
            if (module === "CIVIQUE") return undefined;
            if (!plan) return undefined;
            const action = planStepAction(plan, etape);
            if (!action) return undefined;
            /* 🛑 **Une action SERVIE mais verrouillée ne se lance pas** : son
               geste est un geste d'achat, rendu par `gesteDe`. Le lancer
               partirait chercher un 403 pour le traduire en paywall, exactement
               le chemin qu'A145 ferme. */
            if (planStepActionLocked(action)) return undefined;
            if (action.mesure) {
                const mesure = action.mesure;
                return () => void assessments.start(mesure.assessment);
            }
            const exercise = action.exercise!;
            return () => void exercises.start(exercise);
        },
        [assessments, busy, exercises, module, plan, routerCycle],
    );

    /**
     * **L'action de cette ligne est-elle SERVIE mais verrouillée ?**
     *
     * 🛑 **Le verrou de l'ACTION n'est pas celui de l'ÉTAPE** (A146) : une
     * étape servie ouverte peut porter un exercice — ou une mesure — fermé, et
     * c'est par là que le geste sautait l'écran de transition pour finir sur un
     * 403 puis le paywall. `planStepActionLocked` est l'autorité, partagée avec
     * le mobile.
     *
     * ⚠️ **Rien à lancer ⇒ `false`** : une ligne sans action ne se voit pas
     * poser un geste d'achat qui ne la débloquerait pas (garde-fou A25).
     */
    const actionVerrouillee = useCallback(
        (etape: JourneyStepDto): boolean => {
            if (etape.locked || journeyEtapeASeries(etape)) return false;
            if (module === "CIVIQUE" || !plan) return false;
            const action = planStepAction(plan, etape);
            return action !== null && planStepActionLocked(action);
        },
        [module, plan],
    );

    /**
     * **Le geste d'une ligne d'étape** : son action, ou l'offre quand elle est
     * verrouillée.
     *
     * 🛑 **Le verrou est LU, jamais déduit** (`JourneyStepDto.locked`, D-18) :
     * ni un rang, ni un statut d'abonnement lu côté client, ni une position.
     *
     * 🛑 **Sur une étape d'entraînement, `locked` est TOUJOURS commercial** —
     * `JourneyReadService` §5 bis le pose depuis `SkillAccessService`, et
     * `JourneyBlocDto.steps` ne porte que des étapes d'entraînement (l'examen
     * est servi à part, dans `bloc.exam`). Le seul verrou **pédagogique** du
     * cycle est celui d'un examen de bloc, et il garde son encart muet : sa
     * phrase servie dit déjà ce qui l'ouvrira, et ce n'est pas un pass.
     */
    /* 🛑 **Le palier vient du PLAN**, un fait servi sur la compétence
       (`PlanDomainSkillDto.targetLevel`) — `JourneyStepDto` n'en porte aucun,
       et le dériver ici en ferait une seconde autorité. `null` en civique
       (pas de plan TCF, pas de CECRL) et sur une tâche d'expression, qui porte
       son rang et non un palier. */
    const niveauDe = useCallback(
        (etape: JourneyStepDto): string | null =>
            plan && !etape.taskCode
                ? planSkillTargetLevelDeCode(plan, etape.skillCode)
                : null,
        [plan],
    );

    const gesteDe = useCallback(
        (etape: JourneyStepDto): {label: string; onClick: () => void} | undefined => {
            if (etape.locked) {
                /* 🛑 **Le geste passe par l'ÉCRAN DE TRANSITION**, jamais
                   directement par l'offre (demande du propriétaire,
                   2026-09-20). Le CTA ancré sous le cycle y menait déjà ; une
                   ligne d'étape qui ouvrait le paywall d'un coup sautait
                   l'écran qui **dit au candidat ce qu'il achète** — ses
                   priorités, son écart à l'objectif, le prix d'entrée. Deux
                   chemins vers le même achat, dont un plus pauvre. */
                return {
                    label: JOURNEY_STEP_UNLOCK_LINK,
                    onClick: () => routerCycle.push(planUnlockHref(module)),
                };
            }
            const action = actionDe(etape);
            if (action) return {label: JOURNEY_STEP_ACTION_LINK, onClick: action};
            /* 🛑 **L'action existe mais elle est fermée** : la ligne garde son
               geste d'achat — sans lui, elle serait muette.

               ⚠️ **Révoque** le test `etape.type === "TRAIN_SKILL"`, qui était
               un raccourci pour « le seul cas où `actionDe` ne résout rien est
               un exercice fermé ». Il était faux dès qu'une **mesure** fermée
               portait la ligne, et il donnait un geste d'achat à une étape
               d'entraînement simplement **occupée**. On lit le verrou servi de
               l'action, comme le mobile. */
            return actionVerrouillee(etape)
                ? {
                      label: JOURNEY_STEP_UNLOCK_LINK,
                      onClick: () => routerCycle.push(planUnlockHref(module)),
                  }
                : undefined;
        },
        [actionDe, actionVerrouillee, module, routerCycle],
    );

    return (
        <>
            <Section title={journeyTitle(journey.objectif)}>
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
                                key={bloc.bloc.code}
                                mark={journeyBlocMark(bloc.bloc)}
                                title={journeyBlocTitle(bloc.bloc)}
                                meta={bloc.meta}
                                status={journeyBlocStatus(bloc.status)}
                                current={bloc.status === "EN_COURS"}
                                open={ouvert === bloc.bloc.code}
                                onToggle={() =>
                                    setChoix({
                                        key: ouvert === bloc.bloc.code ? null : bloc.bloc.code,
                                    })
                                }
                            >
                                <BlocBody
                                    bloc={bloc}
                                    actionDe={actionDe}
                                    gesteDe={gesteDe}
                                    niveauDe={niveauDe}
                                />
                            </BlocAccordion>
                        ))}

                        <InfoNote>{JOURNEY_CYCLE_NOTE}</InfoNote>

                        {/* 🛑 Des étapes restent, mais **aucune n'est
                            exécutable** : on le dit, au lieu de laisser un cycle
                            sans étape courante qui se lirait comme une panne. */}
                        {journey.state === "LOCKED" && (
                            <p className={sejourStyles.tiny}>{journeyLockedCaption(module)}</p>
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
                <NextStep
                    examenCompletPossible={journey.nextStep.examenCompletPossible}
                    module={module}
                />
            )}

            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module={passOffre}
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
    gesteDe,
    niveauDe,
}: {
    bloc: JourneyBlocDto;
    /** Le lancement d'une étape **ouverte** — c'est tout ce dont l'encart
     *  d'examen a besoin : verrouillé, il reste inerte et sa phrase servie dit
     *  ce qui l'ouvrira. */
    actionDe: (etape: JourneyStepDto) => (() => void) | undefined;
    /** Le geste d'une **ligne d'étape** : son action, ou l'offre. */
    gesteDe: (etape: JourneyStepDto) => {label: string; onClick: () => void} | undefined;
    /** Le palier d'une compétence de **compréhension**, lu sur le Plan. `null`
     *  partout ailleurs — une tâche d'expression porte son rang, pas un
     *  palier, et le civique n'a pas de CECRL. */
    niveauDe: (etape: JourneyStepDto) => string | null;
}) {
    /* 🛑 **Toutes les étapes du bloc, y compris celles déjà closes** : le
       serveur sert les `COMPLETED` (seules les OBSOLETE sont exclues), et c'est
       ce qui donne à la file son « avant / maintenant / après ». Aucun filtre
       ici. */
    return (
        <JourneyList
            variant="cycle"
            /* 🛑 L'examen est la DERNIÈRE étape de la file, sur le rail et avec
               sa pastille « ◎ » : c'est la maquette. Il reste servi à part
               (`bloc.exam`), l'écran ne fait que le ranger. */
            exam={
                bloc.exam && (
                    <ExamStepBox
                        title={journeyExamTitle(bloc.exam)}
                        state={journeyExamState(bloc.exam)}
                        note={journeyExamNote(bloc, bloc.exam)}
                        locked={bloc.exam.locked}
                        onClick={actionDe(bloc.exam)}
                    />
                )
            }
        >
            {bloc.steps.map((step) => {
                /* 🛑 **Le libellé suit le geste**, et les deux viennent du même
                   endroit : « Faire cette étape → » quand l'étape est ouverte,
                   « Débloquer mon plan → » quand elle ne l'est pas. Le kit ne
                   compose ni l'un ni l'autre. */
                const geste = gesteDe(step);
                return (
                    <JourneyRow
                        key={step.id}
                        /* 🛑 **La composition du CYCLE** : « Tâche 3 » en
                           titre, l'intitulé dessous, et **pas d'épreuve** —
                           l'en-tête du bloc la nomme déjà. Les autres lectures
                           de `journeyStep*` la gardent (cf. `lib/journey.ts`). */
                        title={journeyCycleStepTitle(step, niveauDe(step))}
                        subtitle={journeyCycleStepSubtitle(step)}
                        state={journeyKitState(step)}
                        kind={journeyKind(step)}
                        badge={journeyBadge(step)}
                        locked={step.locked}
                        actionLabel={geste?.label}
                        onClick={geste?.onClick}
                    />
                );
            })}
        </JourneyList>
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
function NextStep({examenCompletPossible, module}: {
    examenCompletPossible: boolean;
    module: ParcoursModule;
}) {
    const router = useRouter();
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const actualiser = useCallback(async () => {
        setError(null);
        setBusy(true);
        try {
            await journeyApi.refresh(module);
            /* Le cache est déjà purgé par `journeyApi` : il ne reste qu'à
               redemander le rendu de la route, qui relit Plan et parcours. */
            router.refresh();
            router.replace(planHref(module));
        } catch {
            setError(JOURNEY_NEXT_STEP_ERROR);
        } finally {
            setBusy(false);
        }
    }, [module, router]);

    const examenComplet = useCallback(async () => {
        setError(null);
        setBusy(true);
        try {
            await journeyApi.measurementCycle(module);
            /* 🛑 Le geste CRÉE le cycle de mesure, puis lance l'examen complet
               par le chemin existant de SON module — il ne démarre rien par
               lui-même côté serveur. */
            if (module === "CIVIQUE") {
                const exam = await attemptApi.start({
                    type: "MOCK_EXAM", module: "CIVIQUE",
                });
                router.push(`/examen-blanc?attempt=${exam.id}`);
            } else {
                const exam = await fullTcfExamApi.start();
                router.push(`/examens-blancs/tcf/${exam.id}`);
            }
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
    }, [module, router]);

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
            {/* 🛑 **Le pass suit le parcours** (A108) : le 403 d'un examen
                civique s'ouvre avec le pass **Civique**, jamais l'Intégral. Il
                était figé sur `INTEGRAL` — sans effet tant que la fin de cycle
                n'existait qu'en TCF, faux dès qu'un cycle civique s'achève. */}
            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module={module === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL"}
                open={paywallOpen}
                onClose={() => setPaywallOpen(false)}
            />
        </Section>
    );
}
