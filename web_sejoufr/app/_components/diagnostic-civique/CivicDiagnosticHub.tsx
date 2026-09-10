"use client";

/**
 * L'accueil du diagnostic **civique** (`20_` §4).
 *
 * 🛑 **Ce n'est PAS un examen blanc**, et l'écran le dit avant de commencer :
 * 24 questions au lieu de 40, couverture équilibrée au lieu de représentative,
 * il sert à repérer quoi travailler, pas à vérifier si on est prêt. Sans cette
 * phrase, le candidat lit son résultat comme un pronostic de réussite.
 *
 * 🛑 **Aucun écran de passation n'est créé** : le diagnostic ouvre le runner de
 * session existant. Un second runner divergerait du premier à la première
 * évolution.
 *
 * 🛑 **Un seul diagnostic civique**, pas de rapide + complet : le civique est du
 * QCM déterministe et rapide, un pré-diagnostic n'apporterait rien et
 * dupliquerait le tunnel du TCF (arbitrage du propriétaire, 2026-09-10).
 */
import {useCallback, useEffect, useState} from "react";
import {useRouter} from "next/navigation";
import {ApiException, civicDiagnosticApi} from "@/lib/api";
import {
    CIVIC_DIAGNOSTIC_NOT_EXAM,
    CIVIC_DIAGNOSTIC_RESULT_CTA,
    CIVIC_DIAGNOSTIC_RESUME_CTA,
    CIVIC_DIAGNOSTIC_START_CTA,
    CIVIC_DIAGNOSTIC_SUBTITLE,
    CIVIC_DIAGNOSTIC_TITLE,
    progressionLabel,
} from "@/lib/civic-diagnostic";
import type {CivicDiagnosticDto} from "@/lib/types";

type Etat =
    | {kind: "loading"}
    | {kind: "absent"}
    | {kind: "pret"; diagnostic: CivicDiagnosticDto}
    | {kind: "erreur"; message: string};

export function CivicDiagnosticHub() {
    const router = useRouter();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});
    const [action, setAction] = useState(false);

    const charger = useCallback(async () => {
        try {
            const courant = await civicDiagnosticApi.current();
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

    /** Ouvrir est idempotent côté serveur : un double appui ne retire pas. */
    const ouvrir = useCallback(async () => {
        if (action) return;
        setAction(true);
        try {
            const ouvert = await civicDiagnosticApi.open();
            router.push(`/sessions/${ouvert.attemptId}`);
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible d'ouvrir votre diagnostic.",
            });
            setAction(false);
        }
    }, [action, router]);

    const voirResultat = useCallback(
        async (sessionId: string) => {
            if (action) return;
            setAction(true);
            try {
                await civicDiagnosticApi.result(sessionId);
                router.push(`/diagnostic-civique/${sessionId}/resultat`);
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

    if (etat.kind === "loading") return <Squelette />;

    if (etat.kind === "erreur") {
        return (
            <section className="cvd">
                <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
                <p className="cvd-error">{etat.message}</p>
                <button type="button" className="btn" onClick={() => void charger()}>
                    Réessayer
                </button>
                <Styles />
            </section>
        );
    }

    if (etat.kind === "absent") {
        return (
            <section className="cvd">
                <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
                <p className="cvd-lead">{CIVIC_DIAGNOSTIC_SUBTITLE}</p>
                <p className="cvd-note">{CIVIC_DIAGNOSTIC_NOT_EXAM}</p>
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void ouvrir()}
                >
                    {CIVIC_DIAGNOSTIC_START_CTA}
                </button>
                <Styles />
            </section>
        );
    }

    const d = etat.diagnostic;
    const termine = d.status === "COMPLETED";

    return (
        <section className="cvd">
            <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
            <p className="cvd-lead">{CIVIC_DIAGNOSTIC_SUBTITLE}</p>
            <p className="cvd-progress">{progressionLabel(d.repondues, d.total)}</p>

            {termine ? (
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void voirResultat(d.sessionId)}
                >
                    {CIVIC_DIAGNOSTIC_RESULT_CTA}
                </button>
            ) : (
                <>
                    <p className="cvd-note">{CIVIC_DIAGNOSTIC_NOT_EXAM}</p>
                    <button
                        type="button"
                        className="btn btn-lg"
                        disabled={action}
                        onClick={() => router.push(`/sessions/${d.attemptId}`)}
                    >
                        {d.repondues > 0
                            ? CIVIC_DIAGNOSTIC_RESUME_CTA
                            : CIVIC_DIAGNOSTIC_START_CTA}
                    </button>
                    {/* Le résultat reste demandable même sans avoir tout répondu :
                        une question sautée sort du dénominateur, elle ne devient
                        jamais une mauvaise réponse. */}
                    {d.repondues > 0 && (
                        <button
                            type="button"
                            className="btn btn-ghost"
                            disabled={action}
                            onClick={() => void voirResultat(d.sessionId)}
                        >
                            {CIVIC_DIAGNOSTIC_RESULT_CTA}
                        </button>
                    )}
                </>
            )}
            <Styles />
        </section>
    );
}

function Squelette() {
    return (
        <section className="cvd" aria-busy="true">
            <div className="cvd-skel cvd-skel-h1" />
            <div className="cvd-skel cvd-skel-line" />
            <Styles />
        </section>
    );
}

function Styles() {
    return (
        <style jsx>{`
            .cvd {
                max-width: 480px;
                margin: 0 auto;
                padding: 24px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 14px;
            }
            .cvd h1 {
                font-family: var(--font-display);
                font-size: 26px;
                color: var(--color-ink);
                margin: 0;
            }
            .cvd-lead,
            .cvd-note {
                color: var(--color-muted);
                margin: 0;
            }
            .cvd-note {
                font-size: 13px;
            }
            .cvd-progress {
                font-family: var(--font-mono);
                font-size: 12px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-muted-2);
                margin: 0;
            }
            .cvd-error {
                background: var(--color-red-light);
                color: var(--color-red-dark);
                border-radius: 12px;
                padding: 12px 14px;
                margin: 0;
            }
            .cvd-skel {
                background: var(--color-line);
                border-radius: 10px;
                animation: cvd-pulse 1.3s ease-in-out infinite;
            }
            .cvd-skel-h1 { height: 30px; width: 70%; }
            .cvd-skel-line { height: 16px; width: 90%; }
            @keyframes cvd-pulse {
                0%, 100% { opacity: 0.55; }
                50% { opacity: 0.9; }
            }
        `}</style>
    );
}
