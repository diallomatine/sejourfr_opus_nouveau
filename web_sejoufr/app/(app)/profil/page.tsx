"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";

const EXAM_DATE_KEY = "sejourfr.examDate";

/**
 * Page profil : vue d'ensemble du compte avec sections en settings-list.
 *  - Le parcours (CSP/CR/NAT) se modifie sur /parcours
 *  - Le mot de passe via /mot-de-passe-oublie (en attendant /api/me/change-password)
 *  - firstName/lastName non éditable pour l'instant (pas d'endpoint /api/me/profile)
 *  - Suppression de compte = stub modal (en attendant DELETE /api/me/account)
 *  - Date d'examen stockée en localStorage (synchro avec le dashboard)
 */
export default function ProfilPage() {
  const router = useRouter();
  const { user, status, logout } = useAuth();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteSoon, setShowDeleteSoon] = useState(false);
  const [showEditNameSoon, setShowEditNameSoon] = useState(false);
  const [examDate, setExamDate] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const v = window.localStorage.getItem(EXAM_DATE_KEY);
    if (v) setExamDate(v);
  }, []);

  useEffect(() => {
    if (!showLogoutConfirm && !showDeleteSoon && !showEditNameSoon) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [showLogoutConfirm, showDeleteSoon, showEditNameSoon]);

  function handleLogout() {
    logout();
    router.push("/");
  }

  if (status === "loading") return <ProfilSkeleton />;
  if (!user) {
    return (
      <main className="pr-gate">
        <p>Connectez-vous pour voir votre compte.</p>
        <Link href="/connexion?next=/profil" className="pr-gate-cta">
          Se connecter →
        </Link>
        <style>{gateStyles}</style>
      </main>
    );
  }

  const fullName =
    [user.firstName, user.lastName].filter(Boolean).join(" ").trim() || "—";
  const initials =
    (user.firstName?.[0] ?? user.email[0] ?? "?").toUpperCase() +
    (user.lastName?.[0]?.toUpperCase() ?? "");

  const planLabel = user.isPremium
    ? user.hasTcf
      ? "Intégral · Civique + TCF"
      : "Civique"
    : "Démo";
  const planSub = user.isPremium
    ? user.premiumEndsAt
      ? `Valide jusqu'au ${formatDate(user.premiumEndsAt)}`
      : "Plan actif"
    : "20 questions et 1 examen blanc gratuits par module";

  return (
    <main className="pr">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span> PROFIL
          </div>
          <h1>
            Votre <em>compte</em>.
          </h1>
        </div>
        <div className="topbar-actions">
          <button
            type="button"
            className="btn-outline"
            onClick={() => setShowLogoutConfirm(true)}
          >
            Déconnexion
          </button>
        </div>
      </header>

      {/* ============ IDENTITY ============ */}
      <section className="identity-card">
        <div className="identity-avatar" aria-hidden>
          {initials}
        </div>
        <div className="identity-info">
          <h2 className="identity-name">{fullName}</h2>
          <div className="identity-email">{user.email}</div>
          <div className="identity-badges">
            <span className={`plan-pill plan-pill-${user.isPremium ? "primary" : "neutral"}`}>
              {planLabel}
            </span>
            {user.targetProcedure && (
              <span className="proc-pill">
                Parcours · {user.targetProcedure}
              </span>
            )}
          </div>
        </div>
      </section>

      {/* ============ PARCOURS ============ */}
      <SettingsGroup title="Démarche">
        <SettingsRow
          name="Parcours visé"
          value={
            user.targetProcedure
              ? PROCEDURE_INFO[user.targetProcedure].title
              : "Pas encore défini"
          }
          accent={user.targetProcedure ? null : "warning"}
          href={`/parcours?from=/profil`}
          chevron
        />
        <SettingsRow
          name="Niveau de français visé"
          value={
            user.targetProcedure
              ? PROCEDURE_INFO[user.targetProcedure].tcfLevel
              : "—"
          }
          valueTone="red"
        />
        <SettingsRow
          name="Date d'examen prévue"
          value={examDate ? formatDate(examDate) : "Non définie"}
          accent={examDate ? null : "muted"}
          actionLabel={examDate ? "Modifier" : "Définir"}
          onAction={() => router.push("/dashboard")}
        />
      </SettingsGroup>

      {/* ============ INFOS PERSONNELLES ============ */}
      <SettingsGroup title="Informations personnelles">
        <SettingsRow
          name="Nom complet"
          value={fullName}
          actionLabel="Modifier"
          onAction={() => setShowEditNameSoon(true)}
        />
        <SettingsRow
          name="Adresse e-mail"
          value={user.email}
          actionLabel="Modifier"
          onAction={() => setShowEditNameSoon(true)}
        />
        <SettingsRow
          name="Mot de passe"
          value="•••••••••"
          actionLabel="Modifier"
          href="/mot-de-passe-oublie"
        />
        <SettingsRow
          name="Identifiant utilisateur"
          value={user.id}
          mono
        />
      </SettingsGroup>

      {/* ============ ABONNEMENT ============ */}
      <SettingsGroup title="Abonnement">
        <SettingsRow
          name="Plan actuel"
          value={planLabel}
          valueTone={user.isPremium ? "blue" : "muted"}
          valueStrong
        />
        <SettingsRow name="Détails" value={planSub} />
        {user.isPremium && user.premiumEndsAt && (
          <SettingsRow
            name="Renouvellement"
            value="Sans renouvellement automatique"
            valueTone="muted"
          />
        )}
        <SettingsRow
          name={user.isPremium ? "Gérer mon abonnement" : "Passer Premium"}
          value=""
          accent={user.isPremium ? null : "primary"}
          href="/paiement"
          chevron
        />
      </SettingsGroup>

      {/* ============ ZONE DANGER ============ */}
      <SettingsGroup title="Zone danger" danger>
        <SettingsRow
          name="Supprimer mon compte"
          value="Toutes vos données et votre progression"
          valueTone="muted"
          accent="danger"
          onAction={() => setShowDeleteSoon(true)}
          actionLabel="Supprimer"
        />
      </SettingsGroup>

      {/* FOOTNOTE */}
      <div className="pr-footnote">
        Besoin d&apos;aide ? <Link href="/#faq">Consultez la FAQ</Link> ou
        écrivez-nous à <a href="mailto:hello@sejourfr.fr">hello@sejourfr.fr</a>.
      </div>

      {/* MODALS */}
      {showLogoutConfirm && (
        <ConfirmModal
          title="Se déconnecter ?"
          body="Vos données restent en sécurité côté serveur. Vous pourrez vous reconnecter à tout moment avec votre email."
          confirmLabel="Me déconnecter"
          confirmTone="danger"
          onConfirm={handleLogout}
          onCancel={() => setShowLogoutConfirm(false)}
        />
      )}
      {showDeleteSoon && (
        <ConfirmModal
          title="Suppression du compte"
          body={
            "Cette fonctionnalité arrive bientôt. En attendant, envoyez-nous un email à hello@sejourfr.fr depuis l'adresse de votre compte et nous procéderons à la suppression manuellement, conformément au RGPD."
          }
          confirmLabel="J'ai compris"
          confirmTone="neutral"
          onConfirm={() => setShowDeleteSoon(false)}
          onCancel={() => setShowDeleteSoon(false)}
          singleAction
        />
      )}
      {showEditNameSoon && (
        <ConfirmModal
          title="Édition à venir"
          body="L'édition du nom et de l'email arrive bientôt. En attendant, écrivez à hello@sejourfr.fr en précisant votre demande."
          confirmLabel="OK"
          confirmTone="neutral"
          onConfirm={() => setShowEditNameSoon(false)}
          onCancel={() => setShowEditNameSoon(false)}
          singleAction
        />
      )}

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// SETTINGS GROUP
// ============================================================================
function SettingsGroup({
  title,
  children,
  danger,
}: {
  title: string;
  children: React.ReactNode;
  danger?: boolean;
}) {
  return (
    <section className={`settings-group ${danger ? "is-danger" : ""}`}>
      <div className={`settings-group-title ${danger ? "is-danger" : ""}`}>
        {title}
      </div>
      <div className={`settings-list ${danger ? "is-danger" : ""}`}>
        {children}
      </div>
    </section>
  );
}

// ============================================================================
// SETTINGS ROW
// ============================================================================
function SettingsRow({
  name,
  value,
  valueTone,
  valueStrong,
  mono,
  accent,
  href,
  onAction,
  actionLabel,
  chevron,
}: {
  name: string;
  value: string;
  valueTone?: "blue" | "red" | "muted";
  valueStrong?: boolean;
  mono?: boolean;
  accent?: "primary" | "danger" | "warning" | "muted" | null;
  href?: string;
  onAction?: () => void;
  actionLabel?: string;
  chevron?: boolean;
}) {
  const valueEl = (
    <span
      className={`row-value ${valueTone ? `row-value-${valueTone}` : ""} ${mono ? "is-mono" : ""}`}
    >
      {valueStrong ? <strong>{value}</strong> : value}
    </span>
  );

  const actionEl = actionLabel ? (
    <span className={`row-action row-action-${accent ?? "default"}`}>
      {actionLabel}
    </span>
  ) : chevron ? (
    <span className="row-chevron">›</span>
  ) : null;

  const isClickable = !!href || !!onAction;

  const inner = (
    <>
      <span className="row-name">{name}</span>
      <span className="row-value-wrap">
        {valueEl}
        {actionEl}
      </span>
    </>
  );

  if (href) {
    return (
      <Link href={href} className={`settings-row ${isClickable ? "is-clickable" : ""}`}>
        {inner}
      </Link>
    );
  }
  if (onAction) {
    return (
      <button
        type="button"
        className={`settings-row ${isClickable ? "is-clickable" : ""}`}
        onClick={onAction}
      >
        {inner}
      </button>
    );
  }
  return <div className="settings-row">{inner}</div>;
}

// ============================================================================
// CONFIRM MODAL
// ============================================================================
function ConfirmModal({
  title,
  body,
  confirmLabel,
  confirmTone = "primary",
  onConfirm,
  onCancel,
  singleAction = false,
}: {
  title: string;
  body: string;
  confirmLabel: string;
  confirmTone?: "primary" | "danger" | "neutral";
  onConfirm: () => void;
  onCancel: () => void;
  singleAction?: boolean;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onCancel]);

  return (
    <div className="cm" role="dialog" aria-modal="true" onClick={onCancel}>
      <div className="cm-backdrop" />
      <div className="cm-sheet" onClick={(e) => e.stopPropagation()}>
        <h2 className="cm-title">{title}</h2>
        <p className="cm-body">{body}</p>
        <div className="cm-actions">
          {!singleAction && (
            <button type="button" className="cm-btn cm-btn-ghost" onClick={onCancel}>
              Annuler
            </button>
          )}
          <button
            type="button"
            className={`cm-btn cm-btn-${confirmTone}`}
            onClick={onConfirm}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
      <style>{modalStyles}</style>
    </div>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
const PROCEDURE_INFO: Record<
  TargetProcedure,
  { title: string; desc: string; tcfLevel: string }
> = {
  CSP: {
    title: "Carte de séjour pluriannuelle",
    desc: "Premier renouvellement après le visa long séjour.",
    tcfLevel: "A2",
  },
  CR: {
    title: "Carte de résident (10 ans)",
    desc: "Stabilité longue durée, démarches allégées.",
    tcfLevel: "B1",
  },
  NAT: {
    title: "Naturalisation française",
    desc: "Nationalité française. Niveau d'exigence le plus élevé.",
    tcfLevel: "B2",
  },
};

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

function ProfilSkeleton() {
  return (
    <div className="pr-loading">
      <style>{`.pr-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

const gateStyles = `
  .pr-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .pr-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pr { padding: 24px 36px 64px; max-width: 900px; }
  @media (max-width: 760px) { .pr { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    gap: 16px; flex-wrap: wrap;
    margin-bottom: 26px;
  }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.2vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0;
    line-height: 1.15;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-actions { display: flex; gap: 10px; align-items: center; }
  .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
    cursor: pointer;
    font-family: inherit;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }

  /* ========== IDENTITY ========== */
  .identity-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 22px;
    padding: 28px;
    display: flex;
    align-items: center;
    gap: 22px;
    margin-bottom: 26px;
    position: relative;
    overflow: hidden;
  }
  .identity-card::before {
    content: '';
    position: absolute;
    width: 220px; height: 220px;
    border-radius: 50%;
    background: radial-gradient(circle, var(--color-blue-light) 0%, transparent 70%);
    top: -90px; right: -60px;
    opacity: 0.6;
    pointer-events: none;
  }
  .identity-avatar {
    width: 80px; height: 80px;
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-red) 100%);
    color: #fff;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 28px;
    letter-spacing: -0.02em;
    flex-shrink: 0;
    box-shadow: 0 12px 28px -10px rgba(30, 58, 140, 0.4);
    position: relative;
    z-index: 1;
  }
  .identity-info {
    min-width: 0;
    position: relative;
    z-index: 1;
  }
  .identity-name {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 22px;
    margin: 0 0 4px;
    letter-spacing: -0.015em;
    color: var(--color-ink);
    line-height: 1.2;
  }
  .identity-email {
    font-family: var(--font-mono);
    font-size: 13px;
    color: var(--color-muted);
    word-break: break-all;
    margin-bottom: 10px;
  }
  .identity-badges {
    display: flex; flex-wrap: wrap; gap: 6px;
  }
  .plan-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    padding: 4px 10px;
    border-radius: 100px;
    font-weight: 700;
    text-transform: uppercase;
  }
  .plan-pill-primary { background: var(--color-blue); color: #fff; }
  .plan-pill-neutral { background: var(--color-paper-2); color: var(--color-muted); }
  .proc-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    padding: 4px 10px;
    border-radius: 100px;
    font-weight: 700;
    background: var(--color-red-light);
    color: var(--color-red);
    text-transform: uppercase;
  }
  @media (max-width: 560px) {
    .identity-card {
      flex-direction: column;
      align-items: flex-start;
      gap: 16px;
      padding: 22px;
    }
    .identity-avatar { width: 64px; height: 64px; font-size: 22px; }
  }

  /* ========== SETTINGS GROUP ========== */
  .settings-group {
    margin-bottom: 22px;
  }
  .settings-group-title {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-muted);
    font-weight: 600;
    margin-bottom: 10px;
    padding: 0 4px;
  }
  .settings-group-title.is-danger { color: var(--color-red); }
  .settings-list {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    overflow: hidden;
  }
  .settings-list.is-danger {
    border-color: rgba(225, 55, 47, 0.3);
  }

  .settings-row {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    padding: 14px 18px;
    border-bottom: 1px solid var(--color-line-2);
    background: transparent;
    text-decoration: none;
    color: inherit;
    width: 100%;
    border-left: none; border-right: none; border-top: none;
    font-family: inherit;
    text-align: left;
    transition: background 0.12s;
  }
  .settings-list > .settings-row:last-child {
    border-bottom: none;
  }
  .settings-row.is-clickable {
    cursor: pointer;
  }
  .settings-row.is-clickable:hover {
    background: var(--color-blue-soft);
  }
  .settings-list.is-danger .settings-row.is-clickable:hover {
    background: var(--color-red-light);
  }

  .row-name {
    font-size: 13.5px;
    font-weight: 600;
    color: var(--color-ink);
    flex-shrink: 0;
  }
  .row-value-wrap {
    display: flex; align-items: center; gap: 10px;
    min-width: 0;
    flex-wrap: nowrap;
  }
  .row-value {
    font-size: 13px;
    color: var(--color-muted);
    text-align: right;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 280px;
  }
  .row-value.is-mono {
    font-family: var(--font-mono);
    font-size: 11.5px;
    letter-spacing: 0.04em;
  }
  .row-value-blue { color: var(--color-blue); }
  .row-value-blue strong { color: var(--color-blue); }
  .row-value-red { color: var(--color-red); font-weight: 700; }
  .row-value-muted { color: var(--color-muted-2); }
  .row-value strong { color: var(--color-ink); font-weight: 700; }

  .row-action {
    font-size: 12.5px;
    font-weight: 700;
    flex-shrink: 0;
  }
  .row-action-default { color: var(--color-blue); }
  .row-action-primary { color: var(--color-blue); }
  .row-action-danger { color: var(--color-red); }
  .row-action-warning { color: var(--color-amber); }
  .row-action-muted { color: var(--color-muted); }
  .row-chevron {
    color: var(--color-muted-2);
    font-size: 18px;
    flex-shrink: 0;
  }

  @media (max-width: 560px) {
    .settings-row {
      flex-direction: column;
      align-items: flex-start;
      gap: 4px;
    }
    .row-value-wrap {
      justify-content: space-between;
      width: 100%;
    }
    .row-value { text-align: left; max-width: none; }
  }

  /* ========== FOOTNOTE ========== */
  .pr-footnote {
    text-align: center;
    margin-top: 32px;
    font-size: 12.5px;
    color: var(--color-muted);
    line-height: 1.55;
  }
  .pr-footnote a { color: var(--color-blue); text-decoration: none; }
  .pr-footnote a:hover { text-decoration: underline; }
`;

const modalStyles = `
  .cm {
    position: fixed; inset: 0;
    z-index: 100;
    display: flex; align-items: flex-end; justify-content: center;
  }
  .cm-backdrop {
    position: absolute; inset: 0;
    background: rgba(15, 24, 57, 0.55);
    backdrop-filter: blur(4px);
    animation: cm-fade 0.18s ease-out;
  }
  @keyframes cm-fade { from { opacity: 0; } to { opacity: 1; } }
  @keyframes cm-slide {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  .cm-sheet {
    position: relative;
    background: #fff;
    border-radius: 22px 22px 0 0;
    padding: 28px 28px 22px;
    width: 100%;
    max-width: 460px;
    animation: cm-slide 0.22s ease-out;
    box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
  }
  @media (min-width: 640px) {
    .cm { align-items: center; }
    .cm-sheet { border-radius: 18px; }
  }
  .cm-title {
    font-family: var(--font-display); font-weight: 600;
    font-size: 22px; letter-spacing: -0.02em;
    color: var(--color-ink);
    margin: 0 0 8px;
  }
  .cm-body {
    font-size: 14px; line-height: 1.55;
    color: var(--color-muted);
    margin: 0 0 22px;
  }
  .cm-actions {
    display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap;
  }
  .cm-btn {
    padding: 10px 16px;
    border-radius: 10px;
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    border: 1px solid transparent;
    transition: all 0.15s;
  }
  .cm-btn-ghost {
    background: #fff;
    border-color: var(--color-line);
    color: var(--color-ink);
  }
  .cm-btn-ghost:hover { border-color: var(--color-ink); }
  .cm-btn-primary {
    background: var(--color-blue);
    color: #fff;
  }
  .cm-btn-primary:hover { background: var(--color-blue-dark); }
  .cm-btn-danger {
    background: var(--color-red);
    color: #fff;
  }
  .cm-btn-danger:hover { background: var(--color-red-dark); }
  .cm-btn-neutral {
    background: var(--color-ink);
    color: #fff;
  }
  .cm-btn-neutral:hover { background: var(--color-ink-2); }
`;
