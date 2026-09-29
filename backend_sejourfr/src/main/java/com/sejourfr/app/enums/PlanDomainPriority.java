package com.sejourfr.app.enums;

/**
 * Ce que le Plan a decide de faire d'un <b>domaine</b> du TCF (CO / CE / EO /
 * EE) : la pastille affichee a droite de sa ligne, dans « Mon profil TCF ».
 *
 * <p><b>C'est le SERVEUR qui decide qu'un domaine est prioritaire</b>, jamais
 * l'ecran — meme philosophie que {@link SituationNiveauVise},
 * {@link ContinuiteSimulation} et {@code SkillStatusResolver} : <b>derive a la
 * lecture, jamais persiste, jamais recalcule par un front</b>. La regle depend
 * du palier que le cycle construit et de la priorite n&deg;1 en cours ; trois
 * copies front auraient fini par peindre trois pastilles differentes sur le
 * meme domaine.
 *
 * <p><b>L'ordre de declaration EST l'ordre d'urgence</b> — c'est lui qui trie
 * les 4 lignes du profil, du plus urgent au moins urgent (patron
 * {@link SkillReferenceLevel}, dont l'ordre d'affichage est gele lui aussi).
 * Ne pas le reordonner.
 *
 * <p><b>Libelles geles</b> par {@code SkillLabelsTest}, et recopies a la main
 * dans les trois fronts : un libelle qui bouge, ce sont quatre fichiers a
 * changer dans la meme passe.
 *
 * <p>🛑 <b>Aucune de ces cinq valeurs ne nomme une faiblesse.</b>
 * {@link #A_EVALUER} en particulier veut dire « il manque des donnees », pas
 * « ce domaine est mauvais » : c'est la transposition, au niveau du domaine, du
 * principe <i>null = inconnu, jamais mauvais</i> que le depot applique deja au
 * niveau d'une epreuve jamais passee.
 */
public enum PlanDomainPriority {

    /** Le domaine porte la priorite n&deg;1 du Plan : c'est ce qui bloque maintenant. */
    FORTE("Priorité forte"),

    /**
     * Le domaine a du travail pour le palier en construction : il est en dessous
     * du palier vise par le cycle, ou il porte encore une competence fragile.
     */
    A_TRAVAILLER("À travailler"),

    /**
     * Le domaine a atteint l'objectif du candidat : il n'y a plus rien a y
     * construire, seulement a l'entretenir.
     */
    ENTRETIEN("Entretien"),

    /**
     * Le domaine a deja depasse le palier que le cycle construit, sans avoir
     * atteint l'objectif : il redeviendra prioritaire a un cycle suivant. Le
     * Plan cible le domaine qui bloque le palier <b>courant</b>, pas celui qui
     * est deja devant.
     */
    PAS_ENCORE_PRIORITAIRE("Pas encore prioritaire"),

    /** Aucune donnee : le domaine n'a jamais ete mesure. Ce n'est pas une faiblesse. */
    A_EVALUER("À évaluer");

    private final String label;

    PlanDomainPriority(String label) {
        this.label = label;
    }

    /** Libelle FR rendu au candidat, tel quel. */
    public String getLabel() {
        return label;
    }
}
