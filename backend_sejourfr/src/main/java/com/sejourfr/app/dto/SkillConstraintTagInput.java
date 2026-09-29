package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillConstraintIcon;

/**
 * Une etiquette de contrainte telle que la console d'administration l'envoie.
 *
 * <p><b>Pourquoi {@code icon} est une chaine et non un
 * {@link SkillConstraintIcon}.</b> Une valeur hors liste desserialisee en enum
 * echouerait dans le convertisseur de messages, avant meme d'atteindre le
 * service : l'editeur recevrait un 400 technique, en anglais, sans savoir
 * quelles valeurs sont admises. En la laissant passer en chaine, c'est le
 * service qui tranche et rend un 422 francais enumerant la liste fermee.
 *
 * <p>La forme sur le fil est identique a celle du DTO de lecture
 * ({@code {"label": "...", "icon": "PERSON"}}) : la console renvoie donc sans
 * transformation ce qu'elle a recu.
 */
public record SkillConstraintTagInput(String label, String icon) {
}
