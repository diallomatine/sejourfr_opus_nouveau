package com.sejourfr.app.service;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillPromptStatus;
import org.springframework.stereotype.Component;

/**
 * Derive le statut d'un petit sujet pour un candidat, a partir de sa DERNIERE
 * tentative.
 *
 * <p><b>Un seul endroit, cote serveur.</b> Le statut n'est pas persiste (une
 * colonne aurait a etre resynchronisee a chaque analyse et aurait fini par
 * mentir) et les fronts ne le recalculent jamais : trois implementations
 * finiraient par diverger, et c'est l'information qui structure tout l'ecran.
 *
 * <p>Le principe qui guide les cinq regles : <b>ne jamais afficher un verdict
 * qu'on n'a pas</b>. Sans analyse, une production n'a aucun jugement de
 * critere — « Validé » serait faux, « À renforcer » serait faux et
 * decourageant. « Fait » est le seul etat honnete.
 */
@Component
public class SkillStatusResolver {

    /**
     * @param latest derniere tentative du candidat sur le sujet, ou {@code null}
     *               s'il n'en a aucune
     */
    public SkillPromptStatus resolve(UserSkillAttempt latest) {
        if (latest == null) {
            return SkillPromptStatus.TODO;
        }
        // Production rendue sans analyse : cas nominal du parcours gratuit.
        if (!latest.isAnalysisRequested()) {
            return SkillPromptStatus.TREATED;
        }
        // Analyse en echec : la panne vient de nous ou du fournisseur, on ne la
        // fait pas payer au candidat en le classant « à renforcer ».
        if (latest.getStatut() == SkillAttemptStatut.FAILED) {
            return SkillPromptStatus.TREATED;
        }
        SkillCriterionStatus criterion = latest.getCriterionStatus();
        if (criterion == SkillCriterionStatus.VALIDATED) {
            return SkillPromptStatus.VALIDATED;
        }
        if (criterion == SkillCriterionStatus.PARTIAL
                || criterion == SkillCriterionStatus.NOT_VALIDATED) {
            return SkillPromptStatus.TO_REINFORCE;
        }
        // Analyse acceptee mais pas encore aboutie (SUBMITTED / TRANSCRIBING /
        // EVALUATING) : la production existe, le verdict pas encore.
        return SkillPromptStatus.TREATED;
    }
}
