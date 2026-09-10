"use client";

/**
 * Le résultat du diagnostic **civique** (`20_` §4.5).
 *
 * Ordre imposé par la spec : résultat → vos thèmes → mises en situation → ce
 * qui coûte le plus de points → rassurance → teaser du plan.
 *
 * 🛑 **Le constat est intégralement gratuit.** « Le paywall porte sur
 * l'accompagnement » (`20_` §4.5) : ce DTO ne porte aucun `locked`, et cet
 * écran n'en invente pas.
 *
 * 🛑 **La projection /40 vient du SERVEUR.** Ni écrite en dur, ni recalculée
 * ici : deux calculs de la même chose finissent par afficher deux nombres. Et
 * c'est une projection, jamais un pronostic de réussite.
 *
 * 🛑 **Un thème NON ÉVALUÉ n'est pas faible.** Il se dit « Non évalué », en
 * atténué, et n'entre dans aucune priorité.
 */
import {useCallback, useEffect, useState} from "react";
import Link from "next/link";
import {ApiException, civicDiagnosticApi, publicCivicDiagnosticApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {adopterSiInvite, lireInvite} from "@/lib/civic-diagnostic-guest";
import {CivicDiagnosticGate} from "./CivicDiagnosticGate";
import {
    CIVIC_DIAGNOSTIC_PLAN_CTA,
    CIVIC_DIAGNOSTIC_TITLE,
    CIVIC_PLAN_TEASER_TITLE,
    CIVIC_PRIORITES_TITLE,
    CIVIC_RASSURANCE_TITLE,
    CIVIC_SITUATIONS_TEXT,
    CIVIC_SITUATIONS_TITLE,
    mentionBadge,
    projectionLine,
    rassuranceText,
    situationsLine,
    themeTone,
} from "@/lib/civic-diagnostic";
import {CIVIC_THEME_STATE_LABEL} from "@/lib/types";
import type {CivicDiagnosticResultDto, TargetProcedure} from "@/lib/types";

type Etat =
    | {kind: "loading"}
    /** Visiteur : le résultat est ce qu'on échange contre le compte (`V053`). */
    | {kind: "compte"; repondues: number; total: number; procedure: TargetProcedure}
    | {kind: "pret"; resultat: CivicDiagnosticResultDto}
    | {kind: "erreur"; message: string};

export function CivicDiagnosticResult({sessionId}: {sessionId: string}) {
    const {status} = useAuth();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});

    const charger = useCallback(async () => {
        try {
            if (status !== "authenticated") {
                // 🛑 **Aucun résultat pour un visiteur.** On ne montre que ce
                // qu'il a déjà : combien de questions il a traitées. Le
                // serveur n'expose d'ailleurs pas de résultat public — cet
                // écran ne pourrait pas mentir même s'il le voulait.
                const invite = lireInvite();
                if (invite?.sessionId === sessionId) {
                    const dto = await publicCivicDiagnosticApi.get(sessionId);
                    setEtat({
                        kind: "compte",
                        repondues: dto.repondues,
                        total: dto.total,
                        procedure: invite.procedure,
                    });
                    return;
                }
                // Session inconnue de cet appareil : le compte tranchera.
                setEtat({
                    kind: "erreur",
                    message: "Connectez-vous pour retrouver ce diagnostic.",
                });
                return;
            }

            // 🛑 **L'adoption d'abord**, et son échec n'arrête rien : un compte
            // qui avait déjà son diagnostic gratuit se voit refuser l'adoption
            // et doit tout de même voir SON résultat.
            await adopterSiInvite();
            // 🛑 `result()` (POST) et non `readResult()` : c'est lui qui
            // CLÔTURE la session. Sans cette clôture, le diagnostic reste
            // « en cours » pour toujours et le Plan continue de réclamer un
            // diagnostic que le candidat vient de terminer — le défaut constaté
            // à l'usage. L'appel est idempotent : une session déjà close est
            // rendue telle quelle.
            setEtat({kind: "pret", resultat: await civicDiagnosticApi.result(sessionId)});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre résultat.",
            });
        }
    }, [sessionId, status]);

    useEffect(() => {
        // `loading` = l'auth n'a pas tranché. Décider ici montrerait l'écran de
        // compte à quelqu'un qui en a déjà un, le temps du refresh de jeton.
        if (status === "loading") return;
        void charger();
    }, [charger, status]);

    if (etat.kind === "compte") {
        return (
            <CivicDiagnosticGate
                repondues={etat.repondues}
                total={etat.total}
                procedure={etat.procedure}
            />
        );
    }

    if (etat.kind === "loading") {
        return (
            <section className="cvr" aria-busy="true">
                <div className="cvr-skel cvr-skel-hero" />
                <Styles />
            </section>
        );
    }

    if (etat.kind === "erreur") {
        return (
            <section className="cvr">
                <p className="cvr-error">{etat.message}</p>
                <Styles />
            </section>
        );
    }

    const r = etat.resultat;
    const projection = projectionLine(r);
    const situations = situationsLine(r);
    const rassurance = rassuranceText(r);

    return (
        <section className="cvr">
            <header className="cvr-head">
                <h1>{CIVIC_DIAGNOSTIC_TITLE}</h1>
                <span className="cvr-mention">{mentionBadge(r.mention)}</span>
            </header>

            {/* 1 — le résultat. L'élément dominant. */}
            <div className="cvr-hero">
                <p className="cvr-eyebrow">Votre résultat</p>
                <p className="cvr-score">
                    {r.bonnes} <small>/ {r.posees}</small>
                </p>
                {/* 🛑 Absent si rien n'a été posé : « on n'a rien mesuré » ne se
                    dit pas « vous auriez 0 sur 40 ». */}
                {projection && <p className="cvr-projection">{projection}</p>}
                {r.projection40 !== null && (
                    <div className="cvr-bar" aria-hidden>
                        <span
                            className="cvr-bar-fill"
                            style={{width: `${Math.min(100, (r.projection40 / 40) * 100)}%`}}
                        />
                        <span
                            className="cvr-bar-seuil"
                            style={{left: `${(r.seuilReussite / 40) * 100}%`}}
                        />
                    </div>
                )}
            </div>

            {/* 2 — les 5 thèmes, TOUS, y compris les non évalués. */}
            <h2 className="cvr-h2">Vos thèmes</h2>
            <ul className="cvr-themes">
                {r.themes.map((t) => (
                    <li key={t.code} data-tone={themeTone(t.etat)}>
                        <span className="cvr-theme-dot" aria-hidden />
                        <span className="cvr-theme-label">{t.label}</span>
                        <span className="cvr-theme-etat">
                            {CIVIC_THEME_STATE_LABEL[t.etat]}
                        </span>
                    </li>
                ))}
            </ul>

            {/* 3 — les mises en situation, bloc distinct : c'est une compétence
                différente, et c'est souvent ce qui fait la différence. */}
            {situations && (
                <div className="cvr-situations">
                    <p className="cvr-situations-title">{CIVIC_SITUATIONS_TITLE}</p>
                    <p className="cvr-situations-score">{situations}</p>
                    <p className="cvr-situations-text">{CIVIC_SITUATIONS_TEXT}</p>
                </div>
            )}

            {/* 4 — ce qui coûte le plus de points. Titre volontairement concret. */}
            {r.priorites.length > 0 && (
                <>
                    <h2 className="cvr-h2">{CIVIC_PRIORITES_TITLE}</h2>
                    <ol className="cvr-priorites">
                        {r.priorites.map((p) => (
                            <li key={p.code} data-tone={themeTone(p.etat)}>
                                <span className="cvr-theme-dot" aria-hidden />
                                <span className="cvr-theme-label">{p.label}</span>
                                <span className="cvr-theme-etat">
                                    {CIVIC_THEME_STATE_LABEL[p.etat]}
                                </span>
                            </li>
                        ))}
                    </ol>
                </>
            )}

            {/* 5 — rassurance. 🛑 Absente si aucun thème n'est solide : « 0 thème
                est déjà solide » sonnerait faux au pire moment. */}
            {rassurance && (
                <div className="cvr-rassurance">
                    <p className="cvr-rassurance-title">{CIVIC_RASSURANCE_TITLE}</p>
                    <p className="cvr-rassurance-text">{rassurance}</p>
                </div>
            )}

            {/* 6 — le teaser du plan. */}
            <h2 className="cvr-h2">{CIVIC_PLAN_TEASER_TITLE}</h2>
            <Link href="/plan?module=CIVIQUE" className="btn btn-lg">
                {CIVIC_DIAGNOSTIC_PLAN_CTA}
            </Link>

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
            .cvr {
                max-width: 480px;
                margin: 0 auto;
                padding: 24px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 16px;
            }
            .cvr-head {
                display: flex;
                flex-direction: column;
                gap: 6px;
            }
            .cvr-head h1 {
                font-family: var(--font-display);
                font-size: 24px;
                color: var(--color-ink);
                margin: 0;
            }
            .cvr-mention {
                align-self: flex-start;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-blue-dark);
                background: var(--color-blue-light);
                border-radius: 999px;
                padding: 4px 10px;
            }
            .cvr-hero {
                background: var(--color-blue-light);
                border-radius: 18px;
                padding: 20px;
                text-align: center;
            }
            .cvr-eyebrow {
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-blue-dark);
                margin: 0;
            }
            .cvr-score {
                font-family: var(--font-display);
                font-size: 46px;
                color: var(--color-blue);
                margin: 6px 0 0;
            }
            .cvr-score small {
                font-size: 22px;
                color: var(--color-blue-dark);
            }
            .cvr-projection {
                margin: 8px 0 0;
                font-size: 13.5px;
                line-height: 1.5;
                color: var(--color-ink);
            }
            /* La barre porte le SEUIL, pas une promesse : le trait dit où est 32,
               il ne dit jamais « vous êtes prêt ». */
            .cvr-bar {
                position: relative;
                height: 8px;
                border-radius: 999px;
                background: #fff;
                margin-top: 12px;
                overflow: visible;
            }
            .cvr-bar-fill {
                position: absolute;
                inset: 0 auto 0 0;
                border-radius: 999px;
                background: var(--color-blue);
            }
            .cvr-bar-seuil {
                position: absolute;
                top: -3px;
                bottom: -3px;
                width: 2px;
                background: var(--color-blue-dark);
            }
            .cvr-h2 {
                font-family: var(--font-display);
                font-size: 18px;
                color: var(--color-ink);
                margin: 8px 0 0;
            }
            .cvr-themes,
            .cvr-priorites {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .cvr-themes li,
            .cvr-priorites li {
                display: flex;
                align-items: center;
                gap: 10px;
                border: 1px solid var(--color-line);
                border-radius: 14px;
                padding: 12px 14px;
                font-size: 14px;
            }
            .cvr-theme-dot {
                width: 8px;
                height: 8px;
                border-radius: 50%;
                flex: 0 0 auto;
            }
            .cvr li[data-tone="ok"] .cvr-theme-dot { background: var(--color-success, #168f5b); }
            .cvr li[data-tone="warn"] .cvr-theme-dot { background: var(--color-amber, #e8a317); }
            .cvr li[data-tone="hot"] .cvr-theme-dot { background: var(--color-red); }
            .cvr li[data-tone="muted"] .cvr-theme-dot { background: var(--color-line); }
            .cvr-theme-label {
                flex: 1;
                color: var(--color-ink);
            }
            .cvr-theme-etat {
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.04em;
                text-transform: uppercase;
                color: var(--color-muted);
            }
            /* Non évalué : atténué, jamais alarmant — ce n'est pas un échec. */
            .cvr li[data-tone="muted"] .cvr-theme-etat { color: var(--color-muted-2); }
            .cvr li[data-tone="hot"] .cvr-theme-etat { color: var(--color-red-dark); }
            .cvr-situations,
            .cvr-rassurance {
                border: 1px solid var(--color-line);
                border-radius: 16px;
                padding: 16px;
            }
            .cvr-rassurance {
                background: var(--color-success-light, #e6f4ed);
                border-color: transparent;
            }
            .cvr-situations-title,
            .cvr-rassurance-title {
                margin: 0;
                font-family: var(--font-display);
                font-size: 16px;
                color: var(--color-ink);
            }
            .cvr-situations-score {
                margin: 6px 0 0;
                font-family: var(--font-display);
                font-size: 22px;
                color: var(--color-blue);
            }
            .cvr-situations-text,
            .cvr-rassurance-text {
                margin: 6px 0 0;
                font-size: 13px;
                line-height: 1.5;
                color: var(--color-muted);
            }
            .cvr-error {
                background: var(--color-red-light);
                color: var(--color-red-dark);
                border-radius: 12px;
                padding: 12px 14px;
                margin: 0;
            }
            .cvr-skel {
                background: var(--color-line);
                border-radius: 16px;
                animation: cvr-pulse 1.3s ease-in-out infinite;
            }
            .cvr-skel-hero { height: 160px; }
            @keyframes cvr-pulse {
                0%, 100% { opacity: 0.55; }
                50% { opacity: 0.9; }
            }
        `}</style>
    );
}
