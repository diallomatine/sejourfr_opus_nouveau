"use client";

/**
 * Récapitulatif du pass choisi — la dernière étape avant Stripe.
 *
 * Le candidat clique un prix sur `/tarifs` (ou `/reussir`), s'inscrit ou se
 * connecte si besoin, et **retrouve exactement ce qu'il a choisi** : un seul
 * pass à l'écran, jamais une grille où il faudrait re-choisir. Le CTA appelle
 * `billingApi.getPaymentLink(planCode)` — l'endpoint existant, aucun nouveau.
 *
 * ⚠️ Deux pièges portent sur de l'argent, traités ici :
 *
 * 1. **La date de fin d'accès ne s'invente pas.** `ends_at` est posé par le
 *    backend (`OneTimeAccessService.grantOneTimeAccess`) et les passes se
 *    CUMULENT par module : pour un candidat qui a déjà un accès en cours, ce
 *    n'est pas « aujourd'hui + durée ». On annonce donc une **durée**, jamais
 *    une date calculée ; la seule date affichée est la fin de l'accès ACTUEL,
 *    qui vient du serveur (`subscription-status.expiresAt`).
 * 2. **La proration.** Un pass Civique en cours + un achat Intégral = crédit du
 *    temps restant côté Stripe (`BillingService.computeOneTimeAmountCents`), donc
 *    le montant débité est **inférieur** au prix affiché. On ne présente alors
 *    aucun total ferme : le prix est étiqueté « Prix du pass » et une note dit
 *    que le montant sera ajusté, Stripe l'affichant avant validation.
 */

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import {
  ArrowLeft,
  CalendarOff,
  Check,
  Info,
  Loader2,
  Lock,
  ShieldCheck,
} from "lucide-react";
import { ApiException, billingApi } from "@/lib/api";
import { track } from "@/lib/analytics";
import { trackSubscribeClicked } from "@/lib/funnel-events";
import {
  findOneTimePass,
  formatPassPrice,
  passDurationLabel,
  passModuleOf,
  passMonthlyLabel,
  passSessionsLabel,
  type PassModule,
} from "@/lib/passes";
import type { PlanPublicResponse, SubscriptionStatusResponse } from "@/lib/types";

// ============================================================================
// PRÉSENTATION (miroir de /paiement — ce que le module ouvre)
// ============================================================================

const MODULE_NAME: Record<PassModule, string> = {
  CIVIQUE: "Civique",
  INTEGRAL: "Intégral",
};

const SCOPE: Record<PassModule, { tag: string; pitch: string; features: string[] }> = {
  CIVIQUE: {
    tag: "POUR CSP · CR · NAT",
    pitch: "L'accès complet au module civique pour préparer votre démarche.",
    features: [
      "Banque complète civique (CSP / CR / NAT)",
      "Examens blancs civiques illimités",
      "Entraînement par thème et révision des erreurs",
      "Statistiques par thématique",
    ],
  },
  INTEGRAL: {
    tag: "CIVIQUE + TCF IRN",
    pitch: "Civique + TCF IRN avec expression écrite et orale évaluées par IA.",
    features: [
      "Tout le module civique inclus",
      "TCF IRN complet (CO + CE + Structure)",
      "Expression écrite et orale évaluées par IA",
      "Examens blancs TCF illimités",
    ],
  },
};

// ============================================================================
// RÈGLES D'ACCÈS — ce que devient l'accès après ce paiement
// ============================================================================

type AccessCase =
  | { kind: "new" }
  /** Accès en cours qui couvre déjà ce module : les durées se cumulent. */
  | { kind: "extension"; currentEnd: string | null }
  /** Pass Civique en cours + achat Intégral : Stripe crédite le reste. */
  | { kind: "upgrade"; currentEnd: string | null };

/** Ordre du `ModuleAccess` serveur : NONE < CIVIQUE < INTEGRAL. */
const MODULE_RANK: Record<string, number> = { NONE: 0, CIVIQUE: 1, INTEGRAL: 2 };

/**
 * Reproduit la décision du serveur, sans la deviner :
 * `currentEndForAtLeast(module)` prolonge dès qu'un accès couvrant est d'un
 * module **au moins** égal ; sinon (Civique en cours, Intégral acheté) l'accès
 * repart de maintenant et le reste est crédité par la proration Stripe.
 */
