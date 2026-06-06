"use client";

import { useEffect, useState } from "react";
import { ApiException, userContentApi } from "@/lib/api";
import { orderedChoices, type QuestionReviewResponse, questionTypeLabel } from "@/lib/types";
import { MediaView } from "@/app/_components/MediaView";

/**
 * Bottom sheet (mobile) / dialog (desktop) de détail d'une question :
 * énoncé, choix avec la bonne réponse résolue, explication. Partagé entre
 * `/revision` (erreurs + favoris) et le détail de thème civique
 * (`/entrainement/civique/[theme]`, onglet Erreurs).
 *
 * Les listes /wrong et /favorites renvoient la version "publique" (sans
 * correct/explanation) : on refetch /review par id pour la correction —
 * même stratégie que le mobile (`question_detail_sheet`).
 *
 * Le bouton favori n'est rendu que si `onToggleFavorite` est fourni.
 */
export function QuestionDetailModal({
  question: fallbackQuestion,
  isFavorite = false,
  onClose,
  onToggleFavorite,
}: {
  question: QuestionReviewResponse;
  isFavorite?: boolean;
  onClose: () => void;
  onToggleFavorite?: (wasFavorite: boolean) => Promise<void>;
}) {
  const [toggling, setToggling] = useState(false);
  const [detail, setDetail] = useState<QuestionReviewResponse | null>(null);
  const [detailLoading, setDetailLoading] = useState(true);
  const [detailError, setDetailError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDetailLoading(true);
    setDetailError(null);
    userContentApi
      .reviewQuestion(fallbackQuestion.id)
      .then((q) => {
        if (cancelled) return;
        setDetail(q);
      })
      .catch((e) => {
        if (cancelled) return;
        setDetailError(
          e instanceof ApiException ? e.message : "Impossible de charger la correction.",
        );
      })
      .finally(() => {
        if (cancelled) return;
        setDetailLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [fallbackQuestion.id]);

  const question = detail ?? fallbackQuestion;

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [onClose]);

  const handleToggle = async () => {
    if (toggling || !onToggleFavorite) return;
    setToggling(true);
    try {
      await onToggleFavorite(isFavorite);
    } finally {
      setToggling(false);
    }
  };

  return (
    <div className="rvd" role="dialog" aria-modal="true" onClick={onClose}>
      <div className="rvd-backdrop" />
      <div className="rvd-sheet" onClick={(e) => e.stopPropagation()}>
        <button type="button" className="rvd-close" onClick={onClose} aria-label="Fermer">
          ✕
        </button>

        <div className="rvd-head">
          <div className="rvd-tags">
            <span className="rv-tag rv-tag-blue">{question.themeName}</span>
            <span className="rv-tag rv-tag-mono">{question.difficulty}</span>
            <span className="rv-tag rv-tag-mono">
              {questionTypeLabel(question.questionType)}
            </span>
          </div>
          {onToggleFavorite && (
            <button
              type="button"
              className={`rvd-fav ${isFavorite ? "is-on" : ""}`}
              onClick={handleToggle}
              disabled={toggling}
              aria-label={isFavorite ? "Retirer des favoris" : "Ajouter aux favoris"}
            >
              <StarIcon filled={isFavorite} />
            </button>
          )}
        </div>

        {question.passageText && (
          <div className="rvd-passage">
            <div className="rvd-passage-label">Document à lire</div>
            <div className="rvd-passage-body">{question.passageText}</div>
          </div>
        )}

        {question.media && (
          <div className="rvd-media">
            <MediaView media={question.media} />
          </div>
        )}

        {question.audioMedia && (
          <div className="rvd-media">
            <MediaView media={question.audioMedia} />
          </div>
        )}

        <h2 className="rvd-statement">
          {question.questionType === "CO_IMAGE"
            ? question.statement ||
              "Écoutez les propositions et choisissez celle qui correspond à l'image."
            : question.statement}
        </h2>

        <div className="rvd-choices">
          {orderedChoices(question.choices).map((c, i) => {
            // FULL_AUDIO / CO_IMAGE : le texte du choix vit dans l'audio → on
            // affiche la lettre dans la pastille et on masque le label redondant ;
            // les choix sont déjà triés A→D.
            const letterMatch = /^(?:r[ée]ponse\s+)?([A-D])$/i.exec(c.label.trim());
            const letterOnly = question.questionType === "CO_IMAGE" || letterMatch !== null;
            const letter = letterMatch
              ? letterMatch[1].toUpperCase()
              : String.fromCharCode(65 + i);
            return (
              <div key={c.id} className={`rvd-choice ${c.correct ? "is-correct" : ""}`}>
                <span className="rvd-letter">{letter}</span>
                <span className="rvd-choice-label">{letterOnly ? "" : c.label}</span>
                {c.correct && (
                  <span className="rvd-check" aria-label="Bonne réponse">
                    <svg viewBox="0 0 16 16" width="16" height="16">
                      <circle cx="8" cy="8" r="8" fill="currentColor" />
                      <path
                        d="M4.5 8.5l2.4 2.2 4.6-5"
                        stroke="#fff"
                        strokeWidth="1.6"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        fill="none"
                      />
                    </svg>
                  </span>
                )}
              </div>
            );
          })}
        </div>

        {detailLoading && !detail && (
          <div className="rvd-loading">
            <span className="rvd-spinner" aria-hidden />
            <span>Chargement de la correction…</span>
          </div>
        )}

        {detailError && <div className="rvd-detail-error">{detailError}</div>}

        {question.explanation && (
          <div className="rvd-explain">
            <div className="rvd-explain-head">
              <BulbIcon />
              <span>Explication</span>
            </div>
            <p>{question.explanation}</p>
          </div>
        )}
      </div>
      <style>{detailStyles}</style>
    </div>
  );
}

const I = (props: React.SVGProps<SVGSVGElement>) => (
  <svg
    width="16"
    height="16"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    {...props}
  />
);
const StarIcon = ({ filled = false }: { filled?: boolean }) => (
  <I fill={filled ? "currentColor" : "none"}>
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </I>
);
const BulbIcon = () => (
  <I width="14" height="14">
    <path d="M9 18h6M10 22h4M12 2a7 7 0 0 0-4 13l1 2h6l1-2a7 7 0 0 0-4-13z" />
  </I>
);

const detailStyles = `
  .rvd {
    position: fixed; inset: 0;
    z-index: 100;
    display: flex; align-items: flex-end; justify-content: center;
  }
  .rvd-backdrop {
    position: absolute; inset: 0;
    background: rgba(15, 24, 57, 0.55);
    backdrop-filter: blur(4px);
    animation: rvd-fade-in 0.18s ease-out;
  }
  @keyframes rvd-fade-in { from { opacity: 0; } to { opacity: 1; } }
  @keyframes rvd-slide-up {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  .rvd-sheet {
    position: relative;
    background: #fff;
    border-radius: 22px 22px 0 0;
    padding: 28px 28px 24px;
    width: 100%;
    max-width: 640px;
    box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
    animation: rvd-slide-up 0.22s ease-out;
    max-height: 92vh;
    overflow-y: auto;
  }
  @media (min-width: 640px) {
    .rvd { align-items: center; }
    .rvd-sheet { border-radius: 22px; }
  }
  .rvd-close {
    position: absolute; top: 18px; right: 18px;
    width: 32px; height: 32px;
    background: var(--color-paper-2);
    border: none; border-radius: 8px;
    font-size: 14px;
    color: var(--color-muted);
    cursor: pointer;
    z-index: 2;
  }
  .rvd-close:hover { background: var(--color-line); color: var(--color-ink); }
  .rvd-head {
    display: flex; align-items: flex-start; justify-content: space-between;
    gap: 16px; margin-bottom: 16px;
    padding-right: 44px;
  }
  .rvd-tags { display: flex; flex-wrap: wrap; gap: 6px; }
  .rv-tag {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    font-weight: 700;
  }
  .rv-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .rv-tag-mono { background: var(--color-paper-2); color: var(--color-muted); }
  .rvd-fav {
    background: none; border: 1px solid var(--color-line);
    color: var(--color-ink);
    width: 36px; height: 36px;
    border-radius: 10px;
    display: inline-flex; align-items: center; justify-content: center;
    cursor: pointer;
    transition: all 0.15s;
    flex-shrink: 0;
  }
  .rvd-fav:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .rvd-fav.is-on {
    color: var(--color-red);
    border-color: rgba(225, 55, 47, 0.3);
    background: var(--color-red-light);
  }
  .rvd-passage {
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.15);
    border-radius: 12px;
    padding: 14px 16px;
    margin: 0 0 16px;
  }
  .rvd-passage-label {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rvd-passage-body {
    font-size: 13.5px; color: var(--color-ink-2); line-height: 1.55;
    white-space: pre-wrap;
  }
  .rvd-media { margin: 0 0 16px; }
  .rvd-media .mediaview { margin: 0; }
  .rvd-statement {
    font-family: var(--font-display); font-weight: 600;
    font-size: 21px; line-height: 1.3;
    color: var(--color-ink);
    margin: 0 0 20px;
    letter-spacing: -0.015em;
  }
  .rvd-choices { display: flex; flex-direction: column; gap: 8px; margin-bottom: 18px; }
  .rvd-choice {
    display: flex; align-items: center; gap: 12px;
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 12px;
    padding: 12px 14px;
    font-size: 14px; color: var(--color-ink-2);
  }
  .rvd-choice.is-correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.05);
  }
  .rvd-letter {
    width: 26px; height: 26px;
    border-radius: 7px;
    background: var(--color-paper-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 12px; font-weight: 700;
    flex-shrink: 0;
  }
  .rvd-choice.is-correct .rvd-letter {
    background: var(--color-green); color: #fff;
  }
  .rvd-choice-label { flex: 1; }
  .rvd-check { color: var(--color-green); display: inline-flex; align-items: center; flex-shrink: 0; }
  .rvd-explain {
    background: var(--color-blue-soft);
    border-left: 3px solid var(--color-blue);
    border-radius: 10px;
    padding: 14px 16px;
  }
  .rvd-explain-head {
    display: inline-flex; align-items: center; gap: 6px;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rvd-explain p {
    font-size: 13.5px; line-height: 1.55; color: var(--color-ink-2); margin: 0;
  }
  .rvd-loading {
    display: inline-flex; align-items: center; gap: 8px;
    margin-bottom: 12px;
    font-size: 12.5px; color: var(--color-muted);
    font-family: var(--font-mono);
    letter-spacing: 0.06em;
  }
  .rvd-spinner {
    width: 12px; height: 12px;
    border-radius: 50%;
    border: 2px solid var(--color-line);
    border-top-color: var(--color-blue);
    animation: rvd-spin 0.8s linear infinite;
  }
  @keyframes rvd-spin { to { transform: rotate(360deg); } }
  .rvd-detail-error {
    background: var(--color-red-light);
    border: 1px solid rgba(225, 55, 47, 0.25);
    border-radius: 10px;
    padding: 10px 14px;
    color: var(--color-red);
    font-size: 12.5px;
    margin-bottom: 12px;
  }
`;
