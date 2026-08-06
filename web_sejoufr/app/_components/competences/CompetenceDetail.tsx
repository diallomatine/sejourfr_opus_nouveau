"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {Check, Sparkles} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {progressPercent} from "@/lib/skill-progress";
import {
  SKILL_DIFFICULTY_LABEL,
  SKILL_PROMPT_STATUS_LABEL,
  type SkillDetailDto,
  type SkillPromptSummaryDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
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

  const [data, setData] = useState<SkillDetailDto | null>(null);
  const [filter, setFilter] = useState<Filter>("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !skillId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    skillApi
      .getSkill(skillId)
      .then((d) => {
        if (!cancelled) setData(d);
      })
      .catch((e) => {
        if (!cancelled)
          setError(
            e instanceof ApiException ? e.message : "Impossible de charger cette compétence.",
          );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, skillId]);

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
        config={config}
        backHref={base}
        backLabel="Compétences"
        mode="competences"
        taskNumero={n}
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
                <div>
                  <span className={`${s.badge} ${s.levelPill}`}>{skill.targetLevel}</span>
                  <h1 className={s.summaryTitle}>{skill.title}</h1>
                  {skill.description && <p className={s.summaryText}>{skill.description}</p>}
                </div>
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
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{prompt.title}</span>
        <span className={s.rowText}>{prompt.uniqueCriterion}</span>
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
