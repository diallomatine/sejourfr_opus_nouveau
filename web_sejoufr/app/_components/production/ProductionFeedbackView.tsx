"use client";

import {situationView} from "@/lib/production-feedback";
import {parseEeFeedback, type EvaluationResultDto, type TargetLevel} from "@/lib/types";
import {CriteriaOverview} from "./CriteriaOverview";
import {EvaluationNotice} from "./EvaluationNotice";
import {ProductionActionPlan} from "./ProductionActionPlan";
import {ProductionResultsHero} from "./ProductionResultsHero";
import {ProductionTextCard} from "./ProductionTextCard";
import {ResultsSummaryTiles} from "./ResultsSummaryTiles";
import {TargetLevelReachedCard} from "./TargetLevelReachedCard";
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
 * 1. **le verdict et le niveau** — un seul hero
 *    ({@link ProductionResultsHero}). Pas de note : sur une tâche isolée, le
 *    /20 n'existe pas au TCF (cf. le composant) ;
 * 2. **ce qui marche / à corriger en priorité** ({@link ResultsSummaryTiles}) :
 *    deux bandeaux d'une ligne, repliés, qui ouvrent leur détail en dessous —
 *    la check-list de la consigne (points traités puis oubliés) et les points
 *    forts d'un côté, la priorité **complète** de l'autre ;
 * 3. **le profil par critère** ({@link CriteriaOverview}), une carte par
 *    critère, dépliable — il vivait dans le repli, donc personne ne le voyait ;
 * 4. **la production** ({@link ProductionTextCard}), puis **le seul texte modèle
 *    de la page** ({@link ProductionActionPlan} : les leviers, une version plus
 *    aboutie — ou, à l'oral, des passages redits — et la tournure à retenir).
 *
 * ⚠️ **« Voir l'analyse complète » n'existe plus (contrat v15/v9)** : le
 * correcteur ne produit plus `exemples_corriges` ni `suggestions`, et ce repli
 * — que personne n'ouvrait — disparaît avec eux. Les deux champs restent
 * **typés et parsés** dans `lib/types.ts` (une centaine d'évaluations en base
 * les portent), aucun écran candidat ne les lit. Ce qui vivait avec eux dans le
 * repli sans venir du LLM n'a PAS disparu :
 * - **les avertissements**, écrits par le SERVEUR (limite de l'oral, purges
 *   automatiques) : remontés en note discrète sous le hero
 *   ({@link EvaluationNotice}) ;
 * - **le détail de l'accomplissement** : le bandeau « Ce qui marche » montrait
 *   déjà les points **traités** ; il montre désormais aussi les points
 *   **oubliés**, faute de quoi le candidat lisait « 2/3 points traités » sans
 *   jamais savoir lequel manquait. Les pistes non abordées, qui ne coûtent
 *   aucun point, ne sont plus rendues.
 *
 * ⚠️ **`version_amelioree` n'est plus affichée nulle part (2026-08-08)** : elle
 * réécrivait la production au niveau **déjà constaté**, en bascule juste sous la
 * rédaction — donc le texte le plus visible et le plus copiable de la page était
 * celui qui ne fait pas progresser (mesuré : recopié puis resoumis, même note,
 * même niveau). Le champ reste servi par l'API et typé dans `lib/types.ts`,
 * aucun composant ne le lit.
 *
 * Une évaluation antérieure n'a ni verdict d'objectif, ni version au niveau
 * visé, ni bandes de critère, et ses priorités sont de simples chaînes : les
 * blocs concernés ne sont pas rendus. C'est un cas normal, jamais une erreur.
 */
export function ProductionFeedbackView({
  evaluation,
  isOral = false,
  eyebrow,
  productionText,
  motsCount,
  targetLevel = null,
}: {
  evaluation: EvaluationResultDto;
  /** EO : `exemples_corriges` sont des reformulations de clarté (jamais de
   *  l'orthographe, filtrée serveur) — on relabellise la section en
   *  conséquence. EE : corrections classiques. */
  isOral?: boolean;
  /** Situe la correction en tête du hero (« Expression écrite · Tâche 1 »). */
  eyebrow?: string | null;
  /** Le texte rendu par le candidat. Fourni en expression ÉCRITE. À l'oral, la
   *  transcription vit dans son propre dépliant (dialogue en bulles) : ce
   *  paramètre reste nul. */
  productionText?: string | null;
  motsCount?: number | null;
  /** Palier TCF visé par la démarche du candidat, pour le rappel d'enjeu du
   *  hero. `null` = inconnu → aucun rappel n'est affiché. */
  targetLevel?: TargetLevel | null;
}) {
  const fb = parseEeFeedback(evaluation);
  // Les évaluations les plus anciennes ne portent pas l'avertissement de
  // transcription : on garde le rappel écrit côté front pour ne pas le perdre.
  const avertissements =
    fb.avertissements.length > 0 ? fb.avertissements : isOral ? [TRANSCRIPTION_LIMIT] : [];
  // Le plan d'action est servi à l'écrit COMME à l'oral depuis le contrat v2 :
  // ce qui change, c'est sa forme (version plus aboutie vs reformulations), et
  // c'est le bloc lui-même qui la porte — pas un `isOral` recopié ici.
  const versionCiblee = fb.versionCiblee;
  // Exclusif du précédent, et servi par le SERVEUR : un front ne saurait pas
  // distinguer « objectif atteint » d'un second appel LLM en échec.
  const niveauViseAtteint = versionCiblee ? null : fb.niveauViseAtteint;
  const highlight = fb.pointsAAmeliorer[0]?.exemple?.avant ?? null;

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 14}}>
      <ProductionResultsHero
        eyebrow={eyebrow}
        objectif={fb.accomplissement?.objectif ?? null}
        resume={fb.accomplissement?.objectifResume ?? null}
        niveau={evaluation.niveauObserve}
        confiance={fb.confiance}
        avertissementNiveau={evaluation.avertissementNiveau}
        confianceRaisons={fb.confianceRaisons}
        situation={situationView(evaluation)}
        targetLevel={targetLevel}
      />

      {/* Écrit par le SERVEUR, pas par le correcteur : la limite de l'oral et
          les purges automatiques se lisent juste sous le verdict, en note. */}
      <EvaluationNotice avertissements={avertissements} />

      <ResultsSummaryTiles
        accomplissement={fb.accomplissement}
        priorites={fb.pointsAAmeliorer}
        pointsForts={fb.pointsForts}
      />

      <CriteriaOverview criteres={fb.criteres} />

      {productionText && (
        <ProductionTextCard
          texte={productionText}
          motsCount={motsCount}
          highlight={highlight}
        />
      )}

      {/* Le plan d'action, juste sous la rédaction : l'ordre de lecture est
          « ce que j'ai produit » → « ce qu'il faut viser, et à quoi ça
          ressemble ». Absent (éval antérieure, second appel en échec, oral
          dégradé) ⇒ rien n'est rendu, et le rapport se termine sur la
          production : ni section vide, ni titre orphelin. */}
      <ProductionActionPlan version={versionCiblee} />

      {/* Même emplacement, cas exclusif : le palier visé est DÉJÀ tenu. On
          l'annonce au lieu de laisser un trou — le candidat qui réussit avait un
          rapport plus vide que celui qui échoue. */}
      <TargetLevelReachedCard atteint={niveauViseAtteint} />
    </div>
  );
}
