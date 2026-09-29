"use client";

import {STORE_LINKS} from "@/lib/site";

/**
 * Badge « App Store » / « Google Play » sombre, lien vers `STORE_LINKS`.
 * Seul rescapé de l'ancien `MobileAppPromo.tsx` (section app de l'accueil
 * d'avant la refonte du 2026-09-26) : il sert `/continuer-sur-app`.
 */
export function StoreBadge({ variant }: { variant: "ios" | "android" }) {
  const isIos = variant === "ios";
  return (
    <a
      href={isIos ? STORE_LINKS.ios : STORE_LINKS.android}
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

/** Logo Apple monochrome (`currentColor`) : repris par la section mobile de l'accueil. */
export function AppleIcon() {
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

/** Logo Google Play monochrome (`currentColor`), pendant d'`AppleIcon` pour les
 *  surfaces qui peignent le logo à la couleur du texte. */
export function GooglePlayMonoIcon() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden>
      <path d="M3.6 2.32a1.02 1.02 0 0 0-.35.79v17.78c0 .33.13.61.36.79l.1.06 9.96-9.96v-.24L3.7 2.26l-.1.06zm13.4 6.4L14.7 6.9 4.86 1.28c-.28-.16-.55-.18-.78-.06l9.96 9.97 3.96-2.47zm3.16 1.9-2.4-1.5-3.3 2.88 3.3 3.3 2.4-1.5c.7-.44.7-1.24 0-1.68zM4.08 22.78c.23.12.5.1.78-.06l9.84-5.62-3.4-3.4-9.96 9.97.74-.89z" />
    </svg>
  );
}
