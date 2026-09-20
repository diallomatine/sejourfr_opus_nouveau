"use client";

import type {ReactNode} from "react";
import {productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadEpreuveTasks, productionTasksKey} from "@/lib/production-catalog";
import {loadTaskProgress, skillsProgressKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {productionTaskSubtitle, productionTaskTitle, skillSectionOf, skillTaskCodeOf} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";
import {type ProductionConfig} from "./config";
import {constraintOf} from "./parcours";

/** Teinte de la tâche : la rampe bleu → rouge de la marque, jamais une couleur
 *  nouvelle (cf. `.taskTone1/2/3` dans `skill.module.css`). */
export function taskToneClass(tacheNumero: number): string {
  if (tacheNumero === 2) return s.taskTone2;
  if (tacheNumero === 3) return s.taskTone3;
  return s.taskTone1;
}

/**
 * **La tête du détail d'une tâche** : ce qu'on va faire, la contrainte, la
 * consigne. Miroir mobile : `widgets/task_banner.dart` (`TaskBanner`).
 *
 * ⚠️ **Fond clair depuis le 2026-09-20** (demande du propriétaire). L'encart
 * était un aplat bleu plein qui pesait plus lourd que la liste de sujets qu'il
 * introduisait ; le bleu ne sert plus que d'**accent** — la pastille du niveau
 * visé, le libellé de la consigne et la contrainte. Le rouge reste réservé aux
 * CTA critiques.
 *
 * La hiérarchie suit ce que le candidat cherche : l'**intitulé** de la tâche est
 * le titre (son rang reste dit, en sur-titre, parce que consignes et corrigés
 * parlent de « tâche 2 »), puis la **contrainte** — le fait le plus utile avant
 * de produire — puis la consigne.
 *
 * ⚠️ **Plus de barre d'onglets depuis le 2026-09-20** : les compétences ne se
 * travaillent que via le Plan, l'écran d'une tâche n'a donc plus qu'un seul
 * contenu — ses sujets complets. La liste des compétences d'une tâche
 * (`CompetencesList`) garde cette même tête, elle n'est plus qu'atteinte
 * autrement.
 *
 * ⚠️ **Plus de pastille de niveau** (demande du propriétaire, 2026-09-20) :
 * `SkillTaskCode.targetLevel` est notre palier PÉDAGOGIQUE interne — le vrai
 * TCF ne rattache aucun niveau CECRL à une tâche, et aucun moteur du produit
 * ne s'en sert. C'est **l'affichage** qui part ; le champ reste servi.
 */
export function TaskChrome({
  config,
  taskNumero,
}: {
  config: ProductionConfig;
  taskNumero: number;
}): ReactNode {
  const {status} = useAuth();
  const ready = status === "authenticated";
  const section = skillSectionOf(config.epreuve);

  const tasksQuery = useCachedData(ready ? productionTasksKey(config.epreuve) : null, () =>
    loadEpreuveTasks(productionApi, config.epreuve),
  );
  const constraint = constraintOf(tasksQuery.data, taskNumero, config.mode === "audio");

  return (
    <section className={s.taskBanner}>
      <div className={s.taskBannerHead}>
        <div className={s.taskBannerBody}>
          <p className={s.taskBannerRank}>
            Tâche {taskNumero} · {config.label}
          </p>
          <h1 className={s.taskBannerTitle}>
            {productionTaskTitle(config.epreuve, taskNumero)}
          </h1>
        </div>
      </div>
      <div className={s.taskBannerBrief}>
        <span className={s.taskBannerLabel}>Consigne</span>
        {/* La contrainte est la PREMIÈRE chose lue de la consigne : c'est elle
            qui cadre la production. Servie par `production_tasks` — jamais un
            nombre écrit ici. */}
        {constraint && <strong className={s.taskBannerRange}>{constraint}</strong>}
        <p className={s.taskBannerText}>
          {productionTaskSubtitle(config.epreuve, taskNumero)}
        </p>
      </div>
    </section>
  );
}
