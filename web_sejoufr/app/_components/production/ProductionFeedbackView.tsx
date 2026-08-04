"use client";

import {
  AlertTriangle,
  ArrowRight,
  Check,
  Info,
  Lightbulb,
  Quote,
  Target,
  ThumbsUp,
} from "lucide-react";
import {
  bandeCritereLabel,
  formatNoteSur20,
  parseEeFeedback,
  type EeAccomplishmentPoint,
  type EeCriterion,
  type EePriority,
  type EvaluationResultDto,
} from "@/lib/types";
import {ProductionScoreHero} from "./ProductionScoreHero";
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
 * 1. niveau observé sur la tâche + note /20 ({@link ProductionScoreHero}, qui
 *    porte le garde-fou « jamais de niveau sans confiance ») ;
 * 2. ce que l'évaluation ne couvre pas (avertissements), visible et non alarmant ;
 * 3. check-list d'accomplissement, en distinguant points exigés et simples pistes ;
 * 4. critères en BANDES (une IA ne distingue pas honnêtement un 13 d'un 14),
 *    avec la citation de la production qui justifie le jugement ;
 * 5. points forts, 2 priorités qui ENSEIGNENT (constat → technique → avant/après),
 *    suggestions, reformulations et ce qu'elles démontrent.
 *
 * Une évaluation antérieure n'a ni niveau, ni confiance, ni accomplissement, ni
 * bandes, et ses priorités sont de simples chaînes sans technique ni exemple :
 * les blocs concernés ne sont pas rendus et les critères retombent sur
 * l'affichage chiffré historique. C'est un cas normal, jamais une erreur.
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
  // Les évaluations les plus anciennes ne portent pas l'avertissement de
  // transcription : on garde le rappel écrit côté front pour ne pas le perdre.
  const notices =
    fb.avertissements.length > 0
      ? fb.avertissements
      : isOral
        ? [TRANSCRIPTION_LIMIT]
        : [];

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 16}}>
      <ProductionScoreHero
        noteSurVingt={fb.noteGlobale}
        niveau={evaluation.niveauObserve}
        confiance={fb.confiance}
        avertissementNiveau={evaluation.avertissementNiveau}
        confianceRaisons={fb.confianceRaisons}
      />

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
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            <Target size={16} strokeWidth={2.2} color="var(--color-amber)" />
            {fb.pointsAAmeliorer.length > 1 ? "Vos priorités" : "Votre priorité"}
          </p>
          <p className={styles.fbHint}>
            À travailler en premier pour progresser sur cette tâche.
          </p>
          <ol className={styles.prioList}>
            {fb.pointsAAmeliorer.map((p, i) => (
              <PriorityItem key={i} rank={i + 1} priority={p} />
            ))}
          </ol>
        </div>
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
              {e.gain && (
                <p className={styles.corrGain}>
                  <span className={styles.corrGainTag}>Ce que ça démontre</span>
                  {e.gain}
                </p>
              )}
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

/**
 * Une priorité qui enseigne : le constat, puis la technique réutilisable, puis
 * sa démonstration sur une phrase du candidat. `comment` et `exemple` sont
 * absents des évaluations déjà en base (priorité réduite à une chaîne) — la
 * ligne se rend alors comme un simple constat.
 */
function PriorityItem({rank, priority: p}: {rank: number; priority: EePriority}) {
  return (
    <li className={styles.prio}>
      <span className={styles.prioRank} aria-hidden>
        {rank}
      </span>
      <div className={styles.prioBody}>
        <p className={styles.prioConstat}>{p.constat}</p>
        {p.comment && (
          <p className={styles.prioHow}>
            <span className={styles.prioHowTag}>Comment faire</span>
            {p.comment}
          </p>
        )}
        {p.exemple && (
          <div className={styles.prioExample}>
            <p className={styles.prioBefore}>
              <span className={styles.prioExampleTag}>Votre phrase</span>
              {p.exemple.avant}
            </p>
            <p className={styles.prioAfter}>
              <span className={styles.prioExampleTag}>
                <ArrowRight size={11} strokeWidth={2.6} aria-hidden />
                Réécrite
              </span>
              {p.exemple.apres}
            </p>
          </div>
        )}
      </div>
    </li>
  );
}

/** Bande qualitative, ou à défaut l'affichage chiffré des évaluations
 *  antérieures (qui ne portent pas de bande). */
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
              {formatNoteSur20(c.noteSurVingt)}/20
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
}: {
  title: string;
  icon: React.ReactNode;
  items: string[];
  dot: string;
}) {
  return (
    <div className={styles.card}>
      <p className={styles.fbTitle}>
        {icon}
        {title}
      </p>
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
