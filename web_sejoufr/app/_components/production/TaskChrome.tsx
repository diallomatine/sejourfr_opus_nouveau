"use client";

import Link from "next/link";
import type {ReactNode} from "react";
import {productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadEpreuveTasks, productionTasksKey, tasksOfTache} from "@/lib/production-catalog";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {productionTaskSubtitle, skillSectionOf, skillTaskCodeOf} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";
import {type ProductionConfig} from "./config";
import {constraintOf} from "./parcours";

/** Les deux façons de travailler une tâche. Ce sont **deux routes** sur le web
 *  (`…/tache/2/competences` et `…/tache/2`), pas deux états d'un même écran :
 *  chacune reste partageable et le Plan route directement vers la première. */
export type TaskTab = "competences" | "sujets";

/** Teinte de la tâche : la rampe bleu → rouge de la marque, jamais une couleur
 *  nouvelle (cf. `.taskTone1/2/3` dans `skill.module.css`). */
export function taskToneClass(tacheNumero: number): string {
  if (tacheNumero === 2) return s.taskTone2;
  if (tacheNumero === 3) return s.taskTone3;
  return s.taskTone1;
}

/**
 * Tête du **détail d'une tâche** : la carte de consigne, puis les deux onglets
 * « Compétences » et « Sujets d'examen ».
 *
 * Elle remplace l'ancienne tête à trois modes (`ParcoursTop`) : les examens
 * blancs ne sont plus un onglet de la tâche — ils portent sur l'épreuve
 * entière et s'atteignent depuis la liste des tâches. Les mettre au même niveau
 * qu'un espace de travail de tâche laissait croire qu'on passait un examen
 * « de la tâche 2 ».
 *
 * Les deux compteurs des onglets viennent des **mêmes clés de cache** que les
 * deux écrans (`productionTasksKey`, `skillsSectionKey`) : les afficher ne coûte
 * aucun appel de plus, quel que soit l'onglet ouvert.
 */
export function TaskChrome({
  config,
  taskNumero,
  tab,
}: {
  config: ProductionConfig;
  taskNumero: number;
  tab: TaskTab;
}): ReactNode {
  const {status} = useAuth();
  const ready = status === "authenticated";
  const section = skillSectionOf(config.epreuve);

  const tasksQuery = useCachedData(ready ? productionTasksKey(config.epreuve) : null, () =>
    loadEpreuveTasks(productionApi, config.epreuve),
  );
  const skillsQuery = useCachedData(ready ? skillsSectionKey(section) : null, () =>
    loadSectionSkills(skillApi, section),
  );

  const constraint = constraintOf(tasksQuery.data, taskNumero, config.mode === "audio");
  const sujets = tasksOfTache(tasksQuery.data, taskNumero).length;
  const competences = skillsOfTask(
    skillsQuery.data,
    skillTaskCodeOf(section, taskNumero),
  ).length;

  const base = `${config.base}/tache/${taskNumero}`;

  return (
    <>
      <section className={`${s.taskBrief} ${taskToneClass(taskNumero)}`}>
        <span className={s.taskBriefTint} aria-hidden />
        <div className={s.taskBriefRow}>
          <span className={s.taskBriefNum} aria-hidden>
            {taskNumero}
          </span>
          <div className={s.taskBriefBody}>
            <span className={s.taskBriefLabel}>
              Consigne{constraint ? ` · ${constraint}` : ""}
            </span>
            <p className={s.taskBriefText}>
              {productionTaskSubtitle(config.epreuve, taskNumero)}
            </p>
          </div>
        </div>
      </section>

      <nav className={s.segTabs} aria-label="Façons de travailler cette tâche">
        <Link
          href={`${base}/competences`}
          className={`${s.segTab} ${tab === "competences" ? s.segTabOn : ""}`}
          aria-current={tab === "competences" ? "page" : undefined}
        >
          Compétences{competences > 0 ? ` · ${competences}` : ""}
        </Link>
        <Link
          href={base}
          className={`${s.segTab} ${tab === "sujets" ? s.segTabOn : ""}`}
          aria-current={tab === "sujets" ? "page" : undefined}
        >
          Sujets d&apos;examen{sujets > 0 ? ` · ${sujets}` : ""}
        </Link>
      </nav>
    </>
  );
}
