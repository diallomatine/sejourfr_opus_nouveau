"use client";

import {
  AlertTriangle,
  Check,
  Info,
  Lightbulb,
  Quote,
  Target,
  ThumbsUp,
} from "lucide-react";
import {
  bandeCritereLabel,
  confianceLabel,
  niveauCecrlLabel,
  parseEeFeedback,
  type EeAccomplishmentPoint,
  type EeCriterion,
  type EvaluationResultDto,
} from "@/lib/types";
import {NoteScoreDonut} from "./NoteScoreDonut";
import styles from "./production.module.css";

const TRANSCRIPTION_LIMIT =
  "Cette évaluation est fondée sur la transcription écrite de votre production : nous " +
  "n'analysons pas votre voix. L'aisance, la fluidité, le débit et la prononciation ne sont " +
  "donc pas évalués ici — c'est une limite technique de notre correction, pas un choix " +
  "pédagogique. À l'examen officiel, ces dimensions comptent.";

/**
 * Rendu complet d'une évaluation IA d'une production (écrite ou orale), dans
 * l'ordre où le candidat en a besoin : ce qu'il a traité de la consigne, puis
 * seulement ensuite la langue.
 *
 * 1. note globale /20 (repère attendu d'un examen — elle, on la garde chiffrée) ;
 * 2. performance observée sur la tâche, JAMAIS sans sa confiance à côté ;
 * 3. ce que l'évaluation ne couvre pas (avertissements), visible et non alarmant ;
 * 4. check-list d'accomplissement, en distinguant points exigés et simples pistes ;
 * 5. critères en BANDES (une IA ne distingue pas honnêtement un 13 d'un 14),
 *    avec la citation de la production qui justifie le jugement ;
 * 6. points forts, 2 priorités, suggestions, corrections.
 *
 * Une évaluation antérieure à la notation v4 n'a ni niveau, ni confiance, ni
 * accomplissement, ni bandes : les blocs concernés ne sont pas rendus et les
 * critères retombent sur l'affichage chiffré historique. C'est un cas normal.
 */
