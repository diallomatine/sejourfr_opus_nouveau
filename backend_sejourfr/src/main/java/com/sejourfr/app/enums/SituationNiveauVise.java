package com.sejourfr.app.enums;

/**
 * Ou en est le candidat PAR RAPPORT AU NIVEAU QU'IL VISE, apres une
 * micro-production du module Competences. C'est la phrase affichee sous le gros
 * niveau sur l'ecran de resultat.
 *
 * <p><b>Derive SERVEUR, jamais recalcule par un front</b> — meme philosophie que
 * {@link SituationDansNiveau} (position dans son propre palier) et que
 * {@code SkillStatusResolver} (statut d'un sujet). Le niveau vise depend de la
 * demarche du candidat ({@link TargetProcedure#niveauVise}), une regle que les
 * fronts n'ont pas a reimplementer et qui a deja existe en six copies
 * divergentes dans ce depot.
 *
 * <p><b>Ne pas confondre avec {@link SituationDansNiveau}</b> : celle-la situe
 * une production A L'INTERIEUR de son propre palier (« A2 solide ») ; celle-ci
 * situe le palier atteint PAR RAPPORT A L'OBJECTIF (« Tu es proche du niveau
 * visé »). Les deux peuvent coexister sans se contredire.
 *
 * <p><b>Libelles geles</b>, comme tout le module Competences : ils sont recopies
 * a la main cote web et cote mobile, et {@code SkillLabelsTest} en tient le cote
 * serveur. Aucun ne nomme un manque : « Encore du chemin » decrit une distance,
 * pas un echec — le depot a deja retire le vocabulaire de deficit des cartes de
 * resultat, on ne le reintroduit pas ici.
 */
public enum SituationNiveauVise {

    /** Le niveau demontre atteint ou depasse le palier vise. */
    OBJECTIF_ATTEINT("Tu as atteint ton objectif"),

    /** Exactement un palier CECRL en dessous de l'objectif. */
    PROCHE("Tu es proche du niveau visé"),

    /** Deux paliers ou plus en dessous de l'objectif. */
    EN_CHEMIN("Encore du chemin vers ton objectif");

    private final String label;

    SituationNiveauVise(String label) {
        this.label = label;
    }

    /** Libelle FR rendu au candidat, tel quel. */
    public String getLabel() {
        return label;
    }
}
