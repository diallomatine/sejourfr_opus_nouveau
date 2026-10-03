"use client";

import Link from "next/link";
import {Suspense, useEffect, useState} from "react";
import {useSearchParams} from "next/navigation";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {
    BlockError,
    BlockSkeleton,
    Card,
    MicroNote,
    Pad,
    PageHead,
    PanelHead,
    ProgressDomainCard,
    ProgressGlobalExamRow,
    ProgressHero,
    ProgressionHead,
    ProgressStatGrid,
    ProgressStatTile,
    SejourApp,
    Split,
    Timeline,
    sejourStyles,
    type ProgressChip,
} from "@/app/_components/sejour/SejourKit";
import {ACCUEIL_BLOCK_ERROR, ACCUEIL_RETRY, accueilPourcentage} from "@/lib/accueil";
import {dashboardApi, progressionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {MODULE_CIVIQUE_KICKER} from "@/lib/module-ecrans";
import {avancementSeriesCivique} from "@/lib/reviser";
import {
    CIVIQUE_CARTE_SUB,
    CIVIQUE_HERO_LABEL,
    CIVIQUE_HINT,
    CIVIQUE_LISTE_SUB,
    CIVIQUE_LISTE_TITLE,
    CIVIQUE_LISTE_TOUS_LINK,
    CIVIQUE_LISTE_TOUS_TITLE,
    CIVIQUE_LISTE_VIDE,
    CIVIQUE_STAT_DERNIER,
    CIVIQUE_STAT_MEILLEUR,
    CIVIQUE_STAT_NOMBRE,
    CIVIQUE_STAT_PREMIER,
    CIVIQUE_THEMES_SUB,
    CIVIQUE_THEMES_TITLE,
    CIVIQUE_DU_PARCOURS,
    CIVIQUE_EVOLUTION_SCORE_LABEL,
    CIVIQUE_EXAMENS_BLANCS_TITLE,
    CIVIQUE_MAITRISE_LABEL,
    CIVIQUE_PROGRESSION_LEAD,
    PROGRESSION_REPERES_MAX,
    PROGRESSION_TITRE,
    civiqueMeilleurScore,
    civiqueSeriesTermineesLabel,
    PROGRESSION_ERROR,
    PROGRESSION_SANS_EXAMEN_THEME,
    PROGRESSION_VIDE,
    PROGRESSION_VOIR,
    PROGRESSION_LISTE_MOINS_LINK,
    civiqueExamenTitre,
    civiqueGlobalBadge,
    civiquePart,
    progressionAnnee,
    progressionDateCourte,
    progressionDateLongue,
    progressionEcart,
    progressionEtatLabel,
    progressionEtatTon,
    progressionHref,
    progressionRapportHref,
    progressionScore,
    progressionSensTon,
    progressionSeuilVerdict,
    progressionTaux,
    progressionTermines,
    progressionThemeHref,
    progressionTousHref,
    progressionUnite,
    progressionValeur,
} from "@/lib/progression";
import {situationIcon} from "@/lib/situation-icons";
import {themeSlug} from "@/lib/themes";
import type {DashboardCategoryStat, DashboardSummaryResponse, ProgressionCiviqueDto, ProgressionMesureDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionSectionHead} from "./ProgressionFrame";

/**
 * **La progression civique globale** — Navigation v2, phase 4 (maquette
 * `docs/redesign/sejourfr-navigation-web.html`, `#civique-progression`), puis
 * les blocs existants (maquette `progression_global_civique.html`), tous
 * gardés.
 *
 * Ordre : en-tête → `Split` : à gauche « Maîtrise globale » (NOUVEAU : le %
 * du parcours par `avancementSeriesCivique`, la fonction unique — 6ᵉ
 * emplacement du même nombre), puis le héros /40, les tuiles, les cartes de
 * thème et la liste des examens ; à droite la frise des taux servis des
 * derniers examens globaux (aucun ⇒ état vide). Pas de « Par thème » : les
 * cartes de thème le disent déjà.
 *
 * Lit `GET /api/me/progression/civique[?tous=true]` : les examens GLOBAUX
 * (40 Q, hors diagnostic), leur échelle /40 et son seuil servis, l'état et
 * le verdict de seuil servis ; les 5 thèmes résumés sur leurs seuls examens de
 * thème (D10) ; les parts par thème d'un examen global en « x / n posées »
 * (D11).
 *
 * 🛑 Miroir de `ProgressionCiviqueScreen` côté mobile, brique pour brique.
 */
export function ProgressionCiviqueView() {
    return (
        <Suspense fallback={null}>
            <CiviqueScoped/>
        </Suspense>
    );
}

/** Les séries par thème : `GET /api/me/dashboard` (mémo 30 s, partagé). */
function useSeriesParTheme(actif: boolean) {
    const [state, setState] = useState<{data: DashboardSummaryResponse | null; error: boolean}>({data: null, error: false});
    const [tentative, setTentative] = useState(0);
    useEffect(() => {
        if (!actif) return;
        let vivant = true;
        dashboardApi
            .summaryCached()
            .then((data) => {
                if (vivant) setState({data, error: false});
            })
            .catch(() => {
                if (vivant) setState((s) => ({data: s.data, error: true}));
            });
        return () => {
            vivant = false;
        };
    }, [actif, tentative]);
    return {
        themes: state.data?.civique ?? null,
        error: state.error,
        reload: () => {
            setState((s) => ({data: s.data, error: false}));
            setTentative((n) => n + 1);
        },
    };
}

function CiviqueScoped() {
    const {status} = useAuth();
    const tous = useSearchParams().get("tous") === "true";
    const actif = status === "authenticated";
    const query = useCachedData<ProgressionCiviqueDto>(
        actif ? progressionApi.civiqueKey(tous) : null,
        () => progressionApi.civique(tous),
        {errorMessage: PROGRESSION_ERROR},
    );
    const series = useSeriesParTheme(actif);
    useAppBarBack({fallbackHref: "/dashboard"});
    const dto = query.data;

    return (
        <SejourApp className={sejourStyles.home}>
            <Pad>
                <PageHead
                    kicker={MODULE_CIVIQUE_KICKER}
                    tone="civique"
                    title={PROGRESSION_TITRE}
                    subtitle={CIVIQUE_PROGRESSION_LEAD}
                />
            </Pad>
            <div className={sejourStyles.pageBody}>
                <Split
                    main={(
                        <>
                            <Pad>
                                <MaitriseGlobale themes={series.themes} error={series.error} onRetry={series.reload}/>
                            </Pad>
                            <Pad>
                                <div className={`${sejourStyles.pScreen} ${sejourStyles.pageBody}`}>
                                    {dto ? (
                                        <CiviqueContenu dto={dto} tous={tous}/>
                                    ) : (
                                        <ProgressionEtat error={query.error} onRetry={query.reload}/>
                                    )}
                                </div>
                            </Pad>
                        </>
                    )}
                    side={(
                        <Pad>
                            <div className={sejourStyles.splitSide}>
                                {dto ? <EvolutionScore dto={dto}/> : null}
                            </div>
                        </Pad>
                    )}
                />
            </div>
        </SejourApp>
    );
}

/**
 * **« Maîtrise globale »** — le pourcentage du parcours en séries
 * (`avancementSeriesCivique`, la fonction unique) et le nombre de séries
 * terminées, avec la barre du module. Bloc à états propres.
 */
function MaitriseGlobale({themes, error, onRetry}: {
    themes: DashboardCategoryStat[] | null;
    error: boolean;
    onRetry: () => void;
}) {
    if (!themes) {
        return error
            ? <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={onRetry}/>
            : <BlockSkeleton height={130}/>;
    }
    const avancement = avancementSeriesCivique(themes);
    return (
        <ProgressionHead
            module="civique"
            label={CIVIQUE_MAITRISE_LABEL}
            primary={{value: accueilPourcentage(avancement.pourcentage), label: CIVIQUE_DU_PARCOURS}}
            secondary={{value: String(avancement.terminees), label: civiqueSeriesTermineesLabel(avancement.terminees)}}
            progress={avancement.pourcentage / 100}
        />
    );
}

/**
 * La frise des taux servis des derniers examens globaux, du plus ancien au
 * plus récent ; « Meilleur score » et « au-dessus du seuil » seulement sur
 * `seuilAtteint` servi. Aucun examen ⇒ la frise disparaît, l'invitation reste.
 */
function EvolutionScore({dto}: {dto: ProgressionCiviqueDto}) {
    const reperes = dto.examens
        .slice(0, PROGRESSION_REPERES_MAX)
        .map(({mesure}) => progressionTaux(mesure.taux))
        .filter((taux): taux is string => taux !== null)
        .reverse();
    return (
        <Timeline
            module="civique"
            label={`${CIVIQUE_EXAMENS_BLANCS_TITLE} · ${CIVIQUE_EVOLUTION_SCORE_LABEL.toLowerCase()}`}
            steps={reperes}
            caption={civiqueMeilleurScore(dto.global.meilleur) ?? CIVIQUE_LISTE_VIDE}
        />
    );
}

/** « 29 / 40 » + l'état servi, sous un meilleur / premier résultat. */
function mesureStat(mesure: ProgressionMesureDto | null) {
    return {
        value: progressionScore(mesure?.score ?? null, mesure?.max ?? 0),
        sub: progressionEtatLabel(mesure?.etat ?? null),
    };
}

function CiviqueContenu({dto, tous}: {dto: ProgressionCiviqueDto; tous: boolean}) {
    const {echelle, global} = dto;
    const dernier = global.dernier;
    const chips: ProgressChip[] = [];
    const etat = progressionEtatLabel(dernier?.etat ?? null);
    if (etat && dernier) chips.push({label: etat, tone: progressionEtatTon(dernier.etat)});
    const ecart = progressionEcart(global.ecart, global.sens, true);
    if (ecart) chips.push({label: ecart, tone: progressionSensTon(global.sens)});
    const taux = progressionTaux(dernier?.taux ?? null);
    const meilleur = mesureStat(global.meilleur);
    const premier = mesureStat(global.premier);

    return (
        <>
            <div className={sejourStyles.pOverview}>
                <ProgressHero
                    label={CIVIQUE_HERO_LABEL}
                    value={progressionValeur(dernier?.score ?? null)}
                    unit={dernier ? progressionUnite(echelle.max) : null}
                    chips={chips}
                    notes={[progressionSeuilVerdict(dernier, echelle.seuil)]}
                    ring={dernier && taux != null ? {
                        ratio: dernier.taux ?? 0,
                        label: taux,
                        reached: dernier.seuilAtteint === true,
                    } : null}
                />
                <ProgressStatGrid boxed>
                    <ProgressStatTile
                        label={CIVIQUE_STAT_NOMBRE}
                        value={String(global.nombre)}
                        sub={progressionTermines(global.nombre)}
                    />
                    <ProgressStatTile label={CIVIQUE_STAT_MEILLEUR} value={meilleur.value} sub={meilleur.sub}/>
                    <ProgressStatTile label={CIVIQUE_STAT_PREMIER} value={premier.value} sub={premier.sub}/>
                    <ProgressStatTile
                        label={CIVIQUE_STAT_DERNIER}
                        value={dernier ? progressionDateCourte(dernier.date) : PROGRESSION_VIDE}
                        sub={dernier ? progressionAnnee(dernier.date) : null}
                    />
                </ProgressStatGrid>
            </div>

            <ProgressionSectionHead title={CIVIQUE_THEMES_TITLE} sub={CIVIQUE_THEMES_SUB}/>
            <div className={sejourStyles.pDomainGrid}>
                {dto.themes.map((t) => {
                    const d = t.resume.dernier;
                    const pill = progressionEtatLabel(d?.etat ?? null);
                    const delta = progressionEcart(t.resume.ecart, t.resume.sens);
                    return (
                        <ProgressDomainCard
                            key={t.themeId}
                            href={progressionThemeHref(themeSlug(t.code))}
                            icon={situationIcon(t.code)}
                            title={t.label}
                            sub={CIVIQUE_CARTE_SUB}
                            value={progressionValeur(d?.score ?? null)}
                            unit={progressionUnite(t.echelle.max)}
                            pill={pill && d ? {label: pill, tone: progressionEtatTon(d.etat)} : null}
                            delta={delta ? {label: delta, tone: progressionSensTon(t.resume.sens)} : null}
                            serie={t.resume.serie}
                            empty={d ? null : PROGRESSION_SANS_EXAMEN_THEME}
                        />
                    );
                })}
            </div>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead title={tous ? CIVIQUE_LISTE_TOUS_TITLE : CIVIQUE_LISTE_TITLE} sub={CIVIQUE_LISTE_SUB}/>
                {dto.examens.length > 0 ? (
                    <div className={sejourStyles.pExamList}>
                        {dto.examens.map(({mesure, parTheme}) => (
                            <ProgressGlobalExamRow
                                key={mesure.attemptId}
                                href={progressionRapportHref(mesure.rapport)}
                                title={civiqueExamenTitre(mesure.numero)}
                                date={progressionDateLongue(mesure.date)}
                                parts={parTheme.map((p) => ({
                                    label: p.label,
                                    value: civiquePart(p.bonnes, p.posees),
                                }))}
                                badge={{label: civiqueGlobalBadge(mesure), tone: progressionEtatTon(mesure.etat)}}
                                action={PROGRESSION_VOIR}
                            />
                        ))}
                    </div>
                ) : (
                    <p className={sejourStyles.tiny}>{CIVIQUE_LISTE_VIDE}</p>
                )}
                {!tous && global.nombre > dto.examens.length ? (
                    <Link href={progressionTousHref("CIVIQUE")} className={`${sejourStyles.link} ${sejourStyles.pMore}`}>
                        {CIVIQUE_LISTE_TOUS_LINK}
                    </Link>
                ) : null}
                {tous ? (
                    <Link href={progressionHref("CIVIQUE")} className={`${sejourStyles.link} ${sejourStyles.pMore}`}>
                        {PROGRESSION_LISTE_MOINS_LINK}
                    </Link>
                ) : null}
                <MicroNote>{CIVIQUE_HINT}</MicroNote>
            </Card>
        </>
    );
}
