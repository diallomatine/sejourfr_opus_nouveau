"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
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
import { tcfNoteTone } from "@/lib/production-feedback";
import { prodQuotaInfoKey, shouldAnnounceFreeTrial } from "@/lib/production-quota-info";
import { replaceUrlShallow } from "@/lib/shallow-url";
import { useCachedData } from "@/lib/use-cached-data";
import {
  canAccessModule,
  formatNoteSur20,
  productionTaskSubtitle,
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
  SkillHero,
  SkillNotice,
  type SkillRowMark,
  SkillRowCard,
  SkillShell,
  TaskPills,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import { type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL } from "./config";

type SubjectFilter = "all" | "todo" | "done";

/** Un sujet fait se lit par son PALIER TCF (cf. `tcfNoteTone`) : la note n'est
 *  pas une note scolaire sur 20, et aucun palier ne se peint en rouge.
 *  `neutral` = fait mais pas encore évalué → simplement « traité ». */
const TONE_BADGE: Record<ReturnType<typeof tcfNoteTone>, SkillBadgeTone> = {
  neutral: "treated",
  amber: "reinforce",
  blue: "treated",
  green: "validated",
};

const TONE_MARK: Record<ReturnType<typeof tcfNoteTone>, SkillRowMark> = {
  neutral: "done",
  amber: "reinforce",
  blue: "done",
  green: "validated",
};

/**
 * Écran d'une tâche productive (T1/T2/T3) — le mode « Sujets TCF » de la
 * maquette client : hero de tâche, pastilles T1/T2/T3, deux espaces (sujets
 * complets · compétences), filtres avec compteurs et cartes de sujet.
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

  // Les sujets des 3 tâches arrivent en un seul appel : une pastille ne fait
  // donc que **filtrer** (aucun réseau, aucun remontage). La tâche est le choix
  // local s'il y en a eu un, sinon celle de l'URL — dans cet ordre, pour que
  // l'accès direct, le lien partagé et le retour navigateur continuent de
  // décider de la tâche d'arrivée sans jamais écraser un choix.
  const routeTask = Number(params?.n ?? "0");
  const [pickedTask, setPickedTask] = useState<number | null>(null);
  const n = pickedTask ?? routeTask;
  const valid = n >= 1 && n <= 3;

  const [filter, setFilter] = useState<SubjectFilter>("all");
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [quotaInfoOpen, setQuotaInfoOpen] = useState(false);

  const pickTask = useCallback(
    (task: number) => {
      setPickedTask(task);
      // Les compteurs du filtre portent sur la tâche affichée : garder « Traités »
      // en changeant de tâche montrerait une liste vide sans dire pourquoi.
      setFilter("all");
      replaceUrlShallow(`${config.base}/tache/${task}`);
    },
    [config.base],
  );

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
        <SkillShell config={config} backHref={TCF_HUB_HREF} backLabel={TCF_HUB_LABEL}>
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
        config={config}
        backHref={TCF_HUB_HREF}
        backLabel={TCF_HUB_LABEL}
        mode="sujets"
        taskNumero={n}
      >
        <SkillHero
          eyebrow={`${config.label} · Tâche ${n}`}
          title={productionTaskTitle(config.epreuve, n)}
          text={productionTaskSubtitle(config.epreuve, n)}
          level={null}
          attempted={doneCount}
          total={rows.length}
          percent={rows.length ? Math.round((doneCount / rows.length) * 100) : 0}
        />

        <SectionHead
          title="Choisissez une tâche"
          text="Chaque tâche a son format et ses attentes."
        />
        <TaskPills
          config={config}
          current={n}
          labelOf={(i) => productionTaskTitle(config.epreuve, i)}
          onPick={pickTask}
        />

        <SectionHead
          title="Sujets TCF complets"
          text="Une production entière, évaluée sur l'échelle du TCF."
          action={
            <Link href={`${config.base}/tache/${n}/exemples`} className={s.headLink}>
              Exemples →
            </Link>
          }
        />

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
                  const note = sub?.evaluation?.noteSurVingt ?? null;
                  const tone = tcfNoteTone(note);
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
                      title={`Sujet ${i + 1}`}
                      text={t.consigne}
                      meta={
                        <>
                          {done ? (
                            <SkillBadge
                              tone={TONE_BADGE[tone]}
                              icon={<Check size={11} strokeWidth={2.6} aria-hidden />}
                            >
                              {note != null ? `${formatNoteSur20(note)}/20` : "Traité"}
                            </SkillBadge>
                          ) : locked ? (
                            <SkillBadge tone="todo" icon={<Lock size={10} aria-hidden />}>
                              Premium
                            </SkillBadge>
                          ) : (
                            <SkillBadge tone="todo">À faire</SkillBadge>
                          )}
                          <SkillBadge tone="level">{t.niveauCible}</SkillBadge>
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

        <SkillNotice title="Comment ces sujets sont notés">
          Chaque sujet est une production complète : l&apos;IA la situe sur l&apos;échelle du
          TCF (note /20 et niveau), puis détaille ce qui est réussi et vos deux priorités.
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
          message={`Vous disposez d'un essai d'entraînement gratuit en ${config.label.toLowerCase()}, évalué par l'IA (note /20 + niveau CECRL), ainsi qu'un examen blanc complet offert. Pour vous entraîner sans limite, passez à l'abonnement Intégral.`}
          onClose={dismissQuotaInfo}
        />
      </SkillShell>
    </DualChromeShell>
  );
}
