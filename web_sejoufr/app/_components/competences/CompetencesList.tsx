"use client";

import {useParams, useRouter} from "next/navigation";
import {useCallback, useState} from "react";
import {skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {competenceProgressLabel} from "@/lib/skill-progress";
import {replaceUrlShallow} from "@/lib/shallow-url";
import {useCachedData} from "@/lib/use-cached-data";
import {skillSectionOf, type SkillDto, skillTaskCodeOf} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  type ProductionConfig,
  TCF_HUB_HREF,
  TCF_HUB_LABEL,
} from "@/app/_components/production/config";
import {ParcoursTop, useParcoursLevel} from "@/app/_components/production/ParcoursTop";
import {
  RowChevron,
  SectionHead,
  SkillNotice,
  SkillRing,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Niveau 4 de la spec — les 8 compétences d'une tâche.
 *
 * C'est l'atelier « je travaille un point précis », à côté (et non à la place)
 * des sujets TCF complets de la même tâche : on n'y produit jamais une copie
 * entière, seulement la brique que la compétence entraîne.
 *
 * L'écran suit la maquette client : hero de parcours avec sa progression
 * globale, pastilles T1/T2/T3 pour changer de tâche sans revenir en arrière,
 * puis les compétences, puis le principe pédagogique du module.
 */
export function CompetencesList({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string}>();
  const router = useRouter();
  const {user, status} = useAuth();

  const section = skillSectionOf(config.epreuve);
  const hrefOf = useCallback(
    (task: number) => `${config.base}/tache/${task}/competences`,
    [config.base],
  );

  // Les 24 compétences de l'épreuve arrivent en un appel : une pastille ne fait
  // donc que **filtrer**, sans remonter l'écran ni redemander quoi que ce soit.
  // La tâche est le choix local s'il y en a eu un, sinon celle de l'URL — dans
  // cet ordre, pour que l'accès direct, le lien partagé et le retour navigateur
  // continuent de décider de la tâche d'arrivée sans jamais écraser un choix.
  const routeTask = Number(params?.n ?? "0");
  const [pickedTask, setPickedTask] = useState<number | null>(null);
  const n = pickedTask ?? routeTask;
  const valid = n >= 1 && n <= 3;
  const taskCode = skillTaskCodeOf(section, n);
  const base = hrefOf(n);

  const pickTask = useCallback(
    (task: number) => {
      setPickedTask(task);
      replaceUrlShallow(hrefOf(task));
    },
    [hrefOf],
  );

  const level = useParcoursLevel();
  const ready = status === "authenticated" && valid;

  // Un seul appel pour toute l'épreuve, mémorisé pour la session : revenir sur
  // cet écran depuis « Sujets » ou « Examens » ne redemande rien.
  const skillsQuery = useCachedData(
    ready ? skillsSectionKey(section) : null,
    () => loadSectionSkills(skillApi, section),
    {errorMessage: "Impossible de charger les compétences."},
  );
  const skills = skillsOfTask(skillsQuery.data, taskCode);
  const loading = skillsQuery.loading;
  const error = skillsQuery.error;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={base} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <SkillShell backHref={TCF_HUB_HREF} backLabel={TCF_HUB_LABEL}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <SkillShell
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        title={config.label}
        meta={config.epreuveMeta}
        level={level}
      >
        <ParcoursTop
          config={config}
          mode="competences"
          taskNumero={n}
          onPickTask={pickTask}
        />

        <SectionHead
          title={`Compétences de la tâche ${n}`}
          text="Chaque compétence contient plusieurs petits sujets de production."
        />

        {error && <div className={s.error}>{error}</div>}

        {loading ? (
          <p className={s.empty}>Chargement des compétences…</p>
        ) : skills.length === 0 ? (
          <p className={s.empty}>Aucune compétence disponible pour cette tâche.</p>
        ) : (
          <div className={s.list}>
            {skills.map((skill) => (
              <SkillCard
                key={skill.id}
                skill={skill}
                onOpen={() => router.push(`${base}/${skill.id}`)}
              />
            ))}
          </div>
        )}

        <SkillNotice title="Principe pédagogique">
          Tu produis directement, sans modèle sous les yeux. Chaque petit sujet travaille
          un seul critère attendu au TCF, et les références n&apos;apparaissent qu&apos;après
          ta réponse.
        </SkillNotice>
      </SkillShell>
    </DualChromeShell>
  );
}

/**
 * Ligne d'une compétence, structure de la maquette client : **anneau de
 * progression** (« 2/5 »), titre, état en clair, chevron.
 *
 * Le titre et l'état, rien d'autre : la description vit derrière la pastille
 * d'information de l'écran de détail (parité mobile). Six lignes de texte par
 * carte repoussaient la 8ᵉ compétence hors de vue.
 */
function SkillCard({skill, onOpen}: {skill: SkillDto; onOpen: () => void}) {
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;

  return (
    <button
      type="button"
      className={`${s.card} ${s.rowCard} ${s.ringRow}`}
      onClick={onOpen}
    >
      <SkillRing attempted={skill.attemptedCount} total={skill.promptCount} done={done} />
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{skill.title}</span>
        <span className={s.rowState}>{competenceProgressLabel(skill)}</span>
      </span>
      <RowChevron />
    </button>
  );
}
