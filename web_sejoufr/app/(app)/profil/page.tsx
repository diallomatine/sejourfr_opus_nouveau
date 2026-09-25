"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {
    Bell,
    Bookmark,
    CircleHelp,
    GraduationCap,
    LogOut,
    MapPin,
    PenLine,
    Pencil,
    Target,
    X,
} from "lucide-react";
import {useAuth} from "@/lib/auth-context";
import {journeyTargetPathHref} from "@/lib/journey";
import {accountApi, billingApi, dashboardApi} from "@/lib/api";
import {AIDE_HREF} from "@/lib/aide";
import {FAVORIS_HREF, FAVORIS_ROW_SUB, FAVORIS_TITLE} from "@/lib/favoris";
import {
    COMPTE_INFORMATIONS_HREF,
    COMPTE_NOTIF_ROW_SUB,
    COMPTE_NOTIF_ROW_TITLE,
    COMPTE_NOTIFICATIONS_HREF,
    COMPTE_PROFIL_HREF,
    compteIsLocal,
} from "@/lib/compte";
import {CompteCard, CompteGate, CompteLoading, CompteRow} from "../../_components/compte/CompteParts";
import {estimatedTcfLevelScopeLabel, niveauCecrlShort, niveauViseTcf} from "@/lib/types";
import type {
    DashboardSummaryResponse,
    SubscriptionStatusResponse,
    TargetProcedure,
} from "@/lib/types";

/**
 * Page profil web — maquette du propriétaire
 * (`docs/progression/maquettes-progression/profil.html`), en parité de contenu
 * avec l'onglet Profil mobile (`profile_screen.dart`). Sections :
 *   - barre de titre « Mon profil » (desktop seul : sous 900 px, la barre du
 *     haut du shell, `AppTopBar`, porte déjà le titre)
 *   - hero bleu : avatar, nom, e-mail, démarche, bouton « Modifier »
 *   - 3 tuiles (maîtrise / série / niveau estimé + périmètre) issues de /api/me/dashboard
 *   - grille « Mon pass » (subscription-status) | « Mon objectif » (démarche)
 *   - « Mon compte » : Mes informations (`/profil/informations`, ses trois pages
 *     d'édition), Notifications par e-mail (`/profil/notifications`), Mes
 *     favoris (`/favoris`), Aide & assistance (`/aide`). « Ma
 *     progression » est dans la barre latérale (« Progression »), pas ici.
 *   - déconnexion + suppression de compte (DELETE /api/account)
 *
 * Tout ce qui est affiché est servi : aucun nombre n'est classé ici.
 */
