"use client";

import {useParams, useRouter} from "next/navigation";
import {useState} from "react";
import {Lock} from "lucide-react";
import {skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {competenceProgressLabel} from "@/lib/skill-progress";
import {useCachedData} from "@/lib/use-cached-data";
import {
  productionTaskTitle,
  skillSectionOf,
  type SkillDto,
  skillTaskCodeOf,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
import {useParcoursLevel} from "@/app/_components/production/parcours";
import {TaskChrome} from "@/app/_components/production/TaskChrome";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  RowChevron,
  SectionHead,
  SkillLockBadge,
  SkillMasteryPill,
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
 * L'écran suit la maquette client : c'est le **premier onglet du détail d'une
 * tâche**, sous la carte de consigne partagée (`TaskChrome`). Le second onglet
 * est la liste des sujets d'examen de la même tâche ; on change de tâche en
 * remontant à la liste des tâches de l'épreuve, plus par des pastilles T1/T2/T3
 * — le sélecteur mettait trois tâches au même niveau qu'un mode de travail.
 */
export function CompetencesList({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string}>();
  const router = useRouter();
  const {user, status} = useAuth();

  const section = skillSectionOf(config.epreuve);

  // Les 24 compétences de l'épreuve arrivent en un appel, mémorisé pour la
  // session : passer d'un onglet à l'autre, ou d'une tâche à l'autre, ne
  // redemande rien. La tâche vient de l'URL, et d'elle seule — chaque tâche est
  // une adresse partageable, et c'est celle où le Plan route ses étapes.
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const taskCode = skillTaskCodeOf(section, n);
  const base = `${config.base}/tache/${n}/competences`;

  const level = useParcoursLevel();
  const ready = status === "authenticated" && valid;
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Un seul appel pour toute l'épreuve, mémorisé pour la session : revenir sur
  // cet écran depuis l'onglet « Sujets d'examen » ne redemande rien.
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
        <SkillShell backHref={config.base} backLabel={config.label}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <SkillShell
        backHref={config.base}
        backLabel={config.label}
        title={productionTaskTitle(config.epreuve, n)}
        meta={`${config.label} · Tâche ${n}`}
        level={level}
      >
        <TaskChrome config={config} taskNumero={n} tab="competences" />

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
          /* Les huit compétences dans un seul cadre, filets entre les lignes —
             la liste de la maquette (`PlanTacheScreen`). Huit cartes autonomes
             repoussaient la dernière hors de vue. */
          <div className={s.groupCard}>
            {skills.map((skill) => (
              <SkillRow
                key={skill.id}
                skill={skill}
                onOpen={
                  skill.locked
                    ? () => setPaywallOpen(true)
                    : () => router.push(`${base}/${skill.id}`)
                }
              />
            ))}
          </div>
        )}

        <SkillNotice title="Principe pédagogique">
          Tu produis directement, sans modèle sous les yeux. Chaque petit sujet travaille
          un seul critère attendu au TCF, et les références n&apos;apparaissent qu&apos;après
          ta réponse.
        </SkillNotice>

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Toutes les compétences"
          message="Cette compétence est réservée à l'abonnement Intégral. Il ouvre les 8 compétences de chaque tâche, tous leurs petits sujets et l'analyse IA sans limite. Ton plan personnalisé, lui, reste entier."
        />
      </SkillShell>
    </DualChromeShell>
  );
}

/**
 * Ligne d'une compétence : **anneau de progression** (« 2/5 »), titre, état,
 * chevron — dans la liste groupée de la maquette.
 *
 * ⚠️ **L'état de maîtrise remplace le compteur de sujets traités** (décision
 * propriétaire) : un compte de sujets dit ce que le candidat a *fait*,
 * `masteryState` dit ce qu'il *maîtrise* — c'est la question qu'il se pose.
 * `masteryState` nul (aucune observation) est le seul cas où le compteur reste
 * pertinent : le serveur n'a encore rien vu, il n'y a pas d'état à annoncer.
 *
 * Le titre et l'état, rien d'autre : la description vit derrière la pastille
 * d'information de l'écran de détail (parité mobile). Six lignes de texte par
 * ligne repoussaient la 8ᵉ compétence hors de vue.
 *
 * Verrouillée (`locked`, **décidé par le serveur**), la ligne reste entièrement
 * lisible : seuls l'anneau — qui n'aurait rien à raconter — et la destination
 * changent. Masquer ou flouter la compétence reviendrait à cacher au candidat
 * ce qu'il y a à travailler ; c'est l'inverse de ce qu'on lui vend.
 */
function SkillRow({skill, onOpen}: {skill: SkillDto; onOpen: () => void}) {
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;
  const locked = skill.locked;

  return (
    <button type="button" className={s.groupRow} onClick={onOpen}>
      {locked ? (
        <span className={`${s.tile} ${s.tileLocked}`} aria-hidden>
          <Lock size={20} />
        </span>
      ) : (
        <SkillRing attempted={skill.attemptedCount} total={skill.promptCount} done={done} />
      )}
      <span className={s.groupBody}>
        <span className={s.groupTitle}>{skill.title}</span>
        <span className={s.groupMeta}>
          {skill.masteryState ? (
            <SkillMasteryPill state={skill.masteryState} />
          ) : (
            <span className={s.metaText}>{competenceProgressLabel(skill)}</span>
          )}
        </span>
      </span>
      <span className={s.groupAside}>
        {locked && <SkillLockBadge />}
        <RowChevron />
      </span>
    </button>
  );
}
