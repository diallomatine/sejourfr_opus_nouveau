"use client";

import Link from "next/link";
import {ClipboardCheck, Mic, PenLine} from "lucide-react";
import {learningPlanApi, productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  acquisesLabel,
  progressionVersObjectif,
  tacheBadge,
} from "@/lib/expression";
import {loadEpreuveTasks, productionTasksKey} from "@/lib/production-catalog";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {
  productionTaskLabeledTitle,
  skillSectionOf,
  skillTaskCodeOf,
  type LearningPlanDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {
  PlanEpreuveReco,
  usePlanEpreuveCarte,
} from "@/app/_components/plan/PlanEpreuveReco";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  RowChevron,
  SectionHead,
  SkillBadge,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL} from "./config";
import {PRODUCTION_TACHES, tacheLabel, useParcoursLevel} from "./parcours";

/**
 * **Écran d'entrée d'une épreuve productive** — maquette du propriétaire
 * `~/Desktop/sejourfr_ecrans/expression_ecran.png`.
 *
 * Trois blocs : l'en-tête (« TCF IRN » / « Expression écrite » / « Votre
 * progression vers l'objectif B2 »), la carte **recommandée par le cycle**,
 * puis **« Les 3 tâches »**. Les **examens blancs** restent en pied (demande
 * explicite du propriétaire) : ils portent sur l'épreuve entière, pas sur une
 * tâche, et leur route ne change pas d'un octet.
 *
 * 🛑 **« Recommandé » VIENT DU CYCLE, jamais du catalogue** (2026-09-20) :
 * `planEpreuveCarte` prend l'étape ouverte du **bloc de cette épreuve**, et le
 * clic fait exactement ce que ferait la même étape cliquée depuis le Plan.
 * ⚠️ Elle **remplace** `recommandationDuPlan`, qui lisait les priorités : deux
 * autorités pour la même question, donc deux réponses possibles selon l'écran.
 * **Aucun repli** : bloc terminé ou action qui ne se résout pas ⇒ **la carte
 * disparaît**. Retomber sur « la première case libre » recommanderait autre
 * chose que le Plan.
 *
 * 🛑 **Rien n'est compté ici.** « 3/8 compétences acquises » est de
 * l'arithmétique sur un `masteryState` **servi** (`acquisesLabel`), « 2/5
 * exercices réussis » sont les compteurs d'étape servis par le Plan, et le
 * nombre de compétences par tâche vient de l'API — jamais un 8 écrit en dur.
 *
 * 🛑 **Aucune phrase n'est composée ici** : elles vivent dans `lib/expression.ts`,
 * miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/tcf_production/expression_labels.dart`.
 */
export function ProductionTasks({config}: {config: ProductionConfig}) {
  const {user, status} = useAuth();
  const section = skillSectionOf(config.epreuve);
  /* L'étape du cycle, pour surligner la tâche qu'elle concerne. Même clé de
     cache que la carte ci-dessous : aucun appel de plus. */
  const carte = usePlanEpreuveCarte(config.epreuve);
  const ready = status === "authenticated";

  const tasksQuery = useCachedData(
    ready ? productionTasksKey(config.epreuve) : null,
    () => loadEpreuveTasks(productionApi, config.epreuve),
    {errorMessage: "Impossible de charger les sujets."},
  );
  const skillsQuery = useCachedData(
    ready ? skillsSectionKey(section) : null,
    () => loadSectionSkills(skillApi, section),
    {errorMessage: "Impossible de charger les compétences."},
  );
  /* Le Plan est lu **en cache** : on arrive presque toujours de l'Accueil ou de
     Réviser, qui l'ont déjà chargé. Son échec n'emporte pas l'écran — la carte
     de recommandation disparaît, les trois tâches restent. */
  const planQuery = useCachedData<LearningPlanDto>(
    ready ? learningPlanApi.cacheKey : null,
    () => learningPlanApi.getCached(),
  );

  const level = useParcoursLevel();
  const error = tasksQuery.error ?? skillsQuery.error;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={config.base} />;

  return (
    <DualChromeShell>
      <SkillShell
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        eyebrow="TCF IRN"
        title={config.label}
        /* 🛑 L'objectif est celui de la DÉMARCHE du candidat, servi. Sans
           démarche déclarée, la ligne disparaît — on ne devine pas un palier. */
        meta={progressionVersObjectif(level) ?? undefined}
      >
        {/* 🛑 **La recommandation vient du CYCLE**, la même étape que le Plan
            met en tête (demande du propriétaire, 2026-09-20). ⚠️ Elle
            **remplace** `recommandationDuPlan`, qui lisait les priorités du
            Plan : deux autorités pour la même question, donc deux réponses
            possibles sur deux écrans. Et son geste d'achat ouvrait le paywall
            d'un coup, sans passer par l'écran de transition (A145). */}
        <PlanEpreuveReco
          blocCode={config.epreuve}
          icon={config.mode === "audio" ? <Mic size={24} /> : <PenLine size={24} />}
        />

        {error && <div className={s.error}>{error}</div>}

        <SectionHead title={`Les ${PRODUCTION_TACHES.length} tâches`} />
        <div className={s.taskList}>
          {PRODUCTION_TACHES.map((n) => {
            const taskSkills = skillsOfTask(skillsQuery.data, skillTaskCodeOf(section, n));
            const badge = tacheBadge(taskSkills);
            return (
              <Link key={n} href={`${config.base}/tache/${n}/competences`} className={s.tacheRow}>
                <span
                  className={s.tacheNum}
                  data-active={carte?.step.taskCode === skillTaskCodeOf(section, n)}
                  aria-hidden
                >
                  {n}
                </span>
                <span className={s.tacheBody}>
                  <span className={s.tacheTitle}>
                    {productionTaskLabeledTitle(config.epreuve, n)}
                  </span>
                  {/* Le dénominateur vient de la liste servie : une tâche
                      publiée avec 6 compétences afficherait « x/6 ». */}
                  {taskSkills.length > 0 && (
                    <span className={s.tacheCount}>{acquisesLabel(taskSkills)}</span>
                  )}
                </span>
                {badge ? (
                  <SkillBadge tone={badge === "Acquis" ? "validated" : "treated"}>
                    {badge}
                  </SkillBadge>
                ) : (
                  <RowChevron />
                )}
              </Link>
            );
          })}
        </div>

        {/* 🛑 Les examens blancs restent EN BAS (demande du propriétaire) :
            ils portent sur l'épreuve entière, jamais sur une tâche. */}
        <Link href={`${config.base}/examens`} className={s.examsAccess}>
          <span className={s.examsAccessIcon} aria-hidden>
            <ClipboardCheck size={20} />
          </span>
          <span className={s.examsAccessBody}>
            <strong>Examens blancs</strong>
            <span>3 tâches · {config.examTiming.short}</span>
          </span>
          <RowChevron />
        </Link>
      </SkillShell>
    </DualChromeShell>
  );
}

