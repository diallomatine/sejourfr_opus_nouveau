"use client";

import Link from "next/link";
import {ArrowRight, Check} from "lucide-react";
import type {PlanChangeDto} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Ce que cette production a changé dans le Plan — **une ligne**, en fin de
 * rapport, et rien d'autre. Pas la liste des compétences observées : le
 * candidat vient lire sa correction, pas un tableau de bord.
 *
 * ⚠️ **Bloc absent = cas NORMAL** (rien n'a bougé, ou les observations, écrites
 * après la correction, ne sont pas encore là) : on n'affiche alors ni message,
 * ni attente, ni « indisponible ». Les deux moitiés sont indépendamment
 * nullables — on ne rend que celle qui existe.
 */
export function PlanChangeLine({change}: {change: PlanChangeDto | null | undefined}) {
  if (!change) return null;
  const {confirmedSkill, newPriority} = change;
  if (!confirmedSkill && !newPriority) return null;
  return (
    <section className={s.planChange} aria-label="Votre plan a évolué">
      <div className={s.planChangeBody}>
        {confirmedSkill && (
          <p className={s.planChangeDone}>
            <Check size={15} strokeWidth={3} aria-hidden /> {confirmedSkill.title} confirmée
          </p>
        )}
        {newPriority && (
          <p className={s.planChangeNext}>Nouvelle priorité : {newPriority.title}.</p>
        )}
      </div>
      <Link href="/plan" className={s.planChangeLink}>
        Voir <ArrowRight size={15} aria-hidden />
      </Link>
    </section>
  );
}
