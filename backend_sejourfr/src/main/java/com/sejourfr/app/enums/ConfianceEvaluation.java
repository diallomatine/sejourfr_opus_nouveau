package com.sejourfr.app.enums;

/**
 * Degre de certitude d'une evaluation IA (schema de sortie v2). Declare par le
 * LLM, puis <b>plafonne cote serveur</b> : la confiance finale est
 * {@code min(confiance IA, plafond serveur)} — on peut abaisser la certitude
 * annoncee par l'IA, jamais la relever.
 *
 * <p>Ordre de declaration = de la plus forte a la plus faible : {@link #min}
 * s'appuie sur l'ordinal.
 *
 * <p><b>Garde-fou produit</b> : un niveau CECRL par tache n'est JAMAIS expose
 * sans sa confiance a cote (cf. {@code EvaluationResultDto}).
 */
public enum ConfianceEvaluation {
    HAUTE,
    MOYENNE,
    FAIBLE;

    /** La plus faible des deux (null = inconnue, l'autre l'emporte). */
    public static ConfianceEvaluation min(ConfianceEvaluation a, ConfianceEvaluation b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.ordinal() >= b.ordinal() ? a : b;
    }

    /** Parse tolerant (casse/espaces libres) ; null si inconnu ou absent. */
    public static ConfianceEvaluation parse(Object raw) {
        if (raw == null) return null;
        String s = raw.toString().trim().toUpperCase(java.util.Locale.ROOT);
        if (s.isEmpty()) return null;
        for (ConfianceEvaluation c : values()) {
            if (c.name().equals(s)) return c;
        }
        return null;
    }
}
