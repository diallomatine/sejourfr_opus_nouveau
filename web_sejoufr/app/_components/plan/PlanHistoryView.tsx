"use client";

import {Suspense} from "react";
import {useSearchParams} from "next/navigation";
import {journeyApi} from "@/lib/api";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {
    BlocAccordion,
    Card,
    Hero,
    InfoNote,
    Pad,
    PanelHead,
    SejourApp,
    Stack,
    StatGrid,
    Top,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
    journeyHistoryPill,
    JOURNEY_HISTORY_EMPTY_TITLE,
    JOURNEY_HISTORY_ERROR,
    JOURNEY_HISTORY_EYEBROW,
    JOURNEY_HISTORY_FOOT_LEAD,
    JOURNEY_HISTORY_HEADLINE,
    JOURNEY_HISTORY_LEAD,
    JOURNEY_HISTORY_LOADING,
    JOURNEY_HISTORY_RETRY,
    JOURNEY_HISTORY_SECTION_SUB,
    JOURNEY_HISTORY_SECTION_TITLE,
    JOURNEY_HISTORY_TITLE,
    journeyArchiveHref,
    journeyHistoryCycleMark,
    journeyHistoryEmptyText,
    journeyHistoryFootText,
    journeyHistoryCycleMeta,
    journeyHistoryCycleTitle,
    journeyHistoryStatCycles,
    journeyHistoryStatExams,
    journeyHistoryStatSkills,
} from "@/lib/journey";
import type {JourneyHistoryDto} from "@/lib/types";

/**
 * **« Mes cycles »** (ex-« Ma progression », D16) — l'archive du parcours, derrière « Voir ma
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
 *
 * ## Le parcours affiché vient de `?module=` (P8.9, 2026-09-20)
 *
 * 🛑 **Un seul écran pour les deux parcours**, scopé comme le Plan et l'Accueil
 * le sont déjà : `?module=` est **le** mécanisme de sélection du web, et une
 * seconde route aurait été une deuxième façon de dire la même chose — ce que ce
 * chantier a passé son temps à supprimer. Le TCF reste le défaut, donc un lien
 * déjà partagé vers `/plan/progression` aboutit sur le même écran qu'avant.
 *
 * Ce qui change avec le module, et **rien d'autre** : le **mot** de l'unité
 * travaillée (compétence ⇄ unité officielle), la **mesure** de fin de cycle
 * (palier CECRL ⇄ score sur 40 rapporté au seuil de 32) et la **destination du
 * retour**. Les briques, l'ordre et les états sont les mêmes.
 *
 * ## Un cycle terminé OUVRE SA PAGE (2026-09-27)
 *
 * 🛑 **La ligne d'un cycle est un lien** (`BlocAccordion` en variante `href`)
 * vers `/plan/progression/cycle/{journeyId}` — son plan tel qu'il était, comme
 * l'écran Plan, en lecture seule (`PlanCycleArchiveView`). ⚠️ **Révoque**
 * l'accordéon déplié ici, dont le seul contenu était une carte « Examens
 * réalisés · NIVEAU A2 » **cadenassée** : un cadenas sur un cycle terminé ne
 * voulait rien dire. Une page plutôt qu'un accordéon : à 360 px, un rail
 * d'étapes et ses blocs dépliables imbriqués dans une carte de liste perdaient
 * la largeur qui rend le Plan lisible.
 *
 * Barre du haut : le menu (toujours là) et la flèche, qui remonte au Plan.
 */
export function PlanHistoryView() {
    /* `useSearchParams` impose une frontière de Suspense : elle est posée ici,
       autour du seul composant qui en a besoin. */
    return (
        <Suspense fallback={null}>
            <PlanHistoryScoped />
        </Suspense>
    );
}

function PlanHistoryScoped() {
    const {status} = useAuth();
    /* 🛑 **Le défaut est TCF**, pas une déduction : l'écran est atteint depuis
       le Plan, qui a déjà fait le choix et le porte dans son lien. */
    /* ⚠️ Pas `module` : Next interdit d'affecter cette variable (elle entre en
       collision avec le `module` de CommonJS au moment du bundling). */
    const parcours: ParcoursModule = moduleDeLUrl(useSearchParams()) ?? "TCF";
    const query = useCachedData<JourneyHistoryDto>(
        status === "authenticated"
            ? journeyApi.historyCacheKeyFor(parcours)
            : null,
        () => journeyApi.history(parcours),
        {errorMessage: JOURNEY_HISTORY_ERROR},
    );
    const history = query.data;

    return (
        <SejourApp>
            <Top title={JOURNEY_HISTORY_TITLE} backTo={planHref(parcours)} />
            <Pad>
                <Stack>
                    {/* 🛑 Le bandeau et ses compteurs restent dans TOUS les
                        états : ils sont vrais même sans cycle terminé. */}
                    <Hero
                        /* Bleu dans les deux parcours (comme le mobile) : le
                           compteur accentué de `StatGrid onHero` est en rouge
                           vif, illisible sur le dégradé civique. */
                        module="tcf"
                        label={JOURNEY_HISTORY_EYEBROW}
                        title={JOURNEY_HISTORY_HEADLINE}
                        sub={JOURNEY_HISTORY_LEAD}
                    >
                        <StatGrid
                            onHero
                            accentIndex={1}
                            stats={[
                                {
                                    value: String(history?.stats.competencesTravaillees ?? 0),
                                    label: journeyHistoryStatSkills(
                                        history?.stats.competencesTravaillees ?? 0, parcours),
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
                    </Hero>

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
                                sub={journeyHistoryEmptyText(parcours)}
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
                                    <BlocAccordion
                                        key={cycle.journeyId}
                                        href={journeyArchiveHref(cycle.journeyId, parcours)}
                                        mark={journeyHistoryCycleMark(cycle.numero)}
                                        title={journeyHistoryCycleTitle(cycle.numero)}
                                        meta={journeyHistoryCycleMeta(cycle, parcours)}
                                        status={journeyHistoryPill(cycle.finDeCycle ?? null)}
                                    />
                                ))}
                            </Stack>
                        </>
                    )}

                    <InfoNote>
                        <b>{JOURNEY_HISTORY_FOOT_LEAD}</b>
                        {journeyHistoryFootText(parcours)}
                    </InfoNote>
                </Stack>
            </Pad>
        </SejourApp>
    );
}
