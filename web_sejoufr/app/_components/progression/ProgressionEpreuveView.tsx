"use client";

import {useParams} from "next/navigation";
import {
    Card,
    MicroNote,
    PanelHead,
    ProgressChart,
    ProgressExamRow,
    ProgressHero,
    ProgressScaleLegend,
    ProgressStatGrid,
    ProgressStatTile,
    sejourStyles,
    type ProgressChip,
} from "@/app/_components/sejour/SejourKit";
import {progressionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    EPREUVE_BACK_LABEL,
    EPREUVE_COURBE_TITLE,
    EPREUVE_CTA,
    EPREUVE_HERO_LABEL,
    EPREUVE_INTROUVABLE,
    EPREUVE_LISTE_SUB,
    EPREUVE_LISTE_TITLE,
    EPREUVE_MEILLEUR_LABEL,
    EPREUVE_NOMBRE_LABEL,
    EPREUVE_NOTE_20_PORTEE,
    EPREUVE_VIDE,
    PROGRESSION_ERROR,
    PROGRESSION_PORTEE_499,
    PROGRESSION_SCORE_LABEL,
    PROGRESSION_TCF_HREF,
    PROGRESSION_TEMPS_LABEL,
    PROGRESSION_VOIR,
    epreuveCourbeSub,
    epreuveExamenDate,
    epreuveLead,
    epreuveMeilleurSub,
    epreuveNiveauActuel,
    epreuveTitre,
    examenBlancTitre,
    progressionBandeEtendue,
    progressionBandeLabel,
    progressionBandeTon,
    progressionDateCourte,
    progressionDuree,
    progressionEchelleNote,
    progressionEcart,
    progressionEpreuveCtaHref,
    progressionEpreuveFromSlug,
    progressionExamensTermines,
    progressionNiveauPill,
    progressionNombre,
    progressionPalier,
    progressionRapportHref,
    progressionScore,
    progressionSensTon,
    progressionUnite,
    progressionValeur,
} from "@/lib/progression";
import type {PlanDomainEpreuve} from "@/lib/plan-domain";
import type {ProgressionEpreuveDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionFrame} from "./ProgressionFrame";

/**
 * **La progression d'UNE épreuve TCF** — maquette `progression_epreuve_tcf.html`.
 *
 * Lit `GET /api/me/progression/tcf/{epreuve}` : ses examens blancs (épreuve
 * passée seule + la même épreuve dans un examen complet, D1), l'échelle servie
 * (CO/CE /499 SANS bande, D2 ; EE/EO /20 avec les bandes officielles, D3), le
 * résumé (dernier, meilleur, écart, sens), le niveau de l'Accueil (D4) et le
 * verrou du CTA (D20).
 *
 * 🛑 Rien n'est recalculé : ce composant écrit des faits servis.
 * 🛑 Miroir de `ProgressionEpreuveScreen` côté mobile, brique pour brique.
 */
export function ProgressionEpreuveView() {
    const params = useParams<{epreuve: string}>();
    const epreuve = progressionEpreuveFromSlug(params?.epreuve ?? "");
    if (!epreuve) {
        return (
            <ProgressionFrame
                backHref={PROGRESSION_TCF_HREF}
                backLabel={EPREUVE_BACK_LABEL}
                cta={null}
                title={EPREUVE_BACK_LABEL}
                paywallModule="INTEGRAL"
                screen="progression_epreuve"
            >
                <ProgressionEtat error={EPREUVE_INTROUVABLE}/>
            </ProgressionFrame>
        );
    }
    return <EpreuveScoped epreuve={epreuve}/>;
}

function EpreuveScoped({epreuve}: {epreuve: PlanDomainEpreuve}) {
    const {status} = useAuth();
    const query = useCachedData<ProgressionEpreuveDto>(
        status === "authenticated" ? progressionApi.epreuveKey(epreuve) : null,
        () => progressionApi.epreuve(epreuve),
        {errorMessage: PROGRESSION_ERROR},
    );
    const dto = query.data;

    return (
        <ProgressionFrame
            backHref={PROGRESSION_TCF_HREF}
            backLabel={EPREUVE_BACK_LABEL}
            cta={dto ? {
                label: EPREUVE_CTA,
                href: progressionEpreuveCtaHref(epreuve),
                locked: dto.cta.locked,
            } : null}
            title={epreuveTitre(epreuve)}
            lead={epreuveLead(epreuve)}
            paywallModule="INTEGRAL"
            screen="progression_epreuve"
        >
            {dto ? (
                <EpreuveContenu dto={dto} epreuve={epreuve}/>
            ) : (
                <ProgressionEtat error={query.error} onRetry={query.reload}/>
            )}
        </ProgressionFrame>
    );
}

