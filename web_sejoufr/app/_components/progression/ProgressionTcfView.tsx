"use client";

import Link from "next/link";
import {Suspense} from "react";
import {useSearchParams} from "next/navigation";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {
    Badge,
    BlockError,
    BlockSkeleton,
    Card,
    LevelList,
    LevelRow,
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
    Section,
    SejourApp,
    Split,
    Timeline,
    sejourStyles,
    type ProgressChip,
} from "@/app/_components/sejour/SejourKit";
import {ACCUEIL_BLOCK_ERROR, ACCUEIL_RETRY} from "@/lib/accueil";
import {PROGRESS_CACHE_PREFIX, progressApi, progressionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {etatEpreuveTcf} from "@/lib/etats-servis";
import {MODULE_TCF_KICKER} from "@/lib/module-ecrans";
import {TCF_EPREUVES_OFFICIELLES} from "@/lib/tcf-epreuves";
import {
    PROGRESSION_ERROR,
    PROGRESSION_SANS_EXAMEN,
    PROGRESSION_VIDE,
    PROGRESSION_VOIR,
    TCF_CARTE_SUB,
    TCF_EPREUVES_SUB,
    TCF_EPREUVES_TITLE,
    TCF_HERO_LABEL,
    TCF_HINT,
    PROGRESSION_LISTE_MOINS_LINK,
    TCF_LISTE_SUB,
    TCF_LISTE_TITLE,
    TCF_LISTE_TOUS_LINK,
    TCF_LISTE_TOUS_SUB,
    TCF_LISTE_TOUS_TITLE,
    TCF_LISTE_VIDE,
    TCF_NIVEAU_INCONNU_NOTE,
    TCF_STAT_DERNIER,
    TCF_STAT_MEILLEUR,
    TCF_STAT_NOMBRE,
    TCF_STAT_PREMIER,
    PROGRESSION_REPERES_MAX,
    PROGRESSION_TITRE,
    TCF_DERNIERS_REPERES_LABEL,
    TCF_EVOLUTION_TITLE,
    TCF_NIVEAU_ACTUEL_LABEL,
    TCF_OBJECTIF_GLOBAL_LABEL,
    TCF_OBJECTIF_LABEL,
    TCF_PAR_COMPETENCE_TITLE,
    examenBlancTitre,
    progressionAnnee,
    progressionDateCourte,
    progressionEcart,
    progressionEpreuveHref,
    progressionEvolutionPalier,
    progressionHref,
    progressionNiveauPill,
    progressionPalier,
    progressionRapportHref,
    progressionScore,
    progressionSensTon,
    progressionTermines,
    progressionTousHref,
    progressionUnite,
    progressionValeur,
    tcfDernierComplet,
    tcfEpreuveMark,
    tcfEpreuveNom,
    tcfExamenDate,
    tcfExamenSub,
    tcfNiveauPartielNote,
    tcfMeilleurNiveauObserve,
    tcfProgressionLead,
    tcfVersCible,
} from "@/lib/progression";
import {situationIcon} from "@/lib/situation-icons";
import type {ProgressDto, ProgressionTcfDto, TargetLevel} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionSectionHead} from "./ProgressionFrame";
import {ProchaineEtapeTcf} from "./ProchaineEtape";

/**
 * **La progression globale TCF** — Navigation v2, phase 4 (maquette
 * `docs/redesign/sejourfr-navigation-web.html`, `#tcf-progression`), puis les
 * blocs existants (maquette `progression_global_tcf.html`), tous gardés.
 *
 * Ordre : en-tête → `Split` : à gauche « Objectif global » (niveau actuel →
 * objectif, **sans barre** à côté des niveaux), « Par compétence » (état
 * SERVI `StatutObjectif`, `etatEpreuveTcf`), « Évolution » (paliers servis
 * des derniers examens complets, sans « + »), puis le héros, les tuiles, les
 * cartes d'épreuve et la liste des examens ; à droite « Prochaine étape »
 * (`journey.current`, geste de l'Accueil). « Analyse IA » : absente, pas de
 * donnée (X11).
 *
 * Lit `GET /api/me/progression/tcf[?tous=true]`. 🛑 **Aucun score global**
 * (D6). Le niveau cible est `AuthenticatedUser.targetLevel` (X13).
 *
 * 🛑 Miroir de `ProgressionTcfScreen` côté mobile, brique pour brique.
 */
export function ProgressionTcfView() {
    /* `useSearchParams` impose une frontière de Suspense. */
    return (
        <Suspense fallback={null}>
            <TcfScoped/>
        </Suspense>
    );
}

