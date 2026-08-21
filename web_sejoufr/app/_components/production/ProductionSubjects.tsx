"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Check, Lock } from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  latestSubmissionByTask,
  loadEpreuveTasks,
  loadMySubmissions,
  productionMineKey,
  productionTasksKey,
  tasksOfTache,
} from "@/lib/production-catalog";
import {
  TACHE_NON_EVALUABLE_LABEL,
  TACHE_TRAITEE_LABEL,
  productionNonEvaluable,
  tacheNiveau,
  tacheNiveauLabel,
  tacheNiveauTone,
} from "@/lib/production-feedback";
import { prodQuotaInfoKey, shouldAnnounceFreeTrial } from "@/lib/production-quota-info";
import { useCachedData } from "@/lib/use-cached-data";
import {
  canAccessModule,
  productionSubjectTitle,
  productionTaskConstraint,
  productionTaskTitle,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  SectionHead,
  SkillBadge,
  type SkillBadgeTone,
  SkillFilterRow,
  SkillNotice,
  type SkillRowMark,
  SkillRowCard,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import {useParcoursLevel} from "./parcours";
import {TaskChrome} from "./TaskChrome";
import s from "@/app/_components/skill-ui/skill.module.css";
import { type ProductionConfig } from "./config";

type SubjectFilter = "all" | "todo" | "done";

/** Un sujet fait se lit par son PALIER TCF (cf. `tacheNiveauTone`), jamais par
 *  une note : une tâche isolée n'en a pas au TCF, et aucun palier ne se peint en
 *  rouge. `neutral` = fait mais pas encore évalué → simplement « traité ». */
const TONE_BADGE: Record<ReturnType<typeof tacheNiveauTone>, SkillBadgeTone> = {
  neutral: "treated",
  amber: "reinforce",
  blue: "treated",
  green: "validated",
};

const TONE_MARK: Record<ReturnType<typeof tacheNiveauTone>, SkillRowMark> = {
  neutral: "done",
  amber: "reinforce",
  blue: "done",
  green: "validated",
};

/**
 * Sujets d'examen d'une tâche productive — le **second onglet du détail d'une
 * tâche**, sous la carte de consigne partagée (`TaskChrome`) : filtres avec
 * compteurs, puis les cartes de sujet.
 *
 * Les **exemples** ne sont pas un espace de la tâche : c'est une ressource
 * d'appoint, atteinte par un lien discret en tête de la liste et rendue sur sa
 * propre page (`ProductionExamples`). En faire un onglet mettait sur le même
 * plan « je produis » et « je lis un modèle ».
 *
 * L'écran est strictement le même en expression écrite et en expression orale :
 * seuls l'accent (`--skill-accent`) et la zone de production changent.
 */
export function ProductionSubjects({ config }: { config: ProductionConfig }) {
  const params = useParams<{ n: string }>();
  const router = useRouter();
  const { user, status } = useAuth();

  // Les sujets des 3 tâches arrivent en un seul appel, mémorisé pour la
  // session : passer d'un onglet à l'autre, ou d'une tâche à l'autre, ne
  // redemande rien. La tâche vient de l'URL, et d'elle seule — chaque tâche est
  // une adresse partageable.
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;

  const [filter, setFilter] = useState<SubjectFilter>("all");
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [quotaInfoOpen, setQuotaInfoOpen] = useState(false);

  const level = useParcoursLevel();
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

  // EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral.
  // Non-abonné : seul le 1er sujet est ouvert, le reste est cadenassé (parité
  // avec les séries CO/CE/Structure et l'app mobile).
  const isPremium = user ? canAccessModule(user, "TCF") : false;

  // Info one-time pour les comptes gratuits : 1 essai d'entraînement offert par
  // épreuve (EE et EO), évalué par l'IA, + 1 examen blanc de production offert
  // (`ProductionAccessService.enforceQuota` / `AttemptService`).
  //
  // Elle vit ICI, sur la liste des sujets TCF complets, et nulle part ailleurs :
  // c'est le seul écran de l'épreuve où cette règle s'applique, et il précède
  // l'écran de production qui consomme l'essai — on annonce avant, pas après un
  // 403. Surtout PAS sur l'écran d'entrée (mode « Compétences ») : les
  // micro-exercices ne verrouillent aucun sujet et ont leur propre quota
  // (3 analyses IA offertes), l'y afficher annoncerait une règle fausse.
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

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/tache/${n}`} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <SkillShell backHref={config.base} backLabel={config.label}>
          <p className={s.empty}>Tâche inconnue.</p>
        </SkillShell>
      </DualChromeShell>
    );
  }

  const rows = tasks.map((t, i) => ({ task: t, index: i, sub: doneByTask[t.id] }));
  const doneCount = rows.filter((r) => r.sub).length;
  const todoCount = rows.length - doneCount;
  const shown = rows.filter((r) =>
    filter === "all" ? true : filter === "done" ? !!r.sub : !r.sub,
  );

  return (
    <DualChromeShell>
      <SkillShell
        backHref={config.base}
        backLabel={config.label}
        title={productionTaskTitle(config.epreuve, n)}
        meta={`${config.label} · Tâche ${n}`}
        level={level}
      >
        <TaskChrome config={config} taskNumero={n} tab="sujets" />

        {error && <div className={s.error}>{error}</div>}

        {loading ? (
          <p className={s.empty}>Chargement des sujets…</p>
        ) : rows.length === 0 ? (
          <p className={s.empty}>Aucun sujet disponible pour cette tâche.</p>
        ) : (
          <>
            <SkillFilterRow
              label="Filtrer les sujets"
              active={filter}
              onPick={setFilter}
              filters={[
                { key: "all", label: "Tous", count: rows.length },
                { key: "todo", label: "À faire", count: todoCount },
                { key: "done", label: "Traités", count: doneCount },
              ]}
            />

            <SectionHead
              title="Sujets d'entraînement"
              text={
                config.mode === "audio"
                  ? "Choisissez un sujet, enregistrez votre réponse, recevez votre correction."
                  : "Choisissez un sujet, rédigez votre réponse, recevez votre correction."
              }
              action={
                <Link href={`${config.base}/tache/${n}/exemples`} className={s.headLink}>
                  Exemples corrigés →
                </Link>
              }
            />

            {shown.length === 0 ? (
              <p className={s.empty}>
                {filter === "done"
                  ? "Aucun sujet traité pour l'instant."
                  : "Tous les sujets sont traités. Bravo !"}
              </p>
            ) : (
              <div className={s.list}>
                {shown.map(({ task: t, index: i, sub }) => {
                  const locked = !isPremium && i > 0;
                  const done = !!sub;
                  const niveau = tacheNiveau(sub?.evaluation);
                  const tone = tacheNiveauTone(niveau);
                  const constraint = productionTaskConstraint(t, config.mode === "audio");
                  return (
                    <SkillRowCard
                      key={t.id}
                      tile={
                        locked ? (
                          <Lock size={20} aria-hidden />
                        ) : done ? (
                          <Check size={22} strokeWidth={2.8} aria-hidden />
                        ) : (
                          i + 1
                        )
                      }
                      tileDone={done && !locked}
                      mark={done && !locked ? TONE_MARK[tone] : "none"}
                      /* Intitulé éditorial du sujet quand la base en porte un,
                         « Sujet N » sinon : la consigne reste dessous dans les
                         deux cas, donc aucun repli ne laisse la carte muette. */
                      title={productionSubjectTitle(t.titre, i + 1)}
                      text={t.consigne}
                      meta={
                        <>
                          {done ? (
                            <SkillBadge
                              tone={TONE_BADGE[tone]}
                              icon={<Check size={11} strokeWidth={2.6} aria-hidden />}
                            >
                              {/* Trois états sans niveau, jamais confondus :
                                  rien de rendu au correcteur (« Traité »),
                                  rendu mais rien à observer (« Non analysée »),
                                  corrigé sans niveau affichable — ce dernier
                                  retombe aussi sur « Traité » ici, la carte
                                  d'un sujet ne distinguant pas les deux. */}
                              {niveau
                                ? tacheNiveauLabel(niveau)
                                : productionNonEvaluable(sub?.evaluation)
                                  ? TACHE_NON_EVALUABLE_LABEL
                                  : TACHE_TRAITEE_LABEL}
                            </SkillBadge>
                          ) : locked ? (
                            <SkillBadge tone="todo" icon={<Lock size={10} aria-hidden />}>
                              Premium
                            </SkillBadge>
                          ) : (
                            <SkillBadge tone="todo">À faire</SkillBadge>
                          )}
                          {/* Contrainte réelle du sujet puis sa tâche — le
                              palier, lui, est annoncé une fois pour toutes par
                              le badge « NIVEAU VISÉ » de l'en-tête : le répéter
                              sur chaque carte noyait la seule information qui
                              change d'un sujet à l'autre. */}
                          {constraint && <SkillBadge tone="todo">{constraint}</SkillBadge>}
                          <SkillBadge tone="todo">Tâche {t.tacheNumero}</SkillBadge>
                        </>
                      }
                      onClick={
                        locked
                          ? () => setPaywallOpen(true)
                          : () =>
                              router.push(`${config.base}/${config.inputSegment}/${t.id}`)
                      }
                    />
                  );
                })}
              </div>
            )}
          </>
        )}

        <SkillNotice title="Comment ces sujets sont évalués">
          Chaque sujet est une production complète : l&apos;IA la situe sur les paliers du
          TCF et vous rend un niveau, puis détaille ce qui est réussi et vos deux
          priorités.
        </SkillNotice>

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          message="Le 1er sujet est offert pour découvrir l'épreuve. Passez à l'abonnement Intégral pour débloquer tous les sujets et leurs corrigés."
        />

        <ConfirmSheet
          open={quotaInfoOpen}
          tone="info"
          title="Un essai gratuit par épreuve"
          message={`Vous disposez d'un essai d'entraînement gratuit en ${config.label.toLowerCase()}, évalué par l'IA (votre niveau sur les paliers du TCF), ainsi qu'un examen blanc complet offert. Pour vous entraîner sans limite, passez à l'abonnement Intégral.`}
          onClose={dismissQuotaInfo}
        />
      </SkillShell>
    </DualChromeShell>
  );
}
