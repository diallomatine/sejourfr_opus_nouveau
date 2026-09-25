package com.sejourfr.app.enums;

/**
 * Les 7 etapes du tunnel diagnostic (brief §7.2), dans l'ordre — jamais
 * reordonnees par un front. Chaque etape porte l'indicateur dont la date de
 * debut de mesure la conditionne (Q16) ; une etape non mesuree vaut
 * {@code null}, et toutes les suivantes aussi (le tunnel est sequentiel : une
 * etape qui suit un maillon non mesure ne peut pas etre comptee juste).
 */
public enum SuiviFunnelStep {
    SUBJECT_VIEWED(SuiviIndicator.DIAGNOSTIC_SUBJECT_VIEWED),
    SUBMITTED(SuiviIndicator.DIAGNOSTIC_SUBMITTED),
    ACCOUNT_ATTACHED(SuiviIndicator.ACCOUNT_ATTACHED),
    REPORT_VIEWED(SuiviIndicator.REPORT_VIEWED),
    PLAN_VIEWED(SuiviIndicator.PLAN_VIEWED),
    UNLOCK_CLICKED(SuiviIndicator.PLAN_UNLOCK_CLICKED),
    PURCHASED(SuiviIndicator.PURCHASE_ORIGIN);

    private final SuiviIndicator indicator;

    SuiviFunnelStep(SuiviIndicator indicator) {
        this.indicator = indicator;
    }

    public SuiviIndicator indicator() {
        return indicator;
    }
}
