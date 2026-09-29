"use client";

/**
 * L'écran de compte du diagnostic **civique** passé en visiteur (`V053`).
 *
 * 🛑 **Arbitrage du propriétaire, 2026-09-10** : le candidat répond d'abord au
 * QCM, « et seulement après on lui demande de créer son compte pour voir le
 * résultat ». Cet écran est donc **le moment de conversion** du parcours
 * civique — pendant exact de `DiagnosticAccountGate` côté TCF, et il monte le
 * même rendu et le même formulaire que `/inscription` (`AuthShell` +
 * `RegisterForm`, « J'ai déjà un compte » = `LoginForm`).
 *
 * 🛑 **Aucun résultat n'est montré ici.** Ni score, ni thème, ni projection :
 * c'est précisément ce qu'on échange contre le compte. Le serveur n'expose
 * d'ailleurs aucune route de résultat publique — l'écran ne pourrait pas
 * mentir même s'il le voulait.
 *
 * 🛑 **Les réponses ne sont pas en jeu.** Elles sont déjà corrigées côté
 * serveur, sur une session que l'inscription se contente d'**adopter** — et
 * l'adoption part de `CivicDiagnosticResult` dès que l'authentification
 * bascule, jamais d'ici.
 *
 * La démarche déclarée au tirage **préremplit** la mention : le candidat l'a
 * déjà donnée, la redemander serait une question de plus au pire moment.
 */
import {useState} from "react";
import {Landmark} from "lucide-react";
import {AuthShell} from "@/app/_components/auth/AuthShell";
import {LoginForm} from "@/app/_components/auth/LoginForm";
import {RegisterForm} from "@/app/_components/auth/RegisterForm";
import {CIVIC_DIAGNOSTIC_PANEL} from "@/app/_components/auth/auth-panels";
import authStyles from "@/app/_components/auth/auth.module.css";
import {ContinueOnAppLink} from "@/app/_components/diagnostic/ContinueOnAppLink";
import {DiagnosticGateRecap} from "@/app/_components/diagnostic/DiagnosticGateRecap";
import {
    CIVIC_DIAGNOSTIC_GATE_EYEBROW,
    CIVIC_DIAGNOSTIC_GATE_LEAD,
    CIVIC_DIAGNOSTIC_GATE_SAFE,
    CIVIC_DIAGNOSTIC_RESULT_CTA,
    CIVIC_INTRO_TITLE,
    progressionLabel,
} from "@/lib/civic-diagnostic";
import type {TargetProcedure} from "@/lib/types";

export function CivicDiagnosticGate({
    sessionId,
    repondues,
    total,
    procedure,
}: {
    /** La session affichée : le lien vers l'app ne porte que SA run. */
    sessionId: string;
    repondues: number;
    total: number;
    /** La démarche déclarée avant le tirage — elle préremplit le formulaire. */
    procedure: TargetProcedure;
}) {
    const [mode, setMode] = useState<"register" | "login">("register");

    return (
        <AuthShell
            kicker={`${CIVIC_DIAGNOSTIC_GATE_EYEBROW} · compte gratuit`}
            title={
                <>
                    Vos réponses sont <em>enregistrées</em>.
                </>
            }
            subtitle={CIVIC_DIAGNOSTIC_GATE_LEAD}
            panel={CIVIC_DIAGNOSTIC_PANEL}
        >
            <DiagnosticGateRecap
                items={[
                    {Icon: Landmark, title: CIVIC_INTRO_TITLE, meta: progressionLabel(repondues, total)},
                ]}
                note={CIVIC_DIAGNOSTIC_GATE_SAFE}
            />

            {mode === "register" ? (
                <RegisterForm initialMention={procedure} submitLabel={CIVIC_DIAGNOSTIC_RESULT_CTA} />
            ) : (
                <LoginForm submitLabel={CIVIC_DIAGNOSTIC_RESULT_CTA} />
            )}

            <p className={authStyles.switchLine}>
                {mode === "register" ? "Déjà un compte ?" : "Pas encore de compte ?"}{" "}
                <button
                    type="button"
                    className={authStyles.switchButton}
                    onClick={() => setMode(mode === "register" ? "login" : "register")}
                >
                    {mode === "register" ? "Se connecter" : "Créer un compte gratuit"}
                </button>
            </p>

            <div className={authStyles.appLink}>
                <ContinueOnAppLink
                    diagnosticType="CIVIQUE"
                    sessionId={sessionId}
                    note="Votre résultat reste lié à ce navigateur : reconnectez-vous ici pour le voir."
                />
            </div>
        </AuthShell>
    );
}
