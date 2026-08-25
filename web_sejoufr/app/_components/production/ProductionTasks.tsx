"use client";

import Link from "next/link";
import {ClipboardCheck, Mic, PenLine} from "lucide-react";
import {productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadEpreuveTasks, productionTasksKey, tasksOfTache} from "@/lib/production-catalog";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {sumProgress} from "@/lib/skill-progress";
import {useCachedData} from "@/lib/use-cached-data";
import {
  productionTaskLabeledTitle,
  productionTaskSubtitle,
  skillSectionOf,
  skillTaskCodeOf,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  ParcoursNextCard,
  RowChevron,
  SkillBadge,
  SkillNotice,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL} from "./config";
import {
  nextSkill,
  PRODUCTION_TACHES,
  tacheLabel,
  tacheOf,
  useParcoursLevel,
} from "./parcours";
import {taskToneClass} from "./TaskChrome";

/** « 8 compétences », « 1 compétence » — le pluriel se décide ici, une fois. */
function plural(n: number, singulier: string): string {
  return `${n} ${singulier}${n > 1 ? "s" : ""}`;
}

/**
 * **Écran d'entrée d'une épreuve productive** (Réviser → Expression écrite /
 * orale), premier des deux niveaux de la maquette client : l'épreuve en une
 * carte de synthèse, puis ses trois tâches.
 *
 * ⚠️ Il **remplace la redirection** vers `…/tache/1/competences` : l'épreuve
 * n'avait pas d'accueil, on tombait directement dans la tâche 1 sans jamais
 * voir les trois. Les tâches sont pourtant ce que le candidat doit choisir en
 * premier — leur format, leur volume de compétences et de sujets diffèrent.
 *
 * Les **examens blancs** quittent la barre de modes de la tâche et deviennent
 * un accès de cet écran : ils portent sur l'épreuve entière, pas sur une tâche.
 * La route (`…/examens`) et l'écran ne changent pas d'un octet.
 *
 * Aucune donnée inventée : les compteurs sont les tailles réelles du catalogue
 * (`GET /api/production-tasks`, `GET /api/skills?section=`), la pastille d'état
 * est la progression réellement mesurée sur les petits sujets de la tâche.
 */
export function ProductionTasks({config}: {config: ProductionConfig}) {
  const {user, status} = useAuth();
  const section = skillSectionOf(config.epreuve);
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

  const level = useParcoursLevel();
  const skills = skillsQuery.data ?? [];
  const totalPrompts = sumProgress(skills).total;
  const next = nextSkill(skillsQuery.data);
  const error = tasksQuery.error ?? skillsQuery.error;

  // Le sous-titre ne peut pas annoncer « 0 compétence » pendant le chargement :
  // tant que le catalogue n'est pas là, c'est la carte d'identité de l'épreuve
  // qui s'affiche.
  const catalogue =
    skills.length > 0
      ? `${plural(PRODUCTION_TACHES.length, "tâche")} · ${plural(
          skills.length,
          "compétence",
        )} · ${plural(totalPrompts, "petit sujet")}`
      : config.epreuveMeta;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={config.base} />;

  return (
    <DualChromeShell>
      <SkillShell
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        title={config.label}
        meta={catalogue}
        level={level}
      >
        <section className={s.epreuveCard}>
          <div className={s.epreuveBanner}>
            <span className={s.epreuveIcon} aria-hidden>
              {config.mode === "audio" ? <Mic size={22} /> : <PenLine size={22} />}
            </span>
            <div className={s.epreuveBody}>
              <strong className={s.epreuveName}>{config.label}</strong>
              <span className={s.epreuveText}>
                {config.mode === "audio"
                  ? "Trois tâches orales, analysées par l'IA."
                  : "Trois tâches écrites, analysées par l'IA."}
              </span>
            </div>
          </div>
          <div className={s.countRow}>
            <Count value={PRODUCTION_TACHES.length} one="tâche" many="tâches" />
            <Count value={skills.length} one="compétence" many="compétences" />
            <Count value={totalPrompts} one="petit sujet" many="petits sujets" />
          </div>
        </section>

        {next && (
          <ParcoursNextCard
            config={config}
            title="Prochain entraînement"
            subtitle={`${tacheLabel(next.taskCode ?? "")} · ${next.title}`}
            actionLabel="Continuer"
            href={`${config.base}/tache/${tacheOf(next.taskCode ?? "")}/competences/${next.id}`}
          />
        )}

        {error && <div className={s.error}>{error}</div>}

        <div className={s.taskList}>
          {PRODUCTION_TACHES.map((n) => {
            const taskSkills = skillsOfTask(skillsQuery.data, skillTaskCodeOf(section, n));
            const progress = sumProgress(taskSkills);
            const sujets = tasksOfTache(tasksQuery.data, n).length;
            return (
              <Link
                key={n}
                href={`${config.base}/tache/${n}/competences`}
                className={`${s.taskRow} ${taskToneClass(n)}`}
              >
                <span className={s.taskRowTint} aria-hidden />
                <span className={s.taskRowTop}>
                  <span className={s.taskRowNum} aria-hidden>
                    {n}
                  </span>
                  <span className={s.taskRowBody}>
                    <span className={s.taskRowTitle}>
                      {productionTaskLabeledTitle(config.epreuve, n)}
                    </span>
                    <span className={s.taskRowText}>
                      {productionTaskSubtitle(config.epreuve, n)}
                    </span>
                  </span>
                  <span className={s.taskRowAside}>
                    {/* Ce que le candidat a réellement produit sur cette tâche —
                        jamais un palier de maîtrise agrégé, qui n'existe pas :
                        le serveur situe une compétence, pas une tâche. */}
                    {progress.total > 0 && progress.attempted >= progress.total ? (
                      <SkillBadge tone="validated">Terminé</SkillBadge>
                    ) : progress.attempted > 0 ? (
                      <SkillBadge tone="treated">
                        {progress.attempted}/{progress.total} traités
                      </SkillBadge>
                    ) : (
                      <RowChevron />
                    )}
                  </span>
                </span>
                <span className={s.countRow}>
                  <Count value={taskSkills.length} one="compétence" many="compétences" small />
                  <Count value={progress.total} one="petit sujet" many="petits sujets" small />
                  <Count value={sujets} one="sujet d'examen" many="sujets d'examen" small />
                </span>
              </Link>
            );
          })}
        </div>

        <SkillNotice title="Deux façons de travailler une tâche">
          Compétence par compétence avec des petits sujets, ou en production complète
          comme à l&apos;examen. Les examens blancs, eux, portent sur l&apos;épreuve
          entière.
        </SkillNotice>

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

/** Une colonne chiffrée d'un pied de carte. Le singulier est porté par
 *  l'appelant : « 1 compétences » se lit comme un bug d'affichage. */
function Count({
  value,
  one,
  many,
  small = false,
}: {
  value: number;
  one: string;
  many: string;
  small?: boolean;
}) {
  return (
    <span className={`${s.countCell} ${small ? s.countCellSmall : ""}`}>
      <span className={s.countValue}>{value}</span>
      <span className={s.countLabel}>{value > 1 ? many : one}</span>
    </span>
  );
}
