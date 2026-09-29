"use client";

import { AlertTriangle, CalendarCheck, Check, Info, Layers, Lock, X } from "lucide-react";
import { PriceCard } from "@/components/pricing/PassCard";
import {
  periodicityFromCycle,
  planCodeFor,
  type PlanModuleTarget,
  type PlanPeriodicity,
} from "@/lib/api";
import {
  formatPassPrice,
  PASS_FEATURES,
  PASS_MODULE_CARD_TITLE,
  PASS_MODULE_NAME,
  PASS_PITCH,
  type PassModule,
} from "@/lib/passes";
import type { AuthenticatedUser, BillingCycle, PlanPublicResponse } from "@/lib/types";
import {
  daysLeft,
  deriveIntent,
  formatEndDate,
  type CurrentPlan,
} from "./paiement-access";
import s from "./paiement.module.css";

// ============================================================================
// EN-TÊTE — titre, phrase, réassurance (une seule fois sur la page)
// ============================================================================

export function PaiementHeader({
  currentPlan,
  firstName,
  oneTime,
}: {
  currentPlan: CurrentPlan;
  firstName: string | null;
  /** Catalogue en achat unique (le cas actuel) ; `false` = mode abonnement dormant. */
  oneTime: boolean;
}) {
  return (
    <header className={s.head}>
      <span className={s.kicker}>{currentPlan === "FREE" ? "Choisir un pass" : "Mon accès"}</span>
      <h1 className={s.title}>{titleFor(currentPlan, firstName)}</h1>
      <p className={s.lead}>
        {oneTime ? leadFor(currentPlan) : "Mensuel, trimestriel ou annuel, résiliable à tout moment."}
      </p>
      <ul className={s.trust}>
        <li>
          <Lock size={14} aria-hidden /> Paiement sécurisé par Stripe
        </li>
        {oneTime ? (
          <>
            <li>
              <CalendarCheck size={14} aria-hidden /> Paiement unique, sans renouvellement
            </li>
            <li>
              <Layers size={14} aria-hidden /> Durées cumulables
            </li>
          </>
        ) : null}
      </ul>
    </header>
  );
}

function titleFor(plan: CurrentPlan, firstName: string | null): React.ReactNode {
  if (plan === "INTEGRAL") return <>Prolongez votre <em>Intégral</em>.</>;
  if (plan === "CIVIQUE") return <>Prolongez, ou passez à l&apos;<em>Intégral</em>.</>;
  const name = firstName?.trim();
  return name ? (
    <>
      Bonjour {name}, choisissez votre <em>pass</em>.
    </>
  ) : (
    <>
      Choisissez votre <em>pass</em>.
    </>
  );
}

function leadFor(plan: CurrentPlan): string {
  if (plan === "INTEGRAL") return "Un nouveau pass s'ajoute à la suite de votre accès en cours.";
  if (plan === "CIVIQUE") {
    return "Prolongez votre pass Civique, ou passez à l'Intégral pour ajouter le TCF IRN.";
  }
  return "Payez une fois, pour la durée qui colle à votre date d'examen.";
}

// ============================================================================
// RETOUR DE STRIPE SANS ACHAT (?canceled=1)
// ============================================================================

export function CanceledBanner({ onDismiss }: { onDismiss: () => void }) {
  return (
    <div className={`${s.notice} ${s.noticeAmber}`} role="status">
      <span className={s.noticeIcon} aria-hidden>
        <Info size={18} />
      </span>
      <div className={s.noticeBody}>
        <p className={s.noticeTitle}>Paiement annulé · aucun débit</p>
        <p className={s.noticeText}>
          Vous êtes revenu sans valider votre achat. Choisissez un pass quand vous voulez.
        </p>
      </div>
      <button
        type="button"
        className={s.noticeClose}
        onClick={onDismiss}
        aria-label="Fermer cette information"
      >
        <X size={16} aria-hidden />
      </button>
    </div>
  );
}

// ============================================================================
// PASS DÉJÀ ACTIF
// ============================================================================

export function CurrentAccessCard({
  user,
  currentPlan,
}: {
  user: AuthenticatedUser;
  currentPlan: CurrentPlan;
}) {
  const remaining = daysLeft(user.premiumEndsAt);
  const label = currentPlan === "INTEGRAL" ? "Intégral · Civique + TCF IRN" : "Civique";
  const expiresSoon = remaining !== null && remaining <= 14;

  return (
    <div className={`${s.notice} ${expiresSoon ? s.noticeAmber : s.noticeGreen}`}>
      <span className={s.noticeIcon} aria-hidden>
        {expiresSoon ? <AlertTriangle size={18} /> : <Check size={18} />}
      </span>
      <div className={s.noticeBody}>
        <p className={s.noticeTitle}>
          Votre pass {label}
          <span className={s.noticePill}>{expiresSoon ? "Bientôt terminé" : "Actif"}</span>
        </p>
        <p className={s.noticeText}>
          {user.premiumEndsAt ? (
            <>
              Accès jusqu&apos;au <strong>{formatEndDate(user.premiumEndsAt)}</strong>
              {remaining !== null ? (
                remaining > 0 ? (
                  <>
                    {" "}
                    · encore <strong>{remaining} jour{remaining > 1 ? "s" : ""}</strong>
                  </>
                ) : (
                  <>
                    {" "}
                    · <strong>se termine aujourd&apos;hui</strong>
                  </>
                )
              ) : null}
            </>
          ) : (
            "Accès actif."
          )}
        </p>
      </div>
    </div>
  );
}

