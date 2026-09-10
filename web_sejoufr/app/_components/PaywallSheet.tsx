"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { track, type AnalyticsCtaLocation } from "@/lib/analytics";
import { trackPaywallViewed } from "@/lib/funnel-events";
import { useTrafficSourceHref } from "@/lib/use-traffic-source";
import { billingApi, learningPlanApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  echeanceLine,
  isContextualised,
  passRecommande,
  paywallContext,
  PAYWALL_PRIORITES_LABEL,
  paywallBenefits,
  paywallCta,
  paywallPitch,
  paywallTitle,
  type PaywallContext,
} from "@/lib/paywall-context";
import type { PlanPublicResponse } from "@/lib/types";

interface PaywallSheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  message?: string;
  /**
   * Module pré-sélectionné quand on arrive sur /paiement. L'utilisateur
   * choisit ensuite la périodicité (mensuel / trimestriel / annuel) sur
   * la page de paiement.
   */
  module?: "CIVIQUE" | "INTEGRAL";
  /**
   * D'où le verrou a été rencontré. C'est ce qui alimente la table « Quel écran
   * déclenche l'achat ? » : sans lui, tous les cadenas du produit se
   * confondraient en une seule ligne « Autre ».
   */
  ctaLocation?: AnalyticsCtaLocation;
  /** Écran précis, quand il apporte plus que l'emplacement. */
  screen?: string;
}

/**
 * Modal (bottom sheet sur mobile, dialog centré sur desktop) qui pousse à
 * l'abonnement. Utilisée quand un utilisateur en mode démo tente de cliquer
 * sur une fonctionnalité premium (thème spécifique, illimité, etc.).
 */
