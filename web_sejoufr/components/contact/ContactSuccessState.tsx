"use client";

import Link from "next/link";
import {ArrowLeft, CheckCircle2, Send} from "lucide-react";

interface Props {
    ticketId: string;
    email: string;
    fullName: string;
    onSendAnother: () => void;
}

export function ContactSuccessState({
                                        ticketId,
                                        email,
                                        fullName,
                                        onSendAnother,
                                    }: Props) {
    const firstName = fullName.split(" ")[0] || fullName;
    return (
        <div className="contact-success">
            <div className="contact-success-icon">
                <CheckCircle2/>
            </div>

            <h2 className="contact-success-title editorial">Message envoyé !</h2>
            <p className="contact-success-sub">
                Merci <strong>{firstName}</strong>, nous avons bien reçu votre message.
                Un email de confirmation vient d&apos;être envoyé à{" "}
                <strong className="contact-success-email">{email}</strong>. Notre équipe
                revient vers vous sous <strong>24 h ouvrées</strong>.
            </p>

            <div className="contact-success-actions">
                <Link href="/" className="btn btn-ghost btn-lg contact-success-btn">
                    <ArrowLeft/>
                    Retour à l&apos;accueil
                </Link>
                <button
                    type="button"
                    onClick={onSendAnother}
                    className="btn btn-lg contact-success-btn"
                >
                    <Send/>
                    Envoyer un autre message
                </button>
            </div>

            <style>{`
        .contact-success {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 20px;
          padding: 36px 24px;
          text-align: center;
          box-shadow: 0 14px 32px -24px rgba(15, 24, 57, 0.18);
        }
        .contact-success-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 64px;
          height: 64px;
          border-radius: 18px;
          background: rgba(22, 143, 91, 0.14);
          color: var(--color-green);
          margin-bottom: 20px;
        }
        .contact-success-icon svg { width: 32px; height: 32px; }
        .contact-success-title {
          margin: 0;
          font-size: clamp(24px, 3vw, 32px);
          line-height: 1.15;
          color: var(--color-ink);
        }
        .contact-success-sub {
          margin: 14px auto 0;
          max-width: 540px;
          color: var(--color-muted);
          font-size: 16px;
          line-height: 1.6;
        }
        .contact-success-sub strong {
          color: var(--color-ink);
          font-weight: 600;
        }
        .contact-success-email {
          word-break: break-all;
        }
        .contact-success-ticket {
          display: inline-block;
          margin-top: 24px;
          padding: 16px 22px;
          border-radius: 16px;
          background: rgba(232, 163, 23, 0.10);
          border: 1px solid rgba(232, 163, 23, 0.35);
          text-align: left;
        }
        .contact-success-ticket-label {
          margin: 0;
          font-family: var(--font-mono);
          font-size: 10.5px;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: #8B5A0A;
          font-weight: 600;
        }
        .contact-success-ticket-id {
          margin: 4px 0 0;
          font-family: var(--font-mono);
          font-size: 18px;
          font-weight: 700;
          letter-spacing: 0.08em;
          color: var(--color-ink);
        }
        .contact-success-ticket-help {
          margin: 4px 0 0;
          font-size: 12px;
          color: #8B5A0A;
        }
        .contact-success-actions {
          margin-top: 28px;
          display: flex;
          flex-direction: column;
          gap: 10px;
          align-items: center;
        }
        .contact-success-btn {
          width: 100%;
          max-width: 320px;
        }
        .contact-success-btn svg { width: 16px; height: 16px; }
        @media (min-width: 640px) {
          .contact-success-actions { flex-direction: row; justify-content: center; }
          .contact-success-btn { width: auto; }
        }
        @media (min-width: 1024px) {
          .contact-success { padding: 52px 40px; }
        }
      `}</style>
        </div>
    );
}
