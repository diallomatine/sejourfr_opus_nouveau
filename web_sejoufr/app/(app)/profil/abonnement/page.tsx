"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { ApiException, billingApi } from "@/lib/api";
import type {
  CancelSubscriptionResponse,
  SubscriptionSource,
  SubscriptionStatusResponse,
} from "@/lib/types";

/**
 * Page « Mon abonnement ». Détail du Premium en cours + bouton de résiliation.
 * Le routing est décidé côté backend selon la source de l'abo :
 * - Stripe → POST /api/billing/cancel renvoie `action=DONE`, on refresh le user.
 * - Apple/Google → `action=REDIRECT`, on ouvre la page de gestion du store dans
 *   un nouvel onglet (les stores n'autorisent pas l'annulation côté serveur).
 *
 * Le statut local ne bascule sur Apple/Google qu'à réception du webhook du store
 * confirmant l'annulation — l'UI invite donc l'utilisateur à finir l'opération
 * dans le store puis revenir.
 */
export default function MonAbonnementPage() {
  const router = useRouter();
  const { user, status: authStatus, refreshUser } = useAuth();

  const [status, setStatus] = useState<SubscriptionStatusResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [confirmOpen, setConfirmOpen] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [lastResult, setLastResult] = useState<CancelSubscriptionResponse | null>(
    null,
  );
  const [actionError, setActionError] = useState<string | null>(null);

  const fetchStatus = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const s = await billingApi.getSubscriptionStatus();
      setStatus(s);
    } catch (e) {
      setLoadError(
        e instanceof ApiException
          ? e.message
          : "Impossible de charger votre abonnement.",
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authStatus !== "authenticated") return;
    void fetchStatus();
  }, [authStatus, fetchStatus]);

  // Body lock pendant la modal de confirmation.
  useEffect(() => {
    if (!confirmOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [confirmOpen]);

  if (authStatus === "loading") {
    return <PageSkeleton />;
  }
  if (!user) {
    return (
      <main className="ab-gate">
        <p>Connectez-vous pour gérer votre abonnement.</p>
        <Link href="/connexion?next=/profil/abonnement" className="ab-gate-cta">
          Se connecter →
        </Link>
        <style>{gateStyles}</style>
      </main>
    );
  }

  async function handleCancel() {
    setConfirmOpen(false);
    setCancelling(true);
    setActionError(null);
    try {
      const res = await billingApi.cancel();
      setLastResult(res);
      if (res.action === "DONE") {
        // Stripe : statut backend mis à jour. Refresh le user pour propager
        // autoRenew=false + status CANCELED dans toute l'app.
        await refreshUser();
        await fetchStatus();
      } else if (res.action === "REDIRECT" && res.redirectUrl) {
        // Apple/Google : on ouvre la page de gestion du store. Le statut
        // local ne bouge qu'à réception du webhook ; on re-fetch quand même
        // au retour de la page pour rafraîchir si l'user était rapide.
        window.open(res.redirectUrl, "_blank", "noopener,noreferrer");
      }
    } catch (e) {
      setActionError(
        e instanceof ApiException
          ? e.message
          : "Impossible d'enregistrer la résiliation. Réessayez.",
      );
    } finally {
      setCancelling(false);
    }
  }

  return (
    <main className="ab">
      <div className="ab-breadcrumb">
        <Link href="/profil">← Mon profil</Link>
      </div>

      <h1 className="ab-title">
        Mon <em>abonnement</em>
      </h1>

      {loading && <PageSkeleton inline />}
      {!loading && loadError && (
        <div className="ab-error">
          <p>{loadError}</p>
          <button type="button" className="btn btn-ghost" onClick={fetchStatus}>
            Réessayer
          </button>
        </div>
      )}

      {!loading && !loadError && status && !status.isPremium && (
        <NotPremiumView />
      )}

      {!loading && !loadError && status?.isPremium && (
        <PremiumView
          status={status}
          cancelling={cancelling}
          lastResult={lastResult}
          actionError={actionError}
          onCancelClick={() => setConfirmOpen(true)}
        />
      )}

      {confirmOpen && status && (
        <ConfirmCancelModal
          status={status}
          onCancel={() => setConfirmOpen(false)}
          onConfirm={handleCancel}
        />
      )}

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// Vues
// ============================================================================

function PremiumView({
  status,
  cancelling,
  lastResult,
  actionError,
  onCancelClick,
}: {
  status: SubscriptionStatusResponse;
  cancelling: boolean;
  lastResult: CancelSubscriptionResponse | null;
  actionError: string | null;
  onCancelClick: () => void;
}) {
  const isCanceled = status.status === "CANCELED";
  // Pass one-time (lot 5) : aucune reconduction → « Mon accès » sans résiliation.
  const isOneTime = status.oneTime === true;
  const planLabel =
    status.moduleAccess === "INTEGRAL"
      ? "Plan Intégral · Civique + TCF"
      : status.moduleAccess === "CIVIQUE"
        ? "Plan Civique"
        : "Plan TCF";

  return (
    <>
      <section className={`ab-hero ${isCanceled ? "ab-hero-canceled" : ""}`}>
        <div className="ab-hero-head">
          <span className="ab-eyebrow">PLAN ACTUEL</span>
          <span
            className={`ab-pill ${isCanceled ? "ab-pill-warn" : "ab-pill-ok"}`}
          >
            {isCanceled ? "Résilié" : "Actif"}
          </span>
        </div>
        <h2>{planLabel}</h2>
        <p>
          {isOneTime
            ? "Accès payé une fois, sans abonnement ni reconduction."
            : isCanceled
              ? "Renouvellement automatique désactivé."
              : "Renouvellement automatique activé."}
        </p>
      </section>

      <section className="ab-details">
        <h3 className="ab-section-title">Détails</h3>
        <dl>
          <DetailRow label="Géré par" value={sourceLabel(status.source)} />
          <DetailRow
            label={isCanceled || isOneTime ? "Accès jusqu'au" : "Prochain renouvellement"}
            value={formatLong(status.expiresAt) ?? "—"}
          />
          {status.productId && (
            <DetailRow label="Référence" value={status.productId} mono />
          )}
        </dl>
      </section>

      {isOneTime && (
        <section className="ab-note">
          <strong>Accès sans abonnement.</strong>{" "}
          {status.expiresAt
            ? `Vous gardez l'accès jusqu'au ${formatLong(status.expiresAt)}. Rien à résilier — rachetez un pass pour prolonger.`
            : "Rien à résilier — rachetez un pass pour prolonger."}
        </section>
      )}

      {!isCanceled && !isOneTime && (
        <section className="ab-action">
          <button
            type="button"
            className="ab-cancel-btn"
            onClick={onCancelClick}
            disabled={cancelling}
          >
            {cancelling ? "Résiliation…" : "Résilier mon abonnement"}
          </button>
          <p className="ab-help">
            {status.source === "STRIPE"
              ? "Votre accès Premium restera ouvert jusqu'à la date d'expiration, puis ne sera pas renouvelé."
              : "Vous serez redirigé vers la page de gestion d'abonnement du store pour confirmer la résiliation."}
          </p>
        </section>
      )}

      {isCanceled && (
        <section className="ab-note ab-note-warn">
          <strong>Abonnement résilié.</strong>{" "}
          {status.expiresAt
            ? `Vous conservez l'accès Premium jusqu'au ${formatLong(status.expiresAt)}.`
            : "Vous conservez l'accès Premium jusqu'à la fin de la période en cours."}
        </section>
      )}

      {actionError && (
        <section className="ab-note ab-note-error">{actionError}</section>
      )}

      {lastResult?.action === "DONE" && (
        <section className="ab-note ab-note-ok">{lastResult.message}</section>
      )}

      {lastResult?.action === "REDIRECT" && lastResult.redirectUrl && (
        <section className="ab-note ab-note-warn">
          <strong>Action requise dans le store.</strong>
          <p style={{ margin: "6px 0 8px" }}>{lastResult.message}</p>
          <a
            href={lastResult.redirectUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="ab-help-link"
          >
            Rouvrir la page du store →
          </a>
        </section>
      )}
    </>
  );
}

function NotPremiumView() {
  return (
    <section className="ab-empty">
      <h2>Aucun abonnement actif</h2>
      <p>
        Vous êtes sur le plan Découverte. Pour débloquer l&apos;accès complet
        aux modules, choisissez une offre.
      </p>
      <Link href="/paiement" className="btn btn-red">
        Passer Premium
      </Link>
    </section>
  );
}

function DetailRow({
  label,
  value,
  mono = false,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="ab-row">
      <dt>{label}</dt>
      <dd className={mono ? "ab-mono" : ""}>{value}</dd>
    </div>
  );
}

// ============================================================================
// Modal confirmation
// ============================================================================

function ConfirmCancelModal({
  status,
  onCancel,
  onConfirm,
}: {
  status: SubscriptionStatusResponse;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onCancel]);

  const isRedirect = status.source === "APPLE" || status.source === "GOOGLE";
  const body = isRedirect
    ? `Vous serez redirigé vers ${storeLabel(status.source)} dans un nouvel onglet pour confirmer la résiliation. L'accès Premium restera ouvert jusqu'à l'expiration en cours.`
    : `Votre accès Premium restera ouvert jusqu'au ${formatLong(status.expiresAt) ?? "à la fin de la période"}, puis ne sera pas renouvelé. Vous pourrez réactiver l'abonnement plus tard.`;

  return (
    <div className="ab-modal" role="dialog" aria-modal="true" onClick={onCancel}>
      <div className="ab-modal-backdrop" />
      <div className="ab-modal-sheet" onClick={(e) => e.stopPropagation()}>
        <h2 className="ab-modal-title">Résilier l&apos;abonnement ?</h2>
        <p className="ab-modal-body">{body}</p>
        <div className="ab-modal-actions">
          <button
            type="button"
            className="ab-modal-btn ab-modal-btn-ghost"
            onClick={onCancel}
          >
            Annuler
          </button>
          <button
            type="button"
            className="ab-modal-btn ab-modal-btn-danger"
            onClick={onConfirm}
          >
            {isRedirect ? "Ouvrir le store" : "Résilier"}
          </button>
        </div>
      </div>
      <style>{modalStyles}</style>
    </div>
  );
}

// ============================================================================
// Helpers
// ============================================================================

function sourceLabel(s: SubscriptionSource | null): string {
  switch (s) {
    case "STRIPE":
      return "Carte bancaire (Stripe)";
    case "APPLE":
      return "App Store (Apple)";
    case "GOOGLE":
      return "Google Play";
    default:
      return "—";
  }
}

function storeLabel(s: SubscriptionSource | null): string {
  switch (s) {
    case "APPLE":
      return "l'App Store";
    case "GOOGLE":
      return "Google Play";
    default:
      return "le store";
  }
}

function formatLong(iso: string | null): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  return d.toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

function PageSkeleton({ inline = false }: { inline?: boolean }) {
  return (
    <div className={inline ? "ab-skel-inline" : "ab-skel"}>
      <style>{`.ab-skel { min-height: 60vh; background: var(--color-paper); }
.ab-skel-inline { height: 160px; border-radius: 16px; background: var(--color-line-2); animation: pulse 1.2s ease-in-out infinite; }
@keyframes pulse { 0%,100% { opacity: .55; } 50% { opacity: 1; } }`}</style>
    </div>
  );
}

// ============================================================================
// Styles
// ============================================================================

const gateStyles = `
.ab-gate { min-height: 60vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 14px; color: var(--color-muted); padding: 36px; }
.ab-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

const styles = `
.ab { max-width: 720px; margin: 0 auto; padding: 24px 24px 64px; display: flex; flex-direction: column; gap: 22px; }
@media (max-width: 600px) { .ab { padding: 20px 16px 56px; gap: 18px; } }

.ab-breadcrumb { font-family: var(--font-mono); font-size: 11.5px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-muted); }
.ab-breadcrumb a { color: var(--color-muted); text-decoration: none; }
.ab-breadcrumb a:hover { color: var(--color-blue); }

.ab-title { font-family: var(--font-display); font-weight: 600; font-size: clamp(26px, 4vw, 34px); letter-spacing: -0.02em; line-height: 1.1; color: var(--color-ink); margin: 0; }
.ab-title em { font-style: italic; color: var(--color-red); font-weight: 500; }

/* Hero plan */
.ab-hero { border-radius: 18px; padding: 22px 24px; color: #fff; background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%); box-shadow: 0 16px 38px -22px rgba(30,58,140,0.4); }
.ab-hero-canceled { background: linear-gradient(135deg, var(--color-muted) 0%, var(--color-ink-2) 100%); box-shadow: 0 16px 38px -22px rgba(15,24,57,0.4); }
.ab-hero-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.ab-eyebrow { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.14em; color: rgba(255,255,255,0.78); font-weight: 700; text-transform: uppercase; }
.ab-pill { font-family: var(--font-sans); font-size: 11.5px; font-weight: 700; padding: 4px 11px; border-radius: 99px; letter-spacing: 0.02em; }
.ab-pill-ok { background: rgba(255,255,255,0.18); color: #fff; }
.ab-pill-warn { background: var(--color-amber); color: var(--color-ink); }
.ab-hero h2 { font-family: var(--font-display); font-weight: 600; font-size: 26px; letter-spacing: -0.02em; margin: 0 0 6px; }
.ab-hero p { font-size: 14px; opacity: 0.85; margin: 0; }

/* Détails */
.ab-details { background: #fff; border: 1px solid var(--color-line); border-radius: 16px; padding: 18px 20px; }
.ab-section-title { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted); font-weight: 700; margin: 0 0 14px; }
.ab-details dl { margin: 0; display: flex; flex-direction: column; gap: 4px; }
.ab-row { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 10px 0; border-bottom: 1px solid var(--color-line-2); }
.ab-row:last-child { border-bottom: none; }
.ab-row dt { font-size: 13px; color: var(--color-muted); margin: 0; }
.ab-row dd { font-size: 14px; font-weight: 700; color: var(--color-ink); margin: 0; text-align: right; word-break: break-all; }
.ab-mono { font-family: var(--font-mono); font-size: 12.5px; font-weight: 600; }

/* CTA cancel */
.ab-action { display: flex; flex-direction: column; gap: 10px; }
.ab-cancel-btn { display: inline-flex; align-items: center; justify-content: center; padding: 14px 22px; border-radius: 12px; border: 1px solid color-mix(in srgb, var(--color-red) 30%, transparent); background: var(--color-red-light); color: var(--color-red); font-family: var(--font-sans); font-weight: 700; font-size: 14.5px; cursor: pointer; transition: all 0.15s; }
.ab-cancel-btn:hover:not(:disabled) { background: var(--color-red); color: #fff; }
.ab-cancel-btn:disabled { opacity: 0.6; cursor: not-allowed; }
.ab-help { font-size: 12.5px; color: var(--color-muted); margin: 0; line-height: 1.5; }
.ab-help-link { color: var(--color-blue); font-weight: 700; text-decoration: none; font-size: 13px; }
.ab-help-link:hover { text-decoration: underline; }

/* Notes (feedback DONE/REDIRECT/error) */
.ab-note { padding: 12px 14px; border-radius: 12px; font-size: 13.5px; line-height: 1.55; color: var(--color-ink); border: 1px solid; }
.ab-note-ok { background: color-mix(in srgb, var(--color-green) 8%, transparent); border-color: color-mix(in srgb, var(--color-green) 30%, transparent); }
.ab-note-warn { background: color-mix(in srgb, var(--color-amber) 10%, transparent); border-color: color-mix(in srgb, var(--color-amber) 30%, transparent); }
.ab-note-error { background: var(--color-red-light); border-color: color-mix(in srgb, var(--color-red) 30%, transparent); color: var(--color-red); }

/* États vides / erreur */
.ab-error { background: var(--color-red-light); border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent); border-radius: 14px; padding: 18px; display: flex; flex-direction: column; gap: 12px; align-items: flex-start; color: var(--color-red); }
.ab-empty { background: #fff; border: 1px solid var(--color-line); border-radius: 18px; padding: 26px; text-align: center; display: flex; flex-direction: column; gap: 12px; align-items: center; }
.ab-empty h2 { font-family: var(--font-display); font-weight: 600; font-size: 20px; margin: 0; color: var(--color-ink); }
.ab-empty p { font-size: 13.5px; color: var(--color-muted); margin: 0; max-width: 380px; }
`;

const modalStyles = `
.ab-modal { position: fixed; inset: 0; z-index: 100; display: flex; align-items: flex-end; justify-content: center; }
.ab-modal-backdrop { position: absolute; inset: 0; background: rgba(15, 24, 57, 0.55); backdrop-filter: blur(4px); animation: ab-fade 0.18s ease-out; }
@keyframes ab-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes ab-slide { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
.ab-modal-sheet { position: relative; background: #fff; border-radius: 22px 22px 0 0; padding: 28px 28px 22px; width: 100%; max-width: 460px; animation: ab-slide 0.22s ease-out; box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25); }
@media (min-width: 640px) { .ab-modal { align-items: center; } .ab-modal-sheet { border-radius: 18px; } }
.ab-modal-title { font-family: var(--font-display); font-weight: 600; font-size: 22px; letter-spacing: -0.02em; color: var(--color-ink); margin: 0 0 8px; }
.ab-modal-body { font-size: 14px; line-height: 1.55; color: var(--color-muted); margin: 0 0 22px; }
.ab-modal-actions { display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap; }
.ab-modal-btn { padding: 10px 16px; border-radius: 10px; font-family: inherit; font-size: 13px; font-weight: 600; cursor: pointer; border: 1px solid transparent; transition: all 0.15s; }
.ab-modal-btn-ghost { background: #fff; border-color: var(--color-line); color: var(--color-ink); }
.ab-modal-btn-ghost:hover { border-color: var(--color-ink); }
.ab-modal-btn-danger { background: var(--color-red); color: #fff; }
.ab-modal-btn-danger:hover { background: var(--color-red-dark); }
`;
