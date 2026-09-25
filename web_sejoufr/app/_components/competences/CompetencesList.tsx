"use client";

import {useParams, useRouter, useSearchParams} from "next/navigation";
import {useState} from "react";
import {skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {competenceBadge, competenceStatus} from "@/lib/expression";
import {isPlanStep, PLAN_STEP_BACK_LABEL} from "@/lib/plan-step";
import {usePlanStepPurchaseOrigin} from "@/app/_components/plan/use-plan-journey-id";
import {loadSectionSkills, skillsOfTask, skillsSectionKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {
  skillSectionOf,
  type SkillDto,
  skillTaskCodeOf,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
import {TaskChrome} from "@/app/_components/production/TaskChrome";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  SectionHead,
  SkillBadge,
  SkillLockBadge,
  SkillNotice,
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
 * ⚠️ **On n'y entre plus que depuis le Plan** (demande du propriétaire,
 * 2026-09-20) : l'écran d'une tâche n'a plus d'onglet « Compétences ». Le Plan
 * route ses tâches d'expression ici, puis d'ici vers la fiche d'une compétence.
 *
 * L'écran garde la carte de consigne partagée (`TaskChrome`) ; on change de
 * tâche en remontant au Plan, plus par des pastilles T1/T2/T3 — le sélecteur
 * mettait trois tâches au même niveau qu'un mode de travail.
 */
export function CompetencesList({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string}>();
  const router = useRouter();
  const searchParams = useSearchParams();
  const {user, status} = useAuth();

  /* D'où vient-on ? Le marqueur d'URL le dit, et lui seul : le Plan route ses
     tâches vers cet écran, or son retour hiérarchique (« ← Expression orale »)
     déposait le candidat dans `/entrainement`, loin du Plan qu'il venait de
     quitter. Le retour suit donc la **provenance**, et son libellé avec — un
     lien qui annonce une destination et en sert une autre serait pire que le
     défaut qu'on corrige. Sans marqueur : comportement d'avant, au pixel près. */
  const fromPlan = isPlanStep(searchParams);
  const backHref = fromPlan ? "/plan" : config.base;
  const backLabel = fromPlan ? PLAN_STEP_BACK_LABEL : config.label;
  const origin = usePlanStepPurchaseOrigin(fromPlan, "OTHER");

  const section = skillSectionOf(config.epreuve);

  // Les 24 compétences de l'épreuve arrivent en un appel, mémorisé pour la
  // session : passer d'une tâche à l'autre ne redemande rien. La tâche vient de
  // l'URL, et d'elle seule — chaque tâche est une adresse partageable, et c'est
  // celle où le Plan route ses étapes.
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const taskCode = skillTaskCodeOf(section, n);
  const base = `${config.base}/tache/${n}/competences`;

  const ready = status === "authenticated" && valid;
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Un seul appel pour toute l'épreuve, mémorisé pour la session : revenir sur
  // cet écran depuis une fiche de compétence ne redemande rien.
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
        <SkillShell backHref={backHref} backLabel={backLabel}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <SkillShell backHref={backHref} backLabel={backLabel}>
        <TaskChrome config={config} taskNumero={n} />

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
          ctaLocation={origin.ctaLocation}
          journeyId={origin.journeyId}
          screen="competences"
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
 * Ligne d'une compétence : titre, ligne d'état, pastille — la liste de la
 * maquette `~/Desktop/sejourfr_ecrans/detail_tache.png`.
 *
 * 🛑 **« Acquis » ⇔ `masteryState === "SOLID"`, et rien d'autre** (arbitrage du
 * 2026-09-12) : transfert **prouvé sur une production complète**, pas une série
 * de micro-exercices terminée. La ligne d'état dit les deux — « Acquis »,
 * « Série terminée · 5/5 », « En cours · 2/5 réussis », « À découvrir » — parce
 * que les confondre reproduirait le défaut que le dépôt nomme « NON FRAGILE ≠
 * PLUS RIEN À APPRENDRE ». Tout vient de `lib/expression.ts`.
 *
 * ⚠️ **Sans palier sur la pastille** : le serveur sait dire « cette compétence
 * est solide », jamais « tu l'as au A2 mais pas au B2 ».
 *
 * ⚠️ L'anneau de progression a quitté la ligne (maquette `detail_tache.png`) :
 * il répétait en image ce que la ligne d'état dit en mots.
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
  const badge = competenceBadge(skill);
  const locked = skill.locked;

  return (
    /* 🛑 **Pas de pastille de cadenas dans le corps de la ligne.** Elle n'était
       rendue que sur les lignes verrouillées : la liste partait en dents de
       scie, avec deux niveaux d'indentation selon l'accès — et le cadenas y
       apparaissait DEUX fois, la pastille doublant le badge « Premium » de
       droite. La maquette `detail_tache.png` aligne les huit lignes, titre à
       gauche, badge à droite. Le verrou reste dit, une fois, par le badge. */
    <button type="button" className={s.groupRow} onClick={onOpen}>
      <span className={s.groupBody}>
        <span className={s.groupTitle}>{skill.title}</span>
        <span className={s.groupMeta}>
          <span className={s.metaText}>{competenceStatus(skill)}</span>
        </span>
      </span>
      <span className={s.groupAside}>
        {locked ? (
          <SkillLockBadge />
        ) : (
          <SkillBadge tone={BADGE_TONE[badge.tone]}>{badge.label}</SkillBadge>
        )}
      </span>
    </button>
  );
}

/** Les trois tons de `competenceBadge`, rendus avec les tons **existants** de
 *  `SkillBadge` — aucune teinte nouvelle n'entre par cet écran. */
const BADGE_TONE = {
  acquis: "validated",
  encours: "treated",
  afaire: "todo",
} as const;
