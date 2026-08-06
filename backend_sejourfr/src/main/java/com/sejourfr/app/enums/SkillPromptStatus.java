package com.sejourfr.app.enums;

/**
 * Statut d'un petit sujet POUR UN CANDIDAT DONNE. Valeur <b>derivee</b> a la
 * lecture depuis sa derniere tentative — jamais persistee : une colonne aurait
 * a etre resynchronisee a chaque analyse et aurait fini par mentir. Le calcul
 * vit cote serveur uniquement (cf. {@code SkillStatusResolver}) ; aucun front ne
 * doit le refaire, sous peine de voir trois interpretations diverger.
 *
 * <p><b>Pourquoi {@link #TREATED} existe</b> — la spec ne prevoyait que TODO /
 * VALIDATED / TO_REINFORCE, ce qui supposait qu'une production est toujours
 * analysee. Le freemium casse cette hypothese : produire est gratuit, analyser
 * ne l'est pas. Un sujet rendu sans analyse n'a donc AUCUN verdict de critere.
 * L'afficher « Validé » serait faux, « À renforcer » serait faux et
 * decourageant. TREATED (« Fait ») est le seul etat honnete.
 *
 * <p>Une tentative FAILED (analyse en echec cote fournisseur) retombe aussi sur
 * TREATED : la production existe, le verdict n'existe pas. On ne penalise pas le
 * candidat pour une panne qui n'est pas la sienne.
 */
public enum SkillPromptStatus {
    TODO("À faire"),
    TREATED("Fait"),
    VALIDATED("Validé"),
    TO_REINFORCE("À renforcer");

    private final String label;

    SkillPromptStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /** Vrai des qu'au moins une production a ete rendue sur le sujet. */
    public boolean isAttempted() {
        return this != TODO;
    }
}
