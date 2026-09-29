package com.sejourfr.app.enums;

/**
 * Le format OFFICIEL de l'examen civique, et le format SejourFR de l'examen de
 * theme.
 *
 * <p>🛑 <b>C'est du code, pas un reglage.</b> 40 questions et un seuil de 32 ne
 * sont pas des parametres produit : ce sont les regles de l'epreuve, fixees par
 * l'<b>arrete du 10 octobre 2025</b> relatif au programme, aux epreuves et aux
 * modalites d'organisation de l'examen civique (JORF n° 0240 du 12 octobre 2025,
 * NOR INTV2527907A). Les loger dans {@code application.yaml} laisserait croire
 * qu'on peut les ajuster, et c'est exactement le raisonnement qui a mis la table
 * des paliers TCF en six copies. Meme traitement que {@code DureeEpreuve} et
 * {@code TargetProcedure}.
 *
 * <h2>🛑 Ce qui vit ICI, et ce qui vit AILLEURS (arbitrage D-38, 2026-09-19)</h2>
 *
 * <table>
 *   <tr><th>Valeur</th><th>Autorite</th></tr>
 *   <tr><td>40 questions, seuil 32, 45 min, partage 28 / 12</td>
 *       <td><b>ici</b></td></tr>
 *   <tr><td>Le <b>quota par unite officielle</b> (Devise et symboles 3,
 *           Laicite 2, …)</td>
 *       <td>la <b>table des 16 unites officielles</b> (P8.2a) — jamais ici</td></tr>
 *   <tr><td>Les totaux par thematique (11 / 6 / 11 / 8 / 4)</td>
 *       <td><b>nulle part</b> : ils se <b>derivent</b> par somme des quotas
 *           d'unite. Les declarer en ferait une 2<sup>e</sup> copie, et un jour
 *           l'une des deux aurait tort.</td></tr>
 * </table>
 *
 * <h2>⚠️ Pourquoi le diagnostic garde SON 28 / 12</h2>
 * <p>{@code sejourfr.civic-diagnostic.connaissances: 28} et
 * {@code mises-en-situation: 12} ne sont pas une copie de ce qui suit, et ne
 * doivent pas etre remplaces par une lecture d'ici : le diagnostic porte un
 * {@code config-version} <b>parce qu'un resultat date se relit avec la
 * configuration QUI L'A PRODUIT</b>. Les deux valeurs coincident aujourd'hui, et
 * c'est voulu (arbitrage du 2026-09-10, qui a aligne le diagnostic sur l'epreuve
 * reelle) ; mais l'une est une <b>loi</b> et l'autre une <b>convention de
 * lecture datee</b>. Meme nuance que {@code tcf-journey-config-v1} et {@code v2},
 * qui coexistent.
 */
public final class CivicExamFormat {

    // ------------------------------------------------------------------------
    // L'examen OFFICIEL — arrete du 10 octobre 2025, article 3
    // ------------------------------------------------------------------------

    /** Questions d'un examen civique reel. */
    public static final int QUESTIONS = 40;

    /** Bonnes reponses exigees pour reussir (80 %). */
    public static final int SEUIL_REUSSITE = 32;

    /** Duree maximale de l'epreuve. */
    public static final int DUREE_SECONDES = 45 * 60;

    /**
     * Questions de <b>connaissances</b> dans l'examen reel.
     *
     * <p>🛑 {@link #CONNAISSANCES} + {@link #MISES_EN_SITUATION} =
     * {@link #QUESTIONS}, et {@link #assertionsDeFormat()} le verrouille.
     */
    public static final int CONNAISSANCES = 28;

    /**
     * <b>Mises en situation</b> dans l'examen reel.
     *
     * <p>🛑 <b>Elles ne sont PAS reparties sur les cinq thematiques</b> : l'annexe
     * I en place <b>6 en « Principes et valeurs de la Republique »</b> et
     * <b>6 en « Droits et devoirs »</b>, et <b>aucune</b> dans les trois autres.
     * Ou elles tombent releve du <b>quota par unite</b>, donc de la table des
     * 16 unites — pas de cette classe.
     */
    public static final int MISES_EN_SITUATION = 12;

    // ------------------------------------------------------------------------
    // L'examen de THEME — format SejourFR, jamais un format officiel (D-31)
    // ------------------------------------------------------------------------

    /**
     * Questions d'un examen de theme.
     *
     * <p>🛑 <b>Ce format n'existe pas dans l'arrete.</b> C'est un format
     * SejourFR : l'examen reel porte sur les cinq thematiques a la fois. Il vit
     * ici quand meme, parce que le <b>cycle en fait sa cloture de bloc</b> et
     * qu'il a besoin d'une autorite — il a vecu en constantes privees d'un
     * service de 900 lignes, ou {@code MeService} en a recopie le seuil en
     * litteral.
     *
     * <p>⚠️ Un examen de theme <b>respecte la STRUCTURE officielle</b> sans
     * pouvoir etre conforme a l'epreuve reelle (D-31) : il n'emporte de mises en
     * situation que dans les deux thematiques ou l'examen reel en pose.
     */
    public static final int QUESTIONS_THEME = 20;

    /** Bonnes reponses exigees sur un examen de theme (80 %, comme l'officiel). */
    public static final int SEUIL_REUSSITE_THEME = 16;

    /** Duree d'un examen de theme. */
    public static final int DUREE_THEME_SECONDES = 20 * 60;

    private CivicExamFormat() {
    }

    /**
     * Les invariants du format, verifies par un test normatif.
     *
     * <p>🛑 Existe pour que les valeurs ci-dessus ne puissent pas deriver en
     * silence : {@code CONNAISSANCES + MISES_EN_SITUATION} doit faire
     * {@link #QUESTIONS}, et les deux seuils doivent valoir 80 % de leur total.
     * Une constante corrigee a moitie casse le test, pas la production.
     *
     * @throws IllegalStateException si le format est incoherent
     */
    public static void assertionsDeFormat() {
        exige(CONNAISSANCES + MISES_EN_SITUATION == QUESTIONS,
                "CONNAISSANCES + MISES_EN_SITUATION doit valoir QUESTIONS");
        exige(SEUIL_REUSSITE * 100 == QUESTIONS * 80,
                "SEUIL_REUSSITE doit valoir 80 % de QUESTIONS");
        exige(SEUIL_REUSSITE_THEME * 100 == QUESTIONS_THEME * 80,
                "SEUIL_REUSSITE_THEME doit valoir 80 % de QUESTIONS_THEME");
    }

    private static void exige(boolean condition, String message) {
        if (!condition) {
            throw new IllegalStateException("Format civique incoherent : " + message);
        }
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
