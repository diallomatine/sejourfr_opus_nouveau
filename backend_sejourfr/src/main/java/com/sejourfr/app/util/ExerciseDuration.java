package com.sejourfr.app.util;

/**
 * Duree estimee d'un exercice, <b>derivee du sujet</b> et jamais d'une constante
 * par epreuve.
 *
 * <p><b>Une seule regle, deux lecteurs.</b> Le micro-exercice du Plan
 * ({@code RecommendedExerciseSelector}) et la verification en situation
 * ({@code ReassessmentExerciseSelector}) annoncent tous deux un temps au
 * candidat ; deux formules auraient fini par afficher « 3 min » ici et « 8 min »
 * la pour un travail comparable. Les colonnes de duree sont nullables des deux
 * cotes (un sujet cree en console peut naitre sans conseil), d'ou les replis.
 */
public final class ExerciseDuration {

    /** Repli quand le sujet ne porte aucune donnee de duree. */
    public static final int DEFAULT_MINUTES_ORAL = 5;
    public static final int DEFAULT_MINUTES_WRITTEN = 4;

    /**
     * Une part de parole, deux parts pour lire la situation, preparer et
     * s'enregistrer : le temps de parole conseille ne represente qu'un tiers du
     * temps reellement passe sur l'exercice.
     */
    public static final int ORAL_PREPARATION_FACTOR = 3;

    /**
     * Mots par minute retenus a l'ecrit : rythme d'un candidat A2/B1 qui redige
     * en langue etrangere, lecture de la consigne et relecture comprises.
     */
    public static final int WRITTEN_WORDS_PER_MINUTE = 12;

    private ExerciseDuration() {
    }

    /** Oral : temps de parole conseille x {@value #ORAL_PREPARATION_FACTOR}, arrondi a la minute superieure. */
    public static int oral(Integer speakingSeconds) {
        if (speakingSeconds == null || speakingSeconds <= 0) return DEFAULT_MINUTES_ORAL;
        return atLeastOne(ceilDiv(speakingSeconds * ORAL_PREPARATION_FACTOR, 60));
    }

    /**
     * Ecrit : milieu de la fourchette de mots divise par
     * {@value #WRITTEN_WORDS_PER_MINUTE} mots par minute, arrondi a la minute
     * superieure. Une seule borne renseignee sert seule de reference.
     */
    public static int written(Integer minWords, Integer maxWords) {
        Integer min = positiveOrNull(minWords);
        Integer max = positiveOrNull(maxWords);
        if (min == null && max == null) return DEFAULT_MINUTES_WRITTEN;
        int words = min == null ? max : max == null ? min : (min + max) / 2;
        return atLeastOne(ceilDiv(words, WRITTEN_WORDS_PER_MINUTE));
    }

    /**
     * Comprehension : la duree <b>officielle</b> de l'epreuve, ramenee au
     * prorata des questions reellement servies.
     *
     * <p>Aucune constante de duree n'est declaree ici — ni « une minute par
     * question », ni un temps par domaine. Les deux references arrivent de leurs
     * autorites respectives ({@code DureeEpreuve} pour la duree d'epreuve, la
     * composition stratifiee pour son nombre de questions) : c'est ce qui evite
     * qu'une serie ciblee annonce un temps sans rapport avec l'epreuve qu'elle
     * prepare, et qu'un troisieme chiffre apparaisse dans le depot.
     *
     * @param questionCount    questions de la serie proposee
     * @param epreuveSeconds   duree officielle de l'epreuve correspondante
     * @param epreuveQuestions questions de cette epreuve
     */
    public static int comprehension(int questionCount, int epreuveSeconds, int epreuveQuestions) {
        if (questionCount <= 0 || epreuveSeconds <= 0 || epreuveQuestions <= 0) {
            return DEFAULT_MINUTES_WRITTEN;
        }
        return atLeastOne(ceilDiv(questionCount * epreuveSeconds / epreuveQuestions, 60));
    }

    private static Integer positiveOrNull(Integer value) {
        return value == null || value <= 0 ? null : value;
    }

    private static int ceilDiv(int value, int divisor) {
        return (value + divisor - 1) / divisor;
    }

    /** Plancher 1 minute : aucun exercice ne dure zero. */
    private static int atLeastOne(int minutes) {
        return Math.max(1, minutes);
    }
}
