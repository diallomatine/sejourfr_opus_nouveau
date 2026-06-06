"use client";

import { useEffect, useRef, useState } from "react";
import type { MediaResponse } from "@/lib/types";

/**
 * Affiche un media de question :
 *   - si `inlineSvg` est défini → rend le SVG tel quel (capture TCF dessinée)
 *   - sinon → image / audio / vidéo selon le type
 *
 * `examAudio` : lecteur audio en conditions d'examen (CO en MOCK_EXAM) —
 * lancement automatique, une seule écoute, pas de pause ni de réécoute.
 * En entraînement (défaut), le lecteur natif reste libre.
 *
 * Le SVG inline vient du backend (seed Flyway), pas d'un upload utilisateur,
 * donc `dangerouslySetInnerHTML` est acceptable ici.
 */
export function MediaView({
  media,
  examAudio = false,
}: {
  media: MediaResponse;
  examAudio?: boolean;
}) {
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
        examAudio ? (
          <ExamAudio src={media.url} />
        ) : (
          <audio src={media.url} controls className="mediaview-audio">
            Votre navigateur ne supporte pas la lecture audio.
          </audio>
        )
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

        .mediaview-exam {
          width: 100%;
          max-width: 480px;
          display: flex; align-items: center; gap: 12px;
          background: var(--color-blue-soft);
          border: 1px solid rgba(30, 58, 140, 0.15);
          border-radius: 12px;
          padding: 12px 16px;
        }
        .mediaview-exam-ico {
          width: 36px; height: 36px; flex-shrink: 0;
          border-radius: 50%;
          background: var(--color-blue);
          color: #fff;
          display: flex; align-items: center; justify-content: center;
          font-size: 16px;
          border: none; cursor: default;
        }
        .mediaview-exam-ico.is-btn { cursor: pointer; }
        .mediaview-exam-ico.is-playing { animation: mv-pulse 1.6s ease-in-out infinite; }
        @keyframes mv-pulse {
          0%, 100% { box-shadow: 0 0 0 0 rgba(30, 58, 140, 0.3); }
          50% { box-shadow: 0 0 0 6px rgba(30, 58, 140, 0); }
        }
        .mediaview-exam-body { flex: 1; min-width: 0; }
        .mediaview-exam-label {
          font-size: 13px; font-weight: 700; color: var(--color-blue);
          margin-bottom: 6px;
        }
        .mediaview-exam.is-done .mediaview-exam-label { color: var(--color-muted); }
        .mediaview-exam-track {
          height: 4px; border-radius: 100px;
          background: rgba(30, 58, 140, 0.15);
          overflow: hidden;
        }
        .mediaview-exam-fill {
          height: 100%;
          background: var(--color-blue);
          border-radius: 100px;
          transition: width 0.25s linear;
        }
      `}</style>
    </div>
  );
}

/**
 * Lecteur « jour J » : l'audio démarre seul et n'est écouté qu'une fois —
 * aucun contrôle exposé. Si le navigateur bloque l'autoplay, un unique
 * bouton « lancer l'écoute » apparaît (puis disparaît, pas de réécoute).
 */
function ExamAudio({ src }: { src?: string }) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [phase, setPhase] = useState<"playing" | "blocked" | "done">("playing");
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const el = audioRef.current;
    if (!el) return;
    el.play().catch(() => setPhase("blocked"));
  }, []);

  const launch = () => {
    const el = audioRef.current;
    if (!el || phase !== "blocked") return;
    setPhase("playing");
    el.play().catch(() => setPhase("blocked"));
  };

  return (
    <div className={`mediaview-exam ${phase === "done" ? "is-done" : ""}`}>
      <audio
        ref={audioRef}
        src={src}
        preload="auto"
        onTimeUpdate={(e) => {
          const el = e.currentTarget;
          if (el.duration > 0) setProgress(el.currentTime / el.duration);
        }}
        onEnded={() => {
          setProgress(1);
          setPhase("done");
        }}
      />
      {phase === "blocked" ? (
        <button
          type="button"
          className="mediaview-exam-ico is-btn"
          onClick={launch}
          aria-label="Lancer l'écoute"
        >
          ▶
        </button>
      ) : (
        <span
          className={`mediaview-exam-ico ${phase === "playing" ? "is-playing" : ""}`}
          aria-hidden
        >
          {phase === "done" ? "✓" : "🎧"}
        </span>
      )}
      <div className="mediaview-exam-body">
        <div className="mediaview-exam-label" aria-live="polite">
          {phase === "blocked"
            ? "Appuyez pour lancer l'écoute — une seule lecture"
            : phase === "done"
              ? "Écoute terminée — répondez puis passez à la suite"
              : "Écoute en cours… une seule lecture, comme le jour J"}
        </div>
        <div className="mediaview-exam-track">
          <div
            className="mediaview-exam-fill"
            style={{ width: `${Math.round(progress * 100)}%` }}
          />
        </div>
      </div>
    </div>
  );
}
