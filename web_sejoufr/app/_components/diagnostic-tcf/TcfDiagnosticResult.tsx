"use client";

/**
 * T12 — le résultat du diagnostic TCF 4 épreuves (`10_` §4.5).
 *
 * Ordre des blocs, imposé par la spec : niveau global → niveau par épreuve →
 * ce qui bloque → rassurance → déjà au niveau → plan.
 *
 * 🛑 **Aucun résultat n'est masqué derrière le paywall.** « Le paywall porte
 * sur le plan, pas sur le constat » (`10_` §4.5) : le DTO ne porte donc aucun
 * `locked`, et cet écran n'en invente pas.
 *
 * 🛑 **Une épreuve non évaluée est NOMMÉE, pas escamotée.** `niveau: null`
 * signifie « on n'a pas mesuré », jamais « A1 » : afficher un palier plancher
 * serait rendre un verdict que personne n'a rendu (invariant V040/V041/V042).
 */
import {useCallback, useEffect, useState} from "react";
import Link from "next/link";
import {ApiException, tcfDiagnosticApi} from "@/lib/api";
import {EPREUVE_PRESENTATION} from "@/lib/exam-durations";
import {PlanLevelRail} from "@/app/_components/plan/PlanBits";
import {
    NIVEAU_NON_EVALUE,
    TCF_DIAGNOSTIC_DEJA_TITLE,
    TCF_DIAGNOSTIC_ESTIMATION_NOTE,
    TCF_DIAGNOSTIC_PLAN_CTA,
    TCF_DIAGNOSTIC_RASSURANCE_TITLE,
    blocageTitle,
    evolutionLabel,
    formatJourCourt,
    prioriteTitle,
    progressionTitle,
    railLevel,
    rassuranceText,
} from "@/lib/tcf-diagnostic";
import {niveauCecrlLabel} from "@/lib/types";
import type {TcfDiagnosticResultDto} from "@/lib/types";

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
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre résultat.",
            });
        }
    }, [sessionId]);

    useEffect(() => {
        void charger();
    }, [charger]);

    if (etat.kind === "loading") {
        return (
            <section className="tcfr" aria-busy="true">
                <div className="tcfr-skel tcfr-skel-hero" />
                <div className="tcfr-skel tcfr-skel-card" />
                <Styles />
            </section>
        );
    }

    if (etat.kind === "erreur") {
        return (
            <section className="tcfr">
                <p className="tcfr-error">{etat.message}</p>
                <button type="button" className="btn" onClick={() => void charger()}>
                    Réessayer
                </button>
                <Styles />
            </section>
        );
    }

    const r = etat.resultat;
    const rail = railLevel(r.niveauGlobal);
    const nonEvaluees = r.epreuves.filter((e) => e.niveau === null);

    return (
        <section className="tcfr">
            {/* 1 — le niveau. L'élément dominant de l'écran. */}
            <header className="tcfr-hero">
                <p className="tcfr-eyebrow">Votre niveau estimé</p>
                <p className="tcfr-level">
                    {r.niveauGlobal ? niveauCecrlLabel(r.niveauGlobal) : "—"}
                </p>
                {r.cible && <p className="tcfr-cible">Objectif : {r.cible}</p>}
                {rail && <PlanLevelRail current={rail} />}

                {/* Une épreuve manquante se dit, elle ne se devine pas. */}
                {nonEvaluees.length > 0 && (
                    <p className="tcfr-manquant" role="status">
                        {nonEvaluees
                            .map(
                                (e) =>
                                    EPREUVE_PRESENTATION[
                                        e.epreuve as keyof typeof EPREUVE_PRESENTATION
                                    ]?.label ?? e.epreuve,
                            )
                            .join(", ")}{" "}
                        : {NIVEAU_NON_EVALUE.toLowerCase()}.
                    </p>
                )}
            </header>

            {/* 1 bis — ce qui a bougé depuis le diagnostic précédent (L7).
                🛑 Absent au premier diagnostic : `progression` vaut alors
                `null`, et on n'affiche pas un bloc vide. */}
            {r.progression && (
                <div className="tcfr-progression">
                    <p className="tcfr-progression-title">
                        {progressionTitle(r.progression.niveauGlobal)}
                    </p>
                    <p className="tcfr-progression-meta">
                        Diagnostic du{" "}
                        {r.progression.previousCompletedAt
                            ? formatJourCourt(r.progression.previousCompletedAt)
                            : "précédent"}
                        {r.progression.previousNiveauGlobal
                            ? ` — niveau estimé ${r.progression.previousNiveauGlobal}`
                            : ""}
                    </p>
                    <ul className="tcfr-progression-list">
                        {r.progression.epreuves.map((e) => {
                            const p =
                                EPREUVE_PRESENTATION[
                                    e.epreuve as keyof typeof EPREUVE_PRESENTATION
                                ];
                            const label = evolutionLabel(e.evolution, e.avant);
                            return (
                                <li key={e.epreuve}>
                                    <span aria-hidden>{p?.icon}</span>
                                    <span className="tcfr-progression-label">
                                        {p?.label ?? e.epreuve}
                                    </span>
                                    <span
                                        className="tcfr-progression-evo"
                                        data-evolution={e.evolution}
                                    >
                                        {/* 🛑 INCONNUE n'affiche RIEN : « = » se
                                            lirait « vous avez tenu votre niveau »
                                            alors que rien n'a été comparé. */}
                                        {label ?? NIVEAU_NON_EVALUE}
                                    </span>
                                </li>
                            );
                        })}
                    </ul>
                </div>
            )}

            {/* 2 — le niveau par épreuve. */}
            <h2 className="tcfr-h2">Votre niveau par épreuve</h2>
            <ul className="tcfr-epreuves">
                {r.epreuves.map((e) => {
                    const p =
                        EPREUVE_PRESENTATION[e.epreuve as keyof typeof EPREUVE_PRESENTATION];
                    return (
                        <li key={e.epreuve} className="tcfr-epreuve">
                            <span aria-hidden>{p?.icon}</span>
                            <span className="tcfr-epreuve-label">{p?.label ?? e.epreuve}</span>
                            <span
                                className="tcfr-epreuve-niveau"
                                data-evaluee={e.niveau !== null}
                            >
                                {e.niveau === null
                                    ? NIVEAU_NON_EVALUE
                                    : niveauCecrlLabel(e.niveau)}
                            </span>
                        </li>
                    );
                })}
            </ul>

            {/* 3 — ce qui bloque. Le bloc de conversion. */}
            {r.priorites.length > 0 && (
                <>
                    <h2 className="tcfr-h2">{blocageTitle(r.cible)}</h2>
                    <ol className="tcfr-priorites">
                        {r.priorites.map((p) => {
                            const pres =
                                EPREUVE_PRESENTATION[
                                    p.epreuve as keyof typeof EPREUVE_PRESENTATION
                                ];
                            return (
                                <li key={`${p.epreuve}-${p.taskCode ?? "epreuve"}`}>
                                    <p className="tcfr-priorite-title">
                                        {prioriteTitle(
                                            p.rang,
                                            pres?.label ?? p.epreuve,
                                            p.taskCode,
                                        )}
                                    </p>
                                    {p.niveauTache && (
                                        <p className="tcfr-priorite-meta">
                                            {niveauCecrlLabel(p.niveauTache)}
                                            {r.cible ? ` → ${r.cible}` : ""}
                                        </p>
                                    )}
                                </li>
                            );
                        })}
                    </ol>
                </>
            )}

            {/* 4 — rassurance. */}
            <div className="tcfr-rassurance">
                <p className="tcfr-rassurance-title">{TCF_DIAGNOSTIC_RASSURANCE_TITLE}</p>
                <p className="tcfr-rassurance-text">{rassuranceText(r.cible)}</p>
            </div>

            {/* 5 — déjà au niveau. Visuellement secondaire, comme la spec le veut. */}
            {r.dejaAuNiveau.length > 0 && (
                <div className="tcfr-deja">
                    <p className="tcfr-deja-title">{TCF_DIAGNOSTIC_DEJA_TITLE}</p>
                    <ul>
                        {r.dejaAuNiveau.map((e) => {
                            const p =
                                EPREUVE_PRESENTATION[
                                    e.epreuve as keyof typeof EPREUVE_PRESENTATION
                                ];
                            return (
                                <li key={e.epreuve}>
                                    ✓ {p?.label ?? e.epreuve}
                                    {e.niveau ? ` — ${niveauCecrlLabel(e.niveau)}` : ""}
                                </li>
                            );
                        })}
                    </ul>
                </div>
            )}

            {/* 6 — le plan. */}
            <Link href="/plan" className="btn btn-lg tcfr-cta">
                {TCF_DIAGNOSTIC_PLAN_CTA}
                {r.cible ? ` ${r.cible}` : ""}
            </Link>

            <p className="tcfr-fine">{TCF_DIAGNOSTIC_ESTIMATION_NOTE}</p>
            <Styles />
        </section>
    );
}

