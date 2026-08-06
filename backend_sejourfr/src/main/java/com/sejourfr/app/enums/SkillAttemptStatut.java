package com.sejourfr.app.enums;

/**
 * Cycle de vie d'une {@code user_skill_attempts}.
 *
 * <p>Deux trajectoires selon que le candidat a demande une analyse IA :
 * <ul>
 *   <li><b>sans analyse</b> : {@link #RECORDED} directement, et c'est fini. La
 *       production est conservee, aucun appel payant n'est declenche — ni
 *       Whisper sur l'oral, ni correcteur.</li>
 *   <li><b>avec analyse</b> : {@link #SUBMITTED} -&gt; {@link #TRANSCRIBING}
 *       (oral seulement) -&gt; {@link #EVALUATING} -&gt; {@link #EVALUATED} ou
 *       {@link #FAILED}.</li>
 * </ul>
 *
 * <p>Etats FINAUX : {@link #RECORDED}, {@link #EVALUATED}, {@link #FAILED}.
 * Depuis FAILED, le candidat peut relancer via
 * {@code POST /api/skill-attempts/{id}/retry} sans reconsommer son quota
 * gratuit : l'analyse lui a deja ete decomptee a l'acceptation.
 */
public enum SkillAttemptStatut {
    RECORDED,
    SUBMITTED,
    TRANSCRIBING,
    EVALUATING,
    EVALUATED,
    FAILED;

    /** Vrai si aucun traitement n'est plus attendu sur cette tentative. */
    public boolean isFinal() {
        return this == RECORDED || this == EVALUATED || this == FAILED;
    }
}
