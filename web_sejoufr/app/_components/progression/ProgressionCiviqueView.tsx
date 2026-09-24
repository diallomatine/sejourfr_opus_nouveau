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
    CIVIQUE_BACK_LABEL,
    CIVIQUE_CARTE_SUB,
    CIVIQUE_CTA,
    CIVIQUE_HERO_LABEL,
    CIVIQUE_HINT,
    CIVIQUE_LEAD,
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
    CIVIQUE_TITLE,
    PROGRESSION_ERROR,
    PROGRESSION_GLOBAL_CTA_HREF,
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
import type {ProgressionCiviqueDto, ProgressionMesureDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionFrame, ProgressionSectionHead} from "./ProgressionFrame";

/**
 * **La progression civique globale** — maquette `progression_global_civique.html`.
 *
 * Lit `GET /api/me/progression/civique[?tous=true]` : les examens GLOBAUX
 * (40 Q, hors diagnostic), leur échelle /40 et son seuil servis, l'état et
 * le verdict de seuil servis ; les 5 thèmes (et non 4) résumés sur leurs seuls
 * examens de thème (D10) ; les parts par thème d'un examen global en
 * « x / n posées » (D11).
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

function CiviqueScoped() {
    const {status} = useAuth();
    const tous = useSearchParams().get("tous") === "true";
    const query = useCachedData<ProgressionCiviqueDto>(
        status === "authenticated" ? progressionApi.civiqueKey(tous) : null,
        () => progressionApi.civique(tous),
        {errorMessage: PROGRESSION_ERROR},
    );
    const dto = query.data;

    return (
        <ProgressionFrame
            backHref="/dashboard?module=CIVIQUE"
            backLabel={CIVIQUE_BACK_LABEL}
            cta={dto ? {label: CIVIQUE_CTA, href: PROGRESSION_GLOBAL_CTA_HREF, locked: dto.cta.locked} : null}
            title={CIVIQUE_TITLE}
            lead={CIVIQUE_LEAD}
            module="CIVIQUE"
            paywallModule="CIVIQUE"
            screen="progression_civique"
        >
            {dto ? (
                <CiviqueContenu dto={dto} tous={tous}/>
            ) : (
                <ProgressionEtat error={query.error} onRetry={query.reload}/>
            )}
        </ProgressionFrame>
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
