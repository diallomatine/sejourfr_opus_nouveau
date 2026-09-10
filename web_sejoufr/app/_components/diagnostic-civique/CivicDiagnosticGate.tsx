"use client";

/**
 * L'écran de compte du diagnostic **civique** passé en visiteur (`V053`).
 *
 * 🛑 **Arbitrage du propriétaire, 2026-09-10** : le candidat répond d'abord au
 * QCM, « et seulement après on lui demande de créer son compte pour voir le
 * résultat ». Cet écran est donc **le moment de conversion** du parcours
 * civique — pendant exact de `DiagnosticAccountGate` côté TCF.
 *
 * 🛑 **Aucun résultat n'est montré ici.** Ni score, ni thème, ni projection :
 * c'est précisément ce qu'on échange contre le compte. Le serveur n'expose
 * d'ailleurs aucune route de résultat publique — l'écran ne pourrait pas
 * mentir même s'il le voulait.
 *
 * 🛑 **Les réponses ne sont pas en jeu.** Elles sont déjà corrigées côté
 * serveur, sur une session que l'inscription se contente d'**adopter** : une
 * erreur de formulaire ne peut rien faire perdre, et l'écran le dit.
 *
 * La démarche déclarée au tirage **préremplit** la mention : le candidat l'a
 * déjà donnée, la redemander serait une question de plus au pire moment.
 */
import {useState} from "react";
import Link from "next/link";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import {PasswordInput} from "@/app/_components/auth/PasswordInput";
import {ApiException} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    CIVIC_DIAGNOSTIC_GATE_EYEBROW,
    CIVIC_DIAGNOSTIC_GATE_LEAD,
    CIVIC_DIAGNOSTIC_GATE_TITLE,
    MENTION_LABEL,
} from "@/lib/civic-diagnostic";
import type {TargetProcedure} from "@/lib/types";

const MENTIONS: TargetProcedure[] = ["CSP", "CR", "NAT"];

function messageErreur(cause: unknown, repli: string): string {
    if (cause instanceof ApiException) {
        const champs = cause.payload?.fieldErrors;
        return champs ? Object.values(champs).join(" · ") : cause.message;
    }
    return repli;
}

