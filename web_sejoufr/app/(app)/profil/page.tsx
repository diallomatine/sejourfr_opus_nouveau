"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {useAuth} from "@/lib/auth-context";
import {accountApi, ApiException, billingApi, dashboardApi} from "@/lib/api";
import {estimatedTcfLevelScopeLabel, niveauCecrlShort, niveauViseTcf} from "@/lib/types";
import type {
    DashboardSummaryResponse,
    SubscriptionStatusResponse,
    TargetProcedure,
} from "@/lib/types";

/**
 * Page profil web — parité avec l'onglet Profil mobile (`profile_screen.dart`),
 * en design web (hero éditorial + cartes tokens). Sections :
 *   - identité (avatar, nom, email, parcours) + bouton « Modifier »
 *   - 3 stat cards (maîtrise / série / niveau estimé) issues de /api/me/dashboard
 *   - « Mon pass » (statut Premium agrégé) → /profil/abonnement ou /paiement
 *   - « Mon objectif » (CSP/CR/NAT) → /parcours
 *   - « Mes informations » → modale d'édition (identité + email + mot de passe)
 *   - zone danger : suppression de compte (DELETE /api/account) + déconnexion
 *
 * Volontairement SANS date d'examen, plan de révision, centre d'aide ni
 * réinitialisation de progression (décision produit).
 */
