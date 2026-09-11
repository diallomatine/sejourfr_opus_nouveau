"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {ArrowLeft, ArrowRight, RotateCcw, Sparkles} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  PLAN_CYCLE_STATE_TEXT,
  PLAN_RECENT_NEW_PRIORITY,
  planCycleLine,
  planPathTitle,
  planSkillMeta,
  planTransitionLine,
} from "@/lib/plan-domain";
import {BlockHead, EmptyCard, PlanShell} from "./PlanLayout";
import {PlanPathList} from "./PlanBits";
import {
  type LearningPlanDto,
  PLAN_RECENT_CHANGES_WINDOW_LABEL,
} from "@/lib/types";
import styles from "./plan.module.css";

/**
 * **« Votre programme évolue »** — l'écran de bascule, quand le plan vient de
 * se réordonner.
 *
 * 🛑 **Rien n'y est inventé.** Il ne montre que ce que le serveur sert : les
 * **vraies transitions** du moteur de maîtrise sur la fenêtre qu'il a choisie
 * (`recentChanges`), la compétence devenue priorité n°1 dans cette fenêtre, et
 * le **chemin de palier** en cours (`cycle`). Aucune ligne n'est fabriquée pour
 * remplir, aucun « avant/après » n'est reconstitué de mémoire.
 *
 * `recentChanges === null` est le cas **NORMAL** : rien n'a bougé, et l'écran le
 * dit d'une phrase au lieu d'afficher un bloc vide.
 */
export function PlanEvolutionView() {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authStatus === "loading" || !user) return;
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => { if (!cancelled) { setPlan(current); setError(null); } },
      (cause: unknown) => {
        if (!cancelled) {
          setError(cause instanceof ApiException ? cause.message : "Impossible de charger votre plan.");
        }
      },
    ).finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [authStatus, user]);

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return (
      <main className={styles.page} aria-busy="true" aria-label="Chargement">
        <div className={styles.skeletonHead} />
        <div className={styles.skeletonHero} />
      </main>
    );
  }

  if (!plan) {
    return (
      <PlanShell>
        <EmptyCard
          icon={<RotateCcw size={28} />}
          title="Votre plan n'a pas pu être chargé"
          text={error ?? "Réessayez dans un instant."}
          role="alert"
        >
          <Link className={styles.primaryButton} href="/plan">Revenir à mon plan</Link>
        </EmptyCard>
      </PlanShell>
    );
  }

  const changes = plan.recentChanges;
  const gains = changes?.transitions.filter((t) => t.progress) ?? [];
  const pertes = changes?.transitions.filter((t) => !t.progress) ?? [];

  return (
    <PlanShell>
      <div className={styles.narrow}>
        <Link className={styles.back} href="/plan">
          <ArrowLeft size={17} aria-hidden /> Mon plan
        </Link>

        <div className={styles.evolutionHead}>
          <span className={styles.evolutionIcon} aria-hidden><Sparkles size={32} /></span>
          <h1>Votre programme évolue</h1>
          <p>{planCycleLine(plan.cycle)} {PLAN_CYCLE_STATE_TEXT[plan.cycle.state]}</p>
        </div>

        <div className={styles.stack}>
          {changes ? (
            <>
              <BlockHead
                title={PLAN_RECENT_CHANGES_WINDOW_LABEL[changes.window]}
                text="Mesuré en rejouant votre historique : ce sont de vraies transitions, pas un résumé."
              />
              <div className={styles.changesCard}>
                {/* Une liste vide n'est jamais rendue : le serveur sert aussi ce
                    bloc pour une simple « nouvelle priorité », et une première
                    mesure n'est pas une transition. */}
                <ul className={styles.changesList} hidden={changes.transitions.length === 0}>
                  {[...gains, ...pertes].map((transition) => (
                    <li key={transition.skillId}>
                      <span
                        className={styles.changesMark}
                        data-up={transition.progress ? "1" : "0"}
                        aria-hidden
                      >
                        {transition.progress ? "+" : "−"}
                      </span>
                      <span>
                        <b>{transition.title}</b>
                        <small>{planSkillMeta(transition)} · {planTransitionLine(transition)}</small>
                      </span>
                    </li>
                  ))}
                </ul>
                {changes.newPriority && (
                  <div className={styles.changesPriority}>
                    <p>{PLAN_RECENT_NEW_PRIORITY}</p>
                    <b>{changes.newPriority.title}</b>
                  </div>
                )}
              </div>
            </>
          ) : (
            <section className={`${styles.card} ${styles.tint}`}>
              <h2 className={styles.cardTitle}>Rien n&apos;a bougé pour l&apos;instant</h2>
              <p className={styles.cardText}>
                Votre programme se réordonne à chaque nouvelle observation, donc à votre
                prochaine production. En attendant, votre plan reste celui-ci.
              </p>
            </section>
          )}

          {plan.cycle.path.length > 0 && (
            <section className={styles.panel} aria-labelledby="evolution-path">
              <div className={styles.panelHead}>
                <div><h2 id="evolution-path">{planPathTitle(plan.cycle)}</h2></div>
              </div>
              <PlanPathList cycle={plan.cycle} titleId="evolution-path" />
            </section>
          )}

          <Link className={`${styles.primaryButton} ${styles.todayCta}`} href="/plan">
            Revenir à mon plan <ArrowRight size={17} aria-hidden />
          </Link>
        </div>
      </div>
    </PlanShell>
  );
}
