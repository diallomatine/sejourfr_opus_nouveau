"use client";

import type { MediaResponse } from "@/lib/types";

/**
 * Affiche un media de question :
 *   - si `inlineSvg` est défini → rend le SVG tel quel (capture TCF dessinée)
 *   - sinon → image / audio / vidéo selon le type
 *
 * Le SVG inline vient du backend (seed Flyway), pas d'un upload utilisateur,
 * donc `dangerouslySetInnerHTML` est acceptable ici.
 */
export function MediaView({ media }: { media: MediaResponse }) {
  // Priorité url > inlineSvg : le backend ne pose normalement qu'un seul des
  // deux, mais si une image porte les deux (cas CO_IMAGE), on privilégie l'URL.
  const preferUrl = media.type === "IMAGE" && !!media.url;
  return (
    <div className="mediaview">
      {media.inlineSvg && !preferUrl ? (
        <div
          className="mediaview-svg"
          dangerouslySetInnerHTML={{ __html: media.inlineSvg }}
          role="img"
          aria-label="Document"
        />
      ) : media.type === "IMAGE" && media.url ? (
        <img src={media.url} alt="Document" className="mediaview-img" />
      ) : media.type === "AUDIO" ? (
        <audio src={media.url} controls className="mediaview-audio">
          Votre navigateur ne supporte pas la lecture audio.
        </audio>
      ) : media.type === "VIDEO" ? (
        <video src={media.url} controls className="mediaview-video">
          Votre navigateur ne supporte pas la lecture vidéo.
        </video>
      ) : null}

      <style>{`
        .mediaview {
          display: flex; justify-content: center;
          margin: 0 0 18px;
        }
        .mediaview-svg {
          width: 100%;
          max-width: 480px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 12px;
          padding: 8px;
          box-shadow: 0 4px 20px -8px rgba(15, 24, 57, 0.12);
        }
        .mediaview-svg svg {
          width: 100%;
          height: auto;
          display: block;
          border-radius: 6px;
        }
        .mediaview-img {
          max-width: 100%;
          width: auto;
          max-height: 420px;
          border-radius: 12px;
          border: 1px solid var(--color-line);
        }
        .mediaview-audio, .mediaview-video {
          width: 100%;
          max-width: 480px;
        }
      `}</style>
    </div>
  );
}
