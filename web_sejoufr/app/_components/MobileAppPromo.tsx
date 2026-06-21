"use client";

import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import {
  Bell,
  RefreshCw,
  Smartphone,
  Sparkles,
  X,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { shouldHideGlobalChrome } from "@/lib/chrome-routes";

/**
 * Bandeau global discret, dismissible (localStorage). Le web a désormais la
 * parité fonctionnelle avec l'app : l'app est un compagnon pour pratiquer
 * partout (transports, pauses), pas un remplaçant du site.
 */
const BANNER_DISMISS_KEY = "sejourfr.mobileBannerDismissed";

export function MobileAppBanner() {
  const pathname = usePathname();
  const { status, user } = useAuth();
  // Initialement caché (SSR safe). Au mount, on bascule à visible si
  // l'utilisateur n'a pas déjà fermé le bandeau.
  const [hidden, setHidden] = useState(true);

  useEffect(() => {
    if (typeof window === "undefined") return;
    if (localStorage.getItem(BANNER_DISMISS_KEY) !== "1") {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setHidden(false);
    }
  }, []);

  // Même règle que SiteHeader/Footer : pas de chrome marketing dans le
  // shell applicatif connecté.
  const isAuth = status === "authenticated" && user !== null;
  if (shouldHideGlobalChrome(pathname, isAuth)) return null;

  if (hidden) return null;

  const dismiss = () => {
    if (typeof window !== "undefined") {
      localStorage.setItem(BANNER_DISMISS_KEY, "1");
    }
    setHidden(true);
  };

  return (
    <div className="mab" role="region" aria-label="App mobile disponible">
      <div className="mab__inner">
        <span className="mab__pill" aria-hidden>
          NOUVEAU
        </span>
        <span className="mab__text">
          L&apos;app mobile est dispo — révisez aussi dans les transports, en
          pause, partout.
        </span>
        <a href="#telecharger" className="mab__cta">
          Télécharger
        </a>
        <button
          type="button"
          className="mab__close"
          onClick={dismiss}
          aria-label="Masquer le bandeau"
        >
          <X size={14} />
        </button>
      </div>
      <style>{`
        .mab {
          background: linear-gradient(90deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
        }
        .mab__inner {
          max-width: 1180px;
          margin: 0 auto;
          padding: 9px 28px;
          display: flex; align-items: center; gap: 14px;
          flex-wrap: nowrap;
          font-size: 13px;
        }
        .mab__pill {
          font-family: var(--font-mono);
          font-size: 9.5px;
          letter-spacing: 0.18em;
          font-weight: 600;
          background: var(--color-red);
          color: #fff;
          padding: 3px 8px;
          border-radius: 100px;
          flex-shrink: 0;
        }
        .mab__text {
          flex: 1;
          color: rgba(255, 255, 255, 0.92);
          min-width: 0;
        }
        .mab__cta {
          color: #fff;
          font-weight: 600;
          text-decoration: none;
          white-space: nowrap;
          border-bottom: 1px solid rgba(255, 255, 255, 0.5);
          padding-bottom: 1px;
          transition: border-color 0.15s;
        }
        .mab__cta:hover { border-color: #fff; }
        .mab__close {
          background: transparent;
          border: 0;
          color: rgba(255, 255, 255, 0.75);
          cursor: pointer;
          padding: 4px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: background 0.15s, color 0.15s;
          flex-shrink: 0;
        }
        .mab__close:hover {
          background: rgba(255, 255, 255, 0.15);
          color: #fff;
        }
        @media (max-width: 640px) {
          .mab__inner { padding: 9px 16px; font-size: 12px; gap: 10px; }
          .mab__text { font-size: 12px; }
        }
        @media (max-width: 460px) {
          .mab__pill { display: none; }
        }
      `}</style>
    </div>
  );
}

const FEATURES = [
  {
    Icon: Smartphone,
    title: "Toujours dans la poche",
    desc: "Sortez votre téléphone à n'importe quel moment pour quelques questions de plus.",
  },
  {
    Icon: Bell,
    title: "Rappels quotidiens",
    desc: "10 questions par jour, à l'heure que vous choisissez. La régularité avant tout.",
  },
  {
    Icon: RefreshCw,
    title: "Sync instantanée",
    desc: "Vos résultats, favoris et statistiques sont partagés avec le site, sans manipulation.",
  },
  {
    Icon: Sparkles,
    title: "Conçue pour le mobile",
    desc: "Saisie tactile, raccourcis swipe, mode sombre — pensée pour les sessions de 5 minutes.",
  },
];

/**
 * Section landing dédiée à l'app mobile. Positionnée comme compagnon du web
 * (même contenu, même progression), pas comme alternative obligatoire.
 */
export function MobileAppSection() {
  return (
    <section id="telecharger" className="mas">
      <div className="mas__bg" aria-hidden />

      <div className="mas__inner">
        <div className="mas__copy">
          <span className="eyebrow">§ Application mobile</span>
          <h2>
            Continuez votre préparation <em>partout</em>.
          </h2>
          <p className="mas__lede">
            L&apos;app mobile reprend exactement ce que vous faites sur le site —
            mêmes questions, mêmes statistiques, mêmes favoris — avec, en plus,
            les rappels quotidiens pour ne plus perdre le fil de votre
            préparation.
          </p>

          <ul className="mas__features">
            {FEATURES.map(({ Icon, title, desc }) => (
              <li key={title} className="mas__feat">
                <div className="mas__feat-icon" aria-hidden>
                  <Icon size={18} strokeWidth={1.8} />
                </div>
                <div className="mas__feat-body">
                  <h3>{title}</h3>
                  <p>{desc}</p>
                </div>
              </li>
            ))}
          </ul>

          <div className="mas__cta">
            <StoreBadge variant="ios" />
            <StoreBadge variant="android" />
          </div>

          <p className="mas__note">
            Un seul compte SejourFR partagé entre le site et l&apos;app — votre
            abonnement Premium se synchronise automatiquement.
          </p>
        </div>

        <div className="mas__visual" aria-hidden>
          <PhoneMock variant="back" />
          <PhoneMock variant="front" />
        </div>
      </div>

      <style>{`
        .mas {
          position: relative;
          padding: 112px 0;
          overflow: hidden;
          background: var(--color-paper);
          border-top: 1px solid var(--color-line);
          border-bottom: 1px solid var(--color-line);
        }
        .mas__bg {
          position: absolute; inset: 0;
          background:
            radial-gradient(900px 500px at 15% 30%, rgba(30, 58, 140, 0.06), transparent 60%),
            radial-gradient(700px 400px at 85% 75%, rgba(225, 55, 47, 0.05), transparent 60%);
          pointer-events: none;
        }
        .mas__inner {
          position: relative;
          max-width: 1180px;
          margin: 0 auto;
          padding: 0 28px;
          display: grid;
          grid-template-columns: 1.05fr 0.95fr;
          gap: 80px;
          align-items: center;
        }
        .mas__copy h2 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 46px;
          line-height: 1.04;
          letter-spacing: -0.025em;
          margin: 16px 0 18px;
          color: var(--color-ink);
        }
        .mas__copy h2 em {
          font-style: italic;
          color: var(--color-blue);
        }
        .mas__lede {
          color: var(--color-ink-2);
          font-size: 16.5px;
          line-height: 1.6;
          margin: 0 0 32px;
          max-width: 540px;
        }
        .mas__features {
          list-style: none;
          padding: 0;
          margin: 0 0 36px;
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 18px 24px;
        }
        .mas__feat {
          display: flex;
          gap: 12px;
          align-items: flex-start;
        }
        .mas__feat-icon {
          flex-shrink: 0;
          width: 36px; height: 36px;
          display: inline-flex;
          align-items: center; justify-content: center;
          border-radius: 10px;
          background: #fff;
          color: var(--color-blue);
          border: 1px solid var(--color-line);
          box-shadow: 0 1px 0 rgba(15, 24, 57, 0.04);
        }
        .mas__feat-body h3 {
          font-family: var(--font-sans);
          font-weight: 700;
          font-size: 14px;
          color: var(--color-ink);
          margin: 0 0 2px;
          letter-spacing: -0.005em;
        }
        .mas__feat-body p {
          font-size: 13px;
          line-height: 1.5;
          color: var(--color-muted);
          margin: 0;
        }
        .mas__cta {
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          margin-bottom: 16px;
        }
        .mas__note {
          font-size: 12.5px;
          color: var(--color-muted);
          margin: 0;
        }

        .mas__visual {
          position: relative;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 540px;
        }

        @media (max-width: 960px) {
          .mas { padding: 72px 0; }
          .mas__inner {
            grid-template-columns: 1fr;
            gap: 48px;
          }
          .mas__copy h2 { font-size: 36px; }
          .mas__visual { order: -1; min-height: 480px; }
          .mas__features { gap: 16px 20px; }
        }
        @media (max-width: 560px) {
          .mas__copy h2 { font-size: 30px; }
          .mas__features { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// Phone mockup
// ============================================================================

export function PhoneMock({ variant }: { variant: "front" | "back" }) {
  const isFront = variant === "front";
  return (
    <div className={`pm pm--${variant}`}>
      <div className="pm__notch" aria-hidden />
      <div className="pm__screen">
        {isFront ? <FrontScreen /> : <BackScreen />}
      </div>
      <style>{`
        .pm {
          width: 260px;
          background: #0F1839;
          padding: 10px;
          border-radius: 38px;
          box-shadow:
            0 50px 100px -30px rgba(15, 24, 57, 0.45),
            0 0 0 1px rgba(15, 24, 57, 0.08);
          position: relative;
        }
        .pm__notch {
          position: absolute;
          top: 18px;
          left: 50%;
          transform: translateX(-50%);
          width: 88px;
          height: 24px;
          border-radius: 100px;
          background: #000;
          z-index: 2;
        }
        .pm__screen {
          position: relative;
          background: #fff;
          border-radius: 28px;
          overflow: hidden;
          aspect-ratio: 9 / 19;
          padding: 50px 16px 20px;
        }
        .pm--back {
          position: absolute;
          left: 12%;
          top: 8%;
          transform: rotate(-8deg);
          opacity: 0.92;
          z-index: 1;
        }
        .pm--front {
          position: relative;
          z-index: 2;
          transform: rotate(3deg);
        }
        @media (max-width: 960px) {
          .pm { width: 220px; }
          .pm__screen { padding: 44px 14px 18px; }
        }
      `}</style>
    </div>
  );
}

function FrontScreen() {
  return (
    <div className="fs">
      <div className="fs__top">
        <span className="fs__eyebrow">CIVIQUE · CSP</span>
        <span className="fs__chip">14 / 20</span>
      </div>
      <div className="fs__q">
        Quelle est la devise de la République française ?
      </div>
      <div className="fs__opts">
        <div className="fs__opt fs__opt--ok">
          <span className="fs__bullet">A</span>
          Liberté, Égalité, Fraternité
        </div>
        <div className="fs__opt">
          <span className="fs__bullet">B</span>
          Liberté, Égalité, Solidarité
        </div>
        <div className="fs__opt">
          <span className="fs__bullet">C</span>
          Unité, Égalité, Fraternité
        </div>
        <div className="fs__opt">
          <span className="fs__bullet">D</span>
          Liberté, Justice, Fraternité
        </div>
      </div>
      <div className="fs__foot">
        <span className="fs__progress">
          <span className="fs__progress-fill" />
        </span>
        <button type="button" className="fs__next">Suivant →</button>
      </div>
      <style>{`
        .fs { display: flex; flex-direction: column; height: 100%; }
        .fs__top {
          display: flex; align-items: center; justify-content: space-between;
          margin-bottom: 14px;
        }
        .fs__eyebrow {
          font-family: var(--font-mono);
          font-size: 9px;
          letter-spacing: 0.16em;
          color: var(--color-muted);
        }
        .fs__chip {
          font-family: var(--font-mono);
          font-size: 9.5px;
          letter-spacing: 0.08em;
          background: var(--color-blue-light);
          color: var(--color-blue-dark);
          padding: 3px 8px;
          border-radius: 100px;
          font-weight: 600;
        }
        .fs__q {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 14.5px;
          line-height: 1.3;
          color: var(--color-ink);
          margin-bottom: 14px;
        }
        .fs__opts {
          display: flex; flex-direction: column; gap: 6px;
          flex: 1;
        }
        .fs__opt {
          display: flex; align-items: center; gap: 8px;
          padding: 8px 10px;
          border: 1.5px solid var(--color-line);
          border-radius: 9px;
          font-size: 11px;
          color: var(--color-ink-2);
          line-height: 1.25;
        }
        .fs__opt--ok {
          border-color: var(--color-green);
          background: rgba(22, 143, 91, 0.08);
          color: var(--color-green);
          font-weight: 600;
        }
        .fs__bullet {
          font-family: var(--font-mono);
          font-size: 9px;
          font-weight: 700;
          width: 16px; height: 16px;
          border-radius: 4px;
          background: var(--color-line-2);
          color: var(--color-muted);
          display: inline-flex;
          align-items: center; justify-content: center;
          flex-shrink: 0;
        }
        .fs__opt--ok .fs__bullet {
          background: var(--color-green);
          color: #fff;
        }
        .fs__foot {
          margin-top: 14px;
          display: flex; flex-direction: column; gap: 10px;
        }
        .fs__progress {
          height: 4px;
          background: var(--color-line);
          border-radius: 100px;
          overflow: hidden;
          display: block;
        }
        .fs__progress-fill {
          display: block;
          height: 100%;
          width: 70%;
          background: var(--color-blue);
        }
        .fs__next {
          background: var(--color-blue);
          color: #fff;
          border: 0;
          padding: 9px;
          border-radius: 9px;
          font-family: var(--font-sans);
          font-weight: 700;
          font-size: 11.5px;
          cursor: pointer;
        }
      `}</style>
    </div>
  );
}

function BackScreen() {
  return (
    <div className="bs">
      <div className="bs__top">
        <div>
          <div className="bs__hi">Bonjour Karim</div>
          <div className="bs__date">Jour 12 · Série en cours</div>
        </div>
        <div className="bs__streak" aria-hidden>🔥 12</div>
      </div>

      <div className="bs__ring">
        <svg viewBox="0 0 100 100" width="120" height="120">
          <circle cx="50" cy="50" r="42" stroke="#E4E7F2" strokeWidth="8" fill="none" />
          <circle
            cx="50" cy="50" r="42"
            stroke="#1E3A8C" strokeWidth="8" fill="none"
            strokeDasharray="263.9"
            strokeDashoffset="79.2"
            strokeLinecap="round"
            transform="rotate(-90 50 50)"
          />
        </svg>
        <div className="bs__ring-num">
          <span className="bs__pct">70%</span>
          <span className="bs__label">CIVIQUE</span>
        </div>
      </div>

      <div className="bs__stats">
        <div className="bs__stat">
          <span className="bs__stat-val">142</span>
          <span className="bs__stat-lab">Questions</span>
        </div>
        <div className="bs__stat">
          <span className="bs__stat-val bs__stat-val--ok">88%</span>
          <span className="bs__stat-lab">Réussite</span>
        </div>
      </div>

      <style>{`
        .bs { display: flex; flex-direction: column; gap: 16px; height: 100%; }
        .bs__top {
          display: flex; align-items: flex-start; justify-content: space-between;
        }
        .bs__hi {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 16px;
          color: var(--color-ink);
        }
        .bs__date {
          font-family: var(--font-mono);
          font-size: 9px;
          letter-spacing: 0.12em;
          color: var(--color-muted);
          margin-top: 2px;
        }
        .bs__streak {
          background: #FFF3E1;
          color: #C56C00;
          font-weight: 700;
          font-size: 11px;
          padding: 4px 9px;
          border-radius: 100px;
        }
        .bs__ring {
          position: relative;
          display: flex;
          justify-content: center;
          padding: 8px 0;
        }
        .bs__ring-num {
          position: absolute;
          inset: 0;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 2px;
        }
        .bs__pct {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 22px;
          color: var(--color-ink);
          line-height: 1;
        }
        .bs__label {
          font-family: var(--font-mono);
          font-size: 8.5px;
          letter-spacing: 0.16em;
          color: var(--color-muted);
        }
        .bs__stats {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
          margin-top: auto;
        }
        .bs__stat {
          background: var(--color-paper);
          border: 1px solid var(--color-line);
          border-radius: 10px;
          padding: 10px;
          display: flex;
          flex-direction: column;
          gap: 2px;
          align-items: flex-start;
        }
        .bs__stat-val {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 18px;
          color: var(--color-ink);
          line-height: 1;
        }
        .bs__stat-val--ok { color: var(--color-green); }
        .bs__stat-lab {
          font-family: var(--font-mono);
          font-size: 8px;
          letter-spacing: 0.14em;
          color: var(--color-muted);
        }
      `}</style>
    </div>
  );
}

// ============================================================================
// Store badges
// ============================================================================

const APP_STORE_URL = "https://apps.apple.com/fr/app/sejourfr/id6771509569";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.sejourfr.app&hl=fr";

export function StoreBadge({ variant }: { variant: "ios" | "android" }) {
  const isIos = variant === "ios";
  return (
    <a
      href={isIos ? APP_STORE_URL : PLAY_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className="sb"
      aria-label={isIos ? "Télécharger sur l'App Store" : "Disponible sur Google Play"}
    >
      <span className="sb__icon" aria-hidden>
        {isIos ? <AppleIcon /> : <GooglePlayIcon />}
      </span>
      <span className="sb__copy">
        <span className="sb__eyebrow">
          {isIos ? "Télécharger sur" : "Disponible sur"}
        </span>
        <span className="sb__name">
          {isIos ? "App Store" : "Google Play"}
        </span>
      </span>
      <style>{`
        .sb {
          display: inline-flex;
          align-items: center;
          gap: 10px;
          padding: 10px 18px;
          background: var(--color-ink);
          color: #fff;
          border-radius: 12px;
          text-decoration: none;
          transition: transform 0.15s, box-shadow 0.2s;
          box-shadow: 0 6px 16px -8px rgba(15, 24, 57, 0.4);
        }
        .sb:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 22px -10px rgba(15, 24, 57, 0.5);
        }
        .sb__icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 24px; height: 24px;
        }
        .sb__copy {
          display: inline-flex;
          flex-direction: column;
          gap: 1px;
        }
        .sb__eyebrow {
          font-family: var(--font-mono);
          font-size: 8.5px;
          letter-spacing: 0.16em;
          text-transform: uppercase;
          color: rgba(255, 255, 255, 0.65);
        }
        .sb__name {
          font-family: var(--font-sans);
          font-weight: 700;
          font-size: 15px;
          letter-spacing: -0.005em;
        }
      `}</style>
    </a>
  );
}

function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor" aria-hidden>
      <path d="M16.498 12.66c.025 2.73 2.39 3.638 2.417 3.65-.021.066-.378 1.291-1.246 2.555-.75 1.094-1.529 2.183-2.755 2.206-1.205.022-1.593-.715-2.97-.715-1.376 0-1.806.692-2.946.737-1.184.045-2.085-1.183-2.842-2.272-1.547-2.234-2.73-6.314-1.14-9.07.79-1.367 2.2-2.232 3.732-2.254 1.162-.023 2.26.781 2.97.781.71 0 2.046-.966 3.45-.823.587.024 2.236.237 3.295 1.787-.085.053-1.967 1.149-1.945 3.418zM14.272 4.94c.626-.758 1.047-1.812.932-2.86-.9.036-1.991.6-2.638 1.357-.58.671-1.088 1.745-.95 2.772 1.005.078 2.029-.51 2.656-1.268z" />
    </svg>
  );
}

function GooglePlayIcon() {
  return (
    <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden>
      <path d="M3.6 1.7c-.4.3-.6.8-.6 1.4v17.7c0 .6.2 1.1.6 1.4l9.4-10.3L3.6 1.7z" fill="#00C2FF" />
      <path d="M16.6 8.6L4.7 1.4c-.5-.3-1-.4-1.4-.2L14 12 16.6 8.6z" fill="#39E170" />
      <path d="M21.4 11l-4.8-2.4L14 12l2.6 3.4L21.4 13c1-.6 1-1.4 0-2z" fill="#FFCC00" />
      <path d="M4.7 22.6L16.6 15.4 14 12 3.3 22.8c.4.2.9.1 1.4-.2z" fill="#FF3B47" />
    </svg>
  );
}
