package com.sejourfr.app.enums;

/**
 * Filtre « Examinateur IA » de la liste admin des productions : {@code AVEC} =
 * productions passées avec l'examinateur vocal (EO temps réel, source
 * {@link ProductionSubmissionSource#REALTIME}) ; {@code SANS} = productions
 * classiques (audio enregistré ou texte, source
 * {@link ProductionSubmissionSource#ASYNC}).
 */
public enum AdminProductionExaminateurFiltre {
    AVEC,
    SANS;

    public ProductionSubmissionSource source() {
        return this == AVEC ? ProductionSubmissionSource.REALTIME : ProductionSubmissionSource.ASYNC;
    }
}
