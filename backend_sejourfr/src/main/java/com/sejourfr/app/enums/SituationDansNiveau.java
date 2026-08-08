package com.sejourfr.app.enums;

import com.sejourfr.app.config.ProductionEvaluationProperties;

import java.math.BigDecimal;

/**
 * Ou se situe une production A L'INTERIEUR de son propre palier CECRL, en trois
 * crans. C'est ce qui remplace, sur le resultat d'une TACHE ISOLEE, la note /20
 * qui n'y est plus affichee.
 *
 * <p><b>Pourquoi ce champ existe.</b> Au TCF, un correcteur humain attribue un
 * NIVEAU par tache ; la note /20 ne porte que sur l'epreuve entiere (3 taches).
 * Et sur l'echelle officielle, ou 10/20 vaut deja B2, un « 3,5/20 » se lit comme
 * un naufrage scolaire alors que c'est un A2 tout a fait normal. On a donc
 * retire la note de l'ecran d'une tache — mais sans rien mettre a la place, un
 * A2 a 2 et un A2 a 5 auraient vu exactement le meme ecran, et le candidat
 * n'aurait plus aucun signal de progression entre deux tentatives.
 *
 * <p><b>Libelles, regle a ne pas casser.</b> Le haut de la bande A2 se dit
 * « A2 solide », <b>jamais</b> « presque B1 » : on vient precisement de retirer
 * le vocabulaire de deficit, on ne le reintroduit pas par la porte de service.
 * Aucun des trois crans ne nomme un manque.
 *
 * <p><b>Derive SERVEUR, jamais recalcule par un front</b> (meme philosophie que
 * {@code SkillStatusResolver}) : les bornes de bande viennent du bloc
 * {@code commun.niveau} de la grille active, pas d'une constante Java — elles
 * changent avec l'echelle (cf. le passage a l'echelle du TCF en v6).
 */
public enum SituationDansNiveau {

    /** Bas de la bande : le palier est atteint, il commence a s'installer. */
    ENTREE_DE_PALIER("Palier atteint", "atteint"),
    /** Milieu de bande : le palier tient sur l'ensemble de la production. */
    PALIER_CONFIRME("Palier confirmé", "confirmé"),
    /** Haut de bande : le palier est tenu de bout en bout. */
    PALIER_SOLIDE("Palier solide", "solide");

    private final String libelle;
    private final String qualificatif;

    SituationDansNiveau(String libelle, String qualificatif) {
        this.libelle = libelle;
        this.qualificatif = qualificatif;
    }

    /** Libelle FR autonome, affichable sans le niveau (« Palier solide »). */
    public String getLibelle() {
        return libelle;
    }

    /** Adjectif seul, pour composer avec un niveau (« solide »). */
    public String getQualificatif() {
        return qualificatif;
    }

    /**
     * Libelle complet rendu au candidat : « A2 solide », « B1 confirmé ».
     * Null si le niveau ne se prete pas a cette lecture (cf. {@link #of}).
     */
    public String libelleAvecNiveau(NiveauCecrl niveau) {
        if (!estSituable(niveau)) return null;
        return niveau.name() + " " + qualificatif;
    }

    /**
     * Situation d'une note /20 dans la bande de son propre niveau, en trois
     * crans egaux.
     *
     * <p>Retourne {@code null} quand la question n'a pas de sens :
     * <ul>
     *   <li>note ou niveau absent ;</li>
     *   <li>{@code A1_NON_ATTEINT} : la bande ne vaut qu'un seul point (0), il
     *       n'y a rien a situer ;</li>
     *   <li>{@code C1}/{@code C2} : hors du profil TCF IRN, plafonne a B2.</li>
     * </ul>
     *
     * <p>La note est RAMENEE dans la bande avant le calcul. C'est necessaire
     * parce que le niveau affiche peut avoir ete PLAFONNE (cf.
     * {@code plafond_niveau}) : la note reste alors celle du bareme pendant que
     * le niveau, lui, a ete abaisse. On situe toujours dans le palier
     * REELLEMENT annonce au candidat — sinon on afficherait une position hors
     * de sa propre bande.
     */
    public static SituationDansNiveau of(BigDecimal note, NiveauCecrl niveau,
                                         ProductionEvaluationProperties.NiveauCecrl seuils) {
        if (note == null || seuils == null || !estSituable(niveau)) return null;

        BigDecimal min = borneBasse(niveau, seuils);
        BigDecimal max = borneHaute(niveau, seuils);
        if (min == null || max == null || max.compareTo(min) <= 0) return null;

        BigDecimal borne = note;
        if (borne.compareTo(min) < 0) borne = min;
        if (borne.compareTo(max) > 0) borne = max;

        double position = borne.subtract(min).doubleValue() / max.subtract(min).doubleValue();
        if (position < 1.0 / 3.0) return ENTREE_DE_PALIER;
        if (position < 2.0 / 3.0) return PALIER_CONFIRME;
        return PALIER_SOLIDE;
    }

    /** Niveaux dont la bande a une largeur exploitable sur le profil TCF IRN. */
    private static boolean estSituable(NiveauCecrl niveau) {
        return niveau == NiveauCecrl.A1 || niveau == NiveauCecrl.A2
            || niveau == NiveauCecrl.B1 || niveau == NiveauCecrl.B2;
    }

    private static BigDecimal borneBasse(NiveauCecrl niveau,
                                         ProductionEvaluationProperties.NiveauCecrl seuils) {
        return switch (niveau) {
            // A1 commence juste au-dessus de 0 (0 = A1 non atteint) : on prend 0
            // comme borne, la note ne peut de toute facon pas y descendre.
            case A1 -> BigDecimal.ZERO;
            case A2 -> BigDecimal.valueOf(seuils.getSeuilA2());
            case B1 -> BigDecimal.valueOf(seuils.getSeuilB1());
            case B2 -> BigDecimal.valueOf(seuils.getSeuilB2());
            default -> null;
        };
    }

    private static BigDecimal borneHaute(NiveauCecrl niveau,
                                         ProductionEvaluationProperties.NiveauCecrl seuils) {
        return switch (niveau) {
            case A1 -> BigDecimal.valueOf(seuils.getSeuilA2());
            case A2 -> BigDecimal.valueOf(seuils.getSeuilB1());
            case B1 -> BigDecimal.valueOf(seuils.getSeuilB2());
            // B2 est le plafond du profil : sa bande monte jusqu'au haut du bareme.
            case B2 -> BigDecimal.valueOf(20);
            default -> null;
        };
    }
}
