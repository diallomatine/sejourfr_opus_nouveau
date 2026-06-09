"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { MediaView } from "./MediaView";
import { ConfirmSheet } from "./hub/ConfirmSheet";
import {
  ApiException,
  attemptApi,
  userContentApi,
} from "@/lib/api";
import {
  orderedChoices,
  questionTypeLabel,
  type AnswerResultResponse,
  type AttemptQuestionResponse,
  type AttemptResponse,
  type Module as ModuleEnum,
  type StartAttemptRequest,
  type SubmitAnswerRequest,
} from "@/lib/types";

export type RunnerMode = "training" | "exam";

/**
 * Partie d'un examen sectionné (ex: TCF — compréhension orale, puis écrite,
 * puis structures). Les questions sont déjà groupées par le backend ; les
 * sections servent à informer l'utilisateur de sa progression : bandeau
 * par partie + écran d'intro à chaque changement.
 */
export interface RunnerSection {
  label: string;
  icon: string;
  /** Index (global) de la première question de la partie. */
  startIndex: number;
  count: number;
}

/**
 * Backend adapters injectables : permettent de faire tourner le même runner
 * en mode connecté (auth API) et en mode démo guest (public API). Par défaut,
 * le runner utilise les endpoints authentifiés.
 */
export interface RunnerBackend {
  submitAnswer: (
    attemptId: string,
    body: SubmitAnswerRequest,
  ) => Promise<AnswerResultResponse>;
  finish: (attemptId: string) => Promise<AttemptResponse>;
  /** Extension training infinite. Null = pas d'extension supportée (démo guest). */
  extend?: (body: StartAttemptRequest) => Promise<AttemptResponse>;
  /** Toggle favori. Optionnel : la démo guest passe null pour cacher l'icône. */
  toggleFavorite?: (questionId: string, isCurrentlyFavorite: boolean) => Promise<void>;
}

export interface QuestionRunnerProps {
  initialAttempt: AttemptResponse;
  mode: RunnerMode;
  /** En training premium, le runner étend automatiquement la session avec un nouveau batch. */
  infinite?: boolean;
  /** Paramètres de l'extension (training infini uniquement). */
  extensionParams?: { module: ModuleEnum; themeId?: string; batchSize: number };
  /** IDs des questions déjà en favori (préchargés en amont). */
  initialFavoriteIds?: Set<string>;
  /** Étiquette du eyebrow (ex: "Entraînement", "Examen blanc"). */
  eyebrow: string;
  /** Lien du bouton "X" pour quitter. */
  quitHref: string;
  /** Comportement du bouton "X" :
   *  - "link" (défaut) : navigue vers `quitHref` (entraînement, épreuve d'un
   *    examen complet → retour au hub).
   *  - "confirmFinish" : avertit puis FINALISE l'examen (questions non répondues
   *    comptées 0) et affiche le résultat — pas d'examen laissé « en cours ». */
  quitMode?: "link" | "confirmFinish";
  /** Appelé quand l'attempt actif est finalisé (score disponible). */
  onCompleted: (finalAttempt: AttemptResponse) => void;
  /** Mode exam : décompte total en secondes. Quand 0, on auto-finalise. */
  timeLimitSeconds?: number;
  /** Mode exam : timestamp ISO de démarrage de l'attempt (pour recaler après reload). */
  startedAt?: string;
  /** Parties de l'examen (≥ 2) quand les questions sont groupées par épreuve. */
  sections?: RunnerSection[];
  /** Backend adapter : par défaut, endpoints authentifiés. La démo guest injecte les endpoints publics. */
  backend?: RunnerBackend;
}

const DEFAULT_BACKEND: RunnerBackend = {
  submitAnswer: (id, body) => attemptApi.submitAnswer(id, body),
  finish: (id) => attemptApi.finish(id),
  extend: (body) => attemptApi.start(body),
  toggleFavorite: async (qid, wasFav) => {
    if (wasFav) await userContentApi.removeFavorite(qid);
    else await userContentApi.addFavorite(qid);
  },
};

interface RunnerState {
  /** Liste cumulée des questions (un seul batch en exam, plusieurs en training infini). */
  questions: AttemptQuestionResponse[];
  /** Map attemptQuestionId -> attemptId (pour router submitAnswer + finish). */
  attemptIdByQuestionId: Map<string, string>;
  /** Le dernier attempt chargé (= batch actif en infini). */
  activeAttempt: AttemptResponse;
  currentIndex: number;
  /** ChoiceIds sélectionnés pour chaque attemptQuestionId. */
  answersByQuestion: Map<string, string[]>;
  /** Résultat de la dernière soumission (training only). */
  lastResult: AnswerResultResponse | null;
  favoriteIds: Set<string>;
  submitting: boolean;
  extending: boolean;
  /** True si l'extension a échoué (plus de questions disponibles pour ce filtre). */
  noMoreQuestions: boolean;
  error: string | null;
}