function TcfScoped() {
    const {user, status} = useAuth();
    const tous = useSearchParams().get("tous") === "true";
    const actif = status === "authenticated";
    const query = useCachedData<ProgressionTcfDto>(
        actif ? progressionApi.tcfKey(tous) : null,
        () => progressionApi.tcf(tous),
        {errorMessage: PROGRESSION_ERROR},
    );
    /* Les états par épreuve : la même lecture (en cache) que l'Accueil. */
    const progres = useCachedData<ProgressDto>(
        actif ? `${PROGRESS_CACHE_PREFIX}current` : null,
        () => progressApi.get(),
    );
    useAppBarBack({fallbackHref: "/dashboard"});
    const dto = query.data;
    const cible = user?.targetLevel ?? null;

    return (
        <SejourApp className={sejourStyles.home}>
            <Pad>
                <PageHead
                    kicker={MODULE_TCF_KICKER}
                    title={PROGRESSION_TITRE}
                    subtitle={tcfProgressionLead(cible)}
                />
            </Pad>
            <div className={sejourStyles.pageBody}>
                <Split
                    main={(
                        <>
                            <Pad>
                                {dto ? (
                                    <ProgressionHead
                                        module="tcf"
                                        label={TCF_OBJECTIF_GLOBAL_LABEL}
                                        from={{value: progressionPalier(dto.niveauActuel), label: TCF_NIVEAU_ACTUEL_LABEL}}
                                        to={{value: cible ?? PROGRESSION_VIDE, label: TCF_OBJECTIF_LABEL}}
                                    />
                                ) : query.error ? null : (
                                    <BlockSkeleton height={130}/>
                                )}
                            </Pad>
                            <Section title={TCF_PAR_COMPETENCE_TITLE}>
                                <Pad>
                                    <ParCompetence progres={progres.data} error={progres.error} onRetry={progres.reload} cible={cible}/>
                                </Pad>
                            </Section>
                            {dto ? (
                                <>
                                    <Section title={TCF_EVOLUTION_TITLE}>
                                        <Pad>
                                            <Evolution dto={dto}/>
                                        </Pad>
                                    </Section>
                                    <Pad>
                                        <div className={`${sejourStyles.pScreen} ${sejourStyles.pageBody}`}>
                                            <TcfContenu dto={dto} tous={tous}/>
                                        </div>
                                    </Pad>
                                </>
                            ) : (
                                <Pad>
                                    <div className={sejourStyles.pageBody}>
                                        <ProgressionEtat error={query.error} onRetry={query.reload}/>
                                    </div>
                                </Pad>
                            )}
                        </>
                    )}
                    side={(
                        <Pad>
                            <ProchaineEtapeTcf/>
                        </Pad>
                    )}
                />
            </div>
        </SejourApp>
    );
}

/**
 * **« Par compétence »** — une ligne par épreuve officielle (miroir
 * `tcf-epreuves`) : code, palier servi (« — » sans mesure), état SERVI et son
 * point, « → {cible} » ou la coche quand l'objectif est atteint (statut
 * servi). Toute la ligne ouvre l'écran de l'épreuve.
 */
function ParCompetence({progres, error, onRetry, cible}: {
    progres: ProgressDto | undefined;
    error: string | null;
    onRetry: () => void;
    cible: TargetLevel | null;
}) {
    if (error) return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={onRetry}/>;
    if (!progres) return <BlockSkeleton height={300}/>;
    return (
        <LevelList>
            {TCF_EPREUVES_OFFICIELLES.map((code) => {
                const epreuve = progres.tcf.epreuves.find((e) => e.epreuve === code) ?? null;
                const etat = etatEpreuveTcf(epreuve);
                const atteint = epreuve?.niveau != null && epreuve.status === "TARGET_REACHED";
                return (
                    <LevelRow
                        key={code}
                        module="tcf"
                        code={tcfEpreuveMark(code)}
                        value={progressionPalier(epreuve?.niveau ?? null)}
                        state={etat}
                        trailing={atteint
                            ? <Badge tone="success" check label={etat?.label}/>
                            : cible ? tcfVersCible(cible) : null}
                        href={progressionEpreuveHref(code)}
                    />
                );
            })}
        </LevelList>
    );
}

/**
 * **« Évolution »** : les paliers servis des derniers examens complets, du
 * plus ancien au plus récent (l'ordre servi est inverse). Un examen encore
 * sans palier (évaluation en vol) n'est pas posé. Aucun examen ⇒ la frise
 * disparaît, l'invitation reste.
 */
function Evolution({dto}: {dto: ProgressionTcfDto}) {
    const meilleur = dto.examensComplets.meilleur?.niveau ?? null;
    const reperes = dto.examens
        .slice(0, PROGRESSION_REPERES_MAX)
        .filter((e) => e.niveau !== null)
        .map((e) => progressionPalier(e.niveau))
        .reverse();
    return (
        <Timeline
            module="tcf"
            label={TCF_DERNIERS_REPERES_LABEL}
            steps={reperes}
            caption={meilleur ? tcfMeilleurNiveauObserve(progressionPalier(meilleur)) : TCF_NIVEAU_INCONNU_NOTE}
        />
    );
}

