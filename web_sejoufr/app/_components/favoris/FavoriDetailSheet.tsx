"use client";

import {useEffect, useState} from "react";
import {BookOpen, Bookmark, BookmarkCheck, Check, Circle, Loader2, X} from "lucide-react";
import {ApiException, userContentApi} from "@/lib/api";
import {
  FAVORI_ADD,
  FAVORI_DETAIL_ERROR,
  FAVORI_EXPLICATION,
  FAVORI_ON,
  FAVORI_PASSAGE,
  favoriDetailEyebrow,
} from "@/lib/favoris";
import {type QuestionReviewResponse, questionTypeLabel} from "@/lib/types";
import {MediaView} from "../MediaView";
import s from "./favoris.module.css";

/**
 * Détail d'un favori : feuille posée en bas (dialogue centré sur grand écran).
 * Énoncé, média, passage, propositions avec la bonne réponse résolue,
 * explication, et le marque-page pour retirer / remettre le favori.
 *
 * La liste des favoris renvoie la version « publique » (sans `correct` ni
 * explication) : on relit `/api/me/questions/{id}/review` pour la correction.
 * Miroir mobile : `QuestionDetailSheet` (`core/widgets/question_detail_sheet.dart`)
 * avec le bouton favori de `MesFavorisScreen`.
 */
export function FavoriDetailSheet({
  question: fallback,
  isFavorite,
  onClose,
  onToggleFavorite,
}: {
  question: QuestionReviewResponse;
  isFavorite: boolean;
  onClose: () => void;
  onToggleFavorite: (wasFavorite: boolean) => Promise<void>;
}) {
  const [detail, setDetail] = useState<QuestionReviewResponse | null>(null);
  const [detailLoading, setDetailLoading] = useState(true);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [toggling, setToggling] = useState(false);

  useEffect(() => {
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDetailLoading(true);
    setDetailError(null);
    userContentApi
      .reviewQuestion(fallback.id)
      .then((q) => {
        if (!cancelled) setDetail(q);
      })
      .catch((e) => {
        if (!cancelled) setDetailError(e instanceof ApiException ? e.message : FAVORI_DETAIL_ERROR);
      })
      .finally(() => {
        if (!cancelled) setDetailLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [fallback.id]);

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

  async function toggle() {
    if (toggling) return;
    setToggling(true);
    try {
      await onToggleFavorite(isFavorite);
    } catch {
      // Le serveur a refusé : l'état affiché reste celui d'avant.
    } finally {
      setToggling(false);
    }
  }

  const q = detail ?? fallback;
  const passage = q.passageText?.trim();

  return (
    <div className={s.sheetRoot} role="dialog" aria-modal="true" onClick={onClose}>
      <div className={s.sheet} onClick={(e) => e.stopPropagation()}>
        <div className={s.sheetTop}>
          <span className={s.sheetEyebrow}>{favoriDetailEyebrow(q.module)}</span>
          <button
            type="button"
            className={`${s.favToggle} ${isFavorite ? s.favOn : ""}`}
            onClick={() => void toggle()}
            disabled={toggling}
          >
            {toggling ? (
              <Loader2 className={s.spin} size={14} aria-hidden/>
            ) : isFavorite ? (
              <BookmarkCheck size={16} aria-hidden/>
            ) : (
              <Bookmark size={16} aria-hidden/>
            )}
            <span>{isFavorite ? FAVORI_ON : FAVORI_ADD}</span>
          </button>
          <button type="button" className={s.sheetClose} onClick={onClose} aria-label="Fermer">
            <X size={16} aria-hidden/>
          </button>
        </div>

        <div className={s.sheetTags}>
          <span className={`${s.tag} ${s.tagRed}`}>{q.difficulty}</span>
          <span className={`${s.tag} ${s.tagBlue}`}>{questionTypeLabel(q.questionType)}</span>
        </div>

        {q.media && (
          <div className={s.sheetBlock}>
            <MediaView media={q.media}/>
          </div>
        )}
        {q.audioMedia && (
          <div className={s.sheetBlock}>
            <MediaView media={q.audioMedia}/>
          </div>
        )}
        {passage && (
          <div className={`${s.sheetBlock} ${s.passage}`}>
            <span className={s.blockLabel}>
              <BookOpen size={14} aria-hidden/> {FAVORI_PASSAGE}
            </span>
            <p>{passage}</p>
          </div>
        )}

        <p className={s.sheetStatement}>{q.statement}</p>

        <div className={s.choices}>
          {q.choices.map((c) => (
            <div key={c.id} className={`${s.choice} ${c.correct ? s.choiceCorrect : ""}`}>
              <span className={s.choiceIcon} aria-hidden>
                {c.correct ? <Check size={14}/> : <Circle size={14}/>}
              </span>
              <span className={s.choiceLabel}>{c.label}</span>
            </div>
          ))}
        </div>

        {detailLoading && !detail && (
          <div className={s.sheetLoading}>
            <Loader2 className={s.spin} size={20} aria-hidden/>
          </div>
        )}
        {detailError && <div className={s.sheetError}>{detailError}</div>}

        {q.explanation && (
          <div className={s.explain}>
            <span className={`${s.blockLabel} ${s.blockLabelBlue}`}>{FAVORI_EXPLICATION}</span>
            <p>{q.explanation}</p>
          </div>
        )}
      </div>
    </div>
  );
}