export function QuestionRunner({
  initialAttempt,
  mode,
  infinite = false,
  extensionParams,
  initialFavoriteIds,
  eyebrow,
  quitHref,
  quitMode = "link",
  onCompleted,
  timeLimitSeconds,
  startedAt,
  sections,
  backend = DEFAULT_BACKEND,
}: QuestionRunnerProps) {
  const favoritesEnabled = backend.toggleFavorite !== undefined;
  const [state, setState] = useState<RunnerState>(() => {
    const firstUnanswered = initialAttempt.questions.findIndex((q) => !q.answered);
    const startIndex =
      firstUnanswered === -1
        ? Math.max(0, initialAttempt.questions.length - 1)
        : firstUnanswered;
    const answers = new Map<string, string[]>();
    for (const q of initialAttempt.questions) {
      if (q.selectedChoiceIds.length > 0) {
        answers.set(q.id, q.selectedChoiceIds);
      }
    }
    const mapping = new Map<string, string>();
    for (const q of initialAttempt.questions) {
      mapping.set(q.id, initialAttempt.id);
    }
    return {
      questions: initialAttempt.questions,
      attemptIdByQuestionId: mapping,
      activeAttempt: initialAttempt,
      currentIndex: startIndex,
      answersByQuestion: answers,
      lastResult: null,
      favoriteIds: new Set(initialFavoriteIds ?? []),
      submitting: false,
      extending: false,
      noMoreQuestions: !infinite,
      error: null,
    };
  });

  const current = state.questions[state.currentIndex];
  const totalForUI = infinite ? null : state.activeAttempt.totalQuestions;
  const selected = current ? state.answersByQuestion.get(current.id) ?? [] : [];
  const isLast = state.currentIndex >= state.questions.length - 1;
  const hasFeedback = state.lastResult !== null;
  const isCurrentFavorite = current
    ? state.favoriteIds.has(current.question.id)
    : false;

  // ============== SECTIONS (examen sectionné) ==============
  // Partie courante + écran d'intro affiché en entrant sur la 1re question
  // d'une partie pas encore répondue (donc pas en navigation arrière, ni à
  // la reprise d'une session au milieu d'une partie). Seuls les examens
  // multi-épreuves émettent des sections (cf. tcfExamSections) : les examens
  // mono-épreuve n'en passent plus, leur présentation vit dans ExamIntroSheet.
  const sectionList = sections && sections.length > 0 ? sections : null;
  const multiSection = sectionList !== null && sectionList.length > 1;
  let sectionIndex = -1;
  if (sectionList) {
    for (let i = 0; i < sectionList.length; i++) {
      if (state.currentIndex >= sectionList[i].startIndex) sectionIndex = i;
    }
  }
  const currentSection = sectionIndex >= 0 ? sectionList![sectionIndex] : null;
  const [introsSeen, setIntrosSeen] = useState<ReadonlySet<number>>(new Set());
  const showSectionIntro =
    currentSection !== null &&
    current !== undefined &&
    state.currentIndex === currentSection.startIndex &&
    !introsSeen.has(currentSection.startIndex) &&
    !state.answersByQuestion.has(current.id);
  const dismissSectionIntro = useCallback(() => {
    if (currentSection === null) return;
    setIntrosSeen((s) => new Set(s).add(currentSection.startIndex));
  }, [currentSection]);
  /** Dernière question d'une partie (hors toute fin d'examen). */
  const isSectionEnd =
    currentSection !== null &&
    !isLast &&
    state.currentIndex === currentSection.startIndex + currentSection.count - 1;

  // ============== ACTIONS ==============

  const toggleChoice = useCallback(
    (choiceId: string) => {
      if (state.submitting || hasFeedback) return;
      const q = state.questions[state.currentIndex];
      if (!q) return;
      setState((s) => {
        const next = new Map(s.answersByQuestion);
        const previous = next.get(q.id) ?? [];
        if (previous.includes(choiceId)) {
          next.delete(q.id);
        } else {
          next.set(q.id, [choiceId]);
        }
        return { ...s, answersByQuestion: next, error: null };
      });
    },
    [state.submitting, hasFeedback, state.questions, state.currentIndex],
  );

  const submitCurrent = useCallback(async () => {
    const q = state.questions[state.currentIndex];
    if (!q) return;
    const choiceIds = state.answersByQuestion.get(q.id) ?? [];
    if (choiceIds.length === 0) return;
    const attemptIdForQ = state.attemptIdByQuestionId.get(q.id);
    if (!attemptIdForQ) return;

    setState((s) => ({ ...s, submitting: true, error: null }));
    try {
      const res = await backend.submitAnswer(attemptIdForQ, {
        attemptQuestionId: q.id,
        choiceIds,
      });
      setState((s) => ({ ...s, submitting: false, lastResult: res }));
    } catch (e) {
      const msg = e instanceof ApiException ? e.message : "Erreur lors de la soumission.";
      setState((s) => ({ ...s, submitting: false, error: msg }));
    }
  }, [backend, state.questions, state.currentIndex, state.answersByQuestion, state.attemptIdByQuestionId]);

  const extendBatch = useCallback(async () => {
    if (!infinite || !extensionParams || !backend.extend) return false;
    setState((s) => ({ ...s, extending: true, error: null }));
    try {
      const newAttempt = await backend.extend({
        type: "TRAINING",
        module: extensionParams.module,
        themeId: extensionParams.themeId,
        size: extensionParams.batchSize,
      });
      if (newAttempt.questions.length === 0) {
        setState((s) => ({ ...s, extending: false, noMoreQuestions: true }));
        return false;
      }
      setState((s) => {
        const mergedQuestions = [...s.questions, ...newAttempt.questions];
        const mergedMapping = new Map(s.attemptIdByQuestionId);
        for (const q of newAttempt.questions) {
          mergedMapping.set(q.id, newAttempt.id);
        }
        return {
          ...s,
          extending: false,
          activeAttempt: newAttempt,
          questions: mergedQuestions,
          attemptIdByQuestionId: mergedMapping,
        };
      });
      return true;
    } catch (e) {
      const msg = e instanceof ApiException ? e.message : "Erreur lors du chargement.";
      setState((s) => ({ ...s, extending: false, error: msg }));
      return false;
    }
  }, [infinite, extensionParams, backend]);

  const finishCurrentAttempt = useCallback(async () => {
    setState((s) => ({ ...s, submitting: true, error: null }));
    try {
      const finalAttempt = await backend.finish(state.activeAttempt.id);
      setState((s) => ({ ...s, submitting: false, activeAttempt: finalAttempt }));
      onCompleted(finalAttempt);
    } catch (e) {
      const msg = e instanceof ApiException ? e.message : "Erreur lors de la finalisation.";
      setState((s) => ({ ...s, submitting: false, error: msg }));
    }
  }, [backend, state.activeAttempt.id, onCompleted]);

  // Quitter un examen autonome : avertit puis finalise (le reste compte 0) et
  // montre le résultat — on ne laisse jamais un examen « en cours ».
  const [quitConfirmOpen, setQuitConfirmOpen] = useState(false);
  const confirmQuit = useCallback(() => {
    setQuitConfirmOpen(false);
    void finishCurrentAttempt();
  }, [finishCurrentAttempt]);

  // ============== TIMER (mode exam) ==============
  // Calcule le temps restant à partir de startedAt + timeLimitSeconds. Tient
  // donc compte de la durée déjà écoulée si l'utilisateur recharge la page —
  // le serveur reste source de vérité, on s'aligne dessus à chaque mount.
  const timerActive = mode === "exam" && typeof timeLimitSeconds === "number";
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const timeoutFired = useRef(false);

  useEffect(() => {
    if (!timerActive) return;
    const startMs = startedAt ? Date.parse(startedAt) : Date.now();
    const tick = () => {
      const elapsed = (Date.now() - startMs) / 1000;
      const left = Math.max(0, Math.floor(timeLimitSeconds! - elapsed));
      setSecondsLeft(left);
      if (left <= 0 && !timeoutFired.current) {
        timeoutFired.current = true;
        void finishCurrentAttempt();
      }
    };
    tick();
    const id = window.setInterval(tick, 1000);
    return () => window.clearInterval(id);
  }, [timerActive, timeLimitSeconds, startedAt, finishCurrentAttempt]);

  const goNext = useCallback(async () => {
    if (state.currentIndex >= state.questions.length - 1) {
      // Dernière question : extension (infini) ou finalisation
      if (infinite && !state.noMoreQuestions && !state.extending) {
        const extended = await extendBatch();
        if (!extended) return;
        setState((s) => ({
          ...s,
          currentIndex: s.currentIndex + 1,
          lastResult: null,
        }));
      } else {
        await finishCurrentAttempt();
      }
      return;
    }
    setState((s) => ({
      ...s,
      currentIndex: s.currentIndex + 1,
      lastResult: null,
      error: null,
    }));
  }, [state.currentIndex, state.questions.length, state.noMoreQuestions, state.extending, infinite, extendBatch, finishCurrentAttempt]);

  // En examen, une question de compréhension orale passée ne peut pas être
  // revisitée (audio à écoute unique, comme le jour J) : retour bloqué tant
  // que la question précédente est une CO. En entraînement, navigation libre.
  const prevQuestion =
    state.currentIndex > 0 ? state.questions[state.currentIndex - 1] : undefined;
  const canGoPrevious =
    state.currentIndex > 0 &&
    !(
      mode === "exam" &&
      prevQuestion !== undefined &&
      (prevQuestion.question.questionType === "CO" ||
        prevQuestion.question.questionType === "CO_IMAGE")
    );

  const goPrevious = useCallback(() => {
    if (!canGoPrevious) return;
    setState((s) => ({
      ...s,
      currentIndex: s.currentIndex - 1,
      lastResult: null,
      error: null,
    }));
  }, [canGoPrevious]);

  // En exam, "Suivant" doit aussi soumettre la réponse silencieusement.
  const onClickNext = useCallback(async () => {
    if (mode === "exam" && selected.length > 0) {
      await submitCurrent();
    }
    await goNext();
  }, [mode, selected.length, submitCurrent, goNext]);

  const toggleFavorite = useCallback(async () => {
    if (!current || !backend.toggleFavorite) return;
    const qid = current.question.id;
    const wasFav = state.favoriteIds.has(qid);
    // Optimistic
    setState((s) => {
      const next = new Set(s.favoriteIds);
      if (wasFav) next.delete(qid);
      else next.add(qid);
      return { ...s, favoriteIds: next };
    });
    try {
      await backend.toggleFavorite(qid, wasFav);
    } catch {
      // Rollback silencieux
      setState((s) => {
        const reverted = new Set(s.favoriteIds);
        if (wasFav) reverted.add(qid);
        else reverted.delete(qid);
        return { ...s, favoriteIds: reverted };
      });
    }
  }, [backend, current, state.favoriteIds]);

  // Prefetch du batch suivant dès qu'on entre sur l'avant-dernière question
  // en mode infinite, pour que le passage soit instantané.
  const prefetchedRef = useRef<string | null>(null);
  useEffect(() => {
    if (!infinite || state.noMoreQuestions || state.extending) return;
    const isOnLast = state.currentIndex >= state.questions.length - 1;
    const prefetchKey = `${state.activeAttempt.id}:${state.currentIndex}`;
    if (isOnLast && hasFeedback && prefetchedRef.current !== prefetchKey) {
      prefetchedRef.current = prefetchKey;
      void extendBatch();
    }
  }, [infinite, state.noMoreQuestions, state.extending, state.currentIndex, state.questions.length, state.activeAttempt.id, hasFeedback, extendBatch]);

  // ============== RACCOURCIS CLAVIER ==============

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      // Ignore si focus dans un input/textarea (pour ne pas casser les formulaires éventuels)
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA")) return;

      if (!current) return;

      // Écran d'intro de partie : Entrée/→ démarre la partie, le reste est inerte.
      if (showSectionIntro) {
        if (e.key === "Enter" || e.key === "ArrowRight") {
          e.preventDefault();
          dismissSectionIntro();
        }
        return;
      }

      if (["1", "2", "3", "4"].includes(e.key)) {
        const idx = Number(e.key) - 1;
        const choice = orderedChoices(current.question.choices)[idx];
        if (choice && !hasFeedback) {
          e.preventDefault();
          toggleChoice(choice.id);
        }
        return;
      }
      if (e.key === "Enter") {
        e.preventDefault();
        if (mode === "training" && !hasFeedback) {
          if (selected.length > 0) void submitCurrent();
        } else {
          void onClickNext();
        }
        return;
      }
      if (e.key === "ArrowRight") {
        e.preventDefault();
        if (mode === "training" && !hasFeedback) {
          if (selected.length > 0) void submitCurrent();
        } else {
          void onClickNext();
        }
        return;
      }
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        goPrevious();
        return;
      }
      if ((e.key === "b" || e.key === "B") && favoritesEnabled) {
        e.preventDefault();
        void toggleFavorite();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [current, hasFeedback, mode, selected.length, submitCurrent, onClickNext, goPrevious, toggleFavorite, toggleChoice, favoritesEnabled, showSectionIntro, dismissSectionIntro]);

  if (!current) {
    return (
      <div className="qr-empty">
        Aucune question disponible.
        <style>{styles}</style>
      </div>
    );
  }

  const q = current.question;
  // CO_IMAGE : image affichée + propositions lues en audio, choix réduits à des
  // lettres A→D. On force le rendu en pastilles-lettres (texte masqué) sur tout
  // ce type, en plus de la détection par label déjà en place pour le FULL_AUDIO.
  const isCoImage = q.questionType === "CO_IMAGE";
  // CO en examen : audio lancé automatiquement, une seule écoute, pas de
  // contrôles (cf. MediaView examAudio). En entraînement, lecteur libre.
  const examCoAudio =
    mode === "exam" && (q.questionType === "CO" || isCoImage);
  const correctIds = state.lastResult?.correctChoiceIds ?? [];
  const isCorrect = state.lastResult?.correct === true;
  const showCorrection = mode === "training" && hasFeedback;
  const progressLabel = totalForUI
    ? `${state.currentIndex + 1} / ${totalForUI}`
    : `${state.currentIndex + 1}`;
  const progressPct = totalForUI ? ((state.currentIndex + 1) / totalForUI) * 100 : null;

  return (
    <section className="qr">
      <div className="qr-frame">
        {/* TOP BAR */}
        <div className="qr-topbar">
          {quitMode === "confirmFinish" ? (
            <button
              type="button"
              className="qr-x"
              aria-label="Quitter"
              onClick={() => setQuitConfirmOpen(true)}
            >
              ✕
            </button>
          ) : (
            <Link href={quitHref} className="qr-x" aria-label="Quitter">
              ✕
            </Link>
          )}
          <div className="qr-topbar-center">
            <span className="eyebrow">{eyebrow}</span>
            <span className="qr-count">
              Question {state.currentIndex + 1}
              {timerActive && totalForUI ? ` / ${totalForUI}` : ""}
            </span>
          </div>
          <div className="qr-topbar-actions">
            {favoritesEnabled && (
              <button
                type="button"
                className={`qr-bookmark ${isCurrentFavorite ? "is-on" : ""}`}
                onClick={toggleFavorite}
                aria-label={isCurrentFavorite ? "Retirer des favoris" : "Ajouter aux favoris"}
                title="Favori (B)"
              >
                {isCurrentFavorite ? <BookmarkFilled /> : <BookmarkOutline />}
              </button>
            )}
            {timerActive && secondsLeft !== null ? (
              <ExamTimerBadge secondsLeft={secondsLeft} />
            ) : (
              <span className="qr-progress">{progressLabel}</span>
            )}
          </div>
        </div>

        {/* PROGRESS BAR */}
        <div className="qr-progressbar">
          {progressPct !== null ? (
            <div className="qr-progressbar-fill" style={{ width: `${progressPct}%` }} />
          ) : state.extending ? (
            <div className="qr-progressbar-indeterminate" />
          ) : null}
        </div>

        {showSectionIntro && currentSection ? (
          /* INTRO DE PARTIE — l'examen est sectionné par épreuve : on annonce
             la partie qui commence. Le chrono (global) continue de tourner. */
          <div className="qr-intermission">
            <div className="qr-intermission-ico" aria-hidden>
              {currentSection.icon}
            </div>
            <div className="qr-intermission-part">
              {multiSection
                ? `PARTIE ${sectionIndex + 1} / ${sectionList!.length}`
                : eyebrow}
            </div>
            <h2 className="qr-intermission-title">{currentSection.label}</h2>
            <p className="qr-intermission-meta">
              {currentSection.count} question{currentSection.count > 1 ? "s" : ""}
              {multiSection
                ? sectionIndex < sectionList!.length - 1
                  ? ` · la suite : ${sectionList![sectionIndex + 1].label.toLowerCase()}`
                  : " · dernière partie"
                : timerActive && typeof timeLimitSeconds === "number"
                  ? ` · ${Math.round(timeLimitSeconds / 60)} min`
                  : ""}
            </p>
            <button
              type="button"
              className="btn btn-blue btn-lg"
              onClick={dismissSectionIntro}
            >
              {sectionIndex === 0 ? "Commencer →" : "Continuer →"}
            </button>
          </div>
        ) : (
          <>
        {/* BANDEAU DE PARTIE (examen multi-parties) */}
        {multiSection && currentSection && (
          <div className="qr-section">
            <span className="qr-section-ico" aria-hidden>
              {currentSection.icon}
            </span>
            <span className="qr-section-label">{currentSection.label}</span>
            <span className="qr-section-pos">
              Partie {sectionIndex + 1}/{sectionList!.length} ·{" "}
              {state.currentIndex - currentSection.startIndex + 1}/{currentSection.count}
            </span>
          </div>
        )}

        {/* TAGS */}
        <div className="qr-tags">
          <span className="qr-tag qr-tag-red">{q.difficulty}</span>
          {!multiSection && (
            <span className="qr-tag qr-tag-blue">{questionTypeLabel(q.questionType)}</span>
          )}
          <span className="qr-tag-theme">{q.themeName}</span>
        </div>

        {/* PASSAGE */}
        {q.passageText && (
          <div className="qr-passage">
            <div className="qr-passage-head">
              <span aria-hidden>📖</span>
              <span>Document à lire</span>
            </div>
            <div className="qr-passage-body">{q.passageText}</div>
          </div>
        )}

        {/* MEDIA — image (CO_IMAGE) ou audio/svg/vidéo classique */}
        {q.media && (
          <div className="qr-media">
            <MediaView key={q.id} media={q.media} examAudio={examCoAudio} />
          </div>
        )}

        {/* AUDIO CO_IMAGE — intro + 4 propositions lues, sous l'image */}
        {q.audioMedia && (
          <div className="qr-media">
            <MediaView key={`${q.id}-audio`} media={q.audioMedia} examAudio={examCoAudio} />
          </div>
        )}

        {/* STATEMENT / CONSIGNE */}
        <h2 className="qr-statement">
          {isCoImage
            ? q.statement || "Écoutez les propositions et choisissez celle qui correspond à l'image."
            : q.statement}
        </h2>

        {/* CHOICES */}
        <div className="qr-options" role="radiogroup">
          {orderedChoices(q.choices).map((c, i) => {
            // TCF CO en mode FULL_AUDIO : le contenu de la réponse est dans
            // l'audio, le label se réduit à une lettre ("A" ou "Réponse A") qui
            // est la clé de réponse citée par l'explication. On affiche cette
            // lettre dans la pastille et on masque le texte redondant ; les choix
            // sont déjà triés A→D par orderedChoices.
            const letterMatch = /^(?:r[ée]ponse\s+)?([A-D])$/i.exec(c.label.trim());
            // En CO_IMAGE le texte des choix vit dans l'audio : on masque le
            // label dans tous les cas et on pose la lettre par position.
            const letterOnly = isCoImage || letterMatch !== null;
            const letter = letterMatch
              ? letterMatch[1].toUpperCase()
              : String.fromCharCode(65 + i);
            const isSel = selected.includes(c.id);
            const isThisCorrect = showCorrection && correctIds.includes(c.id);
            const isWrongPick = showCorrection && isSel && !isCorrect;
            const cls = [
              "qr-opt",
              isSel && !hasFeedback ? "is-sel" : "",
              isThisCorrect ? "is-correct" : "",
              isWrongPick ? "is-wrong" : "",
            ]
              .filter(Boolean)
              .join(" ");

            return (
              <button
                type="button"
                key={c.id}
                className={cls}
                role="radio"
                aria-checked={isSel}
                onClick={() => toggleChoice(c.id)}
                disabled={state.submitting || hasFeedback}
              >
                <span className="qr-opt-letter">{letter}</span>
                <span className="qr-opt-label">{letterOnly ? "" : c.label}</span>
                {isThisCorrect && (
                  <span className="qr-opt-icon" aria-hidden>
                    <CheckIcon />
                  </span>
                )}
                {isWrongPick && (
                  <span className="qr-opt-icon qr-opt-icon-x" aria-hidden>
                    ✕
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* EXPLANATION */}
        {showCorrection && (
          <div className={`qr-explain ${isCorrect ? "good" : "bad"}`}>
            <div className="qr-explain-head">
              <span className="qr-explain-title">
                {isCorrect ? "✓ Bonne réponse" : "✗ Mauvaise réponse"}
              </span>
              <span className="qr-explain-tag">EXPLICATION</span>
            </div>
            {state.lastResult?.explanation && <p>{state.lastResult.explanation}</p>}
          </div>
        )}

        {state.error && (
          <div className="qr-error" role="alert">
            {state.error}
          </div>
        )}

        {/* BOTTOM BAR */}
        <div className="qr-actions">
          {mode === "training" && !hasFeedback ? (
            <button
              type="button"
              className="btn btn-blue btn-lg qr-btn-full"
              onClick={submitCurrent}
              disabled={selected.length === 0 || state.submitting}
            >
              {state.submitting ? "..." : "Valider ma réponse"}
            </button>
          ) : (
            <div className="qr-actions-row">
              {canGoPrevious && !infinite && (
                <button
                  type="button"
                  className="btn btn-ghost qr-btn-half"
                  onClick={goPrevious}
                  disabled={state.submitting || state.extending}
                >
                  ← Précédent
                </button>
              )}
              <button
                type="button"
                className="btn btn-blue btn-lg qr-btn-full"
                onClick={onClickNext}
                disabled={
                  state.submitting ||
                  state.extending ||
                  (mode === "exam" && selected.length === 0)
                }
              >
                {state.extending
                  ? "Chargement…"
                  : isLast && (!infinite || state.noMoreQuestions)
                    ? "Voir le résultat"
                    : isSectionEnd
                      ? "Partie suivante →"
                      : "Question suivante →"}
              </button>
            </div>
          )}
        </div>

        {/* Astuce raccourcis (discret) */}
        <div className="qr-tips" aria-hidden>
          <span>1-4</span> choix · <span>Entrée</span> valider · <span>←/→</span> nav
          {favoritesEnabled && <> · <span>B</span> favori</>}
        </div>
          </>
        )}
      </div>

      <ConfirmSheet
        open={quitConfirmOpen}
        tone="warning"
        title="Quitter l'examen ?"
        message="Si vous quittez maintenant, l'examen est finalisé : les questions non répondues sont comptées comme fausses. Vous verrez votre résultat. Cette action est définitive."
        confirmLabel="Quitter et voir le résultat"
        cancelLabel="Continuer l'examen"
        onConfirm={confirmQuit}
        onClose={() => setQuitConfirmOpen(false)}
      />

      <style>{styles}</style>
    </section>
  );
}

// ============================================================================
// Icônes inline (évite les dépendances externes)
// ============================================================================

function ExamTimerBadge({ secondsLeft }: { secondsLeft: number }) {
  const m = Math.floor(secondsLeft / 60).toString().padStart(2, "0");
  const s = (secondsLeft % 60).toString().padStart(2, "0");
  const urgent = secondsLeft <= 300; // dernières 5 minutes
  return (
    <span className={`qr-timer ${urgent ? "is-urgent" : ""}`} aria-live="polite">
      <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="13" r="8" />
        <path d="M12 9v4l2 2M9 3h6" />
      </svg>
      <span className="qr-timer-value">{m}:{s}</span>
    </span>
  );
}

function BookmarkOutline() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
    </svg>
  );
}

function BookmarkFilled() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
      <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
    </svg>
  );
}

