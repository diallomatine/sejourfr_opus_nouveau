"use client";

import Link from "next/link";
import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { API_BASE_URL, tokenStorage } from "@/lib/api";

type Plan = "mensuel" | "annuel";

const PLAN_DATA = {
  mensuel: {
    name: "Premium Mensuel",
    base: 14.9,
    discount: 0,
    total: 14.9,
    period: "/mois",
  },
  annuel: {
    name: "Premium Annuel",
    base: 179,
    discount: 64,
    total: 115,
    period: "/an",
  },
} as const;

export default function PaiementPage() {
  return (
    <Suspense fallback={null}>
      <PaiementInner />
    </Suspense>
  );
}

function PaiementInner() {
  const sp = useSearchParams();
  const initialPlan = (sp.get("plan") === "premium" ? "mensuel" : "annuel") as Plan;
  const [plan, setPlan] = useState<Plan>(initialPlan);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const planData = PLAN_DATA[plan];
  const tvaShare = +(planData.total - planData.total / 1.2).toFixed(2);

  async function handleCheckout(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      // Appel d'une route Spring qui crée la session Stripe et retourne l'URL.
      // À implémenter côté backend : POST /api/billing/create-checkout-session
      // → { plan } → { url }
      const token = tokenStorage.getAccess();
      const res = await fetch(`${API_BASE_URL}/api/billing/create-checkout-session`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ plan: plan.toUpperCase() }),
      });

      if (!res.ok) {
        // Fallback démo : on simule juste le succès si le back n'est pas encore prêt
        if (res.status === 404) {
          alert(
            "Démo : la route /api/billing/create-checkout-session n'existe pas encore côté backend. La structure du form est prête, il ne reste qu'à brancher Stripe (côté Java : créer la Stripe Session et retourner { url } ; côté Next : window.location.assign(url)).",
          );
          return;
        }
        throw new Error(`HTTP ${res.status}`);
      }

      const data = (await res.json()) as { url: string };
      window.location.assign(data.url);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Impossible d'initier le paiement.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <div className="checkout-wrap">
        {/* LEFT : FORM */}
        <div>
          <div className="steps-bar">
            <span className="step-done">✓ Compte</span>
            <span className="sep">·</span>
            <span className="step-current">2. Paiement</span>
            <span className="sep">·</span>
            <span>3. Accès</span>
          </div>

          <h1 className="h1-edit">
            Dernière étape <em>avant la préparation</em>.
          </h1>
          <p className="sub">
            Annulable à tout moment · Garantie satisfait remboursé 14 jours.
          </p>

          <form onSubmit={handleCheckout}>
            {/* Plan */}
            <div className="section">
              <div className="section-head">
                <div className="section-num">1</div>
                <h2>Votre formule</h2>
              </div>

              <div className="plan-switch">
                <label
                  className={`plan-opt ${plan === "mensuel" ? "active" : ""}`}
                >
                  <input
                    type="radio"
                    name="plan"
                    value="mensuel"
                    checked={plan === "mensuel"}
                    onChange={() => setPlan("mensuel")}
                  />
                  <div className="pn">Mensuel</div>
                  <div className="pp">
                    14,90 €<span className="small">/mois</span>
                  </div>
                  <div className="pper">Sans engagement</div>
                </label>
                <label
                  className={`plan-opt ${plan === "annuel" ? "active" : ""}`}
                >
                  <span className="ribbon">−35 %</span>
                  <input
                    type="radio"
                    name="plan"
                    value="annuel"
                    checked={plan === "annuel"}
                    onChange={() => setPlan("annuel")}
                  />
                  <div className="pn">Annuel</div>
                  <div className="pp">
                    115 €<span className="small">/an</span>
                  </div>
                  <div className="pper">Soit 9,58 €/mois</div>
                </label>
              </div>
            </div>

            {/* Facturation */}
            <div className="section">
              <div className="section-head">
                <div className="section-num">2</div>
                <h2>Informations de facturation</h2>
              </div>

              <div className="field" style={{ marginBottom: 14 }}>
                <label className="field-label" htmlFor="bill-email">
                  Email
                </label>
                <input
                  id="bill-email"
                  type="email"
                  className="field-input"
                  defaultValue="fatima.achour@example.com"
                  required
                />
              </div>

              <div className="row-2">
                <div className="field">
                  <label className="field-label">Prénom</label>
                  <input type="text" className="field-input" placeholder="Fatima" required />
                </div>
                <div className="field">
                  <label className="field-label">Nom</label>
                  <input type="text" className="field-input" placeholder="Achour" required />
                </div>
              </div>

              <div className="field" style={{ marginTop: 14 }}>
                <label className="field-label">Pays</label>
                <select className="field-input" defaultValue="France">
                  <option>France</option>
                  <option>Belgique</option>
                  <option>Suisse</option>
                  <option>Maroc</option>
                  <option>Tunisie</option>
                  <option>Algérie</option>
                </select>
              </div>
            </div>

            {/* Stripe placeholder */}
            <div className="section">
              <div className="section-head">
                <div className="section-num">3</div>
                <h2>Mode de paiement</h2>
              </div>

              <div className="stripe-placeholder">
                <div className="stripe-line">
                  <span className="ico-card" aria-hidden>💳</span>
                  <div>
                    <div className="stripe-line-title">
                      Vous serez redirigé vers Stripe
                    </div>
                    <div className="stripe-line-sub">
                      Carte bancaire, SEPA, Apple Pay, Google Pay. Chiffrement 256 bits.
                    </div>
                  </div>
                </div>
              </div>

              {error && <div className="form-error" style={{ marginTop: 16 }}>{error}</div>}

              <button
                type="submit"
                disabled={loading}
                className="btn-pay"
                style={{ marginTop: 20 }}
              >
                <span className="lock" aria-hidden>
                  <svg viewBox="0 0 16 16" fill="currentColor">
                    <path d="M5 6V4.5a3 3 0 1 1 6 0V6h1a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h1zm1.5 0h3V4.5a1.5 1.5 0 0 0-3 0V6z" />
                  </svg>
                </span>
                {loading
                  ? "Préparation..."
                  : `Payer ${planData.total.toLocaleString("fr-FR")} € maintenant`}
              </button>

              <p className="legal-row">
                En cliquant sur « Payer », vous acceptez les{" "}
                <Link href="#">CGV</Link> et la{" "}
                <Link href="#">politique de remboursement</Link>.
                <br />
                Votre abonnement {plan} se renouvelle automatiquement. Vous
                pouvez le résilier à tout moment depuis votre espace.
              </p>
            </div>
          </form>
        </div>

        {/* RIGHT : SUMMARY */}
        <div className="summary-wrap">
          <div className="summary">
            <div className="summary-head">
              <div className="tag">Récapitulatif</div>
              <h3>{planData.name}</h3>
            </div>
            <div className="summary-body">
              <div className="sum-line">
                <span className="lbl">{planData.name}</span>
                <span className="val">
                  {planData.base.toLocaleString("fr-FR")},00 €
                </span>
              </div>
              {planData.discount > 0 && (
                <div className="sum-line discount">
                  <span className="lbl">Remise lancement −35 %</span>
                  <span className="val">
                    −{planData.discount.toLocaleString("fr-FR")},00 €
                  </span>
                </div>
              )}
              <div className="sum-line">
                <span className="lbl">TVA incluse (20 %)</span>
                <span className="val">
                  {tvaShare.toLocaleString("fr-FR")} €
                </span>
              </div>

              <div className="sum-total">
                <span className="lbl">Total · TTC</span>
                <span className="val">
                  {planData.total.toLocaleString("fr-FR")},00 €
                </span>
              </div>
            </div>

            <div className="includes">
              <h4>Votre abonnement inclut</h4>
              <ul>
                <li>1 240+ questions tous modules</li>
                <li>Examens blancs illimités (civique + TCF)</li>
                <li>Suivi de progression par thématique</li>
                <li>Mode hors-ligne sur mobile</li>
                <li>Support email sous 24 h</li>
                <li>Mises à jour réglementaires gratuites</li>
              </ul>
            </div>
          </div>

          <div className="trust-bar">
            <div className="trust-line">
              <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden>
                <path d="M8 1 2 4v4c0 4 3 7 6 8 3-1 6-4 6-8V4l-6-3zm0 2.2 4 2v2.8c0 3-2.2 5.4-4 6.2-1.8-.8-4-3.2-4-6.2V5.2l4-2z" />
              </svg>
              <span>
                Paiement <strong>chiffré 256 bits</strong>
              </span>
            </div>
            <div className="trust-line">
              <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden>
                <path d="M14 4 6 12 2 8l1.4-1.4L6 9.2l6.6-6.6L14 4z" />
              </svg>
              <span>
                <strong>Garantie 14 jours</strong> · remboursement sans condition
              </span>
            </div>
            <div className="trust-line">
              <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden>
                <path d="M8 0a8 8 0 1 0 0 16A8 8 0 0 0 8 0zM7 11.4 3.4 7.8l1.4-1.4 2.2 2.2 4.2-4.2 1.4 1.4L7 11.4z" />
              </svg>
              <span>
                Résiliable <strong>en 1 clic</strong> à tout moment
              </span>
            </div>
          </div>

          <div className="stripe-badge">
            Sécurisé par <span className="stripe-logo">Stripe</span>
          </div>
        </div>
      </div>

      <style>{`
        .checkout-wrap {
          max-width: 1140px; margin: 0 auto;
          padding: 56px 28px 80px;
          display: grid;
          grid-template-columns: 1.3fr 1fr;
          gap: 56px;
        }

        .steps-bar {
          display: flex; align-items: center; gap: 10px;
          margin-bottom: 36px;
          font-family: var(--font-mono); font-size: 11px;
          letter-spacing: 0.14em; text-transform: uppercase;
          color: var(--color-muted);
        }
        .step-done { color: var(--color-green); }
        .step-current { color: var(--color-blue); font-weight: 600; }
        .sep { color: var(--color-muted-2); }

        .h1-edit {
          font-family: var(--font-display); font-weight: 500; font-size: 38px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 0 0 12px;
        }
        .h1-edit em { font-style: italic; color: var(--color-red); }
        .sub { color: var(--color-muted); font-size: 16px; margin: 0 0 36px; }

        .section {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          padding: 28px;
          margin-bottom: 18px;
        }
        .section-head {
          display: flex; align-items: center; gap: 12px;
          margin-bottom: 22px;
        }
        .section-num {
          width: 26px; height: 26px;
          background: var(--color-blue); color: #fff;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 12px; font-weight: 700;
          font-family: var(--font-mono);
        }
        .section-head h2 {
          font-family: var(--font-sans); font-weight: 700; font-size: 17px;
          margin: 0; letter-spacing: -0.01em;
        }

        .row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

        .plan-switch { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .plan-opt {
          border: 1.5px solid var(--color-line); border-radius: 12px;
          padding: 16px;
          cursor: pointer;
          transition: all 0.15s;
          position: relative;
          background: #fff;
        }
        .plan-opt:hover { border-color: var(--color-ink-2); }
        .plan-opt input { position: absolute; opacity: 0; pointer-events: none; }
        .plan-opt.active { border-color: var(--color-blue); background: var(--color-blue-light); }
        .plan-opt .ribbon {
          position: absolute; top: -10px; right: 12px;
          background: var(--color-red); color: #fff;
          font-family: var(--font-mono); font-size: 9px;
          letter-spacing: 0.1em; text-transform: uppercase;
          padding: 3px 9px; border-radius: 100px;
          font-weight: 700;
        }
        .plan-opt .pn { font-weight: 700; font-size: 14px; margin-bottom: 4px; }
        .plan-opt .pp {
          font-family: var(--font-display); font-size: 22px; font-weight: 500;
          letter-spacing: -0.01em;
        }
        .plan-opt .pp .small { font-size: 13px; color: var(--color-muted); margin-left: 4px; }
        .plan-opt .pper { font-size: 12px; color: var(--color-muted); margin-top: 2px; }

        .stripe-placeholder {
          background: var(--color-paper);
          border: 1px dashed var(--color-line);
          border-radius: 12px;
          padding: 22px;
        }
        .stripe-line { display: flex; gap: 14px; align-items: flex-start; }
        .ico-card { font-size: 28px; line-height: 1; }
        .stripe-line-title { font-weight: 600; color: var(--color-ink); margin-bottom: 4px; font-size: 14px; }
        .stripe-line-sub { font-size: 13px; color: var(--color-muted); line-height: 1.5; }

        .btn-pay {
          width: 100%;
          background: var(--color-red); color: #fff; border: none; border-radius: 12px;
          padding: 16px 22px; font-size: 16px; font-weight: 700;
          font-family: var(--font-sans);
          cursor: pointer; transition: all 0.15s;
          display: flex; align-items: center; justify-content: center; gap: 10px;
          letter-spacing: -0.01em;
        }
        .btn-pay:hover { background: var(--color-red-dark); transform: translateY(-1px); }
        .btn-pay:disabled { opacity: 0.7; cursor: not-allowed; transform: none; }
        .btn-pay .lock svg { width: 14px; height: 14px; }

        .legal-row {
          margin-top: 18px;
          font-size: 12px; color: var(--color-muted);
          text-align: center; line-height: 1.5;
        }
        .legal-row a { color: var(--color-blue); }

        .summary-wrap { position: sticky; top: 24px; align-self: start; }
        .summary {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          overflow: hidden;
        }
        .summary-head {
          background: var(--color-ink);
          color: #fff;
          padding: 22px 26px;
          position: relative;
        }
        .summary-head::after {
          content: ''; position: absolute;
          bottom: -1px; left: 0; right: 0;
          height: 4px;
          background: linear-gradient(90deg,
            var(--color-blue) 0%, var(--color-blue) 33%,
            #fff 33%, #fff 66%,
            var(--color-red) 66%);
        }
        .summary-head .tag {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.16em; text-transform: uppercase;
          color: rgba(255, 255, 255, 0.55); margin-bottom: 4px;
        }
        .summary-head h3 {
          font-family: var(--font-display); font-weight: 500; font-size: 22px;
          margin: 0; letter-spacing: -0.015em;
        }
        .summary-body { padding: 24px 26px; }
        .sum-line {
          display: flex; justify-content: space-between; align-items: center;
          padding: 12px 0;
          border-bottom: 1px solid var(--color-line-2);
          font-size: 14px;
        }
        .sum-line:last-of-type { border-bottom: none; }
        .sum-line .lbl { color: var(--color-muted); }
        .sum-line .val {
          font-weight: 600; color: var(--color-ink);
          font-family: var(--font-mono);
          font-feature-settings: 'tnum' on;
        }
        .sum-line.discount .val { color: var(--color-green); }
        .sum-total {
          display: flex; justify-content: space-between; align-items: baseline;
          margin-top: 16px;
          padding-top: 18px;
          border-top: 2px solid var(--color-ink);
        }
        .sum-total .lbl {
          font-family: var(--font-mono);
          font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase;
          color: var(--color-muted);
        }
        .sum-total .val {
          font-family: var(--font-display); font-size: 34px; font-weight: 500;
          letter-spacing: -0.02em;
          font-feature-settings: 'tnum' on;
        }
        .includes {
          background: var(--color-paper-2);
          padding: 20px 26px 22px;
          border-top: 1px solid var(--color-line);
        }
        .includes h4 {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.16em; text-transform: uppercase; color: var(--color-muted);
          margin: 0 0 12px;
        }
        .includes ul {
          list-style: none; padding: 0; margin: 0;
          display: flex; flex-direction: column; gap: 8px;
        }
        .includes li {
          display: flex; gap: 10px; align-items: flex-start;
          font-size: 13px; color: var(--color-ink-2); line-height: 1.4;
        }
        .includes li::before {
          content: ''; width: 14px; height: 14px;
          margin-top: 2px; flex-shrink: 0;
          background: var(--color-green);
          -webkit-mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path fill='none' stroke='white' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round' d='M3 8.5l3 3 7-7'/></svg>") no-repeat center / contain;
                  mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path fill='none' stroke='white' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round' d='M3 8.5l3 3 7-7'/></svg>") no-repeat center / contain;
        }
        .trust-bar {
          margin-top: 16px;
          display: flex; flex-direction: column; gap: 10px;
          padding: 18px 22px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 12px;
        }
        .trust-line {
          display: flex; gap: 10px; align-items: center;
          font-size: 13px; color: var(--color-ink-2);
        }
        .trust-line svg { width: 16px; height: 16px; color: var(--color-green); flex-shrink: 0; }
        .trust-line strong { color: var(--color-ink); font-weight: 600; }
        .stripe-badge {
          margin-top: 16px;
          display: flex; align-items: center; justify-content: center; gap: 8px;
          font-family: var(--font-mono); font-size: 11px;
          color: var(--color-muted); letter-spacing: 0.1em;
        }
        .stripe-badge .stripe-logo {
          font-family: var(--font-sans);
          font-weight: 800; color: #635BFF;
          font-size: 13px; letter-spacing: -0.02em;
        }

        @media (max-width: 900px) {
          .checkout-wrap { grid-template-columns: 1fr; gap: 32px; padding: 32px 20px 60px; }
          .summary-wrap { position: static; order: -1; }
          .h1-edit { font-size: 30px; }
        }
      `}</style>
    </>
  );
}
