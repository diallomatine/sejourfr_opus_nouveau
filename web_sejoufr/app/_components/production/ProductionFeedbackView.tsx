"use client";

import {parseEeFeedback, type EvaluationResultDto} from "@/lib/types";
import {CriteriaOverview} from "./CriteriaOverview";
import {ProductionFullAnalysis} from "./ProductionFullAnalysis";
import {ProductionResultsHero} from "./ProductionResultsHero";
import {ProductionTextCard} from "./ProductionTextCard";
import {ResultsSummaryTiles} from "./ResultsSummaryTiles";
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
 * **Passe « rapport express »** — le contenu était juste, sa restitution
 * illisible : le candidat traversait un accusé de traitement, un bandeau
 * d'objectif, une carte de note, deux blocs de puces et trois paragraphes
 * d'explication avant le premier conseil. Personne ne lit ça. Rien n'a été
 * retiré : ce qui disait la même chose a été **fusionné**, ce qui se consulte a
 * été **replié**. Structure et gestes identiques au mobile
 * (`evaluation_report.dart`) et à la maquette « Rapport express ».
 *
 * Quatre sections :
 * 1. **le verdict, la note et le niveau** — un seul hero
 *    ({@link ProductionResultsHero}) ;
 * 2. **ce qui marche / à corriger en priorité** ({@link ResultsSummaryTiles}) :
 *    deux bandeaux d'une ligne, repliés, qui ouvrent leur détail en dessous —
 *    points traités et points forts d'un côté, la priorité **complète** de
 *    l'autre ;
 * 3. **le profil par critère** ({@link CriteriaOverview}), une carte par
 *    critère, dépliable — il vivait dans le repli, donc personne ne le voyait ;
 * 4. **la production**, avec sa version améliorée en bascule
 *    ({@link ProductionTextCard}).
 *
 * Puis « Voir l'analyse complète », repliée : avertissements, check-list de la
 * consigne, corrections, suggestions.
 *
 * Une évaluation antérieure n'a ni verdict d'objectif, ni version améliorée, ni
 * bandes de critère, et ses priorités sont de simples chaînes : les blocs
 * concernés ne sont pas rendus. C'est un cas normal, jamais une erreur.
 */
export function ProductionFeedbackView({
  evaluation,
  isOral = false,
  eyebrow,
  productionText,
  motsCount,
}: {
  evaluation: EvaluationResultDto;
  /** EO : `exemples_corriges` sont des reformulations de clarté (jamais de
   *  l'orthographe, filtrée serveur) — on relabellise la section en
   *  conséquence. EE : corrections classiques. */
  isOral?: boolean;
  /** Situe la correction en tête du hero (« Expression écrite · Tâche 1 »). */
  eyebrow?: string | null;
  /** Le texte rendu par le candidat. Fourni en expression ÉCRITE : il porte
   *  alors la bascule vers la version améliorée, pour que la comparaison se
   *  fasse au même endroit. À l'oral, la transcription vit dans son propre
   *  dépliant (dialogue en bulles) : ce paramètre reste nul. */
  productionText?: string | null;
  motsCount?: number | null;
}) {
  const fb = parseEeFeedback(evaluation);
  // Les évaluations les plus anciennes ne portent pas l'avertissement de
  // transcription : on garde le rappel écrit côté front pour ne pas le perdre.
  const avertissements =
    fb.avertissements.length > 0 ? fb.avertissements : isOral ? [TRANSCRIPTION_LIMIT] : [];
  const versionAmelioree = isOral ? null : fb.versionAmelioree;
  const highlight = fb.pointsAAmeliorer[0]?.exemple?.avant ?? null;

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 14}}>
      <ProductionResultsHero
        eyebrow={eyebrow}
        objectif={fb.accomplissement?.objectif ?? null}
        resume={fb.accomplissement?.objectifResume ?? null}
        noteSurVingt={fb.noteGlobale}
        niveau={evaluation.niveauObserve}
        confiance={fb.confiance}
        avertissementNiveau={evaluation.avertissementNiveau}
        confianceRaisons={fb.confianceRaisons}
      />

      <ResultsSummaryTiles
        accomplissement={fb.accomplissement}
        priorites={fb.pointsAAmeliorer}
        pointsForts={fb.pointsForts}
      />

      <CriteriaOverview criteres={fb.criteres} />

      {productionText ? (
        <ProductionTextCard
          texte={productionText}
          motsCount={motsCount}
          versionAmelioree={versionAmelioree}
          highlight={highlight}
        />
      ) : (
        versionAmelioree && (
          // Pas de texte à comparer (oral, ou historique sans production
          // servie) : la version améliorée garde sa carte autonome.
          <div className={styles.card}>
            <p className={styles.prodImprovedLabel}>Version améliorée</p>
            <p className={styles.prodImprovedHint}>
              Vos idées, réécrites : les mêmes, dites autrement.
            </p>
            <p className={styles.improved}>{versionAmelioree}</p>
          </div>
        )
      )}

      <ProductionFullAnalysis
        avertissements={avertissements}
        accomplissement={fb.accomplissement}
        exemplesCorriges={fb.exemplesCorriges}
        suggestions={fb.suggestions}
        isOral={isOral}
      />
    </div>
  );
}
