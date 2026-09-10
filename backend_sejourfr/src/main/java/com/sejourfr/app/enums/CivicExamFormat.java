package com.sejourfr.app.enums;

/**
 * Le format OFFICIEL de l'examen civique.
 *
 * <p>🛑 <b>C'est du code, pas un reglage.</b> 40 questions et un seuil de 32 ne
 * sont pas des parametres produit : ce sont les regles de l'epreuve. Les loger
 * dans {@code application.yaml} laisserait croire qu'on peut les ajuster, et
 * c'est exactement le raisonnement qui a mis la table des paliers TCF en six
 * copies. Meme traitement que {@code DureeEpreuve} et {@code TargetProcedure}.
 */
public final class CivicExamFormat {

    /** Questions d'un examen civique reel. */
    public static final int QUESTIONS = 40;

    /** Bonnes reponses exigees pour reussir. */
    public static final int SEUIL_REUSSITE = 32;

    private CivicExamFormat() {
    }

    /**
     * La <b>projection</b> d'un resultat de diagnostic sur l'echelle de
     * l'examen reel (20_ §4.4).
     *
     * <p>« Sur un examen de 40 questions, votre resultat actuel correspondrait a
     * environ 30 / 40. Le seuil de reussite est de 32. »
     *
     * <p>🛑 <b>C'est une PROJECTION, jamais un pronostic.</b> Elle se calcule
     * cote serveur et se transmet au client : ni ecrite en dur dans une
     * maquette, ni recalculee par un front — deux calculs de la meme chose
     * finiraient par afficher deux nombres.
     *
     * <p>🛑 <b>Aucune question posee ⇒ {@code null}</b>, jamais zero. « On n'a
     * rien mesure » ne se dit pas « vous auriez 0 sur 40 ».
     */
    public static Integer projection(int bonnes, int posees) {
        if (posees <= 0) {
            return null;
        }
        return (int) Math.round((double) bonnes / posees * QUESTIONS);
    }
}
