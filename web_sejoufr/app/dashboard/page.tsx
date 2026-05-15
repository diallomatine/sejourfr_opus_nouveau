"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth-context";

export default function DashboardPage() {
  const { user, status, logout } = useAuth();

  if (status === "loading") {
    return <DashboardSkeleton />;
  }
  if (!user) {
    return (
      <div className="dash-loading">
        <p>
          Session expirée. <Link href="/connexion">Se reconnecter</Link>
        </p>
      </div>
    );
  }

  return (
    <div className="dash">
      <Sidebar onLogout={logout} firstName={user.firstName} lastName={user.lastName} email={user.email} />

      <main className="dash-main">
        <header className="dash-head">
          <span className="eyebrow">Tableau de bord</span>
          <h1>
            Bonjour <em>{user.firstName ?? "à vous"}</em>.
          </h1>
          <p>
            Le web vous donne un aperçu et gère votre paiement. L&apos;entraînement
            quotidien se passe sur l&apos;app mobile.
          </p>
        </header>

        {/* Push app mobile, en first scroll position pour rester fidèle au discours produit */}
        <section className="dash-mobile">
          <div className="dash-mobile-copy">
            <span className="dash-mobile-tag">📱 Application mobile</span>
            <h2>
              Synchronisée avec votre compte <em>{user.email}</em>
            </h2>
            <p>
              Téléchargez l&apos;app, connectez-vous avec ce même email&nbsp;:
              statistiques, favoris, révision des erreurs et 10 questions par
              jour. Votre abonnement Premium suit automatiquement.
            </p>
            <div className="dash-mobile-cta">
              <a href="#" className="store-btn">
                <span className="se">Télécharger sur</span>
                <span className="sn">App Store</span>
              </a>
              <a href="#" className="store-btn">
                <span className="se">Disponible sur</span>
                <span className="sn">Google Play</span>
              </a>
            </div>
          </div>
          <div className="dash-mobile-visual" aria-hidden>
            <div className="dm-phone" />
          </div>
        </section>

        <div className="dash-grid">
          <Card
            title="Examens blancs"
            sub="40 examens publiés · 1 gratuit par module"
            body="Découvrez le format de l'examen civique et le TCF IRN en conditions réelles. Le résultat estime votre niveau."
            cta="Voir les 40 examens"
            href="/examens-blancs"
            tone="blue"
          />
          <Card
            title="Entraînement express"
            sub="20 questions max · 5 minutes"
            body="Quelques QCM ciblés sur un thème, avec correction immédiate. Au-delà, l'entraînement illimité passe sur l'app."
            cta="Lancer un entraînement"
            href="/entrainement"
            tone="green"
          />
          <Card
            title="Premium"
            sub="9,99 €/mois · sans engagement"
            body="Débloquez les 38 examens blancs payants et la synchro complète avec l'app mobile."
            cta="S'abonner"
            href="/paiement"
            tone="red"
          />
        </div>

        <section className="dash-account">
          <h3>Mon compte</h3>
          <Row label="Email" value={user.email} />
          <Row label="Nom" value={`${user.firstName ?? "—"} ${user.lastName ?? ""}`.trim()} />
          {user.targetProcedure && (
            <Row label="Parcours visé" value={procedureLabel(user.targetProcedure)} />
          )}
          <div className="dash-account-foot">
            <button type="button" className="link-danger" onClick={logout}>
              Se déconnecter
            </button>
          </div>
        </section>
      </main>

      <style>{dashStyles}</style>
    </div>
  );
}

