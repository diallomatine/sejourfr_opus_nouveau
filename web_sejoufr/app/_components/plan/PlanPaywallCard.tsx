"use client";

import Link from "next/link";
import {ArrowRight, Check} from "lucide-react";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule} from "@/lib/types";
import {SKILL_PREMIUM_HREF} from "@/app/_components/skill-ui/SkillLayout";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import styles from "./plan.module.css";

/**
 * Ce que l'abonnement ouvre, dit du point de vue de quelqu'un qui LIT SON PLAN.
 *
 * ⚠️ **Liste distincte de celle du rapport de diagnostic** (`PREMIUM_BENEFITS`
 * dans `diagnostic/DiagnosticView.tsx`) et de l'argumentaire de `/tarifs` :
 * celle-ci nomme la suite du **plan** — la séance du jour, les priorités, le
 * réordonnancement —, l'autre nomme la suite d'**un rapport** qu'on vient de
 * lire. Les fusionner rendrait les deux écrans vagues. Ne pas les fusionner.
 *
 * ⚠️ **Vouvoiement**, comme tout le Plan : le tutoiement de la maquette décrit
 * un visiteur d'avant l'inscription, or cet écran n'existe qu'avec un compte.
 *
 * 🛑 **Miroir mot pour mot du mobile** (`plan_paywall_card.dart`) : ces cinq
 * lignes, le titre et les deux libellés d'action se changent des deux côtés
 * dans la même passe.
 */
export const PLAN_PREMIUM_BENEFITS = [
  "Toute votre séance du jour, chaque jour",
  "Vos priorités et vos petits sujets ciblés",
  "La correction IA et la version au niveau supérieur",
  "Votre plan qui évolue automatiquement",
  "Le moment où vous êtes prêt pour un examen blanc",
];

export const PLAN_PREMIUM_TITLE = "Débloquez votre plan complet";
export const PLAN_PREMIUM_CTA = "Débloquer mon plan";
export const PLAN_PREMIUM_SECONDARY_CTA = "Voir les formules";

/**
 * La carte d'abonnement du Plan, sous « Mes priorités ».
 *
 * **Elle ne s'affiche qu'à un compte sans accès TCF**, et c'est elle-même qui
 * le décide : l'autorité est `canAccessModule(user, "TCF")`, la même que
 * partout ailleurs sur le web (`PlanFreeBar`, `SkillAccess` côté
 * serveur). Un abonné ne peut donc pas la voir par un oubli d'appelant.
 *
 * 🛑 **Elle ne masque rien et ne compte rien.** Le Plan reste intégralement
 * visible — priorités, compteurs, exercice désigné : ce sont les **accès** qui
 * sont fermés, ligne par ligne, par le `locked` du serveur. Cette carte ne
 * fait que nommer ce que l'abonnement ouvre ; elle ne redit pas les cadenas
 * déjà posés au-dessus d'elle et ne les contredit pas.
 *
 * 🛑 **Aucun second chemin d'abonnement.** Les deux actions mènent à
 * `SKILL_PREMIUM_HREF` — la grille de passes —, avec la provenance qui suit le
 * candidat jusqu'à la page d'achat, et la **même** mesure de conversion que
 * tous les autres cadenas du Plan (`DIAGNOSTIC_TO_PREMIUM_CLICKED`, déjà dans
 * l'allowlist de `/plan`). Aucun événement d'audience n'est ajouté.
 */
export function PlanPaywallCard({onPremiumClick}: {
  /** Mesure de conversion du verrou, partagée avec les autres cadenas du Plan. */
  onPremiumClick: () => void;
}) {
  const {user} = useAuth();
  const premiumHref = useTrafficSourceHref(SKILL_PREMIUM_HREF);

  if (canAccessModule(user, "TCF")) return null;

  return (
    <section className={styles.paywall} aria-labelledby="plan-paywall-title">
      <div className={styles.paywallHead}>
        <h3 id="plan-paywall-title">{PLAN_PREMIUM_TITLE}</h3>
        <ul className={styles.paywallList}>
          {PLAN_PREMIUM_BENEFITS.map((benefit) => (
            <li key={benefit}>
              <Check size={15} strokeWidth={2.8} aria-hidden />
              {benefit}
            </li>
          ))}
        </ul>
      </div>
      <div className={styles.paywallActions}>
        <Link className={styles.primaryButton} href={premiumHref} onClick={onPremiumClick}>
          {PLAN_PREMIUM_CTA} <ArrowRight size={17} aria-hidden />
        </Link>
        <Link className={styles.paywallGhost} href={premiumHref} onClick={onPremiumClick}>
          {PLAN_PREMIUM_SECONDARY_CTA}
        </Link>
      </div>
    </section>
  );
}
