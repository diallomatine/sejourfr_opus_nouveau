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
    PenLine,
    Target,
    X,
} from "lucide-react";
import {
    Badge,
    BlockError,
    BlockSkeleton,
    InfoCard,
    ObjectiveRow,
    ObjectivesCard,
    Pad,
    PageHead,
    Section,
    SejourApp,
    Split,
    TipCard,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {IconMap, IconShield, IconSparkle} from "@/app/_components/shell/ShellIcons";
import {useAuth} from "@/lib/auth-context";
import {journeyTargetPathHref} from "@/lib/journey";
import {accountApi, billingApi, dashboardApi} from "@/lib/api";
import {AIDE_HREF} from "@/lib/aide";
import {passAccessName} from "@/lib/passes";
import {FAVORIS_HREF, FAVORIS_ROW_SUB, FAVORIS_TITLE} from "@/lib/favoris";
import {
    COMPTE_INFORMATIONS_HREF,
    COMPTE_NOTIF_ROW_SUB,
    COMPTE_NOTIF_ROW_TITLE,
    COMPTE_NOTIFICATIONS_HREF,
    COMPTE_PROFIL_HREF,
    compteIsLocal,
} from "@/lib/compte";
import {
    ACCUEIL_BLOCK_ERROR,
    ACCUEIL_CIVIQUE_LABEL,
    ACCUEIL_CIVIQUE_OBJECTIF_TITRE,
    ACCUEIL_RETRY,
    ACCUEIL_TCF_LABEL,
    accueilPourcentage,
    accueilTcfObjectifTitre,
    accueilTcfProgression,
} from "@/lib/accueil";
import {progressionHref} from "@/lib/progression";
import {avancementSeriesCivique} from "@/lib/reviser";
import {CompteGate, CompteLoading} from "../../_components/compte/CompteParts";
import {estimatedTcfLevelScopeLabel, niveauCecrlShort} from "@/lib/types";
import type {
    DashboardSummaryResponse,
    SubscriptionStatusResponse,
    TargetProcedure,
} from "@/lib/types";

/**
 * **Le Profil web** — Navigation v2, phase 4 (maquette
 * `docs/redesign/sejourfr-navigation-web.html`, `#profil`), en parité de
 * contenu avec l'onglet Profil mobile (`profile_screen.dart`).
 *
 * `Split` : à gauche la carte profil (initiales, nom, e-mail, « Objectif :
 * {démarche} », pastilles pass + démarche, « Modifier »), les 3 tuiles
 * (gardées), « Mon objectif » (gardé), « Mon compte » en `InfoCard` (Mon pass,
 * Mes informations, Notifications, Mes favoris, Aide), la session
 * (déconnexion, suppression) et la version ; à droite le « Résumé de
 * préparation » (`ObjectivesCard`) et « Votre semaine » (`TipCard`).
 *
 * 🛑 Tout est servi : aucun nombre n'est classé ici. Le niveau cible est
 * `AuthenticatedUser.targetLevel` (X13), seule source. « Membre depuis » :
 * non servi ⇒ masqué. Le mot « abonnement » n'apparaît jamais (« Mon pass »).
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
    const [dashboardError, setDashboardError] = useState(false);
    const [dashboardTentative, setDashboardTentative] = useState(0);
    const [subscription, setSubscription] = useState<SubscriptionStatusResponse | null>(null);

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        void dashboardApi.summaryCached().then((d) => {
            if (!cancelled) setDashboard(d);
        }).catch(() => {
            if (!cancelled) setDashboardError(true);
        });
        return () => {
            cancelled = true;
        };
    }, [status, dashboardTentative]);

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
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
    // X13 : le palier VISÉ est servi par `/api/auth/me` (plancher appliqué
    // serveur) — aucun recalcul ici.
    const cible = user.targetLevel ?? null;
    const isLocal = compteIsLocal(user.authProvider);

    // ── Tuile « Niveau estimé » (parité mobile ; Maîtrise et Série retirées
    //    le 2026-10-03, demande du propriétaire) ───────────────────────────
    // Forme courte partagée (« <A1 » et pas « A1 »), jamais une table locale.
    const levelValue = niveauCecrlShort(dashboard?.estimatedTcfLevel ?? null);
    // Périmètre SERVI (épreuves comptées / attendues), une seule chaîne partagée.
    const levelScope = estimatedTcfLevelScopeLabel(dashboard);

    // ── Mon pass ──────────────────────────────────────────────────────────
    const premium = subscription?.isPremium ?? user.isPremium ?? false;
    const access = subscription?.moduleAccess;
    const passName = passAccessName(premium, access === "INTEGRAL");
    const expiresAt = subscription?.expiresAt ?? user.premiumEndsAt ?? null;
    const passDetail = !premium
        ? "Accès limité — débloquez tout SejourFR"
        : expiresAt
            ? `Valable jusqu'au ${formatDate(expiresAt)}`
            : "Accès actif";
    // « paiement unique, aucun renouvellement » : seulement sur un pass actif
    // servi `oneTime` (R6 — un pass n'est jamais un abonnement).
    const passMeta = [
        passName,
        premium && subscription?.oneTime ? "paiement unique, aucun renouvellement" : null,
        passDetail,
    ].filter(Boolean).join(" · ");
    const passHref = premium ? "/profil/abonnement" : "/paiement";

    return (
        <SejourApp className={sejourStyles.home}>
            <Pad>
                <PageHead title="Profil" subtitle="Votre compte, votre objectif et vos réglages."/>
            </Pad>

            <div className={sejourStyles.pageBody}>
                <Split
                    main={(
                        <>
                            {/* ---- Carte profil ---- */}
                            <Pad>
                                <section className="pr-card">
                                    <span className="pr-avatar" aria-hidden>{initials}</span>
                                    <div className="pr-identity">
                                        <h2>{fullName}</h2>
                                        <p className="pr-email">{user.email}</p>
                                        {proc && <p className="pr-objectif">Objectif : {proc.title}</p>}
                                        <div className="pr-badges">
                                            <Badge tone={premium ? "success" : "neutral"}>{passName}</Badge>
                                            {proc && <Badge module="tcf">{proc.short}</Badge>}
                                        </div>
                                    </div>
                                    <Link
                                        href={COMPTE_INFORMATIONS_HREF}
                                        className="pr-edit-btn"
                                        aria-label="Modifier mes informations"
                                    >
                                        Modifier
                                    </Link>
                                </section>

                                <div className="pr-stats">
                                    <StatTile label="Niveau estimé" value={levelValue} meta={levelScope}/>
                                </div>
                            </Pad>

                            {/* ---- Mon objectif (gardé) ---- */}
                            <Section title="Mon objectif">
                                <Pad>
                                    <InfoCard
                                        icon={<Target/>}
                                        title={proc ? proc.title : "Choisir mon parcours"}
                                        meta={proc
                                            ? (cible ? `Niveau de français visé : ${cible}` : null)
                                            : "Définissez votre objectif administratif"}
                                        trailing="chevron"
                                        href={journeyTargetPathHref("/profil")}
                                    />
                                </Pad>
                            </Section>

                            {/* ---- Mon compte ---- */}
                            <Section title="Mon compte">
                                <Pad>
                                    <div className="pr-list">
                                        <InfoCard
                                            icon={<GraduationCap/>}
                                            title="Mon pass"
                                            meta={passMeta}
                                            trailing={(
                                                <Badge tone={premium ? "success" : "neutral"}>
                                                    {premium ? "Actif" : "Gratuit"}
                                                </Badge>
                                            )}
                                            href={passHref}
                                        />
                                        <InfoCard
                                            icon={<PenLine/>}
                                            title="Mes informations"
                                            meta={isLocal ? "Nom, prénom, e-mail et mot de passe" : "Nom et prénom"}
                                            trailing="chevron"
                                            href={COMPTE_INFORMATIONS_HREF}
                                        />
                                        <InfoCard
                                            icon={<Bell/>}
                                            title={COMPTE_NOTIF_ROW_TITLE}
                                            meta={COMPTE_NOTIF_ROW_SUB}
                                            trailing="chevron"
                                            href={COMPTE_NOTIFICATIONS_HREF}
                                        />
                                        {/* « Ma progression » n'est PAS ici sur le web : elle vit dans
                                            la barre latérale (une entrée par module). */}
                                        <InfoCard
                                            icon={<Bookmark/>}
                                            title={FAVORIS_TITLE}
                                            meta={FAVORIS_ROW_SUB}
                                            trailing="chevron"
                                            href={FAVORIS_HREF}
                                        />
                                        <InfoCard
                                            icon={<CircleHelp/>}
                                            title="Aide"
                                            meta="Questions fréquentes et contact"
                                            trailing="chevron"
                                            href={AIDE_HREF}
                                        />
                                    </div>
                                </Pad>
                            </Section>

                            {/* ---- Session ---- */}
                            <Pad>
                                <div className="pr-list pr-session">
                                    <InfoCard
                                        icon={<LogOut/>}
                                        title="Se déconnecter"
                                        onClick={() => setShowLogoutConfirm(true)}
                                    />
                                    <InfoCard
                                        module="civique"
                                        icon={<X/>}
                                        title="Supprimer mon compte"
                                        trailing="chevron"
                                        onClick={() => {
                                            setDeleteError(null);
                                            setShowDeleteConfirm(true);
                                        }}
                                    />
                                </div>
                                <div className="pr-footer">SejourFR · v{process.env.NEXT_PUBLIC_APP_VERSION}</div>
                            </Pad>
                        </>
                    )}
                    side={(
                        <Pad>
                            <div className={sejourStyles.splitSide}>
                                <ResumePreparation
                                    dashboard={dashboard}
                                    error={dashboardError}
                                    onRetry={() => {
                                        setDashboardError(false);
                                        setDashboardTentative((n) => n + 1);
                                    }}
                                    cible={cible}
                                />
                                {dashboard ? (
                                    <TipCard
                                        icon={<IconSparkle/>}
                                        label="Votre semaine"
                                        text={semaineTexte(dashboard.currentStreakDays)}
                                    />
                                ) : null}
                            </div>
                        </Pad>
                    )}
                />
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
        </SejourApp>
    );
}