// ============================================================================
// SIDEBAR
// ============================================================================
function Sidebar({
  firstName,
  lastName,
  email,
  onLogout,
}: {
  firstName: string | null;
  lastName: string | null;
  email: string;
  onLogout: () => void;
}) {
  const pathname = usePathname();
  const initial = firstName?.[0]?.toUpperCase() ?? email[0]!.toUpperCase();

  return (
    <aside className="dash-sidebar">
      <div className="dash-sidebar-brand">
        <span className="cocarde" aria-hidden />
        <div>
          <div className="brand-name">
            Sejour<span className="brand-fr">FR</span>
          </div>
          <div className="brand-tag">ESPACE PERSONNEL</div>
        </div>
      </div>

      <nav className="dash-nav">
        <span className="dash-nav-section">Pilotage</span>
        <SideLink href="/dashboard" active={pathname === "/dashboard"}>
          ↳ Tableau de bord
        </SideLink>

        <span className="dash-nav-section">Pratiquer</span>
        <SideLink href="/entrainement" active={pathname?.startsWith("/entrainement") ?? false}>
          ↳ Entraînement
        </SideLink>
        <SideLink href="/examens-blancs" active={pathname?.startsWith("/examens-blancs") ?? false}>
          ↳ Examens blancs
        </SideLink>

        <span className="dash-nav-section">Compte</span>
        <SideLink href="/paiement" active={pathname?.startsWith("/paiement") ?? false}>
          ↳ Abonnement
        </SideLink>
      </nav>

      <div className="dash-sidebar-foot">
        <div className="dash-user">
          <span className="dash-avatar">{initial}</span>
          <div className="dash-user-info">
            <div className="dash-user-name">
              {firstName ?? "Utilisateur"} {lastName ?? ""}
            </div>
            <div className="dash-user-email">{email}</div>
          </div>
        </div>
        <button type="button" className="dash-logout" onClick={onLogout}>
          Se déconnecter
        </button>
      </div>
    </aside>
  );
}

function SideLink({
  href,
  children,
  active,
}: {
  href: string;
  children: React.ReactNode;
  active: boolean;
}) {
  return (
    <Link href={href} className={`dash-nav-item ${active ? "is-active" : ""}`}>
      {children}
    </Link>
  );
}

// ============================================================================
// CARDS / UTILITIES
// ============================================================================
function Card({
  title,
  sub,
  body,
  cta,
  href,
  tone,
}: {
  title: string;
  sub: string;
  body: string;
  cta: string;
  href: string;
  tone: "blue" | "green" | "red";
}) {
  return (
    <Link href={href} className={`dash-card dash-card-${tone}`}>
      <span className="dash-card-sub">{sub}</span>
      <h3>{title}</h3>
      <p>{body}</p>
      <span className="dash-card-cta">{cta} →</span>
    </Link>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="dash-row">
      <span className="dash-row-l">{label}</span>
      <span className="dash-row-v">{value}</span>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="dash-loading">
      <p>Chargement…</p>
      <style>{`
        .dash-loading {
          padding: 120px 28px; text-align: center;
          color: var(--color-muted);
          font-family: var(--font-mono);
          font-size: 12px; letter-spacing: 0.1em;
        }
      `}</style>
    </div>
  );
}

function procedureLabel(p: string): string {
  switch (p) {
    case "CSP":
      return "Carte de séjour pluriannuelle (CSP)";
    case "CR":
      return "Carte de résident (CR)";
    case "NAT":
      return "Naturalisation (NAT)";
    default:
      return p;
  }
}

