"use client";

import {useEffect, useMemo, useState} from "react";
import {track} from "@/lib/analytics";
import {billingApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  formatPassPrice,
  oneTimePassesOf,
  passCheckoutHref,
  passDurationLabel,
  passMonthlyLabel,
  popularPassCodeOf,
  type PassModule,
} from "@/lib/passes";
import {useTrafficSource} from "@/lib/use-traffic-source";
import type {PlanPublicResponse} from "@/lib/types";
import {
  Card,
  CheckList,
  Cta,
  Pad,
  PassCard,
  Section,
  Stack,
  Sticky,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";

/**
 * **Le paywall du Plan**, dit du point de vue de quelqu'un qui LIT SON PLAN.
 *
 * ⚠️ **Liste distincte de celle du rapport de diagnostic** (`PREMIUM_BENEFITS`
 * dans `diagnostic/DiagnosticView.tsx`) et de l'argumentaire de `/tarifs` :
 * celle-ci nomme la suite du **plan** — la prochaine action, les priorités, le
 * réordonnancement —, l'autre nomme la suite d'**un rapport** qu'on vient de
 * lire. Les fusionner rendrait les deux écrans vagues. Ne pas les fusionner.
 *
 * 🛑 **Notre offre, pas celle de la maquette.** La maquette affiche un prix
 * unique (« 14,99 €/mois ») ; nous vendons des **passes à durée fixe**, servis
 * par `GET /api/billing/plans`. Aucun prix n'est écrit ici, aucune durée n'est
 * codée en dur : la grille vient du serveur et le parcours d'achat est celui
 * de `lib/passes.ts` (prix cliqué → récapitulatif → Stripe), déclaré une seule
 * fois pour tout le web.
 *
 * 🛑 **Il ne masque rien et ne compte rien.** Le Plan reste lisible — ce sont
 * les **accès** qui sont fermés, ligne par ligne, par le `locked` du serveur.
 *
 * 🛑 **Au palier desktop, « Débloquer mon plan » reste l'action DOMINANTE.**
 * C'est acquis sans rien ajouter : le kit rend `.sticky` à sa carte de fin de
 * colonne (la maquette fait pareil avec `sf-desk-cta`) et son bouton y est le
 * **seul** à garder la pleine largeur — tout autre `.btn` hors carte est
 * plafonné à 420 px. Ne pas y poser un second CTA « dans le flux » : le nôtre y
 * est déjà, et il serait alors écrit deux fois.
 */
export const PLAN_PREMIUM_BENEFITS = [
  "Toute votre séance du jour, chaque jour",
  "Vos priorités et vos petits sujets ciblés",
  "La correction IA et la version au niveau supérieur",
  "Votre plan qui évolue automatiquement",
  "Le moment où vous êtes prêt pour un examen blanc",
];

export const CIVIC_PLAN_PREMIUM_BENEFITS = [
  "Vos séries ciblées sur ce qui vous coûte le plus de points",
  "L'explication de chacune de vos erreurs",
  "Le suivi de maîtrise, thème après thème",
  "Les révisions rappelées au bon moment",
  "Votre plan recalculé après chaque série",
];

export const PLAN_PREMIUM_TITLE = "Passez du diagnostic à la progression";
export const PLAN_PREMIUM_TEXT =
  "Votre diagnostic vous montre quoi améliorer. Avec un pass, SejourFR vous accompagne étape par étape pour le travailler.";
export const CIVIC_PLAN_PREMIUM_TEXT =
  "Votre diagnostic vous montre quoi réviser. Avec un pass, votre plan vous accompagne thème après thème jusqu'à ce qu'ils soient acquis.";

const PASS_LABEL: Record<PassModule, string> = {
  INTEGRAL: "Pass Intégral",
  CIVIQUE: "Pass Civique",
};

const PASS_NOTE: Record<PassModule, string> = {
  INTEGRAL: "Le tarif est celui du Pass Intégral : un paiement unique, pas un abonnement mensuel.",
  CIVIQUE: "Le tarif est celui du Pass Civique : un paiement unique, pas un abonnement mensuel.",
};

/** Repli quand le catalogue est injoignable : la grille de passes, jamais un
 *  écran sans porte de sortie. */
const CATALOG_HREF: Record<PassModule, string> = {
  INTEGRAL: "/paiement?module=INTEGRAL",
  CIVIQUE: "/paiement?module=CIVIQUE",
};

/** La mesure de conversion du verrou, partagée avec tous les cadenas du Plan.
 *  🛑 Aucun autre événement : l'allowlist est doublée côté serveur. */
function trackPaywallClick() {
  track("PREMIUM_CTA_CLICKED", {ctaLocation: "LOCKED_PLAN", screen: "plan"});
}

/**
 * Le bloc de conversion du Plan gratuit : la carte hero, ce que le pass ouvre,
 * le choix de la durée, et le CTA collé en bas.
 *
 * L'appelant enveloppe son écran d'un `SejourApp sticky` — la barre basse a
 * besoin de sa réserve de place.
 */
export function PlanPaywall({
  module,
  benefits,
  title = PLAN_PREMIUM_TITLE,
  text = PLAN_PREMIUM_TEXT,
  cta,
}: {
  module: PassModule;
  benefits: string[];
  title?: string;
  text?: string;
  cta: string;
}) {
  const {status} = useAuth();
  const source = useTrafficSource();
  const [plans, setPlans] = useState<PlanPublicResponse[] | null>(null);
  const [chosen, setChosen] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    billingApi.listPlans().then(
      (list) => { if (!cancelled) setPlans(list); },
      () => { /* confort : sans catalogue, le CTA vise la grille de passes */ },
    );
    return () => { cancelled = true; };
  }, []);

  const passes = useMemo(
    () => (plans ? oneTimePassesOf(plans, module) : []),
    [plans, module],
  );

  /* Le pass mis en avant fait le choix par défaut — déclaré une seule fois
     dans `lib/passes.ts`, jamais recopié dans un écran. */
  const selected = chosen ?? popularPassCodeOf(passes);
  const current = passes.find((pass) => pass.code === selected) ?? null;

  /* `status === "loading"` ⇒ on vise le récapitulatif : le middleware renverra
     un visiteur sur `/connexion?next=…`. Jamais l'inverse — envoyer un compte
     connecté sur `/inscription` serait un cul-de-sac. */
  const authenticated = status === "loading" ? null : status === "authenticated";
  const href = current
    ? passCheckoutHref(current.code, authenticated, source)
    : CATALOG_HREF[module];
  const caption = current
    ? `${PASS_LABEL[module]} · ${passDurationLabel(current.durationDays)} · ${formatPassPrice(current.price)} € · paiement unique`
    : undefined;

  return (
    <>
      <Section>
        <Pad>
          <Card variant="hero" className={sejourStyles.cardSoft}>
            <h2 className={sejourStyles.title}>{title}</h2>
            <p className={sejourStyles.sub}>{text}</p>
            <CheckList items={benefits} />
          </Card>
        </Pad>
      </Section>

      {passes.length > 0 && (
        <Section>
          <Pad>
            <p className={sejourStyles.label}>{PASS_LABEL[module]}</p>
            {/* Les durées se rangent en colonnes au palier desktop : empilées
                sur 980 px, elles repoussaient le CTA de déblocage hors de
                l'écran — c'est-à-dire l'action que cette section sert. */}
            <Stack className={sejourStyles.deskGrid}>
              {passes.map((pass) => (
                <PassCard
                  key={pass.code}
                  title={passDurationLabel(pass.durationDays)}
                  subtitle={[
                    `${formatPassPrice(pass.price)} €`,
                    passMonthlyLabel(pass),
                    "paiement unique",
                  ].filter(Boolean).join(" · ")}
                  selected={pass.code === selected}
                  onSelect={() => setChosen(pass.code)}
                />
              ))}
            </Stack>
            <p className={sejourStyles.tiny}>{PASS_NOTE[module]}</p>
          </Pad>
        </Section>
      )}

      <Sticky>
        <Cta
          href={href}
          caption={caption}
          variant={module === "CIVIQUE" ? "blue" : "primary"}
          onClick={trackPaywallClick}
        >
          {cta}
        </Cta>
      </Sticky>
    </>
  );
}