// ============================================================================
// BRIQUES
// ============================================================================

/**
 * **« Résumé de préparation »** — les deux objectifs, comme « Mes objectifs »
 * de l'Accueil : TCF `{actuel|—} → {cible}` (niveau estimé servi, cible
 * `targetLevel`), civique `{pct} %` par `avancementSeriesCivique`, la fonction
 * unique. Chaque ligne ouvre la Progression du module.
 */
function ResumePreparation({dashboard, error, onRetry, cible}: {
    dashboard: DashboardSummaryResponse | null;
    error: boolean;
    onRetry: () => void;
    cible: Parameters<typeof accueilTcfObjectifTitre>[0];
}) {
    if (!dashboard) {
        return error
            ? <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={onRetry}/>
            : <BlockSkeleton height={200} radius={24}/>;
    }
    const civique = avancementSeriesCivique(dashboard.civique);
    return (
        <ObjectivesCard label="Résumé de préparation">
            <ObjectiveRow
                module="tcf"
                icon={<IconMap/>}
                label={ACCUEIL_TCF_LABEL}
                title={accueilTcfObjectifTitre(cible)}
                value={accueilTcfProgression(dashboard.estimatedTcfLevel, cible)}
                href={progressionHref("TCF")}
            />
            <ObjectiveRow
                module="civique"
                icon={<IconShield/>}
                label={ACCUEIL_CIVIQUE_LABEL}
                title={ACCUEIL_CIVIQUE_OBJECTIF_TITRE}
                value={accueilPourcentage(civique.pourcentage)}
                href={progressionHref("CIVIQUE")}
            />
        </ObjectivesCard>
    );
}

