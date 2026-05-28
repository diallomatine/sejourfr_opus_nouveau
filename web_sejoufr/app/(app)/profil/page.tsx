"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";

const EXAM_DATE_KEY = "sejourfr.examDate";

/**
 * Page profil au format "profil-page" du template : hero sombre + carte compte,
 * 2 colonnes (infos perso + abonnement), paramètres du compte (cartes), 2 colonnes
 * (activité + conseil). Branchée sur la vraie data, sans inventer d'activité chiffrée.
 *  - Parcours (CSP/CR/NAT) → /parcours · Mot de passe → /mot-de-passe-oublie
 *  - Édition nom/email + suppression compte = modales "bientôt" (endpoints à venir)
 *  - Date d'examen en localStorage (synchro dashboard)
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
    // eslint-disable-next-line react-hooks/set-state-in-effect
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
  const proc = user.targetProcedure ? PROCEDURE_INFO[user.targetProcedure] : null;
  const tcfLevel = proc?.tcfLevel ?? "—";

  const planLabel = user.isPremium
    ? user.hasTcf
      ? "Intégral · Civique + TCF"
      : "Premium Civique"
    : "Découverte";
  const planSub = user.isPremium
    ? user.premiumEndsAt
      ? `Valide jusqu'au ${formatDate(user.premiumEndsAt)}`
      : "Abonnement actif"
    : "20 questions et 1 examen blanc gratuits par module";

  return (
    <main className="pr">
      {/* ---- Hero ---- */}
      <section className="pr-hero">
        <div className="pr-hero-main">
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span> PROFIL
          </div>
          <h1>Mon <em>profil</em></h1>
          <p>
            Gère ton compte, ton objectif d&apos;examen, ton abonnement et tes
            paramètres de sécurité.
          </p>
          <div className="pr-hero-actions">
            <button
              type="button"
              className="pr-hero-btn"
              onClick={() => setShowEditNameSoon(true)}
            >
              Modifier mon profil
            </button>
            <Link
              href={user.isPremium ? "/profil/abonnement" : "/paiement"}
              className="pr-hero-btn pr-hero-btn-ghost"
            >
              {user.isPremium ? "Gérer mon abonnement" : "Passer Premium"}
            </Link>
          </div>
        </div>

        <div className="pr-score">
          <div className="pr-score-head">
            <span className="pr-avatar">{initials}</span>
            <div>
              <div className="pr-score-name">{user.firstName ?? fullName}</div>
              <div className="pr-score-plan">{planLabel}</div>
            </div>
          </div>
          <div className="pr-score-meta">
            Objectif&nbsp;: {proc ? proc.title : "à définir"}
          </div>
          <div className="pr-score-meta">Niveau de français visé&nbsp;: {tcfLevel}</div>
        </div>
      </section>

      {/* ---- Infos perso + abonnement ---- */}
      <div className="pr-cols">
        <section className="pr-panel">
          <div className="pr-panel-head">
            <h2>Informations personnelles</h2>
            <button type="button" className="pr-link-btn" onClick={() => setShowEditNameSoon(true)}>
              Modifier
            </button>
          </div>
          <div className="pr-info">
            <div className="pr-stat">
              <span>Nom complet</span>
              <strong>{fullName}</strong>
            </div>
            <div className="pr-stat">
              <span>Adresse e-mail</span>
              <strong className="pr-mono">{user.email}</strong>
            </div>
            <div className="pr-stat">
              <span>Objectif</span>
              <strong>{proc ? proc.title : "Pas encore défini"}</strong>
            </div>
            <div className="pr-stat">
              <span>Niveau visé</span>
              <strong>{tcfLevel}</strong>
            </div>
          </div>
        </section>

        <aside className="pr-panel">
          <h2 className="pr-panel-title">Abonnement</h2>
          <div className="pr-tips">
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>⭐</span>
              <p><strong>Offre actuelle :</strong> {planLabel}.</p>
            </div>
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>🤖</span>
              <p>{planSub}.</p>
            </div>
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>🔐</span>
              <p><strong>Gestion :</strong> paiement et accès gérés en ligne en toute sécurité.</p>
            </div>
          </div>
          <Link
            href={user.isPremium ? "/profil/abonnement" : "/paiement"}
            className="pr-panel-cta"
          >
            {user.isPremium ? "Gérer mon abonnement" : "Passer Premium"}
          </Link>
        </aside>
      </div>

      {/* ---- Paramètres du compte ---- */}
      <div className="pr-section-title">
        <h2>Paramètres du compte</h2>
      </div>
      <section className="pr-cards">
        <Link href="/parcours?from=/profil" className="pr-card">
          <div className="pr-card-head">
            <span className="pr-card-icon tone-amber" aria-hidden>🎯</span>
            <span className="pr-card-badge">{tcfLevel}</span>
          </div>
          <h3>Objectif d&apos;examen</h3>
          <p>CSP, CR ou naturalisation — et le niveau de français correspondant.</p>
          <span className="pr-card-cta">Modifier</span>
        </Link>

        <Link href="/dashboard" className="pr-card">
          <div className="pr-card-head">
            <span className="pr-card-icon tone-blue" aria-hidden>📅</span>
            <span className="pr-card-badge">{examDate ? "Définie" : "À définir"}</span>
          </div>
          <h3>Date d&apos;examen</h3>
          <p>{examDate ? `Prévue le ${formatDate(examDate)}.` : "Fixe ta date pour suivre ton compte à rebours."}</p>
          <span className="pr-card-cta">{examDate ? "Modifier" : "Définir"}</span>
        </Link>

        <Link href="/mot-de-passe-oublie" className="pr-card">
          <div className="pr-card-head">
            <span className="pr-card-icon tone-green" aria-hidden>🔒</span>
            <span className="pr-card-badge">Sécurité</span>
          </div>
          <h3>Connexion</h3>
          <p>Réinitialise ton mot de passe. Connexion Google/Apple gérée à part.</p>
          <span className="pr-card-cta">Gérer</span>
        </Link>

        <button type="button" className="pr-card pr-card-danger" onClick={() => setShowDeleteSoon(true)}>
          <div className="pr-card-head">
            <span className="pr-card-icon tone-red" aria-hidden>🗑️</span>
            <span className="pr-card-badge">RGPD</span>
          </div>
          <h3>Données personnelles</h3>
          <p>Supprimer mon historique et fermer mon compte, conformément au RGPD.</p>
          <span className="pr-card-cta">Ouvrir</span>
        </button>
      </section>

      {/* ---- Activité + conseil ---- */}
      <div className="pr-cols">
        <section className="pr-panel">
          <div className="pr-panel-head">
            <h2>Mon activité</h2>
            <Link href="/historique" className="pr-link-btn">Historique complet →</Link>
          </div>
          <Link href="/historique" className="pr-mock-row">
            <span className="pr-card-icon tone-blue" aria-hidden>📝</span>
            <div className="pr-mock-body">
              <h3>Mes examens blancs</h3>
              <p>Scores et progression de tous tes examens passés.</p>
            </div>
            <span className="pr-mock-btn">Voir</span>
          </Link>
          <Link href="/statistiques" className="pr-mock-row">
            <span className="pr-card-icon tone-green" aria-hidden>📈</span>
            <div className="pr-mock-body">
              <h3>Ma progression</h3>
              <p>Maîtrise par thème et points à renforcer.</p>
            </div>
            <span className="pr-mock-btn">Détails</span>
          </Link>
          <Link href="/revision" className="pr-mock-row">
            <span className="pr-card-icon tone-amber" aria-hidden>🔁</span>
            <div className="pr-mock-body">
              <h3>Mes erreurs</h3>
              <p>Revois les questions ratées et tes favoris.</p>
            </div>
            <span className="pr-mock-btn">Revoir</span>
          </Link>
        </section>

        <aside className="pr-panel">
          <h2 className="pr-panel-title">Conseil personnalisé</h2>
          <div className="pr-tips">
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>🎯</span>
              <p>Ton objectif&nbsp;: {proc ? proc.title : "à définir"}. Vise le niveau {tcfLevel}.</p>
            </div>
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>📅</span>
              <p>Garde un rythme simple&nbsp;: 15 à 20 minutes par jour suffisent pour progresser.</p>
            </div>
            <div className="pr-tip">
              <span className="pr-tip-emoji" aria-hidden>🚀</span>
              <p>Alterne civique et TCF pour ne pas perdre le fil de ta préparation.</p>
            </div>
          </div>
        </aside>
      </div>

      {/* ---- Déconnexion ---- */}
      <div className="pr-footnote">
        <button type="button" className="pr-logout" onClick={() => setShowLogoutConfirm(true)}>
          Se déconnecter
        </button>
        <span>
          Besoin d&apos;aide ? <Link href="/faq">Consultez la FAQ</Link> ou écrivez à{" "}
          <a href="mailto:hello@sejourfr.fr">hello@sejourfr.fr</a>.
        </span>
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
          body="Cette fonctionnalité arrive bientôt. En attendant, envoyez-nous un email à hello@sejourfr.fr depuis l'adresse de votre compte et nous procéderons à la suppression manuellement, conformément au RGPD."
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
  .pr { padding: 24px 36px 64px; max-width: 1180px; margin: 0 auto; display: flex; flex-direction: column; gap: 26px; }
  @media (max-width: 760px) { .pr { padding: 20px 16px 56px; gap: 22px; } }

  /* ---- Hero ---- */
  .pr-hero {
    display: grid; grid-template-columns: 1fr; gap: 22px;
    background: linear-gradient(135deg, var(--color-blue) 0%, #3355B5 100%);
    color: #fff; border-radius: 20px; padding: 24px;
  }
  .pr-hero .breadcrumb {
    font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.12em;
    text-transform: uppercase; color: rgba(255,255,255,0.7); margin-bottom: 6px;
  }
  .pr-hero .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .pr-hero-main h1 {
    font-family: var(--font-display); font-weight: 600; font-size: clamp(24px, 3.4vw, 32px);
    letter-spacing: -0.02em; line-height: 1.12; margin: 0; color: #fff;
  }
  .pr-hero-main h1 em { font-style: italic; font-weight: 500; opacity: 0.92; }
  .pr-hero-main p { color: rgba(255,255,255,0.82); font-size: 14.5px; line-height: 1.6; margin: 10px 0 0; max-width: 520px; }
  .pr-hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 18px; }
  .pr-hero-btn {
    display: inline-flex; align-items: center; justify-content: center;
    padding: 11px 20px; border-radius: 10px;
    font-family: var(--font-sans); font-size: 14px; font-weight: 700;
    background: #fff; color: var(--color-ink); text-decoration: none;
    border: 1px solid transparent; cursor: pointer; transition: transform 0.15s, background 0.15s;
  }
  .pr-hero-btn:hover { transform: translateY(-1px); background: #F1F5F9; }
  .pr-hero-btn-ghost { background: transparent; color: #fff; border-color: rgba(255,255,255,0.4); }
  .pr-hero-btn-ghost:hover { background: rgba(255,255,255,0.12); }

  .pr-score {
    background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.18);
    border-radius: 16px; padding: 20px; display: flex; flex-direction: column; gap: 10px;
    justify-content: center;
  }
  .pr-score-head { display: flex; align-items: center; gap: 14px; }
  .pr-avatar {
    width: 56px; height: 56px; border-radius: 50%; flex-shrink: 0;
    background: #fff; color: var(--color-ink);
    display: inline-flex; align-items: center; justify-content: center;
    font-family: var(--font-display); font-weight: 600; font-size: 22px;
  }
  .pr-score-name { font-family: var(--font-display); font-weight: 600; font-size: 20px; color: #fff; }
  .pr-score-plan { font-size: 13px; color: rgba(255,255,255,0.8); margin-top: 2px; }
  .pr-score-meta { font-size: 13px; color: rgba(255,255,255,0.82); }

  /* ---- Colonnes ---- */
  .pr-cols { display: grid; grid-template-columns: 1fr; gap: 16px; }
  .pr-panel { background: #fff; border: 1px solid var(--color-line); border-radius: 16px; padding: 20px; }
  .pr-panel-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-bottom: 14px; }
  .pr-panel-head h2, .pr-panel-title {
    font-family: var(--font-display); font-weight: 600; font-size: 18px;
    letter-spacing: -0.015em; color: var(--color-ink); margin: 0;
  }
  .pr-panel-title { margin-bottom: 14px; }
  .pr-link-btn {
    background: none; border: none; cursor: pointer; padding: 0;
    font-family: var(--font-sans); font-size: 13px; font-weight: 600;
    color: var(--color-blue); text-decoration: none;
  }
  .pr-link-btn:hover { text-decoration: underline; }

  .pr-info { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  .pr-stat {
    background: var(--color-paper); border: 1px solid var(--color-line-2); border-radius: 12px;
    padding: 12px 14px; display: flex; flex-direction: column; gap: 4px; min-width: 0;
  }
  .pr-stat span { font-size: 11px; color: var(--color-muted); font-family: var(--font-mono); letter-spacing: 0.04em; text-transform: uppercase; }
  .pr-stat strong { font-size: 14.5px; font-weight: 700; color: var(--color-ink); word-break: break-word; }
  .pr-stat .pr-mono { font-family: var(--font-mono); font-size: 13px; font-weight: 600; }

  .pr-tips { display: flex; flex-direction: column; gap: 14px; }
  .pr-tip { display: flex; gap: 12px; align-items: flex-start; }
  .pr-tip-emoji {
    flex-shrink: 0; width: 34px; height: 34px; border-radius: 10px;
    display: inline-flex; align-items: center; justify-content: center; font-size: 16px;
    background: var(--color-blue-soft);
  }
  .pr-tip p { font-size: 13px; color: var(--color-ink-2); line-height: 1.5; margin: 0; }
  .pr-tip strong { color: var(--color-ink); font-weight: 700; }
  .pr-panel-cta {
    display: block; width: 100%; margin-top: 18px; text-align: center;
    padding: 11px; border-radius: 10px; background: var(--color-blue); color: #fff;
    font-family: var(--font-sans); font-weight: 700; font-size: 13.5px; text-decoration: none;
    transition: background 0.15s;
  }
  .pr-panel-cta:hover { background: var(--color-blue-dark); }

  /* ---- Titre de section ---- */
  .pr-section-title h2 {
    font-family: var(--font-display); font-weight: 600; font-size: 19px;
    letter-spacing: -0.015em; color: var(--color-ink); margin: 0;
  }

  /* ---- Cartes paramètres ---- */
  .pr-cards { display: grid; grid-template-columns: 1fr; gap: 14px; }
  .pr-card {
    text-align: left; background: #fff; border: 1px solid var(--color-line);
    border-radius: 16px; padding: 18px; cursor: pointer; text-decoration: none;
    font-family: inherit; display: flex; flex-direction: column;
    transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
  }
  .pr-card:hover { transform: translateY(-3px); border-color: var(--color-blue); box-shadow: 0 16px 38px -22px rgba(30,58,140,0.28); }
  .pr-card-danger:hover { border-color: var(--color-red); box-shadow: 0 16px 38px -22px rgba(225,55,47,0.28); }
  .pr-card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
  .pr-card-icon {
    width: 40px; height: 40px; border-radius: 11px; flex-shrink: 0;
    display: inline-flex; align-items: center; justify-content: center; font-size: 18px;
  }
  .pr-card-badge {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em;
    text-transform: uppercase; color: var(--color-muted); background: var(--color-paper-2);
    padding: 4px 9px; border-radius: 8px;
  }
  .pr-card h3 { font-family: var(--font-sans); font-weight: 700; font-size: 15px; color: var(--color-ink); margin: 0 0 4px; }
  .pr-card p { font-size: 12.5px; color: var(--color-muted); line-height: 1.5; margin: 0 0 12px; flex: 1; }
  .pr-card-cta { font-size: 13px; font-weight: 700; color: var(--color-blue); }
  .pr-card-danger .pr-card-cta { color: var(--color-red); }

  .tone-blue { background: var(--color-blue-light); }
  .tone-green { background: rgba(22,143,91,0.12); }
  .tone-amber { background: rgba(232,163,23,0.16); }
  .tone-red { background: var(--color-red-light); }

  /* ---- Activité (mock-rows) ---- */
  .pr-mock-row {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 0; border-bottom: 1px solid var(--color-line-2); text-decoration: none;
  }
  .pr-mock-row:last-child { border-bottom: none; }
  .pr-mock-body { flex: 1; min-width: 0; }
  .pr-mock-body h3 { font-family: var(--font-sans); font-weight: 700; font-size: 14px; color: var(--color-ink); margin: 0 0 2px; }
  .pr-mock-body p { font-size: 12.5px; color: var(--color-muted); line-height: 1.45; margin: 0; }
  .pr-mock-btn {
    flex-shrink: 0; padding: 8px 14px; border-radius: 9px; background: var(--color-blue); color: #fff;
    font-family: var(--font-sans); font-weight: 700; font-size: 12.5px; transition: background 0.15s;
  }
  .pr-mock-row:hover .pr-mock-btn { background: var(--color-blue-dark); }

  /* ---- Footnote / logout ---- */
  .pr-footnote {
    display: flex; flex-direction: column; gap: 12px; align-items: flex-start;
    font-size: 13px; color: var(--color-muted); line-height: 1.5;
  }
  .pr-footnote a { color: var(--color-blue); font-weight: 600; text-decoration: none; }
  .pr-footnote a:hover { text-decoration: underline; }
  .pr-logout {
    padding: 10px 18px; border-radius: 10px; border: 1px solid var(--color-line);
    background: #fff; color: var(--color-red); font-family: var(--font-sans);
    font-size: 13.5px; font-weight: 700; cursor: pointer; transition: all 0.15s;
  }
  .pr-logout:hover { border-color: var(--color-red); background: var(--color-red-light); }

  @media (min-width: 560px) {
    .pr-cards { grid-template-columns: 1fr 1fr; }
  }
  @media (min-width: 900px) {
    .pr-hero { grid-template-columns: 1.5fr 1fr; align-items: stretch; padding: 30px; }
    .pr-cols { grid-template-columns: 1.6fr 1fr; }
    .pr-cards { grid-template-columns: repeat(4, 1fr); }
  }
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
