"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth-context";

export default function DashboardPage() {
  const { user, status } = useAuth();

  if (status === "loading") {
    return <DashboardSkeleton />;
  }
  if (!user) {
    // Le middleware redirige normalement vers /connexion, mais on garde un
    // fallback au cas où.
    return (
      <div className="dash-loading">
        <p>Session expirée. <Link href="/connexion">Se reconnecter</Link></p>
      </div>
    );
  }

  const procedure = user.targetProcedure;

  return (
    <main className="dash">
      <section className="dash-hero">
        <span className="eyebrow">Tableau de bord</span>
        <h1>
          Bonjour <em>{user.firstName ?? "à vous"}</em>.
        </h1>
        <p>
          {procedure
            ? `Parcours : ${procedureLabel(procedure)}.`
            : "Continuez votre préparation où que vous soyez."}
        </p>
      </section>

      <section className="dash-mobile">
        <div className="dash-mobile__copy">
          <span className="dash-mobile__tag">📱 Cœur du produit</span>
          <h2>
            L&apos;entraînement quotidien <em>se fait dans l&apos;app</em>.
          </h2>
          <p>
            Le site web est volontairement limité : il sert à découvrir SejourFR, passer un examen blanc gratuit par module et vous abonner.
            <strong> Tout le reste — questions illimitées, favoris, révision des erreurs, hors-ligne, rappels — se passe sur l&apos;application mobile.</strong>
          </p>
          <div className="dash-mobile__cta">
            <a href="#" className="store-btn ios">
              <span className="store-eyebrow">Télécharger sur</span>
              <span className="store-name">App Store</span>
            </a>
            <a href="#" className="store-btn android">
              <span className="store-eyebrow">Disponible sur</span>
              <span className="store-name">Google Play</span>
            </a>
          </div>
          <p className="dash-mobile__note">
            Connectez-vous sur l&apos;app avec <strong>{user.email}</strong> · votre abonnement et votre progression sont synchronisés.
          </p>
        </div>
      </section>

      <section className="dash-grid">
        <Card
          eyebrow="Disponible ici"
          title="Examens blancs"
          body="Un examen civique et un diagnostic TCF gratuits. 38 examens supplémentaires avec l'abonnement."
          cta="Voir les 40 examens"
          href="/examens-blancs"
        />
        <Card
          eyebrow="Abonnement"
          title="Premium"
          body="Débloquez tous les examens blancs et la synchro avec l'app. À partir de 9,99 €/mois, sans engagement."
          cta="Voir les formules"
          href="/paiement"
          accent
        />
      </section>

      <section className="dash-account">
        <h3>Mon compte</h3>
        <div className="dash-account__row">
          <span className="dash-account__label">Email</span>
          <span className="dash-account__val">{user.email}</span>
        </div>
        <div className="dash-account__row">
          <span className="dash-account__label">Nom</span>
          <span className="dash-account__val">
            {user.firstName} {user.lastName}
          </span>
        </div>
        {procedure && (
          <div className="dash-account__row">
            <span className="dash-account__label">Parcours</span>
            <span className="dash-account__val">{procedureLabel(procedure)}</span>
          </div>
        )}
      </section>

      <style>{dashStyles}</style>
    </main>
  );
}

function Card({
  eyebrow,
  title,
  body,
  cta,
  href,
  accent,
}: {
  eyebrow: string;
  title: string;
  body: string;
  cta: string;
  href: string;
  accent?: boolean;
}) {
  return (
    <Link href={href} className={`dash-card ${accent ? "accent" : ""}`}>
      <span className="dash-card__eyebrow">{eyebrow}</span>
      <h3>{title}</h3>
      <p>{body}</p>
      <span className="dash-card__cta">{cta} →</span>
    </Link>
  );
}

