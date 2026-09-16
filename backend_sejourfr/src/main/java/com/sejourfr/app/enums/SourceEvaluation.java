package com.sejourfr.app.enums;

/**
 * D'où vient une <b>évaluation qualifiante</b> d'une épreuve TCF — celles qui
 * alimentent {@code ProgressDto.Epreuve.niveau} et son {@code evolution}.
 *
 * <p>🛑 <b>Ce n'est pas un libellé</b> : les fronts posent le mot, ici on sert
 * le fait. Une seconde table de libellés côté serveur finirait par nommer
 * autrement ce que l'écran nomme déjà.
 *
 * <p>🛑 <b>Les quatre valeurs ne se fondent pas deux à deux.</b> Le
 * {@link #DIAGNOSTIC_COMPLET} n'est ni le diagnostic rapide (une baseline de
 * deux productions courtes) ni un examen blanc (dont il n'a ni le format ni le
 * chrono d'ensemble) : le ranger dans l'un des deux le nommerait faux à
 * l'écran, sur la seule ligne qui explique au candidat <i>d'où sort son
 * niveau</i>.
 */
public enum SourceEvaluation {

    /**
     * Le <b>diagnostic rapide</b> ({@code DiagnosticSession}) : la baseline
     * d'entrée, deux productions courtes analysées dans
     * {@code diagnostic_production_analyses}.
     */
    DIAGNOSTIC_RAPIDE,

    /**
     * Une sous-épreuve du <b>diagnostic TCF complet</b>
     * ({@code TcfDiagnosticSession}). Depuis le 2026-09-13 sa CO/CE est, ligne
     * pour ligne, la même mesure qu'une CO/CE passée seule — d'où son
     * appartenance aux évaluations qualifiantes (révocation de V049).
     */
    DIAGNOSTIC_COMPLET,

    /** L'épreuve passée <b>seule</b>, en examen blanc de module. */
    EPREUVE_SEULE,

    /** L'épreuve passée à l'intérieur d'un <b>examen blanc TCF complet</b>. */
    EXAMEN_BLANC
}