export default function ProfilPage() {
    const router = useRouter();
    const {user, status, logout} = useAuth();

    const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [deleting, setDeleting] = useState(false);
    const [deleteError, setDeleteError] = useState<string | null>(null);
    // Message d'action manuelle (résiliation Apple/Google) affiché après
    // suppression, avant la redirection finale.
    const [deleteNotice, setDeleteNotice] = useState<string | null>(null);

    const [dashboard, setDashboard] = useState<DashboardSummaryResponse | null>(null);
    const [subscription, setSubscription] = useState<SubscriptionStatusResponse | null>(null);

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        void dashboardApi.summaryCached().then((d) => {
            if (!cancelled) setDashboard(d);
        }).catch(() => {});
        void billingApi.getSubscriptionStatus().then((s) => {
            if (!cancelled) setSubscription(s);
        }).catch(() => {});
        return () => {
            cancelled = true;
        };
    }, [status]);

    const anyModalOpen = showLogoutConfirm || showDeleteConfirm || !!deleteNotice;
    useEffect(() => {
        if (!anyModalOpen) return;
        const prev = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        return () => {
            document.body.style.overflow = prev;
        };
    }, [anyModalOpen]);

    function handleLogout() {
        logout();
        router.push("/");
    }

    async function handleDeleteAccount() {
        setDeleting(true);
        setDeleteError(null);
        try {
            const result = await accountApi.deleteAccount();
            setShowDeleteConfirm(false);
            if (result.hasActiveSubscription && result.manualActionMessage) {
                setDeleteNotice(result.manualActionMessage);
            } else {
                finalizeDeletion();
            }
        } catch {
            setDeleteError("Échec de la suppression. Réessayez ou contactez le support.");
        } finally {
            setDeleting(false);
        }
    }

    function finalizeDeletion() {
        logout();
        router.push("/");
    }

    if (status === "loading") return <CompteLoading/>;
    if (!user) return <CompteGate next={COMPTE_PROFIL_HREF}/>;

    const fullName =
        [user.firstName, user.lastName].filter(Boolean).join(" ").trim() || user.email;
    const initials =
        (user.firstName?.[0] ?? user.email[0] ?? "?").toUpperCase() +
        (user.lastName?.[0]?.toUpperCase() ?? "");
    const proc = user.targetProcedure ? PROCEDURE_INFO[user.targetProcedure] : null;
    // Le palier VISÉ, plancher de la démarche appliqué — pas une table locale.
    const niveauVise = niveauViseTcf(user);
    const isLocal = compteIsLocal(user.authProvider);

    // ── 3 tuiles (parité mobile) ──────────────────────────────────────────
    const masteryValue =
        dashboard?.globalSuccessPercent != null
            ? `${dashboard.globalSuccessPercent} %`
            : "—";
    const streakValue = dashboard ? `${dashboard.currentStreakDays} j` : "—";
    // Forme courte partagée (« <A1 » et pas « A1 »), jamais une table locale.
    const levelValue = niveauCecrlShort(dashboard?.estimatedTcfLevel ?? null);
    // Périmètre SERVI (épreuves comptées / attendues), une seule chaîne partagée.
    const levelScope = estimatedTcfLevelScopeLabel(dashboard);

    // ── Mon pass ──────────────────────────────────────────────────────────
    const premium = subscription?.isPremium ?? user.isPremium ?? false;
    const access = subscription?.moduleAccess;
    const passName = !premium
        ? "Découverte"
        : access === "INTEGRAL"
            ? "Pass Intégral"
            : "Pass Civique";
    const expiresAt = subscription?.expiresAt ?? user.premiumEndsAt ?? null;
    const passSub = !premium
        ? "Accès limité — débloquez tout SejourFR"
        : expiresAt
            ? `Valable jusqu'au ${formatDate(expiresAt)}`
            : "Accès actif";
    const passHref = premium ? "/profil/abonnement" : "/paiement";

    return (
        <main className="pr">
            <div className="pr-shell">
                {/* ---- Barre de titre (desktop) : sous 900 px, c'est la barre du shell ---- */}
                <div className="pr-topbar">
                    <span className="pr-topbar-slot" aria-hidden/>
                    <div className="pr-page-title">Mon profil</div>
                    <span className="pr-topbar-slot" aria-hidden/>
                </div>

                {/* ---- Hero ---- */}
                <section className="pr-hero">
                    <div className="pr-hero-head">
                        <span className="pr-avatar" aria-hidden>{initials}</span>
                        <div className="pr-identity">
                            <h1>{fullName}</h1>
                            <p>{user.email}</p>
                            {proc && (
                                <span className="pr-badge">
                                    <MapPin size={13} aria-hidden/> {proc.short}
                                </span>
                            )}
                        </div>
                        <Link
                            href={COMPTE_INFORMATIONS_HREF}
                            className="pr-edit-btn"
                            aria-label="Modifier mes informations"
                        >
                            <span className="pr-edit-txt">Modifier</span>
                            <Pencil className="pr-edit-ico" size={16} aria-hidden/>
                        </Link>
                    </div>
                </section>

                {/* ---- 3 tuiles ---- */}
                <section className="pr-stats">
                    <StatTile label="Maîtrise" value={masteryValue}/>
                    <StatTile label="Série" value={streakValue} tone="red"/>
                    <StatTile label="Niveau estimé" value={levelValue} meta={levelScope}/>
                </section>

                <div className="pr-grid">
                    {/* ---- Mon pass ---- */}
                    <CompteCard title="Mon pass">
                        <CompteRow
                            href={passHref}
                            icon={<GraduationCap size={21}/>}
                            tone={premium ? "green" : "muted"}
                            title={
                                <>
                                    {passName}
                                    <span className={`pr-status ${premium ? "is-active" : "is-free"}`}>
                                        {premium ? "Actif" : "Gratuit"}
                                    </span>
                                </>
                            }
                            sub={passSub}
                        />
                    </CompteCard>

                    {/* ---- Mon objectif ---- */}
                    <CompteCard title="Mon objectif">
                        <CompteRow
                            href={journeyTargetPathHref("/profil")}
                            icon={<Target size={21}/>}
                            title={proc ? proc.title : "Choisir mon parcours"}
                            sub={proc
                                ? `Niveau de français visé : ${niveauVise}`
                                : "Définissez votre objectif administratif"}
                        />
                    </CompteCard>

                    {/* ---- Mon compte ---- */}
                    <CompteCard title="Mon compte" className="pr-full">
                        <CompteRow
                            href={COMPTE_INFORMATIONS_HREF}
                            icon={<PenLine size={20}/>}
                            title="Mes informations"
                            sub={isLocal ? "Nom, prénom, e-mail et mot de passe" : "Nom et prénom"}
                        />
                        <CompteRow
                            href={COMPTE_NOTIFICATIONS_HREF}
                            icon={<Bell size={20}/>}
                            title={COMPTE_NOTIF_ROW_TITLE}
                            sub={COMPTE_NOTIF_ROW_SUB}
                        />
                        {/* « Ma progression » n'est PAS ici sur le web : elle vit dans
                            la barre latérale (« Progression », 2026-09-24). Le Profil
                            mobile, sans barre latérale, garde sa ligne. */}
                        <CompteRow
                            href={FAVORIS_HREF}
                            icon={<Bookmark size={20}/>}
                            title={FAVORIS_TITLE}
                            sub={FAVORIS_ROW_SUB}
                        />
                        <CompteRow
                            href={AIDE_HREF}
                            icon={<CircleHelp size={20}/>}
                            title="Aide & assistance"
                            sub="FAQ, CGU, confidentialité, contact"
                        />
                    </CompteCard>

                    {/* ---- Session ---- */}
                    <CompteCard className="pr-full">
                        <CompteRow
                            onClick={() => setShowLogoutConfirm(true)}
                            icon={<LogOut size={20}/>}
                            title="Se déconnecter"
                            chevron={false}
                        />
                        <CompteRow
                            onClick={() => {
                                setDeleteError(null);
                                setShowDeleteConfirm(true);
                            }}
                            icon={<X size={21}/>}
                            tone="red"
                            title="Supprimer mon compte"
                            danger
                        />
                    </CompteCard>
                </div>

                <div className="pr-footer">SejourFR · v0.1.0</div>
            </div>

            {/* ---- MODALES ---- */}
            {showLogoutConfirm && (
                <ConfirmModal
                    title="Se déconnecter ?"
                    body="Vous devrez vous reconnecter pour reprendre votre préparation. Vos données restent en sécurité côté serveur."
                    confirmLabel="Me déconnecter"
                    confirmTone="danger"
                    onConfirm={handleLogout}
                    onCancel={() => setShowLogoutConfirm(false)}
                />
            )}
            {showDeleteConfirm && (
                <ConfirmModal
                    title="Supprimer votre compte ?"
                    body={
                        (deleteError ? `${deleteError}\n\n` : "") +
                        "Cette action est irréversible. Vos progrès, examens, favoris et " +
                        "informations personnelles seront définitivement supprimés." +
                        (user.isPremium
                            ? " Votre accès payant en cours sera perdu et ne fait l'objet d'aucun remboursement."
                            : "")
                    }
                    confirmLabel={deleting ? "Suppression…" : "Supprimer mon compte"}
                    confirmTone="danger"
                    onConfirm={handleDeleteAccount}
                    onCancel={() => {
                        if (deleting) return;
                        setShowDeleteConfirm(false);
                    }}
                />
            )}
            {deleteNotice && (
                <ConfirmModal
                    title="Compte supprimé"
                    body={deleteNotice}
                    confirmLabel="Compris"
                    confirmTone="neutral"
                    onConfirm={finalizeDeletion}
                    onCancel={finalizeDeletion}
                    singleAction
                />
            )}

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// BRIQUES
// ============================================================================
function StatTile({
                      label,
                      value,
                      tone = "blue",
                      meta,
                  }: {
    label: string;
    value: string;
    tone?: "blue" | "red";
    /** Précision servie sous le libellé (périmètre d'un niveau estimé
     *  partiel). Absente ⇒ la tuile garde ses deux lignes. */
    meta?: string | null;
}) {
    return (
        <div className="pr-stat">
            <div className={`pr-stat-value tone-${tone}`}>{value}</div>
            <div className="pr-stat-label">{label}</div>
            {meta && <div className="pr-stat-meta">{meta}</div>}
        </div>
    );
}

// ============================================================================
// CONFIRMATION (déconnexion, suppression, avis post-suppression)
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
        <div className="pm" role="dialog" aria-modal="true" aria-labelledby="pm-confirm-title" onClick={onCancel}>
            <section className="pm-sheet pm-sheet-narrow" onClick={(e) => e.stopPropagation()}>
                <h2 id="pm-confirm-title" className="pm-title">{title}</h2>
                <p className="pm-body">{body}</p>
                <div className="pm-actions">
                    {!singleAction && (
                        <button type="button" className="pm-btn pm-btn-secondary" onClick={onCancel}>
                            Annuler
                        </button>
                    )}
                    <button
                        type="button"
                        className={`pm-btn pm-btn-${confirmTone}`}
                        onClick={onConfirm}
                    >
                        {confirmLabel}
                    </button>
                </div>
            </section>
        </div>
    );
}

