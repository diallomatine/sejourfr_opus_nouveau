package com.sejourfr.app.enums;

/**
 * Palier de français visé par un candidat.
 *
 * <p><b>L'ordre de déclaration EST l'ordre CECRL</b> : c'est lui que
 * {@link TargetProcedure#niveauVise} compare pour appliquer le plancher de la
 * démarche. Ne jamais réordonner ces constantes ni en intercaler une sans
 * respecter la progression du CECRL.
 */
public enum TargetLevel {
    A2,
    B1,
    B2
}
