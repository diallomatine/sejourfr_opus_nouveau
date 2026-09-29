"use client";

import {
  ACTION_PLAN_EXEMPLE_TITLE,
  ACTION_PLAN_REFORMULATIONS_TITLE,
  ActionPlanExemple,
  ActionPlanLeviers,
  ActionPlanMemoCard,
  ActionPlanReformulations,
  pourViserTitle,
} from "@/app/_components/skill-ui/ActionPlan";
import type {EeVersionCiblee} from "@/lib/types";
import styles from "./production.module.css";

/**
 * **Le plan d'action** du candidat vers le palier qu'il vise : les leviers, une
 * version plus aboutie (ou, à l'oral, deux ou trois passages redits) et la
 * tournure à retenir.
 *
 * C'est exactement ce que rend déjà le module Compétences après un
 * micro-exercice — mêmes blocs, mêmes libellés, mêmes composants
 * (`skill-ui/ActionPlan`). Seuls les intertitres sont rendus ici, avec le
 * gabarit de titre du rapport de correction.
 *
 * ⚠️ **Ce bloc ne dit plus « au niveau B2, votre réponse pourrait ressembler à
 * ceci ».** Rien ne vérifie qu'un texte atteint le palier dont on l'étiquette,
 * et un candidat qui a recopié un exemple annoncé B2 l'a vu noter B1. On retire
 * l'affirmation invérifiable ; on garde l'**objectif** (« Pour viser B2 »), qui
 * lui est exact. Même correctif que celui déjà appliqué aux petits sujets.
 *
 * **Trois formes, plus l'absence** — cf. {@link EeVersionCiblee} :
 * - v2 écrit : leviers + version plus aboutie surlignée + à retenir ;
 * - v2 oral : leviers + reformulations + à retenir. **Aucun texte modèle
 *   complet** : la production orale n'est jamais réécrite en entier ;
 * - v1 (une centaine d'évaluations en base) : le texte modèle et les leviers en
 *   texte libre, rendus comme avant — mais sans l'étiquette de palier ;
 * - absent (second appel en échec, éval antérieure, oral dégradé) ⇒ **rien**.
 *   Pas de squelette, pas de « non disponible », pas d'encart d'excuse.
 *
 * Chaque section se masque **indépendamment** : un plan sans `à retenir` reste
 * un plan. Miroir mobile : `production_action_plan.dart`.
 */
export function ProductionActionPlan({version}: {version: EeVersionCiblee | null}) {
  if (!version) return null;

  const {leviers, exempleCible, reformulations, aRetenir, texte, ceQuiManque} = version;
  const hasLeviers = leviers.length > 0;
  const hasLegacyLeviers = !hasLeviers && ceQuiManque.length > 0;
  const hasLegacyTexte = !exempleCible && reformulations.length === 0 && !!texte;

  return (
    <>
      {(hasLeviers || hasLegacyLeviers) && (
        <section className={styles.targetSection}>
          <p className={styles.sectionHead}>
            <span className={styles.sectionTitle}>{pourViserTitle(version.niveauVise)}</span>
          </p>
          {hasLeviers ? (
            <ActionPlanLeviers leviers={leviers} />
          ) : (
            /* Contrat v1 : des phrases libres, pas des couples action/exemple.
               Ordre du backend PRÉSERVÉ (du plus rentable au moins rentable) ;
               le numéro le rend lisible sans le retrier. */
            <div className={styles.targetCard}>
              <ol className={styles.targetGapList}>
                {ceQuiManque.map((levier, i) => (
                  <li key={`${levier}-${i}`} className={styles.targetGapItem}>
                    <span className={styles.targetGapRank} aria-hidden>
                      {i + 1}
                    </span>
                    <span>{levier}</span>
                  </li>
                ))}
              </ol>
            </div>
          )}
        </section>
      )}

      {exempleCible && (
        <section className={styles.targetSection}>
          <p className={styles.sectionHead}>
            <span className={styles.sectionTitle}>{ACTION_PLAN_EXEMPLE_TITLE}</span>
          </p>
          <ActionPlanExemple exemple={exempleCible} />
        </section>
      )}

      {reformulations.length > 0 && (
        <section className={styles.targetSection}>
          <p className={styles.sectionHead}>
            <span className={styles.sectionTitle}>{ACTION_PLAN_REFORMULATIONS_TITLE}</span>
          </p>
          <ActionPlanReformulations reformulations={reformulations} />
        </section>
      )}

      {hasLegacyTexte && (
        <section className={styles.targetSection}>
          <p className={styles.sectionHead}>
            <span className={styles.sectionTitle}>{ACTION_PLAN_EXEMPLE_TITLE}</span>
          </p>
          <div className={styles.targetCard}>
            <p className={styles.targetText}>{texte}</p>
          </div>
        </section>
      )}

      {aRetenir && <ActionPlanMemoCard memo={aRetenir} className={styles.planMemo} />}
    </>
  );
}