/**
 * « Votre semaine » : la série de jours servie (`currentStreakDays`) et le
 * texte éditorial de la maquette ; 0 jour ⇒ une invitation, jamais « 0 jour
 * d'activité de suite ».
 */
function semaineTexte(jours: number): string {
    if (jours <= 0) {
        return "Une série aujourd'hui lance votre semaine : la régularité est le meilleur prédicteur de réussite aux deux examens.";
    }
    const mot = jours > 1 ? "jours" : "jour";
    return `${jours} ${mot} d'activité de suite. Continuez ainsi : la régularité est le meilleur prédicteur de réussite aux deux examens.`;
}

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
// STYLES — géométrie de la maquette (`.profile-card`), couleurs et polices de
// l'application. Aucune valeur hexadécimale : tokens `var(--color-*)`,
// `color-mix()`.
// ============================================================================
const styles = `
  /* ---- Carte profil (\`.card.profile-card\`) ---- */
  .pr-card {
    display: flex; align-items: center; gap: 18px; min-width: 0;
    padding: 24px; border: 1px solid var(--color-line); border-radius: var(--sf-radius-4xl);
    background: var(--color-white); box-shadow: var(--sf-shadow-card-sm);
  }
  .pr-avatar {
    width: 74px; height: 74px; flex: 0 0 74px; border-radius: var(--sf-radius-3xl);
    display: grid; place-items: center; color: var(--color-white);
    background: var(--gradient-module-tcf); box-shadow: var(--sf-shadow-module-tcf);
    font-family: var(--font-sans); font-size: 25px; font-weight: 800; letter-spacing: -0.02em;
  }
  .pr-identity { min-width: 0; flex: 1; }
  .pr-identity h2 {
    margin: 0 0 4px; font-family: var(--font-sans); font-size: 20px; font-weight: 800;
    letter-spacing: -0.02em; line-height: 1.2; color: var(--color-ink); overflow-wrap: anywhere;
  }
  .pr-email, .pr-objectif {
    margin: 0; font-size: 14px; line-height: 1.45; color: var(--color-muted);
    overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
  }
  .pr-badges { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
  .pr-edit-btn {
    flex-shrink: 0; display: inline-flex; align-items: center; justify-content: center;
    height: 44px; padding: 0 18px; border-radius: var(--sf-radius-md);
    background: var(--color-paper-2); color: var(--color-ink); text-decoration: none;
    font-family: var(--font-sans); font-size: 14px; font-weight: 700; transition: background 0.15s;
  }
  .pr-edit-btn:hover { background: var(--color-line); }
  .pr-edit-btn:focus-visible { outline: 2px solid var(--color-module-tcf); outline-offset: 2px; }

  /* ---- Tuiles (gardées) ---- */
  .pr-stats { display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; margin-top: 14px; }
  .pr-stat {
    background: var(--color-white); border: 1px solid var(--color-line); border-radius: var(--sf-radius-2xl);
    padding: 17px 15px; min-width: 0; box-shadow: var(--sf-shadow-card-sm);
  }
  .pr-stat-value { font-family: var(--font-sans); font-size: 24px; font-weight: 800; line-height: 1.15; }
  .pr-stat-value.tone-blue { color: var(--color-module-tcf); }
  .pr-stat-value.tone-red { color: var(--color-red); }
  .pr-stat-label {
    margin-top: 4px; font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.12em;
    text-transform: uppercase; color: var(--color-muted);
  }
  .pr-stat-meta { margin-top: 3px; font-size: 12px; line-height: 1.3; color: var(--color-muted-2); overflow-wrap: anywhere; }

  /* ---- Listes de lignes (\`.stack\`) ---- */
  .pr-list { display: grid; gap: 12px; }
  .pr-session { margin-top: 18px; }

  .pr-footer {
    margin-top: 24px; text-align: center; font-family: var(--font-mono); font-size: 12px;
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
  /* ---- ≤ 760 px ---- */
  @media (max-width: 760px) {
    .pr-card { padding: 18px; gap: 14px; align-items: flex-start; }
    .pr-avatar { width: 60px; height: 60px; flex-basis: 60px; font-size: 21px; }
    .pr-stats { gap: 8px; }
    .pr-stat { padding: 14px 10px; }
    .pr-stat-value { font-size: 21px; }
    .pr-stat-label { font-size: 9px; letter-spacing: 0.1em; }
    .pr-stat-meta { font-size: 10px; }
    .pm-sheet { padding: 20px; }
  }

  /* ---- ≤ 430 px : « Modifier » passe sous l'identité ---- */
  @media (max-width: 430px) {
    .pr-card { flex-wrap: wrap; }
    .pr-identity { flex-basis: calc(100% - 74px); }
    .pr-edit-btn { width: 100%; }
  }
`;
