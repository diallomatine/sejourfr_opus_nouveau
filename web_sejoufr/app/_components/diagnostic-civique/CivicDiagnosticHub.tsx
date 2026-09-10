"use client";

/**
 * L'accueil du diagnostic **civique** (`20_` §4).
 *
 * 🛑 **Ce n'est PAS un examen blanc**, et l'écran le dit avant de commencer :
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
 *
 * 🛑 **On peut le passer AVANT de créer son compte** (`V053`, arbitrage du
 * propriétaire du 2026-09-10). Le visiteur déclare sa démarche — c'est elle qui
 * choisit les questions —, répond à ses 40 questions, et le compte n'est
 * demandé qu'au résultat. Dès qu'il s'authentifie, la session invitée est
 * **adoptée** : mêmes questions, mêmes réponses, rien n'est rejoué.
 */
import {useCallback, useEffect, useState} from "react";
import {useRouter} from "next/navigation";
import {ApiException, civicDiagnosticApi, publicCivicDiagnosticApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    adopterSiInvite,
    ecrireInvite,
    etatInvite,
} from "@/lib/civic-diagnostic-guest";
import {
    CIVIC_DIAGNOSTIC_GUEST_BADGE,
    CIVIC_DIAGNOSTIC_GUEST_LEAD,
    CIVIC_DIAGNOSTIC_GUEST_NOTE,
    CIVIC_DIAGNOSTIC_GUEST_TITLE,
    CIVIC_DIAGNOSTIC_NOT_EXAM,
    CIVIC_DIAGNOSTIC_RESULT_CTA,
    CIVIC_DIAGNOSTIC_RESUME_CTA,
    CIVIC_DIAGNOSTIC_START_CTA,
    CIVIC_DIAGNOSTIC_PARAM,
    civicDiagnosticSubtitle,
    CIVIC_DIAGNOSTIC_TITLE,
    MENTION_LABEL,
    progressionLabel,
} from "@/lib/civic-diagnostic";
import {civicDiagnosticResultHref} from "@/lib/civic-diagnostic";
import type {CivicDiagnosticDto, TargetProcedure} from "@/lib/types";

/** Le runner, avec le marqueur de retour vers le diagnostic. */
function runnerHref(attemptId: string, sessionId: string): string {
    return `/sessions/${attemptId}?${CIVIC_DIAGNOSTIC_PARAM}=${sessionId}`;
}

const MENTIONS: TargetProcedure[] = ["CSP", "CR", "NAT"];

type Etat =
    | {kind: "loading"}
    /** Visiteur sans diagnostic ouvert : il choisit sa démarche. */
    | {kind: "invite"}
    | {kind: "absent"}
    | {kind: "pret"; diagnostic: CivicDiagnosticDto; invite: boolean}
    | {kind: "erreur"; message: string};

