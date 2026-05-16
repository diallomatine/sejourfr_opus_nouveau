"use client";

import { useMemo, useState } from "react";
import { AlertCircle, Send } from "lucide-react";
import { ApiException, contactApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { ContactSuccessState } from "./ContactSuccessState";

const SUBJECT_OPTIONS = [
  "Question sur l'examen civique",
  "Question sur la naturalisation",
  "Question sur mon abonnement",
  "Problème technique",
  "Suggestion ou retour",
  "Partenariat ou presse",
  "Autre",
] as const;

type SubjectOption = (typeof SUBJECT_OPTIONS)[number];

interface FormState {
  fullName: string;
  email: string;
  subjectOption: SubjectOption | "";
  customSubject: string;
  message: string;
  consent: boolean;
  /** Honeypot. Reste toujours "" côté humain. */
  website: string;
}

type Errors = Partial<Record<keyof FormState, string>>;

const MIN_NAME = 2;
const MAX_NAME = 120;
const MIN_SUBJECT = 3;
const MAX_SUBJECT = 200;
const MIN_MESSAGE = 20;
const MAX_MESSAGE = 5000;

function effectiveSubject(s: FormState): string {
  if (!s.subjectOption) return "";
  if (s.subjectOption === "Autre") return s.customSubject.trim();
  return s.subjectOption;
}

function validate(s: FormState): Errors {
  const errors: Errors = {};
  if (!s.fullName.trim()) {
    errors.fullName = "Le nom est obligatoire";
  } else if (s.fullName.trim().length < MIN_NAME) {
    errors.fullName = `Le nom doit faire au moins ${MIN_NAME} caractères`;
  } else if (s.fullName.length > MAX_NAME) {
    errors.fullName = "Le nom est trop long";
  }

  if (!s.email.trim()) {
    errors.email = "L'email est obligatoire";
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.email.trim())) {
    errors.email = "Email invalide";
  }

  const finalSubject = effectiveSubject(s);
  if (!finalSubject) {
    errors.subjectOption = "Choisissez un objet";
  } else if (finalSubject.length < MIN_SUBJECT) {
    errors.customSubject = `L'objet doit faire au moins ${MIN_SUBJECT} caractères`;
  } else if (finalSubject.length > MAX_SUBJECT) {
    errors.customSubject = "L'objet est trop long";
  }

  if (!s.message.trim()) {
    errors.message = "Le message est obligatoire";
  } else if (s.message.trim().length < MIN_MESSAGE) {
    errors.message = `Votre message doit faire au moins ${MIN_MESSAGE} caractères`;
  } else if (s.message.length > MAX_MESSAGE) {
    errors.message = `Votre message est trop long (${MAX_MESSAGE} max)`;
  }

  if (!s.consent) {
    errors.consent =
      "Vous devez accepter le traitement de vos données pour envoyer le message";
  }
  return errors;
}

interface SubmittedInfo {
  ticketId: string;
  email: string;
  fullName: string;
}

