"use client";

import Link from "next/link";
import { useEffect } from "react";
import { CalendarOff, Check, Ticket } from "lucide-react";
import { track, type AnalyticsCtaLocation } from "@/lib/analytics";
import { trackPaywallViewed } from "@/lib/funnel-events";
import { useTrafficSourceHref } from "@/lib/use-traffic-source";
import { withPurchaseOrigin } from "@/lib/purchase-origin";
import {
  PASS_FEATURES,
  PASS_OFFER_CTA,
  PASS_OFFER_LATER,
  PASS_OFFER_PLAN,
  PASS_OFFER_TEXT,
  PASS_OFFER_TITLE,
  PASS_ONE_TIME_NOTE,
  type PassModule,
} from "@/lib/passes";

interface PaywallSheetProps {
  open: boolean;
  onClose: () => void;
  /**
   * Le pass qui ouvre le contenu touché : `INTEGRAL` pour tout le TCF,
   * `CIVIQUE` pour le civique (que l'Intégral ouvre aussi). Il choisit le
   * titre, la phrase, les puces (`PASS_FEATURES`) et le pass désigné sur
   * `/paiement` (`?plan=`).
   */
  module: PassModule;
  /**
   * Une phrase propre à l'écran (« Le 1ᵉʳ sujet est offert ; les suivants
   * sont dans le pass Intégral. »). Absente ⇒ `PASS_OFFER_TEXT`. Le titre,
   * lui, ne se surcharge pas : il est le même partout, web et mobile.
   */
  reason?: string;
  /**
   * D'où le verrou a été rencontré — **obligatoire, sans défaut** (contrôle F,
   * 2026-09-25) : l'ancien défaut `OTHER` rangeait en `OTHER_CTA` des achats
   * partis du Plan. Chaque appel choisit : hors Plan, le CTA que l'écran pose
   * déjà sur son verrou ; depuis le Plan, `LOCKED_PLAN` + `journeyId` servi ;
   * origine réellement inconnue, `null` ⇒ aucune intention ⇒ `UNKNOWN`.
   */
  ctaLocation: AnalyticsCtaLocation | null;
  /** Écran précis, quand il apporte plus que l'emplacement. */
  screen?: string;
  /** Le parcours affiché (`plan_id`), quand la feuille s'ouvre sur un Plan :
   *  il suit l'achat jusqu'à l'intention (Q12). */
  journeyId?: string | null;
}

/**
 * La feuille d'offre (bottom sheet sur mobile, dialog centré sur desktop) :
 * un compte sans le pass du module touche un contenu verrouillé.
 *
 * 🛑 **Tout son texte vient de `lib/passes.ts`** (`PASS_OFFER_*`,
 * `PASS_FEATURES`), miroir mot pour mot de `PlanModuleTargetX` côté mobile.
 * Aucun prix : il faudrait un appel au catalogue à l'ouverture, et la règle
 * du paywall est « aucun appel réseau de plus » (`docs/regles/paiements.md`).
 */
export function PaywallSheet({
  open,
  onClose,
  module,
  reason,
  ctaLocation,
  screen,
  journeyId = null,
}: PaywallSheetProps) {
  // Une feuille de paywall ouverte, c'est un écran Premium vu : l'étape de
  // funnel est la même que sur `/paiement`. Idempotente côté serveur, et
  // dédupliquée par onglet côté client — rien n'est écrit sur l'appareil.
  useEffect(() => {
    if (open) trackPaywallViewed();
  }, [open]);

  // La provenance suit le visiteur jusqu'à la page d'achat.
  // Le CTA de la feuille voyage aussi : c'est lui qui fonde l'intention d'achat.
  const paymentHref = useTrafficSourceHref(
    withPurchaseOrigin(`/paiement?plan=${PASS_OFFER_PLAN[module]}`, {ctaLocation, journeyId}),
  );

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

  const title = PASS_OFFER_TITLE[module];

  /* 🛑 **Aucun bandeau de contexte** (demande du propriétaire, 2026-09-20).
     L'en-tête personnalisé était déjà parti ; les deux derniers bandeaux —
     « Objectif B2 avant le … — il vous reste N jours. » et « Votre examen est
     le … Le pass N couvre toute votre préparation. » — sont partis avec, et
     avec eux `lib/paywall-context.ts`, qui ne servait plus qu'à les composer.
     Ne pas les réintroduire : l'offre dit le prix, pas l'échéance. */
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
          <Ticket size={26} strokeWidth={1.8} />
        </div>

        <h2 id="paywall-title" className="pws-title">
          {title.lead}<em>{title.em}</em>
        </h2>
        <p className="pws-text">{reason ?? PASS_OFFER_TEXT[module]}</p>

        <ul className="pws-features">
          {PASS_FEATURES[module].map((f) => (
            <li key={f} className="pws-feature">
              <Check className="pws-check" size={15} strokeWidth={2.4} aria-hidden />
              <span>{f}</span>
            </li>
          ))}
        </ul>

        <p className="pws-note">
          <CalendarOff size={13} aria-hidden />
          {PASS_ONE_TIME_NOTE}
        </p>

        <Link
          href={paymentHref}
          className="btn btn-red btn-lg pws-cta"
          onClick={() => {
            track("PREMIUM_CTA_CLICKED", ctaLocation ? {ctaLocation, screen} : {screen});
            onClose();
          }}
        >
          {PASS_OFFER_CTA} →
        </Link>
        <button type="button" className="pws-later" onClick={onClose}>
          {PASS_OFFER_LATER}
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
          background: color-mix(in srgb, var(--color-ink) 45%, transparent);
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
          background: var(--color-white);
          border-radius: 22px 22px 0 0;
          padding: 28px 24px 24px;
          width: 100%;
          max-width: 480px;
          box-shadow: 0 -10px 50px -10px color-mix(in srgb, var(--color-ink) 25%, transparent);
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
          background: var(--color-blue-light);
          color: var(--color-blue);
          border-radius: 16px;
          display: flex; align-items: center; justify-content: center;
        }
        .pws-title {
          font-family: var(--font-display);
          font-weight: 500; font-size: 24px;
          letter-spacing: -0.015em;
          text-align: center;
          margin: 0 0 8px;
          color: var(--color-ink);
        }
        .pws-title em { font-style: italic; color: var(--color-red); }
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
          margin: 0 0 12px;
          list-style: none;
          display: flex; flex-direction: column; gap: 9px;
        }
        .pws-feature {
          font-size: 13.5px; line-height: 1.45; color: var(--color-ink-2);
          display: flex; align-items: flex-start; gap: 10px;
        }
        .pws-check {
          flex: none;
          margin-top: 2px;
          color: var(--color-green);
        }
        .pws-note {
          display: flex; align-items: center; justify-content: center; gap: 6px;
          margin: 0 0 16px;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.02em;
          color: var(--color-muted);
          text-align: center;
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
