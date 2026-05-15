package com.sejourfr.app.audioquestion.domain;

/**
 * Mode d'audio pour les questions de Comprehension Orale (CO) du TCF IRN.
 * NULL en base pour les questions non audio (CE, STRUCTURE).
 */
public enum AudioMode {

    /**
     * Document sonore lu + question et choix affiches a l'ecran.
     * Format historique du TCF, et defaut de la generation.
     */
    WRITTEN_QUESTION,

    /**
     * Document sonore + question + 4 choix lus dans l'audio.
     * A l'ecran, le candidat voit uniquement Reponse A/B/C/D.
     */
    FULL_AUDIO
}