function EpreuveContenu({dto, epreuve}: {dto: ProgressionEpreuveDto; epreuve: PlanDomainEpreuve}) {
    const {echelle, resume} = dto;
    const dernier = resume.dernier;
    const chips: ProgressChip[] = [];
    const pill = progressionNiveauPill(dernier?.niveau ?? null);
    if (pill) chips.push({label: pill, tone: "now"});
    const ecart = progressionEcart(resume.ecart, resume.sens, true);
    if (ecart) chips.push({label: ecart, tone: progressionSensTon(resume.sens)});

    /* La courbe : les examens servis du plus ancien au plus récent, ceux qui
       portent un score (un score `null` n'est pas un point à zéro). */
    const points = [...dto.examens]
        .reverse()
        .filter((m) => m.score != null)
        .map((m) => ({
            date: progressionDateCourte(m.date),
            value: m.score as number,
            label: progressionNombre(m.score as number),
        }));
    const bandes = echelle.bandes.map((b) => ({
        label: progressionBandeLabel(b),
        min: b.min,
        max: b.max,
        tone: progressionBandeTon(b),
    }));
    const nom = epreuveTitre(epreuve);
    const note20 = echelle.unite === "NOTE_20";

    return (
        <>
            <div className={sejourStyles.pSummary}>
                <ProgressHero
                    label={EPREUVE_HERO_LABEL}
                    value={progressionValeur(dernier?.score ?? null)}
                    unit={dernier ? progressionUnite(echelle.max) : null}
                    chips={chips}
                    notes={[epreuveNiveauActuel(dto.niveauActuel)]}
                />
                <ProgressStatGrid>
                    <ProgressStatTile
                        label={EPREUVE_MEILLEUR_LABEL}
                        value={progressionScore(resume.meilleur?.score ?? null, echelle.max)}
                        sub={epreuveMeilleurSub(resume.meilleur)}
                    />
                    <ProgressStatTile
                        label={EPREUVE_NOMBRE_LABEL}
                        value={String(resume.nombre)}
                        sub={progressionExamensTermines(resume.nombre)}
                    />
                </ProgressStatGrid>
            </div>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead title={EPREUVE_COURBE_TITLE} sub={epreuveCourbeSub(epreuve)}/>
                {points.length > 0 ? (
                    <ProgressChart
                        min={echelle.min}
                        max={echelle.max}
                        reperes={echelle.reperes}
                        bands={bandes}
                        seuil={echelle.seuil}
                        points={points}
                        note={progressionEchelleNote(echelle)}
                        ariaLabel={`${EPREUVE_COURBE_TITLE} — ${nom}`}
                    />
                ) : (
                    <p className={sejourStyles.tiny}>{EPREUVE_VIDE}</p>
                )}
                {bandes.length > 0 ? (
                    <ProgressScaleLegend
                        items={echelle.bandes.map((b) => ({
                            label: progressionBandeLabel(b),
                            range: progressionBandeEtendue(b, echelle.max),
                        }))}
                    />
                ) : (
                    /* D2 : pas de bande en CO/CE — la note de portée prend la
                       place de la légende. */
                    <MicroNote>{PROGRESSION_PORTEE_499}</MicroNote>
                )}
            </Card>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead title={EPREUVE_LISTE_TITLE} sub={EPREUVE_LISTE_SUB}/>
                {dto.examens.length > 0 ? (
                    <div className={sejourStyles.pExamList}>
                        {dto.examens.map((m) => (
                            <ProgressExamRow
                                key={`${m.attemptId}-${m.numero}`}
                                href={progressionRapportHref(m.rapport, epreuve)}
                                title={examenBlancTitre(m.numero)}
                                date={epreuveExamenDate(m)}
                                score={{
                                    label: PROGRESSION_SCORE_LABEL,
                                    value: progressionScore(m.score, m.max),
                                }}
                                badge={m.niveau ? {label: progressionPalier(m.niveau), tone: "now"} : null}
                                duration={{
                                    label: PROGRESSION_TEMPS_LABEL,
                                    value: progressionDuree(m.dureeSecondes),
                                }}
                                action={PROGRESSION_VOIR}
                            />
                        ))}
                    </div>
                ) : (
                    <p className={sejourStyles.tiny}>{EPREUVE_VIDE}</p>
                )}
                {note20 ? <MicroNote>{EPREUVE_NOTE_20_PORTEE}</MicroNote> : null}
            </Card>
        </>
    );
}