export function CivicDiagnosticGate({
    repondues,
    total,
    procedure,
}: {
    repondues: number;
    total: number;
    /** La démarche déclarée avant le tirage — elle préremplit le formulaire. */
    procedure: TargetProcedure;
}) {
    const {login, register} = useAuth();
    const [mode, setMode] = useState<"register" | "login">("register");
    const [mention, setMention] = useState<TargetProcedure>(procedure);
    const [envoi, setEnvoi] = useState(false);
    const [erreur, setErreur] = useState<string | null>(null);

    async function inscrire(event: React.FormEvent<HTMLFormElement>) {
        event.preventDefault();
        const form = new FormData(event.currentTarget);
        setErreur(null);
        setEnvoi(true);
        try {
            await register({
                firstName: String(form.get("firstName") ?? ""),
                lastName: String(form.get("lastName") ?? ""),
                email: String(form.get("email") ?? ""),
                password: String(form.get("password") ?? ""),
                targetProcedure: mention,
            });
            // 🛑 On ne fait rien de plus ici : l'adoption est déclenchée par
            // l'écran de résultat dès que l'authentification bascule. Deux
            // appelants pour la même adoption, ce serait deux chemins à tenir.
        } catch (cause) {
            setErreur(messageErreur(cause, "Impossible de créer le compte. Réessayez dans un instant."));
            setEnvoi(false);
        }
    }

    async function connecter(event: React.FormEvent<HTMLFormElement>) {
        event.preventDefault();
        const form = new FormData(event.currentTarget);
        setErreur(null);
        setEnvoi(true);
        try {
            await login({
                email: String(form.get("email") ?? ""),
                password: String(form.get("password") ?? ""),
            });
        } catch (cause) {
            setErreur(messageErreur(cause, "Connexion impossible. Vérifiez votre email et votre mot de passe."));
            setEnvoi(false);
        }
    }

    return (
        <section className="cvg">
            <p className="cvg-eyebrow">{CIVIC_DIAGNOSTIC_GATE_EYEBROW}</p>
            <h1>{CIVIC_DIAGNOSTIC_GATE_TITLE}</h1>
            <p className="cvg-lead">{CIVIC_DIAGNOSTIC_GATE_LEAD}</p>
            <p className="cvg-count">
                {repondues} réponse{repondues > 1 ? "s" : ""} sur {total} enregistrée
                {repondues > 1 ? "s" : ""}
            </p>

            <div className="cvg-modes" role="tablist" aria-label="Créer un compte ou se connecter">
                <button
                    type="button"
                    role="tab"
                    aria-selected={mode === "register"}
                    className={`cvg-mode${mode === "register" ? " is-active" : ""}`}
                    onClick={() => setMode("register")}
                >
                    Créer mon compte
                </button>
                <button
                    type="button"
                    role="tab"
                    aria-selected={mode === "login"}
                    className={`cvg-mode${mode === "login" ? " is-active" : ""}`}
                    onClick={() => setMode("login")}
                >
                    J&apos;ai déjà un compte
                </button>
            </div>

            {erreur && (
                <div className="form-error" role="alert">
                    {erreur}
                </div>
            )}

            {mode === "register" ? (
                <form onSubmit={inscrire} className="cvg-form" noValidate>
                    <div className="cvg-row2">
                        <div className="field">
                            <label htmlFor="cvg-firstName" className="field-label">Prénom</label>
                            <input id="cvg-firstName" name="firstName" type="text" required
                                   className="field-input" autoComplete="given-name" />
                        </div>
                        <div className="field">
                            <label htmlFor="cvg-lastName" className="field-label">Nom</label>
                            <input id="cvg-lastName" name="lastName" type="text" required
                                   className="field-input" autoComplete="family-name" />
                        </div>
                    </div>
                    <div className="field">
                        <label htmlFor="cvg-email" className="field-label">Email</label>
                        <input id="cvg-email" name="email" type="email" required
                               className="field-input" autoComplete="email" />
                    </div>
                    <div className="field">
                        <label htmlFor="cvg-password" className="field-label">Mot de passe</label>
                        <PasswordInput id="cvg-password" name="password" required
                                       autoComplete="new-password" />
                    </div>
                    {/* La démarche est déjà connue : on la montre modifiable, on ne
                        la redemande pas comme si le candidat n'avait rien dit. */}
                    <fieldset className="cvg-mentions">
                        <legend className="field-label">Ma démarche</legend>
                        {MENTIONS.map((m) => (
                            <button
                                key={m}
                                type="button"
                                role="radio"
                                aria-checked={mention === m}
                                className={`cvg-mention${mention === m ? " is-active" : ""}`}
                                onClick={() => setMention(m)}
                            >
                                <span className="cvg-mention-code">{m}</span>
                                <span>{MENTION_LABEL[m]}</span>
                            </button>
                        ))}
                    </fieldset>
                    <button type="submit" className="btn btn-lg btn-red" disabled={envoi}>
                        {envoi ? "Création…" : "Voir mon résultat"}
                    </button>
                </form>
            ) : (
                <form onSubmit={connecter} className="cvg-form" noValidate>
                    <div className="field">
                        <label htmlFor="cvg-login-email" className="field-label">Email</label>
                        <input id="cvg-login-email" name="email" type="email" required
                               className="field-input" autoComplete="email" />
                    </div>
                    <div className="field">
                        <label htmlFor="cvg-login-password" className="field-label">Mot de passe</label>
                        <PasswordInput id="cvg-login-password" name="password" required
                                       autoComplete="current-password" />
                    </div>
                    <button type="submit" className="btn btn-lg" disabled={envoi}>
                        {envoi ? "Connexion…" : "Voir mon résultat"}
                    </button>
                    <Link href="/mot-de-passe-oublie" className="btn-link-soft">
                        Mot de passe oublié ?
                    </Link>
                </form>
            )}

            <div className="cvg-google">
                <GoogleSignInButton />
            </div>

            <p className="cvg-note">
                Gratuit, sans carte bancaire. Vos réponses sont déjà enregistrées : elles
                vous suivent.
            </p>

            <Styles />
        </section>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`** — styled-jsx scope ses règles aux
 * éléments rendus par le même composant, et un `Styles()` qui ne rend que la
 * balise n'en applique aucune. Le reste du dépôt utilise `<style>` global.
 */
function Styles() {
    return (
        <style>{`
            .cvg {
                max-width: 480px;
                margin: 0 auto;
                padding: 24px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 14px;
            }
            .cvg-eyebrow {
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--color-red);
                margin: 0;
            }
            .cvg h1 {
                font-family: var(--font-display);
                font-size: 26px;
                color: var(--color-ink);
                margin: 0;
            }
            .cvg-lead {
                color: var(--color-muted);
                margin: 0;
                line-height: 1.55;
            }
            .cvg-count {
                font-family: var(--font-mono);
                font-size: 12px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-muted-2);
                margin: 0;
            }
            .cvg-modes {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 6px;
                background: var(--color-line-2);
                border-radius: 12px;
                padding: 4px;
            }
            .cvg-mode {
                border: 0;
                background: transparent;
                border-radius: 9px;
                padding: 9px 8px;
                font-size: 13.5px;
                color: var(--color-muted);
                cursor: pointer;
            }
            .cvg-mode.is-active {
                background: var(--color-surface, #fff);
                color: var(--color-ink);
                font-weight: 600;
            }
            .cvg-form {
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .cvg-row2 {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 10px;
            }
            @media (max-width: 420px) {
                .cvg-row2 { grid-template-columns: 1fr; }
            }
            .cvg-mentions {
                border: 0;
                padding: 0;
                margin: 0;
                display: grid;
                gap: 6px;
            }
            .cvg-mention {
                display: flex;
                align-items: center;
                gap: 10px;
                width: 100%;
                text-align: left;
                background: transparent;
                border: 1px solid var(--color-line);
                border-radius: 12px;
                padding: 10px 12px;
                font-size: 13.5px;
                color: var(--color-ink);
                cursor: pointer;
            }
            .cvg-mention.is-active {
                border-color: var(--color-blue);
                box-shadow: 0 0 0 1px var(--color-blue) inset;
            }
            .cvg-mention-code {
                font-family: var(--font-mono);
                font-size: 12px;
                color: var(--color-blue);
            }
            .cvg-google {
                display: flex;
                justify-content: center;
            }
            .cvg-note {
                font-size: 12.5px;
                color: var(--color-muted-2);
                margin: 0;
                text-align: center;
            }
        `}</style>
    );
}