function Styles() {
    return (
        <style jsx>{`
            .tcfr {
                max-width: 480px;
                margin: 0 auto;
                padding: 24px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 16px;
            }
            .tcfr-hero {
                background: var(--color-blue-light);
                border-radius: 20px;
                padding: 24px 20px;
                text-align: center;
                display: flex;
                flex-direction: column;
                gap: 10px;
            }
            .tcfr-eyebrow {
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--color-blue-dark);
                margin: 0;
            }
            .tcfr-level {
                font-family: var(--font-display);
                font-size: 56px;
                line-height: 1;
                color: var(--color-blue);
                margin: 0;
            }
            .tcfr-cible {
                margin: 0;
                color: var(--color-ink-2);
            }
            .tcfr-manquant {
                margin: 4px 0 0;
                font-size: 13px;
                color: var(--color-blue-dark);
            }
            /* Le bloc de progression (L7). Sobre : c'est une mesure, pas une
               célébration — et il doit rester lisible quand elle baisse. */
            .tcfr-progression {
                border: 1px solid var(--color-line);
                border-radius: 16px;
                padding: 16px;
                display: flex;
                flex-direction: column;
                gap: 10px;
            }
            .tcfr-progression-title {
                font-family: var(--font-display);
                font-size: 18px;
                color: var(--color-ink);
                margin: 0;
            }
            .tcfr-progression-meta {
                font-family: var(--font-mono);
                font-size: 12px;
                color: var(--color-muted-2);
                margin: 0;
            }
            .tcfr-progression-list {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .tcfr-progression-list li {
                display: flex;
                align-items: center;
                gap: 10px;
                font-size: 14px;
            }
            .tcfr-progression-label {
                flex: 1;
                color: var(--color-ink);
            }
            .tcfr-progression-evo {
                font-family: var(--font-mono);
                font-size: 13px;
                color: var(--color-muted);
            }
            .tcfr-progression-evo[data-evolution="HAUSSE"] {
                color: var(--color-blue-dark);
            }
            .tcfr-h2 {
                font-family: var(--font-display);
                font-size: 20px;
                color: var(--color-ink);
                margin: 8px 0 0;
            }
            .tcfr-epreuves,
            .tcfr-priorites,
            .tcfr-deja ul {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .tcfr-epreuve {
                display: grid;
                grid-template-columns: auto minmax(0, 1fr) auto;
                gap: 10px;
                align-items: center;
                border: 1px solid var(--color-line);
                border-radius: 14px;
                padding: 12px 14px;
            }
            .tcfr-epreuve-label {
                color: var(--color-ink);
            }
            .tcfr-epreuve-niveau {
                font-family: var(--font-mono);
                font-size: 13px;
                color: var(--color-ink);
                white-space: nowrap;
            }
            /* Non évaluée : atténué, jamais alarmant — ce n'est pas un échec. */
            .tcfr-epreuve-niveau[data-evaluee="false"] {
                color: var(--color-muted-2);
                font-size: 12px;
            }
            .tcfr-priorites li {
                border-left: 3px solid var(--color-red);
                background: var(--color-red-light);
                border-radius: 0 12px 12px 0;
                padding: 12px 14px;
            }
            .tcfr-priorites li:nth-child(2) {
                border-left-color: var(--color-amber);
                background: color-mix(in srgb, var(--color-amber) 10%, white);
            }
            .tcfr-priorites li:nth-child(3) {
                border-left-color: var(--color-amber);
                background: color-mix(in srgb, var(--color-amber) 6%, white);
            }
            .tcfr-priorite-title {
                margin: 0;
                font-weight: 600;
                color: var(--color-ink);
            }
            .tcfr-priorite-meta {
                margin: 2px 0 0;
                font-family: var(--font-mono);
                font-size: 12px;
                color: var(--color-muted);
            }
            .tcfr-rassurance {
                background: var(--color-paper);
                border-radius: 14px;
                padding: 14px 16px;
            }
            .tcfr-rassurance-title {
                margin: 0;
                font-weight: 600;
                color: var(--color-ink);
            }
            .tcfr-rassurance-text {
                margin: 4px 0 0;
                color: var(--color-muted);
                font-size: 14px;
            }
            .tcfr-deja-title {
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-muted-2);
                margin: 0 0 6px;
            }
            .tcfr-deja li {
                color: var(--color-green);
                font-size: 14px;
            }
            .tcfr-cta {
                text-align: center;
                text-decoration: none;
            }
            .tcfr-fine {
                margin: 0;
                font-size: 12px;
                color: var(--color-muted-2);
                text-align: center;
            }
            .tcfr-error {
                background: var(--color-red-light);
                color: var(--color-red-dark);
                border-radius: 12px;
                padding: 12px 14px;
                margin: 0;
            }
            .tcfr-skel {
                background: var(--color-paper-2);
                border-radius: 16px;
            }
            .tcfr-skel-hero {
                height: 180px;
            }
            .tcfr-skel-card {
                height: 220px;
            }
        `}</style>
    );
}
