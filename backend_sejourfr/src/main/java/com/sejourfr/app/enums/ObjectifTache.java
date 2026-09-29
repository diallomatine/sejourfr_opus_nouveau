package com.sejourfr.app.enums;

/**
 * Verdict d'accomplissement d'une tache de production (schema de sortie v5,
 * champ {@code accomplissement.objectif} du feedback). C'est la premiere chose
 * que lit le candidat sur son ecran de resultat : « Objectif de la tache :
 * atteint / partiellement atteint / non atteint ».
 *
 * <p>Il porte UNIQUEMENT sur les points OBLIGATOIRES de la consigne :
 * <ul>
 *   <li>{@link #ATTEINT} si et seulement si aucun {@code points_oublies} n'est
 *       marque {@code obligatoire=true} — une piste non abordee ne peut jamais
 *       degrader le verdict ;</li>
 *   <li>{@link #NON_ATTEINT} est reserve au hors-sujet ou a l'absence de
 *       traitement de la consigne.</li>
 * </ul>
 *
 * <p><b>Independant de la note et du niveau</b> : une consigne integralement
 * traitee avec des moyens A1 est ATTEINTE et se note quand meme dans la bande
 * A1/A2. Comme {@link ConfianceEvaluation}, le serveur peut ABAISSER ce verdict
 * (ordre de declaration = du plus favorable au moins favorable), jamais le
 * relever. Les evaluations anterieures au schema v5 n'en portent pas : le champ
 * reste alors absent et les fronts n'affichent pas le bloc.
 */
public enum ObjectifTache {
    ATTEINT,
    PARTIELLEMENT_ATTEINT,
    NON_ATTEINT;

    /** Parse tolerant (casse/espaces libres) ; null si inconnu ou absent. */
    public static ObjectifTache parse(Object raw) {
        if (raw == null) return null;
        String s = raw.toString().trim().toUpperCase(java.util.Locale.ROOT);
        if (s.isEmpty()) return null;
        for (ObjectifTache o : values()) {
            if (o.name().equals(s)) return o;
        }
        return null;
    }
}