export function PaywallSheet({
  open,
  onClose,
  title = "Continuez en illimité",
  message = "Le mode démo offre 20 questions de découverte. Activez l'abonnement pour accéder à tous les thèmes, l'entraînement illimité, et la révision des erreurs.",
  module = "CIVIQUE",
  ctaLocation = "OTHER",
  screen,
}: PaywallSheetProps) {
  // Une feuille de paywall ouverte, c'est un écran Premium vu : l'étape de
  // funnel est la même que sur `/paiement`. Idempotente côté serveur, et
  // dédupliquée par onglet côté client — rien n'est écrit sur l'appareil.
  useEffect(() => {
    if (open) trackPaywallViewed();
  }, [open]);

  const { user } = useAuth();
  const [ctx, setCtx] = useState<PaywallContext | null>(null);
  const [plans, setPlans] = useState<PlanPublicResponse[] | null>(null);

  /**
   * Contextualisation **best-effort** (`10_` §5). Deux règles :
   *
   * 🛑 Un échec ne dégrade jamais le paywall — on retombe sur le message
   * générique, et surtout on ne bloque pas l'achat.
   * 🛑 Aucun indicateur d'attente : la feuille s'ouvre tout de suite, le
   * contexte s'ajoute quand il arrive. Un spinner devant une offre est le
   * meilleur moyen de perdre l'acheteur.
   */
  useEffect(() => {
    if (!open) return;
    let annule = false;
    void (async () => {
      const [plan, catalogue] = await Promise.all([
        learningPlanApi.getCached().catch(() => null),
        billingApi.listPlans().catch(() => null),
      ]);
      if (annule) return;
      setCtx(paywallContext(plan, user));
      setPlans(catalogue);
    })();
    return () => {
      annule = true;
    };
  }, [open, user]);

  // La provenance suit le visiteur jusqu'à la page d'achat.
  const paymentHref = useTrafficSourceHref(`/paiement?module=${module}`);

  // Fermeture par ESC
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    // Bloque le scroll body pendant que la sheet est ouverte
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [open, onClose]);

  if (!open) return null;

  const contextualise = ctx !== null && isContextualised(ctx);
  const pitch = contextualise ? paywallPitch(ctx) : null;
  const echeance = ctx ? echeanceLine(ctx) : null;
  const pass = ctx ? passRecommande(ctx, plans) : null;

  return (
    <div
      className="pws"
      role="dialog"
      aria-modal="true"
      aria-labelledby="paywall-title"
      onClick={onClose}
    >
      <div className="pws-backdrop" />
      <div
        className="pws-sheet"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          className="pws-close"
          onClick={onClose}
          aria-label="Fermer"
        >
          ✕
        </button>

        <div className="pws-icon" aria-hidden>
          <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
          </svg>
        </div>

        <h2 id="paywall-title" className="pws-title">
          {contextualise ? paywallTitle(ctx!) : title}
        </h2>
        <p className="pws-text">{pitch ?? message}</p>

        {/* L'échéance du candidat, quand il l'a déclarée. */}
        {echeance && <p className="pws-echeance">{echeance}</p>}

        {/* Les priorités RÉELLES, dans l'ordre servi (`10_` §5). Un paywall qui
            promet un plan sans montrer ce qu'il contient ne prouve rien.
            La pastille reprend le rang : le premier point est celui qui bloque
            le plus, et l'œil doit le voir sans lire. */}
        {contextualise && ctx!.priorities.length > 0 && (
          <div className="pws-prio-card">
            <p className="pws-prio-label">{PAYWALL_PRIORITES_LABEL}</p>
            <ul className="pws-priorites">
              {ctx!.priorities.map((p, rang) => (
                <li key={p.skillId}>
                  <span className="pws-dot" data-rang={rang + 1} aria-hidden />
                  {p.title}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Le levier propre aux pass : aligner la durée sur l'échéance. */}
        {pass && <p className="pws-pass">{pass.phrase}</p>}

        {/* 🛑 Deux jeux de bénéfices. Le paywall CONTEXTUALISÉ parle du plan
            que le candidat vient d'entrevoir ; ouvert depuis un cadenas
            quelconque, il retombe sur ce que l'abonnement ouvre en général.
            Servir les bénéfices du plan à qui n'en a pas encore promettrait un
            contenu qui n'existe pas. */}
        {contextualise ? (
          <div className="pws-benefits">
            {paywallBenefits(ctx!).map((benefit) => (
              <div className="pws-benefit" key={benefit.title}>
                <h3>{benefit.title}</h3>
                <p>{benefit.text}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="pws-features">
            <div className="pws-feature">
              <span className="pws-check">✓</span> Plus de 1 200 questions à jour
            </div>
            <div className="pws-feature">
              <span className="pws-check">✓</span> Tous les thèmes, sans limite
            </div>
            <div className="pws-feature">
              <span className="pws-check">✓</span> Examens blancs en conditions
            </div>
            <div className="pws-feature">
              <span className="pws-check">✓</span> Révision des erreurs et favoris
            </div>
          </div>
        )}

        <Link
          href={paymentHref}
          className="btn btn-red btn-lg pws-cta"
          onClick={() => {
            track("PREMIUM_CTA_CLICKED", {ctaLocation, screen});
            onClose();
          }}
        >
          {contextualise ? paywallCta(ctx!) : "Voir les abonnements"} →
        </Link>
        <button type="button" className="pws-later" onClick={onClose}>
          Plus tard
        </button>
      </div>

      <style>{`
        .pws {
          position: fixed; inset: 0;
          z-index: 100;
          display: flex; align-items: flex-end; justify-content: center;
        }
        .pws-backdrop {
          position: absolute; inset: 0;
          background: rgba(15, 24, 57, 0.45);
          animation: pws-fade-in 0.18s ease-out;
        }
        @keyframes pws-fade-in {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes pws-slide-up {
          from { transform: translateY(20px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }
        .pws-sheet {
          position: relative;
          background: #fff;
          border-radius: 22px 22px 0 0;
          padding: 28px 24px 24px;
          width: 100%;
          max-width: 480px;
          box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
          animation: pws-slide-up 0.22s ease-out;
          max-height: 90vh;
          overflow-y: auto;
        }
        .pws-close {
          position: absolute; top: 12px; right: 12px;
          width: 32px; height: 32px;
          background: var(--color-paper-2);
          border: none; border-radius: 8px;
          font-size: 14px;
          color: var(--color-muted);
          cursor: pointer;
        }
        .pws-close:hover { background: var(--color-line); color: var(--color-ink); }
        .pws-icon {
          width: 56px; height: 56px;
          margin: 0 auto 14px;
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          box-shadow: 0 8px 24px -8px rgba(30, 58, 140, 0.4);
        }
        .pws-echeance {
          margin: 0 0 10px;
          font-family: var(--font-mono);
          font-size: 12px;
          color: var(--color-red-dark);
        }
        .pws-priorites {
          list-style: none;
          margin: 0 0 12px;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 6px;
          text-align: left;
        }
        .pws-priorites li {
          font-size: 14px;
          color: var(--color-ink);
          display: flex;
          align-items: center;
          gap: 9px;
        }
        /* La pastille reprend le RANG servi : le premier point est celui qui
           bloque le plus. Trois rouges identiques ne diraient rien de l'ordre. */
        .pws-dot {
          width: 7px;
          height: 7px;
          border-radius: 50%;
          flex: 0 0 auto;
          background: var(--color-amber, #e8a317);
        }
        .pws-dot[data-rang="1"] { background: var(--color-red); }
        .pws-prio-card {
          text-align: left;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          padding: 14px 16px;
          margin-bottom: 12px;
        }
        .pws-prio-label {
          margin: 0 0 8px;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.06em;
          text-transform: uppercase;
          color: var(--color-muted);
        }
        /* Les bénéfices du PLAN : un titre, une phrase. Ils remplacent la liste
           générique quand le paywall sait de quoi il parle. */
        .pws-benefits {
          text-align: left;
          display: flex;
          flex-direction: column;
          gap: 14px;
          margin-bottom: 16px;
        }
        .pws-benefit h3 {
          margin: 0;
          font-size: 14.5px;
          font-weight: 650;
          color: var(--color-ink);
        }
        .pws-benefit p {
          margin: 3px 0 0;
          font-size: 13px;
          line-height: 1.5;
          color: var(--color-muted);
        }
        .pws-priorites li:nth-child(n + 2)::before {
          background: var(--color-amber);
        }
        .pws-pass {
          margin: 0 0 12px;
          font-size: 13px;
          color: var(--color-blue-dark);
          background: var(--color-blue-light);
          border-radius: 10px;
          padding: 10px 12px;
        }
        .pws-title {
          font-family: var(--font-display);
          font-weight: 500; font-size: 24px;
          letter-spacing: -0.015em;
          text-align: center;
          margin: 0 0 8px;
          color: var(--color-ink);
        }
        .pws-text {
          font-size: 13.5px; line-height: 1.55;
          color: var(--color-muted);
          text-align: center;
          margin: 0 0 18px;
        }
        .pws-features {
          background: var(--color-paper);
          border-radius: 12px;
          padding: 14px 16px;
          margin-bottom: 18px;
          display: flex; flex-direction: column; gap: 8px;
        }
        .pws-feature {
          font-size: 13.5px; color: var(--color-ink-2);
          display: flex; align-items: center; gap: 10px;
        }
        .pws-check {
          color: var(--color-green);
          font-weight: 700;
        }
        .pws-cta {
          width: 100%;
          text-align: center;
          margin-bottom: 8px;
        }
        .pws-later {
          width: 100%;
          padding: 10px;
          background: none; border: none;
          font-family: var(--font-sans);
          font-size: 13px;
          color: var(--color-muted);
          cursor: pointer;
        }
        .pws-later:hover { color: var(--color-ink); }

        @media (min-width: 640px) {
          .pws { align-items: center; }
          .pws-sheet { border-radius: 22px; }
        }
      `}</style>
    </div>
  );
}
