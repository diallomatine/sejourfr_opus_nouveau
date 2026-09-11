"use client";

import Link from "next/link";
import {ChevronRight} from "lucide-react";
import type {ReactNode} from "react";
import {PLAN_RECENT_NEW_PRIORITY, planSkillMeta, planTransitionLine} from "@/lib/plan-domain";
import {type LearningPlanDto, PLAN_RECENT_CHANGES_WINDOW_LABEL} from "@/lib/types";
import styles from "./plan.module.css";

/**
 * **Les structures partagées par les écrans SECONDAIRES du Plan**
 * (`/plan/competences`, `/plan/domaine/[x]`, `/plan/evolution`,
 * `/plan/progression`).
 *
 * Elles vivaient dans `LearningPlanView`, que la refonte du 2026-09-11 a
 * basculé sur le kit `sejour/` : les quatre écrans qui les importaient n'ont
 * pas été refondus et continuent de lire `plan.module.css`. Extraites ici pour
 * que la refonte de l'écran principal n'entraîne pas la leur.
 */

export function PlanShell({children}: {children: ReactNode}) {
  return <main className={styles.page}>{children}</main>;
}

export function EmptyCard({icon, title, text, children, role}: {
  icon: ReactNode;
  title: string;
  text: string;
  children?: ReactNode;
  role?: "alert";
}) {
  return (
    <section className={styles.emptyCard} role={role}>
      <span className={styles.emptyIcon} aria-hidden>{icon}</span>
      <h2>{title}</h2>
      <p>{text}</p>
      {children && <div className={styles.actions}>{children}</div>}
    </section>
  );
}

export function BlockHead({title, text, titleId, action}: {
  title: string;
  text?: string;
  titleId?: string;
  action?: ReactNode;
}) {
  return (
    <div className={styles.blockHead}>
      <div>
        <h2 id={titleId}>{title}</h2>
        {text && <p>{text}</p>}
      </div>
      {action}
    </div>
  );
}

/** 🛑 `recentChanges === null` est le cas **NORMAL** : rien n'a bougé, on
 *  n'affiche rien. Aucune ligne n'est fabriquée pour remplir le bloc.
 *
 *  🛑 **Pas de transition réelle ⇒ pas de section du tout.** Le serveur sert
 *  aussi ce bloc pour une simple « nouvelle priorité », et une PREMIÈRE mesure
 *  n'est jamais une transition : le titre de la section EST la période, et
 *  l'écrire sans rien qui ait bougé dans cette période serait faux. */
export function PlanRecentChanges({plan}: {plan: LearningPlanDto}) {
  const changes = plan.recentChanges;
  if (!changes) return null;
  if (changes.transitions.length === 0) return null;
  return (
    <section aria-labelledby="changes-title">
      <BlockHead
        title={PLAN_RECENT_CHANGES_WINDOW_LABEL[changes.window]}
        text="Ce que vos dernières productions ont changé dans votre plan."
        titleId="changes-title"
        action={<Link className={styles.blockAction} href="/plan/evolution">Voir le détail <ChevronRight size={15} aria-hidden /></Link>}
      />
      <div className={styles.changesCard}>
        <ul className={styles.changesList}>
          {changes.transitions.map((transition) => (
            <li key={transition.skillId}>
              <span className={styles.changesMark} data-up={transition.progress ? "1" : "0"} aria-hidden>
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
    </section>
  );
}
