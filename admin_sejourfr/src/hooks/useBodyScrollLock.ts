import { useEffect } from "react";

let locks = 0;
let previousOverflow = "";

/**
 * Bloque le défilement de la page tant que `active` est vrai (modale, tiroir de
 * navigation). Compté : une modale ouverte depuis le tiroir ne rend pas le
 * défilement en se fermant si le tiroir est encore ouvert.
 */
export function useBodyScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return;
    if (locks === 0) {
      previousOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
    }
    locks += 1;
    return () => {
      locks -= 1;
      if (locks === 0) document.body.style.overflow = previousOverflow;
    };
  }, [active]);
}
