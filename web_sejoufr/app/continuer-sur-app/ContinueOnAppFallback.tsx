"use client";

import {useEffect, useState} from "react";
import {StoreBadge} from "@/app/_components/MobileAppPromo";
import {detectMobilePlatform, type MobilePlatform} from "@/lib/app-link";

/**
 * Le lien est arrivé dans le navigateur au lieu de l'app. On ne sait pas
 * transmettre le diagnostic à une app installée **après coup** (deferred deep
 * link, hors MVP) : on le dit, et on donne le geste qui marche — installer,
 * revenir à la page précédente, toucher le lien de nouveau.
 *
 * 🛑 Le fragment porte le jeton de rattachement : il est retiré de la barre
 * d'adresse et de l'historique dès l'arrivée, et rien ici ne le lit.
 */
export function ContinueOnAppFallback() {
  const [platform, setPlatform] = useState<MobilePlatform | null>(null);

  useEffect(() => {
    if (window.location.hash) {
      window.history.replaceState(null, "", window.location.pathname);
    }
    setPlatform(detectMobilePlatform());
  }, []);

  return (
    <main className="cosa">
      <p className="cosa-eyebrow">Application SejourFR</p>
      <h1 className="cosa-title">
        Continuer sur <em>l&apos;application</em>
      </h1>
      <p className="cosa-lead">
        L&apos;application n&apos;a pas pu s&apos;ouvrir : elle n&apos;est peut-être pas encore
        installée sur ce téléphone.
      </p>

      <ol className="cosa-steps">
        <li>Installez l&apos;application SejourFR.</li>
        <li>
          Revenez à la page précédente et touchez de nouveau « Continuer sur
          l&apos;application » : votre diagnostic suivra.
        </li>
      </ol>

      <div className="cosa-stores">
        {platform !== "android" && <StoreBadge variant="ios" />}
        {platform !== "ios" && <StoreBadge variant="android" />}
      </div>

      <p className="cosa-note">
        Vous pouvez aussi créer votre compte depuis la page précédente : votre diagnostic y
        est conservé.
      </p>

      <style>{`
        .cosa {
          box-sizing: border-box;
          width: 100%;
          max-width: 560px;
          margin: 0 auto;
          padding: 48px 16px 64px;
          color: var(--color-ink);
          font-family: var(--font-sans);
        }
        .cosa-eyebrow {
          margin: 0 0 10px;
          color: var(--color-blue);
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.14em;
          text-transform: uppercase;
        }
        .cosa-title {
          margin: 0 0 12px;
          font-family: var(--font-display);
          font-size: clamp(28px, 7vw, 40px);
          line-height: 1.1;
        }
        .cosa-title em {
          color: var(--color-red);
        }
        .cosa-lead {
          margin: 0 0 20px;
          color: var(--color-ink-2);
          font-size: 16px;
          line-height: 1.55;
        }
        .cosa-steps {
          display: grid;
          gap: 8px;
          margin: 0 0 24px;
          padding-left: 20px;
          color: var(--color-ink-2);
          font-size: 15px;
          line-height: 1.5;
        }
        .cosa-stores {
          display: flex;
          flex-wrap: wrap;
          gap: 12px;
          margin: 0 0 20px;
        }
        .cosa-note {
          margin: 0;
          color: var(--color-muted);
          font-size: 13px;
          line-height: 1.5;
        }
      `}</style>
    </main>
  );
}