function DashboardSkeleton() {
  return (
    <main className="dash">
      <div className="dash-skeleton">Chargement…</div>
      <style>{`
        .dash-skeleton {
          padding: 120px 28px;
          text-align: center;
          color: var(--color-muted);
          font-family: var(--font-mono);
          font-size: 12px;
          letter-spacing: 0.1em;
        }
      `}</style>
    </main>
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

const dashStyles = `
  .dash {
    max-width: 960px;
    margin: 0 auto;
    padding: 48px 28px 80px;
  }

  .dash-hero { margin-bottom: 32px; }
  .dash-hero h1 {
    font-family: var(--font-display); font-weight: 500; font-size: 42px;
    line-height: 1.05; letter-spacing: -0.025em;
    margin: 12px 0 8px;
  }
  .dash-hero h1 em { font-style: italic; color: var(--color-red); }
  .dash-hero p {
    color: var(--color-muted); font-size: 16px;
    margin: 0;
  }

  .dash-mobile {
    background: var(--color-ink);
    color: #fff;
    border-radius: 18px;
    padding: 36px 40px;
    margin-bottom: 24px;
    position: relative; overflow: hidden;
  }
  .dash-mobile::before {
    content: ''; position: absolute;
    top: -100px; right: -100px;
    width: 320px; height: 320px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.25), transparent 70%);
    pointer-events: none;
  }
  .dash-mobile__copy { position: relative; }
  .dash-mobile__tag {
    display: inline-block;
    font-family: var(--font-mono); font-size: 10.5px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: #ffb3b0;
    margin-bottom: 14px;
  }
  .dash-mobile h2 {
    font-family: var(--font-display); font-weight: 500; font-size: 32px;
    line-height: 1.1; letter-spacing: -0.02em;
    margin: 0 0 12px; color: #fff;
  }
  .dash-mobile h2 em { font-style: italic; color: #ffb3b0; }
  .dash-mobile p {
    color: rgba(255, 255, 255, 0.78); font-size: 14.5px; line-height: 1.55;
    margin: 0 0 18px; max-width: 640px;
  }
  .dash-mobile p strong { color: #fff; font-weight: 600; }
  .dash-mobile__cta {
    display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 14px;
  }
  .store-btn {
    display: flex; flex-direction: column;
    padding: 8px 18px;
    background: #fff; color: var(--color-ink);
    border-radius: 10px; text-decoration: none;
    min-width: 150px;
    transition: transform 0.15s;
  }
  .store-btn:hover { transform: translateY(-2px); }
  .store-eyebrow {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: var(--color-muted);
  }
  .store-name {
    font-family: var(--font-sans); font-weight: 700; font-size: 16px;
    margin-top: 1px; letter-spacing: -0.01em;
  }
  .dash-mobile__note {
    font-size: 12px; color: rgba(255, 255, 255, 0.55);
    margin: 0;
  }
  .dash-mobile__note strong { color: rgba(255, 255, 255, 0.85); font-weight: 600; }

  .dash-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 16px;
    margin-bottom: 32px;
  }
  .dash-card {
    background: #fff; border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 24px 24px 22px;
    text-decoration: none; color: inherit;
    display: flex; flex-direction: column; gap: 10px;
    transition: all 0.18s;
  }
  .dash-card:hover {
    transform: translateY(-3px);
    border-color: var(--color-blue);
    box-shadow: 0 20px 40px -22px rgba(30, 58, 140, 0.18);
  }
  .dash-card.accent { border-color: var(--color-red); background: var(--color-red-light); }
  .dash-card.accent:hover { box-shadow: 0 20px 40px -22px rgba(225, 55, 47, 0.22); }
  .dash-card__eyebrow {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted);
  }
  .dash-card h3 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 22px; letter-spacing: -0.015em; margin: 0;
    color: var(--color-ink);
  }
  .dash-card p { color: var(--color-ink-2); font-size: 14px; line-height: 1.5; margin: 0; flex: 1; }
  .dash-card__cta {
    font-size: 13px; font-weight: 600; color: var(--color-blue);
    margin-top: 4px;
  }
  .dash-card.accent .dash-card__cta { color: var(--color-red-dark); }

  .dash-account {
    background: #fff; border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 24px 28px;
  }
  .dash-account h3 {
    font-family: var(--font-sans); font-weight: 700; font-size: 13px;
    letter-spacing: 0.08em; text-transform: uppercase;
    color: var(--color-muted);
    margin: 0 0 14px;
  }
  .dash-account__row {
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid var(--color-line-2);
    font-size: 14px;
  }
  .dash-account__row:last-child { border-bottom: none; }
  .dash-account__label { color: var(--color-muted); }
  .dash-account__val {
    color: var(--color-ink); font-weight: 500;
    font-family: var(--font-mono); font-size: 13px;
  }

  @media (max-width: 720px) {
    .dash { padding: 24px 16px 60px; }
    .dash-hero h1 { font-size: 32px; }
    .dash-mobile { padding: 26px 22px; }
    .dash-mobile h2 { font-size: 24px; }
    .dash-grid { grid-template-columns: 1fr; }
  }
`;
