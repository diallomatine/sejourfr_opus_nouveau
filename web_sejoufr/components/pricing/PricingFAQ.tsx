"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";

interface QA {
  question: string;
  answer: React.ReactNode;
}

const ITEMS: QA[] = [
  {
    question: "Quel pass choisir ?",
    answer: (
      <>
        Cela dépend de la date de votre examen. S&apos;il est{" "}
        <strong>dans quelques jours</strong>, le pass 7 jours suffit pour réviser
        à fond. Si vous préparez le TCF sur plusieurs semaines, le pass 2 mois
        vous laisse le temps d&apos;enchaîner les examens blancs et revient moins
        cher au mois. Le pass Civique, lui, ne couvre que l&apos;examen civique —
        pour le TCF IRN, il faut un pass Intégral.
      </>
    ),
  },
  {
    question: "Que se passe-t-il à la fin de la période ?",
    answer: (
      <>
        Votre accès Premium expire automatiquement à la date de fin.{" "}
        <strong>Aucun renouvellement automatique.</strong> Vous gardez votre
        compte gratuit avec votre progression sauvegardée — vous pouvez
        re-souscrire à tout moment.
      </>
    ),
  },
  {
    question: "Comment payer ?",
    answer: (
      <>
        Par carte bancaire via <strong>Stripe</strong>, le standard du paiement
        en ligne (certifié PCI-DSS, 3D-Secure). Aucune information bancaire
        n&apos;est stockée sur nos serveurs.
      </>
    ),
  },
  {
    question: "Vais-je recevoir une facture ?",
    answer: (
      <>
        Oui, une facture officielle vous est envoyée par email immédiatement
        après votre paiement. Vous la retrouvez aussi dans votre espace
        personnel.
      </>
    ),
  },
  {
    question: "Puis-je changer de pass ?",
    answer: (
      <>
        Oui, à n&apos;importe quel moment. Un nouveau pass acheté avant la fin du
        précédent <strong>prolonge</strong> votre accès : les durées se cumulent.
        Passer du Civique à l&apos;Intégral ouvre le TCF immédiatement. En
        revanche, un pass entamé n&apos;est pas remboursé — c&apos;est un
        paiement unique.
      </>
    ),
  },
];

export function PricingFAQ() {
  const [openIdx, setOpenIdx] = useState<number | null>(0);

  return (
    <section className="pfaq">
      <h2 className="pfaq-title editorial">Questions fréquentes</h2>
      <ul className="pfaq-list">
        {ITEMS.map((it, idx) => {
          const open = openIdx === idx;
          return (
            <li key={it.question} className={`pfaq-item ${open ? "is-open" : ""}`}>
              <button
                type="button"
                onClick={() => setOpenIdx(open ? null : idx)}
                aria-expanded={open}
                className="pfaq-trigger"
              >
                <span className="pfaq-q">{it.question}</span>
                <ChevronDown className="pfaq-chev" />
              </button>
              {open && <div className="pfaq-answer">{it.answer}</div>}
            </li>
          );
        })}
      </ul>

      <style>{`
        .pfaq {
          margin-top: 56px;
          max-width: 720px;
          margin-left: auto;
          margin-right: auto;
        }
        .pfaq-title {
          margin: 0 0 22px;
          text-align: center;
          font-size: clamp(24px, 3vw, 32px);
          color: var(--color-ink);
        }
        .pfaq-list {
          list-style: none;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        .pfaq-item {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          overflow: hidden;
          transition: box-shadow 0.15s ease, border-color 0.15s ease;
        }
        .pfaq-item.is-open {
          box-shadow: 0 14px 32px -22px rgba(30, 58, 140, 0.22);
          border-color: var(--color-line-2);
        }
        .pfaq-trigger {
          width: 100%;
          display: flex;
          align-items: flex-start;
          gap: 14px;
          padding: 18px 22px;
          min-height: 60px;
          background: none;
          border: 0;
          text-align: left;
          cursor: pointer;
          color: inherit;
        }
        .pfaq-trigger:focus-visible {
          outline: none;
          box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.18);
        }
        .pfaq-q {
          flex: 1;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 16px;
          line-height: 1.4;
          color: var(--color-ink);
        }
        .pfaq-chev {
          width: 20px;
          height: 20px;
          flex-shrink: 0;
          margin-top: 2px;
          color: var(--color-muted-2);
          transition: transform 0.2s ease, color 0.2s ease;
        }
        .pfaq-item.is-open .pfaq-chev {
          transform: rotate(180deg);
          color: var(--color-blue);
        }
        .pfaq-answer {
          padding: 8px 22px 20px;
          font-size: 14.5px;
          line-height: 1.6;
          color: var(--color-ink-2);
          border-top: 1px solid var(--color-line-2);
          padding-top: 16px;
        }
        .pfaq-answer strong {
          font-weight: 600;
          color: var(--color-ink);
        }
        @media (min-width: 1024px) {
          .pfaq { margin-top: 72px; }
          .pfaq-q { font-size: 17px; }
        }
      `}</style>
    </section>
  );
}
