"use client";

import {track} from "@/lib/analytics";
import {planUnlockHref, type PlanUnlockModule} from "@/lib/plan-unlock";
import {Cta, Sticky} from "@/app/_components/sejour/SejourKit";

/**
 * **La porte d'achat du Plan** : un seul geste, ancré en bas de l'écran.
 *
 * 🛑 **Refonte du 2026-09-20 (demande du propriétaire).** Cette surface portait
 * trois blocs — la carte bleue « Passez du diagnostic à la progression » avec
 * son texte et ses puces, le sélecteur de durée de pass, et le bouton. Les deux
 * premiers sont **supprimés** : la promesse déménage sur l'écran de transition
 * (`/plan/debloquer`) et le choix de la durée se fait sur la page de choix du
 * pass, qui est déjà l'autorité du catalogue. Dire la même promesse deux fois
 * de suite, et proposer deux grilles de durées à deux écrans d'intervalle,
 * étaient les deux défauts constatés. Ne pas les réintroduire ici.
 *
 * 🛑 **Le bouton ne mène plus au paiement** : il ouvre l'écran de transition,
 * qui raconte ce que le diagnostic a trouvé puis conduit au pass. Le Plan n'a
 * donc **aucun prix** et **aucun catalogue** à charger — un appel réseau de
 * moins sur l'écran le plus lu du produit.
 *
 * 🛑 **Le Plan ne masque rien et ne compte rien.** Ce sont les **accès** qui
 * sont fermés, ligne par ligne, par le `locked` du serveur.
 */

/** La mesure de conversion du verrou, partagée avec tous les cadenas du Plan.
 *  🛑 Aucun autre événement : l'allowlist est doublée côté serveur. */
function trackPaywallClick() {
  track("PREMIUM_CTA_CLICKED", {ctaLocation: "LOCKED_PLAN", screen: "plan"});
}

/**
 * Le geste de déblocage du Plan, collé en bas.
 *
 * L'appelant enveloppe son écran d'un `SejourApp sticky` — la barre basse a
 * besoin de sa réserve de place.
 */
export function PlanPaywall({
  module,
  cta,
}: {
  module: PlanUnlockModule;
  cta: string;
}) {
  return (
    <Sticky>
      <Cta href={planUnlockHref(module)} onClick={trackPaywallClick}>
        {cta}
      </Cta>
    </Sticky>
  );
}
