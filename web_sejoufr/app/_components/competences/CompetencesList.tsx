"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {Check} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {sumProgress} from "@/lib/skill-progress";
import {
  productionTaskTitle,
  skillSectionOf,
  skillTaskCodeOf,
  type SkillDto,
  type SkillTaskProgressDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  type ProductionConfig,
  TCF_HUB_HREF,
  TCF_HUB_LABEL,
} from "@/app/_components/production/config";
import {
  MiniBar,
  RowChevron,
  SectionHead,
  SkillHero,
  SkillNotice,
  SkillShell,
  TaskPills,
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
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const router = useRouter();
  const {user, status} = useAuth();

  const section = skillSectionOf(config.epreuve);
  const taskCode = skillTaskCodeOf(section, n);
  const base = `${config.base}/tache/${n}/competences`;

  const [skills, setSkills] = useState<SkillDto[]>([]);
  const [taskProgress, setTaskProgress] = useState<SkillTaskProgressDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    skillApi
      .listSkills(taskCode)
      .then((list) => {
        if (!cancelled) setSkills([...list].sort((a, b) => a.displayOrder - b.displayOrder));
      })
      .catch((e) => {
        if (!cancelled)
          setError(
            e instanceof ApiException ? e.message : "Impossible de charger les compétences.",
          );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, valid, taskCode]);

  // Palier de la tâche, servi par l'agrégat par tâche. Best-effort : le hero
  // sait s'afficher sans sa pilule, et la progression, elle, se recalcule
  // toujours à partir des compétences déjà chargées (une seule source).
  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    skillApi
      .progress(section)
      .then((rows) => {
        if (!cancelled) setTaskProgress(rows.find((r) => r.taskCode === taskCode) ?? null);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, valid, section, taskCode]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={base} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <SkillShell config={config} backHref={TCF_HUB_HREF} backLabel={TCF_HUB_LABEL}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  // « Continuer » ouvre la première compétence non terminée, c'est-à-dire celle
  // où il reste des sujets jamais tentés. Tout terminé → on retombe sur la 1ʳᵉ,
  // qui reste rejouable : rien ne se ferme ici.
  const next = skills.find((k) => k.attemptedCount < k.promptCount) ?? skills[0];
  const overall = sumProgress(skills);
  const level = taskProgress?.targetLevel ?? skills[0]?.targetLevel ?? null;

  return (
    <DualChromeShell>
      <SkillShell
        config={config}
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        mode="competences"
        taskNumero={n}
      >
        <SkillHero
          eyebrow="Parcours TCF"
          title={productionTaskTitle(config.epreuve, n)}
          text="Travaille une compétence à la fois, puis réutilise-la dans un sujet complet."
          level={level}
          attempted={overall.attempted}
          total={overall.total}
          percent={overall.percent}
        />

        <SectionHead
          title="Choisis une tâche"
          text="Chaque tâche développe des compétences différentes."
        />
        <TaskPills
          config={config}
          current={n}
          labelOf={(i) => productionTaskTitle(config.epreuve, i)}
          hrefOf={(i) => `${config.base}/tache/${i}/competences`}
        />

        <SectionHead
          title={`Compétences de la tâche ${n}`}
          text="Chaque compétence contient plusieurs petits sujets de production."
          action={
            next && (
              <button
                type="button"
                className={s.headLink}
                onClick={() => router.push(`${base}/${next.id}`)}
              >
                Continuer →
              </button>
            )
          }
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

function SkillCard({skill, onOpen}: {skill: SkillDto; onOpen: () => void}) {
  const progress = sumProgress([skill]);
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;

  return (
    <button type="button" className={`${s.card} ${s.rowCard}`} onClick={onOpen}>
      <span className={`${s.tile} ${done ? s.tileDone : ""}`} aria-hidden>
        {done ? <Check size={22} strokeWidth={2.8} /> : skill.displayOrder}
      </span>
      {/* Le titre et la progression, rien d'autre : la description vit derrière
          la pastille d'information de l'écran de détail (parité mobile). Six
          lignes de texte par carte repoussaient la 8ᵉ compétence hors de vue. */}
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{skill.title}</span>
        <MiniBar
          attempted={progress.attempted}
          total={progress.total}
          percent={progress.percent}
        />
      </span>
      <RowChevron />
    </button>
  );
}
