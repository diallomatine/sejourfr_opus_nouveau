"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Check, Lock } from "lucide-react";
import { ApiException, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { tcfNoteTone } from "@/lib/production-feedback";
import {
  canAccessModule,
  formatNoteSur20,
  productionTaskSubtitle,
  productionTaskTitle,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
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
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const router = useRouter();
  const { user, status } = useAuth();

  const [filter, setFilter] = useState<SubjectFilter>("all");
  const [tasks, setTasks] = useState<ProductionTaskDto[]>([]);
  // Dernière soumission par sujet (productionTaskId) → distinction fait/à faire.
  const [doneByTask, setDoneByTask] = useState<Record<string, ProductionSubmissionDto>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral.
  // Non-abonné : seul le 1er sujet est ouvert, le reste est cadenassé (parité
  // avec les séries CO/CE/Structure et l'app mobile).
  const isPremium = user ? canAccessModule(user, "TCF") : false;

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .listTasks({ epreuve: config.epreuve, tacheNumero: n })
      .then((list) => {
        if (!cancelled) {
          // Filtre défensif : certains backends ignorent `tacheNumero` sans niveau.
          setTasks(
            list
              .filter((t) => t.tacheNumero === n)
              .sort((a, b) => a.niveauCible.localeCompare(b.niveauCible)),
          );
        }
      })
      .catch((e) => {
        if (!cancelled)
          setError(e instanceof ApiException ? e.message : "Impossible de charger les sujets.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, valid, n, config.epreuve]);

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    productionApi
      .listMine({ epreuve: config.epreuve })
      .then((subs) => {
        if (cancelled) return;
        // On garde la soumission la plus récente par sujet (submittedAt desc).
        const map: Record<string, ProductionSubmissionDto> = {};
        for (const sub of subs) {
          const prev = map[sub.productionTaskId];
          if (!prev || sub.submittedAt > prev.submittedAt) map[sub.productionTaskId] = sub;
        }
        setDoneByTask(map);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, valid, config.epreuve]);

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
      </SkillShell>
    </DualChromeShell>
  );
}
