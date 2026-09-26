"use client";

import { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import { PriceCard } from "@/components/pricing/PassCard";
import {
  formatPassPrice,
  oneTimePassesOf,
  PASS_EXCLUDED,
  PASS_FEATURES,
  PASS_MODULE_CARD_TITLE,
  PASS_PITCH,
  passDurationLabel,
  passMonthlyLabel,
  passSessionsLabel,
  popularPassCodeOf,
  POPULAR_PASS_CODE,
  type PassModule,
} from "@/lib/passes";
import type { PlanPublicResponse } from "@/lib/types";
import { deriveIntent, type CurrentPlan } from "./paiement-access";
import s from "./paiement.module.css";

/**
 * La grille de passes de `/paiement` (catalogue en achat unique).
 *
 * Une carte par module, sur la carte partagée de la vitrine (`PriceCard`) en
 * mode **sélection** : on choisit une durée, puis le bouton de la carte paie
 * CETTE durée. Pré-sélection : le pass visé par `?plan=` s'il est de ce module,
 * sinon le pass mis en avant (`popularPassCodeOf`). Tout ce qui est une règle
 * (prix, durée, simulations, populaire, ordre, périmètre) vient de
 * `lib/passes.ts`.
 */

const KICKER: Record<PassModule, string> = {
  INTEGRAL: "Civique + TCF IRN",
  CIVIQUE: "Pass Civique",
};

const CARD_ID: Record<PassModule, string> = {
  INTEGRAL: "pass-integral",
  CIVIQUE: "pass-civique",
};

function initialSelection(
  passes: PlanPublicResponse[],
  targetPlanCode: string | null,
): string | null {
  if (targetPlanCode && passes.some((p) => p.code === targetPlanCode)) return targetPlanCode;
  return popularPassCodeOf(passes);
}

export function PassOffers({
  plans,
  modules,
  currentPlan,
  loadingCode,
  targetPlanCode,
  onSubscribe,
}: {
  plans: PlanPublicResponse[];
  modules: readonly PassModule[];
  currentPlan: CurrentPlan;
  loadingCode: string | null;
  targetPlanCode: string | null;
  onSubscribe: (code: string) => void;
}) {
  const visible = modules
    .map((module) => ({ module, passes: oneTimePassesOf(plans, module) }))
    .filter((entry) => entry.passes.length > 0);

  return (
    <section className={`${s.cards} ${visible.length === 1 ? s.cardsSingle : ""}`}>
      {visible.map(({ module, passes }) => (
        <ModuleOffer
          key={module}
          module={module}
          passes={passes}
          currentPlan={currentPlan}
          loadingCode={loadingCode}
          targetPlanCode={targetPlanCode}
          onSubscribe={onSubscribe}
          integralShown={visible.some((v) => v.module === "INTEGRAL")}
        />
      ))}
    </section>
  );
}

function ModuleOffer({
  module,
  passes,
  currentPlan,
  loadingCode,
  targetPlanCode,
  onSubscribe,
  integralShown,
}: {
  module: PassModule;
  passes: PlanPublicResponse[];
  currentPlan: CurrentPlan;
  loadingCode: string | null;
  targetPlanCode: string | null;
  onSubscribe: (code: string) => void;
  integralShown: boolean;
}) {
  const [selected, setSelected] = useState<string | null>(() =>
    initialSelection(passes, targetPlanCode),
  );
  const targetRef = useRef<HTMLButtonElement | null>(null);
  const targeted = targetPlanCode !== null && passes.some((p) => p.code === targetPlanCode);

  // Pass choisi en amont (lien partagé, prolongation) : on le retrouve à l'écran.
  useEffect(() => {
    if (!targeted) return;
    targetRef.current?.scrollIntoView({ block: "center", behavior: "smooth" });
  }, [targeted]);

  const plan = passes.find((p) => p.code === selected) ?? passes[0];
  const intent = deriveIntent(currentPlan, module);
  const anyLoading = loadingCode !== null;
  const busy = loadingCode !== null && loadingCode === plan.code;
  const price = `${formatPassPrice(plan.price)} €`;

  let ctaLabel: string;
  if (busy) ctaLabel = "Redirection vers Stripe…";
  else if (intent === "upgrade") ctaLabel = "Passer à l'Intégral";
  else if (intent === "current") ctaLabel = `Prolonger · ${price}`;
  else ctaLabel = `Payer ${price}`;

  const ribbon =
    intent === "current"
      ? "Votre pass"
      : intent === "upgrade"
        ? "Recommandé"
        : module === "INTEGRAL"
          ? "Le plus complet"
          : null;

  const excluded = PASS_EXCLUDED[module];

  const extra = (
    <>
      {intent === "included" ? (
        <p className={s.included}>Déjà inclus dans votre pass Intégral.</p>
      ) : null}
      {excluded ? (
        <p className={s.excluded}>
          <X size={14} strokeWidth={2.4} aria-hidden />
          <span>
            <span className={s.excludedLabel}>Non inclus</span> {excluded}
            {integralShown ? (
              <>
                {" · "}
                <a href={`#${CARD_ID.INTEGRAL}`} className={s.excludedLink}>
                  Voir l&apos;Intégral
                </a>
              </>
            ) : null}
          </span>
        </p>
      ) : null}
    </>
  );

  return (
    <PriceCard
      id={CARD_ID[module]}
      layout="featuresFirst"
      kicker={KICKER[module]}
      title={PASS_MODULE_CARD_TITLE[module]}
      description={PASS_PITCH[module]}
      features={PASS_FEATURES[module]}
      extra={extra}
      featured={module === "INTEGRAL"}
      ribbon={ribbon}
      ribbonTone={intent === "current" ? "green" : "blue"}
      rowsLabel="Durée d'accès"
      rows={passes.map((p) => ({
        key: p.code,
        label: passDurationLabel(p.durationDays),
        value: `${formatPassPrice(p.price)} €`,
        valueSub: passMonthlyLabel(p),
        note: passSessionsLabel(p),
        badge: p.code === POPULAR_PASS_CODE ? "Populaire" : null,
        selected: p.code === plan.code,
        disabled: anyLoading,
        onSelect: () => setSelected(p.code),
        rowRef: p.code === targetPlanCode ? targetRef : undefined,
      }))}
      cta={{
        label: ctaLabel,
        tone: module === "INTEGRAL" && intent !== "current" ? "red" : "blue",
        onClick: () => onSubscribe(plan.code),
        disabled: anyLoading,
        busy,
      }}
      footnote={
        intent === "upgrade"
          ? "Le montant tient compte de votre pass Civique en cours : Stripe l'affiche avant validation."
          : null
      }
    />
  );
}
