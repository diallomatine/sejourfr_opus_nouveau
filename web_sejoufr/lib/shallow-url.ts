"use client";

/**
 * Réécrit l'URL **sans navigation** : l'App Router met à jour son URL courante,
 * mais ne remonte ni la route, ni les composants, et ne redemande rien au
 * serveur (API « Native History » de Next.js).
 *
 * À quoi ça sert ici : dans le parcours TCF EE/EO, la tâche affichée (T1/T2/T3)
 * est devenue un **état local** — les trois tâches sont chargées ensemble, les
 * pastilles filtrent. Mais une tâche reste une adresse : `…/tache/2/competences`
 * doit continuer de s'ouvrir directement, de se partager, et de rester exacte
 * dans la barre d'adresse pendant qu'on change de tâche. C'est exactement ce que
 * fait cette fonction, et rien de plus.
 *
 * **`replaceState`, pas `pushState`** : filtrer n'est pas naviguer. Empiler une
 * entrée d'historique par pastille obligerait à appuyer trois fois sur
 * « précédent » pour sortir de l'épreuve. Avec le remplacement, « précédent »
 * ramène là d'où l'on vient — l'écran parent — ce qui est la seule lecture
 * cohérente de ce bouton ici.
 *
 * Sans effet côté serveur, et silencieuse si le navigateur refuse (URL
 * inter-origines impossible ici, mais on ne casse jamais un écran pour une
 * barre d'adresse).
 */
export function replaceUrlShallow(url: string): void {
  if (typeof window === "undefined") return;
  if (window.location.pathname + window.location.search === url) return;
  try {
    window.history.replaceState(window.history.state, "", url);
  } catch {
    // Historique indisponible : l'écran reste juste, seule l'URL ne suit pas.
  }
}
