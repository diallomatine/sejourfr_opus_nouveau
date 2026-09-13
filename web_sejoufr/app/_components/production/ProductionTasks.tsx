"use client";

import Link from "next/link";
import {useState} from "react";
import {ArrowRight, ClipboardCheck, Lock, Mic, PenLine} from "lucide-react";
import {learningPlanApi, productionApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {competenceHref} from "@/lib/diagnostic";
import {
  acquisesLabel,
  EXPRESSION_RECOMMENDED_CTA,
  EXPRESSION_RECOMMENDED_LABEL,
  exercicesReussisLabel,
  progressionVersObjectif,
  recommandationDuPlan,
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
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
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
 * progression vers l'objectif B2 »), la carte **« Recommandé pour vous »**,
 * puis **« Les 3 tâches »**. Les **examens blancs** restent en pied (demande
 * explicite du propriétaire) : ils portent sur l'épreuve entière, pas sur une
 * tâche, et leur route ne change pas d'un octet.
 *
 * 🛑 **« Recommandé » VIENT DU PLAN, jamais du catalogue.** `recommandationDuPlan`
 * lit la séance du jour, puis la priorité n°1, puis les suivantes — dans
 * l'ordre où le serveur les range. **Aucun repli** : le Plan classant les quatre
 * domaines par urgence, un candidat dont la priorité est en compréhension n'a
 * rien à recommander ici et **la carte disparaît**. Retomber sur « la première
 * case libre » recommanderait autre chose que le Plan.
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
  const reco = recommandationDuPlan(planQuery.data ?? null, section);
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
        {reco && <RecoCard config={config} reco={reco} />}

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
                  data-active={reco?.taskCode === skillTaskCodeOf(section, n)}
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

/**
 * La carte « Recommandé pour vous ».
 *
 * 🛑 **Verrouillée, elle reste DÉSIGNÉE** : la compétence garde son nom, et
 * c'est l'action qui ouvre l'offre. On ne masque jamais un constat — la règle
 * du dépôt ne floute que l'**action** fermée, et ici le Plan a déjà choisi de
 * nommer cette priorité.
 */
function RecoCard({
  config,
  reco,
}: {
  config: ProductionConfig;
  reco: NonNullable<ReturnType<typeof recommandationDuPlan>>;
}) {
  const [paywall, setPaywall] = useState(false);
  const compteur = exercicesReussisLabel(reco.validated, reco.total);
  const href = competenceHref(
    {skillId: reco.skillId, skillCode: reco.skillCode, section: reco.section},
    {planStep: true},
  );

  const body = (
    <>
      <span className={s.recoTag}>{EXPRESSION_RECOMMENDED_LABEL}</span>
      <span className={s.recoHead}>
        <span className={s.recoIcon} aria-hidden>
          {config.mode === "audio" ? <Mic size={24} /> : <PenLine size={24} />}
        </span>
        <span>
          <strong className={s.recoTitle}>{reco.title}</strong>
          {reco.taskCode && (
            <span className={s.recoWhere}>
              {tacheLabel(reco.taskCode)} · {config.label}
            </span>
          )}
        </span>
      </span>
      {compteur && <p className={s.recoCount}>{compteur}</p>}
    </>
  );

  if (reco.locked) {
    return (
      <>
        <section className={s.reco}>
          {body}
          <button
            type="button"
            className={s.recoCta}
            data-locked="true"
            onClick={() => setPaywall(true)}
          >
            <Lock size={18} aria-hidden />
            Débloquer cette compétence
          </button>
        </section>
        <PaywallSheet
          origin="plan"
          open={paywall}
          module="INTEGRAL"
          onClose={() => setPaywall(false)}
        />
      </>
    );
  }

  return (
    <Link href={href} className={s.reco}>
      {body}
      <span className={s.recoCta}>
        {EXPRESSION_RECOMMENDED_CTA}
        <ArrowRight size={18} aria-hidden />
      </span>
    </Link>
  );
}
