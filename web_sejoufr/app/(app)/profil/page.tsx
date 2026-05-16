"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";

/**
 * Page profil : vue d'ensemble du compte. L'édition est éclatée :
 *  - le parcours (CSP/CR/NAT) se modifie sur /parcours
 *  - le mot de passe via /mot-de-passe-oublie (en attendant un endpoint dédié
 *    /api/me/change-password côté Spring)
 *  - le firstName/lastName n'est pas éditable pour l'instant (endpoint /api/me/profile
 *    pas encore exposé côté backend)
 *  - la suppression de compte est désactivée en attendant DELETE /api/me/account
 */
export default function ProfilPage() {
  const router = useRouter();
  const { user, status, logout } = useAuth();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteSoon, setShowDeleteSoon] = useState(false);

  // Lock body scroll quand une modal est ouverte
  useEffect(() => {
    if (!showLogoutConfirm && !showDeleteSoon) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [showLogoutConfirm, showDeleteSoon]);

  function handleLogout() {
    logout();
    router.push("/");
  }

  if (status === "loading") return <div className="pr-loading" />;
  if (!user) {
    return (
      <main className="pr-gate">
        <p>Connectez-vous pour voir votre compte.</p>
        <Link href="/connexion?next=/profil" className="btn btn-blue">
          Se connecter
        </Link>
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
      ? "Intégral (Civique + TCF)"
      : "Civique 3 mois"
    : "Démo (sans abonnement)";
  const planTone: "primary" | "neutral" = user.isPremium ? "primary" : "neutral";

  return (
    <main className="pr">
      <div className="pr-wrap">
        <header className="pr-head">
          <span className="eyebrow">Mon compte</span>
          <h1>
            Bonjour, <em>{user.firstName ?? user.email.split("@")[0]}</em>.
          </h1>
          <p>
            Gérez votre parcours, votre abonnement et la sécurité de votre
            compte SejourFR.
          </p>
        </header>

        {/* IDENTITÉ */}
        <section className="pr-card pr-identity">
          <div className="pr-avatar" aria-hidden>{initials}</div>
          <div className="pr-identity-info">
            <div className="pr-name">{fullName}</div>
            <div className="pr-email">{user.email}</div>
          </div>
          <span className={`pr-plan-badge ${planTone}`}>{planLabel}</span>
        </section>

        {/* PARCOURS */}
        <section className="pr-section">
          <div className="pr-section-head">
            <span className="pr-section-title">Mon parcours</span>
            <Link href="/parcours?from=/profil" className="pr-section-edit">
              {user.targetProcedure ? "Modifier" : "Choisir"} →
            </Link>
          </div>
          {user.targetProcedure ? (
            <ProcedureCard procedure={user.targetProcedure} />
          ) : (
            <div className="pr-empty">
              <div className="pr-empty-text">
                Vous n&apos;avez pas encore choisi votre parcours administratif.
                Sans parcours, l&apos;entraînement reste générique.
              </div>
              <Link href="/parcours?from=/profil" className="btn btn-blue">
                Choisir mon parcours →
              </Link>
            </div>
          )}
        </section>

        {/* ABONNEMENT */}
        <section className="pr-section">
          <div className="pr-section-head">
            <span className="pr-section-title">Mon abonnement</span>
            <Link href="/paiement" className="pr-section-edit">
              Gérer →
            </Link>
          </div>
          <div className="pr-card pr-sub">
            <div className="pr-sub-icon" data-tone={planTone}>
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                {user.isPremium ? (
                  <>
                    <path d="m12 2 3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
                  </>
                ) : (
                  <>
                    <rect x="2" y="6" width="20" height="12" rx="2" />
                    <path d="M2 10h20" />
                  </>
                )}
              </svg>
            </div>
            <div className="pr-sub-info">
              <div className="pr-sub-plan">{planLabel}</div>
              <div className="pr-sub-detail">
                {user.isPremium ? (
                  user.premiumEndsAt ? (
                    <>Valide jusqu&apos;au {formatDate(user.premiumEndsAt)}</>
                  ) : (
                    <>Plan actif sans date de fin</>
                  )
                ) : (
                  <>20 questions et 1 examen blanc gratuits par module</>
                )}
              </div>
            </div>
            {!user.isPremium && (
              <Link href="/paiement" className="btn btn-red pr-sub-cta">
                S&apos;abonner →
              </Link>
            )}
          </div>
        </section>

        {/* SÉCURITÉ */}
        <section className="pr-section">
          <span className="pr-section-title">Sécurité</span>
          <div className="pr-actions">
            <Link href="/mot-de-passe-oublie" className="pr-action">
              <div className="pr-action-icon" aria-hidden>
                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
              </div>
              <div className="pr-action-text">
                <div className="pr-action-title">Changer mon mot de passe</div>
                <div className="pr-action-sub">Vous recevrez un lien par email</div>
              </div>
              <span className="pr-action-arrow">›</span>
            </Link>

            <button
              type="button"
              className="pr-action"
              onClick={() => setShowDeleteSoon(true)}
            >
              <div className="pr-action-icon danger" aria-hidden>
                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                </svg>
              </div>
              <div className="pr-action-text">
                <div className="pr-action-title">Supprimer mon compte</div>
                <div className="pr-action-sub">
                  Toutes vos données et votre progression seront effacées
                </div>
              </div>
              <span className="pr-action-arrow">›</span>
            </button>
          </div>
        </section>

        {/* LOGOUT */}
        <button
          type="button"
          className="pr-logout"
          onClick={() => setShowLogoutConfirm(true)}
        >
          Se déconnecter
        </button>

        <div className="pr-footnote">
          Besoin d&apos;aide ? <Link href="/#faq">Consultez la FAQ</Link> ou
          écrivez-nous à <a href="mailto:hello@sejourfr.fr">hello@sejourfr.fr</a>.
        </div>
      </div>

      {/* MODAL LOGOUT */}
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

      {/* MODAL DELETE — stub */}
      {showDeleteSoon && (
        <ConfirmModal
          title="Suppression du compte"
          body={
            "Cette fonctionnalité arrive bientôt. En attendant, envoyez-nous un email " +
            "à hello@sejourfr.fr depuis l'adresse de votre compte et nous procéderons " +
            "à la suppression manuellement, conformément au RGPD."
          }
          confirmLabel="J'ai compris"
          confirmTone="neutral"
          onConfirm={() => setShowDeleteSoon(false)}
          onCancel={() => setShowDeleteSoon(false)}
          singleAction
        />
      )}

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// PROCEDURE CARD
// ============================================================================
function ProcedureCard({ procedure }: { procedure: TargetProcedure }) {
  const info = PROCEDURE_INFO[procedure];
  return (
    <div className="pr-card pr-proc">
      <span className="pr-proc-badge">{procedure}</span>
      <div className="pr-proc-info">
        <div className="pr-proc-title">{info.title}</div>
        <div className="pr-proc-desc">{info.desc}</div>
      </div>
      <div className="pr-proc-tcf">
        <span className="pr-proc-tcf-label">TCF requis</span>
        <span className="pr-proc-tcf-value">{info.tcfLevel}</span>
      </div>
    </div>
  );
}

const PROCEDURE_INFO: Record<TargetProcedure, { title: string; desc: string; tcfLevel: string }> = {
  CSP: {
    title: "Titre de séjour pluriannuel",
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
  return d.toLocaleDateString("fr-FR", { day: "2-digit", month: "long", year: "numeric" });
}

// ============================================================================
// MODAL
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
            <button type="button" className="btn btn-ghost" onClick={onCancel}>
              Annuler
            </button>
          )}
          <button
            type="button"
            className={`btn ${confirmTone === "danger" ? "btn-red" : "btn-blue"}`}
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
// STYLES
// ============================================================================
const styles = `
  .pr { background: var(--color-paper); min-height: calc(100vh - 110px); padding: 32px 16px 64px; }
  .pr-loading { min-height: 60vh; }
  .pr-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .pr-wrap { max-width: 720px; margin: 0 auto; }

  .pr-head { margin: 0 0 24px; }
  .pr-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 38px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 10px;
  }
  .pr-head h1 em { font-style: italic; color: var(--color-red); }
  .pr-head p {
    color: var(--color-muted); font-size: 15px;
    margin: 0; max-width: 540px; line-height: 1.55;
  }

  .pr-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 18px 20px;
  }

  /* IDENTITÉ */
  .pr-identity {
    display: grid;
    grid-template-columns: 64px 1fr auto;
    align-items: center; gap: 16px;
    margin-bottom: 24px;
  }
  .pr-avatar {
    width: 64px; height: 64px;
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    color: #fff;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-display); font-weight: 500;
    font-size: 24px; letter-spacing: -0.02em;
    box-shadow: 0 8px 20px -8px rgba(30, 58, 140, 0.32);
  }
  .pr-identity-info { min-width: 0; }
  .pr-name {
    font-family: var(--font-sans); font-weight: 700; font-size: 17px;
    color: var(--color-ink); line-height: 1.2;
  }
  .pr-email {
    font-family: var(--font-mono); font-size: 12.5px;
    color: var(--color-muted); margin-top: 4px;
    word-break: break-all;
  }
  .pr-plan-badge {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    padding: 4px 10px; border-radius: 100px;
    font-weight: 700;
    flex-shrink: 0;
  }
  .pr-plan-badge.primary { background: var(--color-blue); color: #fff; }
  .pr-plan-badge.neutral { background: var(--color-paper-2); color: var(--color-muted); }
  @media (max-width: 560px) {
    .pr-identity {
      grid-template-columns: 48px 1fr;
      gap: 12px;
    }
    .pr-avatar { width: 48px; height: 48px; font-size: 18px; }
    .pr-plan-badge { grid-column: 1 / -1; justify-self: start; }
  }

  /* SECTION */
  .pr-section { margin-bottom: 22px; }
  .pr-section-head {
    display: flex; align-items: baseline; justify-content: space-between;
    margin-bottom: 10px;
  }
  .pr-section-title {
    font-family: var(--font-mono); font-size: 10.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 700;
  }
  .pr-section-edit {
    font-family: var(--font-sans); font-size: 12.5px; font-weight: 700;
    color: var(--color-blue); text-decoration: none;
  }

  /* PARCOURS */
  .pr-proc {
    display: grid;
    grid-template-columns: 48px 1fr auto;
    align-items: center; gap: 14px;
  }
  .pr-proc-badge {
    font-family: var(--font-mono);
    background: var(--color-blue);
    color: #fff;
    padding: 6px 10px;
    border-radius: 8px;
    font-size: 13px; font-weight: 700; letter-spacing: 0.08em;
    text-align: center;
  }
  .pr-proc-info { min-width: 0; }
  .pr-proc-title {
    font-weight: 700; font-size: 14.5px;
    color: var(--color-ink); line-height: 1.25;
  }
  .pr-proc-desc {
    font-size: 12.5px; color: var(--color-muted);
    margin-top: 3px; line-height: 1.4;
  }
  .pr-proc-tcf {
    display: flex; flex-direction: column; align-items: center;
    padding: 8px 12px;
    background: var(--color-paper);
    border-radius: 8px;
  }
  .pr-proc-tcf-label {
    font-family: var(--font-mono); font-size: 8.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 700;
  }
  .pr-proc-tcf-value {
    font-family: var(--font-mono); font-size: 14px;
    font-weight: 700; color: var(--color-red);
  }
  @media (max-width: 480px) { .pr-proc-tcf { display: none; } }

  /* EMPTY parcours */
  .pr-empty {
    background: var(--color-blue-soft);
    border: 1px dashed var(--color-blue-light);
    border-radius: 14px;
    padding: 18px 20px;
    display: flex; flex-direction: column; gap: 14px;
    align-items: flex-start;
  }
  .pr-empty-text {
    font-size: 13.5px; color: var(--color-ink-2);
    line-height: 1.5;
  }

  /* ABONNEMENT */
  .pr-sub {
    display: grid;
    grid-template-columns: 44px 1fr auto;
    align-items: center; gap: 14px;
  }
  .pr-sub-icon {
    width: 44px; height: 44px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
  }
  .pr-sub-icon[data-tone="primary"] {
    background: var(--color-blue-light); color: var(--color-blue);
  }
  .pr-sub-icon[data-tone="neutral"] {
    background: var(--color-paper-2); color: var(--color-muted);
  }
  .pr-sub-info { min-width: 0; }
  .pr-sub-plan {
    font-weight: 700; font-size: 14.5px; color: var(--color-ink); line-height: 1.2;
  }
  .pr-sub-detail {
    font-size: 12.5px; color: var(--color-muted); margin-top: 3px;
  }
  .pr-sub-cta { flex-shrink: 0; }
  @media (max-width: 560px) {
    .pr-sub-cta { grid-column: 1 / -1; width: 100%; }
  }

  /* ACTIONS */
  .pr-actions { display: flex; flex-direction: column; gap: 8px; }
  .pr-action {
    display: grid;
    grid-template-columns: 36px 1fr 20px;
    align-items: center; gap: 14px;
    width: 100%;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 16px;
    text-align: left;
    cursor: pointer;
    text-decoration: none;
    color: inherit;
    transition: all 0.15s;
    font-family: var(--font-sans);
  }
  .pr-action:hover {
    border-color: var(--color-blue);
    background: var(--color-blue-soft);
  }
  .pr-action-icon {
    width: 36px; height: 36px;
    background: var(--color-blue-light); color: var(--color-blue);
    border-radius: 9px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .pr-action-icon.danger {
    background: var(--color-red-light); color: var(--color-red);
  }
  .pr-action-text { min-width: 0; }
  .pr-action-title {
    font-weight: 700; font-size: 14px; color: var(--color-ink); line-height: 1.2;
  }
  .pr-action-sub {
    font-size: 12.5px; color: var(--color-muted); margin-top: 3px;
  }
  .pr-action-arrow {
    color: var(--color-muted-2); font-size: 18px; flex-shrink: 0;
  }

  /* LOGOUT */
  .pr-logout {
    width: 100%;
    padding: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    font-family: var(--font-sans);
    font-size: 14px; font-weight: 600;
    color: var(--color-red);
    cursor: pointer;
    transition: all 0.15s;
    margin-top: 14px;
  }
  .pr-logout:hover {
    background: var(--color-red-light);
    border-color: rgba(225, 55, 47, 0.3);
  }

  /* FOOTNOTE */
  .pr-footnote {
    text-align: center;
    margin-top: 24px;
    font-size: 12.5px; color: var(--color-muted);
    line-height: 1.55;
  }
  .pr-footnote a { color: var(--color-blue); }
`;

const modalStyles = `
  .cm {
    position: fixed; inset: 0;
    z-index: 100;
    display: flex; align-items: flex-end; justify-content: center;
  }
  .cm-backdrop {
    position: absolute; inset: 0;
    background: rgba(15, 24, 57, 0.45);
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
    padding: 28px 24px 22px;
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
    font-family: var(--font-display); font-weight: 500;
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
`;
