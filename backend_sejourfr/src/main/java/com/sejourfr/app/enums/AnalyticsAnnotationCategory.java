package com.sejourfr.app.enums;

/**
 * Nature d'un repere pose sur la courbe temporelle : est-ce le produit qui a
 * change, ou est-ce une action marketing ? Sans cette distinction, un pic
 * s'explique aussi bien par une video virale que par une refonte de la landing,
 * et le repere n'apprend rien.
 */
public enum AnalyticsAnnotationCategory {

    /** Mise en production, refonte d'ecran, nouvelle fonctionnalite. */
    PRODUIT,

    /** Publication, campagne, partenariat. */
    MARKETING
}
