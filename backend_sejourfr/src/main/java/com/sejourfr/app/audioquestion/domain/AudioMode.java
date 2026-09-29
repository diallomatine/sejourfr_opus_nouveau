package com.sejourfr.app.audioquestion.domain;

/**
 * Mode d'audio pour les questions de Comprehension Orale (CO) du TCF IRN.
 * NULL en base pour les questions non audio (CE, STRUCTURE).
 *
 * <p>Un seul axe : <b>ce que le document sonore enonce</b> et <b>ce que l'ecran
 * affiche</b>. C'est lui, et lui seul, qui dit si les propositions peuvent etre
 * melangees a l'affichage (cf. {@code QuestionMapper.choicesAreReadAloud}) : des
 * que l'audio nomme les propositions par leur lettre, l'ordre affiche doit
 * suivre l'audio.
 *
 * <p>Persiste en {@code questions.audio_mode varchar(32)}, borne par
 * {@code chk_question_audio_mode} : la valeur la plus longue tient en 31
 * caracteres.
 */
public enum AudioMode {

    /**
     * Document sonore lu + question et choix affiches a l'ecran.
     * Format historique du TCF, et defaut de la generation.
     *
     * <p>L'audio ne nomme aucune proposition : l'ecran est la seule source de
     * l'ordre, donc les propositions <b>sont melangees</b>.
     */
    WRITTEN_QUESTION,

    /**
     * Document sonore + question + 4 choix lus dans l'audio.
     * A l'ecran, le candidat voit uniquement Reponse A/B/C/D.
     */
    FULL_AUDIO,

    /**
     * Document sonore qui <b>enonce les 4 propositions avec leurs lettres</b>
     * (« A. … B. … C. … D. … ») <b>alors que l'ecran affiche aussi leur texte</b>.
     *
     * <p>Troisieme point du meme axe, ni {@link #WRITTEN_QUESTION} (l'ecran seul)
     * ni {@link #FULL_AUDIO} (l'audio seul, ecran reduit aux lettres). Melanger
     * une telle question desynchronise la lettre dite de la lettre affichee : le
     * candidat qui entend « B », retient B et clique B <b>se trompe alors qu'il
     * avait compris</b>. Elle n'est donc jamais melangee.
     *
     * <p>🛑 Ce mode <b>constate un defaut de contenu, il ne se genere pas</b> : le
     * biais de position qu'il laisse en place (bonne reponse en A sur 13 des 20
     * questions concernees) est une dette a solder en regenerant l'audio
     * <em>sans</em> les lettres, pas un format a produire.
     * {@code AudioQuestionGenerationService} refuse de le prendre en consigne.
     */
    WRITTEN_QUESTION_SPOKEN_CHOICES
}
