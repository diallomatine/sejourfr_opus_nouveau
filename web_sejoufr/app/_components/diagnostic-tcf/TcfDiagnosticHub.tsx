"use client";

/**
 * T06 — l'accueil du diagnostic TCF 4 épreuves (`30_` §5.1).
 *
 * Son travail : rendre 75 minutes acceptables en montrant qu'elles se
 * découpent, et ne rien promettre d'autre.
 *
 * 🛑 **Aucun résultat partiel n'apparaît ici** (`10_` §4.2) : ni score, ni
 * niveau, ni « vous êtes plutôt B1 ». Le DTO ne les porte même pas — le
 * résultat est le moment de conversion, le diluer le détruit.
 *
 * 🛑 **Aucun écran de passation n'est créé** : les sections QCM ouvrent le
 * runner de session existant, les productions la session EE/EO existante. Un
 * second parcours de passation divergerait du premier à la première évolution.
 */
import {useCallback, useEffect, useState} from "react";
import {useRouter} from "next/navigation";
import {ApiException, tcfDiagnosticApi} from "@/lib/api";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {EPREUVE_PRESENTATION, minutesLabel, EO_PAR_TACHE_LABEL} from "@/lib/exam-durations";
import {
    TCF_DIAGNOSTIC_ESTIMATION_NOTE,
    TCF_DIAGNOSTIC_MIC_WARNING,
    TCF_DIAGNOSTIC_REPRISE_ECOULEE,
    TCF_DIAGNOSTIC_RESULT_NOTE,
    TCF_DIAGNOSTIC_SECTION_WARNING,
    TCF_DIAGNOSTIC_DEBLOQUER_CTA,
    TCF_DIAGNOSTIC_DEJA_FAIT_TITLE,
    TCF_DIAGNOSTIC_MESURER_TITLE,
    TCF_DIAGNOSTIC_REEVALUER_CTA,
    TCF_DIAGNOSTIC_SUBTITLE,
    TCF_DIAGNOSTIC_TITLE,
    TCF_DIAGNOSTIC_VOIR_CTA,
    declencheParLePlanLine,
    derniereMesureLine,
    joursRestants,
    progressionLabel,
    resultatDisponible,
    sectionCtaLabel,
    sectionEtatLabel,
    reevaluationPitch,
    reevaluationRegleLine,
    sectionHref,
    sectionIndisponible,
} from "@/lib/tcf-diagnostic";
import type {
    EpreuveType,
    TcfDiagnosticDto,
    TcfDiagnosticSectionDto,
    TcfReassessmentEligibilityDto,
} from "@/lib/types";

type Etat =
    | {kind: "loading"}
    | {kind: "absent"}
    | {kind: "pret"; diagnostic: TcfDiagnosticDto}
    | {kind: "erreur"; message: string};

