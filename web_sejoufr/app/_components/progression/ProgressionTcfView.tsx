"use client";

import Link from "next/link";
import {Suspense} from "react";
import {useSearchParams} from "next/navigation";
import {
    Card,
    MicroNote,
    PanelHead,
    ProgressDomainCard,
    ProgressGlobalExamRow,
    ProgressHero,
    ProgressStatGrid,
    ProgressStatTile,
    sejourStyles,
    type ProgressChip,
} from "@/app/_components/sejour/SejourKit";
import {progressionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    PROGRESSION_ERROR,
    PROGRESSION_GLOBAL_CTA_HREF,
    PROGRESSION_SANS_EXAMEN,
    PROGRESSION_VIDE,
    PROGRESSION_VOIR,
    TCF_BACK_LABEL,
    TCF_CARTE_SUB,
    TCF_CTA,
    TCF_EPREUVES_SUB,
    TCF_EPREUVES_TITLE,
    TCF_HERO_LABEL,
    TCF_HINT,
    TCF_LEAD,
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
    TCF_TITLE,
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
} from "@/lib/progression";
import {situationIcon} from "@/lib/situation-icons";
import type {ProgressionTcfDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionFrame, ProgressionSectionHead} from "./ProgressionFrame";

/**
 * **La progression globale TCF** — maquette `progression_global_tcf.html`.
 *
 * Lit `GET /api/me/progression/tcf[?tous=true]`. 🛑 **Aucun score global**
 * (D6) : la carte de tête porte le PALIER global actuel (le plancher servi),
 * le dernier examen complet et l'évolution de palier — servis. Les quatre
 * cartes sont le résumé de chaque épreuve, le même record que l'en-tête de
 * l'écran épreuve. Les examens complets : 3 derniers, puis tous avec
 * `?tous=true` (D8).
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
    const {status} = useAuth();
    const tous = useSearchParams().get("tous") === "true";
    const query = useCachedData<ProgressionTcfDto>(
        status === "authenticated" ? progressionApi.tcfKey(tous) : null,
        () => progressionApi.tcf(tous),
        {errorMessage: PROGRESSION_ERROR},
    );
    const dto = query.data;

    return (
        <ProgressionFrame
            backHref="/dashboard?module=TCF"
            backLabel={TCF_BACK_LABEL}
            cta={dto ? {label: TCF_CTA, href: PROGRESSION_GLOBAL_CTA_HREF, locked: dto.cta.locked} : null}
            title={TCF_TITLE}
            lead={TCF_LEAD}
            paywallModule="INTEGRAL"
            screen="progression_tcf"
        >
            {dto ? (
                <TcfContenu dto={dto} tous={tous}/>
            ) : (
                <ProgressionEtat error={query.error} onRetry={query.reload}/>
            )}
        </ProgressionFrame>
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