export default function ProfilPage() {
    const router = useRouter();
    const {user, status, logout, refreshUser} = useAuth();

    const [showEdit, setShowEdit] = useState(false);
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

    const anyModalOpen = showEdit || showLogoutConfirm || showDeleteConfirm || !!deleteNotice;
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

    if (status === "loading") return <ProfilSkeleton/>;
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
        [user.firstName, user.lastName].filter(Boolean).join(" ").trim() || user.email;
    const initials =
        (user.firstName?.[0] ?? user.email[0] ?? "?").toUpperCase() +
        (user.lastName?.[0]?.toUpperCase() ?? "");
    const proc = user.targetProcedure ? PROCEDURE_INFO[user.targetProcedure] : null;
    // Le palier VISÉ, plancher de la démarche appliqué — pas une table locale.
    const niveauVise = niveauViseTcf(user);

    // ── 3 stats (parité mobile) ───────────────────────────────────────────
    const masteryValue =
        dashboard?.globalSuccessPercent != null
            ? `${dashboard.globalSuccessPercent} %`
            : "—";
    const streakValue = dashboard ? `${dashboard.currentStreakDays} j` : "—";
    // Forme courte partagée (« <A1 » et pas « A1 »), jamais une table locale.
    const levelValue = niveauCecrlShort(dashboard?.estimatedTcfLevel ?? null);
    const levelScope = estimatedTcfLevelScopeLabel(dashboard);

    // ── Mon pass ──────────────────────────────────────────────────────────
    const premium = subscription?.isPremium ?? user.isPremium ?? false;
    const access = subscription?.moduleAccess;
    const passName = !premium
        ? "Découverte"
        : access === "INTEGRAL"
            ? "Pass Intégral"
            : access === "TCF"
                ? "Pass TCF"
                : "Pass Civique";
    const passAccent = !premium ? "neutral" : access === "INTEGRAL" ? "red" : "blue";
    const expiresAt = subscription?.expiresAt ?? user.premiumEndsAt ?? null;
    const passSub = !premium
        ? "Accès limité — débloquez tout SejourFR"
        : expiresAt
            ? `Valable jusqu'au ${formatDate(expiresAt)}`
            : "Accès actif";
    const passHref = premium ? "/profil/abonnement" : "/paiement";

    return (
        <main className="pr">
            {/* ---- Hero + identité ---- */}
            <section className="pr-hero">
                <div className="pr-hero-main">
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span> PROFIL
                    </div>
                    <h1>Mon <em>profil</em></h1>
                    <p>Gère ton compte, ton objectif d&apos;examen et ton abonnement.</p>
                </div>

                <div className="pr-id">
                    <span className="pr-avatar">{initials}</span>
                    <div className="pr-id-body">
                        <div className="pr-id-name">{fullName}</div>
                        <div className="pr-id-email">{user.email}</div>
                        {proc && (
                            <span className="pr-id-tag">
                                <span aria-hidden>📍</span> {proc.short}
                            </span>
                        )}
                    </div>
                    <button type="button" className="pr-id-edit" onClick={() => setShowEdit(true)}>
                        Modifier
                    </button>
                </div>
            </section>

            {/* ---- 3 stats ---- */}
            <section className="pr-stats">
                <StatCard label="Maîtrise" value={masteryValue} accent="blue"/>
                <StatCard label="Série" value={streakValue} accent="red"/>
                <StatCard label="Niveau estimé" value={levelValue} accent="blue" hint={levelScope}/>
            </section>

            {/* ---- Mon pass ---- */}
            <div className="pr-section-title"><h2>Mon pass</h2></div>
            <Link href={passHref} className={`pr-line-card pr-pass accent-${passAccent}`}>
                <span className="pr-line-icon" aria-hidden>🎓</span>
                <div className="pr-line-body">
                    <div className="pr-line-head">
                        <h3>{passName}</h3>
                        <span className={`pr-pill ${premium ? "pill-active" : "pill-free"}`}>
                            {premium ? "Actif" : "Gratuit"}
                        </span>
                    </div>
                    <p>{passSub}</p>
                </div>
                <span className="pr-chevron" aria-hidden>›</span>
            </Link>

            {/* ---- Mon objectif ---- */}
            <div className="pr-section-title"><h2>Mon objectif</h2></div>
            <Link href="/parcours?from=/profil" className="pr-line-card pr-objectif">
                <span className="pr-line-icon tone-objectif" aria-hidden>🎯</span>
                <div className="pr-line-body">
                    <div className="pr-line-head">
                        <h3>{proc ? proc.title : "Choisir mon parcours"}</h3>
                    </div>
                    <p>
                        {proc
                            ? `Niveau de français visé : ${niveauVise} — toucher pour modifier`
                            : "Définissez votre objectif administratif"}
                    </p>
                </div>
                <span className="pr-chevron" aria-hidden>›</span>
            </Link>

            {/* ---- Mon compte ---- */}
            <div className="pr-section-title"><h2>Mon compte</h2></div>
            <div className="pr-group">
                <button type="button" className="pr-row" onClick={() => setShowEdit(true)}>
                    <span className="pr-row-icon" aria-hidden>✎</span>
                    <span className="pr-row-body">
                        <span className="pr-row-title">Mes informations</span>
                        <span className="pr-row-sub">{user.email}</span>
                    </span>
                    <span className="pr-chevron" aria-hidden>›</span>
                </button>
            </div>

            {/* ---- Danger ---- */}
            <div className="pr-group">
                <button
                    type="button"
                    className="pr-row pr-row-danger"
                    onClick={() => {
                        setDeleteError(null);
                        setShowDeleteConfirm(true);
                    }}
                >
                    <span className="pr-row-icon tone-danger" aria-hidden>✕</span>
                    <span className="pr-row-body">
                        <span className="pr-row-title">Supprimer mon compte</span>
                    </span>
                </button>
                <button type="button" className="pr-row" onClick={() => setShowLogoutConfirm(true)}>
                    <span className="pr-row-icon tone-muted" aria-hidden>⤺</span>
                    <span className="pr-row-body">
                        <span className="pr-row-title">Se déconnecter</span>
                    </span>
                </button>
            </div>

            <div className="pr-version">SejourFR · v0.1.0</div>

            {/* ---- MODALS ---- */}
            {showEdit && (
                <InfoEditModal
                    user={user}
                    onClose={() => setShowEdit(false)}
                    onIdentitySaved={refreshUser}
                />
            )}
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
// STAT CARD
// ============================================================================
function StatCard({
                      label,
                      value,
                      accent,
                      hint,
                  }: {
    label: string;
    value: string;
    accent: "blue" | "red";
    /** Précision facultative sous le libellé (périmètre d'un niveau estimé
     *  partiel). Absente ⇒ la carte garde exactement ses deux lignes. */
    hint?: string | null;
}) {
    return (
        <div className={`pr-stat-card accent-${accent}`}>
            <div className="pr-stat-value">{value}</div>
            <div className="pr-stat-label">{label}</div>
            {hint && <div className="pr-stat-hint">{hint}</div>}
        </div>
    );
}

// ============================================================================
// INFO EDIT MODAL (identité + email + mot de passe)
// ============================================================================
type EditUser = {
    email: string;
    firstName: string;
    lastName: string;
    authProvider?: "LOCAL" | "GOOGLE" | "APPLE";
};

function InfoEditModal({
                           user,
                           onClose,
                           onIdentitySaved,
                       }: {
    user: EditUser;
    onClose: () => void;
    onIdentitySaved: () => Promise<void>;
}) {
    const isLocal = !user.authProvider || user.authProvider === "LOCAL";
    const providerLabel = user.authProvider === "GOOGLE" ? "Google" : user.authProvider === "APPLE" ? "Apple" : "email";

    const [firstName, setFirstName] = useState(user.firstName ?? "");
    const [lastName, setLastName] = useState(user.lastName ?? "");
    const [savingIdentity, setSavingIdentity] = useState(false);
    const [identityError, setIdentityError] = useState<string | null>(null);
    const [identityOk, setIdentityOk] = useState(false);

    const [emailOpen, setEmailOpen] = useState(false);
    const [pwdOpen, setPwdOpen] = useState(false);

    useEffect(() => {
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape") onClose();
        };
        window.addEventListener("keydown", onKey);
        return () => window.removeEventListener("keydown", onKey);
    }, [onClose]);

    async function saveIdentity() {
        const fn = firstName.trim();
        const ln = lastName.trim();
        if (!fn || !ln) {
            setIdentityError("Prénom et nom requis");
            return;
        }
        setSavingIdentity(true);
        setIdentityError(null);
        setIdentityOk(false);
        try {
            await accountApi.updateProfile(fn, ln);
            await onIdentitySaved();
            setIdentityOk(true);
        } catch (e) {
            setIdentityError(e instanceof ApiException ? e.message : "Échec de la mise à jour.");
        } finally {
            setSavingIdentity(false);
        }
    }

    return (
        <div className="cm" role="dialog" aria-modal="true" onClick={onClose}>
            <div className="cm-backdrop"/>
            <div className="cm-sheet cm-sheet-wide" onClick={(e) => e.stopPropagation()}>
                <div className="cm-head">
                    <h2 className="cm-title">Mes informations</h2>
                    <button type="button" className="cm-close" onClick={onClose} aria-label="Fermer">✕</button>
                </div>

                {/* Identité */}
                <div className="ed-label">Identité</div>
                <div className="ed-block">
                    <div className="ed-grid">
                        <div className="ed-field">
                            <label htmlFor="ed-fn">Prénom</label>
                            <input
                                id="ed-fn"
                                className="ed-input"
                                value={firstName}
                                onChange={(e) => setFirstName(e.target.value)}
                                autoComplete="given-name"
                            />
                        </div>
                        <div className="ed-field">
                            <label htmlFor="ed-ln">Nom</label>
                            <input
                                id="ed-ln"
                                className="ed-input"
                                value={lastName}
                                onChange={(e) => setLastName(e.target.value)}
                                autoComplete="family-name"
                            />
                        </div>
                    </div>
                    {identityError && <p className="ed-error">{identityError}</p>}
                    {identityOk && <p className="ed-ok">Identité mise à jour.</p>}
                    <button type="button" className="ed-btn" disabled={savingIdentity} onClick={saveIdentity}>
                        {savingIdentity ? "Enregistrement…" : "Enregistrer"}
                    </button>
                </div>

                {/* Email */}
                <div className="ed-label">Adresse e-mail</div>
                <div className="ed-block">
                    <div className="ed-readline">
                        <span className="ed-readval">{user.email}</span>
                        {isLocal && !emailOpen && (
                            <button type="button" className="ed-ghost" onClick={() => setEmailOpen(true)}>
                                Changer
                            </button>
                        )}
                    </div>
                    {!isLocal && (
                        <p className="ed-note">
                            Connexion via {providerLabel} — l&apos;e-mail se gère côté {providerLabel}.
                        </p>
                    )}
                    {isLocal && emailOpen && (
                        <ChangeEmailForm currentEmail={user.email} onClose={() => setEmailOpen(false)}/>
                    )}
                </div>

                {/* Mot de passe */}
                <div className="ed-label">Mot de passe</div>
                <div className="ed-block">
                    <div className="ed-readline">
                        <span className="ed-readval">••••••••••</span>
                        {isLocal && !pwdOpen && (
                            <button type="button" className="ed-ghost" onClick={() => setPwdOpen(true)}>
                                Modifier
                            </button>
                        )}
                    </div>
                    {!isLocal && (
                        <p className="ed-note">
                            Connexion via {providerLabel} — pas de mot de passe SejourFR.
                        </p>
                    )}
                    {isLocal && pwdOpen && <ChangePasswordForm onClose={() => setPwdOpen(false)}/>}
                </div>

                <style>{modalStyles}</style>
                <style>{editStyles}</style>
            </div>
        </div>
    );
}

function ChangeEmailForm({currentEmail, onClose}: {currentEmail: string; onClose: () => void}) {
    const [newEmail, setNewEmail] = useState("");
    const [password, setPassword] = useState("");
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [done, setDone] = useState(false);

    async function submit() {
        const email = newEmail.trim();
        if (!email.includes("@")) {
            setError("E-mail invalide");
            return;
        }
        if (!password) {
            setError("Votre mot de passe actuel est requis");
            return;
        }
        setSubmitting(true);
        setError(null);
        try {
            await accountApi.requestEmailChange(email, password);
            setDone(true);
        } catch (e) {
            setError(e instanceof ApiException ? e.message : "Échec de la demande.");
        } finally {
            setSubmitting(false);
        }
    }

    if (done) {
        return (
            <div className="ed-sub">
                <p className="ed-ok">
                    Lien de vérification envoyé à {newEmail}. Cliquez dessus pour confirmer. Votre compte
                    reste accessible avec {currentEmail} en attendant.
                </p>
                <button type="button" className="ed-ghost" onClick={onClose}>Fermer</button>
            </div>
        );
    }

    return (
        <div className="ed-sub">
            <div className="ed-field">
                <label htmlFor="ed-newmail">Nouvel e-mail</label>
                <input
                    id="ed-newmail"
                    className="ed-input"
                    type="email"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    placeholder="nouvel@email.fr"
                    autoComplete="email"
                />
            </div>
            <div className="ed-field">
                <label htmlFor="ed-mailpwd">Mot de passe actuel</label>
                <input
                    id="ed-mailpwd"
                    className="ed-input"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete="current-password"
                />
            </div>
            {error && <p className="ed-error">{error}</p>}
            <div className="ed-actions">
                <button type="button" className="ed-ghost" onClick={onClose}>Annuler</button>
                <button type="button" className="ed-btn" disabled={submitting} onClick={submit}>
                    {submitting ? "Envoi…" : "Envoyer le lien"}
                </button>
            </div>
        </div>
    );
}

function ChangePasswordForm({onClose}: {onClose: () => void}) {
    const [current, setCurrent] = useState("");
    const [next, setNext] = useState("");
    const [confirm, setConfirm] = useState("");
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [done, setDone] = useState(false);

    async function submit() {
        if (!current) {
            setError("Mot de passe actuel requis");
            return;
        }
        if (next.length < 8) {
            setError("Le nouveau mot de passe doit faire au moins 8 caractères");
            return;
        }
        if (next !== confirm) {
            setError("La confirmation ne correspond pas");
            return;
        }
        setSubmitting(true);
        setError(null);
        try {
            await accountApi.changePassword(current, next);
            setDone(true);
        } catch (e) {
            setError(e instanceof ApiException ? e.message : "Échec de la modification.");
        } finally {
            setSubmitting(false);
        }
    }

    if (done) {
        return (
            <div className="ed-sub">
                <p className="ed-ok">Mot de passe modifié.</p>
                <button type="button" className="ed-ghost" onClick={onClose}>Fermer</button>
            </div>
        );
    }

    return (
        <div className="ed-sub">
            <div className="ed-field">
                <label htmlFor="ed-curpwd">Mot de passe actuel</label>
                <input
                    id="ed-curpwd"
                    className="ed-input"
                    type="password"
                    value={current}
                    onChange={(e) => setCurrent(e.target.value)}
                    autoComplete="current-password"
                />
            </div>
            <div className="ed-field">
                <label htmlFor="ed-newpwd">Nouveau mot de passe</label>
                <input
                    id="ed-newpwd"
                    className="ed-input"
                    type="password"
                    value={next}
                    onChange={(e) => setNext(e.target.value)}
                    placeholder="Au moins 8 caractères"
                    autoComplete="new-password"
                />
            </div>
            <div className="ed-field">
                <label htmlFor="ed-confpwd">Confirmer le nouveau</label>
                <input
                    id="ed-confpwd"
                    className="ed-input"
                    type="password"
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    autoComplete="new-password"
                />
            </div>
            {error && <p className="ed-error">{error}</p>}
            <div className="ed-actions">
                <button type="button" className="ed-ghost" onClick={onClose}>Annuler</button>
                <button type="button" className="ed-btn" disabled={submitting} onClick={submit}>
                    {submitting ? "Mise à jour…" : "Mettre à jour"}
                </button>
            </div>
        </div>
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
            <div className="cm-backdrop"/>
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
    gap: 14px; color: var(--color-muted); padding: 36px;
  }
  .pr-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pr { padding: 24px 36px 64px; max-width: 920px; margin: 0 auto; display: flex; flex-direction: column; gap: 14px; }
  @media (max-width: 760px) { .pr { padding: 20px 16px 56px; } }

  /* ---- Hero ---- */
  .pr-hero {
    display: grid; grid-template-columns: 1fr; gap: 20px;
    background: linear-gradient(135deg, var(--color-blue) 0%, #3355B5 100%);
    color: #fff; border-radius: 20px; padding: 24px; margin-bottom: 6px;
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

  .pr-id {
    background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.18);
    border-radius: 16px; padding: 16px; display: flex; align-items: center; gap: 14px;
  }
  .pr-avatar {
    width: 54px; height: 54px; border-radius: 14px; flex-shrink: 0;
    background: #fff; color: var(--color-ink);
    display: inline-flex; align-items: center; justify-content: center;
    font-family: var(--font-display); font-weight: 600; font-size: 21px;
  }
  .pr-id-body { flex: 1; min-width: 0; }
  .pr-id-name { font-family: var(--font-display); font-weight: 600; font-size: 18px; color: #fff;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .pr-id-email { font-size: 13px; color: rgba(255,255,255,0.8); margin-top: 1px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .pr-id-tag {
    display: inline-flex; align-items: center; gap: 5px; margin-top: 8px;
    background: rgba(255,255,255,0.16); color: #fff; border-radius: 999px;
    padding: 3px 10px; font-size: 11.5px; font-weight: 700; font-family: var(--font-mono);
    letter-spacing: 0.03em;
  }
  .pr-id-edit {
    flex-shrink: 0; align-self: flex-start;
    background: #fff; color: var(--color-blue); border: none; cursor: pointer;
    padding: 9px 16px; border-radius: 10px; font-family: var(--font-sans);
    font-size: 13px; font-weight: 700; transition: transform 0.15s, background 0.15s;
  }
  .pr-id-edit:hover { transform: translateY(-1px); background: #F1F5F9; }

  /* ---- Stats ---- */
  .pr-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 8px; }
  .pr-stat-card {
    background: #fff; border: 1px solid var(--color-line); border-radius: 16px;
    padding: 16px 14px; text-align: center; min-width: 0;
  }
  .pr-stat-value { font-family: var(--font-display); font-weight: 600; font-size: 22px; letter-spacing: -0.01em; line-height: 1.1; }
  .pr-stat-card.accent-blue .pr-stat-value { color: var(--color-blue); }
  .pr-stat-card.accent-red .pr-stat-value { color: var(--color-red); }
  .pr-stat-label {
    margin-top: 6px; font-family: var(--font-mono); font-size: 10.5px; letter-spacing: 0.06em;
    text-transform: uppercase; color: var(--color-muted);
  }
  /* Périmètre d'un niveau estimé partiel : une précision, pas une alerte —
     ni couleur d'avertissement, ni majuscules. Doit tenir sur une carte de
     grille à 3 colonnes dès 360 px. */
  .pr-stat-hint {
    margin-top: 4px; font-family: var(--font-sans); font-size: 11px; line-height: 1.3;
    color: var(--color-muted-2); overflow-wrap: anywhere;
  }

  /* ---- Section titles ---- */
  .pr-section-title { margin-top: 12px; }
  .pr-section-title h2 {
    font-family: var(--font-display); font-weight: 600; font-size: 17px;
    letter-spacing: -0.015em; color: var(--color-ink); margin: 0 0 4px;
  }

  /* ---- Line cards (pass / objectif) ---- */
  .pr-line-card {
    display: flex; align-items: center; gap: 14px; text-decoration: none;
    background: #fff; border: 1px solid var(--color-line); border-radius: 16px; padding: 16px;
    transition: border-color 0.18s, box-shadow 0.18s, transform 0.18s;
  }
  .pr-line-card:hover { transform: translateY(-2px); border-color: var(--color-blue);
    box-shadow: 0 16px 38px -24px rgba(30,58,140,0.3); }
  .pr-objectif { background: var(--color-paper); }
  .pr-line-icon {
    width: 44px; height: 44px; border-radius: 12px; flex-shrink: 0;
    display: inline-flex; align-items: center; justify-content: center; font-size: 20px;
    background: var(--color-blue-soft);
  }
  .pr-pass.accent-blue .pr-line-icon { background: var(--color-blue); }
  .pr-pass.accent-red .pr-line-icon { background: var(--color-red); }
  .pr-pass.accent-neutral .pr-line-icon { background: var(--color-paper-2); }
  .pr-line-icon.tone-objectif { background: #fff; border: 1px solid var(--color-line); }
  .pr-line-body { flex: 1; min-width: 0; }
  .pr-line-head { display: flex; align-items: center; gap: 8px; }
  .pr-line-head h3 { font-family: var(--font-sans); font-weight: 700; font-size: 15.5px; color: var(--color-ink); margin: 0;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .pr-line-body p { font-size: 12.5px; color: var(--color-muted); margin: 2px 0 0; line-height: 1.45;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .pr-pill {
    flex-shrink: 0; font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    letter-spacing: 0.05em; text-transform: uppercase; padding: 3px 8px; border-radius: 7px;
  }
  .pill-active { background: rgba(22,143,91,0.14); color: var(--color-green); }
  .pill-free { background: var(--color-paper-2); color: var(--color-muted); }
  .pr-chevron { flex-shrink: 0; font-size: 22px; line-height: 1; color: var(--color-muted-2); font-weight: 400; }

  /* ---- Row groups ---- */
  .pr-group { background: #fff; border: 1px solid var(--color-line); border-radius: 16px; overflow: hidden; }
  .pr-row {
    width: 100%; display: flex; align-items: center; gap: 14px; text-align: left;
    background: none; border: none; cursor: pointer; padding: 14px 16px; font-family: inherit;
    border-bottom: 1px solid var(--color-line-2); transition: background 0.15s;
  }
  .pr-group .pr-row:last-child { border-bottom: none; }
  .pr-row:hover { background: var(--color-blue-soft); }
  .pr-row-icon {
    width: 38px; height: 38px; border-radius: 11px; flex-shrink: 0;
    display: inline-flex; align-items: center; justify-content: center; font-size: 16px;
    background: var(--color-blue-soft); color: var(--color-blue);
  }
  .pr-row-icon.tone-danger { background: var(--color-red-light); color: var(--color-red); }
  .pr-row-icon.tone-muted { background: var(--color-paper-2); color: var(--color-muted); }
  .pr-row-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
  .pr-row-title { font-family: var(--font-sans); font-weight: 700; font-size: 14.5px; color: var(--color-ink); }
  .pr-row-danger .pr-row-title { color: var(--color-red); }
  .pr-row-sub { font-size: 12px; color: var(--color-muted);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .pr-row-danger:hover { background: var(--color-red-light); }

  .pr-version { text-align: center; font-family: var(--font-mono); font-size: 11px; color: var(--color-muted-2); margin-top: 12px; }

  @media (min-width: 760px) {
    .pr-hero { grid-template-columns: 1.4fr 1fr; align-items: center; padding: 30px; }
  }
  @media (max-width: 420px) {
    .pr-stats { gap: 8px; }
    .pr-stat-value { font-size: 19px; }
    .pr-id { flex-wrap: wrap; }
    .pr-id-edit { width: 100%; text-align: center; }
  }
`;

const editStyles = `
  .cm-sheet-wide { max-width: 520px; }
  .cm-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
  .cm-head .cm-title { margin: 0; }
  .cm-close {
    background: none; border: none; cursor: pointer; font-size: 16px; color: var(--color-muted);
    width: 32px; height: 32px; border-radius: 8px; flex-shrink: 0;
  }
  .cm-close:hover { background: var(--color-paper-2); color: var(--color-ink); }

  .ed-label {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.14em;
    text-transform: uppercase; color: var(--color-muted); margin: 18px 0 8px;
  }
  .ed-label:first-of-type { margin-top: 0; }
  .ed-block {
    background: var(--color-paper); border: 1px solid var(--color-line-2); border-radius: 14px; padding: 14px;
  }
  .ed-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  @media (max-width: 460px) { .ed-grid { grid-template-columns: 1fr; } }
  .ed-field { display: flex; flex-direction: column; gap: 6px; }
  .ed-field label {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em;
    text-transform: uppercase; color: var(--color-muted);
  }
  .ed-input {
    font-family: var(--font-sans); font-size: 16px; color: var(--color-ink);
    background: #fff; border: 1px solid var(--color-line); border-radius: 10px;
    padding: 10px 12px; width: 100%; transition: border-color 0.15s, box-shadow 0.15s;
  }
  .ed-input:focus { outline: none; border-color: var(--color-blue); box-shadow: 0 0 0 3px var(--color-blue-soft); }
  .ed-error { color: var(--color-red); font-size: 12.5px; margin: 10px 0 0; }
  .ed-ok { color: var(--color-green); font-size: 12.5px; margin: 10px 0 0; line-height: 1.45; }
  .ed-note { color: var(--color-muted); font-size: 12.5px; margin: 8px 0 0; line-height: 1.45; }
  .ed-btn {
    margin-top: 12px; background: var(--color-blue); color: #fff; border: none; cursor: pointer;
    padding: 11px 18px; border-radius: 10px; font-family: var(--font-sans); font-weight: 700; font-size: 13.5px;
    transition: background 0.15s;
  }
  .ed-btn:hover { background: var(--color-blue-dark); }
  .ed-btn:disabled { opacity: 0.6; cursor: default; }
  .ed-readline { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
  .ed-readval { font-family: var(--font-mono); font-size: 13px; font-weight: 600; color: var(--color-ink);
    word-break: break-all; }
  .ed-ghost {
    background: #fff; border: 1px solid var(--color-line); cursor: pointer; flex-shrink: 0;
    padding: 8px 14px; border-radius: 9px; font-family: var(--font-sans); font-weight: 700;
    font-size: 12.5px; color: var(--color-blue); transition: border-color 0.15s;
  }
  .ed-ghost:hover { border-color: var(--color-blue); }
  .ed-sub { margin-top: 14px; padding-top: 14px; border-top: 1px solid var(--color-line-2);
    display: flex; flex-direction: column; gap: 12px; }
  .ed-actions { display: flex; gap: 10px; justify-content: flex-end; }
`;

const modalStyles = `
  .cm { position: fixed; inset: 0; z-index: 100; display: flex; align-items: flex-end; justify-content: center; }
  .cm-backdrop { position: absolute; inset: 0; background: rgba(15, 24, 57, 0.55); backdrop-filter: blur(4px); animation: cm-fade 0.18s ease-out; }
  @keyframes cm-fade { from { opacity: 0; } to { opacity: 1; } }
  @keyframes cm-slide { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  .cm-sheet {
    position: relative; background: #fff; border-radius: 22px 22px 0 0; padding: 28px 28px 22px;
    width: 100%; max-width: 460px; animation: cm-slide 0.22s ease-out;
    box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
    max-height: 92vh; overflow-y: auto;
  }
  @media (min-width: 640px) { .cm { align-items: center; } .cm-sheet { border-radius: 18px; } }
  .cm-title { font-family: var(--font-display); font-weight: 600; font-size: 22px; letter-spacing: -0.02em; color: var(--color-ink); margin: 0 0 8px; }
  .cm-body { font-size: 14px; line-height: 1.55; color: var(--color-muted); margin: 0 0 22px; white-space: pre-line; }
  .cm-actions { display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap; }
  .cm-btn { padding: 10px 16px; border-radius: 10px; font-family: inherit; font-size: 13px; font-weight: 600; cursor: pointer; border: 1px solid transparent; transition: all 0.15s; }
  .cm-btn-ghost { background: #fff; border-color: var(--color-line); color: var(--color-ink); }
  .cm-btn-ghost:hover { border-color: var(--color-ink); }
  .cm-btn-primary { background: var(--color-blue); color: #fff; }
  .cm-btn-primary:hover { background: var(--color-blue-dark); }
  .cm-btn-danger { background: var(--color-red); color: #fff; }
  .cm-btn-danger:hover { background: var(--color-red-dark); }
  .cm-btn-neutral { background: var(--color-ink); color: #fff; }
  .cm-btn-neutral:hover { background: var(--color-ink-2); }
`;