function CheckIcon() {
  return (
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
  );
}

// ============================================================================
// STYLES
// ============================================================================

const styles = `
  .qr-empty { padding: 80px 20px; text-align: center; color: var(--color-muted); }

  .qr { padding: 24px 16px 48px; }
  .qr-frame {
    max-width: 720px; margin: 0 auto;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px 28px 24px;
    box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.18);
  }

  .qr-topbar {
    display: flex; align-items: center; justify-content: space-between;
    padding-bottom: 14px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 0;
    gap: 12px;
  }
  .qr-x {
    text-decoration: none; color: var(--color-ink);
    width: 34px; height: 34px;
    display: inline-flex; align-items: center; justify-content: center;
    font-size: 18px;
    border-radius: 8px;
    flex-shrink: 0;
    background: none; border: none; cursor: pointer;
    font-family: inherit;
  }
  .qr-x:hover { background: var(--color-paper-2); }
  .qr-topbar-center { display: flex; flex-direction: column; align-items: center; flex: 1; min-width: 0; }
  .qr-count {
    font-family: var(--font-sans); font-weight: 700; font-size: 15px;
    margin-top: 2px;
  }
  .qr-topbar-actions { display: inline-flex; align-items: center; gap: 12px; flex-shrink: 0; }
  .qr-bookmark {
    width: 34px; height: 34px;
    display: inline-flex; align-items: center; justify-content: center;
    border-radius: 8px;
    background: none; border: none;
    color: var(--color-ink);
    cursor: pointer;
    transition: all 0.15s;
  }
  .qr-bookmark:hover { background: var(--color-paper-2); }
  .qr-bookmark.is-on { color: var(--color-red); }
  .qr-progress {
    font-family: var(--font-mono); font-size: 11.5px;
    color: var(--color-muted); letter-spacing: 0.06em;
    min-width: 50px; text-align: right;
  }

  .qr-timer {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 6px 10px;
    background: var(--color-blue-light);
    color: var(--color-blue);
    border: 1px solid rgba(30, 58, 140, 0.2);
    border-radius: 8px;
    font-family: var(--font-mono);
    font-size: 12.5px; font-weight: 700;
    letter-spacing: 0.05em;
    transition: background 0.18s, color 0.18s, border-color 0.18s;
  }
  .qr-timer.is-urgent {
    background: var(--color-red-light);
    color: var(--color-red);
    border-color: rgba(225, 55, 47, 0.32);
    animation: qr-timer-pulse 1.4s ease-in-out infinite;
  }
  @keyframes qr-timer-pulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(225, 55, 47, 0); }
    50% { box-shadow: 0 0 0 4px rgba(225, 55, 47, 0.18); }
  }
  .qr-timer-value { line-height: 1; }

  .qr-progressbar {
    height: 3px;
    background: var(--color-line-2);
    margin: 12px -28px 18px;
    position: relative;
    overflow: hidden;
  }
  .qr-progressbar-fill {
    height: 100%;
    background: var(--color-blue);
    transition: width 0.25s ease;
  }
  .qr-progressbar-indeterminate {
    position: absolute; inset: 0;
    background: linear-gradient(90deg,
      transparent 0%,
      var(--color-blue) 50%,
      transparent 100%);
    animation: qr-shimmer 1.4s linear infinite;
  }
  @keyframes qr-shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }

  .qr-section {
    display: flex; align-items: center; gap: 8px;
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.12);
    border-radius: 10px;
    padding: 8px 12px;
    margin-bottom: 12px;
  }
  .qr-section-ico { font-size: 15px; line-height: 1; flex-shrink: 0; }
  .qr-section-label {
    flex: 1; min-width: 0;
    font-weight: 700; font-size: 13px; color: var(--color-blue);
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .qr-section-pos {
    flex-shrink: 0;
    font-family: var(--font-mono); font-size: 10.5px; font-weight: 600;
    letter-spacing: 0.06em; color: var(--color-muted);
  }

  .qr-intermission {
    display: flex; flex-direction: column; align-items: center;
    text-align: center;
    padding: 48px 16px 56px;
  }
  .qr-intermission-ico { font-size: 44px; line-height: 1; margin-bottom: 18px; }
  .qr-intermission-part {
    font-family: var(--font-mono); font-size: 10.5px; font-weight: 700;
    letter-spacing: 0.16em; text-transform: uppercase; color: var(--color-blue);
    margin-bottom: 8px;
  }
  .qr-intermission-title {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(24px, 4vw, 30px); line-height: 1.15;
    letter-spacing: -0.02em; color: var(--color-ink);
    margin: 0 0 8px;
  }
  .qr-intermission-meta {
    font-size: 14px; color: var(--color-muted);
    margin: 0 0 26px;
  }

  .qr-tags { display: flex; gap: 6px; align-items: center; margin-bottom: 14px; flex-wrap: wrap; }
  .qr-tag {
    padding: 4px 10px;
    border-radius: 6px;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.1em; font-weight: 600;
    border: 1px solid;
  }
  .qr-tag-red { background: var(--color-red-light); color: var(--color-red); border-color: rgba(225, 55, 47, 0.3); }
  .qr-tag-blue { background: var(--color-blue-light); color: var(--color-blue); border-color: rgba(30, 58, 140, 0.3); }
  .qr-tag-theme {
    margin-left: auto;
    font-family: var(--font-mono); font-size: 10px;
    color: var(--color-muted); letter-spacing: 0.08em;
    text-transform: uppercase;
    max-width: 60%;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }

  .qr-passage {
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.15);
    border-radius: 10px;
    padding: 12px 14px;
    margin: 0 0 14px;
  }
  .qr-passage-head {
    display: flex; align-items: center; gap: 6px;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 8px;
  }
  .qr-passage-body {
    font-size: 14px; line-height: 1.6;
    color: var(--color-ink-2); white-space: pre-wrap;
  }

  .qr-media { margin: 0 0 14px; }

  .qr-statement {
    font-family: var(--font-display); font-weight: 600;
    font-size: 22px; line-height: 1.35; letter-spacing: -0.005em;
    color: var(--color-ink); margin: 0 0 20px;
  }

  .qr-options { display: flex; flex-direction: column; gap: 8px; margin-bottom: 16px; }
  .qr-opt {
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 12px;
    padding: 13px 14px;
    display: flex; align-items: center; gap: 12px;
    font-family: var(--font-sans);
    font-size: 14.5px; color: var(--color-ink-2);
    text-align: left;
    cursor: pointer;
    transition: all 0.15s;
    width: 100%;
  }
  .qr-opt:hover:not(:disabled) { border-color: var(--color-blue); background: var(--color-blue-soft); }
  .qr-opt:disabled { cursor: default; }
  .qr-opt-letter {
    width: 28px; height: 28px;
    border-radius: 50%;
    background: var(--color-line-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 12px; font-weight: 600;
    flex-shrink: 0;
  }
  .qr-opt-label { flex: 1; }
  .qr-opt-icon { display: inline-flex; align-items: center; }
  .qr-opt-icon-x { color: var(--color-red); font-weight: 700; font-size: 15px; }
  .qr-opt.is-sel { border-color: var(--color-blue); background: var(--color-blue-light); }
  .qr-opt.is-sel .qr-opt-letter { background: var(--color-blue); color: #fff; }
  .qr-opt.is-correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.06);
    box-shadow: 0 0 0 1px var(--color-green);
  }
  .qr-opt.is-correct .qr-opt-letter { background: rgba(22, 143, 91, 0.15); color: var(--color-green); }
  .qr-opt.is-correct .qr-opt-icon { color: var(--color-green); }
  .qr-opt.is-wrong {
    border-color: var(--color-red);
    background: rgba(225, 55, 47, 0.05);
    box-shadow: 0 0 0 1px var(--color-red);
  }
  .qr-opt.is-wrong .qr-opt-letter { background: rgba(225, 55, 47, 0.15); color: var(--color-red); }

  .qr-explain {
    border-radius: 12px;
    padding: 14px 16px;
    margin-bottom: 16px;
    border: 1px solid;
  }
  .qr-explain.good { background: rgba(22, 143, 91, 0.06); border-color: rgba(22, 143, 91, 0.25); }
  .qr-explain.bad { background: rgba(225, 55, 47, 0.05); border-color: rgba(225, 55, 47, 0.25); }
  .qr-explain-head {
    display: flex; align-items: center; justify-content: space-between;
    margin-bottom: 6px;
  }
  .qr-explain.good .qr-explain-title { color: var(--color-green); }
  .qr-explain.bad .qr-explain-title { color: var(--color-red); }
  .qr-explain-title { font-family: var(--font-sans); font-weight: 700; font-size: 14px; }
  .qr-explain-tag {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.14em; font-weight: 600;
    background: rgba(0,0,0,0.06);
    padding: 2px 8px; border-radius: 4px;
  }
  .qr-explain.good .qr-explain-tag { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .qr-explain.bad .qr-explain-tag { background: rgba(225, 55, 47, 0.12); color: var(--color-red); }
  .qr-explain p { font-size: 13.5px; line-height: 1.5; color: var(--color-ink-2); margin: 0; }

  .qr-error {
    background: var(--color-red-light);
    border: 1px solid rgba(225, 55, 47, 0.3);
    color: var(--color-red);
    border-radius: 10px;
    padding: 10px 12px;
    margin-bottom: 14px;
    font-size: 13px;
  }

  .qr-actions { margin-top: 8px; }
  .qr-actions-row { display: flex; gap: 10px; }
  .qr-btn-full { width: 100%; }
  .qr-btn-half { flex: 1; }
  .qr-actions-row .qr-btn-full { flex: 2; }

  .btn-blue {
    background: var(--color-blue); color: #fff;
    border: none; border-radius: 12px;
    padding: 14px 22px; font-size: 15px; font-weight: 700;
    font-family: var(--font-sans);
    cursor: pointer; transition: background 0.15s;
    display: flex; align-items: center; justify-content: center; gap: 8px;
  }
  .btn-blue:hover:not(:disabled) { background: var(--color-blue-dark); }
  .btn-blue:disabled { opacity: 0.5; cursor: not-allowed; }

  .qr-tips {
    text-align: center;
    font-family: var(--font-mono); font-size: 10px;
    color: var(--color-muted-2); letter-spacing: 0.08em;
    margin-top: 16px;
  }
  .qr-tips span {
    background: var(--color-paper-2);
    color: var(--color-muted);
    padding: 1px 6px; border-radius: 4px;
    margin: 0 2px;
    font-weight: 600;
  }

  @media (max-width: 720px) {
    .qr { padding: 16px 12px 40px; }
    .qr-frame { padding: 18px 18px 20px; border-radius: 14px; }
    .qr-progressbar { margin: 10px -18px 16px; }
    .qr-statement { font-size: 19px; }
    .qr-tips { display: none; }
    .qr-tag-theme { display: none; }
  }
`;
