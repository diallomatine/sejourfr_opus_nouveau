"use client";

import Link from "next/link";
import type {ReactNode} from "react";
import {productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadEpreuveTasks, productionTasksKey, tasksOfTache} from "@/lib/production-catalog";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {productionTaskSubtitle, productionTaskTitle, skillSectionOf, skillTaskCodeOf} from "@/lib/types";
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
  level,
}: {
  config: ProductionConfig;
  taskNumero: number;
  tab: TaskTab;
  /** Palier visé, rendu dans le bandeau. `null` ⇒ pas de pastille : on ne
   *  devine jamais la démarche du candidat. */
  level?: string | null;
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
      {/* En-tête ET consigne dans un SEUL encart bleu, miroir du mobile
          (`_TaskBanner`). Arbitrage du propriétaire du 2026-08-21 : les deux
          blocs se succédaient en disant la même chose, et la teinte par tâche
          — verte sur la première — n'appartenait à aucune de nos deux couleurs
          de marque. Le numéro de tâche est le TITRE : c'est ce que le candidat
          cherche en arrivant, le nom éditorial du sujet ne le situe pas dans
          son parcours. */}
      <section className={s.taskBanner}>
        <div className={s.taskBannerHead}>
          <div className={s.taskBannerBody}>
            <h1 className={s.taskBannerTitle}>Tâche {taskNumero}</h1>
            <p className={s.taskBannerMeta}>
              {productionTaskTitle(config.epreuve, taskNumero)} · {config.label}
            </p>
          </div>
          {level && (
            <span className={s.taskBannerLevel}>
              <span className={s.taskBannerLevelLabel}>NIVEAU VISÉ</span>
              <strong>{level}</strong>
            </span>
          )}
        </div>
        <div className={s.taskBannerBrief}>
          <span className={s.taskBannerLabel}>
            Consigne{constraint ? ` · ${constraint}` : ""}
          </span>
          <p className={s.taskBannerText}>
            {productionTaskSubtitle(config.epreuve, taskNumero)}
          </p>
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
