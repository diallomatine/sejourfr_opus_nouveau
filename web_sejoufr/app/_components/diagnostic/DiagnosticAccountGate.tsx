"use client";

import Link from "next/link";
import {useState} from "react";
import {ArrowRight, Check, FilePenLine, Lock, Mic, ShieldCheck, Sparkles, Zap} from "lucide-react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import {PasswordInput} from "@/app/_components/auth/PasswordInput";
import {track} from "@/lib/analytics";
import {ApiException} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {TCF_LEVEL_BY_PROCEDURE, type TargetProcedure} from "@/lib/types";
import styles from "./diagnostic.module.css";

const MENTIONS: {value: TargetProcedure; code: string; name: string}[] = [
  {value: "CSP", code: "CSP", name: "Carte de séjour"},
  {value: "CR", code: "CR", name: "Carte de résident"},
  {value: "NAT", code: "NAT", name: "Naturalisation"},
];

function formatDuration(seconds: number | null): string | null {
  if (seconds == null || seconds <= 0) return null;
  const minutes = Math.floor(seconds / 60);
  const rest = Math.round(seconds % 60);
  return `${minutes} min ${String(rest).padStart(2, "0")}`;
}

/**
 * Écran de demande de compte du diagnostic invité.
 *
 * Il arrive **après** les deux productions : le visiteur a écrit puis parlé,
 * tout est déjà conservé sur son appareil, il ne manque que le compte auquel
 * rattacher l'analyse. C'est l'écran de conversion du produit.
 *
 * Deux règles qui ne bougent pas :
 * - **aucun résultat réel n'est montré ici** — l'analyse coûte deux appels à un
 *   modèle payant, on ne l'offre pas avant le compte ;
 * - l'aperçu de droite est un **exemple**, dit comme tel, avec des valeurs
 *   fictives. Il montre la forme de ce qui sera rendu, jamais un faux résultat
 *   personnel.
 */