// ============================================================================
// MODE ABONNEMENT (dormant — `BILLING_MODE=SUBSCRIPTION`, cf. réversibilité)
// ============================================================================

const PERIODICITIES: { value: PlanPeriodicity; label: string; sub: string }[] = [
  { value: "monthly", label: "Mensuel", sub: "facturé chaque mois" },
  { value: "quarterly", label: "Trimestriel", sub: "facturé tous les 3 mois" },
  { value: "yearly", label: "Annuel", sub: "facturé chaque année" },
];

const PERIOD_SUFFIX: Record<PlanPeriodicity, string> = {
  monthly: "/ mois",
  quarterly: "/ 3 mois",
  yearly: "/ an",
};

export function periodicityFromParam(raw: string | null): PlanPeriodicity | null {
  if (raw === "monthly" || raw === "quarterly" || raw === "yearly") return raw;
  return null;
}

function monthlyEquivalent(price: number, cycle: BillingCycle): number | null {
  if (cycle === "THREE_MONTHS") return price / 3;
  if (cycle === "YEARLY") return price / 12;
  return null;
}

/** Plans récurrents indexés par (module, périodicité). */
function indexPlans(plans: PlanPublicResponse[]): Map<string, PlanPublicResponse> {
  const map = new Map<string, PlanPublicResponse>();
  for (const p of plans) {
    const periodicity = periodicityFromCycle(p.billingCycle);
    if (!periodicity) continue;
    if (p.moduleAccess !== "CIVIQUE" && p.moduleAccess !== "INTEGRAL") continue;
    map.set(`${p.moduleAccess}:${periodicity}`, p);
  }
  return map;
}

export function SubscriptionOffers({
  plans,
  modules,
  currentPlan,
  periodicity,
  onPeriodicity,
  loadingCode,
  onSubscribe,
}: {
  plans: PlanPublicResponse[];
  modules: readonly PassModule[];
  currentPlan: CurrentPlan;
  periodicity: PlanPeriodicity;
  onPeriodicity: (p: PlanPeriodicity) => void;
  loadingCode: string | null;
  onSubscribe: (code: string) => void;
}) {
  const index = indexPlans(plans);
  return (
    <>
      <div className={s.period} role="tablist" aria-label="Périodicité de l'abonnement">
        {PERIODICITIES.map((p) => {
          const active = p.value === periodicity;
          return (
            <button
              key={p.value}
              type="button"
              role="tab"
              aria-selected={active}
              className={`${s.periodBtn} ${active ? s.periodBtnOn : ""}`}
              onClick={() => onPeriodicity(p.value)}
            >
              <span className={s.periodLabel}>{p.label}</span>
              <span className={s.periodSub}>{p.sub}</span>
            </button>
          );
        })}
      </div>
      <section className={s.cards}>
        {modules.map((module) => {
          const plan = index.get(`${module}:${periodicity}`);
          if (!plan) return null;
          const code = planCodeFor(module as PlanModuleTarget, periodicity);
          const intent = deriveIntent(currentPlan, module);
          const monthly = monthlyEquivalent(plan.price, plan.billingCycle);
          const main = monthly ?? plan.price;
          const busy = loadingCode === code;
          const name = PASS_MODULE_NAME[module];
          return (
            <PriceCard
              key={module}
              kicker={module === "INTEGRAL" ? "Civique + TCF IRN" : "Examen civique"}
              title={PASS_MODULE_CARD_TITLE[module]}
              description={PASS_PITCH[module]}
              price={{
                amount: `${formatPassPrice(Number(main.toFixed(2)))} € / mois`,
                sub:
                  monthly !== null
                    ? `soit ${formatPassPrice(plan.price)} € ${PERIOD_SUFFIX[periodicity]}`
                    : "facturé chaque mois",
              }}
              rows={[]}
              features={PASS_FEATURES[module]}
              featured={module === "INTEGRAL"}
              ribbon={
                intent === "current"
                  ? "Votre formule"
                  : intent === "upgrade"
                    ? "Recommandé"
                    : module === "INTEGRAL"
                      ? "Le plus complet"
                      : null
              }
              ribbonTone={intent === "current" ? "green" : "blue"}
              cta={{
                label: busy
                  ? "Redirection…"
                  : intent === "current"
                    ? `Renouveler ${name}`
                    : intent === "upgrade"
                      ? "Passer à l'Intégral"
                      : `Choisir ${name}`,
                tone: module === "INTEGRAL" ? "red" : "blue",
                onClick: () => onSubscribe(code),
                disabled: loadingCode !== null,
                busy,
              }}
            />
          );
        })}
      </section>
    </>
  );
}
