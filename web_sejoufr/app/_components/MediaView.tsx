"use client";

import { useEffect, useRef, useState } from "react";
import { sharedCoAudio } from "@/lib/co-audio";
import type { MediaResponse } from "@/lib/types";

/**
 * Affiche un media de question :
 *   - si `inlineSvg` est défini → rend le SVG tel quel (capture TCF dessinée)
 *   - sinon → image / audio / vidéo selon le type
 *
 * `coAudio` : l'audio d'une question de CO dans le runner, **lancé
 * automatiquement** à l'arrivée sur la question, sur l'élément partagé
 * déverrouillé au clic de lancement (`lib/co-audio.ts`) :
 *   - `"exam"` (régime `EXAMEN`, `AttemptResponse.mode`) — une seule écoute,
 *     pas de pause ni de réécoute ;
 *   - `"training"` — le lecteur natif et ses contrôles : pause, reprise et
 *     réécoute libres.
 * Absent (rapport, favoris…) : lecteur natif, rien ne part seul.
 *
 * Le SVG inline est assaini (DOMPurify, profil SVG) avant injection : la
 * source (drafts générés IA / images admin) n'est pas strictement fiable.
 * La sanitisation se fait côté client (import dynamique) pour ne jamais
 * exécuter DOMPurify au SSR — pas de hydration mismatch, pas de jsdom.
 */
export function MediaView({
  media,
  coAudio,
}: {
  media: MediaResponse;
  coAudio?: "exam" | "training";
}) {
  // Priorité url > inlineSvg : le backend ne pose normalement qu'un seul des
  // deux, mais si une image porte les deux (cas CO_IMAGE), on privilégie l'URL.
  const preferUrl = media.type === "IMAGE" && !!media.url;
  const showSvg = !!media.inlineSvg && !preferUrl;
  const [safeSvg, setSafeSvg] = useState("");

  useEffect(() => {
    if (!showSvg) {
      setSafeSvg("");
      return;
    }
    let active = true;
    import("dompurify").then((mod) => {
      if (active) {
        setSafeSvg(
          mod.default.sanitize(media.inlineSvg as string, {
            USE_PROFILES: { svg: true, svgFilters: true },
          }),
        );
      }
    });
    return () => {
      active = false;
    };
  }, [showSvg, media.inlineSvg]);

  return (
    <div className="mediaview">
      {showSvg ? (
        <div
          className="mediaview-svg"
          dangerouslySetInnerHTML={{ __html: safeSvg }}
          role="img"
          aria-label="Document"
        />
      ) : media.type === "IMAGE" && media.url ? (
        <img src={media.url} alt="Document" className="mediaview-img" />
      ) : media.type === "AUDIO" ? (
        coAudio === "exam" ? (
          <ExamAudio src={media.url} />
        ) : coAudio === "training" ? (
          <TrainingAudio src={media.url} />
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
        .mediaview-audio-host {
          width: 100%;
          max-width: 480px;
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
 * Lecteur d'entraînement CO : l'élément partagé est monté ici avec ses
 * contrôles natifs (pause, reprise, réécoute) et démarre seul 0,5 s après
 * l'arrivée sur la question. Lecture refusée (URL directe, rechargement) :
 * il reste en pause, son bouton play suffit — et ce tap le déverrouille.
 */
function TrainingAudio({ src }: { src?: string }) {
  const hostRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const host = hostRef.current;
    const el = sharedCoAudio();
    if (!host || !el || !src) return;
    el.pause();
    el.src = src;
    el.controls = true;
    el.className = "mediaview-audio";
    host.appendChild(el);
    const timer = setTimeout(() => {
      el.play().catch(() => {});
    }, 500);
    return () => {
      clearTimeout(timer);
      el.pause();
      el.removeAttribute("src");
      el.load();
      el.remove();
      el.controls = false;
      el.className = "";
    };
  }, [src]);

  return <div ref={hostRef} className="mediaview-audio-host" />;
}

/**
 * Lecteur « jour J » : l'audio démarre seul et n'est écouté qu'une fois —
 * aucun contrôle exposé. Si le navigateur bloque l'autoplay, un unique
 * bouton « lancer l'écoute » apparaît (puis disparaît, pas de réécoute).
 *
 * 🛑 Il joue sur l'élément PARTAGÉ `sharedCoAudio()` (`lib/co-audio.ts`),
 * déverrouillé dans le clic qui a lancé la session : c'est ce qui permet à
 * iOS de lancer seule la PREMIÈRE question. L'écoute n'est comptée (`done`)
 * qu'à la fin d'une lecture réelle — un `play()` refusé ne la consomme pas.
 */
function ExamAudio({ src }: { src?: string }) {
  const [phase, setPhase] = useState<"playing" | "blocked" | "done">(
    src ? "playing" : "blocked",
  );
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const el = sharedCoAudio();
    if (!el || !src) return;
    el.pause();
    el.src = src;
    const onTimeUpdate = () => {
      if (el.duration > 0) setProgress(el.currentTime / el.duration);
    };
    const onEnded = () => {
      setProgress(1);
      setPhase("done");
    };
    el.addEventListener("timeupdate", onTimeUpdate);
    el.addEventListener("ended", onEnded);
    // Auto-play 0,5s après l'ouverture de la question (parité mobile), pour
    // laisser une respiration avant l'écoute unique — conditions TCF réelles.
    const timer = setTimeout(() => {
      el.play().catch(() => setPhase("blocked"));
    }, 500);
    return () => {
      clearTimeout(timer);
      el.removeEventListener("timeupdate", onTimeUpdate);
      el.removeEventListener("ended", onEnded);
      el.pause();
      el.removeAttribute("src");
      el.load();
    };
  }, [src]);

  const launch = () => {
    const el = sharedCoAudio();
    if (!el || !src || phase !== "blocked") return;
    setPhase("playing");
    el.play().catch(() => setPhase("blocked"));
  };

  return (
    <div className={`mediaview-exam ${phase === "done" ? "is-done" : ""}`}>
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
