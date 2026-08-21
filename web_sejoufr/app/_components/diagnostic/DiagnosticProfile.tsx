"use client";

import {useEffect, useState} from "react";
import {ArrowRight, ChevronRight} from "lucide-react";
import {learningPlanApi} from "@/lib/api";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {PlanDomainIcon, PlanLevelRail} from "@/app/_components/plan/PlanBits";
import {usePlanAssessment} from "@/app/_components/plan/use-plan-exercise";
import {
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_COMPLETE_PROFILE_TITLE,
  PLAN_DOMAIN_NOT_EVALUATED,
  planAssessmentCta,
  planAssessmentMeta,
  planDomainLabel,
  planProfileCountLabel,
} from "@/lib/plan-domain";
import {niveauCecrlLabel, type LearningPlanDto, type PlanDomainAssessmentDto} from "@/lib/types";
import styles from "./diagnostic.module.css";

/**
 * **Où en est le profil TCF**, et par quoi le compléter — la section que la
 * maquette place sous le niveau estimé.
 *
 * Trois règles du dépôt, toutes tenues ici et jamais recalculées :
 *
 * 1. 🛑 **Un domaine non évalué n'est pas une faiblesse** : `evaluated: false`
 *    veut dire *il manque des données*. On écrit `PLAN_DOMAIN_NOT_EVALUATED`
 *    (« Pas encore évaluée »), jamais un niveau bas, jamais un ton de reproche.
 * 2. 🛑 **L'ordre des quatre domaines vient du serveur** (par urgence, puis
 *    ordre des épreuves) : on ne retrie pas et on ne complète aucun trou.
 * 3. 🛑 **Le compte « 2 sur 4 » se lit sur `cycle`**, jamais sur la longueur de
 *    `domainesAEvaluer` — deux surfaces qui compteraient chacune de leur côté
 *    finiraient par se contredire.
 *
 * Le lancement d'une mesure passe par **`usePlanAssessment`**, le seul endroit
 * du web qui démarre un parcours de mesure : aucun second lanceur n'est écrit
 * ici, et un 403 freemium y ouvre l'offre au lieu d'afficher une erreur.
 */
export function DiagnosticProfileCard({
  emphasis,
}: {
  /** `next` — le candidat a choisi le diagnostic complet : la compréhension est
   *  la suite immédiate. `later` — elle reste ouverte, sans pression. */
  emphasis: "next" | "later";
}) {
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();

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
        /* Confort d'affichage : un échec fait disparaître la section, sans
           message d'erreur — le rapport, lui, reste entier. */
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  if (!plan || plan.domaines.length === 0) return null;

  // 🛑 Le diagnostic vient d'être rendu : proposer « Faire mon diagnostic »
  // renverrait le candidat sur l'écran qu'il est en train de lire
  // (`usePlanAssessment` route `DIAGNOSTIC` vers `/diagnostic`). On retire la
  // ligne **sur cet écran seulement** — c'est une contrainte de place, pas une
  // règle : le Plan continue de la servir et de l'afficher chez lui. L'ordre
  // des lignes restantes reste celui du serveur, on ne retrie rien.
  const remaining = plan.domainesAEvaluer.filter((a) => a.kind !== "DIAGNOSTIC");

  return (
    <section className={styles.profileCard} aria-labelledby="profile-title">
      <div className={styles.profileHead}>
        <div>
          <h2 id="profile-title">Votre profil TCF</h2>
          <p>{planProfileCountLabel(plan.cycle)}</p>
        </div>
        <PlanLevelRail current={plan.cycle.targetLevel} />
      </div>

      <ul className={styles.profileGrid}>
        {plan.domaines.map((domain) => (
          <li key={domain.epreuve} data-evaluated={domain.evaluated ? "1" : "0"}>
            <PlanDomainIcon epreuve={domain.epreuve} small />
            <span className={styles.profileBody}>
              <b>{domain.evaluated && domain.niveau ? niveauCecrlLabel(domain.niveau) : "—"}</b>
              <span>{planDomainLabel(domain.epreuve)}</span>
            </span>
          </li>
        ))}
      </ul>

      {remaining.length > 0 && (
        <div className={styles.profileComplete}>
          <p className={styles.profileCompleteHead}>
            <b>{PLAN_COMPLETE_PROFILE_TITLE}</b>
            <span>
              {emphasis === "next"
                ? "Vous avez choisi le diagnostic complet : voici la suite, maintenant que votre compte porte vos résultats."
                : "Les domaines qui n'ont pas encore de mesure. Rien ne presse : vous pouvez les passer quand vous voulez."}
            </span>
          </p>
          <ul className={styles.profileRows}>
            {remaining.map((assessment, index) => (
              <AssessmentRow
                key={`${assessment.epreuve}-${assessment.kind}`}
                assessment={assessment}
                lead={emphasis === "next" && index === 0}
                busy={starting === assessment.epreuve}
                onStart={() => void start(assessment)}
              />
            ))}
          </ul>
          <p className={styles.profileNote}>{PLAN_COMPLETE_PROFILE_NOTE}</p>
          {error && (
            <p className={styles.error} role="alert">
              {error}
            </p>
          )}
        </div>
      )}

      <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </section>
  );
}

function AssessmentRow({
  assessment,
  lead,
  busy,
  onStart,
}: {
  assessment: PlanDomainAssessmentDto;
  /** Première marche du parcours complet : elle porte l'action principale. */
  lead: boolean;
  busy: boolean;
  onStart: () => void;
}) {
  return (
    <li>
      <button
        type="button"
        className={`${styles.profileRow} ${lead ? styles.profileRowLead : ""}`}
        onClick={onStart}
        disabled={busy}
      >
        <PlanDomainIcon epreuve={assessment.epreuve} small active={lead} />
        <span className={styles.profileBody}>
          <b>{planDomainLabel(assessment.epreuve)}</b>
          <span>
            {PLAN_DOMAIN_NOT_EVALUATED} · {planAssessmentMeta(assessment)}
          </span>
        </span>
        <span className={styles.profileRowCta}>
          {busy ? "Démarrage…" : planAssessmentCta(assessment)}
          {lead ? <ArrowRight size={15} aria-hidden /> : <ChevronRight size={15} aria-hidden />}
        </span>
      </button>
    </li>
  );
}
