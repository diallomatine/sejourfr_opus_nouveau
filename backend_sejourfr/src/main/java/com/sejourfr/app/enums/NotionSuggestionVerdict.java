package com.sejourfr.app.enums;

/**
 * Ce que la <b>relecture humaine</b> a fait d'une suggestion de tagging (V054).
 *
 * <p>🛑 <b>Quatre gestes, quatre etats DISTINCTS.</b> Avant V054, « rejeter » et
 * « passer » n'ecrivaient rien — indiscernables en base — et « valider » et
 * « corriger » produisaient la MEME ecriture. On ne pouvait donc pas mesurer si
 * le modele avait raison, ce qui est tout l'interet du pre-tagging.
 *
 * <p>🛑 <b>{@link #VALIDATED} et {@link #CORRECTED} ne sont JAMAIS annonces par
 * un client</b> : le serveur les deduit en comparant la notion retenue a la
 * suggestion la mieux notee. C'est la metrique de qualite du modele ; un client
 * qui pourrait la nommer pourrait la mentir.
 *
 * <p>🛑 <b>Seuls {@link #VALIDATED} et {@link #CORRECTED} posent un
 * {@code civic_notion_id}.</b> Les deux autres ne touchent pas la question.
 */
public enum NotionSuggestionVerdict {

    /** Le relecteur retient la notion <b>la mieux notee</b> par la machine. */
    VALIDATED,

    /** Il retient une <b>autre</b> notion : le tag est pose sur celle-la. */
    CORRECTED,

    /** Aucune notion suggeree ne convient, et il n'en voit pas d'autre. */
    REJECTED,

    /** Il passe sans trancher : la question <b>reste dans la file</b>. */
    SKIPPED;

    /** Le seul verdict qu'un client puisse demander explicitement : « pose le tag ». */
    public static final String DEMANDE_TAG = "TAG";

    /** Ce verdict pose-t-il le tag valide sur la question ? */
    public boolean poseLaNotion() {
        return this == VALIDATED || this == CORRECTED;
    }
}