export function TcfDiagnosticHub() {
    const router = useRouter();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});
    const [action, setAction] = useState(false);
    /**
     * L'éligibilité **servie** (L7). 🛑 Elle n'est jamais déduite du diagnostic
     * : le serveur connaît aussi la dérogation du Plan, que cet écran ne voit
     * pas. `null` = pas encore chargée, ou l'appel a échoué — l'écran dégrade
     * alors vers ce qu'il sait, il n'invente aucun droit.
     */
    const [eligibilite, setEligibilite] =
        useState<TcfReassessmentEligibilityDto | null>(null);
    const [paywall, setPaywall] = useState(false);

    const charger = useCallback(async () => {
        try {
            // L'éligibilité est **best-effort** : son échec ne doit pas priver
            // le candidat de son diagnostic.
            const [courant, elig] = await Promise.all([
                tcfDiagnosticApi.current(),
                tcfDiagnosticApi.eligibility().catch(() => null),
            ]);
            setEligibilite(elig);
            setEtat(courant ? {kind: "pret", diagnostic: courant} : {kind: "absent"});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre diagnostic.",
            });
        }
    }, []);

    useEffect(() => {
        void charger();
    }, [charger]);

    /** Ouvrir est idempotent côté serveur : un double appui ne coûte rien. */
    const ouvrir = useCallback(async () => {
        if (action) return;
        setAction(true);
        try {
            setEtat({kind: "pret", diagnostic: await tcfDiagnosticApi.open()});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible d'ouvrir votre diagnostic.",
            });
        } finally {
            setAction(false);
        }
    }, [action]);

    /**
     * Poser l'ancre du chrono **avant** d'ouvrir le runner : sans cet appel la
     * section n'a aucune échéance. Idempotent — reprendre ne rend pas de temps.
     */
    const lancerSection = useCallback(
        async (section: TcfDiagnosticSectionDto, sessionId: string) => {
            if (action || section.attemptId === null) return;
            setAction(true);
            try {
                await tcfDiagnosticApi.startSection(sessionId, section.epreuve);
                router.push(sectionHref(section.epreuve, section.attemptId, sessionId));
            } catch (e) {
                setEtat({
                    kind: "erreur",
                    message:
                        e instanceof ApiException
                            ? e.message
                            : "Impossible de lancer cette section.",
                });
                setAction(false);
            }
        },
        [action, router],
    );

    const voirResultat = useCallback(
        async (sessionId: string) => {
            if (action) return;
            setAction(true);
            try {
                await tcfDiagnosticApi.result(sessionId);
                router.push(`/diagnostic-tcf/${sessionId}/resultat`);
            } catch (e) {
                setEtat({
                    kind: "erreur",
                    message:
                        e instanceof ApiException
                            ? e.message
                            : "Impossible de calculer votre résultat.",
                });
                setAction(false);
            }
        },
        [action, router],
    );

    if (etat.kind === "loading") {
        return <SquelettePage />;
    }

    if (etat.kind === "erreur") {
        return (
            <section className="tcfd">
                <h1>{TCF_DIAGNOSTIC_TITLE}</h1>
                <p className="tcfd-error">{etat.message}</p>
                <button type="button" className="btn" onClick={() => void charger()}>
                    Réessayer
                </button>
                <Styles />
            </section>
        );
    }

    if (etat.kind === "absent") {
        return (
            <section className="tcfd">
                <h1>{TCF_DIAGNOSTIC_TITLE}</h1>
                <p className="tcfd-lead">{TCF_DIAGNOSTIC_SUBTITLE}</p>
                <ul className="tcfd-apercu">
                    {(Object.keys(EPREUVE_PRESENTATION) as EpreuveType[]).map((e) => {
                        const p = EPREUVE_PRESENTATION[e as keyof typeof EPREUVE_PRESENTATION];
                        return (
                            <li key={e}>
                                <span aria-hidden>{p.icon}</span> {p.label}
                            </li>
                        );
                    })}
                </ul>
                <p className="tcfd-note">{TCF_DIAGNOSTIC_RESULT_NOTE}</p>
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void ouvrir()}
                >
                    Commencer mon diagnostic
                </button>
                <Styles />
            </section>
        );
    }

    const d = etat.diagnostic;

    // T11 (`30_` §5.6) — un diagnostic CLOS n'affiche pas quatre sections
    // « Terminée » : il affiche ce qu'il a mesuré, et la porte de réévaluation.
    if (d.status === "COMPLETED") {
        return (
            <DiagnosticDejaFait
                eligibilite={eligibilite}
                busy={action}
                onVoir={() => router.push(`/diagnostic-tcf/${d.sessionId}/resultat`)}
                onRelancer={() => void ouvrir()}
                onPaywall={() => setPaywall(true)}
                paywallOpen={paywall}
                onPaywallClose={() => setPaywall(false)}
            />
        );
    }

    const jours = joursRestants(d.expiresAt);

    return (
        <section className="tcfd">
            <header className="tcfd-head">
                <h1>{TCF_DIAGNOSTIC_TITLE}</h1>
                <p className="tcfd-lead">{TCF_DIAGNOSTIC_SUBTITLE}</p>
                <p className="tcfd-progress">{progressionLabel(d)}</p>
            </header>

            {/* Le délai passé n'est PAS une perte : le message le dit. */}
            {d.repriseEcoulee && (
                <p className="tcfd-avis" role="status">
                    {TCF_DIAGNOSTIC_REPRISE_ECOULEE}
                </p>
            )}

            <ul className="tcfd-sections">
                {d.sections.map((s) => (
                    <SectionCard
                        key={s.epreuve}
                        section={s}
                        busy={action}
                        onStart={() => void lancerSection(s, d.sessionId)}
                    />
                ))}
            </ul>

            <p className="tcfd-note">{TCF_DIAGNOSTIC_RESULT_NOTE}</p>

            {resultatDisponible(d) || d.repriseEcoulee ? (
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void voirResultat(d.sessionId)}
                >
                    Voir mon résultat
                </button>
            ) : (
                !d.repriseEcoulee &&
                jours > 0 && (
                    <p className="tcfd-note">
                        Vous avez {jours} jour{jours > 1 ? "s" : ""} pour terminer.
                    </p>
                )
            )}

            <p className="tcfd-fine">{TCF_DIAGNOSTIC_ESTIMATION_NOTE}</p>
            <Styles />
        </section>
    );
}

