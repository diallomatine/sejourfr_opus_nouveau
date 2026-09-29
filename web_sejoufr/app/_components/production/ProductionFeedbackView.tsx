"use client";

import {CircleAlert} from "lucide-react";
import {productionNonEvaluable, situationView} from "@/lib/production-feedback";
import {parseEeFeedback, type EvaluationResultDto, type TargetLevel} from "@/lib/types";
import {ActionPlanPending} from "@/app/_components/skill-ui/ActionPlan";
import {CriteriaOverview} from "./CriteriaOverview";
import {EvaluationNotice} from "./EvaluationNotice";
import {ProductionActionPlan} from "./ProductionActionPlan";
import {ProductionResultsHero} from "./ProductionResultsHero";
import {ProductionTextCard} from "./ProductionTextCard";
import {ResultsSummaryTiles} from "./ResultsSummaryTiles";
import {TargetLevelReachedCard} from "./TargetLevelReachedCard";
import styles from "./production.module.css";

/**
 * Limite de l'évaluation orale, **mot pour mot** le seul avertissement que le
 * serveur pose sur une production orale (`AiEvaluationService
 * .AVERTISSEMENT_TRANSCRIPTION`). Repli quand la liste arrive vide sur une tâche
 * orale (évaluation antérieure) — le candidat doit savoir dans tous les cas que
 * sa voix n'a pas été écoutée.
 *
 * ⚠️ Il a remplacé un pavé de trois paragraphes (2026-08-17) : les deux autres
 * avertissements annonçaient une purge, c'est-à-dire une mécanique interne dont
 * le candidat n'a rien à faire. Le renvoi à l'examen officiel vit désormais dans
 * `docs/notation-ia-eo-ee.md`, pas sur une carte de résultat.
 */
const TRANSCRIPTION_LIMIT =
  "Nous analysons la transcription écrite de votre enregistrement, pas votre voix — et la " +
  "transcription peut se tromper. Dans ce cas, l'erreur ne vous est jamais comptée. La " +
  "prononciation et l'aisance ne sont donc pas évaluées ici.";

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
 *
 * 🛑 **Une production INEXPLOITABLE ne passe par aucune de ces quatre
 * sections** : `evaluabilite === "NON_EVALUABLE"` rend
 * {@link NotEvaluableCard} et rien d'autre. Le fait se lit sur le champ, jamais
 * sur la nullité de la note ou du niveau — une évaluation ancienne les laisse
 * nuls sans être inexploitable pour autant.
 */
export function ProductionFeedbackView({
  evaluation,
  isOral = false,
  eyebrow,
  productionText,
  motsCount,
  targetLevel = null,
  actionPlanPending = false,
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
  /** Le sursis accordé au second appel court encore : la place du plan
   *  d'action porte un indicateur discret. Posé par l'écran, qui est le seul à
   *  savoir si quelque chose tourne encore (cf. `ProductionResults`). */
  actionPlanPending?: boolean;
}) {
  const fb = parseEeFeedback(evaluation);

  // Rien n'a pu être observé : le rapport entier laisse la place à une carte
  // qui le DIT, suivie de la production rendue. Tout ce qui suit décrirait une
  // performance qui n'a pas été mesurée — hero de verdict, bandeaux « ce qui
  // marche », profil par critère, plan d'action vers le palier visé.
  if (productionNonEvaluable(evaluation)) {
    return (
      <div className={styles.wrap} style={{padding: 0, gap: 14}}>
        <NotEvaluableCard
          eyebrow={eyebrow}
          raisons={fb.confianceRaisons.length > 0 ? fb.confianceRaisons : fb.avertissements}
        />
        {productionText && <ProductionTextCard texte={productionText} motsCount={motsCount} />}
      </div>
    );
  }

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

      {/* Le second appel tourne encore : une ligne à la place du bloc, le temps
          du sursis. Elle s'efface en silence s'il ne vient rien, et ne bloque
          jamais la lecture du reste. */}
      {actionPlanPending && !versionCiblee && !niveauViseAtteint && <ActionPlanPending />}
    </div>
  );
}

