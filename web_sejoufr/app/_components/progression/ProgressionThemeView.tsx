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
    PROGRESSION_CIVIQUE_HREF,
    PROGRESSION_ERROR,
    PROGRESSION_SANS_EXAMEN_THEME,
    PROGRESSION_SCORE_LABEL,
    PROGRESSION_TEMPS_LABEL,
    PROGRESSION_VOIR,
    THEME_BACK_LABEL,
    THEME_COURBE_SUB,
    THEME_COURBE_TITLE,
    THEME_CTA,
    THEME_FOOT,
    THEME_HERO_LABEL,
    THEME_INTROUVABLE,
    THEME_LEAD,
    THEME_LISTE_SUB,
    THEME_LISTE_TITLE,
    THEME_MEILLEUR_LABEL,
    THEME_NOMBRE_LABEL,
    THEME_NOMBRE_SUB,
    THEME_VIDE,
    progressionBandeEtendue,
    progressionBandeLabel,
    progressionBandeTon,
    progressionDateCourte,
    progressionDateLongue,
    progressionDuree,
    progressionEchelleNote,
    progressionEcart,
    progressionEtatLabel,
    progressionEtatTon,
    progressionNombre,
    progressionRapportHref,
    progressionScore,
    progressionSensTon,
    progressionSeuilLabel,
    progressionSeuilVerdict,
    progressionTaux,
    progressionThemeCtaHref,
    progressionUnite,
    progressionValeur,
    themeExamenTitre,
    themeMeilleurSub,
    themeTitre,
} from "@/lib/progression";
import {themeSlug} from "@/lib/themes";
import type {ProgressionCiviqueDto, ProgressionThemeDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {ProgressionEtat, ProgressionFrame} from "./ProgressionFrame";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * **La progression d'UN thème civique** — maquette `progression_theme_civique.html`.
 *
 * Lit `GET /api/me/progression/civique/themes/{themeId}` : les seuls examens
 * de THÈME (20 Q, D10), l'échelle /20 et ses trois bandes servies (Faible ·
 * À renforcer · Solide), le seuil 16 servi, et l'état du DERNIER EXAMEN DU
 * THÈME avec sa phrase de provenance servie (D13 : ce n'est pas l'état de
 * l'Accueil, qui vient du diagnostic).
 *
 * Le segment d'URL est le slug du thème (`themeSlug(code)`), comme toutes les
 * routes de thème du web ; un UUID est accepté tel quel. Le slug se résout sur
 * la liste servie de l'écran global (en cache quand on en vient).
 *
 * 🛑 Miroir de `ProgressionThemeScreen` côté mobile, brique pour brique.
 */
export function ProgressionThemeView() {
    const params = useParams<{theme: string}>();
    const ref = params?.theme ?? "";
    const {status} = useAuth();
    const direct = UUID.test(ref);
    const liste = useCachedData<ProgressionCiviqueDto>(
        status === "authenticated" && !direct ? progressionApi.civiqueKey(false) : null,
        () => progressionApi.civique(false),
        {errorMessage: PROGRESSION_ERROR},
    );
    const themeId = direct
        ? ref
        : liste.data?.themes.find((t) => themeSlug(t.code) === ref)?.themeId ?? null;
    const introuvable = !direct && liste.data !== undefined && themeId === null;

    const query = useCachedData<ProgressionThemeDto>(
        status === "authenticated" && themeId ? progressionApi.themeKey(themeId) : null,
        () => progressionApi.theme(themeId as string),
        {errorMessage: PROGRESSION_ERROR},
    );
    const dto = query.data;

    return (
        <ProgressionFrame
            backHref={PROGRESSION_CIVIQUE_HREF}
            backLabel={THEME_BACK_LABEL}
            cta={dto ? {label: THEME_CTA, href: progressionThemeCtaHref(dto.code), locked: dto.cta.locked} : null}
            title={dto ? themeTitre(dto.label) : THEME_BACK_LABEL}
            lead={THEME_LEAD}
            paywallModule="CIVIQUE"
            screen="progression_theme"
        >
            {dto ? (
                <ThemeContenu dto={dto}/>
            ) : introuvable ? (
                <ProgressionEtat error={THEME_INTROUVABLE}/>
            ) : (
                <ProgressionEtat
                    error={liste.error ?? query.error}
                    onRetry={liste.error ? liste.reload : query.reload}
                />
            )}
        </ProgressionFrame>
    );
}

function ThemeContenu({dto}: {dto: ProgressionThemeDto}) {
    const {echelle, resume} = dto;
    const dernier = resume.dernier;
    const chips: ProgressChip[] = [];
    const etat = progressionEtatLabel(dto.etat);
    if (etat) chips.push({label: etat, tone: progressionEtatTon(dto.etat)});
    const ecart = progressionEcart(resume.ecart, resume.sens, true);
    if (ecart) chips.push({label: ecart, tone: progressionSensTon(resume.sens)});
    const taux = progressionTaux(dernier?.taux ?? null);

    const points = [...dto.examens]
        .reverse()
        .filter((m) => m.score != null)
        .map((m) => ({
            date: progressionDateCourte(m.date),
            value: m.score as number,
            label: progressionNombre(m.score as number),
        }));

    return (
        <>
            <div className={sejourStyles.pSummary}>
                <ProgressHero
                    label={THEME_HERO_LABEL}
                    value={progressionValeur(dernier?.score ?? null)}
                    unit={dernier ? progressionUnite(echelle.max) : null}
                    chips={chips}
                    notes={dernier ? [
                        dto.etat ? dto.etatSourceLabel : null,
                        progressionSeuilVerdict(dernier, echelle.seuil),
                    ] : [PROGRESSION_SANS_EXAMEN_THEME]}
                    ring={dernier && taux != null ? {
                        ratio: dernier.taux ?? 0,
                        label: taux,
                        reached: dernier.seuilAtteint === true,
                    } : null}
                />
                <ProgressStatGrid>
                    <ProgressStatTile
                        label={THEME_MEILLEUR_LABEL}
                        value={progressionScore(resume.meilleur?.score ?? null, echelle.max)}
                        sub={themeMeilleurSub(resume.meilleur)}
                    />
                    <ProgressStatTile
                        label={THEME_NOMBRE_LABEL}
                        value={String(resume.nombre)}
                        sub={THEME_NOMBRE_SUB}
                    />
                </ProgressStatGrid>
            </div>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead title={THEME_COURBE_TITLE} sub={THEME_COURBE_SUB}/>
                {points.length > 0 ? (
                    <ProgressChart
                        min={echelle.min}
                        max={echelle.max}
                        reperes={echelle.reperes}
                        bands={echelle.bandes.map((b) => ({
                            label: progressionBandeLabel(b),
                            min: b.min,
                            max: b.max,
                            tone: progressionBandeTon(b),
                        }))}
                        seuil={echelle.seuil}
                        seuilLabel={progressionSeuilLabel(echelle.seuil)}
                        points={points}
                        note={progressionEchelleNote(echelle)}
                        ariaLabel={`${THEME_COURBE_TITLE} — ${dto.label}`}
                    />
                ) : (
                    <p className={sejourStyles.tiny}>{THEME_VIDE}</p>
                )}
                <ProgressScaleLegend
                    items={echelle.bandes.map((b) => ({
                        label: progressionBandeLabel(b),
                        range: progressionBandeEtendue(b, echelle.max),
                    }))}
                />
            </Card>

            <Card className={`${sejourStyles.pCard} ${sejourStyles.pPanel}`}>
                <PanelHead title={THEME_LISTE_TITLE} sub={THEME_LISTE_SUB}/>
                {dto.examens.length > 0 ? (
                    <div className={sejourStyles.pExamList}>
                        {dto.examens.map((m) => (
                            <ProgressExamRow
                                key={m.attemptId}
                                href={progressionRapportHref(m.rapport)}
                                title={themeExamenTitre(m.numero)}
                                date={progressionDateLongue(m.date)}
                                score={{
                                    label: PROGRESSION_SCORE_LABEL,
                                    value: progressionScore(m.score, m.max),
                                }}
                                badge={m.etat ? {
                                    label: progressionEtatLabel(m.etat) as string,
                                    tone: progressionEtatTon(m.etat),
                                } : null}
                                duration={{
                                    label: PROGRESSION_TEMPS_LABEL,
                                    value: progressionDuree(m.dureeSecondes),
                                }}
                                action={PROGRESSION_VOIR}
                            />
                        ))}
                    </div>
                ) : (
                    <p className={sejourStyles.tiny}>{THEME_VIDE}</p>
                )}
                <MicroNote>{THEME_FOOT}</MicroNote>
            </Card>
        </>
    );
}
