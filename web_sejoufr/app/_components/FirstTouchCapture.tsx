"use client";

import {useEffect} from "react";
import {captureFirstTouchOnLanding} from "@/lib/analytics";

/** Capte le premier contact (UTM, referrer, écran d'arrivée) au premier
 *  chargement du site. Layout racine ; ne rend rien, n'envoie rien. */
export function FirstTouchCapture() {
  useEffect(() => {
    captureFirstTouchOnLanding();
  }, []);
  return null;
}
