"use client";

import {Check, Sparkles, Target, ThumbsUp, X} from "lucide-react";
import {parseEeFeedback, type EePriority, type EvaluationResultDto} from "@/lib/types";
import {FeedbackList} from "./FeedbackList";
import {ProductionFullAnalysis} from "./ProductionFullAnalysis";
import {ProductionObjectiveBanner} from "./ProductionObjectiveBanner";
import {ProductionScoreHero} from "./ProductionScoreHero";
import styles from "./production.module.css";

const TRANSCRIPTION_LIMIT =
  "Cette évaluation est fondée sur la transcription écrite de votre production : nous " +
  "n'analysons pas votre voix. L'aisance, la fluidité, le débit et la prononciation ne sont " +
  "donc pas évalués ici — c'est une limite technique de notre correction, pas un choix " +
  "pédagogique. À l'examen officiel, ces dimensions comptent.";

/**
 * Restitution d'une production EE/EO. Ce n'est pas un rapport d'expertise pour
 * un professeur : c'est ce dont un candidat a besoin, dans l'ordre où il en a
 * besoin, et une même erreur n'est expliquée qu'UNE fois.
 *
 * 1. **Objectif de la tâche** — a-t-il fait ce qu'on lui demandait ? Avant tout
 *    le reste, y compris la note ;
 * 2. **note + échelle du TCF** — notre note est une estimation exprimée sur
 *    l'échelle du TCF : montrer l'échelle est la seule façon d'empêcher qu'un
 *    4,5/20 (un A2) se lise comme une catastrophe. Porte les deux garde-fous
 *    niveau/confiance ;
 * 3. **points forts** (2 max) ;
 * 4. **priorités** (2 max) : constat → comment faire → avant/après ;
 * 5. **version améliorée** — sa production réécrite. EE seulement : on ne
 *    réécrit pas un oral, son absence en EO est voulue ;
 * 6. **analyse complète**, repliée : tout le reste, sans rien perdre.
 *
 * Une évaluation antérieure n'a ni verdict d'objectif, ni version améliorée, ni
 * bandes de critère, et ses priorités sont de simples chaînes : les blocs
 * concernés ne sont pas rendus. C'est un cas normal, jamais une erreur.
 */
export function ProductionFeedbackView({
  evaluation,
  isOral = false,
}: {
  evaluation: EvaluationResultDto;
  /** EO : `exemples_corriges` sont des reformulations de clarté (jamais de
   *  l'orthographe, filtrée serveur) — on relabellise la section en
   *  conséquence. EE : corrections classiques. */
  isOral?: boolean;
}) {
  const fb = parseEeFeedback(evaluation);
  // Les évaluations les plus anciennes ne portent pas l'avertissement de
  // transcription : on garde le rappel écrit côté front pour ne pas le perdre.
  const avertissements =
    fb.avertissements.length > 0 ? fb.avertissements : isOral ? [TRANSCRIPTION_LIMIT] : [];

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 16}}>
      <ProductionObjectiveBanner
        objectif={fb.accomplissement?.objectif ?? null}
        resume={fb.accomplissement?.objectifResume ?? null}
      />

      <ProductionScoreHero
        noteSurVingt={fb.noteGlobale}
        niveau={evaluation.niveauObserve}
        confiance={fb.confiance}
        avertissementNiveau={evaluation.avertissementNiveau}
        confianceRaisons={fb.confianceRaisons}
      />

      {fb.pointsForts.length > 0 && (
        <div className={styles.card}>
          <FeedbackList
            title="Points forts"
            icon={<ThumbsUp size={16} strokeWidth={2.2} color="var(--color-green)" />}
            items={fb.pointsForts}
            dot={styles.fbGood}
          />
        </div>
      )}

      {fb.pointsAAmeliorer.length > 0 && (
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            <Target size={16} strokeWidth={2.2} color="var(--color-amber)" />
            {fb.pointsAAmeliorer.length > 1 ? "Vos priorités" : "Votre priorité"}
          </p>
          <p className={styles.fbHint}>
            À travailler en premier lors de votre prochaine production — pas la
            peine de tout corriger d&apos;un coup.
          </p>
          <ol className={styles.prioList}>
            {fb.pointsAAmeliorer.map((p, i) => (
              <PriorityItem key={i} rank={i + 1} priority={p} />
            ))}
          </ol>
        </div>
      )}

      {fb.versionAmelioree && (
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            <Sparkles size={16} strokeWidth={2.2} color="var(--color-blue)" />
            Version améliorée
          </p>
          <p className={styles.fbHint}>
            Vos idées, réécrites comme elles auraient pu être rendues. Comparez
            avec votre texte : ce sont les mêmes idées, dites autrement.
          </p>
          <p className={styles.improved}>{fb.versionAmelioree}</p>
        </div>
      )}

      <ProductionFullAnalysis
        avertissements={avertissements}
        criteres={fb.criteres}
        accomplissement={fb.accomplissement}
        exemplesCorriges={fb.exemplesCorriges}
        suggestions={fb.suggestions}
        isOral={isOral}
      />
    </div>
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
              <span className={styles.prioExampleTag}>
                <X size={11} strokeWidth={3} aria-hidden />
                Votre phrase
              </span>
              {p.exemple.avant}
            </p>
            <p className={styles.prioAfter}>
              <span className={styles.prioExampleTag}>
                <Check size={11} strokeWidth={3} aria-hidden />
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
