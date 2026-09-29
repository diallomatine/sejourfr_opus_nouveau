"use client";

import Link from "next/link";
import type {ReactNode} from "react";
import {ArrowLeft} from "lucide-react";
import {productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadEpreuveTasks, productionTasksKey} from "@/lib/production-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {productionTaskIntro, TASK_BRIEF_LABEL} from "@/lib/production-task-labels";
import {productionTaskTitle} from "@/lib/types";
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
 * **Le retour vit dans la carte** (bouton rond), miroir de `TaskBanner` : les
 * écrans qui la montent passent `hideBack` à `SkillShell`. Au-delà de 760 px
 * de conteneur, la tête et la consigne se posent côte à côte (bandeau).
 *
 * La phrase sous la contrainte est la **consigne générale** de la tâche
 * (`productionTaskIntro`, `lib/production-task-labels.ts`), mot pour mot celle
 * du mobile.
 *
 * ⚠️ **Plus de pastille de niveau** (demande du propriétaire, 2026-09-20) :
 * `SkillTaskCode.targetLevel` est notre palier PÉDAGOGIQUE interne — le vrai
 * TCF ne rattache aucun niveau CECRL à une tâche, et aucun moteur du produit
 * ne s'en sert. C'est **l'affichage** qui part ; le champ reste servi.
 */
export function TaskChrome({
  config,
  taskNumero,
  backHref,
  backLabel,
}: {
  config: ProductionConfig;
  taskNumero: number;
  backHref: string;
  backLabel: string;
}): ReactNode {
  const {status} = useAuth();
  const ready = status === "authenticated";

  const tasksQuery = useCachedData(ready ? productionTasksKey(config.epreuve) : null, () =>
    loadEpreuveTasks(productionApi, config.epreuve),
  );
  const constraint = constraintOf(tasksQuery.data, taskNumero, config.mode === "audio");

  return (
    <section className={s.taskBanner}>
      <div className={s.taskBannerGrid}>
        <div className={s.taskBannerHead}>
          <Link href={backHref} className={s.taskBannerBack} aria-label={backLabel}>
            <ArrowLeft size={19} aria-hidden />
          </Link>
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
          <span className={s.taskBannerLabel}>{TASK_BRIEF_LABEL}</span>
          {/* La contrainte est la PREMIÈRE chose lue de la consigne : c'est elle
              qui cadre la production. Servie par `production_tasks` — jamais un
              nombre écrit ici. */}
          {constraint && <strong className={s.taskBannerRange}>{constraint}</strong>}
          <p className={s.taskBannerText}>
            {productionTaskIntro(config.mode === "audio", taskNumero)}
          </p>
        </div>
      </div>
    </section>
  );
}
