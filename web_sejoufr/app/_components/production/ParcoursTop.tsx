"use client";

import type {ReactNode} from "react";
import {productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  epreuveSubjectProgress,
  examDrafts,
  loadEpreuveTasks,
  loadMySubmissions,
  productionMineKey,
  productionTasksKey,
} from "@/lib/production-catalog";
import {loadSectionSkills, skillsSectionKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {
  formatNoteSur20,
  niveauViseTcf,
  productionTaskConstraint,
  productionTaskShortTitle,
  type ProductionTaskDto,
  skillSectionOf,
  type SkillDto,
} from "@/lib/types";
import {
  ParcoursHero,
  ParcoursNextCard,
  type SkillMode,
  SkillModeTabs,
  TaskCards,
} from "@/app/_components/skill-ui/SkillLayout";
import {type ProductionConfig} from "./config";

/** Nombre d'examens blancs proposés par épreuve EE/EO. Miroir de
 *  `kProductionExamSlots` (mobile, `expression_hub_data.dart`). */
export const PRODUCTION_EXAM_SLOTS = 10;

/**
 * Tête commune aux trois modes du parcours EE/EO, telle que la maquette client
 * la décrit : carte héros chiffrée, carte « Prochain entraînement », barre
 * segmentée des trois modes, puis le sélecteur de tâche.
 *
 * Sur le web les trois modes sont **trois routes**, pas un `IndexedStack` comme
 * sur mobile : chaque écran rend donc cette tête lui-même. Les trois sources
 * qu'elle lit sont mises en cache **sous les mêmes clés** que celles des
 * écrans (`productionTasksKey`, `productionMineKey`, `skillsSectionKey`) — un
 * aller-retour entre les modes ne coûte donc aucun appel de plus, exactement
 * comme sur mobile.
 *
 * Aucune donnée n'est inventée : tout vient du catalogue de l'épreuve et des
 * compteurs déjà servis par `GET /api/skills`.
 */
export function ParcoursTop({
  config,
  mode,
  taskNumero,
  onPickTask,
}: {
  config: ProductionConfig;
  mode: SkillMode;
  /** Tâche courante. Absente sur la grille des examens blancs, portée par
   *  l'épreuve entière : le sélecteur de tâche n'y est alors pas rendu. */
  taskNumero?: number;
  /** Transforme le sélecteur de tâche en filtre local quand l'écran a déjà les
   *  trois tâches en mémoire. */
  onPickTask?: (n: number) => void;
}): ReactNode {
  const {status} = useAuth();
  const ready = status === "authenticated";
  const section = skillSectionOf(config.epreuve);

  const tasksQuery = useCachedData(ready ? productionTasksKey(config.epreuve) : null, () =>
    loadEpreuveTasks(productionApi, config.epreuve),
  );
  const minesQuery = useCachedData(ready ? productionMineKey(config.epreuve) : null, () =>
    loadMySubmissions(productionApi, config.epreuve),
  );
  const skillsQuery = useCachedData(ready ? skillsSectionKey(section) : null, () =>
    loadSectionSkills(skillApi, section),
  );

  const tasks = tasksQuery.data;
  const subjects = epreuveSubjectProgress(tasks, minesQuery.data);
  const drafts = examDrafts(minesQuery.data);
  const avg = averageExamNote(drafts);
  const next = nextSkill(skillsQuery.data);

  return (
    <>
      <ParcoursHero
        percent={subjects.total > 0 ? (subjects.done / subjects.total) * 100 : 0}
        stats={[
          {value: avg == null ? "—" : formatNoteSur20(avg), label: "Score moyen", unit: "/20"},
          {
            value: String(drafts.length),
            label: "Examens blancs",
            unit: `/${PRODUCTION_EXAM_SLOTS}`,
          },
          {
            value: String(subjects.done),
            label: "Sujets traités",
            unit: `/${subjects.total}`,
          },
        ]}
      />

      {next && (
        <ParcoursNextCard
          config={config}
          title="Prochain entraînement"
          subtitle={`${tacheLabel(next.taskCode)} · ${next.title}`}
          actionLabel="Continuer"
          href={`${config.base}/tache/${tacheOf(next.taskCode)}/competences/${next.id}`}
        />
      )}

      <SkillModeTabs config={config} current={mode} taskNumero={taskNumero} />

      {taskNumero != null && (
        <TaskCards
          current={taskNumero}
          tasks={[1, 2, 3].map((n) => ({
            numero: n,
            title: productionTaskShortTitle(config.epreuve, n),
            constraint: constraintOf(tasks, n, config.mode === "audio"),
          }))}
          hrefOf={(n) =>
            mode === "competences"
              ? `${config.base}/tache/${n}/competences`
              : `${config.base}/tache/${n}`
          }
          onPick={onPickTask}
        />
      )}
    </>
  );
}

/**
 * Moyenne /20 des examens blancs **entièrement évalués**. On n'agrège que des
 * sessions complètes : une session dont l'IA n'a rendu qu'une note sur trois
 * tirerait la moyenne vers le bas sans raison. `null` ⇒ « — », jamais un zéro
 * qui se lirait comme un mauvais résultat.
 *
 * ⚠️ C'est une note d'**examen** (3 tâches agrégées), la seule échelle /20
 * autorisée ici : une tâche isolée ne reçoit qu'un niveau.
 */
function averageExamNote(drafts: readonly {avgNote: number | null; fullyEvaluated: boolean}[]) {
  const notes = drafts
    .filter((d) => d.fullyEvaluated && d.avgNote != null)
    .map((d) => d.avgNote as number);
  if (notes.length === 0) return null;
  return Math.round((notes.reduce((acc, v) => acc + v, 0) / notes.length) * 10) / 10;
}

/**
 * La prochaine compétence à travailler : la première **ouverte** dont tous les
 * petits sujets n'ont pas été traités, dans l'ordre du référentiel (la liste
 * arrive déjà triée `taskCode` puis `displayOrder`). Tout terminé, tout
 * verrouillé — ou rien de chargé — ⇒ **aucune carte**, jamais une invitation
 * vide.
 *
 * `locked` est **lu**, jamais déduit : c'est le serveur qui décide de ce qui est
 * ouvert. On l'écarte ici pour une seule raison — cette carte est une invitation
 * à produire, et envoyer le candidat sur une porte fermée n'en est pas une. Le
 * verrou lui-même s'affiche, avec son cadenas, dans la liste des compétences.
 */
function nextSkill(skills: readonly SkillDto[] | undefined): SkillDto | null {
  return skills?.find((k) => !k.locked && k.attemptedCount < k.promptCount) ?? null;
}

/** Numéro de tâche d'un `taskCode` (`EE2` → 2). */
function tacheOf(taskCode: string): number {
  const n = Number(taskCode.slice(-1));
  return Number.isFinite(n) && n >= 1 && n <= 3 ? n : 1;
}

/** « Tâche 2 » depuis un `taskCode`. Un code inattendu retombe sur le code
 *  brut plutôt que sur un numéro inventé. */
function tacheLabel(taskCode: string): string {
  const n = Number(taskCode.slice(-1));
  return Number.isFinite(n) ? `Tâche ${n}` : taskCode;
}

/** Contrainte réelle d'une tâche, lue sur son premier sujet publié. */
function constraintOf(
  tasks: readonly ProductionTaskDto[] | undefined,
  tacheNumero: number,
  isOral: boolean,
): string | null {
  const first = tasks?.find((t) => t.tacheNumero === tacheNumero);
  return first ? productionTaskConstraint(first, isOral) : null;
}

/** Palier **visé** par la démarche du candidat, pour le badge de l'en-tête.
 *  `null` ⇒ pas de badge : on ne devine jamais une démarche à sa place. */
export function useParcoursLevel(): string | null {
  const {user} = useAuth();
  return niveauViseTcf(user);
}