/**
 * T11 — « Votre diagnostic initial a déjà été réalisé » (`30_` §5.6).
 *
 * 🛑 **Le résultat existant n'est jamais bloqué.** Le paywall porte sur la
 * nouvelle mesure, jamais sur le constat déjà rendu (`10_` §4.5) : « Voir mon
 * diagnostic » est toujours le CTA principal.
 *
 * 🛑 **Rien n'est décidé ici.** `canStart`, `locked` et le `message` arrivent
 * servis ; sans eux (appel en échec), on n'affiche que le constat — on ne
 * fabrique pas un bouton dont on ignore s'il sera accepté.
 */
function DiagnosticDejaFait({
    eligibilite,
    busy,
    onVoir,
    onRelancer,
    onPaywall,
    paywallOpen,
    onPaywallClose,
}: {
    eligibilite: TcfReassessmentEligibilityDto | null;
    busy: boolean;
    onVoir: () => void;
    onRelancer: () => void;
    onPaywall: () => void;
    paywallOpen: boolean;
    onPaywallClose: () => void;
}) {
    const derniere = eligibilite ? derniereMesureLine(eligibilite) : null;
    const parLePlan = eligibilite ? declencheParLePlanLine(eligibilite) : null;

    return (
        <section className="tcfd">
            <header className="tcfd-head">
                <h1>{TCF_DIAGNOSTIC_DEJA_FAIT_TITLE}</h1>
                {derniere && <p className="tcfd-lead">{derniere}</p>}
            </header>

            <button type="button" className="btn btn-lg" onClick={onVoir}>
                {TCF_DIAGNOSTIC_VOIR_CTA}
            </button>

            {eligibilite && (
                <div className="tcfd-reeval">
                    <p className="tcfd-reeval-title">{TCF_DIAGNOSTIC_MESURER_TITLE}</p>

                    {eligibilite.locked && (
                        <>
                            <p className="tcfd-reeval-pitch">
                                {reevaluationPitch(eligibilite, null)}
                            </p>
                            <button type="button" className="btn" onClick={onPaywall}>
                                {TCF_DIAGNOSTIC_DEBLOQUER_CTA}
                            </button>
                        </>
                    )}

                    {!eligibilite.locked && eligibilite.canStart && (
                        <>
                            {parLePlan && <p className="tcfd-reeval-pitch">{parLePlan}</p>}
                            <button
                                type="button"
                                className="btn"
                                disabled={busy}
                                onClick={onRelancer}
                            >
                                {TCF_DIAGNOSTIC_REEVALUER_CTA}
                            </button>
                        </>
                    )}

                    {/* Délai non écoulé : ce n'est pas un cadenas, et l'écran ne
                        doit pas le présenter comme tel — aucun CTA d'achat ici. */}
                    {!eligibilite.locked && !eligibilite.canStart && eligibilite.message && (
                        <p className="tcfd-avis" role="status">
                            {eligibilite.message}
                        </p>
                    )}

                    <p className="tcfd-fine">{reevaluationRegleLine(eligibilite)}</p>
                </div>
            )}

            <p className="tcfd-fine">{TCF_DIAGNOSTIC_ESTIMATION_NOTE}</p>

            <PaywallSheet
                open={paywallOpen}
                onClose={onPaywallClose}
                module="INTEGRAL"
                ctaLocation="DIAGNOSTIC_REPORT"
                screen="diagnostic_tcf_reevaluation"
                title={TCF_DIAGNOSTIC_MESURER_TITLE}
                message={
                    eligibilite ? reevaluationPitch(eligibilite, null) : undefined
                }
            />
            <Styles />
        </section>
    );
}

