package com.sejourfr.app.util;

import com.sejourfr.app.enums.DiagnosticRunType;

import java.time.Instant;

/**
 * <b>Autorite unique</b> du « soumis » RETENU d'une {@code diagnostic_run}
 * (controle C, V076) : TCF, le fait pose ; civique, le fait pose ET au moins
 * {@code civicSubmittedMinAnsweredRatio} (config analytics) des questions
 * repondues, mesure figee a la soumission. Une run civique sans mesure
 * (anterieure a V076) est INCONNUE : jamais retenue, jamais lue comme 0 reponse.
 *
 * <p>La regle a deux lecteurs, ecrits ici cote a cote pour ne pas diverger :
 * la lecture Suivi ({@link #SQL}, dans {@code SuiviReadRepository.RUNS}) et le
 * contexte d'inscription pose au claim ({@link #retenu}, dans
 * {@code DiagnosticRunClaimService}). {@code SoumisRetenuIT} evalue les deux
 * sur la meme grille de cas.
 */
public final class SoumisRetenu {

    private SoumisRetenu() {
    }

    /**
     * Predicat SQL sur une run d'alias {@code r}, seuil lie par
     * {@code :civicMinRatio}. Ne teste pas {@code submitted_at} : le lecteur
     * l'applique en {@code CASE WHEN ... THEN r.submitted_at END}.
     */
    public static final String SQL = """
            (r.diagnostic_type <> 'CIVIQUE'
                  OR (r.submitted_question_count > 0
                      AND r.submitted_answered_count
                          >= CAST(:civicMinRatio AS float8) * r.submitted_question_count))""";

    /**
     * Meme regle que {@link #SQL}, plus le fait brut : une run jamais soumise
     * n'est pas retenue.
     */
    public static boolean retenu(DiagnosticRunType type, Instant submittedAt, Integer answeredCount,
                                 Integer questionCount, double civicMinRatio) {
        if (submittedAt == null || type == null) return false;
        if (type != DiagnosticRunType.CIVIQUE) return true;
        return questionCount != null && questionCount > 0 && answeredCount != null
                && (double) answeredCount >= civicMinRatio * questionCount;
    }
}
