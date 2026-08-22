package com.sejourfr.app.util;

/**
 * Repartition d'un total entier entre des lignes, <b>a somme conservee</b>
 * (methode des plus forts restes) — <b>autorite unique</b>.
 *
 * <p><b>Le probleme qu'elle resout.</b> Trois lignes valant chacune un tiers
 * arrondissent a 33 %, et le pied de table affiche 99 %. Un lecteur qui voit
 * « 99 % » se demande legitimement ou est passe le pourcent manquant, et il a
 * raison de se poser la question : c'est exactement le genre d'ecart qui fait
 * douter de tout le tableau. La methode des plus forts restes distribue le
 * reliquat aux lignes dont la partie decimale est la plus grande, ce qui garantit
 * que <b>la somme des lignes egale toujours le pied</b>.
 *
 * <p><b>Elle vit au serveur, pas dans le front.</b> La maquette la fait cote
 * client ; on la remonte ici pour la meme raison que {@code SkillStatusResolver}
 * ou {@code SituationDansNiveau} : trois fronts qui arrondissent chacun de leur
 * cote finissent par afficher trois totaux differents pour la meme mesure.
 *
 * <p><b>Ce n'est pas une regle de calcul, c'est une regle d'affichage.</b> Les
 * valeurs brutes ne sont jamais modifiees : elles sont servies a cote, et c'est
 * sur elles qu'on raisonne.
 */
public final class RepartitionArrondie {

    private RepartitionArrondie() {
    }

    /**
     * Repartit {@code total} proportionnellement aux {@code poids}.
     *
     * <p>Invariants tenus, quels que soient les poids :
     * <ul>
     *   <li>la somme du resultat vaut exactement {@code total} — sauf si tous
     *       les poids sont nuls, auquel cas il n'y a rien a repartir et tout
     *       vaut zero (repartir un total entre des lignes vides inventerait des
     *       parts) ;</li>
     *   <li>un poids nul recoit zero : une ligne sans donnee ne recoit jamais un
     *       point d'arrondi ;</li>
     *   <li>a reste egal, c'est la ligne au plus fort poids qui l'emporte, puis
     *       la premiere — deterministe, donc reproductible d'un appel a l'autre.</li>
     * </ul>
     *
     * @param poids valeurs brutes, jamais nulles individuellement et jamais
     *              negatives
     * @param total total a repartir (typiquement 100 pour des pourcentages)
     * @return un tableau de la meme longueur, de somme {@code total}
     */
    public static int[] repartir(long[] poids, int total) {
        int n = poids == null ? 0 : poids.length;
        int[] parts = new int[n];
        if (n == 0 || total <= 0) return parts;

        long somme = 0;
        for (long p : poids) {
            if (p < 0) throw new IllegalArgumentException("Poids négatif : " + p);
            somme += p;
        }
        // Rien a repartir : on ne fabrique pas des parts a partir de zero.
        if (somme == 0) return parts;

        long[] restes = new long[n];
        int attribue = 0;
        for (int i = 0; i < n; i++) {
            long produit = poids[i] * (long) total;
            parts[i] = (int) (produit / somme);
            restes[i] = produit % somme;
            attribue += parts[i];
        }

        int reliquat = total - attribue;
        // Selection des `reliquat` plus forts restes, sans tri : n est petit
        // (une poignee de lignes) et un tri stable demanderait un comparateur
        // sur des index boxes pour rien.
        for (int tour = 0; tour < reliquat; tour++) {
            int meilleur = -1;
            for (int i = 0; i < n; i++) {
                if (poids[i] == 0) continue;      // une ligne vide ne gagne rien
                if (restes[i] < 0) continue;      // deja servie a ce tour
                if (meilleur < 0
                        || restes[i] > restes[meilleur]
                        || (restes[i] == restes[meilleur] && poids[i] > poids[meilleur])) {
                    meilleur = i;
                }
            }
            if (meilleur < 0) break;
            parts[meilleur]++;
            restes[meilleur] = -1;
        }
        return parts;
    }

    /**
     * Pourcentages entiers de somme 100 — le cas d'usage courant.
     *
     * <p>Rend un tableau de zeros quand rien n'a ete observe : « 0 % partout »
     * est honnete, « 100 % reparti entre des lignes vides » ne l'est pas.
     */
    public static int[] pourcentages(long[] poids) {
        return repartir(poids, 100);
    }
}
