"use client";

import {useSyncExternalStore} from "react";
import {detectTrafficSource, withTrafficSource, type TrafficSource} from "./audience-events";

function subscribeTrafficSource() {
  return () => {};
}

/** Lit la provenance de l'URL après hydratation, tout en gardant un rendu
 * serveur neutre. La valeur ne change pas pendant la vie d'une page. */
export function useTrafficSource(): TrafficSource | null {
  return useSyncExternalStore(subscribeTrafficSource, detectTrafficSource, () => null);
}

/**
 * Chemin interne portant la provenance courante — la forme qu'on donne à tout
 * lien **sortant vers une porte de compte ou d'achat** (`/inscription`,
 * `/connexion`, `/tarifs`, `/paiement`, `/paiement/recapitulatif`). Sans elle,
 * le `?src=` mourait dès qu'on quittait `/reussir`, `/diagnostic` ou `/plan`,
 * et une inscription venue de TikTok devenait indistinguable d'un accès direct.
 *
 * Sans provenance détectée, le chemin est rendu **inchangé** : ce hook ne
 * fabrique jamais de dimension, et n'écrit rien sur l'appareil du visiteur.
 */
export function useTrafficSourceHref(path: string): string {
  return withTrafficSource(path, useTrafficSource());
}
