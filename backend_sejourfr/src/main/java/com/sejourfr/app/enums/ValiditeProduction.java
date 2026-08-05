package com.sejourfr.app.enums;

/**
 * Verdict des controles DETERMINISTES appliques a une production EE/EO
 * <b>avant</b> tout appel au LLM (cf. {@code ProductionValidityService}).
 *
 * <ul>
 *   <li>{@code VALIDE} : rien a signaler, evaluation IA normale ;</li>
 *   <li>{@code AVERTISSEMENT} : la production est evaluable mais un doute
 *       serieux pese dessus (langue partiellement non francaise, recopiage
 *       partiel de la consigne). On appelle le LLM et on expose les raisons au
 *       candidat. La confiance n'est plafonnee que si le doute est un obstacle
 *       a l'observation ({@link DouteValidite#OBSERVATION}) ; un doute
 *       d'{@link DouteValidite#AUTHENTICITE} ne la touche pas ;</li>
 *   <li>{@code INVALIDE} : la production ne peut pas etre notee (texte vide,
 *       pas en francais, consigne recopiee). On <b>n'appelle pas le LLM</b> :
 *       note 0, niveau {@code A1_NON_ATTEINT}, confiance {@code FAIBLE}.</li>
 * </ul>
 */
public enum ValiditeProduction {
    VALIDE,
    AVERTISSEMENT,
    INVALIDE
}