function accessCase(
  status: SubscriptionStatusResponse | null,
  wantedModule: PassModule,
): AccessCase {
  if (!status || !status.isPremium) return { kind: "new" };
  const current = MODULE_RANK[status.moduleAccess] ?? 0;
  const wanted = MODULE_RANK[wantedModule] ?? 0;
  if (current === 0) return { kind: "new" };
  if (current >= wanted) return { kind: "extension", currentEnd: status.expiresAt };
  return { kind: "upgrade", currentEnd: status.expiresAt };
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

// ============================================================================
// PAGE
// ============================================================================

export default function RecapitulatifPage() {
  return (
    <Suspense fallback={<RecapSkeleton />}>
      <RecapInner />
    </Suspense>
  );
}

function RecapInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const planCode = searchParams.get("plan");

  const [plans, setPlans] = useState<PlanPublicResponse[]>([]);
  const [status, setStatus] = useState<SubscriptionStatusResponse | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [catalogError, setCatalogError] = useState(false);
  const [redirecting, setRedirecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Aucun pass choisi : il n'y a rien à récapituler, on renvoie à la grille.
  useEffect(() => {
    if (!planCode) router.replace("/tarifs");
  }, [planCode, router]);

  useEffect(() => {
    if (!planCode) return;
    let cancelled = false;
    // Le statut est un CONFORT (cumul / proration) : son échec ne doit jamais
    // empêcher de payer, d'où les deux promesses séparées.
    billingApi
      .listPlans()
      .then((list) => {
        if (!cancelled) setPlans(list);
      })
      .catch(() => {
        if (!cancelled) setCatalogError(true);
      })
      .finally(() => {
        if (!cancelled) setLoaded(true);
      });
    billingApi
      .getSubscriptionStatus()
      .then((s) => {
        if (!cancelled) setStatus(s);
      })
      .catch(() => {
        /* best-effort : on n'affichera simplement aucune note d'accès. */
      });
    return () => {
      cancelled = true;
    };
  }, [planCode]);

  const plan = useMemo(() => findOneTimePass(plans, planCode), [plans, planCode]);
  const passModule = plan ? passModuleOf(plan) : null;
  /* Demi-tour depuis Stripe : `cancel_url` ramène ici avec le pass choisi (le
     serveur la construit, cf. `BillingService.checkoutCancelUrl`). On le dit
     sobrement — rien n'a été débité, et son choix est toujours là. */
  const canceled = searchParams.get("canceled") === "1";

  /* Retour par le bouton « précédent » : le navigateur restaure la page depuis
     son cache (bfcache) telle qu'on l'a quittée — donc avec `redirecting` à
     vrai, un bouton figé sur « Redirection… » et plus aucun moyen de payer.
     `pageshow` est le seul événement émis dans ce cas (aucun effet React ne
     rejoue), d'où l'écoute directe. */
  useEffect(() => {
    const onShow = (e: PageTransitionEvent) => {
      if (e.persisted) setRedirecting(false);
    };
    window.addEventListener("pageshow", onShow);
    return () => window.removeEventListener("pageshow", onShow);
  }, []);

  async function goToPayment() {
    if (!plan) return;
    // Le CTA d'achat d'un pass : c'est ici que l'achat s'engage réellement,
    // pas au clic qui a mené sur ce récapitulatif.
    track("PREMIUM_CTA_CLICKED", {
      ctaLocation: "PRICING",
      planCode: plan.code,
      screen: "recapitulatif",
    });
    track("PRICING_CTA_CLICKED", {planCode: plan.code});
    trackSubscribeClicked();
    setError(null);
    setRedirecting(true);
    try {
      const { url } = await billingApi.getPaymentLink(plan.code);
      window.location.assign(url);
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 503) {
          setError(
            "Le paiement n'est pas encore activé côté serveur. Réessayez plus tard.",
          );
        } else if (err.status === 404) {
          setError(
            "Ce pass n'est plus disponible. Revenez aux tarifs pour voir l'offre à jour.",
          );
        } else if (err.status === 401) {
          setError("Connexion expirée. Reconnectez-vous puis recommencez.");
        } else {
          setError(err.message);
        }
      } else {
        setError("Impossible d'ouvrir le paiement. Réessayez dans un instant.");
      }
      setRedirecting(false);
    }
  }

  if (!planCode || !loaded) return <RecapSkeleton />;

  // Pass inconnu, désactivé, ou catalogue injoignable : jamais d'écran cassé.
  if (!plan || !passModule) {
    return (
      <main className="rcp">
        <BackLink />
        <div className="rcp-empty">
          <h1 className="rcp-empty-title">
            {catalogError ? "Tarifs indisponibles" : "Ce pass n'est plus proposé"}
          </h1>
          <p className="rcp-empty-body">
            {catalogError
              ? "Nous n'avons pas pu charger l'offre à jour. Réessayez dans un instant."
              : "L'offre a évolué depuis votre clic. Choisissez un pass dans la grille à jour."}
          </p>
          <Link href="/tarifs" className="btn rcp-empty-cta">
            Voir les pass →
          </Link>
        </div>
        <style>{styles}</style>
      </main>
    );
  }

  const scope = SCOPE[passModule];
  const sessions = passSessionsLabel(plan);
  const monthly = passMonthlyLabel(plan);
  const duration = passDurationLabel(plan.durationDays);
  const access = accessCase(status, passModule);
  const prorated = access.kind === "upgrade";

  return (
    <main className="rcp">
      <BackLink />

      <header className="rcp-head">
        <span className="rcp-eyebrow">RÉCAPITULATIF</span>
        <h1 className="rcp-title">
          Votre pass <em>{MODULE_NAME[passModule]}</em> — {duration}
        </h1>
        <p className="rcp-sub">
          Vérifiez votre choix, puis poursuivez vers le paiement sécurisé Stripe.
        </p>
      </header>

      <section className={`rcp-card rcp-card-${passModule === "INTEGRAL" ? "red" : "blue"}`}>
        <span className="rcp-tag">{scope.tag}</span>
        <h2 className="rcp-name">{plan.name}</h2>
        <p className="rcp-pitch">{scope.pitch}</p>

        <ul className="rcp-feats">
          <li>
            <Check className="rcp-tick" />
            <strong>{duration} d&apos;accès</strong>
          </li>
          {sessions !== null && (
            <li>
              <Check className="rcp-tick" />
              {sessions}
            </li>
          )}
          {scope.features.map((f) => (
            <li key={f}>
              <Check className="rcp-tick" />
              {f}
            </li>
          ))}
        </ul>

        <div className="rcp-price">
          <span className="rcp-price-label">
            {prorated ? "Prix du pass" : "Montant à payer"}
          </span>
          <span className="rcp-price-row">
            <span className="rcp-price-num">{formatPassPrice(plan.price)} €</span>
            <span className="rcp-price-once">payés une fois</span>
          </span>
          {monthly !== null && <span className="rcp-price-sub">{monthly}</span>}
        </div>

        <AccessNote access={access} duration={duration} passModule={passModule} />

        <button
          type="button"
          className={`rcp-cta rcp-cta-${passModule === "INTEGRAL" ? "red" : "blue"}`}
          onClick={goToPayment}
          disabled={redirecting}
        >
          {redirecting ? (
            <>
              <Loader2 className="rcp-spin" /> Redirection vers Stripe…
            </>
          ) : (
            <>
              <Lock className="rcp-cta-icon" /> Poursuivre vers le paiement
            </>
          )}
        </button>

        <p className="rcp-norenew">
          <CalendarOff className="rcp-mini-icon" />
          Paiement unique — aucun renouvellement automatique.
        </p>
      </section>

      {/* Un demi-tour n'est pas une erreur : ton neutre, pas de rouge, et on
          redit que le choix est conservé — c'est tout l'objet de ce parcours. */}
      {canceled && !error && (
        <p className="rcp-canceled" role="status">
          Paiement interrompu — vous n&apos;avez rien payé. Votre pass est
          toujours sélectionné, reprenez quand vous voulez.
        </p>
      )}

      {error && (
        <div className="form-error rcp-error" role="alert">
          {error}
        </div>
      )}

      <p className="rcp-foot">
        <ShieldCheck className="rcp-mini-icon" />
        Paiement sécurisé par Stripe. Vous recevez votre facture par email, et la
        date exacte de fin d&apos;accès y figure.
      </p>

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// NOTE D'ACCÈS — durée, cumul ou proration. Jamais une date calculée.
// ============================================================================

function AccessNote({
  access,
  duration,
  passModule,
}: {
  access: AccessCase;
  duration: string;
  passModule: PassModule;
}) {
  if (access.kind === "new") {
    return (
      <p className="rcp-note">
        <Info className="rcp-mini-icon" />
        <span>
          Ce pass ouvre <strong>{duration} d&apos;accès</strong> à partir du
          paiement. La date exacte de fin vous est confirmée par email.
        </span>
      </p>
    );
  }

  if (access.kind === "extension") {
    return (
      <p className="rcp-note">
        <Info className="rcp-mini-icon" />
        <span>
          Vous avez déjà un accès en cours
          {access.currentEnd ? <> jusqu&apos;au {formatDate(access.currentEnd)}</> : null}.{" "}
          <strong>Les durées se cumulent</strong> : ce pass ajoute {duration} à la
          suite de votre accès actuel, il ne le remplace pas.
        </span>
      </p>
    );
  }

  // Upgrade Civique → Intégral : le montant débité sera INFÉRIEUR au prix
  // affiché (crédit du temps restant, calculé par Stripe au checkout).
  return (
    <p className="rcp-note rcp-note-amber">
      <Info className="rcp-mini-icon" />
      <span>
        <strong>Le montant sera ajusté au paiement.</strong> Le temps restant sur
        votre pass Civique
        {access.currentEnd ? <> (jusqu&apos;au {formatDate(access.currentEnd)})</> : null}{" "}
        est déduit du prix ci-dessus : Stripe affiche le montant exact avant que
        vous validiez. Votre accès {MODULE_NAME[passModule]} court alors {duration} à
        partir du paiement.
      </span>
    </p>
  );
}

// ============================================================================
// CHROME
// ============================================================================

function BackLink() {
  return (
    <Link href="/tarifs" className="rcp-back">
      <ArrowLeft className="rcp-back-icon" /> Modifier mon choix
    </Link>
  );
}

function RecapSkeleton() {
  return (
    <div className="rcp-loading">
      <style>{`.rcp-loading { min-height: calc(100vh - 80px); }`}</style>
    </div>
  );
}

// ============================================================================
// STYLES
// ============================================================================

const styles = `
  .rcp {
    padding: 24px 36px 64px;
    max-width: 720px;
  }
  @media (max-width: 760px) { .rcp { padding: 20px 16px 56px; } }

  .rcp-back {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 13.5px;
    font-weight: 600;
    color: var(--color-muted);
    text-decoration: none;
    margin-bottom: 18px;
  }
  .rcp-back:hover { color: var(--color-ink); }
  .rcp-back-icon { width: 16px; height: 16px; }

  .rcp-head { margin-bottom: 22px; }
  .rcp-eyebrow {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--color-muted-2);
  }
  .rcp-title {
    font-family: var(--font-display);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.15;
    color: var(--color-ink);
    margin: 8px 0 8px;
  }
  .rcp-title em { font-style: italic; color: var(--color-red); }
  .rcp-sub {
    margin: 0;
    font-size: 14.5px;
    line-height: 1.55;
    color: var(--color-muted);
  }

  .rcp-card {
    border: 1.5px solid var(--color-line);
    border-radius: 22px;
    padding: 28px;
    background: white;
    display: flex;
    flex-direction: column;
  }
  @media (max-width: 480px) { .rcp-card { padding: 22px 18px; } }
  .rcp-card-blue {
    background: linear-gradient(135deg, var(--color-blue-soft) 0%, white 60%);
    border-color: var(--color-blue-light);
  }
  .rcp-card-red {
    background: linear-gradient(135deg, var(--color-red-light) 0%, white 60%);
    border-color: color-mix(in srgb, var(--color-red) 20%, transparent);
  }

  .rcp-tag {
    align-self: flex-start;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    text-transform: uppercase;
  }
  .rcp-name {
    font-family: var(--font-display);
    font-size: 26px;
    font-weight: 600;
    color: var(--color-ink);
    letter-spacing: -0.02em;
    margin: 8px 0 4px;
  }
  .rcp-pitch {
    margin: 0 0 18px;
    font-size: 14px;
    line-height: 1.55;
    color: var(--color-muted);
  }

  .rcp-feats {
    list-style: none;
    margin: 0 0 22px;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 9px;
  }
  .rcp-feats li {
    display: flex;
    align-items: flex-start;
    gap: 9px;
    font-size: 14px;
    line-height: 1.45;
    color: var(--color-ink-2);
  }
  .rcp-tick {
    width: 16px; height: 16px;
    flex: 0 0 auto;
    margin-top: 2px;
    color: var(--color-green);
  }

  .rcp-price {
    display: flex;
    flex-direction: column;
    gap: 3px;
    padding: 16px 18px;
    border-radius: 16px;
    background: white;
    border: 1px solid var(--color-line);
    margin-bottom: 16px;
  }
  .rcp-price-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
  }
  .rcp-price-row {
    display: flex;
    align-items: baseline;
    gap: 10px;
    flex-wrap: wrap;
  }
  /* Le montant réellement débité domine ; l'équivalent mensuel reste dessous. */
  .rcp-price-num {
    font-family: var(--font-display);
    font-size: 40px;
    font-weight: 700;
    letter-spacing: -0.025em;
    line-height: 1;
    color: var(--color-ink);
  }
  .rcp-price-once {
    font-size: 13px;
    font-weight: 600;
    color: var(--color-muted);
  }
  .rcp-price-sub {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.04em;
    color: var(--color-muted-2);
  }

  .rcp-note {
    display: flex;
    align-items: flex-start;
    gap: 9px;
    margin: 0 0 20px;
    padding: 12px 14px;
    border-radius: 12px;
    background: var(--color-blue-light);
    border: 1px solid color-mix(in srgb, var(--color-blue) 18%, transparent);
    font-size: 13px;
    line-height: 1.55;
    color: var(--color-ink-2);
  }
  .rcp-note strong { color: var(--color-ink); font-weight: 700; }
  .rcp-note-amber {
    background: color-mix(in srgb, var(--color-amber) 12%, white);
    border-color: color-mix(in srgb, var(--color-amber) 35%, transparent);
  }
  .rcp-mini-icon { width: 15px; height: 15px; flex: 0 0 auto; margin-top: 2px; }

  .rcp-cta {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 9px;
    width: 100%;
    min-height: 52px;
    padding: 14px 20px;
    border: none;
    border-radius: 14px;
    font-family: inherit;
    font-size: 15px;
    font-weight: 700;
    color: white;
    cursor: pointer;
    transition: filter 0.15s ease, transform 0.15s ease;
  }
  .rcp-cta-blue { background: var(--color-blue); }
  .rcp-cta-red { background: var(--color-red); }
  .rcp-cta:hover:not(:disabled) { filter: brightness(1.08); transform: translateY(-1px); }
  .rcp-cta:disabled { opacity: 0.6; cursor: default; }
  .rcp-cta-icon { width: 17px; height: 17px; }
  .rcp-spin { width: 17px; height: 17px; animation: rcp-spin 0.9s linear infinite; }
  @keyframes rcp-spin { to { transform: rotate(360deg); } }
  @media (prefers-reduced-motion: reduce) { .rcp-spin { animation: none; } }

  .rcp-norenew {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    margin: 14px 0 0;
    font-size: 12px;
    font-weight: 600;
    color: var(--color-green);
    text-align: center;
    line-height: 1.4;
  }

  .rcp-error { margin-top: 18px; }

  /* Neutre, jamais rouge : interrompre un paiement n'est pas une faute. */
  .rcp-canceled {
    margin: 18px 0 0;
    padding: 11px 14px;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    background: var(--color-paper-2);
    color: var(--color-muted);
    font-size: 12.5px;
    line-height: 1.5;
  }

  .rcp-foot {
    display: flex;
    align-items: flex-start;
    gap: 7px;
    margin: 22px 0 0;
    font-size: 12.5px;
    line-height: 1.55;
    color: var(--color-muted);
  }

  .rcp-empty {
    border: 1px solid var(--color-line);
    border-radius: 20px;
    padding: 32px 26px;
    background: white;
    text-align: center;
  }
  .rcp-empty-title {
    font-family: var(--font-display);
    font-size: 22px;
    font-weight: 600;
    color: var(--color-ink);
    margin: 0 0 8px;
  }
  .rcp-empty-body {
    margin: 0 0 20px;
    font-size: 14px;
    line-height: 1.55;
    color: var(--color-muted);
  }
  .rcp-empty-cta { min-height: 46px; }
`;