// ============================================================================
// STYLES
// ============================================================================
const dashStyles = `
  .dash {
    display: grid;
    grid-template-columns: 260px 1fr;
    min-height: calc(100vh - 110px);
    background: var(--color-paper);
  }

  /* --- sidebar --- */
  .dash-sidebar {
    background: #fff;
    border-right: 1px solid var(--color-line);
    padding: 24px 18px 18px;
    display: flex; flex-direction: column;
    position: sticky; top: 110px;
    height: calc(100vh - 110px);
    overflow-y: auto;
  }

  .dash-sidebar-brand {
    display: flex; gap: 12px; align-items: center;
    padding: 4px 8px 22px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 18px;
  }
  .cocarde {
    width: 28px; height: 28px;
    border-radius: 50%;
    background:
      radial-gradient(circle, var(--color-red) 0 22%, transparent 22%),
      radial-gradient(circle, #fff 0 55%, transparent 55%),
      var(--color-blue);
    flex-shrink: 0;
  }
  .brand-name {
    font-family: var(--font-display);
    font-weight: 600; font-size: 17px;
    color: var(--color-blue);
    letter-spacing: -0.015em;
    line-height: 1;
  }
  .brand-fr { color: var(--color-red); }
  .brand-tag {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    margin-top: 2px;
  }

  .dash-nav { flex: 1; display: flex; flex-direction: column; gap: 1px; }
  .dash-nav-section {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.16em;
    color: var(--color-muted-2);
    text-transform: uppercase;
    padding: 14px 12px 6px;
  }
  .dash-nav-item {
    text-decoration: none;
    display: block;
    padding: 9px 12px;
    border-radius: 8px;
    font-size: 13.5px;
    color: var(--color-ink-2);
    transition: background 0.1s;
  }
  .dash-nav-item:hover { background: var(--color-blue-soft); color: var(--color-blue); }
  .dash-nav-item.is-active {
    background: var(--color-blue-light);
    color: var(--color-blue);
    font-weight: 600;
  }

  .dash-sidebar-foot {
    border-top: 1px solid var(--color-line-2);
    padding-top: 16px;
    margin-top: 16px;
  }
  .dash-user {
    display: flex; align-items: center; gap: 10px;
    padding: 8px 6px 12px;
  }
  .dash-avatar {
    width: 36px; height: 36px;
    border-radius: 50%;
    background: var(--color-blue); color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 14px;
    flex-shrink: 0;
  }
  .dash-user-name {
    font-size: 13px; font-weight: 600; color: var(--color-ink);
    line-height: 1.2;
  }
  .dash-user-email {
    font-size: 11px; color: var(--color-muted);
    word-break: break-all;
    line-height: 1.3;
    margin-top: 2px;
  }
  .dash-logout {
    width: 100%;
    padding: 10px 12px;
    background: none;
    border: 1px solid var(--color-line);
    border-radius: 8px;
    font-family: var(--font-sans);
    font-size: 12.5px;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .dash-logout:hover {
    background: var(--color-red-light);
    color: var(--color-red);
    border-color: rgba(225, 55, 47, 0.3);
  }

  /* --- main --- */
  .dash-main {
    padding: 40px 48px 64px;
    max-width: 980px;
  }
  .dash-head { margin-bottom: 32px; }
  .dash-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 44px; line-height: 1.05; letter-spacing: -0.025em;
    margin: 12px 0 10px;
  }
  .dash-head h1 em { font-style: italic; color: var(--color-red); }
  .dash-head p {
    color: var(--color-muted); font-size: 16px; margin: 0;
    max-width: 540px;
    line-height: 1.55;
  }

  /* --- mobile push --- */
  .dash-mobile {
    background: linear-gradient(135deg, #0F1839, #1F2950);
    color: #fff;
    border-radius: 20px;
    padding: 36px 40px;
    margin-bottom: 28px;
    position: relative; overflow: hidden;
    display: grid; grid-template-columns: 1.4fr 0.6fr; gap: 32px;
    align-items: center;
  }
  .dash-mobile::before {
    content: ''; position: absolute;
    top: -100px; right: -100px;
    width: 320px; height: 320px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.25), transparent 70%);
    pointer-events: none;
  }
  .dash-mobile-copy { position: relative; }
  .dash-mobile-tag {
    display: inline-block;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: #ffb3b0; margin-bottom: 14px;
  }
  .dash-mobile h2 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 28px; line-height: 1.15; letter-spacing: -0.02em;
    margin: 0 0 12px; color: #fff;
  }
  .dash-mobile h2 em {
    font-style: italic;
    color: #ffb3b0;
    font-size: 0.7em;
    display: block;
    margin-top: 4px;
    font-family: var(--font-mono);
    letter-spacing: 0.08em;
    text-transform: lowercase;
  }
  .dash-mobile p {
    color: rgba(255, 255, 255, 0.78); font-size: 14px;
    line-height: 1.55; margin: 0 0 18px;
    max-width: 480px;
  }
  .dash-mobile-cta {
    display: flex; gap: 10px; flex-wrap: wrap;
  }
  .store-btn {
    display: flex; flex-direction: column;
    padding: 8px 18px;
    background: #fff; color: var(--color-ink);
    border-radius: 10px; text-decoration: none;
    min-width: 140px;
    transition: transform 0.15s;
  }
  .store-btn:hover { transform: translateY(-2px); }
  .se {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: var(--color-muted);
  }
  .sn {
    font-family: var(--font-sans); font-weight: 700; font-size: 16px;
    letter-spacing: -0.01em;
  }

  .dash-mobile-visual { display: flex; justify-content: center; position: relative; }
  .dm-phone {
    width: 100px; height: 180px;
    background: #fff;
    border-radius: 18px;
    border: 8px solid #15296B;
    position: relative;
    box-shadow: 0 20px 40px -20px rgba(0,0,0,0.4);
  }
  .dm-phone::before {
    content: '';
    position: absolute; top: 6px; left: 50%;
    transform: translateX(-50%);
    width: 36px; height: 4px;
    background: var(--color-ink);
    border-radius: 2px;
  }
  .dm-phone::after {
    content: '';
    position: absolute; inset: 14px 8px 8px;
    background:
      linear-gradient(180deg, var(--color-blue-light) 0%, transparent 50%),
      linear-gradient(180deg, transparent 50%, var(--color-red-light) 100%);
    border-radius: 6px;
  }

  /* --- grid cards --- */
  .dash-grid {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px;
    margin-bottom: 28px;
  }
  .dash-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 22px 22px 20px;
    text-decoration: none; color: inherit;
    display: flex; flex-direction: column; gap: 8px;
    transition: all 0.18s;
    position: relative; overflow: hidden;
  }
  .dash-card::before {
    content: '';
    position: absolute; top: 0; left: 0; right: 0;
    height: 3px;
  }
  .dash-card-blue::before { background: var(--color-blue); }
  .dash-card-green::before { background: var(--color-green); }
  .dash-card-red::before { background: var(--color-red); }
  .dash-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 20px 40px -22px rgba(15, 24, 57, 0.18);
  }
  .dash-card-sub {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted);
    margin-top: 2px;
  }
  .dash-card h3 {
    font-family: var(--font-display); font-weight: 500; font-size: 20px;
    letter-spacing: -0.015em; margin: 0;
    color: var(--color-ink);
  }
  .dash-card p {
    color: var(--color-ink-2); font-size: 13.5px;
    line-height: 1.5; margin: 0; flex: 1;
  }
  .dash-card-cta {
    margin-top: 6px;
    font-size: 13px; font-weight: 700;
  }
  .dash-card-blue .dash-card-cta { color: var(--color-blue); }
  .dash-card-green .dash-card-cta { color: var(--color-green); }
  .dash-card-red .dash-card-cta { color: var(--color-red); }

  /* --- account --- */
  .dash-account {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 24px 28px;
  }
  .dash-account h3 {
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted);
    font-weight: 600;
    margin: 0 0 14px;
  }
  .dash-row {
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid var(--color-line-2);
    font-size: 14px;
  }
  .dash-row:last-of-type { border-bottom: none; }
  .dash-row-l { color: var(--color-muted); }
  .dash-row-v {
    color: var(--color-ink); font-weight: 500;
    font-family: var(--font-mono); font-size: 13px;
  }
  .dash-account-foot {
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid var(--color-line-2);
    text-align: right;
  }
  .link-danger {
    background: none; border: none; padding: 0;
    color: var(--color-red); font-weight: 600; cursor: pointer;
    font-family: inherit; font-size: 13px;
  }
  .link-danger:hover { color: var(--color-red-dark); text-decoration: underline; }

  @media (max-width: 1024px) {
    .dash-grid { grid-template-columns: 1fr 1fr; }
    .dash-main { padding: 32px 24px 56px; }
  }
  @media (max-width: 760px) {
    .dash { grid-template-columns: 1fr; }
    .dash-sidebar {
      position: static; height: auto;
      flex-direction: row; align-items: center;
      padding: 16px 20px;
      border-right: none; border-bottom: 1px solid var(--color-line);
    }
    .dash-sidebar-brand { border-bottom: none; margin: 0; padding: 0; flex: 1; }
    .dash-nav { display: none; }
    .dash-sidebar-foot { display: flex; gap: 12px; align-items: center; padding: 0; margin: 0; border: none; }
    .dash-user { padding: 0; }
    .dash-logout { width: auto; padding: 8px 12px; }
    .dash-grid { grid-template-columns: 1fr; }
    .dash-mobile { grid-template-columns: 1fr; gap: 22px; padding: 26px 22px; }
    .dash-mobile-visual { display: none; }
    .dash-main { padding: 24px 18px 56px; }
    .dash-head h1 { font-size: 32px; }
  }
`;
