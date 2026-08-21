"use client";

import {useEffect, useState} from "react";
import {learningPlanApi} from "@/lib/api";
import {PlanLevelRail} from "@/app/_components/plan/PlanBits";
import {planDomainLabel, planDomainShort} from "@/lib/plan-domain";
import {niveauCecrlLabel, type LearningPlanDto} from "@/lib/types";
import styles from "./diagnostic.module.css";

/**
 * Les libellés de la carte de niveau.
 *
 * ⚠️ **Miroirs mot pour mot du mobile** (`diagnostic_report_labels.dart`) : ces
 * chaînes ne transitent pas par le réseau, chaque front en tient sa copie.
 *
 * ⚠️ **Vouvoiement.** La maquette du propriétaire tutoie, mais elle ne donne que
 * la direction **visuelle** — structure, ordre des blocs, densité. Le registre,
 * lui, reste celui de l'application : le rapport et le Plan vouvoient, seul le
 * module Compétences tutoie.
 */
export const DIAGNOSTIC_LEVEL_EYEBROW = "Votre niveau estimé";
export const DIAGNOSTIC_LEVEL_OBJECTIVE = "Objectif";
export const DIAGNOSTIC_LEVEL_OBJECTIVE_UNKNOWN = "à définir";
export const DIAGNOSTIC_LEVEL_TEXT =
  "Estimation établie sur vos deux productions. Les compétences à rendre plus stables sont listées ci-dessous.";
/**
 * La note discrète sous la carte.
 *
 * 🛑 **Elle ne s'affiche que si elle est VRAIE** : le diagnostic mesure les deux
 * domaines d'**expression**, jamais la compréhension — mais un candidat a pu
 * passer un examen blanc CO ou CE avant. On ne rend donc la phrase que quand
 * **aucun** des deux domaines de compréhension n'est évalué ; profil complet, ou
 * un seul des deux manquant, la bande de quatre colonnes dit déjà « — » et
 * suffit. Une seconde formulation « partielle » ferait un libellé de plus à
 * tenir des deux côtés pour un cas rare.
 */
export const DIAGNOSTIC_PROFILE_INCOMPLETE_NOTE =
  "La compréhension orale et écrite n'a pas encore été évaluée : vous pourrez compléter votre profil quand vous voulez.";

/**
 * **Une seule carte pour tout ce qui décrit le niveau** : le palier global
 * estimé, l'objectif visé, le palier en construction, et — dans le même cadre,
 * en pied — les quatre domaines du profil TCF.
 *
 * 🛑 **C'est ce pied qui a remplacé la section « Votre profil TCF »**, et c'est
 * ce qui rend l'écran épuré : le profil n'a plus de bloc à lui, il tient dans la
 * carte de niveau. Les lignes « Compléter mon profil » ne sont plus servies ici
 * — **le Plan continue de les servir chez lui**, avec leurs boutons de mesure.
 *
 * Trois règles du dépôt, toutes tenues et jamais recalculées :
 *
 * 1. 🛑 **Un domaine non évalué n'est pas une faiblesse** : `evaluated: false`
 *    veut dire *il manque des données*. On rend « — », jamais un niveau bas.
 * 2. 🛑 **L'ordre des quatre domaines vient du serveur** (par urgence, puis
 *    ordre des épreuves) : on ne retrie pas et on ne comble aucun trou.
 * 3. 🛑 **Le niveau global est celui du serveur** (`cycle.startingLevel`) : le
 *    plancher des quatre domaines est une règle serveur
 *    (`TcfProfileService`), aucun front ne la rejoue à partir des deux
 *    estimations de production.
 */
export function DiagnosticLevelCard({targetLevel}: {targetLevel: string | null}) {
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);

  // ⚠️ Lecture FRAÎCHE, pas `getCached()` : le Plan a pu être lu avant que le
  // diagnostic ne se termine, et le cache dirait encore « aucun domaine mesuré »
  // sur l'écran qui vient précisément d'en mesurer deux.
  useEffect(() => {
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => {
        if (!cancelled) setPlan(current);
      },
      () => {
        /* Confort d'affichage : un échec laisse la carte sans son palier global
           ni sa bande de domaines — « — », jamais un niveau inventé. Le reste du
           rapport, lui, est entier. */
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  const domaines = plan?.domaines ?? [];
  const comprehension = domaines.filter(
    (domain) => domain.epreuve === "TCF_CO" || domain.epreuve === "TCF_CE",
  );
  const aucuneComprehension =
    comprehension.length > 0 && comprehension.every((domain) => !domain.evaluated);

  return (
    <>
      <section className={styles.levelCard} aria-labelledby="level-title">
        <div className={styles.levelTop}>
          <p className={styles.levelEyebrow} id="level-title">
            {DIAGNOSTIC_LEVEL_EYEBROW}
          </p>

          <div className={styles.levelPair}>
            <p className={styles.levelValue}>{niveauCecrlLabel(plan?.cycle.startingLevel)}</p>
            <span className={styles.levelRule} aria-hidden />
            <div className={styles.levelGoal}>
              <p>{DIAGNOSTIC_LEVEL_OBJECTIVE}</p>
              <p>{targetLevel ?? DIAGNOSTIC_LEVEL_OBJECTIVE_UNKNOWN}</p>
            </div>
          </div>

          <p className={styles.levelText}>{DIAGNOSTIC_LEVEL_TEXT}</p>

          {plan && (
            <div className={styles.levelRail}>
              <PlanLevelRail current={plan.cycle.targetLevel} dark />
            </div>
          )}
        </div>

        {domaines.length > 0 && (
          <ul className={styles.levelDomains}>
            {domaines.map((domain) => (
              <li key={domain.epreuve} data-evaluated={domain.evaluated ? "1" : "0"}>
                <b>{niveauCecrlLabel(domain.evaluated ? domain.niveau : null)}</b>
                <abbr title={planDomainLabel(domain.epreuve)}>
                  {planDomainShort(domain.epreuve)}
                </abbr>
              </li>
            ))}
          </ul>
        )}
      </section>

      {aucuneComprehension && (
        <p className={styles.levelNote}>{DIAGNOSTIC_PROFILE_INCOMPLETE_NOTE}</p>
      )}
    </>
  );
}
