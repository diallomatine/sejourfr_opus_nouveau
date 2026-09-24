"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import type {ReactNode} from "react";
import {
    ChartColumn,
    ChevronRight,
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
import {accountApi, ApiException, billingApi, dashboardApi} from "@/lib/api";
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
 *   - barre de titre « Mon profil » (le burger est celui du shell `(app)`)
 *   - hero bleu : avatar, nom, e-mail, démarche, bouton « Modifier »
 *   - 3 tuiles (maîtrise / série / niveau estimé + périmètre) issues de /api/me/dashboard
 *   - grille « Mon pass » (subscription-status) | « Mon objectif » (démarche)
 *   - « Mon compte » : Mes informations (modale), Ma progression, Aide & assistance
 *   - déconnexion + suppression de compte (DELETE /api/account)
 *
 * Tout ce qui est affiché est servi : aucun nombre n'est classé ici.
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
    const isLocal = !user.authProvider || user.authProvider === "LOCAL";

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
                {/* ---- Barre de titre : la case de gauche est celle du burger du shell ---- */}
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
                        <button
                            type="button"
                            className="pr-edit-btn"
                            onClick={() => setShowEdit(true)}
                            aria-label="Modifier mes informations"
                        >
                            <span className="pr-edit-txt">Modifier</span>
                            <Pencil className="pr-edit-ico" size={16} aria-hidden/>
                        </button>
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
                    <section className="pr-card">
                        <h2 className="pr-card-title">Mon pass</h2>
                        <Link href={passHref} className="pr-row">
                            <RowIcon tone={premium ? "green" : "muted"}>
                                <GraduationCap size={21}/>
                            </RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">
                                    {passName}
                                    <span className={`pr-status ${premium ? "is-active" : "is-free"}`}>
                                        {premium ? "Actif" : "Gratuit"}
                                    </span>
                                </span>
                                <span className="pr-row-sub">{passSub}</span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </Link>
                    </section>

                    {/* ---- Mon objectif ---- */}
                    <section className="pr-card">
                        <h2 className="pr-card-title">Mon objectif</h2>
                        <Link href={journeyTargetPathHref("/profil")} className="pr-row">
                            <RowIcon><Target size={21}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">
                                    {proc ? proc.title : "Choisir mon parcours"}
                                </span>
                                <span className="pr-row-sub">
                                    {proc
                                        ? `Niveau de français visé : ${niveauVise}`
                                        : "Définissez votre objectif administratif"}
                                </span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </Link>
                    </section>

                    {/* ---- Mon compte ---- */}
                    <section className="pr-card pr-full">
                        <h2 className="pr-card-title">Mon compte</h2>
                        <button type="button" className="pr-row" onClick={() => setShowEdit(true)}>
                            <RowIcon><PenLine size={20}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">Mes informations</span>
                                <span className="pr-row-sub">
                                    {isLocal
                                        ? "Nom, prénom, e-mail et mot de passe"
                                        : "Nom et prénom"}
                                </span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </button>
                        {/* Profil = « Ma progression » (D16) : l'entrée vers les
                            écrans de progression. Miroir de la ligne du Profil mobile. */}
                        <Link href="/progression/tcf" className="pr-row">
                            <RowIcon><ChartColumn size={20}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">Ma progression</span>
                                <span className="pr-row-sub">Maîtrise par parcours et niveau estimé</span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </Link>
                        <Link href="/contact" className="pr-row">
                            <RowIcon><CircleHelp size={20}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">Aide &amp; assistance</span>
                                <span className="pr-row-sub">Une question sur votre parcours ?</span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </Link>
                    </section>

                    {/* ---- Session ---- */}
                    <section className="pr-card pr-full">
                        <button type="button" className="pr-row" onClick={() => setShowLogoutConfirm(true)}>
                            <RowIcon><LogOut size={20}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">Se déconnecter</span>
                            </span>
                        </button>
                        <button
                            type="button"
                            className="pr-row pr-row-danger"
                            onClick={() => {
                                setDeleteError(null);
                                setShowDeleteConfirm(true);
                            }}
                        >
                            <RowIcon tone="red"><X size={21}/></RowIcon>
                            <span className="pr-row-main">
                                <span className="pr-row-title">Supprimer mon compte</span>
                            </span>
                            <ChevronRight className="pr-arrow" size={22} aria-hidden/>
                        </button>
                    </section>
                </div>

                <div className="pr-footer">SejourFR · v0.1.0</div>
            </div>

            {/* ---- MODALES ---- */}
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

function RowIcon({tone = "blue", children}: {tone?: "blue" | "green" | "red" | "muted"; children: ReactNode}) {
    return <span className={`pr-icon tone-${tone}`} aria-hidden>{children}</span>;
}

// ============================================================================
// MODALE « MES INFORMATIONS » (identité + e-mail + mot de passe)
// ============================================================================
type EditUser = {
    email: string;
    firstName: string;
    lastName: string;
    authProvider?: "LOCAL" | "GOOGLE" | "APPLE";
};

/**
 * Le bouton « Enregistrer » ne porte que l'identité (PATCH /api/me/profile).
 * L'e-mail et le mot de passe gardent leurs flux réels, qui exigent le mot de
 * passe actuel (changement d'e-mail = lien de vérification) : ils s'ouvrent sur
 * place, avec leur propre validation. Comptes Google/Apple : lecture seule.
 */
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
        <div className="pm" role="dialog" aria-modal="true" aria-labelledby="pm-title" onClick={onClose}>
            <section className="pm-sheet" onClick={(e) => e.stopPropagation()}>
                <div className="pm-top">
                    <h2 id="pm-title" className="pm-title">Mes informations</h2>
                    <button type="button" className="pm-close" onClick={onClose} aria-label="Fermer">
                        <X size={20} aria-hidden/>
                    </button>
                </div>

                <div className="pm-fields">
                    <div className="pm-field">
                        <label htmlFor="pm-fn">Prénom</label>
                        <input
                            id="pm-fn"
                            className="pm-input"
                            value={firstName}
                            onChange={(e) => setFirstName(e.target.value)}
                            autoComplete="given-name"
                        />
                    </div>
                    <div className="pm-field">
                        <label htmlFor="pm-ln">Nom</label>
                        <input
                            id="pm-ln"
                            className="pm-input"
                            value={lastName}
                            onChange={(e) => setLastName(e.target.value)}
                            autoComplete="family-name"
                        />
                    </div>

                    <div className="pm-field pm-span">
                        <span className="pm-label">Adresse e-mail</span>
                        <div className="pm-readline">
                            <span className="pm-input pm-readonly">{user.email}</span>
                            {isLocal && !emailOpen && (
                                <button type="button" className="pm-ghost" onClick={() => setEmailOpen(true)}>
                                    Changer
                                </button>
                            )}
                        </div>
                        {!isLocal && (
                            <p className="pm-note">
                                Connexion via {providerLabel} — l&apos;e-mail se gère côté {providerLabel}.
                            </p>
                        )}
                        {isLocal && emailOpen && (
                            <ChangeEmailForm currentEmail={user.email} onClose={() => setEmailOpen(false)}/>
                        )}
                    </div>

                    <div className="pm-field pm-span">
                        <span className="pm-label">Mot de passe</span>
                        <div className="pm-readline">
                            <span className="pm-input pm-readonly" aria-label="Mot de passe masqué">••••••••••</span>
                            {isLocal && !pwdOpen && (
                                <button type="button" className="pm-ghost" onClick={() => setPwdOpen(true)}>
                                    Modifier
                                </button>
                            )}
                        </div>
                        {!isLocal && (
                            <p className="pm-note">
                                Connexion via {providerLabel} — pas de mot de passe SejourFR.
                            </p>
                        )}
                        {isLocal && pwdOpen && <ChangePasswordForm onClose={() => setPwdOpen(false)}/>}
                    </div>
                </div>

                {identityError && <p className="pm-error">{identityError}</p>}
                {identityOk && <p className="pm-ok">Identité mise à jour.</p>}

                <div className="pm-actions">
                    <button type="button" className="pm-btn pm-btn-secondary" onClick={onClose}>
                        Annuler
                    </button>
                    <button
                        type="button"
                        className="pm-btn pm-btn-primary"
                        disabled={savingIdentity}
                        onClick={saveIdentity}
                    >
                        {savingIdentity ? "Enregistrement…" : "Enregistrer"}
                    </button>
                </div>
            </section>
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
            <div className="pm-sub">
                <p className="pm-ok">
                    Lien de vérification envoyé à {newEmail}. Cliquez dessus pour confirmer. Votre compte
                    reste accessible avec {currentEmail} en attendant.
                </p>
                <div className="pm-sub-actions">
                    <button type="button" className="pm-ghost" onClick={onClose}>Fermer</button>
                </div>
            </div>
        );
    }

    return (
        <div className="pm-sub">
            <div className="pm-field">
                <label htmlFor="pm-newmail">Nouvel e-mail</label>
                <input
                    id="pm-newmail"
                    className="pm-input"
                    type="email"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    placeholder="nouvel@email.fr"
                    autoComplete="email"
                />
            </div>
            <div className="pm-field">
                <label htmlFor="pm-mailpwd">Mot de passe actuel</label>
                <input
                    id="pm-mailpwd"
                    className="pm-input"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete="current-password"
                />
            </div>
            {error && <p className="pm-error">{error}</p>}
            <div className="pm-sub-actions">
                <button type="button" className="pm-ghost" onClick={onClose}>Annuler</button>
                <button type="button" className="pm-btn pm-btn-primary" disabled={submitting} onClick={submit}>
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
            <div className="pm-sub">
                <p className="pm-ok">Mot de passe modifié.</p>
                <div className="pm-sub-actions">
                    <button type="button" className="pm-ghost" onClick={onClose}>Fermer</button>
                </div>
            </div>
        );
    }

    return (
        <div className="pm-sub">
            <div className="pm-field">
                <label htmlFor="pm-curpwd">Mot de passe actuel</label>
                <input
                    id="pm-curpwd"
                    className="pm-input"
                    type="password"
                    value={current}
                    onChange={(e) => setCurrent(e.target.value)}
                    autoComplete="current-password"
                />
            </div>
            <div className="pm-field">
                <label htmlFor="pm-newpwd">Nouveau mot de passe</label>
                <input
                    id="pm-newpwd"
                    className="pm-input"
                    type="password"
                    value={next}
                    onChange={(e) => setNext(e.target.value)}
                    placeholder="Au moins 8 caractères"
                    autoComplete="new-password"
                />
            </div>
            <div className="pm-field">
                <label htmlFor="pm-confpwd">Confirmer le nouveau</label>
                <input
                    id="pm-confpwd"
                    className="pm-input"
                    type="password"
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    autoComplete="new-password"
                />
            </div>
            {error && <p className="pm-error">{error}</p>}
            <div className="pm-sub-actions">
                <button type="button" className="pm-ghost" onClick={onClose}>Annuler</button>
                <button type="button" className="pm-btn pm-btn-primary" disabled={submitting} onClick={submit}>
                    {submitting ? "Mise à jour…" : "Mettre à jour"}
                </button>
            </div>
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

function ProfilSkeleton() {
    return (
        <div className="pr-loading">
            <style>{`.pr-loading { min-height: calc(100vh - 80px); background: var(--color-paper); }`}</style>
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
// STYLES — géométrie de la maquette, couleurs et polices de l'application.
// Aucune valeur hexadécimale : tokens `var(--color-*)`, `white`, `color-mix()`.
// ============================================================================
const styles = `
  .pr {
    --pr-shadow: 0 10px 30px color-mix(in srgb, var(--color-ink) 7%, transparent);
    min-height: 100vh; padding: 24px 18px 48px;
  }
  .pr-shell { width: min(980px, 100%); margin: 0 auto; }

  /* ---- Barre de titre ---- */
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
    display: inline-flex; align-items: center; justify-content: center; transition: background 0.15s;
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

  /* ---- Grille de contenu ---- */
  .pr-grid { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 18px; }
  .pr-card {
    background: white; border: 1px solid var(--color-line); border-radius: 24px;
    box-shadow: var(--pr-shadow); overflow: hidden; min-width: 0;
  }
  .pr-full { grid-column: 1 / -1; }
  .pr-card-title {
    margin: 0; padding: 20px 22px 10px; font-family: var(--font-display); font-weight: 600;
    font-size: 18px; letter-spacing: -0.01em; color: var(--color-ink);
  }

  /* ---- Lignes ---- */
  .pr-row {
    width: 100%; display: flex; align-items: center; gap: 14px; padding: 17px 20px;
    border: 0; border-top: 1px solid var(--color-line); background: none; cursor: pointer;
    text-align: left; text-decoration: none; color: inherit; font-family: inherit; transition: background 0.15s;
  }
  .pr-card-title + .pr-row, .pr-card > .pr-row:first-child { border-top: 0; }
  .pr-row:hover { background: var(--color-blue-soft); }
  .pr-row:focus-visible { outline: 2px solid var(--color-blue); outline-offset: -2px; }
  .pr-icon {
    width: 48px; height: 48px; flex: 0 0 48px; border-radius: 15px; display: grid; place-items: center;
  }
  .pr-icon.tone-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .pr-icon.tone-green { background: var(--color-green-light); color: var(--color-green); }
  .pr-icon.tone-red { background: var(--color-red-light); color: var(--color-red); }
  .pr-icon.tone-muted { background: var(--color-paper-2); color: var(--color-muted); }
  .pr-row-main { min-width: 0; flex: 1; display: flex; flex-direction: column; }
  .pr-row-title { font-weight: 800; font-size: 16px; line-height: 1.2; color: var(--color-ink); }
  .pr-row-sub {
    margin-top: 4px; font-size: 13px; line-height: 1.35; color: var(--color-muted);
    overflow: hidden; text-overflow: ellipsis;
  }
  .pr-arrow { flex-shrink: 0; color: var(--color-muted-2); }
  .pr-status {
    display: inline-flex; align-items: center; margin-left: 8px; padding: 5px 9px; border-radius: 999px;
    font-family: var(--font-mono); font-size: 11px; font-weight: 800; letter-spacing: 0.08em;
    text-transform: uppercase; vertical-align: 2px;
  }
  .pr-status.is-active { background: var(--color-green-light); color: var(--color-green); }
  .pr-status.is-free { background: var(--color-paper-2); color: var(--color-muted); }
  .pr-row-danger .pr-row-title { color: var(--color-red); }
  .pr-row-danger:hover { background: var(--color-red-light); }

  .pr-footer {
    margin-top: 28px; text-align: center; font-family: var(--font-mono); font-size: 12px;
    letter-spacing: 0.08em; color: var(--color-muted-2);
  }

  /* ---- Modales : feuille posée en bas (maquette) ---- */
  .pm {
    position: fixed; inset: 0; z-index: 100; display: flex; align-items: flex-end; justify-content: center;
    padding: 18px; background: color-mix(in srgb, var(--color-ink) 42%, transparent);
    -webkit-backdrop-filter: blur(4px); backdrop-filter: blur(4px); animation: pm-fade 0.18s ease-out;
  }
  @keyframes pm-fade { from { opacity: 0; } to { opacity: 1; } }
  @keyframes pm-slide { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  .pm-sheet {
    width: min(620px, 100%); max-height: calc(100vh - 36px); overflow-y: auto; background: white;
    border-radius: 28px 28px 22px 22px; padding: 24px; animation: pm-slide 0.22s ease-out;
    box-shadow: 0 24px 60px color-mix(in srgb, var(--color-ink) 22%, transparent);
  }
  .pm-sheet-narrow { width: min(480px, 100%); }
  .pm-top { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 18px; }
  .pm-title {
    margin: 0; font-family: var(--font-display); font-weight: 600; font-size: 25px;
    letter-spacing: -0.02em; color: var(--color-ink);
  }
  .pm-sheet-narrow .pm-title { font-size: 22px; margin-bottom: 8px; }
  .pm-close {
    flex-shrink: 0; width: 40px; height: 40px; border: 0; border-radius: 12px; cursor: pointer;
    background: var(--color-paper); color: var(--color-muted); display: grid; place-items: center;
  }
  .pm-close:hover { background: var(--color-paper-2); color: var(--color-ink); }
  .pm-body { margin: 0 0 22px; font-size: 14px; line-height: 1.55; color: var(--color-muted); white-space: pre-line; }

  .pm-fields { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 12px; }
  .pm-span { grid-column: 1 / -1; }
  .pm-field { display: flex; flex-direction: column; min-width: 0; }
  .pm-field label, .pm-label {
    display: block; margin-bottom: 7px; font-family: var(--font-mono); font-size: 11px; font-weight: 800;
    letter-spacing: 0.12em; text-transform: uppercase; color: var(--color-muted);
  }
  .pm-input {
    width: 100%; min-width: 0; border: 1px solid var(--color-line); background: var(--color-paper);
    color: var(--color-ink); border-radius: 14px; padding: 14px 15px; font-family: var(--font-sans);
    font-size: 16px; outline: none; transition: border-color 0.15s, box-shadow 0.15s;
  }
  .pm-input:focus { border-color: var(--color-blue); box-shadow: 0 0 0 3px var(--color-blue-light); }
  .pm-readline { display: flex; align-items: center; gap: 10px; }
  .pm-readonly { flex: 1; color: var(--color-muted); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .pm-note { margin: 8px 0 0; font-size: 12.5px; line-height: 1.45; color: var(--color-muted); }
  .pm-sub {
    margin-top: 12px; padding: 14px; border: 1px solid var(--color-line-2); border-radius: 14px;
    background: var(--color-blue-soft); display: flex; flex-direction: column; gap: 12px;
  }
  .pm-sub-actions { display: flex; justify-content: flex-end; gap: 10px; flex-wrap: wrap; }
  .pm-error { margin: 12px 0 0; font-size: 12.5px; color: var(--color-red); }
  .pm-ok { margin: 12px 0 0; font-size: 12.5px; line-height: 1.45; color: var(--color-green); }
  .pm-sub .pm-error, .pm-sub .pm-ok { margin: 0; }

  .pm-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 18px; flex-wrap: wrap; }
  .pm-btn {
    border-radius: 13px; padding: 12px 16px; font-family: var(--font-sans); font-size: 14px; font-weight: 800;
    cursor: pointer; border: 1px solid transparent; transition: background 0.15s, border-color 0.15s;
  }
  .pm-btn:disabled { opacity: 0.6; cursor: default; }
  .pm-btn-secondary { background: white; border-color: var(--color-line); color: var(--color-ink); }
  .pm-btn-secondary:hover { border-color: var(--color-ink); }
  .pm-btn-primary { background: var(--color-blue); color: white; }
  .pm-btn-primary:hover:not(:disabled) { background: var(--color-blue-dark); }
  .pm-btn-danger { background: var(--color-red); color: white; }
  .pm-btn-danger:hover { background: var(--color-red-dark); }
  .pm-btn-neutral { background: var(--color-ink); color: white; }
  .pm-btn-neutral:hover { background: var(--color-ink-2); }
  .pm-ghost {
    flex-shrink: 0; cursor: pointer; background: white; border: 1px solid var(--color-line);
    border-radius: 12px; padding: 10px 14px; font-family: var(--font-sans); font-size: 13px; font-weight: 700;
    color: var(--color-blue); transition: border-color 0.15s;
  }
  .pm-ghost:hover { border-color: var(--color-blue); }

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
    .pr-card { border-radius: 20px; }
    .pr-card-title { padding: 18px 18px 9px; font-size: 17px; }
    .pr-row { padding: 15px 16px; }
    .pr-icon { width: 44px; height: 44px; flex-basis: 44px; border-radius: 14px; }
    .pr-row-title { font-size: 15px; }
    .pr-row-sub { font-size: 12px; }
    .pm-fields { grid-template-columns: minmax(0, 1fr); }
    .pm-span { grid-column: auto; }
    .pm-sheet { padding: 20px; }
  }

  /* ---- ≤ 430 px ---- */
  @media (max-width: 430px) {
    .pr-topbar { margin-bottom: 14px; }
    .pr-page-title { display: none; }
    .pr-hero-head { display: grid; grid-template-columns: 60px minmax(0, 1fr) auto; gap: 12px; }
    .pr-identity h1 { font-size: 22px; }
    .pr-edit-btn { width: 38px; height: 38px; padding: 0; border-radius: 12px; }
    .pr-edit-txt { display: none; }
    .pr-edit-ico { display: block; }
  }
`;