/**
 * Production **rendue, mais inexploitable** (`evaluabilite: NON_EVALUABLE`) :
 * vide ou quasi vide, écrite dans une autre langue, ou recopiant la consigne.
 * Les contrôles déterministes du serveur l'ont écartée **avant** tout appel au
 * correcteur — il n'existe donc ni note, ni niveau, ni `scores_criteres`, et
 * ces trois absences ne sont pas des trous à combler.
 *
 * Elle remplace le rapport **en entier** : ni bandeau de niveau, ni pastille de
 * palier, ni profil par critère. Avant, l'écran affichait « Niveau
 * indisponible » au-dessus d'un bloc de critères vide, sans jamais dire au
 * candidat ce qui s'était passé.
 *
 * 🛑 **Trois états, pas deux.** Une évaluation absente veut dire « pas encore
 * évaluée » (l'écran affiche alors son attente) ; celle-ci veut dire « on a
 * regardé, il n'y avait rien à observer ». Le serveur sert le **fait**
 * (`evaluabilite`), la phrase appartient aux fronts.
 *
 * 🛑 **Ni reproche, ni verdict déguisé.** Une absence de preuve n'est pas la
 * preuve du niveau le plus faible — c'est exactement le défaut que le backend
 * vient de retirer de sa base (`0/20` + `A1_NON_ATTEINT` sur une copie vide).
 * D'où l'ambre (attention) plutôt que le rouge (échec), et un texte qui décrit
 * la **production**, jamais le candidat. Les raisons viennent du serveur, déjà
 * rédigées pour être lues par lui : on n'en réécrit aucune.
 *
 * ⚠️ **Libellés gelés, miroirs mot pour mot du mobile**
 * (`kProductionNonEvaluable*`, `screens/tcf_production/production_result_labels.dart`,
 * rendus par `widgets/production_non_evaluable_card.dart`). Chaque front en
 * tient une copie écrite à la main : un texte qui bouge, ce sont deux fichiers
 * à changer dans la même passe.
 */
const NON_EVALUABLE_EYEBROW = "Analyse impossible";
const NON_EVALUABLE_TITLE = "Cette production n'a pas pu être analysée";
const NON_EVALUABLE_INTRO =
  "Il n'y avait pas assez de matière pour observer quoi que ce soit. Aucun niveau ne vous est " +
  "attribué ici : ce n'est pas un jugement sur votre français, simplement une production qui ne " +
  "peut pas être corrigée.";
const NON_EVALUABLE_RAISONS_TITLE = "Ce qui a été constaté";
const NON_EVALUABLE_RASSURANCE =
  "Elle ne compte pas dans votre niveau estimé. Vous pouvez refaire ce sujet quand vous voulez.";

function NotEvaluableCard({
  eyebrow,
  raisons,
}: {
  /** Situe la tâche (« Expression écrite · Tâche 1 »), comme sur le hero d'un
   *  rapport normal. Absent d'un contexte qui ne la connaît pas. */
  eyebrow?: string | null;
  /** `feedback.confiance_raisons`, à défaut `feedback.avertissements`. Vide est
   *  un cas normal : la carte se suffit alors à elle-même. */
  raisons: string[];
}) {
  return (
    <section className={styles.unusable}>
      {eyebrow && <p className={styles.unusableTag}>{eyebrow}</p>}
      <p className={styles.unusableKind}>
        <CircleAlert size={15} strokeWidth={2.4} aria-hidden />
        {NON_EVALUABLE_EYEBROW}
      </p>
      <h2 className={styles.unusableTitle}>{NON_EVALUABLE_TITLE}</h2>
      <p className={styles.unusableLead}>{NON_EVALUABLE_INTRO}</p>
      {raisons.length > 0 && (
        <>
          <p className={styles.unusableReasonsHead}>{NON_EVALUABLE_RAISONS_TITLE}</p>
          <ul className={styles.unusableReasons}>
            {raisons.map((r, i) => (
              <li key={i}>{r}</li>
            ))}
          </ul>
        </>
      )}
      <p className={styles.unusableFoot}>{NON_EVALUABLE_RASSURANCE}</p>
    </section>
  );
}
