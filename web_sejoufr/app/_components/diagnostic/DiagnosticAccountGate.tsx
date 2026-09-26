"use client";

import {useState} from "react";
import {ArrowLeft, FilePenLine, Mic} from "lucide-react";
import {AuthShell} from "@/app/_components/auth/AuthShell";
import {LoginForm} from "@/app/_components/auth/LoginForm";
import {RegisterForm} from "@/app/_components/auth/RegisterForm";
import {TCF_DIAGNOSTIC_PANEL} from "@/app/_components/auth/auth-panels";
import authStyles from "@/app/_components/auth/auth.module.css";
import {ContinueOnAppLink} from "@/app/_components/diagnostic/ContinueOnAppLink";
import {userContentApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {DIAGNOSTIC_EDIT_WRITTEN_CTA} from "@/lib/diagnostic";
import {DiagnosticGateRecap, type DiagnosticGateRecapItem} from "./DiagnosticGateRecap";
import {DiagnosticSteps} from "./DiagnosticSteps";
import styles from "./diagnostic.module.css";

function formatDuration(seconds: number | null): string | null {
  if (seconds == null || seconds <= 0) return null;
  const minutes = Math.floor(seconds / 60);
  const rest = Math.round(seconds % 60);
  return `${minutes} min ${String(rest).padStart(2, "0")}`;
}

/**
 * Écran de demande de compte du diagnostic TCF invité — le moment de
 * conversion du produit.
 *
 * Il arrive **après** la production : tout est déjà conservé sur l'appareil,
 * il ne manque que le compte auquel rattacher l'analyse. Il monte EXACTEMENT
 * le rendu et le formulaire de `/inscription` (`AuthShell` + `RegisterForm`,
 * « J'ai déjà un compte » = `LoginForm` de `/connexion`), avec un titre, un
 * récapitulatif et un argumentaire propres au diagnostic.
 *
 * Deux règles qui ne bougent pas :
 * - **aucun résultat n'est montré ici** — l'analyse coûte un appel à un modèle
 *   payant, on ne l'offre pas avant le compte ;
 * - **l'écran ne lance rien lui-même** : le rattachement et l'analyse partent
 *   de `DiagnosticView` dès que l'authentification bascule (`runHandoff`).
 *
 * Un retour « ← Modifier mon texte » rouvre l'écrit **pré-rempli** : rien
 * n'est encore parti au serveur, le candidat peut donc revoir sa production
 * avant de créer son compte (`onEditWritten`, porté par `GuestDiagnostic`).
 *
 * Miroir mobile : `widgets/diagnostic_account_gate.dart`, texte pour texte.
 */
export function DiagnosticAccountGate({
  writtenWords,
  oralDurationSec,
  hasOral = true,
  storedOnDevice,
  onEditWritten,
}: {
  writtenWords: number;
  oralDurationSec: number | null;
  /**
   * Ce diagnostic comportait-il une étape orale ? (L3)
   *
   * 🛑 `false` sur le diagnostic rapide. L'écran ne doit alors ni compter deux
   * réponses ni afficher une ligne « Expression orale » cochée : le candidat
   * n'a rien enregistré, et lui montrer une coche là-dessus est un mensonge
   * juste avant de lui demander son e-mail.
   */
  hasOral?: boolean;
  /** `false` quand le navigateur a refusé l'écriture disque (navigation privée,
   *  quota) : on le dit franchement plutôt que de promettre une reprise qui
   *  n'aurait pas lieu. */
  storedOnDevice: boolean;
  /** Rouvre l'écrit pré-rempli. Absent = pas de retour (aucun appelant ne
   *  devrait l'omettre : c'est la seule sortie vers la production). */
  onEditWritten?: () => void;
}) {
  const [mode, setMode] = useState<"register" | "login">("register");
  const {refreshUser} = useAuth();

  const duration = formatDuration(oralDurationSec);
  const recap: DiagnosticGateRecapItem[] = [
    {
      Icon: FilePenLine,
      title: "Expression écrite",
      meta: `${writtenWords} mot${writtenWords > 1 ? "s" : ""} rédigés`,
    },
  ];
  if (hasOral) {
    recap.push({
      Icon: Mic,
      title: "Expression orale",
      meta: duration ? `${duration} enregistrées` : "Enregistrement prêt",
    });
  }

  const safety = storedOnDevice
    ? hasOral
      ? "Vos réponses sont conservées sur cet appareil : vous pouvez fermer cette page, elles seront toujours là."
      : "Votre texte est enregistré sur cet appareil : vous pouvez fermer cette page, il sera toujours là."
    : hasOral
      ? "Vos réponses sont conservées dans cet onglet. Évitez de le fermer avant d'avoir créé votre compte."
      : "Votre texte est conservé dans cet onglet. Évitez de le fermer avant d'avoir créé votre compte.";

  return (
    <AuthShell
      header={
        <>
          {onEditWritten && (
            <button type="button" className={styles.gateBack} onClick={onEditWritten}>
              <ArrowLeft size={16} aria-hidden /> {DIAGNOSTIC_EDIT_WRITTEN_CTA}
            </button>
          )}
          <DiagnosticSteps current="account" guest oral={hasOral} />
        </>
      }
      kicker="Dernière étape · compte gratuit"
      title={
        hasOral ? (
          <>
            Vos deux réponses sont <em>prêtes</em>.
          </>
        ) : (
          <>
            Votre texte est <em>enregistré</em>.
          </>
        )
      }
      /* 🛑 Formulation imposée (`10_` §3.4) : l'écran ne doit PAS laisser
         croire que quelque chose est déjà analysé — rien ne l'est encore. */
      subtitle="Créez votre compte gratuit pour lancer l'analyse. C'est lui qui portera votre résultat et votre plan de travail."
      panel={TCF_DIAGNOSTIC_PANEL}
    >
      <DiagnosticGateRecap items={recap} note={safety} />

      {mode === "register" ? (
        <RegisterForm
          registrationContext="DURING_DIAGNOSTIC"
          submitLabel="Créer mon compte et analyser"
          extraFields={<ExamDateField />}
          onRegistered={(form) => saveExamDate(form, refreshUser)}
        />
      ) : (
        <LoginForm submitLabel="Me connecter et analyser" />
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
          diagnosticType="QUICK_TCF"
          note="Vos réponses restent sur ce navigateur : reconnectez-vous ici pour lancer leur analyse."
        />
      </div>
    </AuthShell>
  );
}

/**
 * La date d'examen (`10_` §3.2, question 3) — **facultative**, et c'est le
 * point : « Pas encore » est une réponse, pas un formulaire incomplet.
 *
 * Elle est posée ICI plutôt que sur un écran de plus parce que c'est le seul
 * moment du tunnel où le candidat remplit déjà un formulaire. C'est elle qui
 * rend possibles le compte à rebours et le pass recommandé du paywall (L5).
 */
function ExamDateField() {
  return (
    <div className={authStyles.field}>
      <label htmlFor="examDate" className={authStyles.label}>
        Votre date d&apos;examen <span className={authStyles.optional}>(facultatif)</span>
      </label>
      <input
        id="examDate"
        name="examDate"
        type="date"
        className={authStyles.input}
        aria-describedby="examDate-hint"
      />
      <p id="examDate-hint" className={authStyles.hint}>
        Si vous la connaissez, votre plan s&apos;organisera autour d&apos;elle. Sinon, laissez vide.
      </p>
    </div>
  );
}

/**
 * 🛑 **Best-effort, et APRÈS l'inscription.** La date ne voyage pas dans la
 * requête d'inscription : `50_` §3.1 interdit d'y mélanger du métier. Un échec
 * ici ne doit surtout pas faire échouer un compte déjà créé — le candidat
 * pourra toujours la saisir dans son profil.
 *
 * 🛑 **Le profil se relit APRÈS l'écriture** : l'inscription a déjà relu
 * `/api/auth/me` avant que la date parte, et le compte ouvert gardait
 * `examDate: null` jusqu'au rechargement de la page.
 */
async function saveExamDate(form: FormData, refreshUser: () => Promise<void>): Promise<void> {
  const examDate = String(form.get("examDate") ?? "");
  if (!examDate) return;
  const saved = await userContentApi.updateExamDate(examDate).then(
    () => true,
    () => false,
  );
  if (saved) await refreshUser();
}
