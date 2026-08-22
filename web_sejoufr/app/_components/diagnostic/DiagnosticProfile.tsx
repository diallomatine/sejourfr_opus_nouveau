"use client";

import Link from "next/link";
import {useEffect, useState, type ReactNode} from "react";
import {learningPlanApi} from "@/lib/api";
import {PlanDomainIcon, PlanDomainPriorityPill, PlanLevelRail} from "@/app/_components/plan/PlanBits";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {RowChevron} from "@/app/_components/skill-ui/SkillLayout";
import {usePlanAssessment} from "@/app/_components/plan/use-plan-exercise";
import {planDomainHref, planDomainLabel, planProfileCountLabel} from "@/lib/plan-domain";
import {
  niveauCecrlLabel,
  type LearningPlanDto,
  type PlanDomainAssessmentDto,
  type PlanDomainDto,
} from "@/lib/types";
import styles from "./diagnostic.module.css";

/**
 * Les libellés du **haut du rapport** : le héros de niveau, le profil TCF et la
 * carte « il reste des domaines à mesurer ».
 *
 * ⚠️ **Miroirs mot pour mot du mobile** (`diagnostic_report_labels.dart`) : ces
 * chaînes ne transitent pas par le réseau, chaque front en tient sa copie. Un
 * libellé qui bouge, ce sont deux fichiers à changer dans la même passe.
 *
 * ⚠️ **Vouvoiement.** La maquette du propriétaire tutoie, mais elle ne donne que
 * la direction **visuelle** — structure, ordre des blocs, densité. Le registre,
 * lui, reste celui de l'application : le rapport et le Plan vouvoient, seul le
 * module Compétences tutoie.
 */
// La maquette dit « Votre niveau actuel ». Le CLAUDE.md racine impose que le
// libellé du niveau estimé contienne **toujours** le mot « estimé » — la
// maquette donne la direction visuelle, pas les règles du produit. Miroir mot
// pour mot de `kDiagnosticLevelEyebrow` côté mobile. Ne pas « aligner » sur la
// maquette.
export const DIAGNOSTIC_LEVEL_EYEBROW = "Votre niveau estimé";
export const DIAGNOSTIC_LEVEL_OBJECTIVE = "Objectif";
export const DIAGNOSTIC_LEVEL_OBJECTIVE_UNKNOWN = "à définir";
export const DIAGNOSTIC_LEVEL_TEXT =
  "Estimation établie sur vos deux productions. Les compétences à rendre plus stables sont listées ci-dessous.";

export const DIAGNOSTIC_PROFILE_TITLE = "Mon profil TCF";
/** Ce qu'on lit sous le nom d'un domaine mesuré. 🛑 Le niveau vient du serveur ;
 *  la phrase ne prétend rien de plus que ce qui a été observé. */
export const DIAGNOSTIC_DOMAIN_OBSERVED = "quelques compétences observées";
/** 🛑 **Un domaine non évalué n'est pas une faiblesse** : `evaluated === false`
 *  veut dire *il manque des données*, et la phrase dit comment les obtenir. */
export const DIAGNOSTIC_DOMAIN_TO_EVALUATE =
  "Votre profil se complétera avec une première série";

export const DIAGNOSTIC_COMPLETE_CTA = "Compléter maintenant";

/**
 * **Le Plan, lu une seule fois pour tout le haut du rapport.**
 *
 * ⚠️ Lecture FRAÎCHE, pas `getCached()` : le Plan a pu être lu avant que le
 * diagnostic ne se termine, et le cache dirait encore « aucun domaine mesuré »
 * sur l'écran qui vient précisément d'en mesurer deux.
 *
 * `null` tant qu'il n'a pas répondu, et `null` à jamais s'il échoue : le héros
 * rend alors « — » et les deux blocs de profil disparaissent. Confort
 * d'affichage — le reste du rapport, lui, est entier.
 */
