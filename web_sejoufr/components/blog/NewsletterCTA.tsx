"use client";

import { useState, type FormEvent } from "react";
import { CheckCircle2, Mail, Send } from "lucide-react";
import { ApiException, newsletterApi } from "@/lib/api";

interface Props {
  source?: string;
  variant?: "card" | "inline";
}

type Status = "idle" | "loading" | "success" | "already" | "error";

export function NewsletterCTA({ source = "blog", variant = "card" }: Props) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [errorMessage, setErrorMessage] = useState<string>("");

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const trimmed = email.trim();
    if (!trimmed) return;
    setStatus("loading");
    setErrorMessage("");
    try {
      const res = await newsletterApi.subscribe(trimmed, source);
      setStatus(res.alreadySubscribed ? "already" : "success");
    } catch (err) {
      if (err instanceof ApiException && err.status === 404) {
        setErrorMessage(
          "Le service d'inscription sera disponible très bientôt — réessayez dans quelques jours.",
        );
      } else if (err instanceof ApiException) {
        setErrorMessage(
          err.message ||
            "Impossible d'enregistrer votre inscription pour le moment.",
        );
      } else {
        setErrorMessage("Erreur réseau — réessayez dans un instant.");
      }
      setStatus("error");
    }
  };

  const isWhite = variant === "card";
  const isSuccess = status === "success" || status === "already";

  return (
    <div
      className={
        isWhite
          ? "newsletter-cta newsletter-cta--card"
          : "newsletter-cta newsletter-cta--inline"
      }
    >
      {isSuccess ? (
        <div className="newsletter-cta-success">
          <CheckCircle2 className="newsletter-cta-success-icon" />
          <div>
            <h3 className="newsletter-cta-title">
              {status === "already"
                ? "Vous êtes déjà inscrit·e"
                : "Merci pour votre inscription"}
            </h3>
            <p className="newsletter-cta-desc">
              {status === "already"
                ? "Votre adresse est déjà dans notre liste. À très vite dans votre boîte mail."
                : "Vous recevrez les prochains articles et l'actualité juridique directement dans votre boîte mail."}
            </p>
          </div>
        </div>
      ) : (
        <form onSubmit={onSubmit} className="newsletter-cta-form">
          <div className="newsletter-cta-head">
            <span className="newsletter-cta-icon-wrap">
              <Mail className="newsletter-cta-icon" />
            </span>
            <div>
              <h3 className="newsletter-cta-title">
                Recevez nos nouveaux articles
              </h3>
              <p className="newsletter-cta-desc">
                Une fois par mois, l&apos;actualité juridique de l&apos;immigration
                et de la naturalisation, sans bullshit. Désinscription en un clic.
              </p>
            </div>
          </div>

          <div className="newsletter-cta-row">
            <label htmlFor={`newsletter-email-${source}`} className="sr-only">
              Adresse email
            </label>
            <input
              id={`newsletter-email-${source}`}
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="vous@exemple.fr"
              className="newsletter-cta-input"
              disabled={status === "loading"}
            />
            <button
              type="submit"
              className="newsletter-cta-btn"
              disabled={status === "loading"}
            >
              <Send className="newsletter-cta-btn-icon" />
              {status === "loading" ? "Envoi…" : "S'inscrire"}
            </button>
          </div>

          {errorMessage && (
            <p role="alert" className="newsletter-cta-error">
              {errorMessage}
            </p>
          )}

          <p className="newsletter-cta-legal">
            En vous inscrivant vous acceptez de recevoir nos emails. Pas de spam,
            pas de partage de votre adresse.
          </p>
        </form>
      )}

      <style>{`
        .sr-only {
          position: absolute;
          width: 1px;
          height: 1px;
          padding: 0;
          margin: -1px;
          overflow: hidden;
          clip: rect(0, 0, 0, 0);
          white-space: nowrap;
          border: 0;
        }
        .newsletter-cta {
          border-radius: 20px;
          padding: 26px;
        }
        @media (min-width: 1024px) {
          .newsletter-cta {
            padding: 32px;
          }
        }
        .newsletter-cta--card {
          background: linear-gradient(
            135deg,
            var(--color-blue),
            var(--color-ink-2)
          );
          color: #fff;
          box-shadow: 0 16px 36px -18px rgba(15, 24, 57, 0.4);
        }
        .newsletter-cta--inline {
          background: var(--color-paper);
          border: 1px solid var(--color-line);
          color: var(--color-ink-2);
        }
        .newsletter-cta-form {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }
        .newsletter-cta-head {
          display: flex;
          align-items: flex-start;
          gap: 14px;
        }
        .newsletter-cta-icon-wrap {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 40px;
          height: 40px;
          border-radius: 12px;
          flex-shrink: 0;
        }
        .newsletter-cta--card .newsletter-cta-icon-wrap {
          background: rgba(255, 255, 255, 0.16);
          color: #fff;
        }
        .newsletter-cta--inline .newsletter-cta-icon-wrap {
          background: rgba(30, 58, 140, 0.10);
          color: var(--color-blue);
        }
        .newsletter-cta-icon {
          width: 20px;
          height: 20px;
        }
        .newsletter-cta-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 22px;
          line-height: 1.2;
        }
        @media (min-width: 1024px) {
          .newsletter-cta-title {
            font-size: 26px;
          }
        }
        .newsletter-cta--card .newsletter-cta-title {
          color: #fff;
        }
        .newsletter-cta--inline .newsletter-cta-title {
          color: var(--color-ink);
        }
        .newsletter-cta-desc {
          margin: 6px 0 0 0;
          font-size: 14px;
          line-height: 1.5;
          max-width: 60ch;
        }
        @media (min-width: 1024px) {
          .newsletter-cta-desc {
            font-size: 15px;
          }
        }
        .newsletter-cta--card .newsletter-cta-desc {
          color: rgba(255, 255, 255, 0.85);
        }
        .newsletter-cta--inline .newsletter-cta-desc {
          color: var(--color-muted);
        }
        .newsletter-cta-row {
          display: flex;
          flex-direction: column;
          gap: 10px;
          margin-top: 4px;
        }
        @media (min-width: 640px) {
          .newsletter-cta-row {
            flex-direction: row;
            gap: 12px;
          }
        }
        .newsletter-cta-input {
          flex: 1;
          padding: 13px 14px;
          font-family: var(--font-sans);
          font-size: 15px;
          background: #fff;
          color: var(--color-ink);
          border: 1px solid var(--color-line);
          border-radius: 10px;
          transition: border-color 0.15s, box-shadow 0.15s;
          width: 100%;
          min-width: 0;
        }
        .newsletter-cta-input:focus {
          outline: none;
          border-color: var(--color-blue);
          box-shadow: 0 0 0 4px rgba(30, 58, 140, 0.18);
        }
        .newsletter-cta-input::placeholder {
          color: var(--color-muted-2);
        }
        .newsletter-cta-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 0 22px;
          min-height: 48px;
          border-radius: 10px;
          font-family: var(--font-sans);
          font-size: 14.5px;
          font-weight: 600;
          letter-spacing: -0.005em;
          cursor: pointer;
          transition: all 0.15s;
          border: 0;
        }
        .newsletter-cta-btn:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        .newsletter-cta--card .newsletter-cta-btn {
          background: #fff;
          color: var(--color-blue);
        }
        .newsletter-cta--card .newsletter-cta-btn:hover:not(:disabled) {
          background: rgba(255, 255, 255, 0.9);
        }
        .newsletter-cta--inline .newsletter-cta-btn {
          background: var(--color-blue);
          color: #fff;
        }
        .newsletter-cta--inline .newsletter-cta-btn:hover:not(:disabled) {
          background: var(--color-blue-dark);
        }
        .newsletter-cta-btn-icon {
          width: 16px;
          height: 16px;
        }
        .newsletter-cta-error {
          margin: 0;
          font-size: 13px;
          padding: 10px 12px;
          border-radius: 8px;
          background: rgba(225, 55, 47, 0.12);
          color: #fff;
        }
        .newsletter-cta--inline .newsletter-cta-error {
          background: var(--color-red-light);
          color: var(--color-red-dark);
        }
        .newsletter-cta-legal {
          margin: 0;
          font-size: 11.5px;
          line-height: 1.5;
        }
        .newsletter-cta--card .newsletter-cta-legal {
          color: rgba(255, 255, 255, 0.7);
        }
        .newsletter-cta--inline .newsletter-cta-legal {
          color: var(--color-muted);
        }
        .newsletter-cta-success {
          display: flex;
          align-items: flex-start;
          gap: 14px;
        }
        .newsletter-cta-success-icon {
          width: 28px;
          height: 28px;
          flex-shrink: 0;
        }
        .newsletter-cta--card .newsletter-cta-success-icon {
          color: #fff;
        }
        .newsletter-cta--inline .newsletter-cta-success-icon {
          color: var(--color-green);
        }
      `}</style>
    </div>
  );
}