function SectionCard({
    section,
    busy,
    onStart,
}: {
    section: TcfDiagnosticSectionDto;
    busy: boolean;
    onStart: () => void;
}) {
    const presentation =
        EPREUVE_PRESENTATION[section.epreuve as keyof typeof EPREUVE_PRESENTATION];
    if (!presentation) return null;

    // Section absente du diagnostic (aucun contenu) : elle se présente comme
    // « non évaluée », jamais comme un manque de contenu (`00_` §7.4).
    const indisponible = sectionIndisponible(section);
    const terminee = section.etat === "TERMINEE";

    return (
        <li className="tcfd-card" data-etat={section.etat}>
            <div className="tcfd-card-main">
                <span className="tcfd-icon" aria-hidden>
                    {presentation.icon}
                </span>
                <div>
                    <p className="tcfd-card-title">{presentation.label}</p>
                    <p className="tcfd-card-meta">
                        {section.totalQuestions !== null
                            ? `${section.totalQuestions} questions`
                            : presentation.volume}
                        {" · "}
                        {/* L'oral ne s'annonce pas en minutes d'épreuve : il se
                            chronomètre tâche par tâche. */}
                        {section.epreuve === "TCF_EO"
                            ? EO_PAR_TACHE_LABEL
                            : section.timeLimitSeconds
                              ? minutesLabel(section.timeLimitSeconds)
                              : "—"}
                    </p>
                </div>
                <span className="tcfd-badge">{sectionEtatLabel(section.etat)}</span>
            </div>

            {!terminee && !indisponible && (
                <>
                    <p className="tcfd-warn">
                        {TCF_DIAGNOSTIC_SECTION_WARNING}
                        {section.epreuve === "TCF_EO" && ` ${TCF_DIAGNOSTIC_MIC_WARNING}`}
                    </p>
                    <button type="button" className="btn" disabled={busy} onClick={onStart}>
                        {sectionCtaLabel(section.etat)}
                    </button>
                </>
            )}

            {indisponible && <p className="tcfd-warn">Non évaluée.</p>}
        </li>
    );
}

