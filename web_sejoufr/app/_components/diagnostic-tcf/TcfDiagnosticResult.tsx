"use client";

/**
 * **Le résultat du diagnostic TCF complet (4 épreuves).**
 *
 * Ordre des blocs, imposé par la spec : niveau global → niveau par épreuve →
 * (progression, s'il y en a une) → ce qui bloque → rassurance → le plan.
 *
 * 🛑 **Aucun résultat n'est masqué derrière le paywall.** « Le paywall porte
 * sur le plan, pas sur le constat » : le DTO ne porte aucun `locked`, et cet
 * écran n'en invente pas.
 *
 * 🛑 **Une épreuve non évaluée est NOMMÉE, pas escamotée.** `niveau: null`
 * signifie « on n'a pas mesuré », jamais « A1 » : afficher un palier plancher
 * serait rendre un verdict que personne n'a rendu (V040/V041/V042).
 *
 * 🛑 **Aucun style local.** Tout l'habillage vient du kit partagé
 * `app/_components/sejour/`.
 */

import {useCallback, useEffect, useState} from "react";
import {BookOpen, Check, Headphones, Mic, PenLine, type LucideIcon} from "lucide-react";
import {ApiException, tcfDiagnosticApi} from "@/lib/api";
import {EPREUVE_PRESENTATION} from "@/lib/exam-durations";
import {
    Card,
    Cta,
    ExamRow,
    LevelTrack,
    MiniPlan,
    NoteCard,
    Pad,
    Prio,
    SejourApp,
    Section,
    Stack,
    Top,
    sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {
    NIVEAU_NON_EVALUE,
    TCF_DIAGNOSTIC_ESTIMATION_NOTE,
    TCF_DIAGNOSTIC_PLAN_CTA,
    TCF_DIAGNOSTIC_RASSURANCE_TITLE,
    analyseGlobale,
    blocageTitle,
    competencesCibleesLine,
    epreuveMention,
    evolutionLabel,
    evolutionTone,
    formatJourCourt,
    levelTrackPosition,
    planPretTitle,
    prioriteCourte,
    prioriteLibelle,
    prioritePastille,
    prioritePhrase,
    prioriteTag,
    progressionTitle,
    rassuranceText,
} from "@/lib/tcf-diagnostic";
import {niveauCecrlShort} from "@/lib/types";
import type {EpreuveType, NiveauCecrl, TcfDiagnosticResultDto} from "@/lib/types";

const BACK_HREF = "/dashboard";
const TOP_KICKER = "TCF IRN";
const TOP_TITLE = "Mon diagnostic TCF";
const TOP_BADGE = "Diagnostic complet";
const HERO_LABEL = "Votre niveau estimé";
const HERO_GOAL = "Objectif :";
const LEVEL_UNKNOWN = "—";
const PLAN_HREF = "/plan";
const EPREUVES_TITLE = "Votre niveau par épreuve";
const ERROR_FALLBACK = "Impossible de charger votre résultat.";
const RETRY = "Réessayer";

/** L'icône d'une épreuve. La seule table d'icônes de cet écran : le reste du
 *  libellé (nom, volume) vient d'`EPREUVE_PRESENTATION`. */
const EPREUVE_ICON: Record<"TCF_CO" | "TCF_CE" | "TCF_EE" | "TCF_EO", LucideIcon> = {
    TCF_CO: Headphones,
    TCF_CE: BookOpen,
    TCF_EE: PenLine,
    TCF_EO: Mic,
};

/**
 * La forme COURTE d'une épreuve, pour le mini-plan (« EO · Tâche 3 »).
 *
 * 🛑 Elle ne remplace pas `EPREUVE_PRESENTATION` : le libellé complet reste
 * celui du tableau des épreuves. Ici la place manque, et « EO » se lit aussi
 * bien dans une liste de trois lignes qu'on parcourt du regard.
 */
const EPREUVE_COURTE: Record<"TCF_CO" | "TCF_CE" | "TCF_EE" | "TCF_EO", string> = {
    TCF_CO: "CO",
    TCF_CE: "CE",
    TCF_EE: "EE",
    TCF_EO: "EO",
};

function epreuveLabel(epreuve: string): string {
    return (
        EPREUVE_PRESENTATION[epreuve as keyof typeof EPREUVE_PRESENTATION]?.label ?? epreuve
    );
}

function epreuveIcon(epreuve: string): LucideIcon {
    return EPREUVE_ICON[epreuve as keyof typeof EPREUVE_ICON] ?? BookOpen;
}

/** Le liseré de rang de la carte `Prio`, borné aux trois teintes du kit. Le
 *  serveur plafonne déjà `priorites` à trois ; ceci ne fait que le typer. */
function rangPrio(rang: number): 1 | 2 | 3 {
    return rang <= 1 ? 1 : rang === 2 ? 2 : 3;
}

type Etat =
    | {kind: "loading"}
    | {kind: "pret"; resultat: TcfDiagnosticResultDto}
    | {kind: "erreur"; message: string};

export function TcfDiagnosticResult({sessionId}: {sessionId: string}) {
    const [etat, setEtat] = useState<Etat>({kind: "loading"});

    const charger = useCallback(async () => {
        try {
            setEtat({kind: "pret", resultat: await tcfDiagnosticApi.readResult(sessionId)});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message: e instanceof ApiException ? e.message : ERROR_FALLBACK,
            });
        }
    }, [sessionId]);

    useEffect(() => {
        void charger();
    }, [charger]);

    if (etat.kind === "loading") {
        return (
            <SejourApp>
                <Top backTo={BACK_HREF} kicker={TOP_KICKER} title={TOP_TITLE} />
                <Pad>
                    <Card variant="hero">
                        <p className={styles.label}>{HERO_LABEL}</p>
                        <p className={styles.level} aria-busy>
                            {LEVEL_UNKNOWN}
                        </p>
                    </Card>
                </Pad>
            </SejourApp>
        );
    }

    if (etat.kind === "erreur") {
        return (
            <SejourApp>
                <Top backTo={BACK_HREF} kicker={TOP_KICKER} title={TOP_TITLE} />
                <Pad>
                    <Stack>
                        <Card variant="warn">
                            <p className={styles.insight} role="alert">
                                {etat.message}
                            </p>
                        </Card>
                        <Cta variant="line" onClick={() => void charger()}>
                            {RETRY}
                        </Cta>
                    </Stack>
                </Pad>
            </SejourApp>
        );
    }

    const r = etat.resultat;
    const track = levelTrackPosition(r.niveauGlobal, r.cible);
    const analyse = analyseGlobale(r);
    const nonEvaluees = r.epreuves.filter((e) => e.niveau === null);

    /**
     * La mention d'une épreuve. Fermée sur `r` pour rester lisible dans le
     * JSX ; toute la règle vit dans `lib/tcf-diagnostic.ts`, partagée avec le
     * mobile.
     */
    const mention = (e: {epreuve: string; niveau: NiveauCecrl | null}) =>
        epreuveMention(e.epreuve as EpreuveType, e.niveau, r.dejaAuNiveau, r.priorites);

    return (
        <SejourApp>
            <Top backTo={BACK_HREF} kicker={TOP_KICKER} title={TOP_TITLE} badge={TOP_BADGE} />

            {/* 1 — le niveau global. L'élément dominant de l'écran. */}
            <Pad>
                <Card variant="hero">
                    <p className={styles.label}>{HERO_LABEL}</p>
                    <p className={styles.level}>
                        {r.niveauGlobal ? niveauCecrlShort(r.niveauGlobal) : LEVEL_UNKNOWN}
                    </p>
                    {r.cible && (
                        <p className={styles.goalLine}>
                            {HERO_GOAL} <span>{r.cible}</span>
                        </p>
                    )}
                    {track && (
                        <LevelTrack
                            levels={[...track.levels]}
                            currentIndex={track.currentIndex}
                            goalIndex={track.goalIndex}
                            youLabel="Actuel"
                        />
                    )}
                    {analyse && <p className={styles.insight}>{analyse}</p>}
                    {/* Une épreuve manquante se dit, elle ne se devine pas. */}
                    {nonEvaluees.length > 0 && (
                        <p className={styles.tiny} role="status">
                            {nonEvaluees.map((e) => epreuveLabel(e.epreuve)).join(", ")} :{" "}
                            {NIVEAU_NON_EVALUE.toLowerCase()}.
                        </p>
                    )}
                </Card>
            </Pad>

            {/* 2 — le niveau par épreuve. Le statut se LIT sur les listes
                servies (`dejaAuNiveau`, rang 1 de `priorites`) : aucun palier
                n'est comparé ici. */}
            <Section title={EPREUVES_TITLE}>
                <Pad>
                    <Stack>
                        {r.epreuves.map((e) => {
                            const m = mention(e);
                            return (
                                <ExamRow
                                    key={e.epreuve}
                                    icon={epreuveIcon(e.epreuve)}
                                    title={epreuveLabel(e.epreuve)}
                                    level={e.niveau ? niveauCecrlShort(e.niveau) : undefined}
                                    status={m ? m.label : NIVEAU_NON_EVALUE}
                                    tone={m?.tone}
                                />
                            );
                        })}
                    </Stack>
                </Pad>
            </Section>

            {/* 3 — ce qui a bougé depuis le diagnostic précédent.
                🛑 Absent au premier diagnostic : `progression` vaut alors
                `null`, et on n'affiche pas un bloc vide. */}
            {r.progression && (
                <Section title={progressionTitle(r.progression.niveauGlobal)}>
                    <Pad>
                        <Stack>
                            <p className={styles.tiny}>
                                Diagnostic du{" "}
                                {r.progression.previousCompletedAt
                                    ? formatJourCourt(r.progression.previousCompletedAt)
                                    : "précédent"}
                                {r.progression.previousNiveauGlobal
                                    ? ` — niveau estimé ${r.progression.previousNiveauGlobal}`
                                    : ""}
                            </p>
                            {r.progression.epreuves.map((e) => (
                                <ExamRow
                                    key={e.epreuve}
                                    icon={epreuveIcon(e.epreuve)}
                                    title={epreuveLabel(e.epreuve)}
                                    level={e.apres ? niveauCecrlShort(e.apres) : undefined}
                                    /* 🛑 `INCONNUE` n'affiche RIEN d'évolutif :
                                       « = » se lirait « vous avez tenu votre
                                       niveau » alors que rien n'a été comparé. */
                                    status={
                                        evolutionLabel(e.evolution, e.avant) ?? NIVEAU_NON_EVALUE
                                    }
                                    tone={evolutionTone(e.evolution) ?? undefined}
                                />
                            ))}
                        </Stack>
                    </Pad>
                </Section>
            )}

            {/* 4 — ce qui bloque. Le bloc de conversion. */}
            {r.priorites.length > 0 && (
                <Section title={blocageTitle(r.cible)}>
                    <Pad>
                        <Stack>
                            {r.priorites.map((p) => (
                                <Prio
                                    key={`${p.epreuve}-${p.taskCode ?? "epreuve"}`}
                                    rank={rangPrio(p.rang)}
                                    tag={prioriteTag(p.rang)}
                                    title={prioriteLibelle(epreuveLabel(p.epreuve), p.taskCode)}
                                    /* 🛑 Couple inconnu ⇒ aucune phrase. On
                                       n'invente pas une consigne générique. */
                                    text={prioritePhrase(p.epreuve, p.taskCode) ?? undefined}
                                />
                            ))}
                        </Stack>
                    </Pad>
                </Section>
            )}

            {/* 5 — rassurance. */}
            <Section>
                <Pad>
                    <NoteCard
                        variant="ok"
                        icon={Check}
                        iconTone="ok"
                        title={TCF_DIAGNOSTIC_RASSURANCE_TITLE}
                    >
                        <p className={styles.tiny}>{rassuranceText(r.cible)}</p>
                    </NoteCard>
                </Pad>
            </Section>

            {/* 6 — le plan, en aperçu. C'est ce bloc qui transforme un constat
                en promesse : le candidat voit l'ordre dans lequel son plan va
                le prendre, avant même de l'ouvrir. Absent sans priorité — on ne
                promet pas un plan vide. */}
            <Section title={r.priorites.length > 0 ? planPretTitle(r.cible) : undefined}>
                <Pad>
                    <Stack>
                        {r.priorites.length > 0 && (
                            <Card>
                                <MiniPlan
                                    rows={r.priorites.map((p) => {
                                        const pastille = prioritePastille(p.rang);
                                        return {
                                            label: prioriteCourte(
                                                EPREUVE_COURTE[
                                                    p.epreuve as keyof typeof EPREUVE_COURTE
                                                ] ?? p.epreuve,
                                                p.taskCode,
                                            ),
                                            pill: pastille.label,
                                            tone: pastille.tone,
                                        };
                                    })}
                                />
                                {competencesCibleesLine(r.tachesSousLaCible) && (
                                    <p className={styles.tiny}>
                                        {competencesCibleesLine(r.tachesSousLaCible)}
                                    </p>
                                )}
                            </Card>
                        )}
                        {/* C'est ICI que l'abonnement se joue, et nulle part
                            avant : le candidat a ses quatre niveaux et ses
                            priorités réelles sous les yeux. Le CTA reste servi
                            même sans priorité — un candidat déjà au niveau doit
                            pouvoir atteindre son plan. */}
                        <Cta href={PLAN_HREF}>
                            {TCF_DIAGNOSTIC_PLAN_CTA}
                            {r.cible ? ` ${r.cible}` : ""}
                        </Cta>
                    </Stack>
                </Pad>
            </Section>

            <p className={styles.footNote}>{TCF_DIAGNOSTIC_ESTIMATION_NOTE}</p>
        </SejourApp>
    );
}
