"use client";

import { useParams } from "next/navigation";
import { type ReactNode, useEffect, useRef, useState } from "react";
import {
  Check,
  ChevronRight,
  FileText,
  Lightbulb,
  Lock,
  Pause,
  Play,
  Sparkles,
  X,
} from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { loadExamples, productionExamplesKey } from "@/lib/production-catalog";
import {
  EXAMPLES_NOTICE_BODY,
  EXAMPLES_NOTICE_TITLE,
  EXAMPLES_SECTION_TITLE,
  EXAMPLES_TITLE,
  EXAMPLE_EYEBROW,
  EXAMPLE_LISTEN,
  EXAMPLE_OPEN_CTA,
  EXAMPLE_PAUSE,
  EXAMPLE_PLAN_TITLE,
  EXAMPLE_TEXT_LABEL,
  EXAMPLE_WHY_TITLE,
  METHOD_TEXT,
  METHOD_TITLE,
  PREPARATION_LABEL,
  exampleLockedLabel,
  examplesEmpty,
  examplesHint,
  examplesMeta,
  productionPreparationPoints,
} from "@/lib/production-task-labels";
import { useCachedData } from "@/lib/use-cached-data";
import {
  canAccessModule,
  productionTaskTitle,
  type ProductionExampleDto,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  SectionHead,
  SkillNotice,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import t from "./task.module.css";
import { type ProductionConfig, TCF_HUB_HREF } from "./config";

/**
 * Réponses-modèles d'une tâche, sur leur **propre page** — ressource d'appoint,
 * atteinte par le lien discret en tête de la liste des sujets. Miroir de
 * `TcfTaskExamplesScreen` (mobile), brique pour brique : en-tête « Exemples
 * corrigés » + tâche, intertitre, une carte par modèle (lecteur intégré à
 * l'oral, « Voir le corrigé » à l'écrit), la carte « Méthode & formules-clés »
 * (fiche de méthode) et l'encart d'usage.
 *
 * Le détail d'un modèle s'ouvre dans une feuille (`ExampleSheet`, miroir de
 * `ExampleDetailSheet`) : résumé, écoute, texte du modèle (écrit seulement —
 * à l'oral on s'entraîne à l'écoute), ce qui fait la différence, plan rapide.
 *
 * Freemium : 1er modèle offert, les suivants ouvrent le paywall (aucun `locked`
 * n'est servi pour les modèles, cf. `docs/regles/freemium.md`).
 *
 * Grand écran : les cartes passent en grille de deux colonnes, la méthode et
 * l'encart se rangent côte à côte.
 */
export function ProductionExamples({ config }: { config: ProductionConfig }) {
  const params = useParams<{ n: string }>();
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const isOral = config.mode === "audio";
  const { user, status } = useAuth();

  const [paywallOpen, setPaywallOpen] = useState(false);
  const [openExample, setOpenExample] = useState<ProductionExampleDto | null>(null);
  const [methodOpen, setMethodOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "TCF") : false;

  // Contenu éditorial : chargé une fois par tâche et pour la session (même
  // entrée que le compteur du lien, sur la liste des sujets).
  const examplesQuery = useCachedData(
    status === "authenticated" && valid ? productionExamplesKey(config.epreuve, n) : null,
    () => loadExamples(productionApi, config.epreuve, n),
  );
  const examples = examplesQuery.data ?? [];
  const loaded = !examplesQuery.loading;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/tache/${n}/exemples`} />;

  const backHref = valid ? `${config.base}/tache/${n}` : TCF_HUB_HREF;

  return (
    <DualChromeShell>
      <SkillShell
        backHref={backHref}
        backLabel={valid ? `${config.label} · Tâche ${n}` : config.label}
        title={EXAMPLES_TITLE}
        meta={valid ? examplesMeta(n, productionTaskTitle(config.epreuve, n)) : undefined}
        wide
      >
        {!valid ? (
          <p className={s.empty}>Tâche inconnue.</p>
        ) : (
          <div className={t.body}>
            <SectionHead title={EXAMPLES_SECTION_TITLE} text={examplesHint(isOral)} />

            {examplesQuery.error && <div className={s.error}>{examplesQuery.error}</div>}

            {!loaded ? (
              <p className={s.empty}>Chargement des exemples…</p>
            ) : examples.length === 0 ? (
              <p className={t.hint}>{examplesEmpty(isOral)}</p>
            ) : (
              <div className={`${t.grid} ${t.gridExamples}`}>
                {examples.map((ex, i) => (
                  <ExampleCard
                    key={ex.id}
                    example={ex}
                    locked={!isPremium && i > 0}
                    onOpen={() =>
                      !isPremium && i > 0 ? setPaywallOpen(true) : setOpenExample(ex)
                    }
                  />
                ))}
              </div>
            )}

            <div className={t.bottom}>
              <button type="button" className={t.strategy} onClick={() => setMethodOpen(true)}>
                <span className={t.strategyIcon} aria-hidden>
                  <Lightbulb size={23} />
                </span>
                <span>
                  <span className={t.strategyTitle}>{METHOD_TITLE}</span>
                  <span className={t.strategyText}>{METHOD_TEXT}</span>
                </span>
                <ChevronRight size={18} className={t.chev} aria-hidden />
              </button>

              <SkillNotice title={EXAMPLES_NOTICE_TITLE}>{EXAMPLES_NOTICE_BODY}</SkillNotice>
            </div>
          </div>
        )}

        {openExample && (
          <ExampleSheet
            example={openExample}
            isOral={isOral}
            onClose={() => setOpenExample(null)}
          />
        )}

        {methodOpen && (
          <Sheet muted onClose={() => setMethodOpen(false)}>
            <h2 className={t.sheetTitle}>{METHOD_TITLE}</h2>
            <span className={t.prepLabel}>{PREPARATION_LABEL}</span>
            <ol className={t.prepList}>
              {productionPreparationPoints(isOral, n).map(([titre, aide], i) => (
                <li key={titre} className={t.prepItem}>
                  <span className={t.prepNum} aria-hidden>
                    {i + 1}
                  </span>
                  <span>
                    <span className={t.prepTitle}>{titre}</span>
                    <span className={t.prepAide}>{aide}</span>
                  </span>
                </li>
              ))}
            </ol>
          </Sheet>
        )}

        <PaywallSheet
          ctaLocation="OTHER"
          screen="production_exemples"
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          reason="Le 1ᵉʳ exemple est offert ; les autres réponses-modèles et leurs explications font partie du pass Intégral."
        />
      </SkillShell>
    </DualChromeShell>
  );
}

/** Le corrigé a-t-il quelque chose à montrer au-delà de l'écoute ? */
function hasCorrige(ex: ProductionExampleDto): boolean {
  return !!ex.explications?.trim() || ex.planPoints.length > 0;
}

/**
 * Carte d'un modèle — miroir de `FeaturedExampleCard`. Verrouillée : barre
 * « inclus dans le pass Intégral » (l'audio n'est même pas chargé). Oral :
 * lecteur intégré, puis « Voir le corrigé » quand le modèle porte des
 * explications ou un plan. Écrit : « Voir le corrigé ».
 */
function ExampleCard({
  example: ex,
  locked,
  onOpen,
}: {
  example: ProductionExampleDto;
  locked: boolean;
  onOpen: () => void;
}) {
  const audio = ex.audioUrl?.trim() ? ex.audioUrl : null;
  return (
    <article className={t.exCard}>
      <span className={t.exEyebrow}>
        <Sparkles size={14} aria-hidden />
        {EXAMPLE_EYEBROW}
      </span>
      <h3 className={t.exTitle}>{ex.titre}</h3>
      <div className={t.exActions}>
        {locked ? (
          <button type="button" className={t.lockedBar} onClick={onOpen}>
            <span className={t.lockedIcon} aria-hidden>
              <Lock size={17} />
            </span>
            <span className={t.lockedText}>{exampleLockedLabel(!!audio)}</span>
            <ChevronRight size={18} className={t.chev} aria-hidden />
          </button>
        ) : (
          <>
            {audio && <InlinePlayer src={audio} />}
            {(!audio || hasCorrige(ex)) && (
              <button type="button" className={t.outlineBtn} onClick={onOpen}>
                <FileText size={15} aria-hidden />
                {EXAMPLE_OPEN_CTA}
              </button>
            )}
          </>
        )}
      </div>
    </article>
  );
}

function formatClock(seconds: number): string {
  const total = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0;
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
}

/** État d'un élément `<audio>` piloté par nos propres boutons. */
function useAudio(src: string) {
  const ref = useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = useState(false);
  const [failed, setFailed] = useState(false);
  const [pos, setPos] = useState(0);
  const [dur, setDur] = useState(0);

  useEffect(() => {
    const el = new Audio();
    el.preload = "metadata";
    el.src = src;
    ref.current = el;
    const onMeta = () => setDur(Number.isFinite(el.duration) ? el.duration : 0);
    const onTime = () => setPos(el.currentTime);
    const onPlay = () => setPlaying(true);
    const onPause = () => setPlaying(false);
    // Fin de lecture : retour au repos, barre à zéro (même geste que le mobile).
    const onEnded = () => {
      el.currentTime = 0;
      setPos(0);
      setPlaying(false);
    };
    const onError = () => {
      setFailed(true);
      setPlaying(false);
    };
    el.addEventListener("loadedmetadata", onMeta);
    el.addEventListener("durationchange", onMeta);
    el.addEventListener("timeupdate", onTime);
    el.addEventListener("play", onPlay);
    el.addEventListener("pause", onPause);
    el.addEventListener("ended", onEnded);
    el.addEventListener("error", onError);
    return () => {
      el.pause();
      el.removeEventListener("loadedmetadata", onMeta);
      el.removeEventListener("durationchange", onMeta);
      el.removeEventListener("timeupdate", onTime);
      el.removeEventListener("play", onPlay);
      el.removeEventListener("pause", onPause);
      el.removeEventListener("ended", onEnded);
      el.removeEventListener("error", onError);
      ref.current = null;
    };
  }, [src]);

  function toggle() {
    const el = ref.current;
    if (!el) return;
    if (el.paused) void el.play().catch(() => setPlaying(false));
    else el.pause();
  }

  return { playing, failed, pos, dur, toggle };
}

/** Lecteur intégré de la carte — miroir de `_buildPlayer` (mobile). */
function InlinePlayer({ src }: { src: string }) {
  const { playing, failed, pos, dur, toggle } = useAudio(src);
  const progress = dur > 0 ? Math.min(1, pos / dur) : 0;
  return (
    <div className={t.player}>
      <button
        type="button"
        className={t.playBtn}
        onClick={toggle}
        disabled={failed}
        aria-label={playing ? EXAMPLE_PAUSE : EXAMPLE_LISTEN}
      >
        {playing ? <Pause size={20} aria-hidden /> : <Play size={20} aria-hidden />}
      </button>
      <div className={t.track}>
        <div className={t.bar}>
          <div className={t.barFill} style={{ width: `${progress * 100}%` }} />
        </div>
        <div className={t.times}>
          <span>{formatClock(pos)}</span>
          <span>{formatClock(dur)}</span>
        </div>
      </div>
    </div>
  );
}

/** Feuille posée en bas (dialogue centré au-delà de 640 px). */
function Sheet({
  muted = false,
  onClose,
  children,
}: {
  muted?: boolean;
  onClose: () => void;
  children: ReactNode;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [onClose]);

  return (
    <div className={t.sheetRoot} role="presentation" onClick={onClose}>
      <div
        className={`${t.sheet} ${muted ? t.sheetMuted : ""}`}
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={t.sheetTop}>
          <span className={t.handle} aria-hidden />
          <button type="button" className={t.sheetClose} onClick={onClose} aria-label="Fermer">
            <X size={16} aria-hidden />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

/** Détail d'un modèle — miroir de `ExampleDetailSheet`. */
function ExampleSheet({
  example: ex,
  isOral,
  onClose,
}: {
  example: ProductionExampleDto;
  isOral: boolean;
  onClose: () => void;
}) {
  const audio = ex.audioUrl?.trim() ? ex.audioUrl : null;
  return (
    <Sheet onClose={onClose}>
      <h2 className={t.sheetTitle}>{ex.titre}</h2>
      {ex.resume && <p className={t.sheetResume}>{ex.resume}</p>}
      {audio && <ListenButton src={audio} />}
      {/* Oral : pas de transcription, le candidat s'entraîne à l'écoute seule.
          Écrit : le texte EST le modèle. */}
      {!isOral && ex.contenu && (
        <>
          <span className={t.blockLabel}>{EXAMPLE_TEXT_LABEL}</span>
          <p className={t.modelText}>{ex.contenu}</p>
        </>
      )}
      {ex.explications?.trim() && (
        <div className={t.why}>
          <span className={t.whyIcon} aria-hidden>
            <Lightbulb size={17} />
          </span>
          <div>
            <strong className={t.whyTitle}>{EXAMPLE_WHY_TITLE}</strong>
            <p className={t.whyText}>{ex.explications}</p>
          </div>
        </div>
      )}
      {ex.planPoints.length > 0 && (
        <>
          <h3 className={t.planTitle}>{EXAMPLE_PLAN_TITLE}</h3>
          <ul className={t.planList}>
            {ex.planPoints.map((p, i) => (
              <li key={i} className={t.planRow}>
                <span className={t.planCheck} aria-hidden>
                  <Check size={13} />
                </span>
                {p}
              </li>
            ))}
          </ul>
        </>
      )}
    </Sheet>
  );
}

function ListenButton({ src }: { src: string }) {
  const { playing, failed, toggle } = useAudio(src);
  return (
    <button type="button" className={t.listen} onClick={toggle} disabled={failed}>
      {playing ? <Pause size={24} aria-hidden /> : <Play size={24} aria-hidden />}
      {playing ? EXAMPLE_PAUSE : EXAMPLE_LISTEN}
    </button>
  );
}