function SquelettePage() {
    return (
        <section className="tcfd" aria-busy="true">
            <div className="tcfd-skel tcfd-skel-h1" />
            <div className="tcfd-skel tcfd-skel-line" />
            <div className="tcfd-skel tcfd-skel-card" />
            <div className="tcfd-skel tcfd-skel-card" />
            <Styles />
        </section>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`, et ce n'est pas un oubli.**
 *
 * styled-jsx scope ses règles aux éléments rendus par **le même** composant :
 * dans un `Styles()` qui ne rend que la balise, aucun élément ne reçoit la
 * classe de scope, et **aucune règle ne s'applique**. C'est ce qui a rendu ces
 * écrans invisiblement nus — le toggle du Plan y compris.
 *
 * Le reste du dépôt utilise `<style>` global : on s'y aligne, et toutes les
 * classes sont préfixées pour qu'il n'y ait aucune collision.
 */
function Styles() {
    return (
        <style>{`
            .tcfd {
                max-width: 480px;
                margin: 0 auto;
                padding: 24px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 16px;
            }
            .tcfd h1 {
                font-family: var(--font-display);
                font-size: 28px;
                color: var(--color-ink);
                margin: 0;
            }
            .tcfd-lead,
            .tcfd-note,
            .tcfd-fine {
                color: var(--color-muted);
                margin: 0;
            }
            .tcfd-note {
                font-size: 14px;
            }
            .tcfd-fine {
                font-size: 12px;
            }
            .tcfd-progress {
                font-family: var(--font-mono);
                font-size: 12px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-muted-2);
                margin: 0;
            }
            .tcfd-avis {
                background: var(--color-blue-light);
                color: var(--color-blue-dark);
                border-radius: 12px;
                padding: 12px 14px;
                margin: 0;
                font-size: 14px;
            }
            /* Le bloc de réévaluation (L7). Il vit sous le CTA principal :
               le constat déjà rendu passe toujours avant la nouvelle mesure. */
            .tcfd-reeval {
                border: 1px solid var(--color-line);
                border-radius: 16px;
                padding: 16px;
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .tcfd-reeval-title {
                font-family: var(--font-display);
                font-size: 18px;
                color: var(--color-ink);
                margin: 0;
            }
            .tcfd-reeval-pitch {
                color: var(--color-muted);
                font-size: 14px;
                margin: 0;
            }
            .tcfd-error {
                background: var(--color-red-light);
                color: var(--color-red-dark);
                border-radius: 12px;
                padding: 12px 14px;
                margin: 0;
            }
            .tcfd-sections {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .tcfd-card {
                border: 1px solid var(--color-line);
                border-radius: 16px;
                padding: 16px;
                display: flex;
                flex-direction: column;
                gap: 10px;
                background: white;
            }
            .tcfd-card[data-etat="TERMINEE"] {
                border-color: color-mix(in srgb, var(--color-green) 40%, white);
                background: color-mix(in srgb, var(--color-green) 6%, white);
            }
            .tcfd-card-main {
                display: grid;
                grid-template-columns: auto minmax(0, 1fr) auto;
                gap: 12px;
                align-items: center;
            }
            .tcfd-icon {
                font-size: 22px;
            }
            .tcfd-card-title {
                margin: 0;
                font-weight: 600;
                color: var(--color-ink);
            }
            .tcfd-card-meta {
                margin: 2px 0 0;
                font-size: 13px;
                color: var(--color-muted);
            }
            .tcfd-badge {
                font-family: var(--font-mono);
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: 0.06em;
                color: var(--color-muted-2);
                white-space: nowrap;
            }
            .tcfd-warn {
                margin: 0;
                font-size: 13px;
                color: var(--color-muted);
            }
            .tcfd-skel {
                background: var(--color-paper-2);
                border-radius: 12px;
                animation: tcfd-pulse 1.4s ease-in-out infinite;
            }
            .tcfd-skel-h1 {
                height: 32px;
                width: 60%;
            }
            .tcfd-skel-line {
                height: 16px;
                width: 85%;
            }
            .tcfd-skel-card {
                height: 96px;
            }
            @keyframes tcfd-pulse {
                0%,
                100% {
                    opacity: 1;
                }
                50% {
                    opacity: 0.55;
                }
            }
            @media (prefers-reduced-motion: reduce) {
                .tcfd-skel {
                    animation: none;
                }
            }
        `}</style>
    );
}
