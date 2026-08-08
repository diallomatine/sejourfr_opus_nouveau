"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useRef, useState} from "react";
import {Check, Info, Sparkles} from "lucide-react";
import {skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {cached} from "@/lib/data-cache";
import {skillDetailKey} from "@/lib/skill-catalog";
import {progressPercent} from "@/lib/skill-progress";
import {useCachedData} from "@/lib/use-cached-data";
import {
  SKILL_DIFFICULTY_LABEL,
  SKILL_PROMPT_STATUS_LABEL,
  type SkillPromptSummaryDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
import {ConfirmSheet} from "@/app/_components/hub/ConfirmSheet";
import {CompetenceStatusBadge, promptCardToneClass} from "./CompetenceStatusBadge";
import {MiniBar, RowChevron, SectionHead, SkillShell} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

type Filter = "all" | "todo" | "done";

/** Date courte d'une dernière tentative (« 4 août »). */
function shortDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("fr-FR", {day: "numeric", month: "long"});
}

/**
 * Niveau 4 de la spec, écran d'une compétence : ce qu'elle travaille, où en est
 * le candidat, et ses 5 petits sujets.
 *
 * La progression affichée est le nombre de **sujets traités**, pas de sujets
 * validés (spec §12) : on ne veut pas laisser croire qu'il faut tout valider
 * pour avancer — un sujet raté puis compris a fait son travail.
 */
export function CompetenceDetail({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string; skillId: string}>();
  const n = Number(params?.n ?? "0");
  const skillId = params?.skillId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;

  const [filter, setFilter] = useState<Filter>("all");
  const [infoOpen, setInfoOpen] = useState(false);
  const infoButtonRef = useRef<HTMLButtonElement>(null);

  // Mémorisé pour la session : aller sur un petit sujet puis revenir à la liste
  // ne recharge pas la compétence. L'entrée est purgée dès qu'une production ou
  // une analyse change le statut d'un sujet (`lib/api.ts`).
  const detailQuery = useCachedData(
    status === "authenticated" && skillId ? skillDetailKey(skillId) : null,
    () => cached(skillDetailKey(skillId), () => skillApi.getSkill(skillId)),
    {errorMessage: "Impossible de charger cette compétence."},
  );
  const data = detailQuery.data;
  const loading = detailQuery.loading;
  const error = detailQuery.error;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${base}/${skillId}`} />;

  const skill = data?.skill;
  const prompts = data?.prompts ?? [];
  const treated = prompts.filter((p) => p.status !== "TODO");
  const todo = prompts.filter((p) => p.status === "TODO");
  const shown = filter === "all" ? prompts : filter === "done" ? treated : todo;
  const pct = progressPercent(treated.length, prompts.length);
  const firstTodo = todo[0];

  const chips: [Filter, string, number][] = [
    ["all", "Tous", prompts.length],
    ["todo", SKILL_PROMPT_STATUS_LABEL.TODO, todo.length],
    ["done", "Traités", treated.length],
  ];

  return (
    <DualChromeShell>
      <SkillShell
        backHref={base}
        backLabel="Compétences"
      >
        {error && <div className={s.error}>{error}</div>}

        {loading ? (
          <p className={s.empty}>Chargement…</p>
        ) : !skill ? (
          <p className={s.empty}>Compétence introuvable.</p>
        ) : (
          <>
            <section className={`${s.card} ${s.summary}`}>
              <div className={s.summaryTop}>
                <span className={s.tile} aria-hidden>
                  <Sparkles size={22} strokeWidth={2.2} />
                </span>
                {/* Pas de pastille de niveau ici (parité mobile) : le palier
                    est celui de toute la tâche, il est déjà porté par le hero
                    de la liste des compétences et par l'écran d'un sujet. */}
                <div className={s.summaryBody}>
                  <h1 className={s.summaryTitle}>{skill.title}</h1>
                </div>
                {skill.description && (
                  <button
                    type="button"
                    ref={infoButtonRef}
                    className={s.infoBtn}
                    aria-label="À quoi sert cette compétence ?"
                    aria-haspopup="dialog"
                    onClick={() => setInfoOpen(true)}
                  >
                    <span className={s.infoDot} aria-hidden>
                      <Info size={15} strokeWidth={2.4} />
                    </span>
                  </button>
                )}
              </div>

              <div className={s.critBox}>
                <span className={s.critLabel}>Critère travaillé</span>
                <p className={s.critText}>{skill.generalCriterion}</p>
              </div>

              <MiniBar attempted={treated.length} total={prompts.length} percent={pct} />
            </section>

            <SectionHead
              title="Petits sujets"
              text="Les sujets déjà réalisés restent clairement identifiables."
              action={
                firstTodo && (
                  <button
                    type="button"
                    className={s.headLink}
                    onClick={() => router.push(`${base}/${skill.id}/${firstTodo.id}`)}
                  >
                    Commencer le sujet {firstTodo.displayOrder} →
                  </button>
                )
              }
            />

            <div className={s.filterRow} role="tablist" aria-label="Filtrer les petits sujets">
              {chips.map(([key, label, count]) => (
                <button
                  key={key}
                  type="button"
                  role="tab"
                  aria-selected={filter === key}
                  className={`${s.filter} ${filter === key ? s.filterOn : ""}`}
                  onClick={() => setFilter(key)}
                >
                  {label} · {count}
                </button>
              ))}
            </div>

            {shown.length === 0 ? (
              <p className={s.empty}>
                {filter === "done"
                  ? "Aucun sujet traité pour l'instant."
                  : "Tous les sujets ont été traités."}
              </p>
            ) : (
              <div className={s.list}>
                {shown.map((p) => (
                  <PromptCard
                    key={p.id}
                    prompt={p}
                    onOpen={() => router.push(`${base}/${skill.id}/${p.id}`)}
                  />
                ))}
              </div>
            )}

            <Link href={`${config.base}/tache/${n}`} className={s.footLink}>
              ← Revenir aux sujets TCF complets
            </Link>

            <ConfirmSheet
              open={infoOpen && !!skill.description}
              tone="info"
              title={skill.title}
              message={skill.description ?? ""}
              onClose={() => {
                setInfoOpen(false);
                infoButtonRef.current?.focus();
              }}
            />
          </>
        )}
      </SkillShell>
    </DualChromeShell>
  );
}

function PromptCard({prompt, onOpen}: {prompt: SkillPromptSummaryDto; onOpen: () => void}) {
  const done = prompt.status !== "TODO";
  return (
    <button
      type="button"
      className={`${s.card} ${s.rowCard} ${promptCardToneClass(prompt.status)}`}
      onClick={onOpen}
    >
      <span className={`${s.tile} ${done ? s.tileDone : ""}`} aria-hidden>
        {done ? <Check size={22} strokeWidth={2.8} /> : prompt.displayOrder}
      </span>
      {/* Le critère unique ne s'affiche plus sous le titre (parité mobile) : il
          est répété par la check-list de l'écran de saisie, et il faisait de
          chaque carte un pavé de texte. */}
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{prompt.title}</span>
        {done && (
          <span className={s.rowMeta}>
            <CompetenceStatusBadge status={prompt.status} />
            <span className={s.metaText}>
              {prompt.attemptCount} tentative{prompt.attemptCount > 1 ? "s" : ""}
              {prompt.lastAttemptAt ? ` · ${shortDate(prompt.lastAttemptAt)}` : ""}
            </span>
          </span>
        )}
      </span>
      <span className={s.rowAside}>
        {done ? (
          <span className={s.metaText}>{SKILL_DIFFICULTY_LABEL[prompt.difficultyLevel]}</span>
        ) : (
          <CompetenceStatusBadge status={prompt.status} />
        )}
        <RowChevron />
      </span>
    </button>
  );
}
