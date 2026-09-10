package com.sejourfr.app.service.plancivique;

/**
 * L'état de maîtrise d'une cible civique ({@code 20_} §5.2, arbitrage A12).
 *
 * <p>🛑 <b>{@link #NON_EVALUEE} n'est pas un mauvais verdict</b> : moins de deux
 * réponses ne conclut rien. C'est l'invariant {@code null = inconnu} du dépôt,
 * appliqué au civique — la confusion inverse a produit les faux
 * {@code A1_NON_ATTEINT} du TCF (V040/V041/V042).
 */
public enum CivicMaitrise {

    /** Moins de deux réponses enregistrées : on ne sait pas. */
    NON_EVALUEE("Non évaluée"),

    /** Boîte 1 ou 2 — ce qui coûte des points aujourd'hui. */
    A_TRAVAILLER("À travailler"),

    /** Boîte 3 — en cours d'acquisition, pas encore tenu. */
    EN_PROGRESSION("En progression"),

    /** Boîte 4 ou 5 <b>et</b> dernière réponse correcte. */
    MAITRISEE("Maîtrisée");

    private final String label;

    CivicMaitrise(String label) {
        this.label = label;
    }

    /** Libellé FR <b>gelé</b> : les trois fronts en tiennent un miroir à la main. */
    public String getLabel() {
        return label;
    }

    /**
     * L'état d'une cible, d'après son historique.
     *
     * @param reponses          nombre de réponses enregistrées
     * @param boite             la boîte Leitner courante
     * @param derniereCorrecte  la dernière réponse était-elle juste ?
     */
    public static CivicMaitrise of(int reponses, int boite, boolean derniereCorrecte) {
        if (reponses < 2) return NON_EVALUEE;
        if (boite <= 2) return A_TRAVAILLER;
        if (boite == 3) return EN_PROGRESSION;
        return derniereCorrecte ? MAITRISEE : EN_PROGRESSION;
    }
}