export function DiagnosticAccountGate({
  writtenWords,
  oralDurationSec,
  storedOnDevice,
}: {
  writtenWords: number;
  oralDurationSec: number | null;
  /** `false` quand le navigateur a refusé l'écriture disque (navigation privée,
   *  quota) : on le dit franchement plutôt que de promettre une reprise qui
   *  n'aurait pas lieu. */
  storedOnDevice: boolean;
}) {
  const {login, register} = useAuth();
  const [mode, setMode] = useState<"register" | "login">("register");
  // Une inscription **commencée**, c'est la première frappe dans le formulaire —
  // pas son ouverture, que le candidat n'a peut-être jamais l'intention de
  // remplir. `once` : une seule fois par onglet.
  const signupStarted = () =>
    track("SIGNUP_STARTED", {registrationContext: "DURING_DIAGNOSTIC"}, {once: true});
  const [mention, setMention] = useState<TargetProcedure>("CSP");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleRegister(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setError(null);
    setSubmitting(true);
    try {
      await register({
        firstName: String(form.get("firstName") ?? ""),
        lastName: String(form.get("lastName") ?? ""),
        email: String(form.get("email") ?? ""),
        password: String(form.get("password") ?? ""),
        targetProcedure: mention,
      });
    } catch (cause) {
      setError(authError(cause, "Impossible de créer le compte. Réessayez dans un instant."));
      setSubmitting(false);
    }
  }

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setError(null);
    setSubmitting(true);
    try {
      await login({
        email: String(form.get("email") ?? ""),
        password: String(form.get("password") ?? ""),
      });
    } catch (cause) {
      setError(authError(cause, "Connexion impossible. Vérifiez votre email et votre mot de passe."));
      setSubmitting(false);
    }
  }

  const duration = formatDuration(oralDurationSec);

  return (
    <div className={styles.gate}>
      <section className={styles.gateMain} aria-labelledby="gate-title">
        <p className={styles.eyebrow}>Dernière étape</p>
        <h1 id="gate-title">Vos deux réponses sont prêtes</h1>
        <p className={styles.gateLead}>
          Créez votre compte gratuit pour lancer l&apos;analyse. C&apos;est lui qui portera
          votre résultat et votre plan de travail.
        </p>

        <ul className={styles.gateRecap}>
          <li>
            <span aria-hidden><FilePenLine size={16} /></span>
            <b>Expression écrite</b>
            <small>{writtenWords} mot{writtenWords > 1 ? "s" : ""} rédigés</small>
            <i aria-hidden><Check size={13} strokeWidth={3.2} /></i>
          </li>
          <li>
            <span aria-hidden><Mic size={16} /></span>
            <b>Expression orale</b>
            <small>{duration ? `${duration} enregistrées` : "Enregistrement prêt"}</small>
            <i aria-hidden><Check size={13} strokeWidth={3.2} /></i>
          </li>
        </ul>

        <p className={styles.gateSafety}>
          <ShieldCheck size={15} aria-hidden />
          {storedOnDevice
            ? "Vos réponses sont conservées sur cet appareil : vous pouvez fermer cette page, elles seront toujours là."
            : "Vos réponses sont conservées dans cet onglet. Évitez de le fermer avant d'avoir créé votre compte."}
        </p>

        <div className={styles.gateTabs} role="tablist" aria-label="Créer un compte ou se connecter">
          <button
            type="button"
            role="tab"
            aria-selected={mode === "register"}
            className={mode === "register" ? styles.gateTabActive : styles.gateTab}
            onClick={() => {
              setMode("register");
              setError(null);
            }}
          >
            Créer mon compte
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={mode === "login"}
            className={mode === "login" ? styles.gateTabActive : styles.gateTab}
            onClick={() => {
              setMode("login");
              setError(null);
            }}
          >
            J&apos;ai déjà un compte
          </button>
        </div>

        {error && <p className={styles.error} role="alert">{error}</p>}

        {mode === "register" ? (
          <form
            className={styles.gateForm}
            onSubmit={handleRegister}
            onInput={signupStarted}
            noValidate
          >
            <div className={styles.gateRow2}>
              <div className="field">
                <label className="field-label" htmlFor="gate-firstName">Prénom</label>
                <input
                  id="gate-firstName"
                  name="firstName"
                  className="field-input"
                  type="text"
                  required
                  autoComplete="given-name"
                  placeholder="Fatima"
                />
              </div>
              <div className="field">
                <label className="field-label" htmlFor="gate-lastName">Nom</label>
                <input
                  id="gate-lastName"
                  name="lastName"
                  className="field-input"
                  type="text"
                  required
                  autoComplete="family-name"
                  placeholder="Achour"
                />
              </div>
            </div>

            <div className="field">
              <label className="field-label" htmlFor="gate-email">Email</label>
              <input
                id="gate-email"
                name="email"
                className="field-input"
                type="email"
                required
                autoComplete="email"
                placeholder="vous@exemple.com"
              />
            </div>

            <div className="field">
              <label className="field-label" htmlFor="gate-password">Mot de passe</label>
              <PasswordInput
                id="gate-password"
                name="password"
                placeholder="8 caractères minimum"
                autoComplete="new-password"
                minLength={8}
              />
            </div>

            <div className="field">
              <span className="field-label">Votre démarche</span>
              <div className={styles.gateMentions}>
                {MENTIONS.map((option) => (
                  <label
                    key={option.value}
                    className={
                      mention === option.value ? styles.gateMentionActive : styles.gateMention
                    }
                  >
                    <input
                      type="radio"
                      name="mention"
                      value={option.value}
                      checked={mention === option.value}
                      onChange={() => setMention(option.value)}
                    />
                    <b>{option.code}</b>
                    <span>{option.name}</span>
                    <small>TCF {TCF_LEVEL_BY_PROCEDURE[option.value]}</small>
                  </label>
                ))}
              </div>
            </div>

            <label className={styles.gateCheck}>
              <input type="checkbox" required />
              <span>
                J&apos;accepte les <Link href="/cgu">Conditions générales</Link> et la{" "}
                <Link href="/confidentialite">Politique de confidentialité</Link>.
              </span>
            </label>

            <button type="submit" className={styles.primaryButton} disabled={submitting}>
              {submitting ? "Création…" : "Créer mon compte et analyser"}
              {!submitting && <ArrowRight size={17} aria-hidden />}
            </button>
          </form>
        ) : (
          <form className={styles.gateForm} onSubmit={handleLogin} noValidate>
            <div className="field">
              <label className="field-label" htmlFor="gate-login-email">Email</label>
              <input
                id="gate-login-email"
                name="email"
                className="field-input"
                type="email"
                required
                autoComplete="email"
                placeholder="vous@exemple.com"
              />
            </div>

            <div className="field">
              <label className="field-label" htmlFor="gate-login-password">Mot de passe</label>
              <PasswordInput
                id="gate-login-password"
                name="password"
                placeholder="Votre mot de passe"
                autoComplete="current-password"
              />
            </div>

            <button type="submit" className={styles.primaryButton} disabled={submitting}>
              {submitting ? "Connexion…" : "Me connecter et analyser"}
              {!submitting && <ArrowRight size={17} aria-hidden />}
            </button>

            <p className={styles.gateHelp}>
              <Link href="/mot-de-passe-oublie">Mot de passe oublié ?</Link>
            </p>
          </form>
        )}

        <div onClickCapture={mode === "register" ? signupStarted : undefined}>
          <GoogleSignInButton
            variant={mode === "register" ? "signup" : "signin"}
            onError={setError}
          />
        </div>

        <p className={styles.gateNoCard}>
          <Lock size={13} aria-hidden /> Compte gratuit, sans carte bancaire.
        </p>
      </section>

      <SampleResultAside />
    </div>
  );
}