export function useDiagnosticPlan(): LearningPlanDto | null {
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);

  useEffect(() => {
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => {
        if (!cancelled) setPlan(current);
      },
      () => {
        /* Confort d'affichage : un échec ne remonte pas à l'écran. */
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  return plan;
}

/**
 * **Le héros du rapport** : le palier global estimé, l'objectif **sur la même
 * ligne**, une phrase, puis le rail A2 → B1 → B2.
 *
 * 🛑 **Aucune bande de quatre colonnes ici.** Elle appartenait au rapport du
 * **visiteur** (`MRapportGratuit`), pas à l'écran d'un candidat connecté : le
 * profil a désormais sa propre section, avec ses lignes cliquables. Ne pas la
 * réintroduire dans la carte.
 *
 * 🛑 **Le niveau global est celui du serveur** (`cycle.startingLevel`) : le
 * plancher des quatre domaines est une règle serveur (`TcfProfileService`),
 * aucun front ne la rejoue à partir des deux estimations de production.
 */
export function DiagnosticLevelCard({
  plan,
  targetLevel,
}: {
  plan: LearningPlanDto | null;
  targetLevel: string | null;
}) {
  return (
    <section className={styles.levelCard} aria-labelledby="level-title">
      <p className={styles.levelEyebrow} id="level-title">
        {DIAGNOSTIC_LEVEL_EYEBROW}
      </p>

      <div className={styles.levelPair}>
        <p className={styles.levelValue}>{niveauCecrlLabel(plan?.cycle.startingLevel)}</p>
        <p className={styles.levelGoal}>
          {DIAGNOSTIC_LEVEL_OBJECTIVE} {targetLevel ?? DIAGNOSTIC_LEVEL_OBJECTIVE_UNKNOWN}
        </p>
      </div>

      <p className={styles.levelText}>{DIAGNOSTIC_LEVEL_TEXT}</p>

      {plan && (
        <div className={styles.levelRail}>
          <PlanLevelRail current={plan.cycle.targetLevel} dark />
        </div>
      )}
    </section>
  );
}

/**
 * **« Mon profil TCF »** — les quatre domaines, en section à part entière.
 *
 * Trois règles du dépôt, toutes tenues et jamais recalculées :
 *
 * 1. 🛑 **L'ordre vient du serveur** (par urgence : priorité forte, à
 *    travailler, entretien, à évaluer) — on ne retrie pas et on ne comble aucun
 *    trou.
 * 2. 🛑 **Le compte se lit sur le cycle** (`planProfileCountLabel`), jamais sur
 *    la longueur d'une liste : trois surfaces qui compteraient chacune de leur
 *    côté finiraient par se contredire.
 * 3. 🛑 **Chaque ligne ouvre la fiche du domaine** (`/plan/domaine/{co,ce,ee,eo}`),
 *    par `planDomainHref` — le même chemin que le Plan, jamais un second.
 */
export function DiagnosticProfileCard({plan}: {plan: LearningPlanDto | null}) {
  if (!plan || plan.domaines.length === 0) return null;

  return (
    <section className={styles.profileCard} aria-labelledby="profile-title">
      <div className={styles.profileHead}>
        <h2 id="profile-title">{DIAGNOSTIC_PROFILE_TITLE}</h2>
        <p className={styles.profileCount}>{planProfileCountLabel(plan.cycle)}</p>
        <span className={styles.profileDots} aria-hidden>
          {plan.domaines.map((domain) => (
            <span key={domain.epreuve} data-on={domain.evaluated ? "1" : "0"} />
          ))}
        </span>
      </div>
      <ul className={styles.profileList}>
        {plan.domaines.map((domain) => (
          <li key={domain.epreuve}>
            <Link className={styles.profileRow} href={planDomainHref(domain.epreuve)}>
              <PlanDomainIcon
                epreuve={domain.epreuve}
                active={domain.evaluated && domain.priority === "FORTE"}
                small
              />
              <span className={styles.profileBody}>
                <span className={styles.profileTitle}>{planDomainLabel(domain.epreuve)}</span>
                <span className={styles.profileMeta}>{domainLine(domain)}</span>
              </span>
              <span className={styles.profilePill}>
                <PlanDomainPriorityPill priority={domain.priority} />
              </span>
              <RowChevron />
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

/** La ligne de repère d'un domaine. 🛑 « Pas encore évalué » n'est jamais dit
 *  comme un défaut : sans mesure, on annonce ce qui la produira. */
function domainLine(domain: PlanDomainDto): string {
  if (!domain.evaluated || !domain.niveau) return DIAGNOSTIC_DOMAIN_TO_EVALUATE;
  return `${niveauCecrlLabel(domain.niveau)} — ${DIAGNOSTIC_DOMAIN_OBSERVED}`;
}

/**
 * **« Il reste des domaines à mesurer »** — la carte qui suit le profil, et la
 * seule porte de sortie d'un profil incomplet depuis le rapport.
 *
 * 🛑 **La durée est VRAIE** : c'est la somme des `estimatedMinutes` servis par
 * le serveur pour les domaines restants (`DureeEpreuve` — CO 20 min, CE 35 min),
 * jamais un nombre écrit ici. Une mesure sans durée (le diagnostic, une
 * production : rien n'y est chronométré par épreuve) n'ajoute aucune minute, et
 * un total nul fait disparaître la durée du bouton plutôt qu'afficher « 0 min ».
 *
 * 🛑 **Le lancement passe par `usePlanAssessment`**, le lanceur qui sert déjà
 * « Compléter mon profil » sur le Plan : on ouvre un parcours **déjà existant**,
 * on n'en écrit pas un second.
 *
 * **Vide = profil complet**, l'état visé et non une anomalie : la carte
 * disparaît, sans félicitations ni indicateur.
 */
export function DiagnosticCompleteProfileCard({plan}: {plan: LearningPlanDto | null}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();

  const missing = plan?.domainesAEvaluer ?? [];
  if (missing.length === 0) return null;

  const minutes = missing.reduce((total, item) => total + (item.estimatedMinutes ?? 0), 0);
  const first = missing[0];

  return (
    <section className={styles.completeCard}>
      <p className={styles.completeText}>{missingSentence(missing)}</p>
      <button
        type="button"
        className={styles.completeCta}
        disabled={starting !== null}
        onClick={() => void start(first)}
      >
        {starting !== null
          ? "Démarrage…"
          : minutes > 0
            ? `${DIAGNOSTIC_COMPLETE_CTA} · ${minutes} min`
            : DIAGNOSTIC_COMPLETE_CTA}
      </button>
      {error && (
        <p className={styles.completeError} role="alert">
          {error}
        </p>
      )}
      <PaywallSheet ctaLocation="DIAGNOSTIC_REPORT" screen="diagnostic_profil" open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </section>
  );
}

/**
 * Ce qu'il reste à mesurer, dit au candidat.
 *
 * Le cas courant, après un diagnostic, est **exactement** les deux domaines de
 * compréhension : ils se nomment alors d'un mot et se mesurent par deux séries.
 * Tout autre cas — une production dont le correcteur n'a rien pu observer, un
 * domaine d'expression resté sans niveau — nomme les domaines un par un et
 * **ne promet pas de « séries »**, qui ne mesurent pas l'expression.
 */
function missingSentence(missing: PlanDomainAssessmentDto[]): ReactNode {
  const epreuves = new Set(missing.map((item) => item.epreuve));
  const comprehensionSeule =
    epreuves.size === 2 && epreuves.has("TCF_CO") && epreuves.has("TCF_CE");
  const noms = comprehensionSeule
    ? "la compréhension"
    : missing.map((item) => `la ${planDomainLabel(item.epreuve).toLowerCase()}`).join(" et ");
  const suite =
    comprehensionSeule && missing.every((item) => item.kind === "MODULE_MOCK_EXAM")
      ? "Deux épreuves suffisent — maintenant ou plus tard depuis votre plan."
      : "Vous pouvez le faire maintenant ou plus tard depuis votre plan.";

  return (
    <>
      Votre diagnostic n&apos;a pas encore évalué <strong>{noms}</strong>. {suite}
    </>
  );
}
