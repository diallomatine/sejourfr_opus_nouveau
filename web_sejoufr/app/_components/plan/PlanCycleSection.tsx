"use client";

import {useCallback, useState} from "react";
import {useRouter} from "next/navigation";
import {journeyApi} from "@/lib/api";
import {planHref, type ParcoursModule} from "@/lib/module-switch";
import {planSkillTargetLevelDeCode, planStepAction, planStepActionLocked} from "@/lib/plan-domain";
import {planUnlockHref} from "@/lib/plan-unlock";
import {
    journeyLockedCaption,
    JOURNEY_NEEDS_OBJECTIVE_CTA,
    JOURNEY_NEEDS_OBJECTIVE_TEXT,
    JOURNEY_NEEDS_OBJECTIVE_TITLE,
    JOURNEY_NEXT_STEP_BUSY,
    JOURNEY_NEXT_STEP_ERROR,
    JOURNEY_NEXT_STEP_EYEBROW,
    JOURNEY_NEXT_STEP_HEADLINE,
    JOURNEY_NEXT_STEP_REFRESH_CTA,
    JOURNEY_NEXT_STEP_TEXT,
    journeyNextStepFacts,
    JOURNEY_STEP_ACTION_LINK,
    JOURNEY_STEP_UNLOCK_LINK,
    JOURNEY_SUGGESTION_MOCK_EXAM,
    journeyTargetPathHref,
    JOURNEY_UP_TO_DATE_TEXT,
    JOURNEY_UP_TO_DATE_TITLE,
    journeyBadge,
    journeyBlocMark,
    journeyBlocRailState,
    journeyBlocStatus,
    journeyBlocTitle,
    journeyCycleBadge,
    journeyCycleHint,
    journeyCycleNote,
    journeyCycleLabel,
    JOURNEY_EXAM_START,
    JOURNEY_EXAM_SUBTITLE,
    JOURNEY_EXAM_TITLE,
    journeyExamDone,
    journeyExamNote,
    JOURNEY_RAIL_END_EYEBROW,
    JOURNEY_RAIL_END_TITLE,
    journeyPrioritesIdentifiees,
    journeyRailEndRemaining,
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
    JourneyCycleDto,
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
    CycleRail,
    CycleRailEnd,
    CycleRailStep,
    ExamStepAction,
    InfoNote,
    JourneyList,
    JourneyRow,
    NextStepCard,
    Pad,
    Section,
    Stack,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {useMockExamLauncher} from "@/app/_components/hub/MockExamLauncher";
import {ClosedExamStep} from "./PlanBits";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

/**
 * **Le cycle du Plan TCF** — tout ce que l'écran affiche à partir du titre
 * « Votre parcours vers le B2 » (D-22, 2026-09-18).
 *
 * Maquettes du propriétaire : `docs/progression/plan_cycle.html` et
 * `docs/progression/cycle_termine.html`. Ordre, définitif :
 *
 * 1. l'**encart de cycle** (`CycleProgress`) — la barre continue et son compteur ;
 * 2. la **timeline** (`CycleRail`, 2026-09-27) : un rond par bloc
 *    (`CycleRailStep`), puis la **dernière étape** « Fin du cycle »
 *    (`CycleRailEnd`) ;
 * 3. sur chaque rond, un **bloc d'épreuve** (`BlocAccordion`), un par entrée de
 *    `blocs`, **dans l'ordre servi**, le premier seul déplié — et dedans les
 *    **lignes d'étape** (`JourneyRow`) puis l'**encart d'examen**
 *    (`ExamStepAction`) ;
 * 4. la **note** de liberté d'ordre (`InfoNote`) ;
 * 5. sur un cycle terminé, la dernière étape **devient** la **carte de fin de
 *    cycle** (`NextStepCard`) — « Actualiser mon plan », sa seule issue depuis
 *    D-66 (2026-09-27).
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
                        <Cta href={journeyTargetPathHref(planHref(module))}>{JOURNEY_NEEDS_OBJECTIVE_CTA}</Cta>
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
    const launchExam = useMockExamLauncher();
    /* Le 403 d'un examen de thème (garde de dernier recours : le créneau servi
       est l'offert) ouvre la même offre que le reste du cycle. */
    const [examPaywallOpen, setExamPaywallOpen] = useState(false);
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
            /* 🛑 **L'examen d'un bloc CIVIQUE lance l'examen de thème SERVI**
               (`examenTheme`, 2026-09-28) — par le lanceur partagé de la grille
               du thème : feuille d'information, puis démarrage. Le thème et le
               créneau viennent du serveur, jamais d'ici. */
            const examenTheme = etape.examenTheme;
            if (examenTheme) {
                return () => launchExam({
                    kind: "CIVIQUE",
                    themeId: examenTheme.themeId,
                    themeName: etape.bloc?.label ?? JOURNEY_EXAM_TITLE,
                    slotNumber: examenTheme.slotNumber,
                    onPaywall: () => setExamPaywallOpen(true),
                });
            }
            /* 🛑 **Le Plan TCF n'a rien à dire d'une étape civique** (A86) : hors
               étape de séries et examen de thème, une ligne civique n'a pas de
               geste. */
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
        [assessments, busy, exercises, launchExam, module, plan, routerCycle],
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
                            celles que la file n'a pas encore peuplées. Le rond
                            de chaque bloc traduit son statut SERVI. */}
                        <CycleRail>
                            {journey.blocs.map((bloc) => (
                                <CycleRailStep
                                    key={bloc.bloc.code}
                                    state={journeyBlocRailState(bloc.status)}
                                >
                                    <BlocAccordion
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
                                            /* 🛑 Un examen de thème civique
                                               est lançable dès que son action
                                               est SERVIE (`examenTheme`). */
                                            examenLancable={
                                                module !== "CIVIQUE"
                                                || Boolean(bloc.exam?.examenTheme)
                                            }
                                            actionDe={actionDe}
                                            gesteDe={gesteDe}
                                            niveauDe={niveauDe}
                                        />
                                    </BlocAccordion>
                                </CycleRailStep>
                            ))}

                            {/* 🛑 **La dernière étape : « Actualiser mon plan »**,
                                la seule fin de cycle depuis D-66, avec le nombre
                                SERVI de priorités du cycle suivant
                                (`prioritesCycleSuivant`, D-67) et le compteur
                                servi lu à l'envers. Atteinte — cycle terminé ET
                                issue servie —, elle devient la carte de fin. */}
                            <CycleRailEnd
                                eyebrow={JOURNEY_RAIL_END_EYEBROW}
                                title={JOURNEY_RAIL_END_TITLE}
                                note={journeyPrioritesIdentifiees(cycle)}
                                remaining={journeyRailEndRemaining(cycle)}
                                reached={termine && journey.nextStep !== null}
                            >
                                {termine && journey.nextStep && (
                                    <NextStep cycle={cycle} module={module} />
                                )}
                            </CycleRailEnd>
                        </CycleRail>

                        <InfoNote>{journeyCycleNote(cycle)}</InfoNote>

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

            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module={passOffre}
                journeyId={journey.journeyId}
                open={exercises.paywallOpen || assessments.paywallOpen || examPaywallOpen}
                onClose={() => {
                    exercises.closePaywall();
                    assessments.closePaywall();
                    setExamPaywallOpen(false);
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
    examenLancable,
    actionDe,
    gesteDe,
    niveauDe,
}: {
    bloc: JourneyBlocDto;
    /** L'étape d'examen porte-t-elle un bouton « Commencer » ? Toujours en
     *  TCF ; en civique, dès que l'examen de thème est **servi**
     *  (`examenTheme`, 2026-09-28 — révoque le « sans bouton » d'A86). Le
     *  verrou, lui, reste dit dans tous les cas. */
    examenLancable: boolean;
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
                    <ExamStep
                        exam={bloc.exam}
                        lancable={examenLancable}
                        actionDe={actionDe}
                        gesteDe={gesteDe}
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
 * **L'étape d'examen d'un bloc** — « Examen blanc », « Évaluez vos progrès », et
 * le bouton « Commencer » à droite (demande du propriétaire, 2026-09-26) ; une
 * fois passé, « Passé le … » et son résultat servi (D-69 ter).
 *
 * 🛑 **Tout l'état est lu, rien n'est classé ici** : passé ⇐ `status` servi ;
 * verrouillé ⇐ `locked` servi, et sa raison ⇐ `lockReason` servi. Le bouton est
 * inactif dès que `actionDe` ne résout rien — verrou, action fermée ou
 * lancement en cours.
 *
 * 🛑 **Le geste d'achat n'apparaît que sur un verrou d'ACCÈS** : un verrou de
 * progression (D-15) ne se lève pas avec un pass, lui proposer l'offre serait
 * mentir sur ce qui l'ouvrira.
 */
function ExamStep({exam, lancable, actionDe, gesteDe}: {
    exam: JourneyStepDto;
    lancable: boolean;
    actionDe: (etape: JourneyStepDto) => (() => void) | undefined;
    gesteDe: (etape: JourneyStepDto) => {label: string; onClick: () => void} | undefined;
}) {
    /* 🛑 **Un examen passé PENDANT le cycle montre ce qu'il a donné**
       (D-69 ter) : même ligne que la consultation d'un cycle clos, résultat
       servi, jamais un bloc muet. */
    if (journeyExamDone(exam)) return <ClosedExamStep exam={exam} />;
    const action = lancable ? actionDe(exam) : undefined;
    const achat = !action && (exam.locked ? exam.lockReason === "ACCESS" : lancable)
        ? gesteDe(exam)
        : undefined;
    return (
        <ExamStepAction
            title={JOURNEY_EXAM_TITLE}
            subtitle={JOURNEY_EXAM_SUBTITLE}
            trailing={lancable
                ? {kind: "start", label: JOURNEY_EXAM_START, locked: exam.locked, onClick: action}
                : undefined}
            note={journeyExamNote(exam)}
            noteAction={achat}
        />
    );
}

/**
 * **La fin de cycle** — « Actualiser mon plan », et rien d'autre (D-66,
 * 2026-09-27). Le choix « Passer l'examen blanc complet / Actualiser sans
 * examen complet » est supprimé : l'examen complet est devenu un **jalon**
 * proposé au-dessus du Plan (`ExamenCompletJalon`).
 *
 * 🛑 **`journeyApi.refresh` purge, range le nouveau cycle et fait relire
 * l'écran** : rien d'autre à faire ici.
 *
 * 🛑 **Un échec réseau se DIT** : le bouton ne reste jamais muet.
 */
function NextStep({cycle, module}: {
    cycle: JourneyCycleDto;
    module: ParcoursModule;
}) {
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const actualiser = useCallback(async () => {
        setError(null);
        setBusy(true);
        try {
            await journeyApi.refresh(module);
        } catch {
            setError(JOURNEY_NEXT_STEP_ERROR);
        } finally {
            setBusy(false);
        }
    }, [module]);

    /* 🛑 **Plus d'intertitre « Prochaine étape »** (2026-09-27) : la carte est
       rendue DANS la dernière étape de la timeline, dont elle prend la place.
       Ni `Section` ni `Pad` — elle est déjà dans ceux du cycle. */
    return (
        <Stack>
            <NextStepCard
                eyebrow={JOURNEY_NEXT_STEP_EYEBROW}
                title={JOURNEY_NEXT_STEP_HEADLINE}
                text={JOURNEY_NEXT_STEP_TEXT}
                facts={journeyNextStepFacts(cycle)}
                primary={{
                    label: busy ? JOURNEY_NEXT_STEP_BUSY : JOURNEY_NEXT_STEP_REFRESH_CTA,
                    onClick: () => void actualiser(),
                }}
            />
            {error && (
                <p className={sejourStyles.tiny} role="alert">
                    {error}
                </p>
            )}
        </Stack>
    );
}
