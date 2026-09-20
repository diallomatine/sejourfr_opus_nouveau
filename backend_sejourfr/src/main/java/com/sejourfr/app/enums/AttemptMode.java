package com.sejourfr.app.enums;

/**
 * <b>Le REGIME DE PASSATION d'une session</b> — comment elle se joue, par
 * opposition a {@link AttemptType}, qui dit ce qu'elle <b>est</b> (et decide du
 * freemium, de l'historique et des observations).
 *
 * <p>🛑 <b>Depuis le 2026-09-20, ce n'est plus un simple miroir du type.</b> La
 * colonne {@code attempts.mode} existait depuis toujours, {@code NOT NULL},
 * derivee du type par {@code Attempt.prePersist} et lue par <b>personne</b>.
 * Elle porte desormais la seule question que le type ne sait plus trancher :
 * <b>le candidat voit-il les corrections pendant qu'il joue ?</b>
 *
 * <p>Une <b>serie lancee depuis une carte d'etape du Plan</b> est un
 * {@link AttemptType#TRAINING} — pour ne rien changer au freemium ni a
 * l'historique — pose en {@link #EXAMEN} : aucune correction, et l'audio de
 * comprehension orale ne se joue qu'une fois.
 *
 * <p>🛑 <b>Il est SERVI</b> ({@code AttemptResponse.mode}) et <b>opposable</b>
 * ({@code AttemptInteractionService.doSubmitAnswer} ne renvoie la correction
 * qu'en {@link #ENTRAINEMENT}) : une seule valeur, deux lecteurs, aucune
 * divergence possible entre ce que l'ecran montre et ce que le serveur repond.
 */
public enum AttemptMode {

    /** Correction immediate apres chaque reponse ; audio reecoutable. */
    ENTRAINEMENT,

    /**
     * <b>Aucune correction pendant la passation</b> — ni bonne reponse, ni
     * explication — et l'audio de CO ne se joue qu'<b>une seule fois</b>. Le
     * resultat complet reste consultable une fois la session terminee.
     */
    EXAMEN,

    /** Session de revision : pas de correction en cours de session. */
    REVISION
}
