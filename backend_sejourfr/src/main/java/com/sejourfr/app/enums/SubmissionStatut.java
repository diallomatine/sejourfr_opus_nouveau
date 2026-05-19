package com.sejourfr.app.enums;

/**
 * Cycle de vie d'une {@code production_submissions}.
 * <p>
 * SUBMITTED -&gt; TRANSCRIBING (EO seulement) -&gt; EVALUATING -&gt; EVALUATED
 * <br>
 * En cas d'echec : -&gt; FAILED. L'utilisateur peut relancer via POST
 * /api/production-submissions/{id}/retry (3 tentatives max).
 * <p>
 * En MVP synchrone, les statuts intermediaires TRANSCRIBING / EVALUATING ne sont
 * pas observes (on passe directement SUBMITTED -&gt; EVALUATED). Ils existent dans
 * le schema pour preparer la migration future en async.
 */
public enum SubmissionStatut {
    SUBMITTED,
    TRANSCRIBING,
    EVALUATING,
    EVALUATED,
    FAILED
}
