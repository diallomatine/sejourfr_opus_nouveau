"use client";

import {useRouter} from "next/navigation";
import {useState, type ReactNode} from "react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {useMockExamLauncher} from "@/app/_components/hub/MockExamLauncher";
import type {ActionCardCta} from "@/app/_components/sejour/SejourKit";
import {ACCUEIL_CIVIQUE_CTA, ACCUEIL_TCF_CTA} from "@/lib/accueil";
import type {civicNowCard} from "@/lib/civic-plan";
import {planHref} from "@/lib/module-switch";
import type {planNowCard} from "@/lib/plan-domain";
import {planUnlockHref} from "@/lib/plan-unlock";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

type TcfCarte = NonNullable<ReturnType<typeof planNowCard>>;
type CiviqueCarte = NonNullable<ReturnType<typeof civicNowCard>>;

/** L'écran qui porte la carte, pour la mesure du paywall. */
type GesteScreen = "dashboard" | "progression";

/**
 * **Le geste de l'étape courante TCF hors du Plan** — Accueil (« À faire
 * maintenant ») et « Prochaine étape » des écrans Progression. Extrait à son
 * 2ᵉ lecteur ; miroir mobile : `gesteEtapeTcf` (`plan/now_card_gestes.dart`).
 *
 * 🛑 **Le geste est SERVI** (`planNowCard`) : `DEBLOQUER` ouvre l'écran de
 * transition (libellé servi : un verrou se dit), `OUVRIR_ETAPE` l'écran de
 * l'étape, `LANCER` la mesure ou l'exercice par les lanceurs du Plan, `AUCUN`
 * ⇒ `null` — jamais un bouton mort.
 */
export function useGesteEtapeTcf(screen: GesteScreen): {
  cta: (vue: TcfCarte) => ActionCardCta | null;
  erreur: string | null;
  paywall: (journeyId: string | null | undefined) => ReactNode;
} {
  const router = useRouter();
  const exercices = usePlanExercise();
  const mesures = usePlanAssessment();
  const busy = exercices.starting || mesures.starting !== null;

  const cta = (vue: TcfCarte): ActionCardCta | null => {
    if (vue.geste === "DEBLOQUER") {
      return {label: vue.cta, onClick: () => router.push(planUnlockHref("TCF"))};
    }
    if (vue.geste === "OUVRIR_ETAPE") {
      return vue.etapeHref ? {label: ACCUEIL_TCF_CTA, href: vue.etapeHref} : null;
    }
    if (vue.geste !== "LANCER") return null;
    return {
      label: ACCUEIL_TCF_CTA,
      disabled: busy,
      onClick: () => {
        if (vue.mesure) void mesures.start(vue.mesure.assessment);
        else if (vue.exercise) void exercices.start(vue.exercise);
      },
    };
  };

  return {
    cta,
    erreur: exercices.error ?? mesures.error,
    paywall: (journeyId) => (
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen={screen}
        module="INTEGRAL"
        journeyId={journeyId ?? null}
        open={exercices.paywallOpen || mesures.paywallOpen}
        onClose={() => {
          exercices.closePaywall();
          mesures.closePaywall();
        }}
      />
    ),
  };
}

/**
 * **Le geste de l'étape courante civique hors du Plan** (`civicNowCard`
 * appelée avec `lancerExamen: true`, DEC-18). L'examen de thème part du
 * lanceur partagé ; une cible du plan dérivé mène au Plan civique, seul
 * porteur de son lanceur de série. Miroir mobile : `gesteEtapeCivique`.
 */
export function useGesteEtapeCivique(screen: GesteScreen): {
  cta: (carte: CiviqueCarte) => ActionCardCta | null;
  paywall: (journeyId: string | null | undefined) => ReactNode;
} {
  const router = useRouter();
  const lancerExamen = useMockExamLauncher();
  const [ouvert, setOuvert] = useState(false);

  const cta = (carte: CiviqueCarte): ActionCardCta | null => {
    if (carte.geste === "DEBLOQUER") {
      return {label: carte.cta, onClick: () => router.push(planUnlockHref("CIVIQUE"))};
    }
    if (carte.geste === "OUVRIR_ETAPE") {
      return carte.etapeHref ? {label: ACCUEIL_CIVIQUE_CTA, href: carte.etapeHref} : null;
    }
    if (carte.geste !== "LANCER") return null;
    const examen = carte.examen;
    if (examen) {
      return {
        label: ACCUEIL_CIVIQUE_CTA,
        onClick: () => lancerExamen({kind: "CIVIQUE", ...examen, onPaywall: () => setOuvert(true)}),
      };
    }
    return {label: ACCUEIL_CIVIQUE_CTA, href: planHref("CIVIQUE")};
  };

  return {
    cta,
    paywall: (journeyId) => (
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen={screen}
        module="CIVIQUE"
        journeyId={journeyId ?? null}
        open={ouvert}
        onClose={() => setOuvert(false)}
      />
    ),
  };
}