export function ContactForm() {
  const { user } = useAuth();

  const [state, setState] = useState<FormState>(() => ({
    fullName: user
      ? [user.firstName, user.lastName].filter(Boolean).join(" ").trim()
      : "",
    email: user?.email ?? "",
    subjectOption: "",
    customSubject: "",
    message: "",
    consent: false,
    website: "",
  }));
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitted, setSubmitted] = useState<SubmittedInfo | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const errors = useMemo(() => validate(state), [state]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setTouched({
      fullName: true,
      email: true,
      subjectOption: true,
      customSubject: true,
      message: true,
      consent: true,
    });
    if (Object.keys(errors).length > 0) return;
    setSubmitError(null);
    setSubmitting(true);
    try {
      const res = await contactApi.submit({
        fullName: state.fullName.trim(),
        email: state.email.trim(),
        subject: effectiveSubject(state),
        message: state.message.trim(),
        consent: state.consent,
        website: state.website,
      });
      setSubmitted({
        ticketId: res.ticketId,
        email: state.email.trim(),
        fullName: state.fullName.trim(),
      });
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 404) {
          // L'endpoint n'est pas encore branché côté backend Java :
          // on affiche un message inline plutôt qu'une erreur générique.
          setSubmitError(
            "Le service de contact sera bientôt disponible. En attendant, écrivez-nous à support@sejourfr.fr.",
          );
        } else if (err.status === 429) {
          setSubmitError(
            err.message ||
              "Trop de messages envoyés depuis votre adresse. Réessayez plus tard.",
          );
        } else {
          setSubmitError(
            err.message ||
              "Impossible d'envoyer votre message pour le moment. Réessayez dans quelques minutes.",
          );
        }
      } else {
        setSubmitError(
          "Impossible d'envoyer votre message pour le moment. Réessayez dans quelques minutes.",
        );
      }
    } finally {
      setSubmitting(false);
    }
  }

  const onReset = () => {
    setSubmitted(null);
    setState({
      fullName: user
        ? [user.firstName, user.lastName].filter(Boolean).join(" ").trim()
        : "",
      email: user?.email ?? "",
      subjectOption: "",
      customSubject: "",
      message: "",
      consent: false,
      website: "",
    });
    setTouched({});
    setSubmitError(null);
  };

  if (submitted) {
    return (
      <ContactSuccessState
        ticketId={submitted.ticketId}
        email={submitted.email}
        fullName={submitted.fullName}
        onSendAnother={onReset}
      />
    );
  }

  const messageLen = state.message.length;
  const messageWarn =
    messageLen > 4800 ? "danger" : messageLen > 4000 ? "warn" : "muted";

  const hasErrorsToShow =
    Object.keys(errors).length > 0 &&
    Object.keys(touched).some((k) => touched[k]);

  return (
    <form onSubmit={onSubmit} noValidate className="contact-form">
      {/* Honeypot — invisible, mais accessible aux bots qui parsent le DOM. */}
      <div aria-hidden="true" className="contact-honeypot">
        <label htmlFor="contact-website">Ne pas remplir</label>
        <input
          id="contact-website"
          type="text"
          tabIndex={-1}
          autoComplete="off"
          value={state.website}
          onChange={(e) =>
            setState((s) => ({ ...s, website: e.target.value }))
          }
        />
      </div>

      {submitError && (
        <div role="alert" className="form-error contact-submit-error">
          {submitError}
        </div>
      )}

      {hasErrorsToShow && (
        <div role="alert" className="contact-recap">
          <AlertCircle className="contact-recap-icon" />
          <span>
            Veuillez corriger les champs en rouge avant d&apos;envoyer le
            message.
          </span>
        </div>
      )}

      <div className="contact-row-2">
        <div className="field">
          <label htmlFor="contact-fullname" className="field-label">
            Nom complet *
          </label>
          <input
            id="contact-fullname"
            type="text"
            autoComplete="name"
            required
            placeholder="Jean Dupont"
            value={state.fullName}
            onChange={(e) =>
              setState((s) => ({ ...s, fullName: e.target.value }))
            }
            onBlur={() => setTouched((t) => ({ ...t, fullName: true }))}
            maxLength={MAX_NAME}
            className={`field-input ${touched.fullName && errors.fullName ? "has-error" : ""}`}
          />
          {touched.fullName && errors.fullName && (
            <p className="contact-field-err">{errors.fullName}</p>
          )}
        </div>
        <div className="field">
          <label htmlFor="contact-email" className="field-label">
            Email *
          </label>
          <input
            id="contact-email"
            type="email"
            autoComplete="email"
            required
            placeholder="jean.dupont@email.fr"
            value={state.email}
            onChange={(e) =>
              setState((s) => ({ ...s, email: e.target.value }))
            }
            onBlur={() => setTouched((t) => ({ ...t, email: true }))}
            maxLength={255}
            className={`field-input ${touched.email && errors.email ? "has-error" : ""}`}
          />
          {touched.email && errors.email && (
            <p className="contact-field-err">{errors.email}</p>
          )}
        </div>
      </div>

      <div className="field">
        <label htmlFor="contact-subject" className="field-label">
          Objet de votre demande *
        </label>
        <select
          id="contact-subject"
          value={state.subjectOption}
          onChange={(e) =>
            setState((s) => ({
              ...s,
              subjectOption: e.target.value as SubjectOption,
            }))
          }
          onBlur={() => setTouched((t) => ({ ...t, subjectOption: true }))}
          required
          className={`field-input ${touched.subjectOption && errors.subjectOption ? "has-error" : ""}`}
        >
          <option value="" disabled>
            Sélectionnez un objet…
          </option>
          {SUBJECT_OPTIONS.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
        {touched.subjectOption && errors.subjectOption && (
          <p className="contact-field-err">{errors.subjectOption}</p>
        )}
      </div>

      {state.subjectOption === "Autre" && (
        <div className="field">
          <label htmlFor="contact-custom-subject" className="field-label">
            Précisez l&apos;objet *
          </label>
          <input
            id="contact-custom-subject"
            type="text"
            required
            placeholder="Décrivez en quelques mots…"
            value={state.customSubject}
            onChange={(e) =>
              setState((s) => ({ ...s, customSubject: e.target.value }))
            }
            onBlur={() => setTouched((t) => ({ ...t, customSubject: true }))}
            maxLength={MAX_SUBJECT}
            className={`field-input ${touched.customSubject && errors.customSubject ? "has-error" : ""}`}
          />
          {touched.customSubject && errors.customSubject && (
            <p className="contact-field-err">{errors.customSubject}</p>
          )}
        </div>
      )}

      <div className="field">
        <div className="contact-message-head">
          <label htmlFor="contact-message" className="field-label">
            Votre message *
          </label>
          <span className={`contact-counter contact-counter-${messageWarn}`}>
            {messageLen} / {MAX_MESSAGE}
          </span>
        </div>
        <textarea
          id="contact-message"
          rows={6}
          required
          placeholder="Décrivez votre demande en quelques mots…"
          value={state.message}
          onChange={(e) =>
            setState((s) => ({ ...s, message: e.target.value }))
          }
          onBlur={() => setTouched((t) => ({ ...t, message: true }))}
          maxLength={MAX_MESSAGE}
          className={`field-input contact-textarea ${touched.message && errors.message ? "has-error" : ""}`}
        />
        {touched.message && errors.message && (
          <p className="contact-field-err">{errors.message}</p>
        )}
      </div>

      <div className="contact-consent">
        <label className="contact-consent-label">
          <input
            type="checkbox"
            checked={state.consent}
            onChange={(e) =>
              setState((s) => ({ ...s, consent: e.target.checked }))
            }
            onBlur={() => setTouched((t) => ({ ...t, consent: true }))}
          />
          <span>
            J&apos;accepte que mes données soient utilisées pour traiter ma
            demande conformément à la{" "}
            <a href="/confidentialite" className="contact-consent-link">
              politique de confidentialité
            </a>
            .
          </span>
        </label>
        {touched.consent && errors.consent && (
          <p className="contact-field-err">{errors.consent}</p>
        )}
      </div>

      <div className="contact-submit-wrap">
        <button
          type="submit"
          disabled={submitting}
          className="btn btn-lg contact-submit"
        >
          {submitting ? (
            "Envoi en cours…"
          ) : (
            <>
              Envoyer mon message
              <Send className="contact-submit-icon" />
            </>
          )}
        </button>
      </div>

      <style>{`
        .contact-form {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 20px;
          padding: 24px;
          display: flex;
          flex-direction: column;
          gap: 22px;
          box-shadow: 0 14px 32px -28px rgba(15, 24, 57, 0.18);
        }
        .contact-honeypot {
          position: absolute;
          left: -9999px;
          width: 1px;
          height: 1px;
          overflow: hidden;
          opacity: 0;
        }
        .contact-recap {
          display: flex;
          align-items: flex-start;
          gap: 10px;
          padding: 12px 14px;
          background: var(--color-red-light);
          border: 1px solid var(--color-red);
          border-radius: 12px;
          color: var(--color-red-dark);
          font-size: 13.5px;
        }
        .contact-recap-icon {
          width: 16px;
          height: 16px;
          flex-shrink: 0;
          margin-top: 2px;
        }
        .contact-submit-error { margin-bottom: 0; }
        .contact-row-2 {
          display: grid;
          grid-template-columns: 1fr;
          gap: 18px;
        }
        .field-input.has-error {
          border-color: var(--color-red);
        }
        .field-input.has-error:focus {
          border-color: var(--color-red);
          box-shadow: 0 0 0 4px rgba(225, 55, 47, 0.12);
        }
        .contact-field-err {
          margin: 4px 0 0;
          font-size: 12px;
          color: var(--color-red-dark);
        }
        .contact-message-head {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 6px;
        }
        .contact-counter {
          font-family: var(--font-mono);
          font-size: 11px;
          font-variant-numeric: tabular-nums;
        }
        .contact-counter-muted { color: var(--color-muted-2); }
        .contact-counter-warn { color: var(--color-amber); }
        .contact-counter-danger { color: var(--color-red); }
        .contact-textarea {
          min-height: 140px;
          line-height: 1.55;
          resize: vertical;
        }
        .contact-consent-label {
          display: flex;
          align-items: flex-start;
          gap: 10px;
          font-size: 14px;
          line-height: 1.55;
          color: var(--color-muted);
          cursor: pointer;
        }
        .contact-consent-label input {
          margin-top: 3px;
          accent-color: var(--color-blue);
          width: 16px;
          height: 16px;
          flex-shrink: 0;
        }
        .contact-consent-link {
          color: var(--color-blue);
          text-decoration: underline;
          text-decoration-color: rgba(30, 58, 140, 0.35);
          text-underline-offset: 2px;
        }
        .contact-consent-link:hover { text-decoration-color: var(--color-blue); }
        .contact-submit-wrap { padding-top: 4px; }
        .contact-submit {
          min-height: 50px;
          width: 100%;
        }
        .contact-submit-icon { width: 16px; height: 16px; }
        @media (min-width: 640px) {
          .contact-row-2 { grid-template-columns: 1fr 1fr; gap: 20px; }
          .contact-submit { width: auto; padding-left: 32px; padding-right: 32px; }
        }
        @media (min-width: 1024px) {
          .contact-form { padding: 32px; }
        }
      `}</style>
    </form>
  );
}
