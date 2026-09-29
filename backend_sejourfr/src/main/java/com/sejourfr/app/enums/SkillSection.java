package com.sejourfr.app.enums;

/**
 * Domaine d'appartenance d'une competence.
 *
 * <p><b>Deux familles, un seul referentiel.</b> Les deux premieres valeurs sont
 * les epreuves d'EXPRESSION : une competence y appartient a l'une des 6 taches
 * officielles ({@link SkillTaskCode}) et s'entraine sur des petits sujets. Les
 * deux suivantes sont les domaines de COMPREHENSION : une competence par niveau
 * ({@code CO-A2}, {@code CO-B1}, {@code CO-B2} et leurs jumelles CE),
 * <b>sans aucune tache et sans aucun petit sujet</b> — l'entrainement y est une
 * serie ciblee de QCM, pas une page de 5 sujets.
 *
 * <p>C'est cette asymetrie que porte {@code skills.task_code}, nullable depuis
 * V039 : le domaine se lit ici, le niveau sur {@code skills.target_level}, et
 * {@link SkillTaskCode} reste le referentiel FIGE des seules EE1..EO3 — on ne
 * lui ajoute jamais de valeur CO/CE.
 *
 * <p>Volontairement distinct de {@link EpreuveType} (qui vaut {@code TCF_EE} /
 * {@code TCF_CO}... et sert aux epreuves COMPLETES et aux attempts). Melanger
 * les deux enums inviterait a reutiliser le pipeline de notation des
 * productions, ce qu'on refuse explicitement.
 */
public enum SkillSection {
    EE("Expression écrite"),
    EO("Expression orale"),
    CO("Compréhension orale"),
    CE("Compréhension écrite");

    private final String label;

    SkillSection(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /**
     * Le candidat PRODUIT (ecrit ou parle) : la competence appartient a une
     * tache et s'entraine sur des petits sujets analyses par l'IA.
     */
    public boolean isProduction() {
        return this == EE || this == EO;
    }

    /**
     * Le candidat COMPREND : la competence n'a ni tache ni petit sujet, et
     * s'entraine par une serie ciblee de QCM du meme niveau.
     */
    public boolean isComprehension() {
        return this == CO || this == CE;
    }
}
