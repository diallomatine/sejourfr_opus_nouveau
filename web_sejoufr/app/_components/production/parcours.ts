"use client";

import {useAuth} from "@/lib/auth-context";
import {
  niveauViseTcf,
  productionTaskConstraint,
  type ProductionTaskDto,
  type SkillDto,
} from "@/lib/types";

/**
 * Repères communs aux écrans d'une épreuve productive (EE/EO) : liste des
 * tâches, détail d'une tâche, examens blancs.
 *
 * ⚠️ Ce module a remplacé `ParcoursTop.tsx` (2026-08-21), qui rendait une tête
 * commune aux **trois modes** d'un même écran — héros chiffré, carte
 * « Prochain entraînement », barre Compétences · Sujets · Examens et sélecteur
 * T1/T2/T3. Le parcours se lit désormais en **deux niveaux** (la liste des
 * tâches, puis une tâche), donc cette tête n'avait plus d'endroit unique où
 * vivre : chaque niveau compose la sienne. Il ne reste ici que les calculs, qui
 * eux étaient partagés pour de bonnes raisons.
 */

/** Nombre d'examens blancs proposés par épreuve EE/EO. Miroir de
 *  `kProductionExamSlots` (mobile, `expression_hub_data.dart`). */
export const PRODUCTION_EXAM_SLOTS = 10;

/** Les trois tâches d'une épreuve productive. */
export const PRODUCTION_TACHES = [1, 2, 3] as const;

/**
 * Moyenne /20 des examens blancs **entièrement évalués**. On n'agrège que des
 * sessions complètes : une session dont l'IA n'a rendu qu'une note sur trois
 * tirerait la moyenne vers le bas sans raison. `null` ⇒ « — », jamais un zéro
 * qui se lirait comme un mauvais résultat.
 *
 * ⚠️ C'est une note d'**examen** (3 tâches agrégées), la seule échelle /20
 * autorisée ici : une tâche isolée ne reçoit qu'un niveau.
 */
export function averageExamNote(
  drafts: readonly {avgNote: number | null; fullyEvaluated: boolean}[],
): number | null {
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
export function nextSkill(skills: readonly SkillDto[] | undefined): SkillDto | null {
  return skills?.find((k) => !k.locked && k.attemptedCount < k.promptCount) ?? null;
}

/** Numéro de tâche d'un `taskCode` (`EE2` → 2). */
export function tacheOf(taskCode: string): number {
  const n = Number(taskCode.slice(-1));
  return Number.isFinite(n) && n >= 1 && n <= 3 ? n : 1;
}

/** « Tâche 2 » depuis un `taskCode`. Un code inattendu retombe sur le code
 *  brut plutôt que sur un numéro inventé. */
export function tacheLabel(taskCode: string): string {
  const n = Number(taskCode.slice(-1));
  return Number.isFinite(n) ? `Tâche ${n}` : taskCode;
}

/** Contrainte réelle d'une tâche, lue sur son premier sujet publié. */
export function constraintOf(
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