/**
 * Aperçu **fictif** du résultat, pour montrer ce que le compte débloque.
 *
 * Chaque valeur y est inventée et la carte le dit deux fois : badge « Exemple »
 * en tête, phrase explicite en pied. On ne montre jamais de chiffre issu des
 * productions du visiteur — l'analyse n'a pas encore eu lieu.
 */
function SampleResultAside() {
  return (
    <aside className={styles.gateSample} aria-label="Exemple de résultat de diagnostic">
      <p className={styles.gateSampleTag}>
        <Sparkles size={13} aria-hidden /> Exemple — pas votre résultat
      </p>

      <div className={styles.gateSampleCard} aria-hidden="false">
        <div className={styles.gateSampleLevels}>
          <div>
            <span>Expression écrite</span>
            <b>B1</b>
          </div>
          <div>
            <span>Expression orale</span>
            <b>A2</b>
          </div>
        </div>

        <div className={styles.gateSampleBlock}>
          <p className={styles.gateSampleLabel}>Ce qui fonctionne déjà</p>
          <ul className={styles.gateSampleList}>
            <li>Les informations demandées sont toutes présentes.</li>
            <li>Le message reste compréhensible du début à la fin.</li>
          </ul>
        </div>

        <div className={styles.gateSamplePriority}>
          <p className={styles.gateSamplePriorityTag}>
            <Zap size={12} aria-hidden /> Priorité n°1
          </p>
          <b>Relier ses idées autrement que par une suite de phrases courtes</b>
          <span>Exercice conseillé · 8 min · Expression écrite</span>
        </div>
      </div>

      <p className={styles.gateSampleFoot}>
        Valeurs fictives, uniquement pour illustrer la forme du bilan. Le vôtre sera
        calculé sur vos deux réponses, sans note sur 20.
      </p>
    </aside>
  );
}

function authError(cause: unknown, fallback: string): string {
  if (cause instanceof ApiException) {
    const fields = cause.payload?.fieldErrors;
    return fields ? Object.values(fields).join(" · ") : cause.message;
  }
  return fallback;
}