// ============================================================================
// HELPERS
// ============================================================================
/** Le palier exigé n'est PAS recopié : `TCF_LEVEL_BY_PROCEDURE` (miroir gelé de
 *  l'enum backend) le porte pour les trois surfaces web. */
const PROCEDURE_INFO: Record<TargetProcedure, {title: string; short: string}> = {
    CSP: {title: "Carte de séjour pluriannuelle", short: "CSP"},
    CR: {title: "Carte de résident (10 ans)", short: "CR"},
    NAT: {title: "Naturalisation française", short: "NAT"},
};

function formatDate(iso: string): string {
    const d = new Date(iso);
    return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "long", year: "numeric"});
}

// ============================================================================
// STYLES — géométrie de la maquette, couleurs et polices de l'application.
// Aucune valeur hexadécimale : tokens `var(--color-*)`, `white`, `color-mix()`.
// ============================================================================
const styles = `
  .pr {
    min-height: 100vh; padding: 24px 18px 48px;
  }
  .pr-shell { width: min(980px, 100%); margin: 0 auto; }

  /* ---- Barre de titre (masquée sous 900 px : AppTopBar la remplace) ---- */
  .pr-topbar { display: flex; align-items: center; justify-content: space-between; min-height: 48px; margin-bottom: 18px; }
  .pr-topbar-slot { width: 48px; height: 48px; flex-shrink: 0; }
  .pr-page-title {
    font-family: var(--font-mono); font-size: 15px; font-weight: 700; letter-spacing: 0.16em;
    text-transform: uppercase; color: var(--color-muted); text-align: center; min-width: 0;
  }

  /* ---- Hero ---- */
  .pr-hero {
    position: relative; overflow: hidden; border-radius: 30px; padding: 28px; color: white;
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-mid) 100%);
    box-shadow: 0 16px 34px color-mix(in srgb, var(--color-blue) 18%, transparent);
  }
  .pr-hero::after {
    content: ""; position: absolute; width: 220px; height: 220px; right: -80px; top: -90px;
    border-radius: 50%; background: color-mix(in srgb, white 7%, transparent); pointer-events: none;
  }
  .pr-hero-head { display: flex; align-items: center; gap: 18px; position: relative; z-index: 1; }
  .pr-avatar {
    width: 70px; height: 70px; flex: 0 0 70px; border-radius: 20px; background: white; color: var(--color-ink);
    display: grid; place-items: center; font-family: var(--font-display); font-size: 27px; font-weight: 700;
    box-shadow: 0 8px 22px color-mix(in srgb, var(--color-ink) 10%, transparent);
  }
  .pr-identity { min-width: 0; flex: 1; }
  .pr-identity h1 {
    margin: 0 0 5px; font-family: var(--font-display); font-weight: 700; font-size: 30px; line-height: 1.05;
    letter-spacing: -0.01em; color: white; overflow-wrap: anywhere;
  }
  .pr-identity p {
    margin: 0; font-size: 15px; color: color-mix(in srgb, white 84%, var(--color-blue));
    overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
  }
  .pr-badge {
    display: inline-flex; align-items: center; gap: 7px; margin-top: 10px; padding: 7px 10px;
    border-radius: 999px; background: color-mix(in srgb, white 13%, transparent); color: white;
    font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.08em;
  }
  .pr-edit-btn {
    position: relative; z-index: 1; flex-shrink: 0; cursor: pointer;
    border: 1px solid color-mix(in srgb, white 25%, transparent);
    background: color-mix(in srgb, white 12%, transparent); color: white;
    border-radius: 14px; padding: 11px 15px; font-family: var(--font-sans); font-size: 14px; font-weight: 700;
    text-decoration: none; display: inline-flex; align-items: center; justify-content: center; transition: background 0.15s;
  }
  .pr-edit-btn:hover { background: color-mix(in srgb, white 20%, transparent); }
  .pr-edit-btn:focus-visible { outline: 2px solid white; outline-offset: 2px; }
  .pr-edit-ico { display: none; }

  /* ---- Tuiles ---- */
  .pr-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin: 14px 0 28px; }
  .pr-stat {
    background: white; border: 1px solid var(--color-line); border-radius: 20px; padding: 17px 15px; min-width: 0;
    box-shadow: 0 4px 18px color-mix(in srgb, var(--color-ink) 3.5%, transparent);
  }
  .pr-stat-value { font-family: var(--font-display); font-size: 25px; font-weight: 700; line-height: 1.15; }
  .pr-stat-value.tone-blue { color: var(--color-blue); }
  .pr-stat-value.tone-red { color: var(--color-red); }
  .pr-stat-label {
    margin-top: 4px; font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.12em;
    text-transform: uppercase; color: var(--color-muted);
  }
  .pr-stat-meta { margin-top: 3px; font-size: 12px; line-height: 1.3; color: var(--color-muted-2); overflow-wrap: anywhere; }

  /* ---- Grille de contenu (cartes et lignes : \`CompteCard\` / \`CompteRow\`) ---- */
  .pr-grid { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 18px; }
  .pr-full { grid-column: 1 / -1; }

  /* ---- Pastille du pass ---- */
  .pr-status {
    display: inline-flex; align-items: center; margin-left: 8px; padding: 5px 9px; border-radius: 999px;
    font-family: var(--font-mono); font-size: 11px; font-weight: 800; letter-spacing: 0.08em;
    text-transform: uppercase; vertical-align: 2px;
  }
  .pr-status.is-active { background: var(--color-green-light); color: var(--color-green); }
  .pr-status.is-free { background: var(--color-paper-2); color: var(--color-muted); }

  .pr-footer {
    margin-top: 28px; text-align: center; font-family: var(--font-mono); font-size: 12px;
    letter-spacing: 0.08em; color: var(--color-muted-2);
  }

  /* ---- Modales de confirmation : feuille posée en bas (maquette) ---- */
  .pm {
    position: fixed; inset: 0; z-index: 100; display: flex; align-items: flex-end; justify-content: center;
    padding: 18px; background: color-mix(in srgb, var(--color-ink) 42%, transparent);
    -webkit-backdrop-filter: blur(4px); backdrop-filter: blur(4px); animation: pm-fade 0.18s ease-out;
  }
  @keyframes pm-fade { from { opacity: 0; } to { opacity: 1; } }
  @keyframes pm-slide { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  .pm-sheet {
    width: min(480px, 100%); max-height: calc(100vh - 36px); overflow-y: auto; background: white;
    border-radius: 28px 28px 22px 22px; padding: 24px; animation: pm-slide 0.22s ease-out;
    box-shadow: 0 24px 60px color-mix(in srgb, var(--color-ink) 22%, transparent);
  }
  .pm-title {
    margin: 0; font-family: var(--font-display); font-weight: 600; font-size: 25px;
    letter-spacing: -0.02em; color: var(--color-ink);
  }
  .pm-sheet-narrow .pm-title { font-size: 22px; margin-bottom: 8px; }
  .pm-body { margin: 0 0 22px; font-size: 14px; line-height: 1.55; color: var(--color-muted); white-space: pre-line; }

  .pm-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 18px; flex-wrap: wrap; }
  .pm-btn {
    border-radius: 13px; padding: 12px 16px; font-family: var(--font-sans); font-size: 14px; font-weight: 800;
    cursor: pointer; border: 1px solid transparent; transition: background 0.15s, border-color 0.15s;
  }
  .pm-btn-secondary { background: white; border-color: var(--color-line); color: var(--color-ink); }
  .pm-btn-secondary:hover { border-color: var(--color-ink); }
  .pm-btn-primary { background: var(--color-blue); color: white; }
  .pm-btn-primary:hover { background: var(--color-blue-dark); }
  .pm-btn-danger { background: var(--color-red); color: white; }
  .pm-btn-danger:hover { background: var(--color-red-dark); }
  .pm-btn-neutral { background: var(--color-ink); color: white; }
  .pm-btn-neutral:hover { background: var(--color-ink-2); }
  @media (max-width: 900px) {
    .pr-topbar { display: none; }
    /* Sous la barre du haut de l'espace connecté : --app-bar-gap (globals.css). */
    .app-shell--has-drawer .pr { padding-top: var(--app-bar-gap); }
  }
  /* ---- ≤ 760 px ---- */
  @media (max-width: 760px) {
    .pr { padding: 16px 14px 34px; }
    .pr-grid { grid-template-columns: minmax(0, 1fr); }
    .pr-full { grid-column: auto; }
    .pr-hero { padding: 22px 18px; border-radius: 26px; }
    .pr-hero-head { align-items: flex-start; }
    .pr-avatar { width: 60px; height: 60px; flex-basis: 60px; border-radius: 17px; font-size: 23px; }
    .pr-identity h1 { font-size: 24px; }
    .pr-identity p { font-size: 13px; }
    .pr-edit-btn { padding: 9px 11px; font-size: 13px; }
    .pr-stats { gap: 8px; margin-top: 10px; margin-bottom: 20px; }
    .pr-stat { padding: 14px 10px; border-radius: 17px; }
    .pr-stat-value { font-size: 22px; }
    .pr-stat-label { font-size: 9px; letter-spacing: 0.1em; }
    .pr-stat-meta { font-size: 10px; }
    .pm-sheet { padding: 20px; }
  }

  /* ---- ≤ 430 px ---- */
  @media (max-width: 430px) {
    .pr-hero-head { display: grid; grid-template-columns: 60px minmax(0, 1fr) auto; gap: 12px; }
    .pr-identity h1 { font-size: 22px; }
    .pr-edit-btn { width: 38px; height: 38px; padding: 0; border-radius: 12px; }
    .pr-edit-txt { display: none; }
    .pr-edit-ico { display: block; }
  }
`;