export function CivicDiagnosticHub() {
    const router = useRouter();
    const {status} = useAuth();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});
    const [action, setAction] = useState(false);
    const [procedure, setProcedure] = useState<TargetProcedure>("CSP");

    const charger = useCallback(async () => {
        try {
            if (status === "authenticated") {
                // 🛑 **L'adoption d'abord.** Le visiteur qui vient de créer son
                // compte doit retrouver SON diagnostic, pas s'en voir proposer
                // un neuf : lire l'état avant d'adopter afficherait « aucun
                // diagnostic » une fraction de seconde puis changerait d'avis.
                const adopte = await adopterSiInvite();
                if (adopte) {
                    setEtat({kind: "pret", diagnostic: adopte, invite: false});
                    return;
                }
                const courant = await civicDiagnosticApi.current();
                setEtat(courant ? {kind: "pret", diagnostic: courant, invite: false} : {kind: "absent"});
                return;
            }
            const invite = await etatInvite();
            setEtat(invite ? {kind: "pret", diagnostic: invite, invite: true} : {kind: "invite"});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre diagnostic.",
            });
        }
    }, [status]);

    useEffect(() => {
        // `loading` = l'auth n'a pas encore tranché. Décider ici enverrait un
        // utilisateur connecté dans le tunnel invité le temps du refresh.
        if (status === "loading") return;
        void charger();
    }, [charger, status]);

    /** Ouvrir est idempotent côté compte : un double appui ne retire pas. */
    const ouvrir = useCallback(async () => {
        if (action) return;
        setAction(true);
        try {
            const ouvert =
                status === "authenticated"
                    ? await civicDiagnosticApi.open()
                    : await publicCivicDiagnosticApi.open(procedure);
            if (status !== "authenticated") {
                // L'adresse de la session, pour la reprise après rechargement
                // et pour l'adoption au moment du compte.
                ecrireInvite(ouvert, procedure);
            }
            // 🛑 Le marqueur voyage avec l'attempt : c'est LUI qui ramène au
            // diagnostic à la fin. Sans lui, le candidat termine ses questions
            // et atterrit sur le bilan de série générique.
            router.push(runnerHref(ouvert.attemptId, ouvert.sessionId));
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
    }, [action, procedure, router, status]);

    /**
     * Voir le résultat.
     *
     * 🛑 **Un visiteur n'obtient aucun résultat ici** : il est envoyé sur
     * l'écran de résultat, qui lui demande son compte. Le résultat est
     * exactement ce qu'on échange contre l'inscription.
     */
    const voirResultat = useCallback(
        async (sessionId: string, invite: boolean) => {
            if (action) return;
            if (invite) {
                router.push(civicDiagnosticResultHref(sessionId));
                return;
            }
            setAction(true);
            try {
                await civicDiagnosticApi.result(sessionId);
                router.push(civicDiagnosticResultHref(sessionId));
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

    if (etat.kind === "invite") {
        return (
            <section className="cvd">
                <span className="cvd-badge">{CIVIC_DIAGNOSTIC_GUEST_BADGE}</span>
                <h1>{CIVIC_DIAGNOSTIC_GUEST_TITLE}</h1>
                <p className="cvd-lead">{CIVIC_DIAGNOSTIC_GUEST_LEAD}</p>
                {/* 🛑 La démarche n'est pas un confort : elle choisit les
                    questions. Un candidat naturalisation mesuré sur le
                    programme d'une carte de séjour repart avec un diagnostic
                    flatteur et un plan incomplet. */}
                <div className="cvd-mentions" role="radiogroup" aria-label="Ma démarche">
                    {MENTIONS.map((m) => (
                        <button
                            key={m}
                            type="button"
                            role="radio"
                            aria-checked={procedure === m}
                            className={`cvd-mention${procedure === m ? " is-active" : ""}`}
                            onClick={() => setProcedure(m)}
                        >
                            <span className="cvd-mention-code">{m}</span>
                            <span className="cvd-mention-name">{MENTION_LABEL[m]}</span>
                        </button>
                    ))}
                </div>
                <p className="cvd-note">{CIVIC_DIAGNOSTIC_NOT_EXAM}</p>
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void ouvrir()}
                >
                    {CIVIC_DIAGNOSTIC_START_CTA}
                </button>
                <p className="cvd-note">{CIVIC_DIAGNOSTIC_GUEST_NOTE}</p>
                <Styles />
            </section>
        );
    }

    if (etat.kind === "absent") {
        return (
            <section className="cvd">
                <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
                {/* 🛑 Le nombre de questions n'est pas écrit en dur : tant que
                    le serveur n'a rien servi, on décrit le parcours sans le
                    chiffrer plutôt que d'annoncer un compte qui pourrait
                    changer. */}
                <p className="cvd-lead">
                    Le format de l&apos;examen, réparti sur les 5 thèmes.
                </p>
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
            {etat.invite && <span className="cvd-badge">{CIVIC_DIAGNOSTIC_GUEST_BADGE}</span>}
            <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
            <p className="cvd-lead">{civicDiagnosticSubtitle(d.total)}</p>
            <p className="cvd-progress">{progressionLabel(d.repondues, d.total)}</p>

            {termine ? (
                <button
                    type="button"
                    className="btn btn-lg"
                    disabled={action}
                    onClick={() => void voirResultat(d.sessionId, etat.invite)}
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
                        onClick={() => router.push(runnerHref(d.attemptId, d.sessionId))}
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
                            onClick={() => void voirResultat(d.sessionId, etat.invite)}
                        >
                            {CIVIC_DIAGNOSTIC_RESULT_CTA}
                        </button>
                    )}
                </>
            )}
            {etat.invite && <p className="cvd-note">{CIVIC_DIAGNOSTIC_GUEST_NOTE}</p>}
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
            .cvd-badge {
                align-self: flex-start;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--color-blue);
                background: var(--color-blue-light);
                border-radius: 999px;
                padding: 4px 10px;
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
            .cvd-mentions {
                display: grid;
                gap: 8px;
            }
            .cvd-mention {
                display: flex;
                align-items: center;
                gap: 10px;
                width: 100%;
                text-align: left;
                background: var(--color-surface);
                border: 1px solid var(--color-line);
                border-radius: 12px;
                padding: 12px 14px;
                cursor: pointer;
            }
            .cvd-mention.is-active {
                border-color: var(--color-blue);
                box-shadow: 0 0 0 1px var(--color-blue) inset;
            }
            .cvd-mention-code {
                font-family: var(--font-mono);
                font-size: 12px;
                color: var(--color-blue);
            }
            .cvd-mention-name {
                font-size: 14px;
                color: var(--color-ink);
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
