package com.sejourfr.app.enums;

/**
 * Les trois familles d'emails, et ce que le candidat peut refuser.
 *
 * <ul>
 *   <li>{@code REQUIRED} — securite, compte, paiement. <b>Jamais desactivable.</b></li>
 *   <li>{@code ENGAGEMENT} — accompagnement de l'apprentissage, actif par defaut,
 *       desactivable (lien en pied de mail + « Notifications par e-mail »).</li>
 *   <li>{@code MARKETING} — prevu, opt-in, <b>aucun mail implemente</b>.</li>
 * </ul>
 */
public enum EmailCategory {
    REQUIRED,
    ENGAGEMENT,
    MARKETING
}