export function ProductionFeedbackView({
  evaluation,
  isOral = false,
}: {
  evaluation: EvaluationResultDto;
  /** EO : `exemples_corriges` sont des reformulations de clarte (jamais de
   *  l'orthographe, filtree serveur) — on relabellise la section en
   *  consequence. EE : corrections classiques. */
  isOral?: boolean;
}) {
  const fb = parseEeFeedback(evaluation);
  const acc = fb.accomplissement;
  const accPoints = acc ? [...acc.pointsTraites, ...acc.pointsOublies] : [];
  const showLevel = evaluation.niveauObserve != null && fb.confiance != null;
  // Les évaluations d'avant la notation v4 ne portent pas l'avertissement de
  // transcription : on garde le rappel écrit côté front pour ne pas le perdre.
  const notices =
    fb.avertissements.length > 0
      ? fb.avertissements
      : isOral
        ? [TRANSCRIPTION_LIMIT]
        : [];

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 16}}>
      <NoteScoreDonut noteSurVingt={fb.noteGlobale} />

      {(showLevel || fb.confiance != null) && (
        <div className={styles.levelCard}>
          {showLevel && (
            <p className={styles.levelTitle}>
              Performance observée sur cette tâche :{" "}
              <strong className={styles.levelValue}>
                {evaluation.niveauObserve === "A1_NON_ATTEINT"
                  ? "niveau A1 non atteint"
                  : `proche du niveau ${niveauCecrlLabel(evaluation.niveauObserve)}`}
              </strong>
            </p>
          )}
          {fb.confiance != null && (
            <p className={styles.levelMeta}>
              <span className={styles.confChip} data-confiance={fb.confiance}>
                {confianceLabel(fb.confiance)}
              </span>
              {evaluation.avertissementNiveau && (
                <span className={styles.levelNote}>{evaluation.avertissementNiveau}</span>
              )}
            </p>
          )}
          {fb.confianceRaisons.length > 0 && (
            <ul className={styles.confList}>
              {fb.confianceRaisons.map((r, i) => (
                <li key={i}>{r}</li>
              ))}
            </ul>
          )}
        </div>
      )}

      {notices.length > 0 && (
        <div className={styles.limitsBox}>
          <p className={styles.limitsTitle}>
            <Info size={16} strokeWidth={2.2} aria-hidden /> À savoir sur cette évaluation
          </p>
          <ul className={styles.limitsList}>
            {notices.map((a, i) => (
              <li key={i}>{a}</li>
            ))}
          </ul>
        </div>
      )}

      {accPoints.length > 0 && acc && (
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            <Target size={16} strokeWidth={2.2} color="var(--color-blue)" aria-hidden />
            Ce que demandait la consigne
          </p>
          <ul className={styles.accList}>
            {acc.pointsTraites.map((p, i) => (
              <AccomplishmentItem key={`t${i}`} point={p} done />
            ))}
            {acc.pointsOublies.map((p, i) => (
              <AccomplishmentItem key={`o${i}`} point={p} done={false} />
            ))}
          </ul>
          {accPoints.some((p) => !p.obligatoire) && (
            <p className={styles.accFoot}>
              Les <strong>pistes</strong>{" "}
              sont des idées proposées par le sujet : ne pas les
              traiter n&apos;enlève aucun point.
            </p>
          )}
        </div>
      )}

      {fb.criteres.length > 0 && (
        <div className={styles.card}>
          <p className={styles.cardLabel}>Détail par critère</p>
          {fb.criteres.map((c, i) => (
            <CriterionRow key={c.code || i} criterion={c} />
          ))}
        </div>
      )}

      {fb.pointsForts.length > 0 && (
        <FeedbackList
          title="Points forts"
          icon={<ThumbsUp size={16} strokeWidth={2.2} color="var(--color-green)" />}
          items={fb.pointsForts}
          dot={styles.fbGood}
        />
      )}
      {fb.pointsAAmeliorer.length > 0 && (
        <FeedbackList
          title={fb.pointsAAmeliorer.length > 1 ? "Vos priorités" : "Votre priorité"}
          icon={<Target size={16} strokeWidth={2.2} color="var(--color-amber)" />}
          items={fb.pointsAAmeliorer}
          dot={styles.fbWarn}
          hint="À travailler en premier pour progresser sur cette tâche."
        />
      )}
      {fb.suggestions.length > 0 && (
        <FeedbackList
          title="Suggestions"
          icon={<Lightbulb size={16} strokeWidth={2.2} color="var(--color-blue)" />}
          items={fb.suggestions}
          dot={styles.fbInfo}
        />
      )}

      {fb.exemplesCorriges.length > 0 && (
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            {isOral ? (
              <Lightbulb size={16} strokeWidth={2.2} color="var(--color-blue)" />
            ) : (
              <AlertTriangle size={16} strokeWidth={2.2} color="var(--color-red)" />
            )}
            {isOral ? "Reformulations pour plus de clarté" : "Corrections"}
          </p>
          {fb.exemplesCorriges.map((e, i) => (
            <div key={i} className={styles.correction}>
              <div className={styles.corrLine}>
                {e.original && <span className={styles.corrOrig}>{e.original}</span>}
                {e.original && e.corrige ? "  →  " : ""}
                {e.corrige && <span className={styles.corrFix}>{e.corrige}</span>}
              </div>
              {e.explication && <p className={styles.corrExpl}>{e.explication}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/** Une ligne de la check-list : ✓ traité / ○ non traité, exigé ou simple piste. */
function AccomplishmentItem({point, done}: {point: EeAccomplishmentPoint; done: boolean}) {
  const state = done ? "done" : point.obligatoire ? "missing" : "skipped";
  return (
    <li className={styles.accItem}>
      <span className={styles.accIcon} data-state={state} aria-hidden>
        {done ? <Check size={13} strokeWidth={3.2} /> : null}
      </span>
      <span className={styles.accLabel}>{point.libelle}</span>
      <span className={styles.accTag} data-state={state}>
        {done
          ? point.obligatoire
            ? "demandé"
            : "piste explorée"
          : point.obligatoire
            ? "attendu par la consigne"
            : "piste non traitée · sans effet sur la note"}
      </span>
    </li>
  );
}

/** Bande qualitative (v4) ou, à défaut, l'affichage chiffré historique. */
function CriterionRow({criterion: c}: {criterion: EeCriterion}) {
  const legacyColor =
    c.noteSurVingt >= 14
      ? "var(--color-green)"
      : c.noteSurVingt >= 10
        ? "var(--color-amber)"
        : "var(--color-red)";

  return (
    <div className={styles.critRow}>
      <div className={styles.critBody}>
        <div className={styles.critTop}>
          <span className={styles.critLabel}>{c.label}</span>
          {c.bande ? (
            <span className={styles.critBande} data-band={c.bande}>
              {bandeCritereLabel(c.bande)}
            </span>
          ) : (
            <span className={styles.critNote} style={{color: legacyColor}}>
              {formatNote(c.noteSurVingt)}/20
            </span>
          )}
        </div>
        {c.bande ? (
          <span className={styles.critSteps} data-band={c.bande} aria-hidden>
            <span />
            <span />
            <span />
            <span />
          </span>
        ) : (
          <div className={styles.critTrack}>
            <div
              className={styles.critFill}
              style={{
                width: `${Math.max(0, Math.min(100, (c.noteSurVingt / 20) * 100))}%`,
                background: legacyColor,
              }}
            />
          </div>
        )}
        {c.commentaire && <p className={styles.critComment}>{c.commentaire}</p>}
        {c.preuve && (
          <p className={styles.critProof}>
            <Quote size={12} strokeWidth={2.4} aria-hidden />
            <span>{c.preuve}</span>
          </p>
        )}
      </div>
    </div>
  );
}

function FeedbackList({
  title,
  icon,
  items,
  dot,
  hint,
}: {
  title: string;
  icon: React.ReactNode;
  items: string[];
  dot: string;
  hint?: string;
}) {
  return (
    <div className={styles.card}>
      <p className={styles.fbTitle}>
        {icon}
        {title}
      </p>
      {hint && <p className={styles.fbHint}>{hint}</p>}
      <ul className={styles.fbList}>
        {items.map((it, i) => (
          <li key={i} className={styles.fbItem}>
            <span className={`${styles.fbBullet} ${dot}`} />
            {it}
          </li>
        ))}
      </ul>
    </div>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
