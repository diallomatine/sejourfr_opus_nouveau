/**
 * **Le geste « retour » d'une page**, quand elle n'a pas d'adresse fixe où
 * remonter.
 *
 * 🛑 **`router.back()` seul ne suffit pas.** Une page ouverte directement — lien
 * partagé, nouvel onglet, retour de paiement — n'a pas d'historique : le bouton
 * ne fait alors **rien**, ou sort du site. Le candidat est enfermé sur une page
 * dont la flèche ne répond pas.
 *
 * ⚠️ Le repli doit mener là où il serait arrivé en remontant, d'où le paramètre
 * — jamais une valeur unique codée ici.
 *
 * ✅ **Une adresse fixe reste préférable** : la plupart des écrans du kit
 * passent `backTo` à `Top`, donc un vrai lien, qui mène toujours quelque part et
 * se partage. Ce helper est pour les pages où le retour dépend d'où l'on vient.
 *
 * Miroir de `retourOuRepli` (`mobile_sejourfr/lib/core/router/retour.dart`).
 */
export function retourOuRepli(
    router: {back(): void; push(href: string): void},
    repli: string,
): void {
    if (typeof window !== "undefined" && window.history.length > 1) {
        router.back();
        return;
    }
    router.push(repli);
}
