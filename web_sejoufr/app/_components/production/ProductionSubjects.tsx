"use client";

import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { BookOpen, Check, ChevronDown, Headphones, Lock, Play, RefreshCw } from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  latestSubmissionByTask,
  loadEpreuveTasks,
  loadExamples,
  loadMySubmissions,
  productionExamplesKey,
  productionMineKey,
  productionTasksKey,
  tasksOfTache,
} from "@/lib/production-catalog";
import {
  TACHE_EVALUEE_LABEL,
  TACHE_NON_EVALUABLE_LABEL,
  TACHE_TRAITEE_LABEL,
  productionNonEvaluable,
  tacheNiveau,
  tacheNiveauLabel,
  tacheNiveauTone,
} from "@/lib/production-feedback";
import {
  SUBJECTS_ALL_DONE,
  SUBJECTS_EMPTY,
  SUBJECTS_NONE_DONE,
  SUBJECTS_PAGE_SIZE,
  SUBJECTS_TITLE,
  SUBJECT_DETAIL_CTA,
  SUBJECT_FILTER_ALL,
  SUBJECT_FILTER_DONE,
  SUBJECT_FILTER_TODO,
  SUBJECT_REDO_CTA,
  SUBJECT_TODO,
  examplesLinkLabel,
  lastEvaluationLabel,
  showMoreLabel,
  subjectFilterLabel,
  subjectsHint,
} from "@/lib/production-task-labels";
import { prodQuotaInfoKey, shouldAnnounceFreeTrial } from "@/lib/production-quota-info";
import { useCachedData } from "@/lib/use-cached-data";
import { isPlanStep } from "@/lib/plan-step";
import { usePlanStepPurchaseOrigin } from "@/app/_components/plan/use-plan-journey-id";
import {
  canAccessModule,
  productionSubjectTitle,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { ExamDoneSheet } from "@/app/_components/hub/ExamDoneSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  SectionHead,
  SkillBadge,
  type SkillBadgeTone,
  SkillFilterRow,
  SkillLockBadge,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import {TaskChrome} from "./TaskChrome";
import s from "@/app/_components/skill-ui/skill.module.css";
import t from "./task.module.css";
import { type ProductionConfig } from "./config";

type SubjectFilter = "all" | "todo" | "done";

type NiveauTone = ReturnType<typeof tacheNiveauTone>;

/** Un sujet fait se lit par son PALIER TCF (cf. `tacheNiveauTone`), jamais par
 *  une note : une tâche isolée n'en a pas au TCF, et aucun palier ne se peint en
 *  rouge. `neutral` = fait mais sans niveau affichable → vert « terminé », comme
 *  `ProductionSubjectCard` côté mobile. */
const TONE_BADGE: Record<NiveauTone, SkillBadgeTone> = {
  neutral: "validated",
  amber: "reinforce",
  blue: "treated",
  green: "validated",
};

const TONE_CLASS: Record<NiveauTone, string> = {
  neutral: t.toneGreen,
  amber: t.toneAmber,
  blue: t.toneBlue,
  green: t.toneGreen,
};

/** L'état d'un sujet traité, en toutes lettres — trois états sans niveau,
 *  jamais confondus : rien de rendu au correcteur (« Traité »), rendu mais rien
 *  à observer (« Non analysée »), corrigé sans niveau affichable (« Évaluée »).
 *  Miroir de la feuille `_openDoneSheet` (mobile). */
function doneStateLabel(sub: ProductionSubmissionDto): string {
  const niveau = tacheNiveau(sub.evaluation);
  if (niveau) return tacheNiveauLabel(niveau);
  if (!sub.evaluation) return TACHE_TRAITEE_LABEL;
  return productionNonEvaluable(sub.evaluation) ? TACHE_NON_EVALUABLE_LABEL : TACHE_EVALUEE_LABEL;
}

/**
 * Sujets d'entraînement d'une tâche productive — le **seul contenu du détail
 * d'une tâche** depuis que les compétences ne se travaillent plus que via le
 * Plan (2026-09-20). Miroir de `ProductionTaskScreen` +
 * `ProductionSubjectsView` (mobile), brique pour brique : tête de tâche avec
 * son retour et sa consigne (`TaskChrome`), filtres Tous / À faire / Traités
 * avec compteurs, intertitre et lien discret vers les exemples corrigés, puis
 * des cartes compactes (numéro, titre sur une ligne, extrait de consigne sur
 * deux, pastille d'état, bouton rond). La tâche et sa durée sont dites UNE fois
 * par la tête : aucune carte ne les répète.
 *
 * **« Traité »** = au moins une production du candidat sur ce sujet, quels que
 * soient son statut et sa session (`latestSubmissionByTask`) — la règle du
 * « N/M sujets » servi par `/api/me/dashboard` et celle du mobile
 * (`ProductionCatalog.lastByTaskId`). Rien n'est recompté autrement ici.
 *
 * Sujet non fait → l'entraînement démarre ; sujet fait → feuille « Voir le
 * détail / Refaire » ; sujet verrouillé → paywall. Le verrou suit **l'index
 * d'origine**, jamais l'index filtré (aucun `locked` n'est servi pour les
 * sujets de production, cf. `docs/regles/freemium.md`).
 *
 * Grand écran : la tête passe en bandeau (tête | consigne), les cartes en
 * grille de deux colonnes dès 700 px de conteneur.
 */
export function ProductionSubjects({ config }: { config: ProductionConfig }) {
  const params = useParams<{ n: string }>();
  const router = useRouter();
  const { user, status } = useAuth();
  /* Repli d'une vérification du Plan sans tâche désignée : le marqueur d'étape
     dit la provenance, et le verrou est alors le CTA du Plan (contrôle F). */
  const origin = usePlanStepPurchaseOrigin(isPlanStep(useSearchParams()), "OTHER");

  // La tâche vient de l'URL, et d'elle seule — chaque tâche est une adresse
  // partageable.
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const isOral = config.mode === "audio";

  const [filter, setFilter] = useState<SubjectFilter>("all");
  const [showAll, setShowAll] = useState(false);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [quotaInfoOpen, setQuotaInfoOpen] = useState(false);
  const [doneRow, setDoneRow] = useState<{
    task: ProductionTaskDto;
    sub: ProductionSubmissionDto;
    order: number;
  } | null>(null);

  const ready = status === "authenticated" && valid;

  // Catalogue : les 3 tâches en un appel, mémorisé pour la session.
  const tasksQuery = useCachedData(
    ready ? productionTasksKey(config.epreuve) : null,
    () => loadEpreuveTasks(productionApi, config.epreuve),
    { errorMessage: "Impossible de charger les sujets." },
  );
  const tasks = tasksOfTache(tasksQuery.data, n);
  const loading = tasksQuery.loading;
  const error = tasksQuery.error;

  // Progression : mise en cache aussi, mais invalidée à chaque soumission
  // (`lib/api.ts`) — sinon un sujet rendu resterait affiché « à faire ».
  // Même entrée que la grille des examens blancs : un seul appel pour les deux.
  const minesQuery = useCachedData(ready ? productionMineKey(config.epreuve) : null, () =>
    loadMySubmissions(productionApi, config.epreuve),
  );
  const doneByTask = latestSubmissionByTask(minesQuery.data);

  // Les modèles : seul le compteur du lien en dépend, il ne retient jamais la
  // liste. Même entrée que la page des exemples, qui s'ouvre donc sans appel.
  const examplesQuery = useCachedData(
    ready ? productionExamplesKey(config.epreuve, n) : null,
    () => loadExamples(productionApi, config.epreuve, n),
  );
  const examplesCount = examplesQuery.data?.length ?? 0;

  // EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral.
  // Non-abonné : seul le 1er sujet est ouvert, le reste est cadenassé (parité
  // avec les séries CO/CE/Structure et l'app mobile).
  const isPremium = user ? canAccessModule(user, "TCF") : false;

  // Info one-time pour les comptes gratuits : 1 examen blanc de production
  // offert par épreuve (`ProductionAccessService.enforceQuota`).
  //
  // Elle vit ICI, sur la liste des sujets TCF complets, et nulle part ailleurs :
  // c'est le seul écran de l'épreuve où cette règle s'applique, et il précède
  // l'écran de production — on annonce avant, pas après un 403. Surtout PAS
  // sur la liste des compétences, qui a ses propres règles.
  const quotaInfoKey = prodQuotaInfoKey(config.epreuve);
  useEffect(() => {
    if (typeof window === "undefined") return;
    const announce = shouldAnnounceFreeTrial({
      status,
      hasUser: !!user,
      isPremium: user ? canAccessModule(user, "TCF") : false,
      alreadySeen: !!window.localStorage.getItem(quotaInfoKey),
    });
    if (!announce) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setQuotaInfoOpen(true);
  }, [status, user, quotaInfoKey]);

  function dismissQuotaInfo() {
    setQuotaInfoOpen(false);
    try {
      window.localStorage.setItem(quotaInfoKey, "1");
    } catch {
      // stockage indisponible (navigation privée) : la modale reviendra.
    }
  }

  const taskHref = `${config.base}/tache/${n}`;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={taskHref} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <SkillShell backHref={config.base} backLabel={config.label}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  function practice(task: ProductionTaskDto) {
    router.push(`${config.base}/${config.inputSegment}/${task.id}`);
  }

  const rows = tasks.map((task, i) => ({ task, index: i, sub: doneByTask[task.id] }));
  const doneCount = rows.filter((r) => r.sub).length;
  const todoCount = rows.length - doneCount;
  const filtered = rows.filter((r) =>
    filter === "all" ? true : filter === "done" ? !!r.sub : !r.sub,
  );
  const visible = showAll ? filtered : filtered.slice(0, SUBJECTS_PAGE_SIZE);
  const remaining = filtered.length - visible.length;

  return (
    <DualChromeShell>
      <SkillShell backHref={config.base} backLabel={config.label} wide hideBack>
        <TaskChrome
          config={config}
          taskNumero={n}
          backHref={config.base}
          backLabel={config.label}
        />

        <div className={t.body}>
          {error && <div className={s.error}>{error}</div>}

          {loading ? (
            <p className={s.empty}>Chargement des sujets…</p>
          ) : rows.length === 0 ? (
            <p className={t.hint}>{SUBJECTS_EMPTY}</p>
          ) : (
            <>
              <SkillFilterRow
                label="Filtrer les sujets"
                active={filter}
                onPick={(key) => {
                  setFilter(key);
                  setShowAll(false);
                }}
                filters={[
                  { key: "all", label: subjectFilterLabel(SUBJECT_FILTER_ALL, rows.length) },
                  { key: "todo", label: subjectFilterLabel(SUBJECT_FILTER_TODO, todoCount) },
                  { key: "done", label: subjectFilterLabel(SUBJECT_FILTER_DONE, doneCount) },
                ]}
              />

              <SectionHead
                title={SUBJECTS_TITLE}
                text={subjectsHint(isOral)}
                action={
                  <Link href={`${taskHref}/exemples`} className={t.sideLink}>
                    {isOral ? (
                      <Headphones size={14} aria-hidden />
                    ) : (
                      <BookOpen size={14} aria-hidden />
                    )}
                    {examplesLinkLabel(examplesCount)}
                  </Link>
                }
              />

              {filtered.length === 0 ? (
                <p className={t.hint}>
                  {filter === "done" ? SUBJECTS_NONE_DONE : SUBJECTS_ALL_DONE}
                </p>
              ) : (
                <div className={t.grid}>
                  {visible.map(({ task, index: i, sub }) => (
                    <SubjectCard
                      key={task.id}
                      task={task}
                      order={i + 1}
                      sub={sub}
                      locked={!isPremium && i > 0}
                      onOpen={() => {
                        if (!isPremium && i > 0) {
                          setPaywallOpen(true);
                        } else if (sub) {
                          setDoneRow({ task, sub, order: i + 1 });
                        } else {
                          practice(task);
                        }
                      }}
                    />
                  ))}
                </div>
              )}

              {remaining > 0 && (
                <button type="button" className={t.more} onClick={() => setShowAll(true)}>
                  {showMoreLabel(remaining)}
                  <ChevronDown size={18} aria-hidden />
                </button>
              )}
            </>
          )}
        </div>

        <ExamDoneSheet
          open={doneRow !== null}
          title={doneRow ? productionSubjectTitle(doneRow.task.titre, doneRow.order) : ""}
          subtitle={doneRow ? lastEvaluationLabel(doneStateLabel(doneRow.sub)) : null}
          detailLabel={SUBJECT_DETAIL_CTA}
          resumeLabel={SUBJECT_REDO_CTA}
          resumeTone="blue"
          onViewDetail={() => {
            if (!doneRow) return;
            const href = `${config.base}/resultats/${doneRow.sub.id}?back=${encodeURIComponent(taskHref)}`;
            setDoneRow(null);
            router.push(href);
          }}
          onResume={() => {
            if (!doneRow) return;
            const task = doneRow.task;
            setDoneRow(null);
            practice(task);
          }}
          onClose={() => setDoneRow(null)}
        />

        <PaywallSheet
          ctaLocation={origin.ctaLocation}
          journeyId={origin.journeyId}
          screen="production_sujets"
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          reason="Les sujets d'entraînement et leur correction par l'IA font partie du pass Intégral."
        />

        <ConfirmSheet
          open={quotaInfoOpen}
          tone="info"
          title="Un examen blanc offert par épreuve"
          message={`Votre compte gratuit comprend un examen blanc complet en ${config.label.toLowerCase()}, corrigé par l'IA (votre niveau sur les paliers du TCF). S'entraîner sur les sujets fait partie du pass Intégral.`}
          onClose={dismissQuotaInfo}
        />
      </SkillShell>
    </DualChromeShell>
  );
}

/**
 * Carte compacte d'un sujet — miroir de `ProductionSubjectCard` (mobile) :
 * numéro sur deux chiffres (✓ une fois traité), titre sur une ligne, extrait
 * de consigne sur deux, puis la colonne d'état (pastille au-dessus, bouton rond
 * dessous). Le liseré n'existe que sur un sujet traité.
 */
function SubjectCard({
  task,
  order,
  sub,
  locked,
  onOpen,
}: {
  task: ProductionTaskDto;
  order: number;
  sub: ProductionSubmissionDto | undefined;
  locked: boolean;
  onOpen: () => void;
}) {
  const done = !!sub;
  const niveau = tacheNiveau(sub?.evaluation);
  const tone = tacheNiveauTone(niveau);
  const title = productionSubjectTitle(task.titre, order);
  const toneClass = done ? `${TONE_CLASS[tone]} ${t.subjectDone}` : "";

  return (
    <button type="button" className={`${t.subject} ${toneClass}`} onClick={onOpen}>
      <span
        className={`${t.tile} ${locked ? t.tileLocked : done ? t.tileDone : ""}`}
        aria-hidden
      >
        {done ? (
          <Check size={22} strokeWidth={2.6} />
        ) : (
          String(order).padStart(2, "0")
        )}
      </span>
      <span className={t.subjectBody}>
        <span className={t.subjectTitle} title={title}>
          {title}
        </span>
        <span className={t.subjectText}>{task.consigne}</span>
      </span>
      <span className={t.subjectSide}>
        {locked ? (
          <SkillLockBadge />
        ) : sub ? (
          <SkillBadge
            tone={TONE_BADGE[tone]}
            icon={niveau ? undefined : <Check size={11} strokeWidth={2.6} aria-hidden />}
          >
            {niveau
              ? tacheNiveauLabel(niveau)
              : productionNonEvaluable(sub.evaluation)
                ? TACHE_NON_EVALUABLE_LABEL
                : TACHE_TRAITEE_LABEL}
          </SkillBadge>
        ) : (
          <SkillBadge tone="todo">{SUBJECT_TODO}</SkillBadge>
        )}
        <span className={`${t.dot} ${locked ? t.dotLocked : ""}`} aria-hidden>
          {locked ? (
            <Lock size={16} />
          ) : done ? (
            <RefreshCw size={16} />
          ) : (
            <Play size={16} />
          )}
        </span>
      </span>
    </button>
  );
}
