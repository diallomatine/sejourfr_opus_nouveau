"use client";

import {useEffect, useState} from "react";

const QUERY = "(prefers-reduced-motion: reduce)";

/**
 * Le réglage système « réduire les animations », lu **en direct**.
 *
 * Presque tout le mouvement du site se règle en CSS (`@media
 * (prefers-reduced-motion: reduce)`), et c'est la bonne façon de faire : rien à
 * remonter dans React, rien à re-rendre. Ce hook n'existe que pour le cas où le
 * mouvement est **calculé en JavaScript** — la forme d'onde de l'enregistreur,
 * dont l'amplitude est peinte image par image : aucune règle CSS ne peut
 * l'atténuer.
 *
 * Deux précautions :
 * - **faux au premier rendu**, y compris côté serveur : on ne connaît le
 *   réglage qu'une fois monté. Ne jamais s'en servir pour décider *quoi* rendre,
 *   seulement *avec quelle amplitude* — sinon le contenu sauterait à
 *   l'hydratation.
 * - **réactif** : le réglage peut changer pendant qu'un enregistrement de trois
 *   minutes est en cours, on écoute donc la media query au lieu de la lire une
 *   fois.
 */
export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined" || !window.matchMedia) return;
    const mq = window.matchMedia(QUERY);
    const apply = () => setReduced(mq.matches);
    apply();
    mq.addEventListener("change", apply);
    return () => mq.removeEventListener("change", apply);
  }, []);

  return reduced;
}
