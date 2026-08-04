package com.sejourfr.app.enums;

/**
 * Grille <b>officielle</b> du TCF IRN pour les epreuves d'expression (ecrite et
 * orale) : a quelle fourchette de note /20 correspond chaque niveau CECRL.
 *
 * <pre>
 * 0      -> A1 non atteint
 * 1      -> A1
 * 2 - 5  -> A2
 * 6 - 9  -> B1
 * 10 - 20-> B2
 * </pre>
 *
 * <p><b>C'est aussi notre echelle depuis les rubriques v6.</b> Jusqu'a v5, l'IA
 * notait sur une echelle maison plus etalee (16-20 = B2, 11-15 = B1, 6-10 = A2,
 * 1-5 = A1), si bien qu'une carte de resultat pouvait afficher « 12,5/20 » et
 * « proche du B1 » alors que 12,5 vaut B2 ici. La v6 a supprime cet ecart : les
 * seuils {@code commun.niveau} de la grille active sont exactement cette table
 * (cf. {@code ProductionRubricsProvider#niveauCecrl()}), et chaque critere est
 * note dessus. Cet enum reste neanmoins la source officielle : il ne se regle
 * pas, et il continue de servir a AFFICHER la fourchette du niveau atteint.
 *
 * <p><b>A ne jamais utiliser comme conversion, meme maintenant.</b> On ne
 * transforme pas une note interne en note TCF : notre note porte sur UNE tache,
 * celle du TCF sur une epreuve entiere. On part du <b>niveau</b> estime et on
 * affiche la fourchette officielle correspondante. Une grille anterieure reste
 * par ailleurs rechargeable via {@code EVAL_RUBRICS_VERSION}, et son echelle
 * n'est alors plus celle-ci.
 *
 * <p><b>A ne jamais afficher sur une tache isolee.</b> Au TCF, la note /20 est
 * celle d'une epreuve entiere (3 taches). Une tache seule n'a pas de note TCF.
 *
 * <p>Constante officielle, donc dans le code et non dans la configuration :
 * contrairement aux seuils {@code sejourfr.production-evaluation.niveau-cecrl},
 * qui sont notre calibration et se reglent, celle-ci n'est pas negociable.
 * Enum distinct de {@link NiveauCecrl} parce que la grille ne vaut que pour les
 * epreuves d'expression : les epreuves de comprehension (CO/CE) sont notees sur
 * une echelle de points, pas sur 20.
 */
public enum BandeNoteTcf {
    A1_NON_ATTEINT(NiveauCecrl.A1_NON_ATTEINT, 0, 0),
    A1(NiveauCecrl.A1, 1, 1),
    A2(NiveauCecrl.A2, 2, 5),
    B1(NiveauCecrl.B1, 6, 9),
    B2(NiveauCecrl.B2, 10, 20);

    private final NiveauCecrl niveau;
    private final int scoreMin;
    private final int scoreMax;

    BandeNoteTcf(NiveauCecrl niveau, int scoreMin, int scoreMax) {
        this.niveau = niveau;
        this.scoreMin = scoreMin;
        this.scoreMax = scoreMax;
    }

    public NiveauCecrl getNiveau() {
        return niveau;
    }

    public int getScoreMin() {
        return scoreMin;
    }

    public int getScoreMax() {
        return scoreMax;
    }

    /**
     * Fourchette officielle d'un niveau ; {@code null} pour {@code null} et pour
     * C1/C2, qui sont hors de l'echelle du TCF IRN (l'examen ne certifie pas
     * au-dela de B2 sur les epreuves d'expression).
     */
    public static BandeNoteTcf of(NiveauCecrl niveau) {
        if (niveau == null) return null;
        for (BandeNoteTcf bande : values()) {
            if (bande.niveau == niveau) return bande;
        }
        return null;
    }
}