function TcfContenu({dto, tous}: {dto: ProgressionTcfDto; tous: boolean}) {
    const complets = dto.examensComplets;
    const chips: ProgressChip[] = [];
    const dernierComplet = complets.dernier
        ? tcfDernierComplet(complets.dernier.niveau, complets.dernier.partiel)
        : null;
    if (dernierComplet) chips.push({label: dernierComplet, tone: "now"});
    const evolution = progressionEvolutionPalier(complets.evolution);
    if (evolution) chips.push({label: evolution, tone: progressionSensTon(complets.evolution)});

    return (
        <>
            <div className={sejourStyles.pOverview}>
                <ProgressHero
                    label={TCF_HERO_LABEL}
                    value={progressionPalier(dto.niveauActuel)}
                    chips={chips}
                    notes={[
                        dto.niveauActuel
                            ? tcfNiveauPartielNote(dto.niveauActuelEpreuves, dto.niveauActuelPartiel)
                            : TCF_NIVEAU_INCONNU_NOTE,
                    ]}
                />
                <ProgressStatGrid boxed>
                    <ProgressStatTile
                        label={TCF_STAT_NOMBRE}
                        value={String(complets.nombre)}
                        sub={progressionTermines(complets.nombre)}
                    />
                    <ProgressStatTile
                        label={TCF_STAT_MEILLEUR}
                        value={progressionPalier(complets.meilleur?.niveau ?? null)}
                        sub={complets.meilleur
                            ? tcfExamenSub(complets.meilleur.numero, complets.meilleur.date)
                            : null}
                    />
                    <ProgressStatTile
                        label={TCF_STAT_PREMIER}
                        value={progressionPalier(complets.premier?.niveau ?? null)}
                        sub={complets.premier
                            ? tcfExamenSub(complets.premier.numero, complets.premier.date)
                            : null}
                    />
                    <ProgressStatTile
                        label={TCF_STAT_DERNIER}
                        value={complets.dernier
                            ? progressionDateCourte(complets.dernier.date)
                            : PROGRESSION_VIDE}
                        sub={complets.dernier ? progressionAnnee(complets.dernier.date) : null}
                    />
                </ProgressStatGrid>
            </div>

            <ProgressionSectionHead title={TCF_EPREUVES_TITLE} sub={TCF_EPREUVES_SUB}/>
            <div className={sejourStyles.pDomainGrid}>
                {dto.epreuves.map(({epreuve, echelle, resume}) => {
                    const href = progressionEpreuveHref(epreuve);
                    if (!href) return null;
                    const dernier = resume.dernier;
                    const pill = progressionNiveauPill(dernier?.niveau ?? null);
                    const delta = progressionEcart(resume.ecart, resume.sens);
                    return (
                        <ProgressDomainCard
                            key={epreuve}
                            href={href}
                            icon={situationIcon(epreuve)}
                            title={tcfEpreuveNom(epreuve)}
                            sub={TCF_CARTE_SUB}
                            value={progressionValeur(dernier?.score ?? null)}
                            unit={progressionUnite(echelle.max)}
                            pill={pill ? {label: pill, tone: "now"} : null}
                            delta={delta ? {label: delta, tone: progressionSensTon(resume.sens)} : null}
                            serie={resume.serie}
                            empty={dernier ? null : PROGRESSION_SANS_EXAMEN}
                        />
                    );
                })}
            </div>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead
                    title={tous ? TCF_LISTE_TOUS_TITLE : TCF_LISTE_TITLE}
                    sub={tous ? TCF_LISTE_TOUS_SUB : TCF_LISTE_SUB}
                />
                {dto.examens.length > 0 ? (
                    <div className={sejourStyles.pExamList}>
                        {dto.examens.map((ex) => (
                            <ProgressGlobalExamRow
                                key={ex.attemptId}
                                href={progressionRapportHref({kind: "EXAMEN_COMPLET", attemptId: ex.attemptId})}
                                title={examenBlancTitre(ex.numero)}
                                date={tcfExamenDate(ex.date, ex.partiel, ex.epreuvesComptees)}
                                parts={ex.parEpreuve.map((p) => ({
                                    label: tcfEpreuveMark(p.epreuve),
                                    value: progressionScore(p.score, p.max),
                                }))}
                                badge={{label: progressionPalier(ex.niveau), tone: ex.niveau ? "now" : "muted"}}
                                action={PROGRESSION_VOIR}
                            />
                        ))}
                    </div>
                ) : (
                    <p className={sejourStyles.tiny}>{TCF_LISTE_VIDE}</p>
                )}
                {/* D8 : le total est servi ; le lien n'apparaît que s'il en
                    reste à montrer. */}
                {!tous && complets.nombre > dto.examens.length ? (
                    <Link href={progressionTousHref("TCF")} className={`${sejourStyles.link} ${sejourStyles.pMore}`}>
                        {TCF_LISTE_TOUS_LINK}
                    </Link>
                ) : null}
                {tous ? (
                    <Link href={progressionHref("TCF")} className={`${sejourStyles.link} ${sejourStyles.pMore}`}>
                        {PROGRESSION_LISTE_MOINS_LINK}
                    </Link>
                ) : null}
                <MicroNote>{TCF_HINT}</MicroNote>
            </Card>
        </>
    );
}
