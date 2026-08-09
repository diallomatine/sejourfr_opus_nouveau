"use client";

import {useSyncExternalStore} from "react";
import {detectTrafficSource, type TrafficSource} from "./audience";

function subscribeTrafficSource() {
  return () => {};
}

/** Lit la provenance de l'URL après hydratation, tout en gardant un rendu
 * serveur neutre. La valeur ne change pas pendant la vie d'une page. */
export function useTrafficSource(): TrafficSource | null {
  return useSyncExternalStore(subscribeTrafficSource, detectTrafficSource, () => null);
}
