"use client";

import { useParams } from "next/navigation";
import { useState } from "react";
import { Lock } from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { loadExamples, productionExamplesKey } from "@/lib/production-catalog";
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
  SkillHero,
  SkillNotice,
  SkillRowCard,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import { type ProductionConfig, TCF_HUB_HREF } from "./config";

/**
 * Réponses-modèles d'une tâche, sur leur **propre page** — la maquette ne les
 * met pas au même niveau que les sujets : c'est une ressource d'appoint, qu'on
 * consulte quand on bloque, pas un espace de travail. Elle s'ouvre depuis le
 * lien discret en tête de la liste des sujets.
 *
 * L'écran est identique en expression écrite et en expression orale ; en oral,
 * le modèle est un enregistrement (le texte reste masqué : on écoute).
 */
export function ProductionExamples({ config }: { config: ProductionConfig }) {
  const params = useParams<{ n: string }>();
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const { user, status } = useAuth();

  const [paywallOpen, setPaywallOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "TCF") : false;

  // Contenu éditorial : chargé une fois par tâche et pour la session. Revenir
  // depuis la liste des sujets ne redemande rien.
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
        config={config}
        backHref={backHref}
        backLabel={valid ? `${config.label} · Tâche ${n}` : config.label}
        mode="sujets"
        taskNumero={valid ? n : undefined}
      >
        {!valid ? (
          <p className={s.empty}>Tâche inconnue.</p>
        ) : (
          <>
            <SkillHero
              eyebrow={`${config.label} · Tâche ${n}`}
              title="Réponses-modèles"
              text={
                config.mode === "audio"
                  ? "Écoutez comment une réponse attendue s'organise, puis retournez produire la vôtre."
                  : "Lisez comment une réponse attendue s'organise, puis retournez produire la vôtre."
              }
              level={null}
              attempted={0}
              total={0}
              percent={0}
            />

            <SectionHead
              title={productionTaskTitle(config.epreuve, n)}
              text="Ces modèles ne remplacent pas la production : ils montrent un plan possible."
            />

            {!loaded ? (
              <p className={s.empty}>Chargement des exemples…</p>
            ) : examples.length === 0 ? (
              <p className={s.empty}>
                Aucune réponse-modèle pour cette tâche pour l&apos;instant.
              </p>
            ) : (
              <div className={s.list}>
                {examples.map((ex, i) =>
                  !isPremium && i > 0 ? (
                    <SkillRowCard
                      key={ex.id}
                      tile={<Lock size={20} aria-hidden />}
                      title={ex.titre}
                      text={
                        config.mode === "audio"
                          ? "Écoute réservée à l'abonnement Intégral"
                          : "Corrigé réservé à l'abonnement Intégral"
                      }
                      onClick={() => setPaywallOpen(true)}
                    />
                  ) : (
                    <ExampleCard
                      key={ex.id}
                      example={ex}
                      hideText={config.mode === "audio"}
                    />
                  ),
                )}
              </div>
            )}

            <SkillNotice title="À utiliser après coup">
              Le meilleur usage d&apos;un modèle, c&apos;est de comparer : produisez
              d&apos;abord votre réponse, revenez ensuite voir ce qui vous manquait.
            </SkillNotice>
          </>
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          message="Le 1er exemple est offert. Passez à l'abonnement Intégral pour débloquer toutes les réponses-modèles et leurs explications."
        />
      </SkillShell>
    </DualChromeShell>
  );
}

function ExampleCard({
  example: ex,
  hideText,
}: {
  example: ProductionExampleDto;
  hideText: boolean;
}) {
  return (
    <article className={`${s.card} ${s.summary}`}>
      <h3 className={s.summaryTitle}>{ex.titre}</h3>
      {ex.resume && <p className={s.summaryText}>{ex.resume}</p>}

      {ex.audioUrl && (
        <div className={s.player}>
          <audio src={ex.audioUrl} controls preload="none" />
        </div>
      )}

      {!hideText && ex.contenu && (
        <div className={s.answerBox}>
          <span className={s.answerLabel}>Production modèle</span>
          <p className={s.prodText}>{ex.contenu}</p>
        </div>
      )}

      {ex.planPoints.length > 0 && (
        <ol className={s.planList}>
          {ex.planPoints.map((p, i) => (
            <li key={i} className={s.planItem}>
              <span className={s.planNum}>{i + 1}.</span>
              {p}
            </li>
          ))}
        </ol>
      )}

      {ex.explications && (
        <div className={s.why}>
          <span className={s.whyIcon} aria-hidden>
            ?
          </span>
          <p className={s.whyText}>{ex.explications}</p>
        </div>
      )}
    </article>
  );
}
